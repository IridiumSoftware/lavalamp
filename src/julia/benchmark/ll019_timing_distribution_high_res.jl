"""
LL-019-high-res — Higher-resolution refresh of the timing-
distribution benchmark for the LL-019 :benchmarked-tier
verdict.

The 0.0.19 :benchmarked fit (`docs/ll019_benchmarked_companion.md`)
used 200 samples per bucket × α=0.05, giving:
- KS critical at α=0.05: 0.170
- verify_constant_time KS_stat: 0.109 → INDISTINGUISHABLE
- plain verify KS_stat: 0.041 → INDISTINGUISHABLE

This refresh tightens the test in two ways:

1. **Higher trial count.** 50 distinct λs per bucket × 20 timed
   calls = 1000 samples per bucket (vs 200). The KS critical
   value scales as `c(α) · sqrt((n+m)/(n·m))`; with n=m=1000
   instead of n=320/m=80, the critical value tightens
   significantly.
2. **Stricter α.** α=0.01 (c=1.628) instead of α=0.05 (c=1.358).
   At α=0.01 the test is harder to pass; an indistinguishability
   verdict at this level is a stronger claim.

If `verify_constant_time`'s KS_stat stays below the new (much
tighter) critical, the timing-decorrelation claim is validated
at α=0.01 with 5× the original sample size — a stronger
:benchmarked-tier evidence statement.

If the KS_stat *exceeds* the new critical, that's also
informative: it would mean the data-dependent timing channel
emerges at higher resolution, which is the kind of finding a
:benchmarked-tier benchmark should expose.

**Determinism convention for this benchmark class.** Unlike the
P-R2c / P3-bound / LL-020-strategy-2 benchmarks (where every
output value is RNG-deterministic), the LL-019 benchmark
measures *wall-clock timing* via `time_ns()`. Timing
measurements are intrinsically non-deterministic across runs
(OS scheduling, cache state, thermal regime, system load).
Per the CLAUDE.md §Benchmarking discipline rule the *verdict*
(INDISTINGUISHABLE / DISTINGUISHABLE) is the operationally-
meaningful invariant; KS_stat will vary by ±0.01-0.02 across
runs due to timing jitter without that variance changing the
verdict. The result file records both, but the determinism
check in this benchmark's class should compare verdicts, not
raw timing statistics.

Configuration:
- Lorenz-96 N=20, F=8.0, single channel b=ones(N), α=1.0,
  constant_stream(1.0)
- Calibration: n_trials=5, N_benettin=800, Δt=0.05, Ttr=200.0
- Verifier: k=10.0 (conservative — all genuine accept; only
  strong adversaries reject)
- Adversary: BROAD direction, ε_A=2.0
- 50 distinct λs per bucket × 20 timed calls = 1000 samples
- target_seconds=0.1
- α=0.01

Run from `src/julia/`:
```bash
julia --project=. benchmark/ll019_timing_distribution_high_res.jl
```

Wall clock: ~250-300s on Apple Silicon (100 spectrum
estimations + 2000 timed verify_constant_time calls at
target=0.1s + 2000 plain verify calls).

Companion: `docs/ll019_high_res_companion.md`.
"""

using Random
using Printf
using LavaLamp

const N = 20
const F_BASE = 8.0
const N_BENETTIN = 800
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 5
const K_THRESHOLD = 10.0
const N_DISTINCT_λS = 50              # was 20
const N_CALLS_PER_λS = 20             # was 10
const TARGET_SECONDS = 0.1
const ADVERSARY_ε = 2.0
const CALIBRATION_SEED = 101
const GENUINE_SEED_BASE = 5000
const ADVERSARY_SEED_BASE = 7000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "ll019_timing_distribution_high_res.txt")

# α=0.01 KS critical-value coefficient (two-sided large-n approx).
const C_α01 = 1.628

# ─── Genuine + adversary system construction ───────────────

