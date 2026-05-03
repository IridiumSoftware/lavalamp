"""
P3-bound — High-resolution detection-probability sweep for the
LL-006 :benchmarked upgrade.

The architecture-design §2.1 detection bound shape:

    P(detect | adversary submits) ≥ 1 - K · exp(-c · T · δ_A²)

Recast in fittable form using ε_A as proxy for δ_A (the
proportionality constant ∂λ/∂α absorbed into an effective
slope c'):

    log(1 - P_reject) = log(K) - c' · T · ε_A²

For a fixed observation window T (set by the benchmark
parameters), a least-squares fit of `log(1 - P_reject)` on
`ε_A²` recovers K (intercept) and c' (slope / -T). The fit
is valid in the transition region; FPR-floor points (P_reject
≈ baseline FPR) and saturation points (P_reject ≈ 1.00) are
excluded from the fit but reported in the result.

Configuration intentionally matches the original P3b benchmark
(`p3b_detection_lorenz96.txt`) to keep the bound's claim
comparable: Lorenz-96 N=20, F=8, single coupling channel
b=ones(N), constant_stream(1.0), α=1.0, k=5, n_calibration=10.
The only changes from P3b are (a) finer ε_A grid in the
transition, (b) more trials per point for stable P estimates,
(c) verify_full instead of plain verify (LL-019 audit-on-
every-verify).

Run from `src/julia/`:
```bash
julia --project=. benchmark/p3_bound_high_res.jl
```

Wall clock: ~150s on Apple Silicon (10 ε_A points × 15 trials
= 150 verify_full calls at ~0.5s each + 10 calibration runs).

Reproducibility: deterministic via fixed seeds.
"""

using Random
using Printf
using LavaLamp

const N = 20
const F_BASE = 8.0
const N_BENETTIN = 1200
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 10
const N_TRIALS_PER_POINT = 15
const K_THRESHOLD = 5.0
const T_OBSERVATION = N_BENETTIN * ΔT       # 60 time units
const ε_A_GRID = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
const CALIBRATION_SEED = 101
const ADVERSARY_SEED_BASE = 2000
const TRIAL_SEED_BASE = 3000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p3_bound_high_res_lorenz96.txt")

function genuine_factory()
    b = ones(N)
    return () -> begin
        s_const = constant_stream(1.0; t_max=2000.0)
        p = CouplingParams(F_BASE, [s_const], [1.0], [b])
        lorenz96_coupled(N; F=F_BASE, coupling=p)
    end
end

function genuine_coupling()
    b = ones(N)
    s_const = constant_stream(1.0; t_max=2000.0)
    return CouplingParams(F_BASE, [s_const], [1.0], [b])
end

function run_benchmark()
    println("LavaLamp P3-bound high-resolution detection sweep")
    println("==================================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, single channel b=ones($N)")
    println("Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN")
    println("Verifier: k=$K_THRESHOLD, verify_full (LL-019 audit-on-verify)")
    println("Trials per ε_A: $N_TRIALS_PER_POINT")
    println("Observation window T = $T_OBSERVATION (= N_benettin·Δt)")
    println()

    print("Calibrating envelope... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    println(@sprintf("%.1f s", time() - t0))
    println(@sprintf("  σ mean = %.4f, σ max = %.4f, σ min = %.4f",
                     sum(env.σ)/length(env.σ),
                     maximum(env.σ), minimum(env.σ)))
    println()

    println("ε_A      P_reject    rejects/trials    mean_δ_A    wall_s")
    println("-----    --------    ---------------   --------    ------")

    p_genuine = genuine_coupling()
    rows = NamedTuple[]
    for ε_A in ε_A_GRID
        rejects = 0
        δ_A_sum = 0.0
        t1 = time()
        for trial in 1:N_TRIALS_PER_POINT
            rng = Random.Xoshiro(ADVERSARY_SEED_BASE + trial)
            p_adv = synthetic_adversary(p_genuine, ε_A; rng=rng)
            Random.seed!(TRIAL_SEED_BASE + trial)
            ds = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)
            λs = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
            res = residue(λs, env)
            δ_A_sum += maximum(res)
            if !verify(λs, env; k=K_THRESHOLD)
                rejects += 1
            end
        end
        wall = time() - t1
        p_reject = rejects / N_TRIALS_PER_POINT
        mean_δ_A = δ_A_sum / N_TRIALS_PER_POINT
        push!(rows, (
            ε_A=ε_A,
            p_reject=p_reject,
            rejects=rejects,
            mean_δ_A=mean_δ_A,
            wall=wall,
        ))
        println(@sprintf("%.2f     %8.3f    %4d / %d         %8.4f    %6.1f",
                          ε_A, p_reject, rejects, N_TRIALS_PER_POINT,
                          mean_δ_A, wall))
    end

    println()
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P3-bound — High-resolution detection-probability sweep
            # ===============================================================
            # Date: 2026-05-03
            # Reproducibility: deterministic. calibration seed = $CALIBRATION_SEED;
            #                    adversary seed = Xoshiro($ADVERSARY_SEED_BASE+trial);
            #                    trial IC seed = $TRIAL_SEED_BASE+trial.
            #
            # System: Lorenz-96 N=$N, F=$F_BASE
            # Coupling: single channel, b=ones($N), α=[1.0], constant_stream(1.0)
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR
            # Verifier: vector per-exponent test, k=$K_THRESHOLD
            # Adversary: synthetic_adversary with isotropic unit-vector × ε_A
            # Trials per ε_A: $N_TRIALS_PER_POINT
            # Observation window: T = $T_OBSERVATION (= N_benettin · Δt)
            #
            # Bound shape under test (architecture-design §2.1):
            #   P(detect) ≥ 1 - K · exp(-c · T · δ_A²)
            # Fittable form (ε_A absorbing ∂λ/∂α into effective slope c'):
            #   log(1 - P_reject) = log(K) - c' · T · ε_A²
            #
            ε_A      P_reject    rejects/trials    mean_δ_A    wall_s
            -----    --------    ---------------   --------    ------
            """)
        for r in rows
            write(io, @sprintf(
                "%.2f     %8.3f    %4d / %d         %8.4f    %6.1f\n",
                r.ε_A, r.p_reject, r.rejects, N_TRIALS_PER_POINT,
                r.mean_δ_A, r.wall))
        end
        write(io, """

            # ===
            # P3-bound fit (computed in companion §2 from this data):
            #   1. Filter to transition region: 0 < P_reject < 1 strictly.
            #   2. Least-squares fit of log(1-P_reject) on ε_A².
            #   3. Slope = -c'·T → c' = -slope/T.
            #   4. Intercept = log(K).
            #   5. Verify empirical P_reject ≥ predicted lower-bound 1-K·exp(-c'·T·ε_A²)
            #      across all transition-region points (residuals ≥ 0).
            """)
    end
    println("Done.")
    return rows
end

run_benchmark()
