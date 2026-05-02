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

end # module Audit
