"""
LavaLamp — substrate-bound identity primitive (Julia prototype core).

Project status: design-stage → prototype-stage. This module is the P3
prototype core entry point. Architectural design is fixed by the
project's spec discipline; this module implements that design.

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
# Audit (which depends on Engine.lyapunov_spectrum), then
# ChaosGuard (which is self-contained on DynamicalSystems but
# benefits from sitting alongside the others).
include("Sensors.jl")
include("Engine.jl")
include("Audit.jl")
include("ChaosGuard.jl")
include("RealSensors.jl")

using .Sensors: SensorStream, evaluate, CouplingParams, no_coupling
using .Sensors: constant_stream, binary_step_stream, gaussian_noise_stream
using .Sensors: nyquist_compliant
using .Engine: lorenz96, lyapunov_spectrum, lorenz96_coupled
using .Engine: lorenz63, rossler
using .Audit: Envelope, register_envelope, residue, verify, synthetic_adversary
using .Audit: verify_full, verify_constant_time
using .Audit: differentially_private_envelope
using .ChaosGuard: GuardState, INVALID, WARMUP, VALID
using .ChaosGuard: GuardConfig, default_config
using .ChaosGuard: Guard, update!, is_valid, current_lambda, reseed!
using .RealSensors: real_thermal_stream, real_battery_stream
using .RealSensors: real_ac_stream, real_usb_stream
using .RealSensors: real_cpu_governor_stream, real_loadavg_stream

# Engine + spectrum estimator (LL-003).
export lorenz96, lyapunov_spectrum
export lorenz63, rossler

# Sensor-coupling layer (LL-004 / LL-005 / LL-016).
export lorenz96_coupled
export SensorStream, evaluate, CouplingParams, no_coupling
export constant_stream, binary_step_stream, gaussian_noise_stream
export nyquist_compliant

# Residue audit / verifier (LL-006 / LL-017 / LL-019 / LL-020).
export Envelope, register_envelope, residue, verify, synthetic_adversary
export verify_full, verify_constant_time
export differentially_private_envelope

# Chaos-guard / periodic-window safety signal (LL-007 / LL-002).
export GuardState, INVALID, WARMUP, VALID
export GuardConfig, default_config
export Guard, update!, is_valid, current_lambda, reseed!

# Real-sensor scaffold (LL-024). Scaffold tier — calling these
# functions errors pointing to the scoping companion. Per-platform
# FFI implementations land per the Phase 1 / 2 / 3 roadmap.
export real_thermal_stream, real_battery_stream
export real_ac_stream, real_usb_stream
export real_cpu_governor_stream, real_loadavg_stream

end # module LavaLamp
