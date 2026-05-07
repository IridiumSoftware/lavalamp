"""
Audit — residue-audit verifier per architecture-design §2.1.

Implements LL-006: vector per-exponent threshold test on the
Lyapunov spectrum, with the threshold derived from per-exponent
estimator standard deviation (calibrated at registration time).

The detection-probability bound from design §2.1 is:

```
P(detect | adversary submits) ≥ 1 - K · exp(-c · T · δ_A²)
```

where δ_A is the adversary's worst-case spectrum gap, T is the
observation window, c depends on the SDE and estimator. The
verifier in this module produces ACCEPT/REJECT decisions per
trajectory; the empirical detection-probability bound across many
adversary trajectories is benchmarked separately
(`benchmark/p3b_detection_probability.jl`).

Conventions in force:
- The residue test is *vector*, not scalar (design §2.1 rejects
  scalar metrics; round-1's slow-drift attack vector V-005 is
  closed by per-exponent thresholding).
- The threshold τᵢ = k · σᵢ where σᵢ is the per-exponent
  estimator standard deviation calibrated from n_trials
  registration runs. Default k=4 keeps the genuine-device
  false-positive rate ≈ 0.997⁴⁰ ≈ 0.886 — i.e., ~11% genuine
  rejection at the strict threshold; tighter k (e.g., k=5)
  drops the FPR much further at small detection-power cost.
- No oracle (LL-017): `verify` returns Bool only. Distance,
  per-exponent residual, time-to-detection are not exposed.

API STABILITY: experimental (P3b-stage).
"""
module Audit

using Random: AbstractRNG, default_rng
using Statistics: mean, std

using ..Sensors: CouplingParams
using ..Engine: lyapunov_spectrum

export Envelope, register_envelope, residue, verify, synthetic_adversary
export verify_full, verify_constant_time, verify_jittered
export differentially_private_envelope

"""
    Envelope

Registered Lyapunov-spectrum envelope for a device. Holds the
mean per-exponent spectrum across `n_trials` calibration runs,
the per-exponent estimator standard deviation, and metadata
sufficient for reproducibility.

Fields:
- `spectrum::Vector{Float64}` — mean λᵢ across calibration trials.
- `σ::Vector{Float64}` — per-exponent sample standard deviation
  (BesselCorrected, n_trials-1 in denominator). For `n_trials=1`
  this is filled with zeros — calibration with a single trial
  cannot estimate σ.
- `n_trials::Int` — calibration trials used.
- `metadata::Dict{Symbol,Any}` — SDE parameters (N, Δt, Ttr,
  dimension) for reproducibility.

API STABILITY: stable shape.
"""
struct Envelope
    spectrum::Vector{Float64}
    σ::Vector{Float64}
    n_trials::Int
    metadata::Dict{Symbol,Any}

    function Envelope(spectrum::AbstractVector{<:Real},
                      σ::AbstractVector{<:Real},
                      n_trials::Integer,
                      metadata::Dict)
        length(spectrum) == length(σ) ||
            throw(ArgumentError("spectrum and σ must have equal length"))
        n_trials >= 1 ||
            throw(ArgumentError("n_trials must be ≥ 1"))
        return new(Float64.(collect(spectrum)),
                   Float64.(collect(σ)),
                   Int(n_trials),
                   metadata)
    end
end

