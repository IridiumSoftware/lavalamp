"""
P-R2c-high-res — Higher-resolution refresh of the structured-adversary
detection benchmark for LL-021.

The 0.0.18 :benchmarked fit (`docs/ll021_benchmarked_companion.md`)
used 5 trials per (direction, magnitude) point, which produced
Wilson 95% CIs of width ~0.43 around 0/5 sample frequencies and
~0.65 around 3/5. The fit's binding constraint was MIXED at
ε_A=1.0 with empirical 3/5=0.60 → c'=0.02777; the binding was
sample-variance-limited, not bound-shape-limited.

This script tightens the fit by extending to 15 trials per point
(matching the P3-bound :benchmarked-tier convention from
0.0.17). Same system / coupling / verifier / RNG-seed convention
as the original `p_r2c_structured_adversary.jl`; only
`N_TRIALS_PER_POINT` and the result-file path differ. Trials 1-5
will produce identical reject/accept decisions to the original
benchmark (same seeds); trials 6-15 are new.

Configuration:
- Lorenz-96 N=20, F_base=8.0, two sensor channels
  (NARROW: b_1=e_1; BROAD: b_2=ones(N))
- Genuine alphas = [1.0, 1.0]
- Calibration: n_trials=5, N_benettin=1000, Δt=0.05, Ttr=200.0
- Verifier: verify_full at k=5.0 (LL-019 audit-on-every-verify)
- Sweep: 3 directions × 4 magnitudes × 15 trials = 180
  verify_full calls

Reproducibility: deterministic via fixed seeds. Per CLAUDE.md
§Benchmarking discipline (added 2026-05-04), determinism check
is a discipline rule for brittle-precision benchmarks: run twice
and `diff` the result file before treating any unexpected
finding as a real result.

Wall clock: ~100s on Apple Silicon (180 verify_full calls at
~500 ms each + 5 calibration runs).

Run from `src/julia/`:
```bash
julia --project=. benchmark/p_r2c_structured_adversary_high_res.jl
```

Companion: `docs/ll021_high_res_companion.md`.
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
const N_TRIALS_PER_POINT = 15
const K = 5.0
const CALIBRATION_SEED = 101
const ADVERSARY_SEED_BASE = 2000
const TRIAL_SEED_BASE = 3000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p_r2c_structured_high_res_lorenz96.txt")

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
    println("LavaLamp P-R2c-high-res structured-adversary benchmark")
    println("======================================================")
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
            println(@sprintf("%-7s    %4.2f    %9.2f    %4d / %d          %6.1f",
                              dir_name, ε_A, p_reject, rejects,
                              N_TRIALS_PER_POINT, wall))
        end
    end

    println()
    println("Writing committed result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P-R2c-high-res — Structured-Adversary Benchmark (LL-021)
            # ==================================================================
            # Date: 2026-05-04
            # Reproducibility: deterministic (Random.seed!=$CALIBRATION_SEED for
            #                    calibration; trial IC seeds = $TRIAL_SEED_BASE+trial;
            #                    adversary direction is supplied explicitly).
            #
            # Higher-resolution refresh of `p_r2c_structured_adversary.jl`.
            # Same system / coupling / verifier / seeds; n=$N_TRIALS_PER_POINT
            # trials per point instead of n=5. Trials 1-5 reproduce the
            # original benchmark's outputs by construction; trials 6-15
            # are new evidence.
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
            #
            # Wall-clock timings are printed to stdout but excluded
            # from the result file so the determinism check
            # (per CLAUDE.md §Benchmarking discipline) succeeds
            # byte-identically across runs.
            #
            direction    ε_A    p_reject   rejects/trials
            ---------    ---    --------   ---------------
            """)
        for r in rows
            write(io, @sprintf(
                "%-9s    %.2f   %8.3f   %4d / %d\n",
                r.direction, r.ε_A, r.p_reject, r.rejects,
                N_TRIALS_PER_POINT))
        end
        write(io, """

            # ===
            # Refit and Wilson 95% CI analysis live in the
            # companion: docs/ll021_high_res_companion.md.
            #
            # Expected outcome shape (per ll021_benchmarked_companion.md
            # §2.5 follow-up note): Wilson CI width on 0/n sample
            # frequencies tightens from 0.43 (n=5) to ~0.21 (n=15),
            # giving sharper discrimination for the 3 negative-margin
            # points. The binding constraint may shift if the n=15
            # sample frequency at MIXED ε_A=1.0 differs materially
            # from 0.60.
            """)
    end
    println("Done.")
end

run_benchmark()
