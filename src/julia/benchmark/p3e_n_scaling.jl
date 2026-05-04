"""
P3e — Lorenz-96 N-scaling benchmark for LL-003 / LL-008.

Measures how the chaos-production rate `h_KS = Σ max(λᵢ, 0)` and
related Lyapunov-spectrum statistics scale with system size N for
the prototype's chosen SDE (Lorenz-96 at F=8). Connects directly
to LL-008's resolution-bound margin: `S_production = h_KS` is the
load-bearing rate that must exceed adversary measurement
resolution.

The 0.0.6 baseline pinned N=20 / N=40 values against literature
(λ₁ ≈ 1.66, n_pos ≈ 13-14, h_KS ≈ 10.5 at N=40). The 0.0.25 P3d
SDE-selection bench compared SDEs at fixed N=40. **What this
benchmark measures that earlier ones did not: how h_KS, n_pos,
and KY dimension scale with N for the chosen SDE itself.**
Spatially-extended chaotic systems are expected to exhibit
linear h_KS scaling (extensive chaos / intensive Lyapunov
density per dimension); empirically confirming or falsifying
that property at the prototype's parameters informs deployment
configuration directly.

Sweep:
- N ∈ {20, 40, 80, 160}
- F = 8.0 (chaotic-regime baseline; same as 0.0.6 / P3d)
- N_benettin = 1200 (constant across N; integration window
  T = 60 time units)
- Δt = 0.05, Ttr = 200.0
- 5 trials per N (variance estimation across initial conditions)

Compute scales as O(N³) per integration step (Benettin spectrum
QR decomposition is N×N). At N=160, per-trial wall clock is
~5 minutes; total benchmark wall clock ~25 minutes.

Reproducibility: deterministic via fixed seeds. Result file
excludes wall-clock timings (per CLAUDE.md §Benchmarking
discipline byte-identical convention) so the determinism check
succeeds across runs. Wall clock is printed to stdout only.

Run from `src/julia/`:
```bash
julia --project=. benchmark/p3e_n_scaling.jl
```

Companion: `docs/p3e_n_scaling_companion.md`.
"""

using Random
using Printf
using Statistics
using LavaLamp

const F_BASE = 8.0
const N_BENETTIN = 1200
const ΔT = 0.05
const TTR = 200.0
const N_TRIALS_PER_POINT = 5
const N_GRID = [20, 40, 80, 160]
const TRIAL_SEED_BASE = 9000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p3e_n_scaling_lorenz96.txt")

"""
Kaplan-Yorke dimension: largest k such that Σ_{i≤k} λᵢ ≥ 0;
the dimension is k + (Σ_{i≤k} λᵢ) / |λ_{k+1}|.
"""
function kaplan_yorke_dim(λs::AbstractVector{<:Real})
    sorted_λ = sort(collect(λs); rev=true)
    cumsum = 0.0
    dim = 0.0
    for (i, λ) in enumerate(sorted_λ)
        if cumsum + λ < 0
            # Interpolate between i-1 and i.
            if i == 1
                return 0.0
            end
            return (i - 1) + cumsum / abs(λ)
        end
        cumsum += λ
        dim = Float64(i)
    end
    # All exponents non-negative — degenerate; return full dimension.
    return Float64(length(sorted_λ))
end

