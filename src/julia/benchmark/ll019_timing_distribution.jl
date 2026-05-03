"""
LL-019 — Timing-distribution benchmark for the :benchmarked
upgrade.

Round-2 §1C-A1 / V-011 surfaced a timing channel: chaos-guard
state transitions plus naturally-fast verify paths produce
observable timing that correlates with sensor-driven internal
state. P-R2a (0.0.14) added `verify_constant_time` to pad
response time to a uniform target, decorrelating the channel.

This benchmark validates the decorrelation property
*statistically* via a two-sample Kolmogorov-Smirnov test on
the response-time distributions of accept-bucket vs
reject-bucket inputs.

Hypothesis test:

  H0 : F_accept = F_reject   (constant-time wrapper successful;
                              two distributions identical)
  H1 : F_accept ≠ F_reject   (timing channel exists)

The KS statistic is the maximum absolute difference between
the two empirical CDFs; the critical value at significance α
is approximately `c(α) · sqrt((n+m)/(n·m))` where
c(0.05) ≈ 1.358 (two-sided test). If `KS_stat < critical`,
fail to reject H0 — i.e., the constant-time wrapper has
made the two distributions statistically indistinguishable.

Comparison: also run the same KS test on plain `verify`
(without padding). Expected outcome:

- `verify_constant_time`: KS_stat well below critical → H0
  retained → indistinguishability validated.
- `verify`: KS_stat may or may not be above critical at the
  prototype's scale. The `verify` primitive is microsecond-
  fast and OS jitter dominates; the data-dependent timing
  is sub-microsecond. So even raw `verify` is empirically
  hard to distinguish at the prototype's scale.

Run from `src/julia/`:
```bash
julia --project=. benchmark/ll019_timing_distribution.jl
```

Wall clock: ~80s on Apple Silicon (40 spectrum estimations
for sample inputs + 400 timed verify_constant_time calls at
target=0.1s).

Reproducibility: deterministic via fixed seeds.
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
const K_THRESHOLD = 10.0   # conservative: all genuine accept; all strong adversaries reject
const N_DISTINCT_λS = 20             # 20 distinct λs per bucket
const N_CALLS_PER_λS = 10            # 10 timed calls each → 200 per bucket
const TARGET_SECONDS = 0.1
const ADVERSARY_ε = 2.0              # BROAD direction → consistent reject
const CALIBRATION_SEED = 101
const GENUINE_SEED_BASE = 5000
const ADVERSARY_SEED_BASE = 7000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "ll019_timing_distribution.txt")

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
    """Generate `n_distinct` independent Lyapunov spectra from
    `p_input`; record each one for replay through verify."""
    λs_list = Vector{Vector{Float64}}(undef, n_distinct)
    for i in 1:n_distinct
        Random.seed!(seed_base + i)
        ds = lorenz96_coupled(N; F=F_BASE, coupling=p_input)
        λs_list[i] = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    end
    return λs_list
end

# ─── Timed call helper ────────────────────────────────────

"""
    timed_call(f, args...; kwargs...) -> (result, elapsed_seconds)

Returns the function result + elapsed time in seconds via
`time_ns` for nanosecond-resolution timing.
"""
function timed_call(f, args...; kwargs...)
    t0 = time_ns()
    result = f(args...; kwargs...)
    t1 = time_ns()
    return result, (t1 - t0) / 1e9
end

# ─── Two-sample Kolmogorov-Smirnov test ──────────────────

"""
    ks_two_sample(x, y) -> (ks_stat, critical_α05, n, m)

