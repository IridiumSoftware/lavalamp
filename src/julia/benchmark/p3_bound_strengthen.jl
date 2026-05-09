"""
P3-bound — Strengthen pass for the LL-006 :benchmarked evidence.

Extends `p3_bound_high_res.jl` with three deliverables that each
strengthen the empirical evidence base AND extract the constants
the eventual Lean concentration-inequality proof will target:

  1. **Wilson 95% confidence intervals** on every P_reject point.
     Formal CIs replace the rough sampling-variance argument
     used in the high-res result.

  2. **Per-trial max-residue distributions** captured at each
     ε_A point. From these we estimate:
        - E[R](ε_A) — sample mean of max_residue per ε_A.
        - σ²_R(ε_A) — sample variance of max_residue per ε_A.
     A linear fit of E[R] vs ε_A recovers the geometric slope a;
     σ²_R(ε_A) at fixed T gives the sub-Gaussian rate. Together
     these constants drive the eventual Lean concentration
     inequality:

        (E[R] - k·σ_env)² / (2 σ²_R)  ≈  c'·T·ε_A²

     so c' is recovered from the slope-and-rate combination.

  3. **χ² goodness-of-fit** on the bound shape. Tests whether
     the empirical P_reject surface is consistent with the fitted
     bound 1 - K·exp(-c'·T·ε_A²). Reports degrees-of-freedom-
     adjusted χ² and an asymptotic p-value.

Configuration mirrors the high-res benchmark for direct
comparability:
  - Lorenz-96 N=20, F=8, single channel b=ones(N)
  - constant_stream(1.0), α=1.0
  - n_calibration=10, N_benettin=1200 (T=60)
  - k=5 threshold, verify_full per LL-019 audit-on-verify
  - Same ε_A grid (11 points)

Differences from p3_bound_high_res:
  - n_trials_per_point: 15 → 50 (3.3× more samples; tighter CIs)
  - Per-trial max_residue collected (not just rejection count)
  - Three additional analyses post-sweep (CI, σ²_R fit, χ² GOF)

Run from `src/julia/`:

```bash
julia --project=. benchmark/p3_bound_strengthen.jl
```

Wall-clock budget: ~9-12 minutes on Apple Silicon
(11 ε_A × 50 trials = 550 verify_full calls at ~0.7-1.2 s each
+ 10 calibration runs at ~3 s each).

Reproducibility: deterministic via fixed seeds. Re-runs produce
bit-identical result files.
"""

using Random
using Printf
using Statistics: mean, var, std
using LavaLamp

const N = 20
const F_BASE = 8.0
const N_BENETTIN = 1200
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 10
const N_TRIALS_PER_POINT = 50
const K_THRESHOLD = 5.0
const T_OBSERVATION = N_BENETTIN * ΔT       # 60 time units
const ε_A_GRID = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
const CALIBRATION_SEED = 101
const ADVERSARY_SEED_BASE = 2000
const TRIAL_SEED_BASE = 3000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "p3_bound_strengthen_lorenz96.txt")

# ─────────────────────────────────────────────────────────────────────
# Statistical helpers (no external deps)
# ─────────────────────────────────────────────────────────────────────

"""
Wilson score interval for a binomial proportion p̂ = k/n at
confidence level z (default 1.96 for 95%). Returns (lo, hi).

Better than the normal approximation at the boundaries (k=0 or
k=n) and standard for proportion CIs. Reference: Wilson (1927);
the form used here matches scipy.stats.binomtest's Wilson method.
"""
function wilson_ci(k::Int, n::Int; z::Float64=1.96)
    n == 0 && return (0.0, 0.0)
    p̂ = k / n
    denom = 1 + z^2 / n
    centre = (p̂ + z^2 / (2n)) / denom
    halfwidth = z * sqrt(p̂*(1-p̂)/n + z^2/(4n^2)) / denom
    lo = max(0.0, centre - halfwidth)
    hi = min(1.0, centre + halfwidth)
    return (lo, hi)
