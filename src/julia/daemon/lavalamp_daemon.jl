#!/usr/bin/env julia
#
# LavaLamp daemon — long-running identity-monitor process.
#
# Behaviour:
#   1. Calibrates an envelope at start (registration ceremony per
#      LL-011) using synthetic constant-stream coupling — same
#      shape as Step 1+2 of `lavalamp_demo.jl`.
#   2. Loops indefinitely. Every VERIFY_CADENCE_SECONDS, runs
#      `verify_full` against the registered envelope (LL-006 +
#      LL-019). Verify result is logged to stdout only.
#   3. Every HEARTBEAT_CADENCE_SECONDS, touches a heartbeat
#      file (~/.lavalamp/heartbeat) containing **only** a current
#      timestamp. The heartbeat file is the cross-process signal
#      that the menu bar app (LL-039) reads. NOTHING about the
#      verify result, residue, λ values, or chaos-guard state is
#      ever written to that file — strict LL-002 + LL-039
#      existence-only semantics.
#   4. On SIGINT / clean exit, deletes the heartbeat file (the
#      menu bar treats absent file as "daemon not running" and
#      hides its icon).
#
# Run from the lavalamp/ root:
#
#     julia --project=src/julia src/julia/daemon/lavalamp_daemon.jl
#
# To use with the macOS menu bar app, leave this running in a
# terminal; the icon will go green within a few seconds and stay
# green as long as the daemon is alive.
#
# CLI flags (all optional):
#   --verify-cadence N   seconds between verify_full passes
#                        (default 60)
#   --heartbeat-cadence N  seconds between heartbeat refreshes
#                          (default 3)

using Random
using Printf
using Dates
using Sockets
using SHA
using LavaLamp
using LavaLamp.Audit: residue
using LavaLamp.Engine: lorenz96_coupled, CouplingParams
using LavaLamp.Sensors: constant_stream

const HEARTBEAT_DIR = expanduser("~/.lavalamp")
const HEARTBEAT_FILE = joinpath(HEARTBEAT_DIR, "heartbeat")
const VERIFY_SOCKET = joinpath(HEARTBEAT_DIR, "verify.sock")
const VERIFY_PUB    = joinpath(HEARTBEAT_DIR, "verify.pub")

# ─── LL-040 singleton guard (cold-start IPC bug fix, 2026-05-29) ─
#
# The daemon previously had NO singleton guard. main() deletes
# verify.sock / verify.pub at startup *and* at exit; with two
# overlapping instances (a manual run racing the launchd job, or a
# restart overlap) the short-lived instance's atexit hooks would
# delete files the long-lived instance is still advertising —
# leaving a healthy daemon whose IPC channel is gone from disk
# while its banner still claims it. See
# docs/ll040_ipc_coldstart_bug_companion.md for the full root cause.
#
# Fix: take an exclusive, non-blocking flock(2) on a lock file
# before ANY destructive file op in main(). The lock is held for
# the whole process lifetime and the kernel auto-releases it on
# exit (including SIGKILL / crash), so there is no stale-lock
# problem. A second instance that cannot acquire the lock exits
# immediately without touching the incumbent's files.
const LOCK_FILE = joinpath(HEARTBEAT_DIR, "daemon.lock")

# BSD flock(2) operation flags — identical values on macOS + Linux.
const FLOCK_LOCK_EX = Cint(2)   # exclusive lock
const FLOCK_LOCK_NB = Cint(4)   # non-blocking: fail rather than wait

# Holds the open lock-file handle for the daemon's lifetime. Keeping
# the IOStream referenced here prevents GC from closing the fd (which
# would release the flock). `nothing` until the lock is acquired.
const LOCK_HANDLE = Ref{Union{IOStream,Nothing}}(nothing)

# Defense-in-depth behind the flock guard: only the instance that
# actually stood up the IPC files may delete them at exit. Guards the
# should-never-happen case where flock is a no-op on an exotic
# filesystem (e.g. some NFS-mounted home dirs). Set true once
# verify.sock + verify.pub are both live for THIS process.
const I_OWN_IPC_FILES = Ref{Bool}(false)

# LL-044 TPM2 working files. Used only on Linux when tpm2-tools
# is available; otherwise the daemon falls through to the
# LL-043 software-key path.
const TPM2_PRIMARY_CTX = joinpath(HEARTBEAT_DIR, "tpm2_primary.ctx")
const TPM2_KEY_PUB     = joinpath(HEARTBEAT_DIR, "tpm2_key.pub")
const TPM2_KEY_PRIV    = joinpath(HEARTBEAT_DIR, "tpm2_key.priv")  # TPM-encrypted blob, NOT a software priv
const TPM2_KEY_CTX     = joinpath(HEARTBEAT_DIR, "tpm2_key.ctx")
# Persistent handle for the loaded key. The 0x81xxxxxx range is
# reserved for application persistent handles per TPM 2.0 spec.
# We use 0x81FF0001 (high in the range to minimise collision with
# other apps that don't pick deterministic handles).
const TPM2_PERSISTENT_HANDLE = "0x81FF0001"

# Runtime flag: true if we're using the TPM2-bound signing path.
# Set during generate_startup_keypair! based on platform + tool
# availability.
const SIGNING_VIA_TPM2 = Ref{Bool}(false)