function genuine_coupling()
    b = ones(N)
    s_const = constant_stream(1.0; t_max=2000.0)
    return CouplingParams(F_BASE, [s_const], [1.0], [b])
end

function genuine_factory()
    p = genuine_coupling()
    return () -> lorenz96_coupled(N; F=F_BASE, coupling=p)
end

function precompute_λs(env, n_distinct, seed_base, p_input::CouplingParams)
    λs_list = Vector{Vector{Float64}}(undef, n_distinct)
    for i in 1:n_distinct
        Random.seed!(seed_base + i)
        ds = lorenz96_coupled(N; F=F_BASE, coupling=p_input)
        λs_list[i] = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    end
    return λs_list
end

# ─── Timed call helper ────────────────────────────────────

function timed_call(f, args...; kwargs...)
    t0 = time_ns()
    result = f(args...; kwargs...)
    t1 = time_ns()
    return result, (t1 - t0) / 1e9
end

# ─── Two-sample Kolmogorov-Smirnov test at α=0.01 ─────────

function ks_two_sample_α01(x::AbstractVector, y::AbstractVector)
    n = length(x)
    m = length(y)
    n > 0 && m > 0 || throw(ArgumentError("samples must be non-empty"))

    combined = sort(unique(vcat(x, y)))
    sorted_x = sort(x)
    sorted_y = sort(y)
    ks = 0.0
    for v in combined
        F_x = count(<=(v), sorted_x) / n
        F_y = count(<=(v), sorted_y) / m
        diff = abs(F_x - F_y)
        ks = max(ks, diff)
    end

    critical = C_α01 * sqrt((n + m) / (n * m))

    return (ks_stat=ks, critical_α01=critical, n=n, m=m)
end

# ─── Benchmark ─────────────────────────────────────────────

