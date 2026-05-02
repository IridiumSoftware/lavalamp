using Test
using Random
using Statistics: mean
using LavaLamp
using DynamicalSystems: trajectory

# Helper used by the sensor-stream primitive tests; using a local
# definition rather than pulling in a heavier statistics dependency.
function std_internal(xs::AbstractVector)
    μ = mean(xs)
    n = length(xs)
    return sqrt(sum((xs[i] - μ)^2 for i in 1:n) / (n - 1))
end

# Conventions in force:
# - Tests are deterministic. Random.seed! before any random IC.
# - Bounds are calibrated against literature reference values plus
#   a margin for finite-window estimator variance and IC randomness.
# - These tests produce :tested evidence under the CLAUDE.md taxonomy.
#   They do NOT establish :verified (which would require property-
#   tested QuickCheck-style coverage) or :proved (which would require
#   Lean proofs).

@testset "LavaLamp prototype" begin

    @testset "Lorenz-96 construction (LL-003)" begin
        Random.seed!(42)
        ds = lorenz96(40; F=8.0)
        # Smoke: ds is a CoupledODEs from DynamicalSystems.jl
        @test ds !== nothing
    end

    @testset "Lorenz-96 Lyapunov spectrum (LL-003 / λ₁_expected for LL-007)" begin
        # Literature reference: Karimi & Paul (2010) and others report
        # λ₁ ≈ 1.66 for Lorenz-96 at N=40, F=8, with ~13-14 positive
        # exponents and Kaplan-Yorke dimension ≈ 27. The Σ of positive
        # exponents (h_KS, the chaos-production rate per Pesin) is
        # ≈ 10.5.
        #
        # Bounds below allow ±15% on λ₁ to accommodate finite-window
        # estimator variance (~5% per Benettin theory at N=2000 QR
        # steps) and IC randomness (small but non-zero contribution).

        Random.seed!(42)
        ds = lorenz96(40; F=8.0)
        λs = lyapunov_spectrum(ds; N=2000, Δt=0.05, Ttr=500.0)

        # Spectrum has correct length (one exponent per dimension).
        @test length(λs) == 40

        # Spectrum is sorted in decreasing order by construction
        # (lyapunovspectrum returns sorted output).
        @test issorted(λs; rev=true)

        # Largest exponent matches literature (1.66) within margin.
        # The :tested evidence for LL-003 (single-attractor chaotic
        # engine) and the λ₁_expected baseline for LL-007 (chaos-guard)
        # rest on this assertion.
        λ₁ = λs[1]
        @test 1.4 < λ₁ < 1.9

        # Number of positive exponents is in literature range.
        n_pos = count(>(0), λs)
        @test 11 <= n_pos <= 16

        # h_KS = Σ max(λᵢ, 0) is the chaos-production rate cited in
        # LL-008 (resolution-bounded security) via Pesin's formula on
        # the ergodic component. Literature: ≈ 10.5.
        h_KS = sum(max.(λs, 0))
        @test 8.0 < h_KS < 12.5

        # Smallest exponent is significantly negative (strange
        # attractor has contraction directions).
        @test λs[end] < -3.0
    end

    @testset "Lorenz-96 IC sensitivity (parameter non-degeneracy hint for LL-006)" begin
        # The detection-probability bound in LL-006 §2.1 requires that
        # small parameter changes produce non-zero spectrum gap. This
        # test does not verify non-degeneracy formally (∂λ/∂s rank
        # benchmark is a separate P3 deliverable); it just checks that
        # two ICs from the same distribution produce slightly different
        # estimated λ₁'s, and that the spread is below the literature
        # tolerance.

        Random.seed!(7)
        ds1 = lorenz96(40; F=8.0)
        λs1 = lyapunov_spectrum(ds1; N=2000, Δt=0.05, Ttr=500.0)

        Random.seed!(13)
        ds2 = lorenz96(40; F=8.0)
        λs2 = lyapunov_spectrum(ds2; N=2000, Δt=0.05, Ttr=500.0)

        # Same dynamics, different IC → λ₁ should match within
        # estimator variance. This is the Oseledec-invariance fact
        # (the spectrum does not depend on the trajectory in the
        # support of the invariant measure) confirmed numerically.
        @test abs(λs1[1] - λs2[1]) < 0.2
    end

    # ─── Sensor coupling layer (LL-004 / LL-005 / LL-016) ──────────

    @testset "Sensor stream primitives" begin
        # Smoke tests for the SensorStream constructors.
        s_const = constant_stream(2.5; t_max=10.0)
        @test evaluate(s_const, 0.0) == 2.5
        @test evaluate(s_const, 5.0) == 2.5
        @test evaluate(s_const, 100.0) == 2.5  # clamps to endpoint

        # Sigmoid step: at the step time, value is half-way; before
        # the ramp window, value ≈ before; well after, value ≈ after.
        s_step = binary_step_stream(5.0, 0.0, 1.0; ramp_τ=0.1, t_max=10.0)
        @test evaluate(s_step, 0.0) < 0.01
        @test 0.4 < evaluate(s_step, 5.0) < 0.6
        @test evaluate(s_step, 10.0) > 0.99

        # Gaussian noise: zero mean, σ magnitude over many samples.
        rng = Random.Xoshiro(42)
        s_noise = gaussian_noise_stream(1.0; sample_rate=1000.0, t_max=10.0, rng=rng)
        @test length(s_noise.values) == 10000
        @test abs(mean(s_noise.values)) < 0.05  # near zero mean
        @test 0.9 < std_internal(s_noise.values) < 1.1  # ≈ σ
    end

    @testset "lorenz96_coupled with no sensors == uncoupled (LL-004 sanity)" begin
        # Empty coupling reduces to uncoupled Lorenz-96. The two EOMs
        # are mathematically identical when n_sensors == 0; spectra
        # should match within estimator variance.
        Random.seed!(42)
        ds_un = lorenz96(40; F=8.0)
        λs_un = lyapunov_spectrum(ds_un; N=1500, Δt=0.05, Ttr=300.0)

        Random.seed!(42)
        ds_co = lorenz96_coupled(40; F=8.0)  # default no_coupling
        λs_co = lyapunov_spectrum(ds_co; N=1500, Δt=0.05, Ttr=300.0)

        # Both implementations should produce the same spectrum to
        # tight tolerance (numerically near-identical EOM computation).
        @test abs(λs_un[1] - λs_co[1]) < 0.05
        @test sum(abs.(λs_un .- λs_co)) / 40 < 0.05  # mean abs diff
    end

    @testset "Stepped sensor: trajectory tracks shift smoothly (LL-004)" begin
        # Smoothness + tracking: integrate through a binary sensor step
        # (smoothed by a sigmoid ramp) and verify (a) the integration
        # succeeds throughout (no NaN/Inf, no integrator blow-up at the
        # ramp event); (b) the post-step time-average ⟨x⟩ exceeds the
        # pre-step time-average by a measurable, predicted-direction
        # amount.
        #
        # IMPORTANT: For Lorenz-96 the time-averaged ⟨x_i⟩ in the
        # chaotic regime is not the trivial fixed-point coordinate F.
        # Empirically ⟨x⟩(F=8) ≈ 2.34 and ⟨x⟩(F=10) ≈ 2.77, so
        # d⟨x⟩/dF ≈ 0.2. With α=1 and uniform b = ones(N), the
        # effective F shifts by 1.0 between pre and post windows, so
        # the predicted ⟨x⟩ shift is ≈ 0.2 (not ≈ 1).
        Random.seed!(7)
        N = 40
        F_base = 8.0
        α = 1.0
        b = ones(N)
        # Step at t=20, ramp_τ=0.5; total simulation T=60 so the post
        # window has plenty of time to equilibrate after the step.
        stream = binary_step_stream(20.0, 0.0, 1.0; ramp_τ=0.5, t_max=80.0)

        p = CouplingParams(F_base, [stream], [α], [b])
        ds = lorenz96_coupled(N; F=F_base, coupling=p)

        X, t = trajectory(ds, 60.0; Δt=0.05, Ttr=5.0)

        # All states finite throughout (no integrator blow-up through
        # the ramp event = LL-004 smoothness assertion).
        @test all(all(isfinite, x) for x in X)

        # Trajectory norm bounded — Lorenz-96 attractor radius is
        # O(N·F) roughly; allow generous bound.
        norms = [sqrt(sum(abs2, X[i])) for i in eachindex(t)]
        @test all(<(200.0), norms)

        # No anomalous excursion at the step time vs a far-from-step
        # window. If the ramp were too sharp / smoothing failed,
        # |x| would spike around t=20.
        step_idxs = findall(τ -> 19.0 <= τ <= 22.0, t)
        far_idxs = findall(τ -> 50.0 <= τ <= 60.0, t)
        @test maximum(norms[step_idxs]) < 1.5 * maximum(norms[far_idxs])

        # Time-averaged ⟨x⟩ over a window.
        function mean_window(X, t, t_lo, t_hi)
            idxs = findall(τ -> t_lo <= τ <= t_hi, t)
            !isempty(idxs) || error("empty window")
            s = 0.0
            for i in idxs
                s += sum(X[i]) / length(X[i])
            end
            return s / length(idxs)
        end

        # Pre-step window (10 ≤ t ≤ 19): well before the ramp at t=20
        # (ramp half-width 3·τ = 1.5). Effective F ≈ F_base = 8.0;
        # empirical ⟨x⟩(F=8) ≈ 2.34. Bounds wide enough for chaos.
        pre = mean_window(X, t, 10.0, 19.0)
        @test 1.0 < pre < 4.0

        # Post-step window (30 ≤ t ≤ 60): ramp finished by t=21.5;
        # effective F ≈ F_base + α = 9.0; empirical ⟨x⟩(F=9) ≈ 2.55.
        post = mean_window(X, t, 30.0, 60.0)
        @test 1.0 < post < 4.5

        # Shift in predicted direction (d⟨x⟩/dF > 0; F shifted up).
        # Magnitude predicted ≈ 0.2; allow [0.02, 0.6] for a single
        # seed run with chaotic finite-window noise.
        Δ = post - pre
        @test 0.02 < Δ < 0.6
    end

    # ─── Residue-audit verifier (LL-006 / LL-017) ──────────────────

    @testset "Audit module: mechanism + envelope smoke (LL-006)" begin
        # Mechanism tests — these exercise the verifier API in
        # isolation, no spectrum estimation cost.

        # Direct Envelope construction smoke.
        env = LavaLamp.Audit.Envelope([1.0, 0.5, -0.3], [0.1, 0.1, 0.1], 5,
                                       Dict{Symbol,Any}(:dim => 3))
        @test length(env.spectrum) == 3
        @test env.n_trials == 5

        # residue() correctness.
        res_zero = residue([1.0, 0.5, -0.3], env)
        @test all(iszero, res_zero)
        res_offset = residue([1.5, 1.0, 0.2], env)
        @test all(≈(0.5), res_offset)

        # verify() returns Bool only (LL-017 no-oracle):
        @test verify([1.0, 0.5, -0.3], env; k=1.0) isa Bool
        @test verify([1.0, 0.5, -0.3], env; k=1.0) == true
        @test verify([1.0, 0.5, -0.3] .+ 100.0, env; k=1.0) == false

        # synthetic_adversary preserves L2 magnitude exactly.
        N = 20
        b = ones(N)
        p = CouplingParams(8.0, [constant_stream(1.0; t_max=10.0)], [1.0], [b])
        rng = Random.Xoshiro(1)
        p_adv = synthetic_adversary(p, 2.5; rng=rng)
        diff = p_adv.alphas .- p.alphas
        @test isapprox(sqrt(sum(diff .^ 2)), 2.5; atol=1e-10)

        # ε_A=0 returns unperturbed.
        p_zero = synthetic_adversary(p, 0.0; rng=Random.Xoshiro(1))
        @test p_zero.alphas == p.alphas

        # Wrong-length λs throws.
        @test_throws ArgumentError residue([1.0, 0.5], env)
    end

    @testset "Audit: register, self-accept, strong-adversary reject (LL-006)" begin
        # End-to-end exercise: calibrate an envelope from 10
        # genuine-system trials; verify a fresh genuine run accepts
        # at conservative k; verify a strong adversary (ε_A=3.0)
        # rejects at the working k=5.0. N=20 to keep wall clock
        # reasonable per the 0.0.7 §2.4 budget analysis.

        Random.seed!(101)
        N = 20
        F_base = 8.0
        b = ones(N)
        s_const = constant_stream(1.0; t_max=2000.0)
        p_genuine = CouplingParams(F_base, [s_const], [1.0], [b])
        ds_factory = () -> lorenz96_coupled(N; F=F_base, coupling=p_genuine)

        Random.seed!(101)
        env = register_envelope(ds_factory;
                                 n_trials=10, N=1200, Δt=0.05, Ttr=200.0)

        # Envelope structure
        @test length(env.spectrum) == N
        @test all(env.σ .>= 0)
        @test env.n_trials == 10
        @test env.metadata[:N] == 1200
        @test env.metadata[:dim] == N

        # Self-acceptance at conservative k=10. With n_trials=10
        # calibration the empirical σ has substantial sampling
        # variance; k=10 well above any single-trial residue makes
        # this test deterministic. (Working k=5.0 has empirical
        # FPR ≈ 0.1 per the P3b benchmark, suitable for the
        # benchmarked detection-probability curve but not for a
        # deterministic test assertion.)
        Random.seed!(5001)
        ds_check = ds_factory()
        λs_check = lyapunov_spectrum(ds_check; N=1200, Δt=0.05, Ttr=200.0)
        @test verify(λs_check, env; k=10.0)

        # Strong adversary: ε_A=3.0 (3σ-magnitude perturbation in
        # alpha-space) at k=5.0 is deterministically rejected on
        # this configuration — the spectrum gap δ_A is well above
        # any single-trial estimator noise.
        rng_adv = Random.Xoshiro(7001)
        p_adv = synthetic_adversary(p_genuine, 3.0; rng=rng_adv)
        Random.seed!(7001)
        ds_adv = lorenz96_coupled(N; F=F_base, coupling=p_adv)
        λs_adv = lyapunov_spectrum(ds_adv; N=1200, Δt=0.05, Ttr=200.0)
        @test !verify(λs_adv, env; k=5.0)

        # Mechanism: residue magnitude > envelope σ for the strong
        # adversary, confirming the test is rejecting on signal not
        # on a degenerate corner case.
        res_adv = residue(λs_adv, env)
        max_k_adv = maximum(res_adv ./ max.(env.σ, 1e-10))
        @test max_k_adv > 5.0
    end

    @testset "Coupling strength sweep: λ₁ varies with α (LL-006 ∂λ/∂s ≠ 0)" begin
        # Constant sensor at value 1.0 with uniform coupling b = ones(N)
        # makes the effective forcing F_base + α uniformly across all
        # dimensions. Lorenz-96's λ₁ depends monotonically on F in the
        # 8 ≲ F ≲ 12 regime; sweeping α ∈ {0, 1, 2} corresponds to
        # effective F ∈ {8, 9, 10} and should produce visibly different
        # λ₁ values. This is the empirical demonstration of the
        # non-degeneracy condition the §2.1 detection bound requires.

        N = 40
        F_base = 8.0
        b = ones(N)
        stream = constant_stream(1.0; t_max=2000.0)

        λ1s = Float64[]
        for α in [0.0, 1.0, 2.0]
            p = CouplingParams(F_base, [stream], [α], [b])
            Random.seed!(13)
            ds = lorenz96_coupled(N; F=F_base, coupling=p)
            λs = lyapunov_spectrum(ds; N=1500, Δt=0.05, Ttr=300.0)
            push!(λ1s, λs[1])
        end

        # All measurements finite and in the chaotic-regime band.
        @test all(λ -> 1.0 < λ < 3.0, λ1s)

        # End-to-end change between α=0 and α=2 is non-trivial.
        # At α=0 (effective F=8) λ₁ ≈ 1.66; at α=2 (effective F=10)
        # λ₁ ≈ 2.4 per literature. Δ ≳ 0.5 expected; require ≳ 0.2
        # to leave margin against estimator variance.
        @test λ1s[3] - λ1s[1] > 0.2

        # Per-step change is measurable (non-degeneracy at the
        # O(α=1) scale, not just at the cumulative scale).
        @test λ1s[2] - λ1s[1] > 0.05
        @test λ1s[3] - λ1s[2] > 0.05
    end

end
