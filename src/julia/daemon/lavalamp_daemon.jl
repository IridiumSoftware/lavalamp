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
const VERIFY_SECRET = joinpath(HEARTBEAT_DIR, "verify.secret")

# ─── LL-040 + LL-041: daemon verify-result IPC channel ──────────
#
# A second cross-process channel beyond the LL-039 heartbeat:
# an AF_UNIX socket at $HEARTBEAT_DIR/verify.sock that exposes
# the *cached* verify_full result to authorised local clients
# (PharOS PAM module being the canonical consumer).
#
# Strict LL-002 amendment (LL-040): this channel CARRIES the
# verify Bool result, more than LL-039's existence-only bit.
# Justified by: (a) chmod 0600 restricts to owner UID;
# (b) AF_UNIX never traverses network; (c) cached not per-
# request, so no threshold-probing oracle (V-010); (d) one
# byte / three states.
#
# LL-041 anti-replay extension (v2 protocol):
#   - Daemon generates a 32-byte random secret on startup,
#     written to $HEARTBEAT_DIR/verify.secret (mode 0600).
#   - Both client and daemon use the secret to compute
#     HMAC-SHA256 over (nonce || result_byte || timestamp).
#   - Client sends 17-byte request: 1-byte version (0x02) +
#     16-byte random nonce.
#   - Daemon responds with 42-byte response: 1-byte version
#     (0x02) + 1-byte result + 8-byte LE timestamp + 32-byte
#     HMAC.
#   - Client validates: nonce embedded in HMAC matches the
#     nonce it sent (anti-replay) AND HMAC validates against
#     the shared secret (anti-forge MITM) AND timestamp is
#     fresh (within IPC_STALE_AFTER_S).
#
# Protocol negotiation: only v2 is supported in this build.
# v1 (1-byte response) is the LavaLamp v0.0.84 protocol;
# clients speaking v1 will get a malformed response and
# should fail closed.
#
# Threat model honest framing:
#   - Anti-replay defends against capture-and-replay attacks
#     (attacker observes one IPC exchange, replays the
#     captured response later).
#   - Anti-forge defends against same-process-tier attackers
#     who can connect to the socket but cannot read the
#     secret file.
#   - Same-UID attackers (i.e., attacker has the user's UID
#     or root) can read both the socket AND the secret, and
#     therefore can forge responses. This is the load-bearing
#     limit; same-UID attackers have already defeated the
#     security model.
#   - TPM-bound asymmetric signing (LL-022 strategy 1) would
#     defeat same-UID forgery; deferred to a future LL-NNN.

const IPC_STALE_AFTER_S = 120.0  # 2× the default 60s verify cadence
const IPC_VERSION = UInt8(0x02)
const IPC_REQUEST_LEN = 17    # 1 version + 16 nonce
const IPC_RESPONSE_LEN = 42   # 1 version + 1 result + 8 ts + 32 hmac
const IPC_NONCE_LEN = 16
const IPC_HMAC_LEN = 32
const IPC_SECRET_LEN = 32

# Pre-generated per-startup random secret. Re-rolled every
# time the daemon process starts; clients must re-read after
# daemon restarts.
const STARTUP_SECRET = Ref{Vector{UInt8}}(UInt8[])

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

function delete_verify_secret()
    try
        isfile(VERIFY_SECRET) && rm(VERIFY_SECRET; force=true)
    catch
    end
end

"""
    generate_startup_secret!()

Generates the 32-byte per-startup random secret and writes it
to VERIFY_SECRET with mode 0600. Called once at daemon start.
"""
function generate_startup_secret!()
    STARTUP_SECRET[] = rand(RandomDevice(), UInt8, IPC_SECRET_LEN)
    open(VERIFY_SECRET, "w") do io
        write(io, STARTUP_SECRET[])
    end
    chmod(VERIFY_SECRET, 0o600)
end

"""
    hmac_sha256(key, message) -> Vector{UInt8}

HMAC-SHA256 implementation built on stdlib SHA. Returns a
32-byte vector. Pure Julia, no external crypto deps.
"""
function hmac_sha256(key::AbstractVector{UInt8}, message::AbstractVector{UInt8})
    block_size = 64
    k = if length(key) > block_size
        collect(sha256(collect(key)))
    elseif length(key) < block_size
        vcat(collect(key), zeros(UInt8, block_size - length(key)))
    else
        collect(key)
    end
    o_key_pad = k .⊻ UInt8(0x5c)
    i_key_pad = k .⊻ UInt8(0x36)
    inner = sha256(vcat(i_key_pad, collect(message)))
    return collect(sha256(vcat(o_key_pad, collect(inner))))
end

"""
    encode_int64_le(n) -> Vector{UInt8}

Encodes a signed Int64 as 8 little-endian bytes. Used for
the timestamp field in v2 responses.
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

LL-041 v2 protocol handler. Reads 17 bytes from the client
(1-byte version + 16-byte nonce), determines the cached
verify state, and writes 42 bytes back (1-byte version +
1-byte result + 8-byte LE timestamp + 32-byte HMAC over
nonce||result||timestamp). Closes the connection.

Run in an @async task so multiple concurrent clients are
served. Bad protocol versions / short reads / write errors
just close the connection silently — the client will see
a short read or EOF and fail closed.
"""
function ipc_handle_client(client::IO)
    try
        # Read the v2 request header (timeout via channel-close
        # when daemon shuts down; otherwise block).
        request = read(client, IPC_REQUEST_LEN)
        if length(request) != IPC_REQUEST_LEN || request[1] != IPC_VERSION
            return  # close connection; client gets short read
        end
        nonce = request[2:1 + IPC_NONCE_LEN]

        # Determine result byte from cached state.
        age = time() - STATE.last_verify_ts
        result = if STATE.last_verify_ts == 0.0 || age > IPC_STALE_AFTER_S
            UInt8('S')
        elseif STATE.accepted
            UInt8('A')
        else
            UInt8('R')
        end

        # Build signed response.
        ts = Int64(round(time()))
        ts_bytes = encode_int64_le(ts)
        signed_message = vcat(nonce, [result], ts_bytes)
        mac = hmac_sha256(STARTUP_SECRET[], signed_message)

        response = vcat([IPC_VERSION, result], ts_bytes, mac)
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
    delete_verify_secret()

    # Generate the per-startup secret used for LL-041 anti-replay
    # HMAC. Re-rolled on every daemon restart; clients must
    # re-read the secret file after a restart.
    generate_startup_secret!()

    # Robust cleanup: runs on any process exit (SIGINT, SIGTERM,
    # SIGHUP, normal return, uncaught exception). Without this,
    # a daemon killed mid-sleep can leave a stale heartbeat,
    # socket, or secret file that fools downstream consumers
    # into believing the daemon is alive — exactly the failure
    # mode we never want.
    Base.atexit(delete_heartbeat)
    Base.atexit(delete_verify_socket)
    Base.atexit(delete_verify_secret)

    println("LavaLamp daemon")
    println("  Heartbeat file        : $HEARTBEAT_FILE")
    println("  Verify-result socket  : $VERIFY_SOCKET   (LL-040)")
    println("  HMAC secret file      : $VERIFY_SECRET   (LL-041 v2)")
    println("  Verify cadence        : every $VERIFY_CADENCE_SECONDS s")
    println("  Heartbeat cadence     : every $HEARTBEAT_CADENCE_SECONDS s")
    println("  Press Ctrl-C to stop (heartbeat + socket + secret cleaned up).")
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
