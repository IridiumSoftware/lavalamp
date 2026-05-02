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

# Submodule load order matters: Sensors first (Engine and Audit
# both reference Sensors types via ..Sensors), then Engine, then
# Audit (which depends on both Sensors types and Engine.lyapunov_spectrum).
include("Sensors.jl")
include("Engine.jl")
include("Audit.jl")

using .Sensors: SensorStream, evaluate, CouplingParams, no_coupling
using .Sensors: constant_stream, binary_step_stream, gaussian_noise_stream
using .Engine: lorenz96, lyapunov_spectrum, lorenz96_coupled
using .Audit: Envelope, register_envelope, residue, verify, synthetic_adversary

# Engine + spectrum estimator (LL-003).
export lorenz96, lyapunov_spectrum

# Sensor-coupling layer (LL-004 / LL-005 / LL-016).
export lorenz96_coupled
export SensorStream, evaluate, CouplingParams, no_coupling
export constant_stream, binary_step_stream, gaussian_noise_stream

# Residue audit / verifier (LL-006 / LL-017).
export Envelope, register_envelope, residue, verify, synthetic_adversary

end # module LavaLamp
