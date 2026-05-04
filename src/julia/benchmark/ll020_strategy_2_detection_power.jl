"""
LL-020 Strategy 2 — Detection-power-vs-ε benchmark for the
ε-differentially-private envelope (`differentially_private_envelope`).

The Dwork-Roth Gaussian mechanism adds Gaussian noise of scale

    σ_DP = sensitivity · sqrt(2 · ln(1.25 / δ)) / ε

per component to the published envelope. As ε shrinks (more
privacy), σ_DP grows; the verifier's published threshold k · σ_pub
widens; adversaries with smaller spectrum gaps slip through. As ε
grows (less privacy), σ_DP shrinks toward zero and the published
envelope approaches the un-perturbed registered envelope; detection
power approaches the LL-006 P3-bound surface.

The benchmark traces this trade-off curve directly: for each ε_DP
in a sweep grid, sample several DP realizations of the published
envelope, run synthetic adversaries at structured magnitudes, and
record the empirical P(reject) at each (ε_DP, ε_A) cell.

The trajectory computation is *shared* across the (ε_DP,
DP-realization) sweep — the adversary's λs depends only on
(ε_A, trial), not on the DP perturbation. Wall clock is
dominated by the 60 genuine trajectory computations (~0.5 s each
at N=20) plus the cheap O(N) verify checks across the (ε_DP,
DP-realization) cells.

Configuration matches `p3_bound_high_res.jl` for direct
comparability: Lorenz-96 N=20, F=8, single coupling channel
b=ones(N), constant_stream(1.0), α=1.0, k=5, n_calibration=10,
N_benettin=1200.

Run from `src/julia/`:
```bash
julia --project=. benchmark/ll020_strategy_2_detection_power.jl
```

Reproducibility: deterministic via fixed seeds. The DP-realization
seeds are derived from a fixed base seed so the same ε_DP value
produces the same noise draws across runs.

Companion: `docs/ll020_strategy_2_benchmarked_companion.md`.
"""

using Random
using Printf
using Statistics
using LavaLamp

const N = 20
const F_BASE = 8.0
const N_BENETTIN = 1200
const ΔT = 0.05
const TTR = 200.0
const N_CALIBRATION_TRIALS = 10
const N_TRIALS_PER_POINT = 10
const N_DP_REALIZATIONS = 5
const K_THRESHOLD = 5.0
const T_OBSERVATION = N_BENETTIN * ΔT       # 60 time units
const ε_A_GRID = [0.0, 0.5, 1.0, 1.5, 2.0, 3.0]
const ε_DP_GRID = [0.3, 1.0, 3.0, 10.0]
const DP_DELTA = 1e-6
const DP_SENSITIVITY = 0.1
const CALIBRATION_SEED = 101
const ADVERSARY_SEED_BASE = 2000
const TRIAL_SEED_BASE = 3000
const DP_SEED_BASE = 4000
const RESULT_PATH = joinpath(@__DIR__, "results",
                             "ll020_strategy_2_detection_power_lorenz96.txt")

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

"""
Compute σ_DP analytically per the Dwork-Roth Gaussian mechanism.
"""
function σ_DP_for(ε::Real;
                  δ::Real=DP_DELTA,
                  sensitivity::Real=DP_SENSITIVITY)
    return sensitivity * sqrt(2 * log(1.25 / δ)) / ε
end

