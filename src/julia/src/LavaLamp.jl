"""
LavaLamp — substrate-bound identity primitive (Julia prototype core).

Project status: design-stage → prototype-stage. This module is the P3
prototype core entry point. Architectural design is fixed in
`docs/architecture_design_companion.md`; this module implements that
design under the discipline declared in `LAVALAMP_SPEC.md`.

Conventions in force:
- Real-valued mathematics throughout (LL-009 boundary).
- Bounded-window analysis only; no open-ended simulation (LL-010).
- Visual layer is decoupled and lives elsewhere; this module is the
  security primitive only (LL-002).

API STABILITY: experimental (P3-stage). Public functions stabilise as
spec entries close to `:tested` / `:verified` / `:benchmarked`.
"""
module LavaLamp

include("Engine.jl")

using .Engine: lorenz96, lyapunov_spectrum, lorenz96_coupled
using .Engine: SensorStream, evaluate, CouplingParams, no_coupling
using .Engine: constant_stream, binary_step_stream, gaussian_noise_stream

# Engine + spectrum estimator (LL-003).
export lorenz96, lyapunov_spectrum

# Sensor-coupling layer (LL-004 / LL-005 / LL-016).
export lorenz96_coupled
export SensorStream, evaluate, CouplingParams, no_coupling
export constant_stream, binary_step_stream, gaussian_noise_stream

end # module LavaLamp
