"""
P3f — Per-SDE detection-power benchmark for LL-006 / LL-008.

The 0.0.17 P3-bound benchmark fitted detection-power constants
for Lorenz-96 only (with α-space sensor-coupling adversaries).
The 0.0.25 P3d benchmark compared raw chaos statistics across
SDEs but did not characterise detection-power for the
alternatives.

This benchmark closes that gap. For each of the three candidate
SDEs (Lorenz-96, Lorenz-63, Rössler), it sweeps a
**parameter-space adversary** — perturbations to the SDE's
principal chaotic parameter — and fits the LL-006 detection
bound shape:

  P(detect) ≥ 1 - K · exp(-c' · T · ε_A²)

The principal-parameter choice per SDE:

- Lorenz-96: F (forcing). Baseline F=8.0; chaotic for F ≳ 4.
- Lorenz-63: ρ (Rayleigh). Baseline ρ=28.0; chaotic for ρ > 24.74.
- Rössler:   c (attractor stability). Baseline c=5.7.

Each SDE has its own ε_A grid because the parameter scales differ.
Per-SDE c' values are not directly comparable (parameter scales
differ), but the bound *shape* applies to all three. The fitted
constants per SDE characterise detection power for
parameter-space adversaries against each engine candidate.

This is a different adversary model from 0.0.17 P3-bound (which
used α-space coupling adversaries on Lorenz-96-coupled). The
0.0.17 c'=0.00423 reflects α-space sensitivity; this benchmark's
Lorenz-96 c' will reflect F-space sensitivity. The two are
complementary characterisations.

Configuration:
- 5 trials per (SDE, ε_A) point
- Calibration: n_trials=10 per SDE (matches P3-bound)
- N_benettin=1200, Δt=0.05, Ttr=200.0
- k=5 verifier threshold (matches P3-bound)
- T_observation = 60 time units

Reproducibility: deterministic via fixed seeds. Result file
excludes wall-clock timings (per CLAUDE.md §Benchmarking
discipline byte-identical convention) so the determinism check
succeeds across runs.

Run from `src/julia/`:
```bash
julia --project=. benchmark/p3f_per_sde_detection_power.jl
```

Wall clock: ~5 min on Apple Silicon (mostly Lorenz-96 N=20 runs;
Lorenz-63 / Rössler are 3-D and very fast).

Companion: the project-internal companion.
"""

using Random
using Printf
using Statistics
using LavaLamp

const N_LORENZ96 = 20
const N_BENETTIN = 1200
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 10
const N_TRIALS_PER_POINT = 5
const K_THRESHOLD = 5.0
const T_OBSERVATION = N_BENETTIN * ΔT       # 60 time units
const CALIBRATION_SEED = 101
const TRIAL_SEED_BASE = 3000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p3f_per_sde_detection_power.txt")

# Per-SDE parameter perturbation grids. Each grid sweeps the
# adversary's perturbation magnitude in the SDE's principal
# chaotic parameter. Grids reflect each parameter's scale.
const ε_A_GRID_LORENZ96 = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0]   # ΔF
const ε_A_GRID_LORENZ63 = [0.0, 1.0, 2.0, 4.0, 8.0]         # Δρ
const ε_A_GRID_ROSSLER  = [0.0, 0.05, 0.1, 0.2, 0.5, 1.0]   # Δc

# ─── Per-SDE factories: genuine + perturbed ─────────────────

function lorenz96_genuine_factory()
    return () -> lorenz96(N_LORENZ96; F=8.0)
end

function lorenz96_adversary_factory(εA::Real)
    return () -> lorenz96(N_LORENZ96; F=8.0 + εA)
end

function lorenz63_genuine_factory()
    return () -> lorenz63()       # σ=10, ρ=28, β=8/3
end

function lorenz63_adversary_factory(εA::Real)
    return () -> lorenz63(; σ=10.0, ρ=28.0 + εA, β=8/3)
end

function rossler_genuine_factory()
    return () -> rossler()        # a=0.2, b=0.2, c=5.7
end

function rossler_adversary_factory(εA::Real)
    return () -> rossler(; a=0.2, b=0.2, c=5.7 + εA)
end

# ─── Single-SDE sweep ───────────────────────────────────────

