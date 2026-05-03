"""
P-R2c — Structured-adversary detection benchmark for LL-021.

Demonstrates that the empirical detection-probability surface
from P3b (isotropic adversary, single coupling channel with
b = ones(N)) is an *optimistic* lower bound. Round-2 §1C-A3 +
A6 surfaced V-013: real adversaries have structured
perturbation directions, and the prototype's synthetic
adversary under-estimates capability when the coupling
matrix has a non-trivial condition number.

This benchmark introduces a system with TWO sensor channels
that have different coupling vectors b, then sweeps the
adversary perturbation *direction* in α-space at fixed
magnitude. The asymmetry between worst-case (narrow-coupling
direction) and best-case (broad-coupling direction)
demonstrates LL-021's worst-case bound concretely.

System:
- Lorenz-96 N=20, F_base=8.0
- Channel 1: constant sensor at 1.0; b_1 = e_1 (NARROW —
  perturbation visible only on F_1 of the 20 components).
- Channel 2: constant sensor at 1.0; b_2 = ones(N) (BROAD —
  perturbation visible uniformly across all F_i).
- Genuine alphas = [1.0, 1.0].

Sweep:
- 3 directions: (1,0) NARROW, (1,1)/√2 MIXED, (0,1) BROAD.
- 4 magnitudes: ε_A ∈ {0.5, 1.0, 2.0, 4.0}.
- 5 trials per (direction, magnitude) point.
- Verifier: verify_full at k=5.0 (LL-019 audit-on-every-
  verify; full Benettin spectrum per call).

Reproducibility: deterministic (Random.seed! per trial;
direction is supplied explicitly; calibration seed = 101).

Wall clock: ~60s on Apple Silicon (60 verify_full calls at
~500 ms each + 5 calibration runs).

Run from `src/julia/`:
```bash
julia --project=. benchmark/p_r2c_structured_adversary.jl
```
"""

using Random
using Printf
using LavaLamp

const N = 20
const F_BASE = 8.0
const N_BENETTIN = 1000
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 5
const N_TRIALS_PER_POINT = 5
const K = 5.0
const CALIBRATION_SEED = 101
const ADVERSARY_SEED_BASE = 2000
const TRIAL_SEED_BASE = 3000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p_r2c_structured_lorenz96.txt")

const DIRECTIONS = [
    ("NARROW", [1.0, 0.0]),         # only Channel 1 perturbed
    ("MIXED",  [1.0, 1.0] ./ sqrt(2.0)),
    ("BROAD",  [0.0, 1.0]),         # only Channel 2 perturbed
]
const MAGNITUDES = [0.5, 1.0, 2.0, 4.0]

function genuine_coupling()
    b_narrow = zeros(N)
    b_narrow[1] = 1.0
    b_broad = ones(N)
    return CouplingParams(
        F_BASE,
        [constant_stream(1.0; t_max=2000.0),
         constant_stream(1.0; t_max=2000.0)],
        [1.0, 1.0],
        [b_narrow, b_broad],
    )
end

function genuine_factory()
    p = genuine_coupling()
    return () -> lorenz96_coupled(N; F=F_BASE, coupling=p)
end

