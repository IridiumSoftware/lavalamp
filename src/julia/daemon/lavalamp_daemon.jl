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
const VERIFY_PRIV   = joinpath(HEARTBEAT_DIR, "verify.priv")
const VERIFY_PUB    = joinpath(HEARTBEAT_DIR, "verify.pub")

# ─── LL-040 + LL-041 + LL-042: daemon verify-result IPC ────────
#
# A second cross-process channel beyond the LL-039 heartbeat:
# an AF_UNIX socket at $HEARTBEAT_DIR/verify.sock that exposes
# the *cached* verify_full result to authorised local clients
# (PharOS PAM module being the canonical consumer).
#
# Protocol versions:
#   v1 (LL-040, v0.0.84): 1-byte response. Existence + cached
#       Bool only. Superseded.
#   v2 (LL-041, v0.0.85): 17-byte challenge + 42-byte HMAC-SHA256
#       response with shared secret. Anti-replay + anti-forge
#       MITM. Superseded.
#   v3 (LL-042, v0.0.86): 17-byte challenge + 74-byte Ed25519-
#       signed response with on-disk private key. Asymmetric
#       crypto — public key is public-readable; only the daemon
#       UID has the private key. Current.
#
# Wire format (v3 / LL-042):
#   Request (17 bytes): version (0x03) + 16-byte client nonce
#   Response (74 bytes): version (0x03) + 1-byte result
#                        + 8-byte LE Int64 timestamp
#                        + 64-byte Ed25519 signature
#                        over (nonce ‖ result ‖ timestamp)
#
# Threat model honest framing for v3 (LL-042 software-key tier):
#   Defended:
#     - Capture-and-replay (client-supplied nonce binds response)
#     - Same-process-tier MITM forgery (private key file mode 0600)
#     - Stale captured responses (timestamp freshness window)
#     - Public-key compromise → no forgery (verifying with public
#       does not enable signing; the asymmetric shape is the
#       architectural improvement over LL-041's shared secret —
#       client doesn't need the private key)
#   NOT defended (load-bearing limit, deferred to LL-NNN+1):
#     - Same-UID attackers (root or daemon UID) can read the
#       private key file directly. TPM/Secure-Enclave key
#       binding (LL-022 strategy 1) is the defense; private
#       key never leaves the secure element. Out of scope for
#       this software-key release; queued.

const IPC_STALE_AFTER_S = 120.0  # 2× the default 60s verify cadence
const IPC_VERSION = UInt8(0x03)
const IPC_REQUEST_LEN = 17    # 1 version + 16 nonce
const IPC_RESPONSE_LEN = 74   # 1 version + 1 result + 8 ts + 64 sig
const IPC_NONCE_LEN = 16
const IPC_SIG_LEN = 64
const IPC_KEY_LEN = 32        # Ed25519 raw key (priv = pub = 32 bytes)

# OpenSSL Ed25519 NID (from <openssl/obj_mac.h>).
const EVP_PKEY_ED25519 = Cint(1087)
const LIBCRYPTO = "libcrypto"

# Per-startup signing key. Pointer into OpenSSL's EVP_PKEY
# heap; held for the lifetime of the daemon process. Freed
# in the atexit hook.
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

function delete_verify_priv()
    try
        isfile(VERIFY_PRIV) && rm(VERIFY_PRIV; force=true)
    catch
    end
end

function delete_verify_pub()
    try
        isfile(VERIFY_PUB) && rm(VERIFY_PUB; force=true)
    catch
    end
end

"""
    evp_pkey_from_priv(priv) -> Ptr{Cvoid}

Allocates an OpenSSL `EVP_PKEY` from a raw 32-byte Ed25519
private seed. Returns a non-null pointer; caller is
responsible for `EVP_PKEY_free`.
"""
function evp_pkey_from_priv(priv::Vector{UInt8})
    @assert length(priv) == IPC_KEY_LEN
    pkey = ccall((:EVP_PKEY_new_raw_private_key, LIBCRYPTO), Ptr{Cvoid},
                 (Cint, Ptr{Cvoid}, Ptr{UInt8}, Csize_t),
                 EVP_PKEY_ED25519, C_NULL, priv, IPC_KEY_LEN)
    pkey == C_NULL && error("EVP_PKEY_new_raw_private_key failed")
    return pkey
end

