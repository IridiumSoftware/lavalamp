"""
RealSensors — real-hardware-sensor readers (LL-024).

The current Julia prototype uses synthetic sensor streams
(`gaussian_noise_stream`, `constant_stream`, `binary_step_stream`
in `Sensors.jl`) for algorithmic development and testing. This
module provides **real-hardware** readers that populate
`SensorStream` from actual platform sensor sources.

Per-platform implementation status:

- **Linux** (Phase 1): implemented in pure Julia file-I/O
  against the standard sysfs/procfs paths documented in each
  reader's docstring. Works on any Linux box that exposes
  the canonical `/sys/class/...` and `/proc/...` interfaces.
- **macOS / Windows / other**: scaffold-tier. Each reader
  errors with a clear message naming (a) the platform
  detected, (b) the per-platform implementation hook
  required (Darwin IOKit, Windows WMI), (c) the synthetic
  substitute for development.

Each public reader returns a `SensorStream` (existing type
from `Sensors.jl`) populated by sampling the platform's
hardware sensor at `sample_rate` Hz for `t_max` seconds. The
output type is unchanged so existing `CouplingParams` /
`lorenz96_coupled` / `verify` pipelines work without
modification.

**Wall-clock note.** The readers block synchronously for
`t_max` seconds while sampling. Default `t_max=10.0`; production
deployments record longer windows aligned with the verify
cadence (the default is intentionally short so unit tests can
exercise the readers without hanging). For long-window
recording in a verify pipeline, call from a `Threads.@spawn`
task and `fetch` the resulting stream when verify is ready.

API STABILITY: experimental (LL-024 :argued; Phase 1 partial
coverage). Stabilises as macOS / Windows implementations land.
"""
module RealSensors

using ..Sensors: SensorStream

export real_thermal_stream, real_battery_stream
export real_ac_stream, real_usb_stream
export real_cpu_governor_stream, real_loadavg_stream
export record_stream

# ─── Platform detection + scaffold-error helpers ───────────

"""
    _detect_platform() -> Symbol

Returns one of `:linux`, `:macos`, `:windows`, `:other`. Used
by per-sensor public readers to dispatch to platform-specific
backends.
"""
function _detect_platform()
    Sys.islinux() && return :linux
    Sys.isapple() && return :macos
    Sys.iswindows() && return :windows
    return :other
end

"""
    _suggested_rate(sensor_name::String) -> Real

Returns a suggested synthetic-substitute sample rate per the
scoping companion §2.3 sample-rate-constraints table. Used in
the scaffold-error message.
"""
function _suggested_rate(sensor_name::String)
    if sensor_name == "real_thermal_stream"
        return 50.0
    elseif sensor_name == "real_battery_stream"
        return 5.0
    elseif sensor_name == "real_ac_stream"
        return 1.0
    elseif sensor_name == "real_usb_stream"
        return 1.0
    elseif sensor_name == "real_cpu_governor_stream"
        return 50.0
    elseif sensor_name == "real_loadavg_stream"
        return 5.0
    else
        return 10.0
    end
end

"""
    _scaffold_error(sensor_name)

Throws an error indicating the sensor is not yet implemented
on the detected platform and pointing at (a) the per-platform
implementation hook needed and (b) the synthetic substitute
for development.
"""
function _scaffold_error(sensor_name::String)
    platform = _detect_platform()
    hook = if platform == :macos
        "Darwin hook: IOKit framework via `IOServiceGetMatchingServices` + " *
        "thermal/battery/AC properties. Phase 2 roadmap."
    elseif platform == :windows
        "Windows hook: WMI / PerfCounters via `GetSystemTimes`, " *
        "`Win32_TemperatureProbe`, `Win32_Battery`. Phase 3 roadmap."
    else
        "Platform-specific hooks required; no roadmap commitment yet."
    end
    error("""
        RealSensors.$sensor_name not yet implemented on platform :$platform.
        Phase 1 (Linux) is implemented in this module via sysfs/procfs;
        non-Linux platforms remain scaffold tier.

        $hook

        For development or testing on this platform, use a synthetic
        substitute from Sensors.jl:

            using LavaLamp
            stream = gaussian_noise_stream(σ; sample_rate=$(_suggested_rate(sensor_name)),
                                            t_max=t_max)

        where σ matches the expected hardware-sensor magnitude for the
        intended deployment. See the scoping companion (project-internal)
        for per-sensor sample-rate guidance.
        """)
end

# ─── Generic recording helper ──────────────────────────────