"""
    register_envelope(ds_factory; n_trials::Int=3,
                      N::Int=1500, Δt::Float64=0.05,
                      Ttr::Float64=300.0,
                      lyapunov_fn=lyapunov_spectrum) -> Envelope

Calibrate an `Envelope` from `n_trials` independent runs of the
genuine device. `ds_factory` is a 0-arg callable returning a
fresh `CoupledODEs` (each call should produce a different
random IC, so the trials are independent samples of the
spectrum estimator).

`lyapunov_fn` defaults to `LavaLamp.Engine.lyapunov_spectrum`.
Override only for tests that want to inject a stub.

Per-exponent σ is the BesselCorrected sample standard deviation
across the `n_trials` runs. With `n_trials=1`, σ is a zero
vector — the verifier cannot calibrate at a single trial.
"""
function register_envelope(ds_factory;
                           n_trials::Int=3,
                           N::Int=1500,
                           Δt::Float64=0.05,
                           Ttr::Float64=300.0,
                           lyapunov_fn=lyapunov_spectrum)
    n_trials >= 1 ||
        throw(ArgumentError("n_trials must be ≥ 1"))

    spectra = Vector{Vector{Float64}}(undef, n_trials)
    @inbounds for trial in 1:n_trials
        ds = ds_factory()
        spectra[trial] = lyapunov_fn(ds; N=N, Δt=Δt, Ttr=Ttr)
    end
    dim = length(spectra[1])
    @inbounds for trial in 2:n_trials
        length(spectra[trial]) == dim ||
            throw(ArgumentError(
                "calibration trials produced spectra of differing length"))
    end

    means = Vector{Float64}(undef, dim)
    σs = Vector{Float64}(undef, dim)
    @inbounds for i in 1:dim
        vals = [spectra[t][i] for t in 1:n_trials]
        means[i] = mean(vals)
        σs[i] = n_trials >= 2 ? std(vals) : 0.0
    end

    metadata = Dict{Symbol,Any}(
        :N => N,
        :Δt => Δt,
        :Ttr => Ttr,
        :dim => dim,
    )
    return Envelope(means, σs, n_trials, metadata)
end

"""
    residue(λs::AbstractVector{<:Real}, env::Envelope) -> Vector{Float64}

Per-exponent absolute difference between the candidate spectrum
`λs` and the registered envelope mean. Returned vector has the
same length as `env.spectrum`.
"""
function residue(λs::AbstractVector{<:Real}, env::Envelope)
    length(λs) == length(env.spectrum) ||
        throw(ArgumentError(
            "λs length $(length(λs)) ≠ envelope dim $(length(env.spectrum))"))
    return abs.(Float64.(collect(λs)) .- env.spectrum)
end

"""
    verify(λs::AbstractVector{<:Real}, env::Envelope;
           k::Float64=4.0) -> Bool

Per-exponent vector test: ACCEPT iff for every i,
`|λs[i] - env.spectrum[i]| < k · env.σ[i]`. REJECT if any
component exceeds the threshold.

Returns `Bool` only — no distance information leaks per LL-017
(verification no-oracle requirement).

When `env.σ` contains zeros (single-trial calibration), the
corresponding components reject any non-exact match. Use
`n_trials ≥ 3` for meaningful calibration.
"""
function verify(λs::AbstractVector{<:Real}, env::Envelope;
                k::Float64=4.0)
    k > 0 || throw(ArgumentError("k must be positive"))
    res = residue(λs, env)
    @inbounds for i in eachindex(res)
        # Strict comparison; equal-to-threshold is rejected.
        if res[i] >= k * env.σ[i]
            return false
        end
    end
    return true
end

"""
    verify_full(ds, env::Envelope; k::Float64=4.0,
                N::Int=1500, Δt::Float64=0.05,
                Ttr::Float64=300.0) -> Bool

Compute the full Benettin Lyapunov spectrum from `ds` and verify
against `env`. Returns `Bool` only (LL-017 no-oracle).

**LL-019 audit-on-every-verify requirement.** The chaos-guard's
cheap Wolf-method λ̂₁ estimator (`DynamicalSystems.lyapunov`) is
sufficient for *always-on* monitoring — but every verification
*request* must run the full-spectrum Benettin audit, because
adversaries can craft trajectories that match λ₁ (passing the
guard) while diverging in higher exponents (caught only by the
full-spectrum residue test). Round 2 §1C-A4 documents the
exploitable window if the audit runs less frequently than the
guard.

This function makes the requirement explicit at the API level:
verifiers using `verify_full` cannot accidentally substitute the
cheap single-exponent estimator for the full-spectrum audit. The
underlying `verify(λs, env; k)` remains available for callers
that have already computed the full spectrum.

Cost: ~507 ms per call at N=40, ~50-150 ms at N=20 (per the 0.0.7
§2.4 cost analysis; 400× more expensive than Wolf-method λ₁
alone).
"""
function verify_full(ds, env::Envelope;
                     k::Float64=4.0,
                     N::Int=1500,
                     Δt::Float64=0.05,
                     Ttr::Float64=300.0)
    λs = lyapunov_spectrum(ds; N=N, Δt=Δt, Ttr=Ttr)
    return verify(λs, env; k=k)