"""
    get_raw_public(pkey) -> Vector{UInt8}

Extracts the 32-byte raw Ed25519 public key from an EVP_PKEY.
"""
function get_raw_public(pkey::Ptr{Cvoid})
    pub = zeros(UInt8, IPC_KEY_LEN)
    len = Ref{Csize_t}(IPC_KEY_LEN)
    rc = ccall((:EVP_PKEY_get_raw_public_key, LIBCRYPTO), Cint,
               (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Csize_t}),
               pkey, pub, len)
    rc == 1 || error("EVP_PKEY_get_raw_public_key failed: rc=$rc")
    len[] == IPC_KEY_LEN || error("unexpected pub len: $(len[])")
    return pub
end

"""
    ed25519_sign(pkey, message) -> Vector{UInt8}

Signs `message` with the Ed25519 private key bound to `pkey`.
Returns a 64-byte signature.
"""
function ed25519_sign(pkey::Ptr{Cvoid}, message::AbstractVector{UInt8})
    mctx = ccall((:EVP_MD_CTX_new, LIBCRYPTO), Ptr{Cvoid}, ())
    mctx == C_NULL && error("EVP_MD_CTX_new failed")
    try
        rc = ccall((:EVP_DigestSignInit, LIBCRYPTO), Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                   mctx, C_NULL, C_NULL, C_NULL, pkey)
        rc == 1 || error("EVP_DigestSignInit failed: rc=$rc")
        sig = zeros(UInt8, IPC_SIG_LEN)
        sig_len = Ref{Csize_t}(IPC_SIG_LEN)
        msg_bytes = collect(message)
        rc2 = ccall((:EVP_DigestSign, LIBCRYPTO), Cint,
                    (Ptr{Cvoid}, Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t),
                    mctx, sig, sig_len, msg_bytes, length(msg_bytes))
        rc2 == 1 || error("EVP_DigestSign failed: rc=$rc2")
        sig_len[] == IPC_SIG_LEN || error("unexpected sig len: $(sig_len[])")
        return sig
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

Generates the per-startup Ed25519 keypair, writes raw private
to VERIFY_PRIV (mode 0600) and raw public to VERIFY_PUB (mode
0644). Holds the EVP_PKEY in SIGNING_PKEY for in-process
signing.

Honest scope: keys are software-stored on disk. Same-UID
attackers can read VERIFY_PRIV. TPM/Secure-Enclave key
binding is the future defense; deferred.
"""
function generate_startup_keypair!()
    priv = rand(RandomDevice(), UInt8, IPC_KEY_LEN)
    SIGNING_PKEY[] = evp_pkey_from_priv(priv)
    pub = get_raw_public(SIGNING_PKEY[])

    open(VERIFY_PRIV, "w") do io
        write(io, priv)
    end
    chmod(VERIFY_PRIV, 0o600)

    open(VERIFY_PUB, "w") do io
        write(io, pub)
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

LL-042 v3 protocol handler. Reads 17 bytes from the client
(1-byte version 0x03 + 16-byte nonce), determines the cached
verify state, and writes 74 bytes back (1-byte version +
1-byte result + 8-byte LE timestamp + 64-byte Ed25519
signature over nonce ‖ result ‖ timestamp).

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
        sig = ed25519_sign(SIGNING_PKEY[], signed_message)

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
    delete_verify_priv()
    delete_verify_pub()

    # Generate the per-startup Ed25519 keypair used for LL-042
    # asymmetric signing. Private key written mode 0600
    # (daemon-UID readable), public key written mode 0644
    # (world-readable — clients verify with public key only).
    generate_startup_keypair!()

    # Robust cleanup: runs on any process exit (SIGINT, SIGTERM,
    # SIGHUP, normal return, uncaught exception). Without this,
    # a daemon killed mid-sleep leaves stale files that fool
    # downstream consumers into believing the daemon is alive —
    # exactly the failure mode we never want.
    Base.atexit(delete_heartbeat)
    Base.atexit(delete_verify_socket)
    Base.atexit(delete_verify_priv)
    Base.atexit(delete_verify_pub)
    Base.atexit(free_signing_pkey!)

    println("LavaLamp daemon")
    println("  Heartbeat file         : $HEARTBEAT_FILE")
    println("  Verify-result socket   : $VERIFY_SOCKET   (LL-040)")
    println("  Ed25519 private key    : $VERIFY_PRIV     (LL-042, mode 0600)")
    println("  Ed25519 public key     : $VERIFY_PUB      (LL-042, mode 0644)")
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