"""
    record_stream(reader::Function;
                  sample_rate::Real=10.0,
                  t_max::Real=10.0) -> SensorStream

Synchronous-recording helper. Calls `reader()` at `sample_rate`
Hz for `t_max` seconds, building a `SensorStream` from the
collected (time, value) pairs.

`reader` is any zero-argument function returning a real-valued
sample. This is the platform-independent core of all the
per-sensor public readers in this module — they construct an
appropriate `reader` closure and call this function. It is
also the test seam: tests exercise the recording logic by
passing a synthetic Julia closure as `reader`.

Wall-clock blocks for approximately `t_max` seconds (modulo
OS scheduling jitter). Returns a `SensorStream` covering
`t ∈ [0, t_max]` with `n = floor(t_max · sample_rate) + 1`
samples.
"""
function record_stream(reader::Function;
                       sample_rate::Real=10.0,
                       t_max::Real=10.0)
    sample_rate > 0 ||
        throw(ArgumentError("sample_rate must be positive"))
    t_max > 0 ||
        throw(ArgumentError("t_max must be positive"))

    dt = 1.0 / Float64(sample_rate)
    n_samples = floor(Int, Float64(t_max) / dt) + 1
    n_samples >= 2 || (n_samples = 2)  # SensorStream requires ≥ 2 samples

    times = Vector{Float64}(undef, n_samples)
    values = Vector{Float64}(undef, n_samples)

    t_start = time()
    @inbounds for i in 1:n_samples
        target_t = (i - 1) * dt
        # Sleep until the target sample time (relative to start).
        elapsed = time() - t_start
        if elapsed < target_t
            sleep(target_t - elapsed)
        end
        times[i] = target_t
        values[i] = Float64(reader())
    end

    return SensorStream(times, values)
end

# ─── Linux Phase 1 readers ─────────────────────────────────

"""
    _read_thermal_linux_value(sensor_index::Int=1;
                               root::String="/sys/class/hwmon") -> Float64

Reads the platform's thermal sensor and returns a temperature
in degrees Celsius. Looks for the first `temp*_input` file in
`{root}/hwmon{sensor_index}/`; the kernel reports the value
in millidegrees C (per hwmon convention), so the read value
is divided by 1000.

Falls back to `/sys/class/thermal/thermal_zone0/temp` if the
hwmon path is unavailable (this is also millidegrees C).

Throws `SystemError` if no thermal source is found. Tests
override `root` to read fixture directories.
"""
function _read_thermal_linux_value(sensor_index::Int=1;
                                    root::String="/sys/class/hwmon")
    hwmon_dir = joinpath(root, "hwmon$(sensor_index - 1)")
    if isdir(hwmon_dir)
        for entry in readdir(hwmon_dir)
            if occursin(r"^temp\d+_input$", entry)
                path = joinpath(hwmon_dir, entry)
                val_str = strip(read(path, String))
                return parse(Int, val_str) / 1000.0
            end
        end
    end
    # Fallback: thermal_zone
    fallback = "/sys/class/thermal/thermal_zone0/temp"
    if isfile(fallback)
        val_str = strip(read(fallback, String))
        return parse(Int, val_str) / 1000.0
    end
    error("RealSensors: no thermal sensor found at $hwmon_dir or $fallback")
end

"""
    _read_battery_current_linux_value(; root::String="/sys/class/power_supply") -> Float64

Reads battery instantaneous current (microamps) from the first
`BAT*` directory under `root`. Returns `0.0` if no battery is
present (desktop / server systems).
"""
function _read_battery_current_linux_value(;
                                            root::String="/sys/class/power_supply")
    isdir(root) || return 0.0
    for entry in readdir(root)
        if startswith(entry, "BAT")
            path = joinpath(root, entry, "current_now")
            if isfile(path)
                val_str = strip(read(path, String))
                return Float64(parse(Int, val_str))
            end
        end
    end
    return 0.0
end

"""
    _read_ac_online_linux_value(; root::String="/sys/class/power_supply") -> Float64

Reads AC-adapter online status (`0` or `1`) from the first
`AC*` directory under `root`. Returns `0.0` if no AC source
is reported (battery-only / unknown).
"""
function _read_ac_online_linux_value(;
                                      root::String="/sys/class/power_supply")
    isdir(root) || return 0.0
    for entry in readdir(root)
        # AC adapters typically named "AC", "AC0", "ACAD", "ADP1", etc.
        if startswith(entry, "AC") || startswith(entry, "ADP")
            path = joinpath(root, entry, "online")
            if isfile(path)
                val_str = strip(read(path, String))
                return Float64(parse(Int, val_str))
            end
        end
    end
    return 0.0
end

"""
    _read_usb_count_linux_value(; root::String="/sys/bus/usb/devices") -> Float64

Returns the count of USB devices currently attached. Discrete
state per LL-005; transitions on attach/detach events are the
security-relevant content.
"""
function _read_usb_count_linux_value(;
                                      root::String="/sys/bus/usb/devices")
    isdir(root) || return 0.0
    # Filter to actual USB device entries (numeric or starting with digit).
    n = 0
    for entry in readdir(root)
        if !isempty(entry) && isdigit(first(entry))
            n += 1
        end
    end
    return Float64(n)
end

"""
    _read_cpu_freq_linux_value(cpu_index::Int=0;
                                root::String="/sys/devices/system/cpu") -> Float64

Reads the current CPU scaling frequency in kHz for the
specified core. Returns `0.0` if cpufreq is unavailable
(e.g. virtualised hosts where the kernel reports no
`scaling_cur_freq`).
"""
function _read_cpu_freq_linux_value(cpu_index::Int=0;
                                     root::String="/sys/devices/system/cpu")
    path = joinpath(root, "cpu$(cpu_index)", "cpufreq", "scaling_cur_freq")
    isfile(path) || return 0.0
    val_str = strip(read(path, String))
    return Float64(parse(Int, val_str))