# ─── LL-040 + LL-041 + LL-042 + LL-043: daemon verify-result IPC ─
#
# A second cross-process channel beyond the LL-039 heartbeat:
# an AF_UNIX socket at $HEARTBEAT_DIR/verify.sock that exposes
# the *cached* verify_full result to authorised local clients
# (PharOS PAM module being the canonical consumer).
#
# Protocol versions:
#   v1 (LL-040, v0.0.84): 1-byte response. Superseded.
#   v2 (LL-041, v0.0.85): 17-byte challenge + 42-byte HMAC-SHA256.
#       Superseded.
#   v3 (LL-042, v0.0.86): 17-byte challenge + 74-byte Ed25519
#       asymmetric signature. Superseded — Ed25519 is not
#       supported by Apple Secure Enclave, blocking the
#       hardware-key roadmap.
#   v4 (LL-043, v0.0.87): 17-byte challenge + 74-byte ECDSA
#       P-256 (prime256v1) raw r||s signature. **Current.**
#       ECDSA P-256 is supported by both Apple Secure Enclave
#       and TPM 2.0, unblocking future LL-044 (Linux TPM2-bound)
#       and LL-045 (macOS Secure-Enclave-bound) without further
#       wire-format changes.
#
# Wire format (v4 / LL-043):
#   Request (17 bytes):
#     - byte 0: version 0x04
#     - bytes 1..16: 16-byte client nonce
#   Response (74 bytes):
#     - byte 0: version 0x04
#     - byte 1: result 'A' / 'R' / 'S'
#     - bytes 2..9: 8-byte LE Int64 daemon timestamp
#     - bytes 10..73: 64-byte raw ECDSA P-256 signature
#                     (32-byte r ‖ 32-byte s)
#                     over SHA-256(nonce ‖ result ‖ timestamp)
#
# Public key file (verify.pub, mode 0644): 33 bytes — SEC1
# compressed point (0x02 or 0x03 prefix + 32-byte X).
#
# Threat model honest framing for v4 (LL-043 software-key tier):
#   Defended:
#     - Capture-and-replay (client-supplied nonce binds signature)
#     - Same-process-tier MITM forgery (private key file mode 0600)
#     - Stale captured responses (timestamp freshness window)
#     - Public-key compromise → no forgery (asymmetric shape;
#       client only holds public key)
#   NOT defended (load-bearing limit, deferred):
#     - Same-UID attackers (root or daemon UID) can read the
#       private key file directly.
#     - **LL-044** (Linux TPM 2.0 binding) closes this on Linux:
#       private key generated inside the TPM, never extractable.
#       Same v4 wire format; only key-storage layer changes.
#     - **LL-045** (macOS Secure Enclave binding) closes this
#       on macOS but requires Apple Developer ID code-signing
#       (the SE's `keychain-access-groups` entitlement is
#       gated to apps with valid provisioning). The Swift
#       helper at src/swift/lavalamp_se_signer/ ships
#       code-ready; runtime binding awaits Developer ID
#       infrastructure.

const IPC_STALE_AFTER_S = 120.0
const IPC_VERSION = UInt8(0x04)
const IPC_REQUEST_LEN = 17    # 1 version + 16 nonce
const IPC_RESPONSE_LEN = 74   # 1 version + 1 result + 8 ts + 64 sig
const IPC_NONCE_LEN = 16
const IPC_SIG_LEN = 64        # raw r(32) || s(32)
const IPC_RAW_FIELD_LEN = 32  # r and s are each 32 bytes
const IPC_PUB_LEN = 33        # SEC1 compressed P-256 point
const IPC_PUB_UNCOMPRESSED_LEN = 65  # 0x04 || X(32) || Y(32)

# OpenSSL constants and library reference.
const LIBCRYPTO = "libcrypto"

# Per-startup signing key (EVP_PKEY*). Held for the lifetime of
# the daemon process; freed in the atexit hook.
const SIGNING_PKEY = Ref{Ptr{Cvoid}}(C_NULL)

# Mutable shared state between verify loop and IPC handler tasks.
# Read by IPC clients; written by the verify loop. Single writer
# (main task) / multiple readers; @async tasks for IPC handling.
mutable struct DaemonState
    accepted::Bool
    max_resσ::Float64
    last_verify_ts::Float64
end
const STATE = DaemonState(false, 0.0, 0.0)

# ─── CLI parsing ────────────────────────────────────────────

function parse_int_flag(args::Vector{String}, flag::String, default::Int)
    i = findfirst(==(flag), args)
    i === nothing && return default
    i + 1 > length(args) && error("$flag requires an integer argument")
    return parse(Int, args[i + 1])
end

VERIFY_CADENCE_SECONDS   = parse_int_flag(ARGS, "--verify-cadence", 60)
HEARTBEAT_CADENCE_SECONDS = parse_int_flag(ARGS, "--heartbeat-cadence", 3)

# ─── Heartbeat file management ──────────────────────────────

function ensure_heartbeat_dir()
    isdir(HEARTBEAT_DIR) || mkpath(HEARTBEAT_DIR)
end

"""
    write_heartbeat()

Writes the current epoch second + ISO8601 timestamp to the
heartbeat file. The file contents are deliberately limited to a
timestamp — no verify result, no residue values, no security
state. The menu bar app reads only the file's mtime to determine
liveness, never the contents.
"""
function write_heartbeat()
    open(HEARTBEAT_FILE, "w") do io
        write(io, string(Int(round(time())), " ", now()))
    end
end

function delete_heartbeat()
    isfile(HEARTBEAT_FILE) && rm(HEARTBEAT_FILE)
end

# ─── LL-040 IPC server ──────────────────────────────────────

