"""
P3-Nyq — Nyquist adversary-rate benchmark for LL-005.

Architecture-design §2.4 / §3.6: sensor sampling rate
`f_sensor` and SDE integration rate `f_SDE` must satisfy a
Nyquist-like condition relative to the physical noise
bandwidth. Specifically: `f_SDE > 2·BW ∧ f_sensor > BW`.
An adversary at sub-Nyquist sensor sampling cannot reconstruct
the genuine sensor stream and therefore produces a
trajectory whose Lyapunov spectrum diverges from the
genuine envelope.

This benchmark validates the claim empirically. Construct a
genuine system with a gaussian_noise_stream at high sample
rate (f_genuine = 100 Hz). Construct adversaries that
*observe* the genuine stream at sub-Nyquist sample rate
f_adv, *interpolate* back to a continuous signal, and use
that low-pass-filtered reconstruction as their own sensor
input. Sweep f_adv and measure detection probability.

Expected behaviour: P(detect) ≈ FPR baseline for f_adv ≥
f_genuine (full-fidelity reconstruction); P(detect) rises
sigmoidally as f_adv falls below the SDE's effective sensor-
sampling bandwidth (1/Δt = 20 Hz at the prototype's settings).

System:
- Lorenz-96 N=20, F=8.0
- Single sensor channel: gaussian_noise_stream(σ=1.0,
  sample_rate=f_genuine=100 Hz)
- α = [1.0], b = ones(N) uniform coupling
- Verifier: verify_full at k=5.0 (LL-019 audit-on-every-verify)
- Calibration: n_trials=5 against the genuine stream

Sweep:
- f_adv ∈ {1, 2, 5, 10, 20, 50, 100} Hz
- 5 trials per f_adv point
- Total: 7 × 5 = 35 verify_full calls + 5 calibration runs

Run from `src/julia/`:
```bash
julia --project=. benchmark/p3_nyq_adversary_rate.jl
```

Wall clock: ~30s on Apple Silicon.

Reproducibility: deterministic via fixed seeds.
"""

using Random
using Printf
using LavaLamp

const N = 20
const F_BASE = 8.0
const F_GENUINE = 100.0          # genuine sensor sample rate (Hz)
const N_BENETTIN = 1000
const ΔT = 0.05                  # SDE integration step (effective f_SDE = 20 Hz)
const TTR = 200.0
const N_CALIBRATION_TRIALS = 5
const N_TRIALS_PER_POINT = 20
const K_THRESHOLD = 5.0
const T_OBSERVATION = N_BENETTIN * ΔT
const TRIAL_T_MAX = 200.0        # gaussian_noise_stream t_max; covers SDE integration window
const STREAM_SEED = 1001
const CALIBRATION_SEED = 2001
const TRIAL_SEED_BASE = 3001
const F_ADV_GRID = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p3_nyq_adversary_rate.txt")

# ─── Genuine system ────────────────────────────────────────

function genuine_stream()
    """The genuine sensor stream. Fixed across the entire
    benchmark — calibration sees it; the adversary observes
    a sub-Nyquist subsample of it."""
    return gaussian_noise_stream(1.0;
                                  sample_rate=F_GENUINE,
                                  t_max=TRIAL_T_MAX,
                                  rng=Random.Xoshiro(STREAM_SEED))
end

function genuine_coupling()
    s = genuine_stream()
    return CouplingParams(F_BASE, [s], [1.0], [ones(N)])
end

function genuine_factory()
    p = genuine_coupling()
    return () -> lorenz96_coupled(N; F=F_BASE, coupling=p)
end

# ─── Adversary: subsample + interpolate ────────────────────

function adversary_subsampled_stream(genuine::SensorStream,
                                      f_adv::Real)
    """The adversary samples the genuine stream at f_adv Hz
    and reconstructs via linear interpolation. Returns the
    reconstructed stream — which is the same shape as the
    genuine but low-pass-filtered at f_adv/2."""
    Δt_adv = 1.0 / f_adv
    t_first, t_last = genuine.times[1], genuine.times[end]
    t_sampled = collect(t_first:Δt_adv:t_last)
    # Append the endpoint if not exactly aligned
    if t_sampled[end] < t_last
        push!(t_sampled, t_last)
    end
    # Sample by evaluating (linear interpolation against the
    # original stream — this models the adversary's
    # measurement at f_adv).
    values_sampled = [evaluate(genuine, t) for t in t_sampled]
    return SensorStream(t_sampled, values_sampled)
end

function adversary_coupling(genuine_p::CouplingParams, f_adv::Real)
    s_adv = adversary_subsampled_stream(genuine_p.streams[1], f_adv)
    return CouplingParams(genuine_p.F_base,
                          [s_adv],
                          copy(genuine_p.alphas),
                          deepcopy(genuine_p.coupling_vectors))
end

# ─── Benchmark ─────────────────────────────────────────────

