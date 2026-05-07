"""
RealSensors — real-hardware-sensor scaffold (LL-024).

The current Julia prototype uses synthetic sensor streams
(`gaussian_noise_stream`, `constant_stream`, `binary_step_stream`
in `Sensors.jl`) for algorithmic development and testing. This
module is the **scaffold tier** of the real-sensor work landed
in 0.0.38: API stubs are present but their bodies error with a
clear pointer to the scoping companion. Per-platform FFI
implementations (Linux sysfs/procfs first, then macOS IOKit,
then Windows WMI) land in subsequent commits per the
the project-internal companion §2.5 roadmap.

Conventions in force:
- API surface mirrors LL-004's sensor categories: thermal,
  battery, AC adapter, USB, CPU governor, scheduler load.
- Each constructor returns a `SensorStream` (existing type from
  `Sensors.jl`) populated by reading the platform-specific
  hardware sensor at the requested sample rate over the
  requested duration. The output type is unchanged so
  existing `CouplingParams` / `lorenz96_coupled` / `verify`
  pipelines work without modification.
- At scaffold tier, every constructor errors with a meaningful
  message including (a) the sensor name, (b) the platform
  detected, (c) a pointer to the scoping companion. Same
  shape as the 0.0.36 Lean scaffold's `sorry`-only theorems —
  infrastructure-prep, not evidence.

API STABILITY: experimental (scaffold tier; LL-024 :argued at
0.0.38). Stabilises as Phase 1 (Linux baseline) lands.
"""
module RealSensors

using ..Sensors: SensorStream

export real_thermal_stream, real_battery_stream
export real_ac_stream, real_usb_stream
export real_cpu_governor_stream, real_loadavg_stream

"""
    _detect_platform() -> Symbol

Returns one of `:linux`, `:macos`, `:windows`, `:other`. Used by
the per-sensor constructors to dispatch to platform-specific
readers (when those land in Phase 1+).
"""
function _detect_platform()
    Sys.islinux() && return :linux
    Sys.isapple() && return :macos
    Sys.iswindows() && return :windows
    return :other
end

"""
    _scaffold_error(sensor_name::String)

Internal helper. Throws an error indicating the sensor is at
scaffold tier and pointing to the scoping companion for the
implementation roadmap.
"""
function _scaffold_error(sensor_name::String)
    platform = _detect_platform()
    error("""
        RealSensors.$sensor_name not yet implemented on platform :$platform.
        This is scaffold tier (LL-024 :argued at 0.0.38); per-platform
        FFI implementations land per the §2.5 roadmap in
        the project-internal companion (Linux first, then
        macOS, then Windows).

        For development or testing, use a synthetic substitute from
        Sensors.jl:

            using LavaLamp
            stream = gaussian_noise_stream(σ; sample_rate=$(_suggested_rate(sensor_name)),
                                            t_max=t_max)

        where σ matches the expected hardware-sensor magnitude for the
        intended deployment. See the scoping companion §2.3 for per-
        sensor sample-rate guidance.
        """)
end

"""
    _suggested_rate(sensor_name::String) -> Real

Returns a suggested synthetic-substitute sample rate per the
scoping companion §2.3 sample-rate-constraints table. Used in
the scaffold-error message to point users at a working
synthetic configuration while real-sensor FFI lands.
"""
function _suggested_rate(sensor_name::String)
    if sensor_name == "real_thermal_stream"
        return 50.0       # ~10-100 Hz typical; 50 Hz middle
    elseif sensor_name == "real_battery_stream"
        return 5.0        # ~1-10 Hz typical
    elseif sensor_name == "real_ac_stream"
        return 1.0        # event-driven; low rate adequate
    elseif sensor_name == "real_usb_stream"
        return 1.0        # event-driven
    elseif sensor_name == "real_cpu_governor_stream"
        return 50.0       # ~10-100 Hz typical
    elseif sensor_name == "real_loadavg_stream"
        return 5.0        # ~1-10 Hz typical
    else
        return 10.0       # generic fallback
    end
end

# ─── Per-sensor scaffold stubs ─────────────────────────────