function delete_verify_socket()
    try
        ispath(VERIFY_SOCKET) && rm(VERIFY_SOCKET; force=true)
    catch
        # Best-effort cleanup; ignore errors at exit.
    end
end

function delete_verify_pub()
    try
        isfile(VERIFY_PUB) && rm(VERIFY_PUB; force=true)
    catch
    end
end

"""
    acquire_singleton_lock(lock_path=LOCK_FILE) -> Bool

Take an exclusive, non-blocking flock(2) on `lock_path`. Returns
true if this process now holds the lock (stashing the open handle
in LOCK_HANDLE so the fd stays open — and the lock held — for the
process lifetime), false if another live daemon already holds it.

The lock file itself is never removed: closing the fd releases the
flock, and leaving the 0-byte file in place avoids the classic
unlink-vs-relock race where a new instance locks a freshly-created
file while the old one still "holds" the unlinked inode.

flock(2) takes a RawFD directly via ccall's RawFD arg type (Julia
auto-converts); the kernel releases the lock when the fd closes,
including on SIGKILL / crash, so a stale lock is impossible.
"""
function acquire_singleton_lock(lock_path::AbstractString=LOCK_FILE)::Bool
    io = open(lock_path, "a")   # append: create-if-absent, never truncate
    rc = ccall(:flock, Cint, (Base.RawFD, Cint),
               fd(io), FLOCK_LOCK_EX | FLOCK_LOCK_NB)
    if rc != 0
        close(io)
        return false
    end
    LOCK_HANDLE[] = io
    return true
end

"""
    release_singleton_lock()

Close the lock handle, releasing the flock. Idempotent. Registered
in atexit; the kernel would release the lock on process death
anyway — this just makes the release prompt and explicit. The lock
file is intentionally left on disk (see acquire_singleton_lock).
"""
function release_singleton_lock()
    io = LOCK_HANDLE[]
    if io !== nothing
        try; close(io); catch; end
        LOCK_HANDLE[] = nothing
    end
end

"""
    evp_ec_gen_p256() -> Ptr{Cvoid}

Generates a fresh ECDSA P-256 keypair via the OpenSSL 1.1+
multi-step paramgen API (avoiding Julia's varargs-ccall
issue with `EVP_PKEY_Q_keygen` on ARM64). Returns an
EVP_PKEY pointer; caller is responsible for `EVP_PKEY_free`.

Steps:
  1. EVP_PKEY_CTX_new_id(EVP_PKEY_EC = 408, NULL)
  2. EVP_PKEY_keygen_init(ctx)
  3. EVP_PKEY_CTX_ctrl(ctx, EVP_PKEY_EC, OP_PARAMGEN|OP_KEYGEN,
                      CTRL_EC_PARAMGEN_CURVE_NID, NID_P-256, NULL)
  4. EVP_PKEY_keygen(ctx, &pkey)
  5. EVP_PKEY_CTX_free(ctx)
"""
function evp_ec_gen_p256()
    # OpenSSL constants (from openssl/evp.h, openssl/obj_mac.h):
    EVP_PKEY_EC                            = Cint(408)
    EVP_PKEY_OP_PARAMGEN_OR_KEYGEN         = Cint(4 | 8)   # PARAMGEN=1<<2, KEYGEN=1<<3
    EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID    = Cint(0x1001)  # EVP_PKEY_ALG_CTRL + 1
    NID_X9_62_prime256v1                   = Cint(415)

    ctx = ccall((:EVP_PKEY_CTX_new_id, LIBCRYPTO), Ptr{Cvoid},
                (Cint, Ptr{Cvoid}), EVP_PKEY_EC, C_NULL)
    ctx == C_NULL && error("EVP_PKEY_CTX_new_id(EVP_PKEY_EC) failed")

    try
        rc1 = ccall((:EVP_PKEY_keygen_init, LIBCRYPTO), Cint,
                    (Ptr{Cvoid},), ctx)
        rc1 == 1 || error("EVP_PKEY_keygen_init failed: rc=$rc1")

        rc2 = ccall((:EVP_PKEY_CTX_ctrl, LIBCRYPTO), Cint,
                    (Ptr{Cvoid}, Cint, Cint, Cint, Cint, Ptr{Cvoid}),
                    ctx, EVP_PKEY_EC, EVP_PKEY_OP_PARAMGEN_OR_KEYGEN,
                    EVP_PKEY_CTRL_EC_PARAMGEN_CURVE_NID,
                    NID_X9_62_prime256v1, C_NULL)
        rc2 == 1 || error("EVP_PKEY_CTX_ctrl(set curve P-256) failed: rc=$rc2")

        pkey_ref = Ref{Ptr{Cvoid}}(C_NULL)
        rc3 = ccall((:EVP_PKEY_keygen, LIBCRYPTO), Cint,
                    (Ptr{Cvoid}, Ptr{Ptr{Cvoid}}), ctx, pkey_ref)
        rc3 == 1 || error("EVP_PKEY_keygen failed: rc=$rc3")
        pkey_ref[] == C_NULL && error("EVP_PKEY_keygen returned NULL")

        return pkey_ref[]
    finally
        ccall((:EVP_PKEY_CTX_free, LIBCRYPTO), Cvoid, (Ptr{Cvoid},), ctx)
    end
end