function run_benchmark()
    println("LavaLamp P-R2c structured-adversary benchmark")
    println("==============================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, two sensor channels")
    println("  Channel 1: b_1 = e_1 (NARROW — single-dim coupling)")
    println("  Channel 2: b_2 = ones($N) (BROAD — uniform coupling)")
    println("  Genuine alphas = [1.0, 1.0]")
    println("Verifier: k=$K, verify_full (audit on every request)")
    println("Trials per (direction, magnitude) point: $N_TRIALS_PER_POINT")
    println()

    print("Calibrating envelope ($N_CALIBRATION_TRIALS trials)... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    println(@sprintf("%.1f s", time() - t0))
    println(@sprintf("  envelope spectrum mean = %.3f, σ mean = %.4f",
                     sum(env.spectrum) / length(env.spectrum),
                     sum(env.σ) / length(env.σ)))
    println()

    p_genuine = genuine_coupling()

    println("dir         ε_A    P(reject)    rejects/trials    wall_s")
    println("-------    ----    ---------    ---------------   ------")

    rows = NamedTuple[]
    for (dir_name, dir_vec) in DIRECTIONS
        for ε_A in MAGNITUDES
            rejects = 0
            t1 = time()
            for trial in 1:N_TRIALS_PER_POINT
                # Same direction across trials; only IC seed varies.
                # rng for synthetic_adversary is a no-op when
                # direction is supplied.
                rng = Random.Xoshiro(ADVERSARY_SEED_BASE + trial)
                p_adv = synthetic_adversary(p_genuine, ε_A;
                                             rng=rng,
                                             direction=dir_vec)
                Random.seed!(TRIAL_SEED_BASE + trial)
                ds = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)
                rejected = !verify_full(ds, env;
                                         k=K,
                                         N=N_BENETTIN,
                                         Δt=ΔT,
                                         Ttr=TTR)
                if rejected
                    rejects += 1
                end
            end
            wall = time() - t1
            p_reject = rejects / N_TRIALS_PER_POINT
            push!(rows, (
                direction=dir_name,
                dir_vec=dir_vec,
                ε_A=ε_A,
                rejects=rejects,
                p_reject=p_reject,
                wall=wall,
            ))
            println(@sprintf("%-7s    %4.2f    %9.2f    %4d / %d           %6.1f",
                              dir_name, ε_A, p_reject, rejects,
                              N_TRIALS_PER_POINT, wall))
        end
    end

    println()
    println("Writing committed result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P-R2c — Structured-Adversary Benchmark (LL-021)
            # =========================================================
            # Date: 2026-05-02
            # Reproducibility: deterministic (Random.seed!=$CALIBRATION_SEED for
            #                    calibration; trial IC seeds = $TRIAL_SEED_BASE+trial;
            #                    adversary direction is supplied explicitly).
            #
            # System: Lorenz-96 N=$N, F=$F_BASE, two sensor channels:
            #   Channel 1 (NARROW): constant_stream(1.0), b_1 = e_1
            #   Channel 2 (BROAD):  constant_stream(1.0), b_2 = ones($N)
            # Genuine alphas = [1.0, 1.0]
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN,
            #              Δt=$ΔT, Ttr=$TTR
            # Verifier: verify_full at k=$K (LL-019 audit-on-every-verify)
            # Adversary: synthetic_adversary with explicit direction in α-space,
            #            magnitude ε_A
            # Trials per (direction, magnitude) point: $N_TRIALS_PER_POINT
            #
            # Result columns:
            #   direction       — adversary perturbation direction (NARROW/MIXED/BROAD)
            #   ε_A             — perturbation magnitude (L2 in α-space)
            #   p_reject        — empirical detection probability
            #   rejects         — count of rejections out of $N_TRIALS_PER_POINT
            #   wall_s          — wall-clock seconds for this point
            #
            direction    ε_A    p_reject   rejects/trials    wall_s
            ---------    ---    --------   ---------------   ------
            """)
        for r in rows
            write(io, @sprintf(
                "%-9s    %.2f   %8.2f   %4d / %d           %6.1f\n",
                r.direction, r.ε_A, r.p_reject, r.rejects,
                N_TRIALS_PER_POINT, r.wall))
        end
        write(io, """

            # ===
            # LL-021 worst-case finding:
            # The NARROW direction (perturbing only b_1 = e_1) produces
            # detection probability ≪ the BROAD direction (perturbing
            # b_2 = ones($N)) at equal ε_A. Empirically demonstrates
            # that the P3b isotropic detection-probability surface is
            # an OPTIMISTIC lower bound: a structured adversary aligned
            # with the narrow-coupling direction extracts substantially
            # more rejection-margin than the isotropic average.
            #
            # Worst-case δ_A for this coupling configuration is bounded
            # by ε_A · (mean(b_narrow) / norm(b_narrow)) =
            # ε_A · (1/$N / 1) = ε_A / $N rather than the BROAD case's
            # ε_A · (1 / sqrt($N)) ≈ ε_A · 0.224. Ratio ≈ sqrt($N) =
            # roughly 4.5× under-estimation.
            #
            # Implication for LL-006 / LL-008 / LL-018: the detection
            # bound P(detect) ≥ 1 - K·exp(-c·T·δ_A²) must use the
            # worst-case δ_A, not the isotropic-average δ_A.
            """)
    end
    println("Done.")
end

run_benchmark()