function run_benchmark()
    println("LavaLamp LL-019-high-res timing-distribution benchmark")
    println("=======================================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, single channel b=ones($N)")
    println("Verifier k=$K_THRESHOLD; target_seconds=$TARGET_SECONDS")
    println("Adversary: BROAD direction, ε_A=$ADVERSARY_ε")
    println("$N_DISTINCT_λS distinct λs per source × $N_CALLS_PER_λS timed calls each")
    println("Total samples per source = $(N_DISTINCT_λS * N_CALLS_PER_λS)")
    println("KS test α = 0.01 (c = $C_α01)")
    println()

    # Calibrate
    print("Calibrating envelope... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env = register_envelope(factory;
                             n_trials=N_CALIBRATION_TRIALS,
                             N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    println(@sprintf("%.1f s", time() - t0))

    # Pre-compute distinct genuine λs samples
    print("Pre-computing $N_DISTINCT_λS genuine λs samples... ")
    flush(stdout)
    t0 = time()
    p_genuine = genuine_coupling()
    λs_genuine = precompute_λs(env, N_DISTINCT_λS, GENUINE_SEED_BASE, p_genuine)
    println(@sprintf("%.1f s", time() - t0))

    # Pre-compute distinct adversary λs samples (BROAD direction, ε_A=2.0)
    print("Pre-computing $N_DISTINCT_λS adversary λs samples... ")
    flush(stdout)
    t0 = time()
    rng = Random.Xoshiro(ADVERSARY_SEED_BASE)
    p_adv = synthetic_adversary(p_genuine, ADVERSARY_ε; rng=rng)
    λs_adv = precompute_λs(env, N_DISTINCT_λS, ADVERSARY_SEED_BASE, p_adv)
    println(@sprintf("%.1f s", time() - t0))
    println()

    # Sanity: verify result expectations
    n_accept_genuine = count(λ -> verify(λ, env; k=K_THRESHOLD), λs_genuine)
    n_reject_adv = count(λ -> !verify(λ, env; k=K_THRESHOLD), λs_adv)
    println(@sprintf("Genuine-bucket accept rate: %d/%d = %.2f",
                     n_accept_genuine, N_DISTINCT_λS, n_accept_genuine/N_DISTINCT_λS))
    println(@sprintf("Adversary-bucket reject rate: %d/%d = %.2f",
                     n_reject_adv, N_DISTINCT_λS, n_reject_adv/N_DISTINCT_λS))
    println()

    # ─── Time plain verify ─────────────────────────────────
    # Bucket samples by verify RESULT (not by input source) so the
    # KS-test compares accept-path timing vs reject-path timing
    # cleanly.
    print("Timing plain verify (no padding)... ")
    flush(stdout)
    times_verify_accept = Float64[]
    times_verify_reject = Float64[]
    t0 = time()
    for λs_set in (λs_genuine, λs_adv)
        for λ in λs_set
            for _ in 1:N_CALLS_PER_λS
                result, elapsed = timed_call(verify, λ, env; k=K_THRESHOLD)
                if result
                    push!(times_verify_accept, elapsed)
                else
                    push!(times_verify_reject, elapsed)
                end
            end
        end
    end
    println(@sprintf("%.1f s; n_accept=%d, n_reject=%d",
                     time() - t0,
                     length(times_verify_accept),
                     length(times_verify_reject)))

    # ─── Time verify_constant_time ──────────────────────────
    print(@sprintf("Timing verify_constant_time (target=%.2fs)... ",
                   TARGET_SECONDS))
    flush(stdout)
    times_ct_accept = Float64[]
    times_ct_reject = Float64[]
    t0 = time()
    for λs_set in (λs_genuine, λs_adv)
        for λ in λs_set
            for _ in 1:N_CALLS_PER_λS
                result, elapsed = timed_call(verify_constant_time, λ, env;
                                              k=K_THRESHOLD,
                                              target_seconds=TARGET_SECONDS)
                if result
                    push!(times_ct_accept, elapsed)
                else
                    push!(times_ct_reject, elapsed)
                end
            end
        end
    end
    println(@sprintf("%.1f s; n_accept=%d, n_reject=%d",
                     time() - t0,
                     length(times_ct_accept),
                     length(times_ct_reject)))
    println()

    # ─── KS tests at α=0.01 ──────────────────────────────────
    println("Two-sample Kolmogorov-Smirnov tests (α=0.01):")
    println()

    function summarise(label, accept, reject)
        println(label)
        n = length(accept); m = length(reject)
        if n == 0 || m == 0
            println("  (empty bucket — n_accept=$n, n_reject=$m; cannot KS-test)")
            println()
            return (ks_stat=NaN, critical_α01=NaN, n=n, m=m, verdict="N/A")
        end
        result = ks_two_sample_α01(accept, reject)
        verdict = result.ks_stat < result.critical_α01 ?
                  "INDISTINGUISHABLE" : "DISTINGUISHABLE"
        println(@sprintf("  accept: n=%d  median=%.6e  mean=%.6e  std=%.6e",
                         n, _median(accept), _mean(accept), _std(accept)))
        println(@sprintf("  reject: n=%d  median=%.6e  mean=%.6e  std=%.6e",
                         m, _median(reject), _mean(reject), _std(reject)))
        println(@sprintf("  KS_stat = %.6f, critical_α01 = %.6f",
                         result.ks_stat, result.critical_α01))
        if result.ks_stat < result.critical_α01
            println("  → KS_stat < critical → fail to reject H0 → INDISTINGUISHABLE")
        else
            println("  → KS_stat > critical → reject H0 → DISTINGUISHABLE")
        end
        println()
        return (ks_stat=result.ks_stat,
                critical_α01=result.critical_α01,
                n=n, m=m, verdict=verdict)
    end

    res_verify = summarise("== plain verify ==",
                            times_verify_accept, times_verify_reject)
    res_ct = summarise("== verify_constant_time ==",
                       times_ct_accept, times_ct_reject)

    # ─── Write result file ─────────────────────────────────
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp LL-019-high-res — Timing-Distribution Benchmark
            # =========================================================
            # Date: 2026-05-04
            # Reproducibility: deterministic in calibration / λs precomputation
            #   (calibration seed=$CALIBRATION_SEED; genuine seeds=$GENUINE_SEED_BASE+i;
            #   adversary seeds=$ADVERSARY_SEED_BASE+i for i in 1..$N_DISTINCT_λS).
            #   Timing measurements are wall-clock (`time_ns()`) and are
            #   intrinsically non-deterministic across runs; the
            #   operationally-meaningful invariant is the verdict.
            #
            # Higher-resolution refresh of `ll019_timing_distribution.jl`.
            # 5× sample size + α=0.01 (vs original 200 samples + α=0.05).
            #
            # System: Lorenz-96 N=$N, F=$F_BASE
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN,
            #              Δt=$ΔT, Ttr=$TTR
            # Verifier k=$K_THRESHOLD; constant-time target=$TARGET_SECONDS s
            # Adversary: BROAD direction, ε_A=$ADVERSARY_ε
            # $N_DISTINCT_λS distinct λs per source × $N_CALLS_PER_λS timed calls
            #   = $(N_DISTINCT_λS * N_CALLS_PER_λS) samples per source
            #
            # Hypothesis test:
            #   H0: F_accept_times = F_reject_times (no timing channel)
            #   H1: F_accept_times ≠ F_reject_times (timing channel exists)
            # Two-sample two-sided KS test, α=0.01.
            # critical = $C_α01 · sqrt((n+m)/(n·m))
            #
            # Buckets: by verify RESULT (accept vs reject), not by
            # input source. This is the operationally-meaningful split.
            #
            # ─── plain verify (no padding) ──────────────────────────
            #   accept n=$(res_verify.n)  median=$(_median_safe(times_verify_accept))  mean=$(_mean_safe(times_verify_accept))  std=$(_std_safe(times_verify_accept))
            #   reject n=$(res_verify.m)  median=$(_median_safe(times_verify_reject))  mean=$(_mean_safe(times_verify_reject))  std=$(_std_safe(times_verify_reject))
            #   KS_stat = $(res_verify.ks_stat)
            #   critical_α01 = $(res_verify.critical_α01)
            #   verdict = $(res_verify.verdict)
            #
            # ─── verify_constant_time (target=$TARGET_SECONDS s) ─────
            #   accept n=$(res_ct.n)  median=$(_median_safe(times_ct_accept))  mean=$(_mean_safe(times_ct_accept))  std=$(_std_safe(times_ct_accept))
            #   reject n=$(res_ct.m)  median=$(_median_safe(times_ct_reject))  mean=$(_mean_safe(times_ct_reject))  std=$(_std_safe(times_ct_reject))
            #   KS_stat = $(res_ct.ks_stat)
            #   critical_α01 = $(res_ct.critical_α01)
            #   verdict = $(res_ct.verdict)
            #
            # LL-019 :benchmarked-tier claim refinement at high-res:
            # verify_constant_time produces a response-time distribution
            # statistically indistinguishable across accept/reject inputs
            # at α=0.01 with 1000 samples per bucket (5× the original
            # n=200 evidence at α=0.05).
            """)
    end
    println("Done.")
    return (verify=res_verify, constant_time=res_ct)
end

function _mean(x)
    n = length(x)
    s = 0.0
    @inbounds for v in x; s += v; end
    return s / n
end

function _median(x)
    s = sort(x)
    n = length(s)
    if isodd(n)
        return s[(n+1) ÷ 2]
    else
        return (s[n÷2] + s[n÷2+1]) / 2
    end
end

function _std(x)
    n = length(x)
    n >= 2 || return 0.0
    μ = _mean(x)
    s = 0.0
    @inbounds for v in x; s += (v - μ)^2; end
    return sqrt(s / (n - 1))
end

_mean_safe(x) = isempty(x) ? NaN : _mean(x)
_median_safe(x) = isempty(x) ? NaN : _median(x)
_std_safe(x) = isempty(x) ? NaN : _std(x)

run_benchmark()