"""
    get_uncompressed_pub(pkey) -> Vector{UInt8}

Extracts the 65-byte SEC1 uncompressed public key from an
EVP_PKEY for an EC key. Format: 0x04 || X(32) || Y(32).
Uses OpenSSL 3's EVP_PKEY_get_octet_string_param("pub").
"""
function get_uncompressed_pub(pkey::Ptr{Cvoid})
    pub = zeros(UInt8, IPC_PUB_UNCOMPRESSED_LEN)
    out_len = Ref{Csize_t}(IPC_PUB_UNCOMPRESSED_LEN)
    rc = ccall((:EVP_PKEY_get_octet_string_param, LIBCRYPTO), Cint,
               (Ptr{Cvoid}, Cstring, Ptr{UInt8}, Csize_t, Ptr{Csize_t}),
               pkey, "pub", pub, IPC_PUB_UNCOMPRESSED_LEN, out_len)
    rc == 1 || error("EVP_PKEY_get_octet_string_param(pub) failed: rc=$rc")
    out_len[] == IPC_PUB_UNCOMPRESSED_LEN || error("unexpected pub len: $(out_len[])")
    return pub
end

"""
    compress_pub(uncompressed) -> Vector{UInt8}

Converts SEC1 uncompressed P-256 (0x04 || X(32) || Y(32),
65 bytes) to SEC1 compressed (0x02 or 0x03 prefix + X(32),
33 bytes). Prefix is 0x02 if Y is even, 0x03 if odd.
"""
function compress_pub(uncompressed::Vector{UInt8})
    @assert length(uncompressed) == IPC_PUB_UNCOMPRESSED_LEN
    @assert uncompressed[1] == 0x04
    x = uncompressed[2:33]
    y_last = uncompressed[65]
    prefix = (y_last & 0x01) == 0 ? UInt8(0x02) : UInt8(0x03)
    return vcat([prefix], x)
end

"""
    der_to_raw64(der) -> Vector{UInt8}

Converts an ASN.1 DER-encoded ECDSA P-256 signature (as
returned by `EVP_DigestSign`) into the raw 64-byte form
(32-byte r ‖ 32-byte s, big-endian, zero-padded).
"""
function der_to_raw64(der::Vector{UInt8})
    idx = 1
    @assert der[idx] == 0x30 "expected SEQUENCE tag"; idx += 1
    # Single-byte length form (ECDSA P-256 DER is always < 128 bytes total)
    if (der[idx] & 0x80) != 0
        nbytes = Int(der[idx] & 0x7f)
        idx += 1 + nbytes
    else
        idx += 1
    end
    # Read r
    @assert der[idx] == 0x02 "expected INTEGER tag for r"; idx += 1
    rlen = Int(der[idx]); idx += 1
    rbytes = collect(der[idx:idx + rlen - 1]); idx += rlen
    # Read s
    @assert der[idx] == 0x02 "expected INTEGER tag for s"; idx += 1
    slen = Int(der[idx]); idx += 1
    sbytes = collect(der[idx:idx + slen - 1]); idx += slen

    # Strip leading zero (DER negative-prevention padding)
    while length(rbytes) > IPC_RAW_FIELD_LEN && rbytes[1] == 0x00
        rbytes = rbytes[2:end]
    end
    while length(sbytes) > IPC_RAW_FIELD_LEN && sbytes[1] == 0x00
        sbytes = sbytes[2:end]
    end
    # Left-pad to 32 bytes
    rbytes = vcat(zeros(UInt8, IPC_RAW_FIELD_LEN - length(rbytes)), rbytes)
    sbytes = vcat(zeros(UInt8, IPC_RAW_FIELD_LEN - length(sbytes)), sbytes)
    @assert length(rbytes) == IPC_RAW_FIELD_LEN && length(sbytes) == IPC_RAW_FIELD_LEN
    return vcat(rbytes, sbytes)
end

"""
    ecdsa_p256_sign(pkey, message) -> Vector{UInt8}

Signs `message` with ECDSA P-256 over SHA-256. Returns the
64-byte raw r||s signature (DER → raw conversion done
internally so the wire format is fixed-size).
"""
function ecdsa_p256_sign(pkey::Ptr{Cvoid}, message::AbstractVector{UInt8})
    mctx = ccall((:EVP_MD_CTX_new, LIBCRYPTO), Ptr{Cvoid}, ())
    mctx == C_NULL && error("EVP_MD_CTX_new failed")
    try
        sha256_md = ccall((:EVP_sha256, LIBCRYPTO), Ptr{Cvoid}, ())
        sha256_md == C_NULL && error("EVP_sha256 returned NULL")
        rc = ccall((:EVP_DigestSignInit, LIBCRYPTO), Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                   mctx, C_NULL, sha256_md, C_NULL, pkey)
        rc == 1 || error("EVP_DigestSignInit failed: rc=$rc")

        msg_bytes = collect(message)
        # First call: get required signature length
        sig_len = Ref{Csize_t}(0)
        rc1 = ccall((:EVP_DigestSign, LIBCRYPTO), Cint,
                    (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t),
                    mctx, C_NULL, sig_len, msg_bytes, length(msg_bytes))
        rc1 == 1 || error("EVP_DigestSign (size query) failed: rc=$rc1")

        # Second call: actually sign
        sig = zeros(UInt8, sig_len[])
        rc2 = ccall((:EVP_DigestSign, LIBCRYPTO), Cint,
                    (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t),
                    mctx, sig, sig_len, msg_bytes, length(msg_bytes))
        rc2 == 1 || error("EVP_DigestSign failed: rc=$rc2")

        actual_der = sig[1:Int(sig_len[])]
        return der_to_raw64(actual_der)
    finally
        ccall((:EVP_MD_CTX_free, LIBCRYPTO), Cvoid, (Ptr{Cvoid},), mctx)
    end