"""
    real_thermal_stream(; sample_rate::Real=50.0,
                        t_max::Real=1000.0,
                        sensor_index::Int=1) -> SensorStream

Reads the platform's thermal sensor at `sample_rate` Hz for
`t_max` seconds. `sensor_index` selects between multiple
thermal sensors when the platform exposes more than one
(typical on multi-zone systems).

Per LL-005 Nyquist: `sample_rate > 2 · adversary_bandwidth`
must hold; check at deployment time via
`nyquist_compliant(f_SDE, sample_rate, BW)` (LL-005 part-(a)
predicate from `Sensors.jl`).

Per LL-016 authenticity: real thermal sensors are vulnerable
to V-006 (e.g., a hairdryer drives temperature up). Phase 1
default: cross-validate against battery discharge rate +
CPU governor activity per the §2.4 strategy 2 design.

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux implementation reads
`/sys/class/hwmon/hwmon\$sensor_index/temp*_input` (millidegrees
C, scaled to °C).
"""
function real_thermal_stream(; sample_rate::Real=50.0,
                              t_max::Real=1000.0,
                              sensor_index::Int=1)
    _scaffold_error("real_thermal_stream")
end

"""
    real_battery_stream(; sample_rate::Real=5.0,
                        t_max::Real=1000.0) -> SensorStream

Reads the platform's battery state (typically discharge current
or remaining capacity) at `sample_rate` Hz for `t_max` seconds.

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux reads
`/sys/class/power_supply/BAT*/current_now` (microamps).
"""
function real_battery_stream(; sample_rate::Real=5.0,
                              t_max::Real=1000.0)
    _scaffold_error("real_battery_stream")
end

"""
    real_ac_stream(; sample_rate::Real=1.0,
                   t_max::Real=1000.0) -> SensorStream

Reads the AC adapter online status (binary 0/1) at
`sample_rate` Hz. Discrete-state per LL-005's classification —
the security-relevant content is in transitions, not in
continuous values.

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux reads
`/sys/class/power_supply/AC*/online`.
"""
function real_ac_stream(; sample_rate::Real=1.0,
                        t_max::Real=1000.0)
    _scaffold_error("real_ac_stream")
end

"""
    real_usb_stream(; sample_rate::Real=1.0,
                    t_max::Real=1000.0) -> SensorStream

Reads aggregate USB peripheral state (count of attached
devices, or hash of vendor/product IDs) at `sample_rate` Hz.
Discrete-state per LL-005; transitions on attach/detach.

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux reads
`/sys/bus/usb/devices/*/{vendor,product,bMaxPower}`.
"""
function real_usb_stream(; sample_rate::Real=1.0,
                         t_max::Real=1000.0)
    _scaffold_error("real_usb_stream")
end

"""
    real_cpu_governor_stream(; sample_rate::Real=50.0,
                             t_max::Real=1000.0,
                             cpu_index::Int=0) -> SensorStream

Reads the CPU frequency or governor state at `sample_rate` Hz
for `t_max` seconds. `cpu_index` selects which CPU core
(typically core 0).

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux reads
`/sys/devices/system/cpu/cpu\$cpu_index/cpufreq/scaling_cur_freq`.
"""
function real_cpu_governor_stream(; sample_rate::Real=50.0,
                                   t_max::Real=1000.0,
                                   cpu_index::Int=0)
    _scaffold_error("real_cpu_governor_stream")
end

"""
    real_loadavg_stream(; sample_rate::Real=5.0,
                        t_max::Real=1000.0) -> SensorStream

Reads the system load average (1-minute) at `sample_rate` Hz
for `t_max` seconds. Captures scheduler timing / overall
system busy-ness per LL-004's sensor enumeration.

**Scaffold tier (0.0.38): errors pointing to the scoping
companion.** Phase 1 Linux reads `/proc/loadavg` (first
field).
"""
function real_loadavg_stream(; sample_rate::Real=5.0,
                              t_max::Real=1000.0)
    _scaffold_error("real_loadavg_stream")
end

end # module RealSensors