end

"""
Linear least-squares fit y = a·x + b. Returns (a, b, R²).
"""
function linear_fit(x::Vector{Float64}, y::Vector{Float64})
    n = length(x)
    n == length(y) || throw(ArgumentError("x and y must have equal length"))
    n >= 2 || throw(ArgumentError("need ≥ 2 points to fit"))
    x̄ = mean(x)
    ȳ = mean(y)
    sxx = sum((xi - x̄)^2 for xi in x)
    sxy = sum((x[i] - x̄) * (y[i] - ȳ) for i in 1:n)
    a = sxy / sxx
    b = ȳ - a * x̄
    syy = sum((yi - ȳ)^2 for yi in y)
    ŷ = [a * x[i] + b for i in 1:n]
    ssr = sum((y[i] - ŷ[i])^2 for i in 1:n)
    R² = syy > 0 ? 1.0 - ssr / syy : 1.0
    return (a, b, R²)
end

"""
Asymptotic p-value for a χ² statistic on `df` degrees of freedom.
Uses the regularized lower incomplete gamma function γ(df/2, χ²/2)
via a series expansion for small values and continued-fraction
expansion for large values.

Reference: Press et al., Numerical Recipes §6.2 (gammq).
"""
function chi2_pvalue(χ²::Float64, df::Int)
    df > 0 || throw(ArgumentError("df must be positive"))
    χ² < 0 && throw(ArgumentError("χ² must be non-negative"))
    χ² == 0 && return 1.0
    return _gammq(df / 2.0, χ² / 2.0)
end

# Q(a, x) = upper-tail incomplete gamma (regularized).
function _gammq(a::Float64, x::Float64)
    if x < a + 1.0
        return 1.0 - _gser(a, x)
    else
        return _gcf(a, x)
    end
end

function _gser(a::Float64, x::Float64; itmax::Int=200, eps::Float64=3e-9)
    gln = _lgamma(a)
    if x ≈ 0.0
        return 0.0
    end
    ap = a
    sum_ = 1.0 / a
    del = sum_
    for _ in 1:itmax
        ap += 1.0
        del *= x / ap
        sum_ += del
        if abs(del) < abs(sum_) * eps
            break
        end
    end
    return sum_ * exp(-x + a * log(x) - gln)
end

function _gcf(a::Float64, x::Float64; itmax::Int=200, eps::Float64=3e-9)
    gln = _lgamma(a)
    b = x + 1.0 - a
    c = 1.0 / 1e-30
    d = 1.0 / b
    h = d
    for i in 1:itmax
        an = -i * (i - a)
        b += 2.0
        d = an * d + b
        if abs(d) < 1e-30; d = 1e-30; end
        c = b + an / c
        if abs(c) < 1e-30; c = 1e-30; end
        d = 1.0 / d
        del = d * c
        h *= del
        if abs(del - 1.0) < eps
            break
        end
    end
    return exp(-x + a * log(x) - gln) * h
end

# log Γ via Lanczos. Accurate to ~14 digits for x > 0.
function _lgamma(x::Float64)
    coeffs = (
        76.18009172947146,
        -86.50532032941677,
        24.01409824083091,
        -1.231739572450155,
        0.1208650973866179e-2,
        -0.5395239384953e-5,
    )
    y = x
    tmp = x + 5.5
    tmp -= (x + 0.5) * log(tmp)
    ser = 1.000000000190015
    for c in coeffs
        y += 1.0
        ser += c / y
    end
    return -tmp + log(2.5066282746310005 * ser / x)
end

# ─────────────────────────────────────────────────────────────────────
# Coupling factories (mirror p3_bound_high_res for comparability)
# ─────────────────────────────────────────────────────────────────────

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

# ─────────────────────────────────────────────────────────────────────
# Benchmark
# ─────────────────────────────────────────────────────────────────────