end

"""
    free_signing_pkey!()

Frees the OpenSSL EVP_PKEY held by SIGNING_PKEY. Idempotent.
Called from atexit.
"""
function free_signing_pkey!()
    if SIGNING_PKEY[] != C_NULL
        ccall((:EVP_PKEY_free, LIBCRYPTO), Cvoid, (Ptr{Cvoid},), SIGNING_PKEY[])
        SIGNING_PKEY[] = C_NULL
    end
end

# ─── LL-044: Linux TPM 2.0 binding (shell-out to tpm2-tools) ───
#
# When tpm2-tools is available on Linux, the daemon binds its
# signing key to the TPM. The private key parameters never
# leave the TPM; signing operations are mediated by the TPM
# kernel (~30ms latency per signature). When TPM2 is unavailable
# (no tools / non-Linux / no /dev/tpmrm0), the daemon falls
# back to the LL-043 software-key path — same v4 wire format,
# different key-storage tier.
#
# Honest scope for the current release:
#   - Code is implemented but UNVERIFIED on actual TPM2
#     hardware in this session (developer is on macOS without
#     a TPM). The dispatch logic is exercised by the software
#     fallback path; the TPM2 path is exercised only when CI
#     or downstream deployments run on Linux with tpm2-tools.
#   - Marked :argued in the spec until validated end-to-end
#     against swtpm in CI or a real TPM in a deployment.

"""
    tpm2_available() -> Bool

Returns true on Linux when `tpm2_getcap` is on \$PATH and
exits 0 when invoked. False on macOS (no Linux TPM kernel
interface), when tpm2-tools is not installed, or when the
TPM device is unreachable.
"""
function tpm2_available()
    Sys.islinux() || return false
    try
        rc = run(pipeline(`tpm2_getcap properties-fixed`,
                           stdout=devnull, stderr=devnull);
                 wait=false)
        wait(rc)
        return rc.exitcode == 0
    catch
        return false
    end
end

"""
    tpm2_init_signing_key()

Generates a primary key + a child ECDSA P-256 signing key
inside the TPM, persists the loaded key to
`TPM2_PERSISTENT_HANDLE`, and writes the SEC1-compressed
public key to VERIFY_PUB. Per-startup: previous handle (if
any) is evicted first.

Throws an exception if any step fails (caller catches and
falls back to software ECDSA).
"""
function tpm2_init_signing_key()
    # Best-effort eviction of any leftover persistent handle.
    try
        run(pipeline(Cmd(["tpm2_evictcontrol", "-c", TPM2_PERSISTENT_HANDLE]),
                     stdout=devnull, stderr=devnull); wait=true)
    catch
        # Ignore — handle may not exist yet.
    end

    # Create primary in owner hierarchy.
    run(Cmd(["tpm2_createprimary",
             "--hierarchy=o",
             "--key-algorithm=ecc",
             "--key-context=$TPM2_PRIMARY_CTX"]))

    # Create ECDSA P-256 signing key as child of primary.
    # --key-algorithm=ecc256 selects NIST P-256.
    # --hash-algorithm=sha256 sets the per-key hash.
    # --attributes restricts to signing only.
    # Using Cmd array-form to avoid Julia's command-parser
    # rejecting the `|` separators in --attributes.
    run(Cmd(["tpm2_create",
             "--parent-context=$TPM2_PRIMARY_CTX",
             "--key-algorithm=ecc256:ecdsa-sha256",
             "--hash-algorithm=sha256",
             "--attributes=sign|userwithauth|sensitivedataorigin",
             "--public=$TPM2_KEY_PUB",
             "--private=$TPM2_KEY_PRIV"]))

    # Load the key into TPM transient memory.
    run(Cmd(["tpm2_load",
             "--parent-context=$TPM2_PRIMARY_CTX",
             "--public=$TPM2_KEY_PUB",
             "--private=$TPM2_KEY_PRIV",
             "--key-context=$TPM2_KEY_CTX"]))

    # Make persistent (per-startup rotation: we evict on
    # shutdown; persistence is required for tpm2_sign to find
    # the key across separate tpm2-tools invocations).
    run(Cmd(["tpm2_evictcontrol",
             "--hierarchy=o",
             "--object-context=$TPM2_KEY_CTX",
             TPM2_PERSISTENT_HANDLE]))

    # Read the public key in PEM format, then convert to
    # SEC1-compressed via OpenSSL CLI.
    pub_pem = joinpath(HEARTBEAT_DIR, "tpm2_pub.pem")
    run(Cmd(["tpm2_readpublic",
             "--object-context=$TPM2_PERSISTENT_HANDLE",
             "--output=$pub_pem",
             "--format=pem"]))

    # Use OpenSSL CLI to extract the compressed point.
    pub_der = joinpath(HEARTBEAT_DIR, "tpm2_pub.der")
    run(pipeline(Cmd(["openssl", "ec",
                      "-pubin", "-in", pub_pem,
                      "-conv_form", "compressed",
                      "-outform", "DER"]),
                 stdout=pub_der))

    # Parse the DER to extract the raw 33-byte compressed point.
    # The X.509 SubjectPublicKeyInfo structure ends with a
    # BIT STRING whose value (after the unused-bits byte) is
    # the SEC1 encoded public key. For P-256 compressed, that's
    # 33 bytes at the end of the file.
    der_bytes = read(pub_der)
    # The compressed point is the last 33 bytes.
    @assert length(der_bytes) >= IPC_PUB_LEN "DER too short: $(length(der_bytes))"
    compressed = der_bytes[end - IPC_PUB_LEN + 1:end]
    @assert compressed[1] == 0x02 || compressed[1] == 0x03 "expected SEC1 compressed prefix, got 0x$(string(compressed[1], base=16, pad=2))"

    open(VERIFY_PUB, "w") do io
        write(io, compressed)
    end
    chmod(VERIFY_PUB, 0o644)

    # Clean up intermediate PEM/DER files; keep the .ctx files
    # for sign-time context loading.
    isfile(pub_pem) && rm(pub_pem; force=true)
    isfile(pub_der) && rm(pub_der; force=true)
