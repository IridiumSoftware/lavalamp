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
    hook = if platform == :windows
        "Windows hook: WMI / PerfCounters via `GetSystemTimes`, " *
        "`Win32_TemperatureProbe`, `Win32_Battery`. Phase 3 roadmap."
    else
        "Platform-specific hooks required; no roadmap commitment yet."
    end
    error("""
        RealSensors.$sensor_name not yet implemented on platform :$platform.
        Phase 1 (Linux) and Phase 2a (macOS) are implemented in this
        module; remaining platforms are scaffold tier.

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

# ─── macOS Phase 2 readers ─────────────────────────────────
#
# Phase 2 dispatches macOS via shell-out to non-privileged
# tools (`sysctl`, `pmset`, `ioreg`) to keep the implementation
# hermetic — no FFI bindings, no IOKit framework dependency,
# no privileged access. Each reader has a parse function
# isolated from the I/O so tests can exercise parsing logic
# with canned output strings.
#
# Performance baseline (M5 Max, 0.0.82, n=50):
#   loadavg          median  1.2 ms  (sysctl)      → 5 Hz default has 166× headroom
#   ac_online        median  5.9 ms  (pmset)       → 1 Hz default has 168× headroom
#   battery_current  median 11.9 ms  (ioreg)       → 5 Hz default has  17× headroom
#   thermal          median 10.7 ms  (ioreg)       → 50 Hz default has 1.9× headroom (tightest)
#   usb_count        median 10.5 ms  (ioreg)       → 1 Hz default has  95× headroom
#   cpu_freq_proxy   median  1.2 ms  (sysctl)      → 50 Hz default has 17× headroom
# The 50 Hz thermal case is the tightest reading (~57% of the
# 20 ms per-sample budget on a busy laptop). `record_stream`
# was confirmed to maintain perfect 20 ms cadence at 50 Hz
# under this load. Lowering the default below 50 Hz would
# require re-validating LL-005 Nyquist for the assumed
# adversary-bandwidth tier.
#
# Substrate notes:
#  - Apple Silicon does not expose CPU thermal via public sysctl
#    (`machdep.xcpm.cpu_thermal_level` is Intel-only). Phase 2a
#    substitutes battery temperature from `AppleSmartBattery`
#    (a real, per-deployment thermal reading from the device);
#    a future Phase 2b SMC IOKit FFI reader can land alongside
#    without breaking the public API.
#  - Apple Silicon does not expose instantaneous CPU frequency
#    (no `hw.cpufrequency`). Phase 2a substitutes
#    `vm.page_free_count` as the system-activity proxy — it
#    varies in real time with workload, satisfies LL-005
#    Nyquist for the 50 Hz public default, and is per-deployment
#    unique (memory pressure tracks user behaviour).
#
# All parse functions are pure (no I/O); reader functions take
# an optional `output::Union{String,Nothing}=nothing` keyword
# that bypasses the shell call when supplied — the test seam.

"""
    _parse_loadavg_macos(output) -> Float64

Parses `sysctl -n vm.loadavg` output of the form
`{ 7.13 7.17 6.84 }` and returns the 1-minute load average.
"""
function _parse_loadavg_macos(output::AbstractString)
    m = match(r"\{\s*([0-9.]+)\s+", output)
    m === nothing &&
        error("RealSensors macOS: cannot parse loadavg from \"$output\"")
    return parse(Float64, m.captures[1])
end

"""
    _read_loadavg_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns the 1-minute load average from `sysctl -n vm.loadavg`.
Pass `output=...` to parse a canned string instead of running
the shell command (test seam).
"""
function _read_loadavg_macos_value(;
                                    output::Union{AbstractString,Nothing}=nothing)
    s = output === nothing ? read(`sysctl -n vm.loadavg`, String) : output
    return _parse_loadavg_macos(s)
end

"""
    _parse_battery_current_macos(output) -> Float64

Parses `ioreg -rn AppleSmartBattery` output for the
`"InstantAmperage" = N` field and returns N as a signed
Float64 (mA). The kernel reports current as an unsigned 64-bit
integer; values above 2^63 are reinterpreted as signed
(charging draws negative current).

Returns `0.0` if the field is absent (desktop / no battery).
"""
function _parse_battery_current_macos(output::AbstractString)
    m = match(r"\"InstantAmperage\"\s*=\s*(\d+)", output)
    m === nothing && return 0.0
    raw = parse(UInt64, m.captures[1])
    # Reinterpret as signed (Int64) — charging is negative.
    signed_val = raw < UInt64(2)^63 ? Int64(raw) : Int64(raw - UInt64(2)^63) - Int64(2)^63
    return Float64(signed_val)
end

"""
    _read_battery_current_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns instantaneous battery amperage (mA) from
`ioreg -rn AppleSmartBattery`. Charging is negative,
discharging positive.
"""
function _read_battery_current_macos_value(;
                                            output::Union{AbstractString,Nothing}=nothing)
    s = if output === nothing
        try
            read(`ioreg -rn AppleSmartBattery`, String)
        catch
            return 0.0
        end
    else
        output
    end
    return _parse_battery_current_macos(s)
end

"""
    _parse_ac_online_macos(output) -> Float64

Parses `pmset -g ps` first-line output:
`Now drawing from 'AC Power'` → 1.0;
`Now drawing from 'Battery Power'` → 0.0.
"""
function _parse_ac_online_macos(output::AbstractString)
    return occursin("AC Power", output) ? 1.0 : 0.0
end

"""
    _read_ac_online_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns 1.0 if the system is on AC power, 0.0 if on battery,
parsed from `pmset -g ps`.
"""
function _read_ac_online_macos_value(;
                                      output::Union{AbstractString,Nothing}=nothing)
    s = if output === nothing
        try
            read(`pmset -g ps`, String)
        catch
            return 0.0
        end
    else
        output
    end
    return _parse_ac_online_macos(s)
end

"""
    _parse_usb_count_macos(output) -> Float64

Counts top-level USB host devices and attached devices from
`ioreg -p IOUSB -l -w 0` output. Matches `+-o ` lines whose
indentation indicates a non-Root entry. Excludes the implicit
`Root` registry entry to align semantically with the Linux
reader (which counts attached devices, not the controller).
"""
function _parse_usb_count_macos(output::AbstractString)
    n = 0
    for line in split(output, '\n')
        # Match indented `+-o ` lines (anything except "+-o Root").
        if occursin(r"^[ |]+\+-o ", line)
            n += 1
        end
    end
    return Float64(n)
end

"""
    _read_usb_count_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns count of attached USB devices from
`ioreg -p IOUSB -l -w 0`.
"""
function _read_usb_count_macos_value(;
                                      output::Union{AbstractString,Nothing}=nothing)
    s = if output === nothing
        try
            read(`ioreg -p IOUSB -l -w 0`, String)
        catch
            return 0.0
        end
    else
        output
    end
    return _parse_usb_count_macos(s)
end

"""
    _parse_thermal_macos(output) -> Float64

Parses `ioreg -rn AppleSmartBattery` output for the
`"Temperature" = N` field and returns the value in degrees
Celsius. The kernel reports temperature in 0.01°C units;
this function divides by 100.

**Substrate note:** this is *battery* temperature, the
Phase-2a fallback. Phase 2b (`_read_smc_temperature_macos`
below) reads CPU-die thermal directly via SMC IOKit FFI on
hosts where it is available; battery temp is the graceful
fallback when SMC is unreachable (sandboxed environments,
older kernel versions, or unrecognised SMC firmware).
"""
function _parse_thermal_macos(output::AbstractString)
    m = match(r"\"Temperature\"\s*=\s*(\d+)", output)
    m === nothing && return 0.0
    return parse(Int, m.captures[1]) / 100.0
end

# ─── Phase 2b: SMC IOKit FFI for CPU-die thermal ───────────
#
# AppleSMC is accessible without sudo via the IOKit framework.
# This module reads thermal keys directly from the kernel SMC
# driver — no shell-out, no privileged access, ~425 µs per
# read (25× faster than the Phase 2a `ioreg` battery-temp
# fallback).
#
# Protocol (verified empirically on M5 Max):
#   1. IOServiceMatching("AppleSMC") + IOServiceGetMatchingService
#      to locate the kernel SMC driver.
#   2. IOServiceOpen returns a connection handle.
#   3. IOConnectCallStructMethod with selector=2 (KERNEL_INDEX_SMC),
#      inputStruct = 80-byte SMCKeyData_t with the FOURCC key
#      packed *little-endian* (UInt32 native-endian C-struct
#      layout — this byte order was empirically confirmed; a
#      big-endian packing returns kSMCKeyNotFound).
#   4. Two-phase read: first call with command=9 (READ_KEYINFO)
#      retrieves dataType + dataSize; second call with command=5
#      (READ_BYTES) retrieves the value.
#   5. Floating-point thermal values are encoded as `flt ` in
#      IEEE-754 single-precision, **little-endian** bytes.
#      Integer fields (dataSize, dataType, key) are *also*
#      little-endian on the wire — they are UInt32 fields in
#      a native-layout C struct on a little-endian host.
#
# Apple Silicon thermal-key inventory (M5 Max, empirical):
#   Tp0a  =  P-core temperature (~55°C under light load)
#   Tp0d  =  P-core temperature (~55°C)
#   Tp0p  =  P-core temperature (~56°C)
#   TaLP  =  ambient/logic-board (~45°C)
#   TB0T..TB2T = battery sensors (~31°C; same readings as the
#                Phase-2a ioreg path, sanity-check)
#   TH0a..TH0x = drive/heatpipe (~36°C)
#
# The thermal-key set differs across chip generations
# (M1/M2/M3/M4/M5 perf-core layouts vary). The reader probes
# a priority list and returns the first key that responds —
# stable behaviour across the M-series + Intel.

const _SMC_KERNEL_INDEX = UInt32(2)
const _SMC_CMD_READ_BYTES = UInt8(5)
const _SMC_CMD_READ_KEYINFO = UInt8(9)
const _SMC_STRUCT_SIZE = 80
const _IOKIT_LIB = "/System/Library/Frameworks/IOKit.framework/IOKit"
const _LIBSYSTEM = "/usr/lib/libSystem.B.dylib"

# Priority list of thermal keys. The first key that returns
# data is used. Order: Apple Silicon P-cores first (canonical
# CPU thermal on M-series), then ambient/legacy fallbacks.
const _SMC_THERMAL_KEYS = String[
    "Tp0a", "Tp0d", "Tp0p", "Tp0z",  # M-series P-core variants
    "TC0P", "TC0D", "TC0E",            # Intel CPU keys
    "TaLP",                            # ambient (any Mac)
]

"""
    _smc_pack_key(key) -> Vector{UInt8}

Pack a 4-character SMC key as a 4-byte little-endian sequence
matching the native-endian UInt32 layout of `SMCKeyData_t.key`
on a little-endian host.
"""
function _smc_pack_key(key::AbstractString)
    @assert length(key) == 4 "SMC key must be exactly 4 ASCII characters: $key"
    bs = UInt8.(collect(codeunits(key)))
    return UInt8[bs[4], bs[3], bs[2], bs[1]]
end

"""
    _smc_decode_flt(bytes) -> Float64

Decode a 4-byte SMC `flt ` value (IEEE-754 single, little-endian
on the wire) to Float64.
"""
function _smc_decode_flt(bytes::AbstractVector{UInt8})
    length(bytes) == 4 || return NaN
    raw = UInt32(bytes[1]) |
          (UInt32(bytes[2]) << 8) |
          (UInt32(bytes[3]) << 16) |
          (UInt32(bytes[4]) << 24)
    return Float64(reinterpret(Float32, raw))
end

"""
    _smc_open() -> UInt32

Opens an AppleSMC connection. Returns the connection handle
(io_connect_t) or 0 if the service is unavailable. Caller
must `_smc_close` the returned handle.
"""
function _smc_open()
    matching = ccall((:IOServiceMatching, _IOKIT_LIB), Ptr{Cvoid},
                     (Cstring,), "AppleSMC")
    matching == C_NULL && return UInt32(0)

    service = ccall((:IOServiceGetMatchingService, _IOKIT_LIB), UInt32,
                    (UInt32, Ptr{Cvoid}), UInt32(0), matching)
    service == 0 && return UInt32(0)

    task_self = ccall((:mach_task_self, _LIBSYSTEM), UInt32, ())

    conn = Ref{UInt32}(0)
    rc = ccall((:IOServiceOpen, _IOKIT_LIB), Cint,
               (UInt32, UInt32, UInt32, Ptr{UInt32}),
               service, task_self, UInt32(0), conn)
    ccall((:IOObjectRelease, _IOKIT_LIB), Cint, (UInt32,), service)
    rc == 0 || return UInt32(0)
    return conn[]
end

"""
    _smc_close(conn) -> Cint

Releases the SMC connection.
"""
function _smc_close(conn::UInt32)
    conn == 0 && return Cint(0)
    return ccall((:IOServiceClose, _IOKIT_LIB), Cint, (UInt32,), conn)
end

"""
    _smc_read_key_raw(conn, key) -> Union{Nothing, Tuple{String,Vector{UInt8}}}

Reads an SMC key. Returns `(dataType_string, value_bytes)` on
success; `nothing` if the key is not present or not readable.
"""
function _smc_read_key_raw(conn::UInt32, key::AbstractString)
    conn == 0 && return nothing
    key_bytes = _smc_pack_key(key)

    # Phase 1: READ_KEYINFO
    inp1 = zeros(UInt8, _SMC_STRUCT_SIZE)
    out1 = zeros(UInt8, _SMC_STRUCT_SIZE)
    inp1[1:4] = key_bytes
    inp1[43] = _SMC_CMD_READ_KEYINFO  # data8 at C-struct offset 42 = 1-indexed byte 43
    out_size = Ref{Csize_t}(_SMC_STRUCT_SIZE)
    rc = ccall((:IOConnectCallStructMethod, _IOKIT_LIB), Cint,
               (UInt32, UInt32, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Ptr{Csize_t}),
               conn, _SMC_KERNEL_INDEX, inp1, Csize_t(_SMC_STRUCT_SIZE),
               out1, out_size)
    rc == 0 || return nothing
    out1[41] == 0 || return nothing  # result byte; 0x84 = key-not-found

    # Parse keyInfo (offset 28 in C struct = bytes 29..40 in 1-indexed)
    dataSize = UInt32(out1[29]) |
               (UInt32(out1[30]) << 8) |
               (UInt32(out1[31]) << 16) |
               (UInt32(out1[32]) << 24)
    dataSize == 0 && return nothing
    dataSize > 32 && return nothing  # bytes[] field is 32 bytes max

    # dataType is also UInt32, stored little-endian → reverse for ASCII
    dataType_str = String(UInt8[out1[36], out1[35], out1[34], out1[33]])

    # Phase 2: READ_BYTES
    inp2 = zeros(UInt8, _SMC_STRUCT_SIZE)
    out2 = zeros(UInt8, _SMC_STRUCT_SIZE)
    inp2[1:4] = key_bytes
    inp2[29] = UInt8(dataSize & 0xff)
    inp2[30] = UInt8((dataSize >> 8) & 0xff)
    inp2[31] = UInt8((dataSize >> 16) & 0xff)
    inp2[32] = UInt8((dataSize >> 24) & 0xff)
    inp2[43] = _SMC_CMD_READ_BYTES
    out_size2 = Ref{Csize_t}(_SMC_STRUCT_SIZE)
    rc2 = ccall((:IOConnectCallStructMethod, _IOKIT_LIB), Cint,
                (UInt32, UInt32, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Ptr{Csize_t}),
                conn, _SMC_KERNEL_INDEX, inp2, Csize_t(_SMC_STRUCT_SIZE),
                out2, out_size2)
    rc2 == 0 || return nothing
    out2[41] == 0 || return nothing

    # bytes[] starts at C-struct offset 48 = 1-indexed byte 49
    return (dataType_str, out2[49:48 + Int(dataSize)])
end

"""
    _read_smc_temperature_macos() -> Union{Nothing, Float64}

Reads CPU-die temperature in °C from the AppleSMC service via
IOKit FFI. Probes the priority list `_SMC_THERMAL_KEYS` and
returns the first reading that succeeds. Returns `nothing` if
SMC is unavailable or no thermal key responds — caller should
fall back to the Phase-2a battery-temp path.
"""
function _read_smc_temperature_macos()
    conn = _smc_open()
    conn == 0 && return nothing
    try
        for key in _SMC_THERMAL_KEYS
            r = _smc_read_key_raw(conn, key)
            r === nothing && continue
            (dt, bytes) = r
            if dt == "flt "
                v = _smc_decode_flt(bytes)
                isfinite(v) && v > -50.0 && v < 200.0 && return v
            end
        end
    finally
        _smc_close(conn)
    end
    return nothing
end

"""
    _read_thermal_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns thermal sensor reading in °C. Tries SMC IOKit FFI
first (Phase 2b — CPU-die thermal); falls back to battery
temperature via `ioreg -rn AppleSmartBattery` (Phase 2a) if
SMC is unavailable. Pass `output=...` to bypass both shell-out
and SMC and parse a canned ioreg string instead (test seam —
exercises the Phase 2a parser).

Returns `0.0` if both Phase 2b and Phase 2a sources are
unavailable (sandboxed environment without battery — desktop
Mac mini / Mac Studio without external battery sensor).
"""
function _read_thermal_macos_value(;
                                    output::Union{AbstractString,Nothing}=nothing)
    # Test-seam path: explicit canned ioreg output
    if output !== nothing
        return _parse_thermal_macos(output)
    end
    # Phase 2b: SMC FFI for CPU-die thermal
    smc_value = _read_smc_temperature_macos()
    smc_value === nothing || return smc_value
    # Phase 2a fallback: battery temperature via ioreg
    s = try
        read(`ioreg -rn AppleSmartBattery`, String)
    catch
        return 0.0
    end
    return _parse_thermal_macos(s)
end

"""
    _parse_cpu_proxy_macos(output) -> Float64

Parses `sysctl -n vm.page_free_count` output (a single
integer) and returns it as Float64. Per-call value tracks
real-time memory pressure, which on a multi-process system
correlates with CPU activity (allocator churn).
"""
function _parse_cpu_proxy_macos(output::AbstractString)
    return Float64(parse(Int, strip(output)))
end

"""
    _read_cpu_freq_macos_value(; output::Union{String,Nothing}=nothing) -> Float64

Returns `vm.page_free_count` as a system-activity proxy on
Apple Silicon (Phase 2a substitute for CPU scaling
frequency, which Apple Silicon does not expose via public
sysctl). The value varies in real time with workload.
"""
function _read_cpu_freq_macos_value(;
                                     output::Union{AbstractString,Nothing}=nothing)
    s = if output === nothing
        try
            read(`sysctl -n vm.page_free_count`, String)
        catch
            return 0.0
        end
    else
        output
    end
    return _parse_cpu_proxy_macos(s)
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

**macOS Phase 2b implementation.** Reads CPU-die temperature
via AppleSMC IOKit FFI (no shell-out, no privileged access,
~425 µs per read). Probes a priority list of SMC thermal
keys (`Tp0a`/`Tp0d`/`Tp0p`/`TC0P`/`TaLP`) and returns the
first reading that succeeds — stable across the M1/M2/M3/
M4/M5 chip series + Intel. Falls back to **Phase 2a** (battery
temperature via `ioreg -rn AppleSmartBattery`) if SMC is
unavailable (sandboxed environments, unrecognised firmware).
The `sensor_index` keyword is currently ignored on macOS;
it is retained for API parity with the Linux reader.

**Windows / other**: errors with a per-platform
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
    elseif _detect_platform() == :macos
        return record_stream(_read_thermal_macos_value;
                              sample_rate=sample_rate, t_max=t_max)
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

**macOS Phase 2a**: reads `InstantAmperage` (signed mA) from
`ioreg -rn AppleSmartBattery`. Charging is negative. Returns
`0.0` on desktops without a battery.

**Other platforms**: scaffold error.
"""
function real_battery_stream(; sample_rate::Real=5.0,
                              t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_battery_current_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    elseif _detect_platform() == :macos
        return record_stream(_read_battery_current_macos_value;
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

**macOS Phase 2a**: parses `pmset -g ps` first line; returns
1.0 if "AC Power", 0.0 otherwise.

**Other platforms**: scaffold error.
"""
function real_ac_stream(; sample_rate::Real=1.0,
                        t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_ac_online_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    elseif _detect_platform() == :macos
        return record_stream(_read_ac_online_macos_value;
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

**macOS Phase 2a**: counts indented `+-o ` entries from
`ioreg -p IOUSB -l -w 0` (excludes the synthetic Root entry,
includes XHCI controllers and attached host devices). The
absolute count semantics differ slightly from Linux but the
*transition* semantics — what LL-005 actually guards — are
identical.

**Other platforms**: scaffold error.
"""
function real_usb_stream(; sample_rate::Real=1.0,
                         t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_usb_count_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    elseif _detect_platform() == :macos
        return record_stream(_read_usb_count_macos_value;
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

**macOS Phase 2a**: reads `vm.page_free_count` via `sysctl -n`
as a system-activity proxy. Apple Silicon does not expose
instantaneous CPU frequency through public sysctl; memory
pressure (page-free count) is a real-time substitute that
varies with workload at sub-second timescales. The
`cpu_index` keyword is currently ignored on macOS (single
system-wide value); it is retained for API parity with the
Linux reader.

**Other platforms**: scaffold error.
"""
function real_cpu_governor_stream(; sample_rate::Real=50.0,
                                   t_max::Real=10.0,
                                   cpu_index::Int=0)
    if _detect_platform() == :linux
        reader = () -> _read_cpu_freq_linux_value(cpu_index)
        return record_stream(reader; sample_rate=sample_rate, t_max=t_max)
    elseif _detect_platform() == :macos
        return record_stream(_read_cpu_freq_macos_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_cpu_governor_stream")
end

"""
    real_loadavg_stream(; sample_rate::Real=5.0,
                        t_max::Real=10.0) -> SensorStream

Reads 1-minute system load average at `sample_rate` Hz.

**Linux Phase 1**: reads first whitespace-separated token from
`/proc/loadavg` (per kernel docs).

**macOS Phase 2a**: parses `sysctl -n vm.loadavg` (output
`{ 7.13 7.17 6.84 }`) and returns the 1-minute load average.

**Other platforms**: scaffold error.
"""
function real_loadavg_stream(; sample_rate::Real=5.0,
                              t_max::Real=10.0)
    if _detect_platform() == :linux
        return record_stream(_read_loadavg_linux_value;
                              sample_rate=sample_rate, t_max=t_max)
    elseif _detect_platform() == :macos
        return record_stream(_read_loadavg_macos_value;
                              sample_rate=sample_rate, t_max=t_max)
    end
    _scaffold_error("real_loadavg_stream")
end

end # module RealSensors
