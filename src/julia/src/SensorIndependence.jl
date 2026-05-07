"""
LavaLamp.SensorIndependence — multi-channel entropy independence
analysis for the LL-029 deployment-time calibration check.

LL-029 (multi-channel-entropy-independence) requires that a
deployment's sensor set spans *uncorrelated physical mechanisms*,
not merely *uncorrelated sensors*. The sensor-fusion-inversion
attack class (V-018) defeats LL-016 Strategy 2 cross-validation
by physically coupling channels to satisfy the cross-validation
constraints rather than violate them — heater + thermal +
battery share one physical mechanism, so the cross-check on
their readings passes even under coordinated adversarial
manipulation.

The defense is operational: at registration time, classify the
sensor set into physical-mechanism families by cross-correlation
over a calibration window. Pairs of streams with `|ρ| >
ρ_threshold` are flagged as same-family and counted as one
entropy source. Deployments where the resulting `n_families < 2`
fail the LL-029 independence requirement.

Default parameters per the LL-029 spec: `ρ_threshold = 0.3`,
60-second calibration window. Both are deployment-tunable.

Algorithm: union-find over the threshold-graph (streams are
nodes; edges connect pairs with `|ρ| > ρ_threshold`; families
are connected components). Pearson correlation; constant
streams (zero variance) treated as orthogonal to everything
else.

API STABILITY: stable shape. The `FamilyClassification` record
is the canonical return type for classify_families; downstream
verifiers (e.g. an LL-028 runtime conformance check) will
inspect `n_families` and `ρ`.
"""
module SensorIndependence

using ..Sensors: SensorStream, evaluate
using Statistics: std, cor

export correlation_matrix, classify_families, n_independent_families
export FamilyClassification

"""
    FamilyClassification

Result of running family-classification on a set of sensor streams.

Fields:
- `n_families::Int` — number of independent physical-mechanism
  families detected.
- `assignments::Vector{Int}` — family ID per stream, in the
  range `1..n_families`. Two streams with the same assignment
  share a physical mechanism (same family).
- `ρ::Matrix{Float64}` — pairwise Pearson correlation matrix
  over the calibration window. Symmetric; diagonal = 1.0;
  off-diagonal = 0.0 if either stream has zero variance.
- `ρ_threshold::Float64` — threshold that was used for
  family-merging (`|ρ| > threshold` ⇒ same family).
"""
struct FamilyClassification
    n_families::Int
    assignments::Vector{Int}
    ρ::Matrix{Float64}
    ρ_threshold::Float64
end

"""
    correlation_matrix(streams::AbstractVector{SensorStream};
                       t_start::Real=0.0,
                       window_s::Real=60.0,
                       n_samples::Int=600) -> Matrix{Float64}

Compute the pairwise Pearson cross-correlation matrix for a set
of sensor streams over a calibration window
`[t_start, t_start + window_s]`.

Each stream is sampled at `n_samples` uniformly-spaced points
within the window via `Sensors.evaluate`; the resulting sample
vectors feed into `Statistics.cor`. Constant streams (zero
variance) yield correlation `0.0` against any other stream —
they carry no information that a cross-validation algorithm
could exploit, so they're treated as orthogonal to all other
channels.

Returns: `Matrix{Float64}` of size `N × N`, symmetric, diagonal
= `1.0`.
"""
function correlation_matrix(streams::AbstractVector{SensorStream};
                            t_start::Real=0.0,
                            window_s::Real=60.0,
                            n_samples::Int=600)
    n_samples >= 2 ||
        throw(ArgumentError("n_samples must be at least 2"))
    window_s > 0 ||
        throw(ArgumentError("window_s must be positive"))
    n = length(streams)
    if n == 0
        return Matrix{Float64}(undef, 0, 0)
    end

    times = range(Float64(t_start),
                  Float64(t_start) + Float64(window_s);
                  length=n_samples)
    samples = [Float64[evaluate(s, t) for t in times] for s in streams]

    ρ = Matrix{Float64}(undef, n, n)
    @inbounds for i in 1:n
        ρ[i, i] = 1.0
        for j in (i+1):n
            ρij = _pearson(samples[i], samples[j])
            ρ[i, j] = ρij
            ρ[j, i] = ρij
        end
    end
    return ρ
end

"""Pearson correlation; returns `0.0` if either input has zero
variance (constant streams carry no information for
cross-validation)."""
function _pearson(x::AbstractVector, y::AbstractVector)
    σx = std(x)
    σy = std(y)
    if σx == 0 || σy == 0
        return 0.0
    end
    return cor(x, y)
end

"""
    classify_families(streams::AbstractVector{SensorStream};
                      ρ_threshold::Real=0.3,
                      t_start::Real=0.0,
                      window_s::Real=60.0,
                      n_samples::Int=600) -> FamilyClassification

Classify a set of sensor streams into physical-mechanism
families by cross-correlation. Streams with `|ρ| > ρ_threshold`
are flagged same-family.

The threshold is taken on the *absolute value* of the
correlation: anti-correlated streams (e.g. one rises while the
other falls because both track the same underlying mechanism
with opposite sign) still indicate a shared mechanism and merge
to the same family.

LL-029 spec defaults: `ρ_threshold = 0.3`, 60-second calibration
window, 600 samples (10 Hz over a minute).

Algorithm: union-find with path compression on the
threshold-graph (streams are nodes; pairs with `|ρ| >
ρ_threshold` get an edge; families are connected components).
Family IDs are normalized to `1..n_families` in the order they
appear when scanning streams left-to-right.
"""
function classify_families(streams::AbstractVector{SensorStream};
                           ρ_threshold::Real=0.3,
                           t_start::Real=0.0,
                           window_s::Real=60.0,
                           n_samples::Int=600)
    ρ_threshold >= 0 ||
        throw(ArgumentError("ρ_threshold must be non-negative"))

    ρ = correlation_matrix(streams;
                           t_start=t_start,
                           window_s=window_s,
                           n_samples=n_samples)
    n = length(streams)
    if n == 0
        return FamilyClassification(0, Int[], ρ, Float64(ρ_threshold))
    end

    # Union-find with path compression
    parent = collect(1:n)

    function find(x)
        r = x
        while parent[r] != r
            r = parent[r]
        end
        # Path compression
        while parent[x] != r
            parent[x], x = r, parent[x]
        end
        return r
    end

    function union!(x, y)
        rx, ry = find(x), find(y)
        if rx != ry
            parent[rx] = ry
        end
    end

    @inbounds for i in 1:n, j in (i+1):n
        if abs(ρ[i, j]) > ρ_threshold
            union!(i, j)
        end
    end

    # Normalize family IDs in order of first appearance
    roots = [find(i) for i in 1:n]
    root_to_family = Dict{Int,Int}()
    next_id = 1
    assignments = Vector{Int}(undef, n)
    @inbounds for i in 1:n
        r = roots[i]
        fid = get(root_to_family, r, 0)
        if fid == 0
            fid = next_id
            root_to_family[r] = fid
            next_id += 1
        end
        assignments[i] = fid
    end

    return FamilyClassification(length(root_to_family),
                                 assignments,
                                 ρ,
                                 Float64(ρ_threshold))
end

"""
    n_independent_families(streams; kwargs...) -> Int

Convenience wrapper: returns just the family count from
`classify_families`. Use this when only the count matters
(e.g. asserting `n_independent_families(streams) >= 2` as a
deployment-time independence check).
"""
function n_independent_families(streams::AbstractVector{SensorStream};
                                 kwargs...)
    return classify_families(streams; kwargs...).n_families
end

end # module SensorIndependence