end

"""
    _read_loadavg_linux_value(; path::String="/proc/loadavg") -> Float64

Reads the 1-minute load average from `/proc/loadavg`. The
file's first whitespace-separated token is the 1-minute load
(per kernel docs).
"""
function _read_loadavg_linux_value(;
                                    path::String="/proc/loadavg")
    isfile(path) || return 0.0
    contents = strip(read(path, String))
    first_token = first(split(contents))
    return parse(Float64, first_token)
end

# ─── Per-sensor public readers ─────────────────────────────

"""
    real_thermal_stream(; sample_rate::Real=50.0,
                        t_max::Real=10.0,
                        sensor_index::Int=1) -> SensorStream

Reads the platform's thermal sensor at `sample_rate` Hz for
`t_max` seconds. `sensor_index` (1-based) selects between
multiple thermal sensors when the platform exposes more than
one (typical on multi-zone systems).

**Linux Phase 1 implementation.** Reads `temp*_input` under
`/sys/class/hwmon/hwmon{sensor_index-1}/` (millidegrees C,
scaled to °C). Falls back to `/sys/class/thermal/thermal_zone0/temp`
if hwmon is unavailable.

**macOS / Windows / other**: errors with a per-platform
implementation pointer. Use `gaussian_noise_stream` for
development.

Per LL-005 Nyquist: `sample_rate > 2 · adversary_bandwidth`
must hold. Per LL-016 authenticity: real thermal sensors are
vulnerable to V-006 (e.g., a hairdryer drives temperature up);
LL-029 multi-channel cross-validation is the deployment-tier
defense.
"""
function real_thermal_stream(; sample_rate::Real=50.0,
                              t_max::Real=10.0,
                              sensor_index::Int=1)
    if _detect_platform() == :linux
        reader = () -> _read_thermal_linux_value(sensor_index)
        return record_stream(reader; sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_thermal_stream")
end

"""
    real_battery_stream(; sample_rate::Real=5.0,
                        t_max::Real=10.0) -> SensorStream

Reads battery discharge current at `sample_rate` Hz for
`t_max` seconds.

**Linux Phase 1**: reads `current_now` (microamps) from the
first `/sys/class/power_supply/BAT*` directory. Returns `0.0`
on desktops / servers without a battery (still produces a
`SensorStream` with all-zero values; callers should
cross-validate with other sensors per LL-029).

**Other platforms**: scaffold error.
"""
function real_battery_stream(; sample_rate::Real=5.0,
                              t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_battery_current_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_battery_stream")
end

"""
    real_ac_stream(; sample_rate::Real=1.0,
                   t_max::Real=10.0) -> SensorStream

Reads AC-adapter online status (0/1) at `sample_rate` Hz.
Discrete-state per LL-005's classification — security-relevant
content is in transitions, not in continuous values.

**Linux Phase 1**: reads `online` from the first
`/sys/class/power_supply/AC*` or `/sys/class/power_supply/ADP*`
directory.

**Other platforms**: scaffold error.
"""
function real_ac_stream(; sample_rate::Real=1.0,
                        t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_ac_online_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_ac_stream")
end

"""
    real_usb_stream(; sample_rate::Real=1.0,
                    t_max::Real=10.0) -> SensorStream

Reads aggregate USB peripheral count at `sample_rate` Hz.
Discrete-state per LL-005; transitions on attach/detach.

**Linux Phase 1**: counts entries under `/sys/bus/usb/devices/`
whose name starts with a digit (filtering out hub / controller
metadata entries).

**Other platforms**: scaffold error.
"""
function real_usb_stream(; sample_rate::Real=1.0,
                         t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_usb_count_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_usb_stream")
end

"""
    real_cpu_governor_stream(; sample_rate::Real=50.0,
                             t_max::Real=10.0,
                             cpu_index::Int=0) -> SensorStream

Reads CPU scaling frequency (kHz) for the specified core at
`sample_rate` Hz.

**Linux Phase 1**: reads
`/sys/devices/system/cpu/cpu{cpu_index}/cpufreq/scaling_cur_freq`.
Returns `0.0` for cores where cpufreq is unavailable
(virtualised hosts).

**Other platforms**: scaffold error.
"""
function real_cpu_governor_stream(; sample_rate::Real=50.0,
                                   t_max::Real=10.0,
                                   cpu_index::Int=0)
    if _detect_platform() == :linux
        reader = () -> _read_cpu_freq_linux_value(cpu_index)
        return record_stream(reader; sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_cpu_governor_stream")
end

"""
    real_loadavg_stream(; sample_rate::Real=5.0,
                        t_max::Real=10.0) -> SensorStream

Reads 1-minute system load average at `sample_rate` Hz.

**Linux Phase 1**: reads first whitespace-separated token from
`/proc/loadavg` (per kernel docs).

**Other platforms**: scaffold error.
"""
function real_loadavg_stream(; sample_rate::Real=5.0,
                              t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_loadavg_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_loadavg_stream")
end

end # module RealSensors