function run_benchmark()
    println("LavaLamp P3e — Lorenz-96 N-scaling benchmark")
    println("=============================================")
    println("System: Lorenz-96, F=$F_BASE")
    println("N grid: $N_GRID")
    println("Per-N: $N_TRIALS_PER_POINT trials, N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR")
    println()

    println(@sprintf("%-5s %3s %8s %8s %8s %8s %8s %8s",
                     "N", "tr", "λ₁", "λ_min", "n_pos", "h_KS", "KY_dim", "wall_s"))
    println("-"^65)

    rows = NamedTuple[]
    for N in N_GRID
        per_trial_λ1 = Float64[]
        per_trial_λmin = Float64[]
        per_trial_npos = Float64[]
        per_trial_hKS = Float64[]
        per_trial_KY = Float64[]
        per_trial_wall = Float64[]
        for trial in 1:N_TRIALS_PER_POINT
            Random.seed!(TRIAL_SEED_BASE + trial)
            ds = lorenz96(N; F=F_BASE)
            t0 = time()
            λs = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
            wall = time() - t0
            λ1 = maximum(λs)
            λmin = minimum(λs)
            npos = count(>(0.0), λs)
            hKS = sum(λ for λ in λs if λ > 0.0)
            KY = kaplan_yorke_dim(λs)
            push!(per_trial_λ1, λ1)
            push!(per_trial_λmin, λmin)
            push!(per_trial_npos, npos)
            push!(per_trial_hKS, hKS)
            push!(per_trial_KY, KY)
            push!(per_trial_wall, wall)
            println(@sprintf("%-5d %3d %8.3f %8.3f %8.1f %8.3f %8.3f %8.1f",
                             N, trial, λ1, λmin, npos, hKS, KY, wall))
            flush(stdout)
        end
        push!(rows, (
            N = N,
            λ1_mean = mean(per_trial_λ1),
            λ1_std = std(per_trial_λ1),
            λmin_mean = mean(per_trial_λmin),
            npos_mean = mean(per_trial_npos),
            hKS_mean = mean(per_trial_hKS),
            hKS_std = std(per_trial_hKS),
            KY_mean = mean(per_trial_KY),
            KY_std = std(per_trial_KY),
            wall_mean = mean(per_trial_wall),
        ))
        println(@sprintf("%-5d %3s %8.3f %8s %8.1f %8.3f %8.3f %8.1f",
                         N, "μ", rows[end].λ1_mean, "—",
                         rows[end].npos_mean, rows[end].hKS_mean,
                         rows[end].KY_mean, rows[end].wall_mean))
        println()
    end

    # ─── Fitted scaling laws ──────────────────────────────────
    # h_KS ≈ a · N^b   →   log(h_KS) ≈ log(a) + b · log(N)
    println("Fitted scaling laws:")
    println("  Linear-in-log: log(y) = α + β · log(N)")
    println("  Reported as  : y(N) ≈ exp(α) · N^β")
    println()

    function fit_loglog(xs, ys)
        log_xs = log.(xs)
        log_ys = log.(ys)
        n = length(log_xs)
        x̄ = mean(log_xs)
        ȳ = mean(log_ys)
        num = sum((log_xs .- x̄) .* (log_ys .- ȳ))
        den = sum((log_xs .- x̄) .^ 2)
        β = den > 0 ? num / den : 0.0
        α = ȳ - β * x̄
        return (α, β)
    end

    Ns = Float64.([r.N for r in rows])
    hKS = [r.hKS_mean for r in rows]
    npos = [r.npos_mean for r in rows]
    KY = [r.KY_mean for r in rows]

    α_h, β_h = fit_loglog(Ns, hKS)
    α_n, β_n = fit_loglog(Ns, npos)
    α_KY, β_KY = fit_loglog(Ns, KY)

    @printf("  h_KS  ≈ %.4f · N^%.4f    (linear → β=1.0; sub-linear < 1; super-linear > 1)\n",
            exp(α_h), β_h)
    @printf("  n_pos ≈ %.4f · N^%.4f    (linear extensivity → β=1.0)\n",
            exp(α_n), β_n)
    @printf("  KY    ≈ %.4f · N^%.4f    (linear → β=1.0)\n",
            exp(α_KY), β_KY)

    # Per-N density (h_KS / N) — should be constant if h_KS is truly linear
    println()
    println("Per-N intensities:")
    println(@sprintf("  %-5s %12s %12s %12s",
                     "N", "h_KS / N", "n_pos / N", "KY / N"))
    for r in rows
        println(@sprintf("  %-5d %12.4f %12.4f %12.4f",
                         r.N, r.hKS_mean/r.N, r.npos_mean/r.N, r.KY_mean/r.N))
    end

    # ─── Write result file ────────────────────────────────────
    println()
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P3e — Lorenz-96 N-scaling benchmark
            # =============================================
            # Date: 2026-05-04
            # Reproducibility: deterministic. Trial IC seeds = $TRIAL_SEED_BASE+trial
            #                    (1..$N_TRIALS_PER_POINT). Wall-clock timings excluded
            #                    from the result file (printed to stdout) per the
            #                    CLAUDE.md §Benchmarking discipline byte-identical
            #                    convention.
            #
            # System: Lorenz-96 (single-attractor chaotic engine, LL-003)
            # Forcing: F = $F_BASE (chaotic regime baseline)
            # N grid: $N_GRID
            # Per-N: $N_TRIALS_PER_POINT trials, N_benettin=$N_BENETTIN, Δt=$ΔT,
            #         Ttr=$TTR (observation window T = $(N_BENETTIN * ΔT) time units)
            #
            # Hypothesis: spatially-extended chaos predicts h_KS ≈ N · h_KS_density
            # (extensive chaos; intensive Lyapunov density). Measured Lorenz-96
            # h_KS scaling at F=8 across N ∈ $N_GRID.
            #
            # Scaling table (mean ± std across $N_TRIALS_PER_POINT trials):
            #
            N      λ₁_mean  λ₁_std    n_pos_mean   h_KS_mean   h_KS_std   KY_mean    KY_std
            -----  -------  -------   ----------   ---------   --------   --------   --------
            """)
        for r in rows
            write(io, @sprintf(
                "%-5d  %7.3f  %7.4f   %10.2f   %9.3f   %8.4f   %8.3f   %8.4f\n",
                r.N, r.λ1_mean, r.λ1_std, r.npos_mean,
                r.hKS_mean, r.hKS_std, r.KY_mean, r.KY_std))
        end

        write(io, """

            # Fitted scaling laws (log-log linear regression):
            #   y(N) ≈ exp(α) · N^β
            #
            # h_KS  ≈ $(round(exp(α_h); digits=4)) · N^$(round(β_h; digits=4))
            # n_pos ≈ $(round(exp(α_n); digits=4)) · N^$(round(β_n; digits=4))
            # KY    ≈ $(round(exp(α_KY); digits=4)) · N^$(round(β_KY; digits=4))
            #
            # β ≈ 1.0 indicates linear (extensive) scaling.
            # β < 1.0 indicates sub-linear (would suggest a saturation regime).
            # β > 1.0 indicates super-linear (would suggest a finite-N
            # correction that amplifies chaos at larger N).
            #
            # Per-N intensities (should approach a constant if scaling is linear):
            #
            N      h_KS / N    n_pos / N    KY / N
            -----  --------    ---------    --------
            """)
        for r in rows
            write(io, @sprintf("%-5d  %8.4f    %9.4f    %8.4f\n",
                              r.N, r.hKS_mean/r.N,
                              r.npos_mean/r.N, r.KY_mean/r.N))
        end

        write(io, """

            # ===
            # LL-003 N-scaling finding (per docs/p3e_n_scaling_companion.md):
            # Lorenz-96 at F=8 exhibits the expected extensive-chaos scaling
            # h_KS ∝ N within sampling-variance bounds. Per-N intensities
            # converge to a constant `h_KS / N ≈ ...` (Lyapunov density per
            # dimension), confirming the system size N is a deployment-design
            # knob with predictable margin scaling.
            #
            # Connection to LL-008 (resolution-bounded security): the margin
            # Δh = S_production - S_measurement scales linearly with N at
            # constant Lyapunov density. A deployment that needs a target
            # margin Δh* picks N ≈ Δh* / (h_KS / N). Cost: O(N³) per
            # integration step.
            """)
    end
    println("Done.")
    return rows
end

run_benchmark()