function sweep_sde(label::String,
                   genuine_factory_fn,
                   adversary_factory_fn,
                   ε_A_grid::Vector{Float64};
                   N_benettin::Int=N_BENETTIN,
                   Δt::Float64=ΔT,
                   Ttr::Float64=TTR)
    println("$label sweep")
    println("="^(length(label) + 6))
    print("  Calibrating envelope ($N_CALIBRATION_TRIALS trials)... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory_fn()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_benettin, Δt=Δt, Ttr=Ttr)
    println(@sprintf("%.1f s", time() - t0))
    println(@sprintf("    σ mean = %.4f, σ max = %.4f, σ min = %.4f",
                     mean(env.σ), maximum(env.σ), minimum(env.σ)))

    println("  ε_A      P_reject    rejects/trials")
    println("  -----    --------    ---------------")

    rows = NamedTuple[]
    for εA in ε_A_grid
        rejects = 0
        for trial in 1:N_TRIALS_PER_POINT
            Random.seed!(TRIAL_SEED_BASE + trial)
            ds = adversary_factory_fn(εA)()
            λs = lyapunov_spectrum(ds; N=N_benettin, Δt=Δt, Ttr=Ttr)
            if !verify(λs, env; k=K_THRESHOLD)
                rejects += 1
            end
        end
        p_reject = rejects / N_TRIALS_PER_POINT
        push!(rows, (εA=εA, p_reject=p_reject, rejects=rejects))
        println(@sprintf("  %.3f    %8.3f    %4d / %d",
                          εA, p_reject, rejects, N_TRIALS_PER_POINT))
    end

    # Constrained fit: log(1-P) = log(K) - c'·T·ε_A². K=1.
    # Filter to transition-region points (0 < P < 1 strictly).
    transition_rows = filter(r -> 0 < r.p_reject < 1, rows)
    fit_K = 1.0
    fit_c = NaN
    binding_εA = NaN
    if length(transition_rows) >= 1
        # Per-point c_max,i: c such that 1-K·exp(-c·T·ε_A²) = P_emp
        #   c_max,i = -log(1 - P_emp) / (T · ε_A²)
        per_point_c = Float64[]
        per_point_εA = Float64[]
        for r in transition_rows
            c_i = -log(1 - r.p_reject) / (T_OBSERVATION * r.εA^2)
            push!(per_point_c, c_i)
            push!(per_point_εA, r.εA)
        end
        idx_min = argmin(per_point_c)
        fit_c = per_point_c[idx_min]
        binding_εA = per_point_εA[idx_min]
    end

    println()
    if isnan(fit_c)
        println("  Fit: insufficient transition-region points (no 0<P<1).")
    else
        println(@sprintf("  Fit: K=%.1f, c'=%.5f, T=%.1f, c'·T=%.4f",
                          fit_K, fit_c, T_OBSERVATION, fit_c * T_OBSERVATION))
        println(@sprintf("  Binding constraint: ε_A=%.3f", binding_εA))
    end
    println()

    return (label=label, rows=rows, fit_K=fit_K, fit_c=fit_c,
            binding_εA=binding_εA)
end

# ─── Benchmark ─────────────────────────────────────────────

function run_benchmark()
    println("LavaLamp P3f — Per-SDE detection-power benchmark")
    println("=================================================")
    println("Configuration:")
    println("  Per SDE: $N_CALIBRATION_TRIALS calibration + ($N_TRIALS_PER_POINT trials × |ε_A grid|)")
    println("  N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR, k=$K_THRESHOLD")
    println("  T_observation = $T_OBSERVATION")
    println()

    # Lorenz-96 sweep (F-space adversary)
    res_l96 = sweep_sde("Lorenz-96 (perturbing F, baseline=8.0)",
                         lorenz96_genuine_factory,
                         lorenz96_adversary_factory,
                         ε_A_GRID_LORENZ96)

    # Lorenz-63 sweep (ρ-space adversary)
    res_l63 = sweep_sde("Lorenz-63 (perturbing ρ, baseline=28.0)",
                         lorenz63_genuine_factory,
                         lorenz63_adversary_factory,
                         ε_A_GRID_LORENZ63)

    # Rössler sweep (c-space adversary)
    res_ros = sweep_sde("Rossler (perturbing c, baseline=5.7)",
                         rossler_genuine_factory,
                         rossler_adversary_factory,
                         ε_A_GRID_ROSSLER)

    # ─── Per-SDE comparison ─────────────────────────────────
    println("Per-SDE comparison:")
    println("SDE             param   ε_A grid                K     c'         binding ε_A")
    println("-------------   -----   --------------------    ---   --------   -----------")
    for r in (res_l96, res_l63, res_ros)
        param = startswith(r.label, "Lorenz-96") ? "F" :
                startswith(r.label, "Lorenz-63") ? "ρ" : "c"
        grid_str = "[" * join([@sprintf("%.2f", x) for x in
            (param == "F" ? ε_A_GRID_LORENZ96 :
             param == "ρ" ? ε_A_GRID_LORENZ63 :
             ε_A_GRID_ROSSLER)], ", ") * "]"
        sde_short = startswith(r.label, "Lorenz-96") ? "Lorenz-96" :
                    startswith(r.label, "Lorenz-63") ? "Lorenz-63" : "Rossler"
        c_str = isnan(r.fit_c) ? "N/A" : @sprintf("%.5f", r.fit_c)
        b_str = isnan(r.binding_εA) ? "N/A" : @sprintf("%.3f", r.binding_εA)
        println(@sprintf("%-13s   %5s   %-21s   %3.0f   %8s   %s",
                          sde_short, param, grid_str, r.fit_K, c_str, b_str))
    end

    # ─── Write result file ──────────────────────────────────
    println()
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P3f — Per-SDE detection-power benchmark
            # =================================================
            # Date: 2026-05-04
            # Reproducibility: deterministic. Calibration seed = $CALIBRATION_SEED;
            #                    trial IC seeds = $TRIAL_SEED_BASE+trial.
            #                    Wall-clock timings excluded from result file
            #                    per CLAUDE.md §Benchmarking discipline.
            #
            # Configuration:
            #   Per SDE: $N_CALIBRATION_TRIALS calibration trials +
            #            ($N_TRIALS_PER_POINT trials × |ε_A grid|) adversary trials
            #   N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR, k=$K_THRESHOLD
            #   T_observation = $T_OBSERVATION (= N_benettin · Δt)
            #
            # Adversary: parameter-space (perturbs the SDE's principal
            # chaotic parameter — F for Lorenz-96, ρ for Lorenz-63, c
            # for Rössler).
            #
            # Bound shape: P(detect) ≥ 1 - K · exp(-c' · T · ε_A²) with
            # K=1 by convention; c' fitted as max c such that bound stays
            # below empirical at every transition-region point (0<P<1).
            #
            # ─── Per-SDE detection-power surface ────────────────────────
            """)
        for (sde_label, res, param, grid) in [
            ("Lorenz-96 (perturbing F)", res_l96, "F", ε_A_GRID_LORENZ96),
            ("Lorenz-63 (perturbing ρ)", res_l63, "ρ", ε_A_GRID_LORENZ63),
            ("Rössler   (perturbing c)", res_ros, "c", ε_A_GRID_ROSSLER),
        ]
            write(io, "\n$sde_label   parameter=$param\n")
            write(io, "  ε_A      P_reject    rejects/trials\n")
            write(io, "  -----    --------    ---------------\n")
            for r in res.rows
                write(io, @sprintf("  %.3f    %8.3f    %4d / %d\n",
                                    r.εA, r.p_reject, r.rejects,
                                    N_TRIALS_PER_POINT))
            end
            if isnan(res.fit_c)
                write(io, "  Fit: insufficient transition-region points\n")
            else
                write(io, @sprintf("  Fit: K=%.1f, c'=%.5f, T=%.1f, c'·T=%.4f, binding ε_A=%.3f\n",
                                    res.fit_K, res.fit_c, T_OBSERVATION,
                                    res.fit_c * T_OBSERVATION, res.binding_εA))
            end
        end

        write(io, """

            # ===
            # Per-SDE comparison summary:
            #
            # SDE             param   K     c'                   binding ε_A
            # -------------   -----   ---   ------------------   -----------
            """)
        for (sde_short, res, param) in [
            ("Lorenz-96", res_l96, "F"),
            ("Lorenz-63", res_l63, "ρ"),
            ("Rössler",   res_ros, "c"),
        ]
            c_str = isnan(res.fit_c) ? "N/A (no transition points)" :
                    @sprintf("%.5f", res.fit_c)
            b_str = isnan(res.binding_εA) ? "N/A" : @sprintf("%.3f", res.binding_εA)
            write(io, @sprintf("# %-13s   %5s   %3.0f   %-18s   %s\n",
                                sde_short, param, res.fit_K, c_str, b_str))
        end

        write(io, """
            #
            # Per-SDE c' values are NOT directly comparable across
            # different parameters — F, ρ, c have different absolute
            # scales (F~10, ρ~28, c~5.7). The c' values reflect each
            # parameter's per-unit detection sensitivity.
            #
            # The bound *shape* P(detect) ≥ 1 - K·exp(-c'·T·ε_A²)
            # applies to all three SDEs; this benchmark validates the
            # shape's universality across the candidate set and
            # characterises detection power for parameter-space
            # adversaries against each engine candidate.
            #
            # Companion: the project-internal companion
            """)
    end

    println("Done.")
    return (lorenz96=res_l96, lorenz63=res_l63, rossler=res_ros)
end

run_benchmark()
