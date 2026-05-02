"""
Sensors — sensor-stream types and smoothing primitives for the
LavaLamp substrate-coupling layer.

Implements the sensor side of the architecture-design §2.4 smooth
external potential field: SensorStream (time-tabled signal with
linear interpolation), constructors for the three sensor categories
called out in §2.4 (high-bandwidth noise; discrete-state binary;
slow-drift), and CouplingParams (the parameter bundle threading
sensor streams into the SDE forcing term).

Conventions in force:
- Real-valued throughout (LL-009 boundary).
- Time grids are Float64 increasing; values are Float64.
- Discrete-state sensor transitions are *smoothed* by sigmoid /
  Gaussian ramps at construction time (LL-004: continuous coupling
  via smooth potential, no step-function parameter kicks).
- Linear interpolation between samples; clamped at the stream
  endpoints. For sample rates above the SDE timestep, this is
  effectively the smoothed signal.

API STABILITY: experimental (P3a-stage).
"""
module Sensors

using Random: AbstractRNG, default_rng

export SensorStream, evaluate
export constant_stream, binary_step_stream, gaussian_noise_stream
export CouplingParams, no_coupling

"""
    SensorStream

Time-indexed sensor reading. `times` is a strictly-increasing
Float64 vector; `values` is parallel. Lookups use linear
interpolation; lookups outside the time range clamp to the
endpoint.

`SensorStream` is the LavaLamp-side abstraction over what would,
in production, be a live hardware sensor with its own bandwidth
and sample rate. The prototype substitutes synthetic streams
(constant / stepped / noisy) for test fixtures.

API STABILITY: stable shape.
"""
struct SensorStream
    times::Vector{Float64}
    values::Vector{Float64}

    function SensorStream(times::AbstractVector{<:Real},
                          values::AbstractVector{<:Real})
        length(times) == length(values) ||
            throw(ArgumentError("times and values must have equal length"))
        length(times) >= 2 ||
            throw(ArgumentError("SensorStream requires at least two samples"))
        issorted(times) ||
            throw(ArgumentError("times must be sorted increasing"))
        return new(Float64.(collect(times)), Float64.(collect(values)))
    end
end

"""
    evaluate(stream::SensorStream, t::Real) -> Float64

Linearly interpolate `stream` at time `t`, clamping to the
endpoint values for `t` outside the stream's time range.
"""
function evaluate(stream::SensorStream, t::Real)
    times, values = stream.times, stream.values
    if t <= times[1]
        return values[1]
    elseif t >= times[end]
        return values[end]
    end
    i = searchsortedlast(times, t)
    if i >= length(times)
        return values[end]
    end
    α = (t - times[i]) / (times[i+1] - times[i])
    return (1 - α) * values[i] + α * values[i+1]
end

"""
    constant_stream(value::Real; t_max::Real=1000.0) -> SensorStream

Constant signal at `value`. Use as a fixed configuration baseline
in non-degeneracy / sanity tests.
"""
function constant_stream(value::Real; t_max::Real=1000.0)
    return SensorStream([0.0, Float64(t_max)], [Float64(value), Float64(value)])
end

"""
    binary_step_stream(t_step::Real, before::Real, after::Real;
                       ramp_τ::Real=0.5, t_max::Real=1000.0,
                       n_samples::Int=200) -> SensorStream

Discrete binary state transition smoothed by a sigmoid ramp of
time constant `ramp_τ`. Models e.g. AC-adapter plug-in or USB
plug events from architecture-design §2.4 ("ramp time ~10 ms is
sufficient to suppress transients while remaining well below
human-perceptible reaction time" — the prototype uses a wider
default for visibility in simulation time units).

WHY a sigmoid (and not a Gaussian convolution): the sigmoid is
monotonic and avoids the pre-event ringing a Gaussian-smoothed
step would create from finite tails. Architecture-design §2.4
calls these "ramp" smoothers without committing to a specific
shape; sigmoid is the simplest monotone choice.
"""
function binary_step_stream(t_step::Real, before::Real, after::Real;
                            ramp_τ::Real=0.5,
                            t_max::Real=1000.0,
                            n_samples::Int=200)
    n_samples >= 4 ||
        throw(ArgumentError("n_samples must be at least 4 for a meaningful ramp"))
    t_grid = collect(range(0.0, Float64(t_max); length=n_samples))
    Δ = Float64(after) - Float64(before)
    vals = similar(t_grid)
    @inbounds for i in eachindex(t_grid)
        x = (t_grid[i] - Float64(t_step)) / Float64(ramp_τ)
        vals[i] = Float64(before) + Δ / (1.0 + exp(-x))
    end
    return SensorStream(t_grid, vals)