function run_benchmark()
    println("LavaLamp P3-Nyq adversary-rate benchmark (LL-005)")
    println("==================================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE")
    println("Genuine sensor: gaussian_noise_stream σ=1.0, f_genuine=$F_GENUINE Hz")
    println("SDE integration: Δt=$ΔT (effective f_SDE = $(round(1/ΔT; digits=2)) Hz)")
    println("Verifier k=$K_THRESHOLD; verify_full audit-on-every-verify")
    println("Calibration n_trials=$N_CALIBRATION_TRIALS; trials per f_adv = $N_TRIALS_PER_POINT")
    println()

    # Calibrate against genuine system
    print("Calibrating envelope against genuine stream... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    println(@sprintf("%.1f s", time() - t0))
    println(@sprintf("  spectrum mean = %.3f, σ mean = %.4f",
                     sum(env.spectrum)/length(env.spectrum),
                     sum(env.σ)/length(env.σ)))
    println()

    # Genuine self-acceptance baseline (FPR)
    print("Genuine self-acceptance trials (FPR baseline)... ")
    flush(stdout)
    p_genuine = genuine_coupling()
    rejects_genuine = 0
    for trial in 1:N_TRIALS_PER_POINT
        Random.seed!(TRIAL_SEED_BASE + trial)
        ds = lorenz96_coupled(N; F=F_BASE, coupling=p_genuine)
        rejected = !verify_full(ds, env;
                                 k=K_THRESHOLD,
                                 N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
        if rejected
            rejects_genuine += 1
        end
    end
    fpr = rejects_genuine / N_TRIALS_PER_POINT
    println(@sprintf("FPR = %d/%d = %.2f", rejects_genuine, N_TRIALS_PER_POINT, fpr))
    println()

    # Sweep f_adv
    println("f_adv (Hz)    P(reject)    rejects/trials    wall_s")
    println("----------    ---------    ---------------   ------")
    rows = NamedTuple[]
    for f_adv in F_ADV_GRID
        rejects = 0
        t1 = time()
        p_adv = adversary_coupling(p_genuine, f_adv)
        for trial in 1:N_TRIALS_PER_POINT
            Random.seed!(TRIAL_SEED_BASE + trial + 100)
            ds = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)
            rejected = !verify_full(ds, env;
                                     k=K_THRESHOLD,
                                     N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
            if rejected
                rejects += 1
            end
        end
        wall = time() - t1
        p_reject = rejects / N_TRIALS_PER_POINT
        push!(rows, (
            f_adv=f_adv,
            p_reject=p_reject,
            rejects=rejects,
            wall=wall,
        ))
        println(@sprintf("%9.2f     %8.2f    %4d / %d           %6.1f",
                          f_adv, p_reject, rejects, N_TRIALS_PER_POINT, wall))
    end

    println()
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P3-Nyq — Nyquist adversary-rate benchmark (LL-005)
            # ============================================================
            # Date: 2026-05-03
            # Reproducibility: deterministic. genuine stream seed = $STREAM_SEED;
            #                    calibration seed = $CALIBRATION_SEED;
            #                    trial IC seeds = $TRIAL_SEED_BASE+trial.
            #
            # System: Lorenz-96 N=$N, F=$F_BASE
            # Genuine sensor: gaussian_noise_stream(σ=1.0, sample_rate=$F_GENUINE Hz, t_max=$TRIAL_T_MAX)
            # SDE integration: Δt=$ΔT (effective f_SDE = $(round(1/ΔT; digits=2)) Hz)
            # Coupling: α=[1.0], b=ones($N)
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN, Ttr=$TTR
            # Verifier: verify_full at k=$K_THRESHOLD (LL-019 audit-on-every-verify)
            #
            # Adversary model: observes the genuine sensor stream at f_adv Hz
            # (uniformly-spaced samples), reconstructs via linear interpolation,
            # uses the reconstructed stream as the sensor input for their own
            # SDE run. The adversary's α, b, and SDE parameters are *identical*
            # to genuine — only the sensor sample rate differs.
            #
            # Genuine self-acceptance FPR baseline = $fpr (= $rejects_genuine/$N_TRIALS_PER_POINT)
            #
            # Trials per f_adv: $N_TRIALS_PER_POINT
            #
            f_adv (Hz)    P(reject)    rejects/trials    wall_s
            ----------    ---------    ---------------   ------
            """)
        for r in rows
            write(io, @sprintf(
                "%9.2f     %8.2f    %4d / %d           %6.1f\n",
                r.f_adv, r.p_reject, r.rejects, N_TRIALS_PER_POINT, r.wall))
        end
        write(io, """

            # ===
            # LL-005 Nyquist claim: f_SDE > 2·BW ∧ f_sensor > BW.
            # The prototype's effective f_SDE = $(round(1/ΔT; digits=2)) Hz; thermal-noise BW
            # is bounded by sensor electronics. With f_genuine = $F_GENUINE Hz the
            # genuine system saturates the SDE's view of sensor variation.
            #
            # An adversary at f_adv ≥ f_SDE = $(round(1/ΔT; digits=2)) Hz can reconstruct what
            # the SDE would have seen anyway (since the SDE only samples the
            # sensor at f_SDE = $(round(1/ΔT; digits=2)) Hz). Detection rate at f_adv ≥ f_SDE should
            # be at the FPR baseline.
            #
            # An adversary at f_adv < f_SDE loses information: their reconstructed
            # stream is low-pass-filtered at f_adv/2. Their SDE trajectory differs
            # from genuine because the sensor coupling now sees a different
            # (smoother) signal. Detection rate should rise.
            #
            # Empirical pattern: P(reject) at f_adv ≥ $(round(1/ΔT; digits=2)) Hz should match
            # FPR baseline; P(reject) at f_adv ≪ $(round(1/ΔT; digits=2)) Hz should approach 1.
            """)
    end
    println("Done.")
    return rows
end

run_benchmark()
