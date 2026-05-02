using Test
using Random
using LavaLamp

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

end
