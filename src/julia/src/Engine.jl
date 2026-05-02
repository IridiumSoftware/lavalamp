"""
Engine — chaotic SDE substrate for the security primitive.

Implements Lorenz-96 as the candidate single-attractor chaotic engine
(LL-003) and the Lyapunov-spectrum estimator that drives the residue
audit (LL-006) and the chaos-guard (LL-007). Sensor coupling
(LL-004 / LL-005) and the residue audit proper land in subsequent
modules.

Conventions in force:
- ODE form, deterministic dynamics. Stochastic perturbation (the σ dW
  term in the §2.4 design) lands when sensor coupling does.
- Periodic boundary on Lorenz-96: index arithmetic uses 1-based
  modular arithmetic (i+1 wraps 1; i-1 wraps to N; i-2 wraps to
  N-1, N as appropriate).
- F is the single scalar forcing parameter; chaotic for F ≳ 4 in
  the standard parameter range.

Reference values (literature):
- Lorenz-96 N=40, F=8: λ₁ ≈ 1.66 (Karimi & Paul 2010), ergodic on
  a strange attractor of fractal dimension ≈ 27 by Kaplan-Yorke.

API STABILITY: experimental (P3-stage).
"""
module Engine

using DynamicalSystems

# Sensors is a sibling submodule under LavaLamp; this module
# references its types via the parent namespace. This keeps
# Audit and Engine on equal footing as consumers of Sensors.
using ..Sensors: SensorStream, evaluate, CouplingParams, no_coupling
using ..Sensors: constant_stream, binary_step_stream, gaussian_noise_stream

export lorenz96, lyapunov_spectrum, lorenz96_coupled

"""
    lorenz96_eom!(du, u, p, t)

In-place Lorenz-96 right-hand side. Conventions:
- Periodic boundary: i+1, i-1, i-2 indices wrap modulo N.
- p[1] = F (forcing).
- du[i] = (u[i+1] - u[i-2]) * u[i-1] - u[i] + F.

WHY this primitive and not Lorenz-63 or Rössler: Lorenz-96 is
high-dimensional (variable N), has high λ₁, is parameter-sensitive,
and has the richest Lyapunov spectrum of the three candidates. The
SDE-selection benchmark across all three is a follow-up; Lorenz-96
is the leading candidate per the design pass and is the prototype's
default.

PERFORMANCE NOTE: in-place form (`du, u, p, t` signature) is required
by DynamicalSystems.jl v3 when N > a small SVector threshold, and it
avoids per-step allocation. Memory-fits-in-RAM is assumed at the
N ≤ ~10⁴ scale.
"""
function lorenz96_eom!(du, u, p, t)
    N = length(u)
    F = p[1]
    @inbounds for i in 1:N
        ip1 = i == N ? 1 : i + 1
        im1 = i == 1 ? N : i - 1
        im2 = i <= 2 ? (i == 1 ? N - 1 : N) : i - 2
        du[i] = (u[ip1] - u[im2]) * u[im1] - u[i] + F
    end
    return nothing
end

"""
    lorenz96(N::Int=40; F::Float64=8.0, u0=nothing)

Construct a `CoupledODEs` dynamical system implementing Lorenz-96.

Defaults: N = 40 dimensions, F = 8.0 (the canonical chaotic-regime
parameter pair). `u0=nothing` triggers a small perturbation around
the F·𝟙 fixed point: `u0 = F .+ 0.1·randn(N)`.

# Examples
```julia-repl
julia> ds = lorenz96(40; F=8.0);
julia> λs = lyapunov_spectrum(ds);
julia> λs[1]  # ≈ 1.66 within estimator tolerance
```

API STABILITY: stable shape; the *parameter defaults* (N, F) are
intentional and not for tuning at call sites without spec impact.
"""
function lorenz96(N::Int=40; F::Float64=8.0, u0=nothing)
    state = u0 === nothing ? F .+ 0.1 .* randn(N) : copy(u0)
    p = [F]
    return CoupledODEs(lorenz96_eom!, state, p)