end

"""
    tpm2_sign(message) -> Vector{UInt8}

Signs `message` via the TPM's persistent signing handle.
Returns the 64-byte raw r||s signature. Shell-out cost is
~30-50ms per signature on real TPM hardware; ~5-10ms on
swtpm.

The TPM signs SHA-256(message) via ECDSA. tpm2_sign emits a
TPM2B_SIGNATURE structure; we extract r and s from the
serialized format.
"""
function tpm2_sign(message::AbstractVector{UInt8})
    msg_bytes = collect(message)
    msg_file = tempname()
    sig_file = tempname()
    try
        write(msg_file, msg_bytes)

        # Sign with SHA-256 hash; --format=plain emits raw r||s
        # on tpm2-tools >= 4.0.
        run(Cmd(["tpm2_sign",
                 "--key-context=$TPM2_PERSISTENT_HANDLE",
                 "--hash-algorithm=sha256",
                 "--signature=$sig_file",
                 "--format=plain",
                 msg_file]))

        # `--format=plain` emits raw r||s for ECDSA on
        # tpm2-tools >= 4.0. (Older versions need DER parsing
        # via --format=tss + manual extraction.)
        sig_bytes = read(sig_file)
        if length(sig_bytes) == IPC_SIG_LEN
            return collect(sig_bytes)
        elseif length(sig_bytes) > IPC_SIG_LEN
            # tss format — DER-like. Try der_to_raw64 fallback.
            return der_to_raw64(collect(sig_bytes))
        else
            error("tpm2_sign produced unexpected signature length: $(length(sig_bytes))")
        end
    finally
        isfile(msg_file) && rm(msg_file; force=true)
        isfile(sig_file) && rm(sig_file; force=true)
    end
end

"""
    tpm2_cleanup()

Evicts the persistent handle and removes intermediate context
files. Idempotent; called from atexit.
"""
function tpm2_cleanup()
    if SIGNING_VIA_TPM2[]
        try
            run(pipeline(Cmd(["tpm2_evictcontrol", "-c", TPM2_PERSISTENT_HANDLE]),
                         stdout=devnull, stderr=devnull); wait=true)
        catch
        end
    end
    for f in (TPM2_PRIMARY_CTX, TPM2_KEY_PUB, TPM2_KEY_PRIV, TPM2_KEY_CTX)
        try
            isfile(f) && rm(f; force=true)
        catch
        end
    end
end

"""
    generate_startup_keypair!()

Dispatches per-platform: on Linux with tpm2-tools available,
generates the per-startup ECDSA P-256 keypair INSIDE THE TPM
(LL-044 path; private key never leaves the TPM). Otherwise
falls back to the LL-043 software-key path (private key in
OpenSSL EVP_PKEY heap, in process memory).

Either path writes a 33-byte SEC1-compressed public key to
VERIFY_PUB (mode 0644). Wire format is identical regardless
of the key-storage tier.

Honest scope:
  - Software-key tier (LL-043, current default on macOS):
    same-UID attackers can read process memory and recover
    the private key.
  - TPM2-bound tier (LL-044, Linux when tpm2-tools available):
    private key parameters never leave the TPM; same-UID
    attackers cannot extract the key. Closes the LL-043
    software-key limit on Linux.
  - macOS Secure Enclave tier (LL-045): code-ready
    (`src/swift/lavalamp_se_signer/`); awaits Apple Developer
    ID code-signing.
"""
function generate_startup_keypair!()
    # Try LL-044 Linux TPM2 path first.
    if tpm2_available()
        try
            tpm2_init_signing_key()
            SIGNING_VIA_TPM2[] = true
            return
        catch e
            @warn "LL-044 TPM2 init failed; falling back to LL-043 software key" exception=e
            tpm2_cleanup()
            SIGNING_VIA_TPM2[] = false
            # Fall through to software path below.
        end
    end

    # LL-043 software-key path (default on macOS / no-TPM Linux).
    SIGNING_PKEY[] = evp_ec_gen_p256()
    pub_uncompressed = get_uncompressed_pub(SIGNING_PKEY[])
    pub_compressed = compress_pub(pub_uncompressed)

    open(VERIFY_PUB, "w") do io
        write(io, pub_compressed)
    end
    chmod(VERIFY_PUB, 0o644)
end

"""
    encode_int64_le(n) -> Vector{UInt8}

Encodes a signed Int64 as 8 little-endian bytes.
"""
function encode_int64_le(n::Int64)
    bytes = Vector{UInt8}(undef, 8)
    v = reinterpret(UInt64, n)
    for i in 1:8
        bytes[i] = UInt8((v >> ((i-1)*8)) & 0xff)
    end
    return bytes