end

"""
    verify_constant_time(λs, env::Envelope;
                         k::Float64=4.0,
                         target_seconds::Float64=0.1) -> Bool

Constant-time wrapper around `verify`. Wall-clock elapsed is
padded to at least `target_seconds` regardless of the verify
result, so an external observer measuring response timing
cannot distinguish ACCEPT from REJECT (or any other internal
state).

**LL-019 timing-decorrelation requirement.** Round 2 §1C-A1
identified V-011 (Reseed Oracle): chaos-guard state transitions
plus naturally-fast `verify` paths produce observable timing
that correlates with sensor-driven internal state. Padding
to a uniform target time defeats the timing channel.

Choosing `target_seconds`: must exceed the *slowest* legitimate
verify path so that no fast-path leak occurs. For Lorenz-96 N=40
audit-on-every-verify (`verify_full`), the verify call alone is
~500 ms; choose `target_seconds = 0.6` or higher for
production. For unit tests `target_seconds = 0.1` (with a fast
pre-computed λs) is sufficient to demonstrate the property.

Padding via `sleep` is the prototype's mechanism — production
would use a wait-on-deadline scheduling primitive that does not
block a worker thread (e.g. an async timer event). The
correctness of the *decorrelation* property is the test target;
the implementation choice is a deployment detail.

The function returns the same `Bool` as `verify`; it does not
itself add any oracle leak. Combine with `verify_full` for
audit-on-every-verify + constant-time response together.
"""
function verify_constant_time(λs::AbstractVector{<:Real},
                              env::Envelope;
                              k::Float64=4.0,
                              target_seconds::Float64=0.1)
    target_seconds > 0 ||
        throw(ArgumentError("target_seconds must be positive"))
    t_start = time()
    result = verify(λs, env; k=k)
    elapsed = time() - t_start
    if elapsed < target_seconds
        sleep(target_seconds - elapsed)
    end
    return result
end

"""
    verify_jittered(λs, env::Envelope;
                    k::Float64=4.0,
                    target_seconds::Float64=0.1,
                    jitter_window::Float64=0.001,
                    rng::AbstractRNG=default_rng()) -> Bool

LL-019 regime-2 deployment-context wrapper around `verify`.
Extends `verify_constant_time` with a uniform-random jitter
offset on top of constant-time padding.

Total wall-clock elapsed:

    max(verify_elapsed, target_seconds) + Uniform(0, jitter_window)

The constant-time pad alone (`verify_constant_time`) is
sufficient for LL-019 *regime 1* (dev-host artifact, sub-µs
data-dependent timing channel below OS scheduling jitter
floor; the 0.0.19 KS-test benchmark validates this regime).
LL-019 *regime 2* — multi-tenant shared environments (cloud
VMs, container orchestrators with neighbouring workloads,
co-tenant CPUs) — needs additional jitter randomisation
because the timing channel sits *above* the shared-host
jitter floor and a co-tenant adversary can aggregate
observations to recover the verify result.

The uniform-random offset decorrelates systematic timing
leakage from the verify result: even if the constant-time
pad is observed to systematically vary by a few µs across
accept/reject inputs (e.g. cache-line effects, branch
predictor state), the jitter offset dominates that signal at
the per-call level and aggregating across many calls cannot
recover it without a much larger sample than is available
in any reasonable attack window.

**Spec defaults (LL-019 regime-2 deployment constraint):**
- `target_seconds ≥ 0.010` (10 ms; dominates typical
  shared-host scheduling jitter floor).
- `jitter_window ≥ 0.001` (1 ms; uniform offset over a window
  comparable to the shared-host noise floor).

These are deployment minima; production deployments calibrate
to the specific co-tenancy environment. The function accepts
any positive values for both — the caller is responsible for
choosing values that meet the deployment's adversary model.

Determinism: the jitter draw uses the supplied `rng` (default
`default_rng()`); pass `Random.Xoshiro(seed)` for reproducible
test runs. Note that *intentional* determinism in the jitter
defeats the security property — `default_rng()` is the
operationally-correct default for production use.

Returns the same `Bool` as `verify`; like `verify_constant_time`,
the function does not itself add an oracle leak.
"""
function verify_jittered(λs::AbstractVector{<:Real},
                         env::Envelope;
                         k::Float64=4.0,
                         target_seconds::Float64=0.1,
                         jitter_window::Float64=0.001,
                         rng::AbstractRNG=default_rng())
    target_seconds > 0 ||
        throw(ArgumentError("target_seconds must be positive"))
    jitter_window >= 0 ||
        throw(ArgumentError("jitter_window must be non-negative"))
    t_start = time()
    result = verify(λs, env; k=k)
    elapsed = time() - t_start
    pad_to = target_seconds + jitter_window * rand(rng)
    if elapsed < pad_to
        sleep(pad_to - elapsed)
    end
    return result