end

"""
    lyapunov_spectrum(ds; N::Int=5000, Δt::Float64=0.05, Ttr::Float64=1000.0)

Estimate the full Lyapunov spectrum of `ds` via Benettin's QR-
reorthonormalization algorithm, as exposed by ChaosTools through the
DynamicalSystems v3 metapackage.

Returns: `Vector{Float64}` of length `dimension(ds)`, exponents in
decreasing order.

Parameters:
- `N`: number of QR re-orthonormalization steps. Variance of λ̂ᵢ is
  ~1/N; N=5000 is a reasonable accuracy/cost trade-off for Lorenz-96.
- `Δt`: time between QR steps. Too large allows tangent vectors to
  align with the dominant direction (loses higher-spectrum
  resolution); too small wastes compute on uninformative reorthog.
  0.05 is the standard Lorenz-96 setting.
- `Ttr`: transient discarded before measurement begins. Lorenz-96 at
  N=40, F=8 reaches the strange attractor within ~10 time units;
  Ttr=1000 is generous and reliable.

API STABILITY: stable.
"""
function lyapunov_spectrum(ds; N::Int=5000, Δt::Float64=0.05, Ttr::Float64=1000.0)
    return lyapunovspectrum(ds, N; Δt=Δt, Ttr=Ttr)
end

"""
    lorenz96_coupled_eom!(du, u, p::CouplingParams, t)

Sensor-coupled Lorenz-96 right-hand side. Per-component perturbed
forcing per architecture-design §2.4:

```
F_i(t) = F_base + Σ_k alphas[k] · evaluate(streams[k], t) · coupling_vectors[k][i]
du[i]  = (u[i+1] - u[i-2]) * u[i-1] - u[i] + F_i(t)
```

Sensor evaluations are *hoisted* out of the per-component loop —
they are per-step, not per-component. Per-step heap allocation
of the s_vals scratch buffer is small (length = number of sensors,
typically ≤ 10) and dominated by the integrator's internal work.

Reduces to the uncoupled `lorenz96_eom!` when `p.streams` is empty.
"""
function lorenz96_coupled_eom!(du, u, p::CouplingParams, t)
    N = length(u)
    n_sensors = length(p.streams)
    s_vals = Vector{Float64}(undef, n_sensors)
    @inbounds for k in 1:n_sensors
        s_vals[k] = p.alphas[k] * evaluate(p.streams[k], t)
    end
    @inbounds for i in 1:N
        ip1 = i == N ? 1 : i + 1
        im1 = i == 1 ? N : i - 1
        im2 = i <= 2 ? (i == 1 ? N - 1 : N) : i - 2
        F_i = p.F_base
        for k in 1:n_sensors
            F_i += s_vals[k] * p.coupling_vectors[k][i]
        end
        du[i] = (u[ip1] - u[im2]) * u[im1] - u[i] + F_i
    end
    return nothing
end

"""
    lorenz96_coupled(N::Int=40; F::Float64=8.0,
                     coupling::Union{Nothing,CouplingParams}=nothing,
                     u0=nothing)

Construct a sensor-coupled `CoupledODEs` from `lorenz96_coupled_eom!`
with parameters from `coupling`. `coupling=nothing` uses
`no_coupling(F)` and the system reduces exactly to uncoupled
Lorenz-96 at parameter F.

API STABILITY: experimental.
"""
function lorenz96_coupled(N::Int=40; F::Float64=8.0,
                          coupling::Union{Nothing,CouplingParams}=nothing,
                          u0=nothing)
    state = u0 === nothing ? F .+ 0.1 .* randn(N) : copy(u0)
    p = coupling === nothing ? no_coupling(F) : coupling
    return CoupledODEs(lorenz96_coupled_eom!, state, p)
end

end # module Engine