end

"""
    ipc_handle_client(client)

LL-043 v4 protocol handler. Reads 17 bytes from the client
(1-byte version 0x04 + 16-byte nonce), determines the cached
verify state, and writes 74 bytes back (1-byte version +
1-byte result + 8-byte LE timestamp + 64-byte raw ECDSA
P-256 signature over SHA-256(nonce ‖ result ‖ timestamp)).

Run in an @async task so multiple concurrent clients are
served. Bad protocol versions / short reads / write errors
just close the connection silently — the client will see a
short read or EOF and fail closed.
"""
function ipc_handle_client(client::IO)
    try
        request = read(client, IPC_REQUEST_LEN)
        if length(request) != IPC_REQUEST_LEN || request[1] != IPC_VERSION
            return
        end
        nonce = request[2:1 + IPC_NONCE_LEN]

        age = time() - STATE.last_verify_ts
        result = if STATE.last_verify_ts == 0.0 || age > IPC_STALE_AFTER_S
            UInt8('S')
        elseif STATE.accepted
            UInt8('A')
        else
            UInt8('R')
        end

        ts = Int64(round(time()))
        ts_bytes = encode_int64_le(ts)
        signed_message = vcat(nonce, [result], ts_bytes)
        sig = if SIGNING_VIA_TPM2[]
            tpm2_sign(signed_message)
        else
            ecdsa_p256_sign(SIGNING_PKEY[], signed_message)
        end

        response = vcat([IPC_VERSION, result], ts_bytes, sig)
        @assert length(response) == IPC_RESPONSE_LEN
        write(client, response)
    catch
        # Best-effort: clients that close early or send malformed
        # data shouldn't crash the daemon.
    finally
        try; close(client); catch; end
    end
end

"""
    start_ipc_server() -> server

Creates the AF_UNIX listener at $VERIFY_SOCKET, restricts to
owner-only (chmod 0600), and spawns an @async accept loop that
dispatches each connection to ipc_handle_client. Returns the
server handle so main can close it on shutdown.
"""
function start_ipc_server()
    delete_verify_socket()
    server = listen(VERIFY_SOCKET)
    chmod(VERIFY_SOCKET, 0o600)
    @async begin
        while isopen(server)
            try
                client = accept(server)
                @async ipc_handle_client(client)
            catch e
                # Server-close during shutdown raises an IOError; that's
                # the expected exit path. Re-raise anything else.
                isopen(server) || break
                @warn "ipc accept error" exception=e
            end
        end
    end
    return server
end

# ─── Envelope calibration ───────────────────────────────────

"""
    setup_envelope() -> (env, ds_factory, k_check)

Calibrates a registration envelope using the same synthetic-
stream shape as the demo (Lorenz-96, F=8, constant_stream
coupling). Returns the envelope plus the SDE factory and check
threshold so the verify loop can run against them.

Real-deployment registration would use real-hardware sensor
streams and persist the envelope to a TPM-bound secret store
(LL-022 strategy 1). The synthetic-envelope path here is the
prototype-tier default.
"""
function setup_envelope()
    Random.seed!(101)
    N        = 20
    F_BASE   = 8.0
    N_TRIALS = 5
    N_STEPS  = 1000
    Δt       = 0.05
    T_TR     = 200.0
    # K_CHECK: residue/σ rejection threshold. verify REJECTs a live
    # system whose max normalised residue exceeds this.
    #
    # Raised 10.0 → 12.0 on 2026-05-31 from 9,790 logged verifies
    # (2026-05-21 → 05-31): 9,788 ACCEPT, 2 REJECT (0.02%). Both false
    # rejects barely crossed 10.0 — 10.40 (05-25) and 10.22 (05-26),
    # both under heavy load (billions of allocations between restarts).
    # Distribution: min 1.23, median 3.46, mean 3.62, p99 6.82, with a
    # clear empty gap between ~8.6 and those two outliers. k=12.0 clears
    # both observed false rejects with ~15% margin and sits in that dead
    # zone, while staying far below the >15 band where genuine
    # adversaries fall — eliminates the load-induced nuisance-REJECT
    # tail without meaningfully narrowing impostor detection. The
    # downstream PharOS reactor recovery cost is high (physical re-login
    # + remembering to unload the reactor), so a conservative threshold
    # is the right default. See PharOS PH-019 log analysis 2026-05-31.
    K_CHECK  = 12.0

    b         = ones(N)
    s_const   = constant_stream(1.0; t_max=2000.0)
    p_genuine = CouplingParams(F_BASE, [s_const], [1.0], [b])
    ds_factory = () -> lorenz96_coupled(N; F=F_BASE, coupling=p_genuine)

    println("[$(now())] Calibrating registration envelope ...")
    env = register_envelope(
        ds_factory;
        n_trials = N_TRIALS,
        N        = N_STEPS,
        Δt       = Δt,
        Ttr      = T_TR,
    )
    println("[$(now())] Envelope registered (λ_max ≈ $(round(env.spectrum[1], digits=4)); n_trials=$N_TRIALS).")

    return env, ds_factory, K_CHECK
end

# ─── Verify loop ────────────────────────────────────────────