end

"""
    synthetic_adversary(p::CouplingParams, ε_A::Real;
                        rng::AbstractRNG=default_rng(),
                        direction::Union{Nothing,AbstractVector}=nothing
                        ) -> CouplingParams

Construct a synthetic adversary near the genuine `CouplingParams`
by perturbing the coupling-strength vector `alphas` by exactly
`ε_A` in L2 norm: `alphas_adv = alphas + ε_A · û` where `û` is a
random unit vector in α-space (or supplied via `direction`).

Unit-vector + deterministic magnitude (rather than `ε_A · randn`)
gives a *consistent* perturbation magnitude across trials. With
`randn` perturbations the realized magnitude varies wildly with
trial index (especially for small `n`), which breaks
detection-probability sweeps.

The adversary uses the same SDE family, the same sensor streams,
and the same per-dimension coupling vectors — only the
coupling-strength magnitudes α_k differ. This represents an A4
adversary who knows the architecture but cannot reproduce the
exact coupling-strength calibration.

`ε_A=0` returns a parameter bundle equal to `p` (no perturbation).
For `n=0` (no coupling channels), the input is returned unchanged.
"""
function synthetic_adversary(p::CouplingParams, ε_A::Real;
                             rng::AbstractRNG=default_rng(),
                             direction::Union{Nothing,AbstractVector}=nothing)
    n = length(p.alphas)
    if iszero(ε_A) || n == 0
        return CouplingParams(p.F_base, p.streams, p.alphas, p.coupling_vectors)
    end
    if direction === nothing
        d = randn(rng, n)
    else
        length(direction) == n ||
            throw(ArgumentError(
                "direction length $(length(direction)) ≠ alphas length $n"))
        d = Float64.(collect(direction))
    end
    norm_d = sqrt(sum(d .^ 2))
    if iszero(norm_d)
        # Degenerate direction; return unperturbed (ε_A · 0 = 0).
        return CouplingParams(p.F_base, p.streams, p.alphas, p.coupling_vectors)
    end
    û = d ./ norm_d
    perturbed = p.alphas .+ Float64(ε_A) .* û
    return CouplingParams(p.F_base, p.streams, perturbed, p.coupling_vectors)
end

