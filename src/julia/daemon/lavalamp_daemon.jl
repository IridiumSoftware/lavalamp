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

"""
    generate_startup_keypair!()

Generates the per-startup ECDSA P-256 keypair via OpenSSL,
writes the SEC1-compressed (33-byte) public key to VERIFY_PUB
(mode 0644). The private key is held in OpenSSL's EVP_PKEY
heap structure (referenced from SIGNING_PKEY[]); on the
software-key tier this means the bytes live in the daemon
process's address space.

Honest scope: software-key tier. Same-UID attackers (root or
daemon UID) can read process memory and recover the private
key. LL-044 (Linux TPM 2.0 binding) and LL-045 (macOS Secure
Enclave binding, awaiting Developer ID code-signing) are the
future defenses; same v4 wire format, only key-storage layer
swaps.
"""
function generate_startup_keypair!()
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
        sig = ecdsa_p256_sign(SIGNING_PKEY[], signed_message)

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
    K_CHECK  = 10.0

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
    Base.atexit(delete_verify_socket)
    Base.atexit(delete_verify_pub)
    Base.atexit(free_signing_pkey!)

    println("LavaLamp daemon")
    println("  Heartbeat file         : $HEARTBEAT_FILE")
    println("  Verify-result socket   : $VERIFY_SOCKET   (LL-040)")
    println("  ECDSA P-256 public key : $VERIFY_PUB      (LL-043, mode 0644, 33 bytes)")
    println("  Verify cadence         : every $VERIFY_CADENCE_SECONDS s")
    println("  Heartbeat cadence      : every $HEARTBEAT_CADENCE_SECONDS s")
    println("  Press Ctrl-C to stop (all files cleaned up).")
    println()

    Base.exit_on_sigint(false)

    env, ds_factory, k_check = setup_envelope()

    # Start the LL-040 IPC server (background @async accept loop).
    server = start_ipc_server()

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

main()