"""
    run_verify(env, ds_factory, k_check) -> (accepted::Bool, max_resσ::Float64)

Runs a fresh Lyapunov-spectrum residue audit against the
registered envelope. Returns the accept/reject decision **and**
the max residue/σ ratio observed — the underlying calculation
the verify decision is based on. Surfacing this number in the
daemon's log line is what makes the per-cycle verification
auditable from outside (per the credibility-section discipline:
no black-box ACCEPT lines).
"""
function run_verify(env, ds_factory, k_check)
    Random.seed!(rand(UInt32))
    ds = ds_factory()
    λs = lyapunov_spectrum(ds; N=1000, Δt=0.05, Ttr=200.0)
    accepted = verify(λs, env; k=k_check)
    res = LavaLamp.Audit.residue(λs, env)
    max_resσ = maximum(res ./ max.(env.σ, 1e-10))
    return (accepted, max_resσ)
end

# ─── Main loop ──────────────────────────────────────────────

function main()
    ensure_heartbeat_dir()

    # Singleton guard MUST run before any destructive file op below
    # (delete_heartbeat / delete_verify_*). If another daemon already
    # holds the lock, exit cleanly WITHOUT touching its files — this
    # is the fix for the cold-start IPC bug where an overlapping
    # instance stomped the incumbent's verify.sock / verify.pub. See
    # docs/ll040_ipc_coldstart_bug_companion.md.
    if !acquire_singleton_lock()
        println("LavaLamp daemon: another instance already holds " *
                "$LOCK_FILE — exiting without touching its IPC files.")
        return
    end
    Base.atexit(release_singleton_lock)

    delete_heartbeat()
    delete_verify_socket()
    delete_verify_pub()

    # Generate the per-startup ECDSA P-256 keypair used for LL-043
    # asymmetric signing. Private key lives in OpenSSL's EVP_PKEY
    # heap structure (in daemon process memory); public key is
    # SEC1-compressed (33 bytes) and written to VERIFY_PUB at
    # mode 0644 (world-readable — clients verify only).
    generate_startup_keypair!()

    # Robust cleanup: runs on any process exit (SIGINT, SIGTERM,
    # SIGHUP, normal return, uncaught exception). Without this,
    # a daemon killed mid-sleep leaves stale files that fool
    # downstream consumers into believing the daemon is alive —
    # exactly the failure mode we never want.
    Base.atexit(delete_heartbeat)
    # IPC-file cleanup is gated on ownership (defense-in-depth behind
    # the flock guard): only the instance that actually stood up the
    # IPC files may remove them at exit, so a second instance that
    # somehow slipped past the lock can never delete the incumbent's.
    Base.atexit() do
        if I_OWN_IPC_FILES[]
            delete_verify_socket()
            delete_verify_pub()
        end
    end
    Base.atexit(free_signing_pkey!)
    Base.atexit(tpm2_cleanup)

    key_tier = SIGNING_VIA_TPM2[] ? "LL-044 TPM2-bound (Linux, tpm2-tools)" :
                                     "LL-043 software-key (process memory)"
    println("LavaLamp daemon")
    println("  Heartbeat file         : $HEARTBEAT_FILE")
    println("  Verify-result socket   : $VERIFY_SOCKET   (LL-040)")
    println("  ECDSA P-256 public key : $VERIFY_PUB      (mode 0644, 33 bytes)")
    println("  Signing-key tier       : $key_tier")
    println("  Verify cadence         : every $VERIFY_CADENCE_SECONDS s")
    println("  Heartbeat cadence      : every $HEARTBEAT_CADENCE_SECONDS s")
    println("  Press Ctrl-C to stop (all files cleaned up).")
    println()

    Base.exit_on_sigint(false)

    env, ds_factory, k_check = setup_envelope()

    # Start the LL-040 IPC server (background @async accept loop).
    server = start_ipc_server()
    # Both IPC files are now live for THIS process — verify.pub from
    # generate_startup_keypair! above, verify.sock from
    # start_ipc_server. Claim ownership so the gated atexit cleanup
    # is permitted to remove them.
    I_OWN_IPC_FILES[] = true

    # First heartbeat + first verify on entry.
    write_heartbeat()
    last_verify_time = time()
    (accepted, max_resσ) = run_verify(env, ds_factory, k_check)
    STATE.accepted = accepted
    STATE.max_resσ = max_resσ
    STATE.last_verify_ts = time()
    @printf("[%s] verify_full → %s  (max residue/σ = %.2f / k=%.1f)\n",
            now(), (accepted ? "ACCEPT" : "REJECT"), max_resσ, k_check)
    flush(stdout)

    try
        while true
            sleep(HEARTBEAT_CADENCE_SECONDS)
            write_heartbeat()

            if time() - last_verify_time >= VERIFY_CADENCE_SECONDS
                (accepted, max_resσ) = run_verify(env, ds_factory, k_check)
                STATE.accepted = accepted
                STATE.max_resσ = max_resσ
                STATE.last_verify_ts = time()
                last_verify_time = time()
                @printf("[%s] verify_full → %s  (max residue/σ = %.2f / k=%.1f)\n",
                        now(), (accepted ? "ACCEPT" : "REJECT"), max_resσ, k_check)
                flush(stdout)
            end
        end
    catch e
        if e isa InterruptException
            println("\n[$(now())] LavaLamp daemon stopping (SIGINT) ...")
        else
            rethrow(e)
        end
    finally
        try; close(server); catch; end
        delete_heartbeat()
        delete_verify_socket()
        println("[$(now())] Heartbeat + verify socket removed. Daemon stopped.")
    end
end

# Only run the daemon when this file is executed as a script.
# `include`-ing it (e.g. from the test suite) defines all the
# functions WITHOUT starting the daemon or touching ~/.lavalamp.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