end

"""
    gaussian_noise_stream(σ::Real; sample_rate::Real=100.0,
                          t_max::Real=1000.0,
                          rng::AbstractRNG=default_rng()) -> SensorStream

Pre-sampled white-Gaussian noise stream of magnitude `σ` at
`sample_rate` Hz. Models high-bandwidth-noise sensors (thermal,
scheduler-jitter) per architecture-design §2.4. The Nyquist
condition (LL-005) applies: `sample_rate` must exceed any
adversary measurement bandwidth that could reconstruct the stream.

Defaults: `σ=1.0`, `sample_rate=100 Hz`, `t_max=1000 s`. Pass
`rng=Xoshiro(seed)` for deterministic test signals.
"""
function gaussian_noise_stream(σ::Real;
                               sample_rate::Real=100.0,
                               t_max::Real=1000.0,
                               rng::AbstractRNG=default_rng())
    sample_rate > 0 ||
        throw(ArgumentError("sample_rate must be positive"))
    n = max(2, ceil(Int, Float64(t_max) * Float64(sample_rate)))
    t_grid = collect(range(0.0, Float64(t_max); length=n))
    vals = Float64(σ) .* randn(rng, n)
    return SensorStream(t_grid, vals)
end

"""
    CouplingParams

Parameter bundle for sensor-coupled Lorenz-96. Threaded through
`CoupledODEs` as the `p` argument; the EOM reads the streams via
`evaluate` at each integration step.

Fields:
- `F_base::Float64` — uncoupled forcing parameter (Lorenz-96 default 8.0).
- `streams::Vector{SensorStream}` — one entry per sensor channel.
- `alphas::Vector{Float64}` — coupling strength α_k per channel.
- `coupling_vectors::Vector{Vector{Float64}}` — per-dimension
  coupling vector b_k (length must equal SDE dimension N) per
  channel.

Semantics: at integration time t, the perturbed forcing per
component is
```
F_i(t) = F_base + Σ_k alphas[k] · evaluate(streams[k], t) · coupling_vectors[k][i]
```

This is the gradient ∇_x U of the architecture-design §2.4
potential when U is linear in x (`U(s, x) = Σ_k α_k · s_k(t) · ⟨b_k, x⟩`):
the gradient is constant in x, so the sensor coupling is a state-
independent forcing perturbation. State-dependent coupling (U
quadratic-or-higher in x) is a future enhancement.

API STABILITY: experimental.
"""
struct CouplingParams
    F_base::Float64
    streams::Vector{SensorStream}
    alphas::Vector{Float64}
    coupling_vectors::Vector{Vector{Float64}}

    function CouplingParams(F_base::Real,
                            streams::Vector{SensorStream},
                            alphas::Vector{<:Real},
                            coupling_vectors::Vector{<:AbstractVector{<:Real}})
        length(streams) == length(alphas) ||
            throw(ArgumentError("streams and alphas must have equal length"))
        length(streams) == length(coupling_vectors) ||
            throw(ArgumentError("streams and coupling_vectors must have equal length"))
        if !isempty(coupling_vectors)
            N = length(coupling_vectors[1])
            for v in coupling_vectors
                length(v) == N ||
                    throw(ArgumentError("all coupling_vectors must share the same length N"))
            end
        end
        cv = Vector{Vector{Float64}}(undef, length(coupling_vectors))
        @inbounds for k in eachindex(coupling_vectors)
            cv[k] = Float64.(collect(coupling_vectors[k]))
        end
        return new(Float64(F_base),
                   streams,
                   Float64.(collect(alphas)),
                   cv)
    end
end

"""
    no_coupling(F_base::Real=8.0) -> CouplingParams

Empty coupling: zero sensor channels. Used to construct a
sensor-coupled Lorenz-96 that reduces exactly to the uncoupled
baseline, for sanity tests and as a default.
"""
function no_coupling(F_base::Real=8.0)
    return CouplingParams(F_base,
                          SensorStream[],
                          Float64[],
                          Vector{Float64}[])
end

end # module Sensors