Two-sample two-sided KS test. Returns the KS statistic, the
critical value at α=0.05, and the sample sizes.
"""
function ks_two_sample(x::AbstractVector, y::AbstractVector)
    n = length(x)
    m = length(y)
    n > 0 && m > 0 || throw(ArgumentError("samples must be non-empty"))

    # Combined sorted unique points
    combined = sort(unique(vcat(x, y)))

    # Empirical CDFs at each point
    sorted_x = sort(x)
    sorted_y = sort(y)
    ks = 0.0
    for v in combined
        # F_n(v) = fraction of x ≤ v
        F_x = count(<=(v), sorted_x) / n
        F_y = count(<=(v), sorted_y) / m
        diff = abs(F_x - F_y)
        ks = max(ks, diff)
    end

    # Critical value at α=0.05 (two-sided, large-n approx)
    c_α = 1.358   # for α = 0.05
    critical = c_α * sqrt((n + m) / (n * m))

    return (ks_stat=ks, critical_α05=critical, n=n, m=m)
end

# ─── Benchmark ─────────────────────────────────────────────

function run_benchmark()
    println("LavaLamp LL-019 timing-distribution benchmark")
    println("==============================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, single channel b=ones($N)")
    println("Verifier k=$K_THRESHOLD; target_seconds=$TARGET_SECONDS")
    println("Adversary: BROAD direction, ε_A=$ADVERSARY_ε")
    println("$N_DISTINCT_λS distinct λs per bucket; $N_CALLS_PER_λS timed calls each")
    println("Total samples per bucket = $(N_DISTINCT_λS * N_CALLS_PER_λS)")
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

    # Pre-compute distinct adversary λs samples (BROAD direction at ε_A=2)
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
    # cleanly. With mixed FPR a single input source can produce
    # both accept-path and reject-path samples.
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

    # ─── KS tests ──────────────────────────────────────────
    println("Two-sample Kolmogorov-Smirnov tests (α=0.05):")
    println()

    function summarise(label, accept, reject)
        println(label)
        n = length(accept); m = length(reject)
        if n == 0 || m == 0
            println("  (empty bucket — n_accept=$n, n_reject=$m; cannot KS-test)")
            println()
            return (ks_stat=NaN, critical_α05=NaN, n=n, m=m)
        end
        println(@sprintf("  accept: n=%d  median=%.6e  mean=%.6e  std=%.6e",
                         n, _median(accept), _mean(accept), _std(accept)))
        println(@sprintf("  reject: n=%d  median=%.6e  mean=%.6e  std=%.6e",
                         m, _median(reject), _mean(reject), _std(reject)))
        result = ks_two_sample(accept, reject)
        println(@sprintf("  KS_stat = %.4f, critical_α05 = %.4f",
                         result.ks_stat, result.critical_α05))
        if result.ks_stat < result.critical_α05
            println("  → KS_stat < critical → fail to reject H0 → INDISTINGUISHABLE")
        else
            println("  → KS_stat > critical → reject H0 → DISTINGUISHABLE")
        end
        println()
        return result
    end

    res_verify = summarise("== plain verify ==",
                            times_verify_accept, times_verify_reject)
    res_ct = summarise("== verify_constant_time ==",
                       times_ct_accept, times_ct_reject)

    # ─── Write result file ─────────────────────────────────
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp LL-019 — Timing-Distribution Benchmark
            # ================================================
            # Date: 2026-05-03
            # Reproducibility: deterministic. Calibration seed=$CALIBRATION_SEED;
            #                    genuine seeds = $GENUINE_SEED_BASE+i for i in 1..$N_DISTINCT_λS;
            #                    adversary seeds = $ADVERSARY_SEED_BASE+i for i in 1..$N_DISTINCT_λS.
            #
            # System: Lorenz-96 N=$N, F=$F_BASE
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR
            # Verifier k=$K_THRESHOLD; constant-time target=$TARGET_SECONDS s
            # Adversary: BROAD direction, ε_A=$ADVERSARY_ε
            # $N_DISTINCT_λS distinct λs per bucket × $N_CALLS_PER_λS timed calls = $(N_DISTINCT_λS * N_CALLS_PER_λS) samples per bucket
            #
            # Hypothesis test:
            #   H0: F_accept_times = F_reject_times (no timing channel)
            #   H1: F_accept_times ≠ F_reject_times (timing channel exists)
            # Two-sample two-sided KS test, α=0.05.
            # critical = 1.358 · sqrt((n+m)/(n·m)) for the chosen α.
            #
            # Buckets: by verify RESULT (accept vs reject), not by
            # input source. This is the operationally-meaningful split
            # for timing-channel analysis.
            #
            # ─── plain verify (no padding) ──────────────────────────
            #   accept n=$(length(times_verify_accept))  median=$(_median_safe(times_verify_accept))  mean=$(_mean_safe(times_verify_accept))  std=$(_std_safe(times_verify_accept))
            #   reject n=$(length(times_verify_reject))  median=$(_median_safe(times_verify_reject))  mean=$(_mean_safe(times_verify_reject))  std=$(_std_safe(times_verify_reject))
            #   KS_stat = $(res_verify.ks_stat)
            #   critical_α05 = $(res_verify.critical_α05)
            #   verdict = $(res_verify.ks_stat < res_verify.critical_α05 ? "INDISTINGUISHABLE" : "DISTINGUISHABLE")
            #
            # ─── verify_constant_time (target=$TARGET_SECONDS s) ─────
            #   accept n=$(length(times_ct_accept))  median=$(_median_safe(times_ct_accept))  mean=$(_mean_safe(times_ct_accept))  std=$(_std_safe(times_ct_accept))
            #   reject n=$(length(times_ct_reject))  median=$(_median_safe(times_ct_reject))  mean=$(_mean_safe(times_ct_reject))  std=$(_std_safe(times_ct_reject))
            #   KS_stat = $(res_ct.ks_stat)
            #   critical_α05 = $(res_ct.critical_α05)
            #   verdict = $(res_ct.ks_stat < res_ct.critical_α05 ? "INDISTINGUISHABLE" : "DISTINGUISHABLE")
            #
            # LL-019 :benchmarked claim: verify_constant_time produces a
            # response-time distribution that is statistically
            # indistinguishable across accept/reject inputs.
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

# Empty-bucket-safe wrappers for write-time summaries
_mean_safe(x) = isempty(x) ? NaN : _mean(x)
_median_safe(x) = isempty(x) ? NaN : _median(x)
_std_safe(x) = isempty(x) ? NaN : _std(x)

run_benchmark()