"""
    differentially_private_envelope(env::Envelope; ε::Real,
                                     δ::Real=1e-6,
                                     sensitivity::Real=0.1,
                                     rng::AbstractRNG=default_rng()
                                     ) -> Envelope

Construct an `(ε, δ)`-differentially-private published version
of `env`. The published spectrum is obtained by adding calibrated
Gaussian noise (Dwork-Roth Gaussian mechanism); the published σ
is the *variance-convolution* form `sqrt(env.σ² + σ_DP²)` rather
than a noised σ.

**Why σ is treated differently from spectrum.** Naive symmetric
Gaussian noise on σ (the obvious application of the Gaussian
mechanism) can push σ near zero or negative, requiring a floor
that operationally collapses the verifier's threshold to ~0 and
forces every candidate trajectory to be rejected (including the
genuine device — see the project-internal audit companion for the negative
result that surfaced this). The variance-convolution form sidesteps
the issue by computing the σ a verifier *needs* to see: the
expected variance of the residual `λ_genuine - spectrum_pub`,
which is the convolution `Var(genuine_residual) + Var(DP_shift)
= σ_true² + σ_DP²`. This is deterministically larger than σ_true
so detection thresholds widen monotonically with σ_DP, matching
the operational intent of the privacy/detection trade-off.

**Privacy implications of the σ choice.**

- *Spectrum* is fully `(ε, δ)`-DP via the Gaussian mechanism.
- *σ is not DP* under this implementation. `σ_pub` is a
  deterministic function of `env.σ` and the public `σ_DP`, so
  it leaks `env.σ ≤ σ_pub`. Operationally σ is calibration
  *confidence* metadata (estimator standard deviation across
  registration trials), strictly less sensitive than the
  spectrum itself; for a calibration-confidentiality strategy
  this is honest. A deployment that needs σ to be DP-protected
  must substitute Strategy 1 (TPM-sealed storage) or Strategy 3
  (Shamir threshold) for that field.

The Gaussian mechanism on the spectrum: for a function with
L2-sensitivity Δ_2, adding `Gaussian(0, σ²)` noise per component
satisfies `(ε, δ)`-DP when

```
σ ≥ Δ_2 · sqrt(2 · ln(1.25 / δ)) / ε
```

(See Dwork & Roth, "The Algorithmic Foundations of Differential
Privacy" §A.1 / Thm A.1.)

**Sensitivity argument.** The L2-sensitivity Δ_2 of the registered
spectrum w.r.t. swapping a single calibration trial is bounded
by the per-trial λ̂ deviation: at the prototype's calibration
config (n_trials = 5–10, N_benettin ≈ 1200), per-exponent λ̂
varies by ≈ 0.1 across trials (per `register_envelope`'s sample
σ ≈ 0.05–0.2). The supplied `sensitivity` parameter must exceed
the empirical per-trial deviation; default 0.1 is honest for
the prototype's calibration config but should be re-derived per
deployment.

**Privacy-vs-detection trade-off.** A registration-channel
observer who sees only `differentially_private_envelope(env)`
gains at most `ε`-bounded information about the true spectrum
(per the DP guarantee). The verifier using the perturbed envelope
has correspondingly *wider* threshold tolerances
(k · sqrt(σ_true² + σ_DP²) vs k · σ_true) so weak adversaries
slip through more easily; detection power decreases monotonically
as ε decreases.

This implements LL-020 Strategy 2 from
the project-internal companion §2.2,
with the variance-convolution σ refinement landed 2026-05-04
in response to the diagnostic finding documented in
the project-internal audit companion. Other LL-020 strategies (TPM-sealed
storage; multi-party threshold scheme) require platform /
cryptographic-library coupling and live in P7 hardening / P5
Haskell tracks.

# Examples
```julia-repl
julia> env_pub = differentially_private_envelope(env;
                                                  ε=1.0, δ=1e-6,
                                                  sensitivity=0.1);
# env_pub.spectrum satisfies (1.0, 1e-6)-DP; env_pub.σ leaks a
# lower bound on env.σ but is operationally usable for verification.
```

API STABILITY: experimental.
"""
function differentially_private_envelope(env::Envelope;
                                          ε::Real,
                                          δ::Real=1e-6,
                                          sensitivity::Real=0.1,
                                          rng::AbstractRNG=default_rng())
    ε > 0 || throw(ArgumentError("ε must be positive"))
    0 < δ < 1 || throw(ArgumentError("δ must be in (0, 1)"))
    sensitivity > 0 || throw(ArgumentError("sensitivity must be positive"))

    σ_DP = sensitivity * sqrt(2 * log(1.25 / δ)) / ε

    n = length(env.spectrum)
    # Spectrum: Gaussian-mechanism (ε, δ)-DP.
    spectrum_pub = env.spectrum .+ σ_DP .* randn(rng, n)
    # σ: variance-convolution. Deterministic in env.σ; reflects the
    # expected variance of the verifier's residual under DP-perturbed
    # spectrum. Strictly ≥ env.σ; no floor required (σ ≥ 0 always
    # for a valid envelope, so sqrt(σ² + σ_DP²) ≥ σ_DP > 0).
    σ_pub = sqrt.(env.σ .^ 2 .+ σ_DP^2)

    metadata = copy(env.metadata)
    metadata[:dp_ε] = Float64(ε)
    metadata[:dp_δ] = Float64(δ)
    metadata[:dp_sensitivity] = Float64(sensitivity)
    metadata[:dp_σ] = σ_DP
    metadata[:dp_perturbed] = true

    return Envelope(spectrum_pub, σ_pub, env.n_trials, metadata)
end

end # module Audit