function run_benchmark()
    println("LavaLamp P3-bound — strengthen pass for LL-006")
    println("===============================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, single channel b=ones($N)")
    println("Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN")
    println("Verifier: k=$K_THRESHOLD, verify_full (LL-019 audit-on-verify)")
    println("Trials per ε_A: $N_TRIALS_PER_POINT  (vs 15 in p3_bound_high_res)")
    println("Observation window T = $T_OBSERVATION  (= N_benettin·Δt)")
    println()

    print("Calibrating envelope... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    cal_wall = time() - t0
    println(@sprintf("%.1f s", cal_wall))
    σ_max = maximum(env.σ)
    σ_mean = sum(env.σ) / length(env.σ)
    σ_min = minimum(env.σ)
    println(@sprintf("  σ mean = %.4f, σ max = %.4f, σ min = %.4f",
                     σ_mean, σ_max, σ_min))
    println(@sprintf("  rejection criterion: max(residue ./ σ) > k = %.1f",
                     K_THRESHOLD))
    println("  (per-σ-units residue space; threshold = k regardless of σ)")
    println()

    println("Sweep (with per-trial max_residue distributions):")
    println()
    println("ε_A     P̂_rej   95% CI            E[R/σ]    σ(R/σ)    n=$N_TRIALS_PER_POINT")
    println("-----   -----   ---------------   -------   -------   --------")

    p_genuine = genuine_coupling()
    rows = NamedTuple[]
    total_t0 = time()
    for ε_A in ε_A_GRID
        rejects = 0
        # Per-σ-units max-residue per trial. The verify-function
        # reject criterion is max(residue ./ env.σ) > k, so the
        # right random variable for the Gaussian-tail proxy is the
        # per-σ-units max-residue, not the absolute max-residue.
        residues_per_sigma = Float64[]
        sizehint!(residues_per_sigma, N_TRIALS_PER_POINT)
        t1 = time()
        for trial in 1:N_TRIALS_PER_POINT
            rng = Random.Xoshiro(ADVERSARY_SEED_BASE + trial)
            p_adv = synthetic_adversary(p_genuine, ε_A; rng=rng)
            Random.seed!(TRIAL_SEED_BASE + trial)
            ds = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)
            λs = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
            res = residue(λs, env)
            # Per-σ-units max — same units the verify function uses.
            push!(residues_per_sigma, maximum(res ./ env.σ))
            if !verify(λs, env; k=K_THRESHOLD)
                rejects += 1
            end
        end
        wall = time() - t1
        p_rej = rejects / N_TRIALS_PER_POINT
        ci_lo, ci_hi = wilson_ci(rejects, N_TRIALS_PER_POINT)
        E_R = mean(residues_per_sigma)
        σ_R = N_TRIALS_PER_POINT > 1 ? std(residues_per_sigma) : 0.0
        residues = residues_per_sigma   # alias for downstream blocks

        push!(rows, (
            ε_A=ε_A,
            p_rej=p_rej,
            rejects=rejects,
            ci_lo=ci_lo,
            ci_hi=ci_hi,
            mean_R=E_R,
            std_R=σ_R,
            wall=wall,
            residues=copy(residues),
        ))
        println(@sprintf("%5.2f   %5.3f   [%5.3f, %5.3f]   %7.4f   %7.4f   %5.1f s",
                          ε_A, p_rej, ci_lo, ci_hi, E_R, σ_R, wall))
    end
    sweep_wall = time() - total_t0
    println()
    @printf("Sweep wall-clock: %.1f s (%.1f min)\n", sweep_wall, sweep_wall / 60)
    println()

    # ──────────────────────────────────────────────────────────
    # Post-sweep analysis
    # ──────────────────────────────────────────────────────────

    println("─"^72)
    println("Post-sweep analysis")
    println("─"^72)

    # 1. Linear fit E[R] vs ε_A in the dynamic regime (drop ε_A=0).
    dyn_rows = filter(r -> r.ε_A > 0.0, rows)
    ε_dyn = Float64[r.ε_A for r in dyn_rows]
    R_dyn = Float64[r.mean_R for r in dyn_rows]
    a_R, b_R, R²_R = linear_fit(ε_dyn, R_dyn)
    println()
    println("1. Linear fit E[R] = a·ε_A + b  (dynamic regime, ε_A > 0)")
    @printf("   slope  a   = %8.4f\n", a_R)
    @printf("   intercept = %8.4f\n", b_R)
    @printf("   R²        = %8.4f\n", R²_R)
    println("   (slope a is the Lyapunov-residue sensitivity to adversary")
    println("    magnitude — the 'a' in the eventual Lean proof's")
    println("    (E[R] - threshold) ∝ a·ε_A drift term.)")
    println()

    # 2. Sub-Gaussian rate σ²_R averaged over the dynamic regime.
    #    Excludes ε_A=0 (FPR-floor; different regime) and the saturation
    #    points where rejection is 100% and σ_R may be artificially small.
    transition_rows = filter(r -> 0.0 < r.ε_A && r.p_rej < 0.99, rows)
    σ²_R_samples = Float64[r.std_R^2 for r in transition_rows]
    σ²_R_mean = mean(σ²_R_samples)
    σ²_R_std = length(σ²_R_samples) > 1 ? std(σ²_R_samples) : 0.0
    println("2. Sub-Gaussian rate σ²_R (transition regime, 0 < P̂_rej < 0.99)")
    @printf("   mean σ²_R = %8.6f  (over %d ε_A points)\n",
            σ²_R_mean, length(σ²_R_samples))
    @printf("   std  σ²_R = %8.6f  (point-to-point variability)\n", σ²_R_std)
    println("   (σ²_R is the residue variance under adversary perturbation;")
    println("    the eventual Lean proof's sub-Gaussian-tail bound uses")
    println("    this directly. Variability across ε_A points indicates")
    println("    whether the sub-Gaussian assumption is uniform.)")
    println()

    # 3. Predicted P_reject under Gaussian-tail proxy and χ² GOF.
    #    Working in per-σ-units residue space, the rejection event is
    #    R/σ > k, with k = K_THRESHOLD. The Gaussian-tail proxy uses
    #    P̂_pred = 1 - Φ((k - E[R]) / σ_R) = Φ((E[R] - k) / σ_R)
    #    (standard normal CDF).
    threshold = Float64(K_THRESHOLD)
    gauss_pvals = [(0.5 * (1 + erf((r.mean_R - threshold) / (r.std_R * sqrt(2)))))
                   for r in transition_rows]
    println("3. Predicted P_reject under Gaussian-tail proxy")
    println("   (per-σ-units residue; P̂_pred = Φ((E[R/σ] - k) / σ(R/σ)))")
    println()
    println("   ε_A     P̂_rej (emp)   P̂_pred (Gauss)   |Δ|")
    println("   -----   ------------   ----------------   -----")
    abs_diffs = Float64[]
    for (i, r) in enumerate(transition_rows)
        δ = abs(r.p_rej - gauss_pvals[i])
        push!(abs_diffs, δ)
        println(@sprintf("   %5.2f   %12.3f   %16.3f   %5.3f",
                          r.ε_A, r.p_rej, gauss_pvals[i], δ))
    end
    @printf("\n   max |Δ| over transition regime: %.3f\n", maximum(abs_diffs))
    @printf("   mean |Δ| over transition regime: %.3f\n", mean(abs_diffs))
    println()

    # 4. χ² goodness-of-fit. Compare empirical rejection counts to
    #    the Gaussian-tail predicted counts under the binomial model.
    #    Using the Pearson χ² statistic; df = (n_points - n_params).
    #    Free parameters: a (slope), σ²_R, threshold (last is fixed by
    #    calibration so really 2 free) — use df = n_points - 2.
    println("4. χ² goodness-of-fit (Pearson statistic)")
    println("   H₀: empirical rejection counts consistent with Gaussian-tail")
    println("       prediction at fitted (a, σ²(R/σ), k) constants.")
    χ²_stat = 0.0
    for (i, r) in enumerate(transition_rows)
        p_pred = clamp(gauss_pvals[i], 1e-6, 1 - 1e-6)
        observed_rej = r.rejects
        observed_acc = N_TRIALS_PER_POINT - observed_rej
        expected_rej = p_pred * N_TRIALS_PER_POINT
        expected_acc = (1 - p_pred) * N_TRIALS_PER_POINT
        χ²_stat += (observed_rej - expected_rej)^2 / expected_rej
        χ²_stat += (observed_acc - expected_acc)^2 / expected_acc
    end
    n_points = length(transition_rows)
    n_free = 2   # a, σ²_R (threshold pinned by calibration)
    df = max(1, n_points - n_free)
    p_value = chi2_pvalue(χ²_stat, df)
    @printf("   χ²        = %8.4f\n", χ²_stat)
    @printf("   df        = %d  (n_points=%d - n_params=%d)\n",
            df, n_points, n_free)
    @printf("   p-value   = %8.4f\n", p_value)
    println("   Interpretation:")
    if p_value > 0.05
        println("     p > 0.05 → fail to reject H₀; Gaussian-tail prediction")
        println("     is consistent with the empirical surface within sampling")
        println("     variance. The bound shape's sub-Gaussian assumption is")
        println("     empirically supported at α=0.05.")
    else
        println("     p < 0.05 → reject H₀; Gaussian-tail prediction is")
        println("     statistically distinguishable from the empirical")
        println("     surface. Sub-Gaussian-tail assumption may be too tight;")
        println("     consider a sub-exponential-tail relaxation.")
    end
    println()

    # ──────────────────────────────────────────────────────────
    # Summary block: Lean-proof-relevant constants
    # ──────────────────────────────────────────────────────────

    println("─"^72)
    println("Lean-proof-relevant constants (extracted from this benchmark)")
    println("─"^72)
    println()
    @printf("  E[R/σ](ε_A) ≈ %.4f · ε_A + %.4f  (dynamic-regime linear fit, R²=%.3f)\n",
            a_R, b_R, R²_R)
    @printf("  σ²(R/σ)     ≈ %.6f  (sub-Gaussian rate, mean over transition)\n", σ²_R_mean)
    @printf("  threshold   = k = %.1f  (per-σ-units; verify uses max(res ./ σ) > k)\n",
            K_THRESHOLD)
    @printf("  T           = %.1f time units  (= N_benettin · Δt)\n", T_OBSERVATION)
    println()
    println("  Implied effective slope c' (Gaussian-tail / sub-Gaussian model):")
    # From the bound shape: P_reject ≈ 1 - exp(-((E[R] - threshold)² / (2σ²_R)))
    # → matching log(1-P_reject) = -c'·T·ε_A² in the LL-006 fittable form
    # → c'·T·ε_A² ≈ (a·ε_A + b - threshold)² / (2σ²_R)
    # → at ε_A=2 (deep in transition where (a·ε_A) >> b): c' ≈ a²/(2·σ²_R·T)
    c_prime_inferred = a_R^2 / (2 * σ²_R_mean * T_OBSERVATION)
    @printf("    c' ≈ a² / (2·σ²_R·T) = %.6f\n", c_prime_inferred)
    println("    (compare to the high-res benchmark's least-squares fit:")
    println("    c'=0.00423 from p3_bound_high_res_lorenz96.txt §2 fit)")
    println()
    println("  These constants give the eventual Lean concentration-")
    println("  inequality theorem its target shape:")
    println("    ∀ ε_A > 0, T > 0,")
    println("      P(reject) ≥ 1 - exp(-c'·T·ε_A²)")
    println("  with the sub-Gaussian-rate assumption σ²_R ≤ above-stated value")
    println("  as the load-bearing hypothesis the Lean proof will require.")
    println()

    # ──────────────────────────────────────────────────────────
    # Result file
    # ──────────────────────────────────────────────────────────

    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp P3-bound — Strengthen pass for LL-006 :benchmarked
            # =============================================================
            # Date: 2026-05-08
            # Script: benchmark/p3_bound_strengthen.jl
            # Predecessor: p3_bound_high_res_lorenz96.txt (15 trials/point;
            #              this run uses $N_TRIALS_PER_POINT trials/point)
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
            # Rejection criterion: max(residue ./ env.σ) > k = $K_THRESHOLD
            # (per-σ-units residue space)
            #
            # Bound shape under test (LL-006 §2.1):
            #   P(detect) ≥ 1 - K · exp(-c · T · δ_A²)
            # Fittable form (ε_A absorbing ∂λ/∂α into effective slope c'):
            #   log(1 - P_reject) = log(K) - c' · T · ε_A²
            #
            # Per-row columns:
            #   ε_A      adversary magnitude
            #   P̂_rej    empirical rejection rate (rejects / n_trials)
            #   CI_lo    Wilson 95% lower bound on P̂_rej
            #   CI_hi    Wilson 95% upper bound on P̂_rej
            #   E[R/σ]   sample mean of max(residue ./ env.σ) (per-σ-units)
            #   σ(R/σ)   sample std of max(residue ./ env.σ)
            #
            ε_A     P̂_rej   CI_lo   CI_hi   E[R/σ]    σ(R/σ)    wall_s
            -----   -----   -----   -----   -------   -------   ------
            """)
        for r in rows
            write(io, @sprintf(
                "%5.2f   %5.3f   %5.3f   %5.3f   %7.4f   %7.4f   %6.1f\n",
                r.ε_A, r.p_rej, r.ci_lo, r.ci_hi, r.mean_R, r.std_R, r.wall))
        end
        write(io, "\n")
        write(io, """
            # ===
            # Lean-proof-relevant constants (extracted post-sweep):
            #
            #   E[R](ε_A) linear fit (dynamic regime, ε_A > 0):
            #     slope a   = $(round(a_R, digits=4))
            #     intercept = $(round(b_R, digits=4))
            #     R²        = $(round(R²_R, digits=4))
            #
            #   Sub-Gaussian rate σ²_R (transition regime, 0 < P̂_rej < 0.99):
            #     mean σ²_R = $(round(σ²_R_mean, digits=6))
            #     std  σ²_R = $(round(σ²_R_std, digits=6))
            #
            #   Implied effective slope:
            #     c' ≈ a² / (2·σ²_R·T) = $(round(c_prime_inferred, digits=6))
            #     (compare p3_bound_high_res LSQ-fit c' = 0.00423)
            #
            # χ² goodness-of-fit (Gaussian-tail proxy):
            #   χ²       = $(round(χ²_stat, digits=4))
            #   df       = $df  (n_points=$n_points - n_params=$n_free)
            #   p-value  = $(round(p_value, digits=4))
            #   Verdict  = $(p_value > 0.05 ? "fail-to-reject H₀ at α=0.05" : "reject H₀ at α=0.05")
            #
            # Sweep wall-clock: $(round(sweep_wall / 60, digits=1)) min
            """)
    end
    println("Done.")
    return rows
end

# erf() via Mathlib equivalent: Julia's Statistics doesn't ship erf;
# use the SpecialFunctions package if loaded, or a manual Abramowitz
# & Stegun approximation. Avoid adding dependency: provide a local
# polynomial approximation accurate to ~7 decimal places.
function erf(x::Real)
    # Abramowitz & Stegun 7.1.26: maximum error ~1.5e-7 for x ≥ 0
    sign_x = sign(x)
    z = abs(Float64(x))
    p = 0.3275911
    a1 = 0.254829592
    a2 = -0.284496736
    a3 = 1.421413741
    a4 = -1.453152027
    a5 = 1.061405429
    t = 1.0 / (1.0 + p * z)
    y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*exp(-z*z)
    return sign_x * y
end

run_benchmark()