function run_benchmark()
    println("LavaLamp LL-020 Strategy 2 — DP detection-power sweep")
    println("======================================================")
    println("System: Lorenz-96 N=$N, F=$F_BASE, single channel b=ones($N)")
    println("Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN")
    println("Verifier: k=$K_THRESHOLD")
    println("DP grid: ε_DP ∈ $ε_DP_GRID (δ=$DP_DELTA, sensitivity=$DP_SENSITIVITY)")
    println("DP realizations per ε_DP: $N_DP_REALIZATIONS")
    println("Adversary magnitudes: ε_A ∈ $ε_A_GRID")
    println("Trials per ε_A: $N_TRIALS_PER_POINT")
    println("Observation window T = $T_OBSERVATION (= N_benettin·Δt)")
    println()

    println("Predicted σ_DP per ε_DP (Dwork-Roth Gaussian mechanism):")
    for ε_DP in ε_DP_GRID
        σ_DP = σ_DP_for(ε_DP)
        println(@sprintf("  ε_DP = %5.2f  →  σ_DP = %.4f", ε_DP, σ_DP))
    end
    println()

    print("Calibrating envelope... ")
    flush(stdout)
    Random.seed!(CALIBRATION_SEED)
    factory = genuine_factory()
    t0 = time()
    env_true = register_envelope(factory;
                                  n_trials=N_CALIBRATION_TRIALS,
                                  N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
    println(@sprintf("%.1f s", time() - t0))
    println(@sprintf("  σ_true mean = %.4f, σ_true max = %.4f, σ_true min = %.4f",
                     mean(env_true.σ),
                     maximum(env_true.σ), minimum(env_true.σ)))
    println()

    # Pre-compute the published-envelope realizations per ε_DP.
    println("Generating DP-realizations of published envelope...")
    env_pub_grid = Dict{Float64,Vector{Envelope}}()
    for ε_DP in ε_DP_GRID
        envs = Envelope[]
        for r in 1:N_DP_REALIZATIONS
            rng = Random.Xoshiro(DP_SEED_BASE +
                                 round(Int, ε_DP * 10) +
                                 r * 1000)
            env_pub = differentially_private_envelope(env_true;
                                                       ε=ε_DP,
                                                       δ=DP_DELTA,
                                                       sensitivity=DP_SENSITIVITY,
                                                       rng=rng)
            push!(envs, env_pub)
        end
        env_pub_grid[ε_DP] = envs
    end
    println("Done.")
    println()

    # Compute genuine adversary trajectories once; reuse across ε_DP cells.
    println("Computing adversary trajectories (shared across DP cells)...")
    p_genuine = genuine_coupling()
    # trajectories[(ε_A, trial)] -> λs
    trajectories = Dict{Tuple{Float64,Int},Vector{Float64}}()
    t_traj_start = time()
    for ε_A in ε_A_GRID
        for trial in 1:N_TRIALS_PER_POINT
            rng = Random.Xoshiro(ADVERSARY_SEED_BASE + trial)
            p_adv = synthetic_adversary(p_genuine, ε_A; rng=rng)
            Random.seed!(TRIAL_SEED_BASE + trial)
            ds = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)
            λs = lyapunov_spectrum(ds; N=N_BENETTIN, Δt=ΔT, Ttr=TTR)
            trajectories[(ε_A, trial)] = λs
        end
    end
    println(@sprintf("Done in %.1f s (%d trajectories).",
                    time() - t_traj_start,
                    length(trajectories)))
    println()

    # Build the result table. Columns:
    #   ε_A | P_baseline | P_DP=10 ± std | P_DP=3 ± std | P_DP=1 ± std | P_DP=0.3 ± std
    println("Detection-power sweep:")
    println("ε_A    P_no_DP   P_ε=10            P_ε=3             P_ε=1             P_ε=0.3")
    println("----   -------   ---------------   ---------------   ---------------   ---------------")

    rows = NamedTuple[]
    for ε_A in ε_A_GRID
        # Baseline (no DP): one envelope, N_TRIALS_PER_POINT trials.
        rejects_baseline = 0
        for trial in 1:N_TRIALS_PER_POINT
            λs = trajectories[(ε_A, trial)]
            if !verify(λs, env_true; k=K_THRESHOLD)
                rejects_baseline += 1
            end
        end
        p_baseline = rejects_baseline / N_TRIALS_PER_POINT

        # DP cells: per ε_DP, average across DP realizations.
        dp_results = Dict{Float64,Tuple{Float64,Float64}}()  # ε_DP -> (mean, std)
        for ε_DP in ε_DP_GRID
            p_per_realization = Float64[]
            for env_pub in env_pub_grid[ε_DP]
                rejects = 0
                for trial in 1:N_TRIALS_PER_POINT
                    λs = trajectories[(ε_A, trial)]
                    if !verify(λs, env_pub; k=K_THRESHOLD)
                        rejects += 1
                    end
                end
                push!(p_per_realization, rejects / N_TRIALS_PER_POINT)
            end
            dp_results[ε_DP] = (mean(p_per_realization),
                                std(p_per_realization))
        end

        # Print row in descending-ε_DP order (highest privacy budget = least
        # noisy = closest to baseline first).
        m10, s10 = dp_results[10.0]
        m3, s3   = dp_results[3.0]
        m1, s1   = dp_results[1.0]
        m03, s03 = dp_results[0.3]
        println(@sprintf(
            "%.2f   %7.3f   %.3f ± %.3f     %.3f ± %.3f     %.3f ± %.3f     %.3f ± %.3f",
            ε_A, p_baseline,
            m10, s10, m3, s3, m1, s1, m03, s03))

        push!(rows, (
            ε_A=ε_A,
            p_baseline=p_baseline,
            dp_results=dp_results,
        ))
    end

    # Per-ε_DP fitted bound constants (transition-region only).
    println()
    println("Fitted bound constants per ε_DP (P3-bound shape):")
    println("  log(1 - P_reject) = log(K) - c'·T·ε_A²,  T = $T_OBSERVATION")
    println("  Excludes FPR-floor (P=baseline) and saturation (P≥0.95) points.")
    println()
    println("ε_DP    σ_DP      n_fit  K        c'         P_genuine_FPR")
    println("-----   -------   -----  -------  ---------  -------------")

    fit_results = NamedTuple[]
    for ε_DP_row in vcat(["baseline"], string.(ε_DP_GRID))
        if ε_DP_row == "baseline"
            ps = [r.p_baseline for r in rows]
            σ_DP = 0.0
            ε_DP = NaN
            label = "no DP "
        else
            ε_DP = parse(Float64, ε_DP_row)
            ps = [first(r.dp_results[ε_DP]) for r in rows]
            σ_DP = σ_DP_for(ε_DP)
            label = @sprintf("%.2f", ε_DP)
        end

        # Fit transition region: 0 < P < 0.95 strictly (exclude floor + saturation).
        ε_A_fit = Float64[]
        log_one_minus_P = Float64[]
        for (i, ε_A) in enumerate(ε_A_GRID)
            P = ps[i]
            if P > 0 && P < 0.95
                push!(ε_A_fit, ε_A)
                push!(log_one_minus_P, log(1 - P))
            end
        end

        # FPR is P at ε_A = 0.
        p_genuine_fpr = ps[1]

        if length(ε_A_fit) >= 2
            # Linear fit of log(1-P) vs ε_A².
            x² = ε_A_fit .^ 2
            y = log_one_minus_P
            n_fit = length(x²)
            x²_mean = mean(x²)
            y_mean = mean(y)
            num = sum((x² .- x²_mean) .* (y .- y_mean))
            den = sum((x² .- x²_mean) .^ 2)
            slope = den > 0 ? num / den : 0.0
            intercept = y_mean - slope * x²_mean
            K = exp(intercept)
            c_prime = -slope / T_OBSERVATION
            println(@sprintf(
                "%-5s   %7.4f   %5d  %7.3f  %8.5f   %.3f",
                label, σ_DP, n_fit, K, c_prime, p_genuine_fpr))
            push!(fit_results, (
                label=label, ε_DP=ε_DP, σ_DP=σ_DP,
                n_fit=n_fit, K=K, c_prime=c_prime,
                p_genuine_fpr=p_genuine_fpr,
            ))
        else
            println(@sprintf(
                "%-5s   %7.4f   %5d  (insufficient transition-region points)              %.3f",
                label, σ_DP, length(ε_A_fit), p_genuine_fpr))
            push!(fit_results, (
                label=label, ε_DP=ε_DP, σ_DP=σ_DP,
                n_fit=length(ε_A_fit), K=NaN, c_prime=NaN,
                p_genuine_fpr=p_genuine_fpr,
            ))
        end
    end

    println()
    println("Writing result to $RESULT_PATH")
    open(RESULT_PATH, "w") do io
        write(io, """
            # LavaLamp LL-020 Strategy 2 — DP detection-power sweep
            # ======================================================
            # Date: 2026-05-03
            # Reproducibility: deterministic. calibration seed = $CALIBRATION_SEED;
            #                    adversary seed = Xoshiro($ADVERSARY_SEED_BASE+trial);
            #                    trial IC seed = $TRIAL_SEED_BASE+trial;
            #                    DP-realization seed = Xoshiro($DP_SEED_BASE +
            #                                                  round(ε_DP·10) +
            #                                                  r·1000).
            #
            # System: Lorenz-96 N=$N, F=$F_BASE
            # Coupling: single channel, b=ones($N), α=[1.0], constant_stream(1.0)
            # Calibration: n_trials=$N_CALIBRATION_TRIALS, N_benettin=$N_BENETTIN, Δt=$ΔT, Ttr=$TTR
            # Verifier: vector per-exponent test, k=$K_THRESHOLD
            # Adversary: synthetic_adversary with isotropic unit-vector × ε_A
            # Trials per ε_A: $N_TRIALS_PER_POINT
            # DP grid: ε_DP ∈ $ε_DP_GRID (δ=$DP_DELTA, sensitivity=$DP_SENSITIVITY)
            # DP realizations per ε_DP: $N_DP_REALIZATIONS
            # Observation window: T = $T_OBSERVATION (= N_benettin · Δt)
            #
            # σ_DP per Dwork-Roth Gaussian mechanism:
            #   σ_DP = sensitivity · sqrt(2·ln(1.25/δ)) / ε
            """)
        for ε_DP in ε_DP_GRID
            write(io, @sprintf("#   ε_DP = %5.2f  →  σ_DP = %.4f\n",
                              ε_DP, σ_DP_for(ε_DP)))
        end
        write(io, """
            #
            # σ_true (registered envelope, no DP):
            #   mean = $(round(mean(env_true.σ), digits=4))
            #   max  = $(round(maximum(env_true.σ), digits=4))
            #   min  = $(round(minimum(env_true.σ), digits=4))
            #
            ε_A    P_no_DP   P_ε=10            P_ε=3             P_ε=1             P_ε=0.3
            ----   -------   ---------------   ---------------   ---------------   ---------------
            """)
        for r in rows
            m10, s10 = r.dp_results[10.0]
            m3, s3   = r.dp_results[3.0]
            m1, s1   = r.dp_results[1.0]
            m03, s03 = r.dp_results[0.3]
            write(io, @sprintf(
                "%.2f   %7.3f   %.3f ± %.3f     %.3f ± %.3f     %.3f ± %.3f     %.3f ± %.3f\n",
                r.ε_A, r.p_baseline,
                m10, s10, m3, s3, m1, s1, m03, s03))
        end

        write(io, """

            # Fitted bound constants per ε_DP:
            #   log(1 - P_reject) = log(K) - c'·T·ε_A²
            #   T = $T_OBSERVATION
            #   Excludes FPR-floor (P ≤ baseline) and saturation (P ≥ 0.95).
            ε_DP    σ_DP      n_fit  K        c'         P_genuine_FPR
            -----   -------   -----  -------  ---------  -------------
            """)
        for f in fit_results
            if isnan(f.K)
                write(io, @sprintf(
                    "%-5s   %7.4f   %5d  (insufficient transition-region points)              %.3f\n",
                    f.label, f.σ_DP, f.n_fit, f.p_genuine_fpr))
            else
                write(io, @sprintf(
                    "%-5s   %7.4f   %5d  %7.3f  %8.5f   %.3f\n",
                    f.label, f.σ_DP, f.n_fit, f.K, f.c_prime, f.p_genuine_fpr))
            end
        end

        write(io, """

            # ===
            # Trade-off interpretation:
            #
            # As ε_DP decreases (more privacy), σ_DP increases per the
            # Dwork-Roth Gaussian mechanism. This widens the published
            # threshold k·σ_pub, which has two operationally distinct
            # effects:
            #
            #   (a) FPR cost: genuine-device verification rejects more
            #       often — see the P_genuine_FPR column. The published
            #       envelope is shifted by Gaussian noise from the true
            #       envelope; genuine λs may now lie outside the rejection
            #       ball.
            #
            #   (b) Detection cost: weak adversaries (small ε_A) slip
            #       through more easily — see the c' column. Lower c'
            #       means a weaker bound; for a fixed observation window T,
            #       achieving a given P(detect) requires a *larger* ε_A.
            #
            # The benchmark exposes both costs simultaneously, so a
            # deployment can choose ε_DP to land at an acceptable point
            # on the privacy / detection / FPR three-way trade-off.
            #
            # Companion: docs/ll020_strategy_2_benchmarked_companion.md
            """)
    end
    println("Done.")
    return rows, fit_results
end

run_benchmark()
