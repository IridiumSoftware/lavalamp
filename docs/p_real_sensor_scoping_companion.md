# P-RS — Real-Sensor Deployment Scoping Pass

Version: 0.0.38 (P-RS scoping pass; LL-024 added :argued; Linux-first roadmap, 2026-05-04)

Permanent record of the real-sensor deployment scoping pass —
parallel-safe Level-2 prototype prep work landed while waiting
for upstream (`closure_forces_structure` paper update + engine
updates). The current Julia prototype (Level 1) uses synthetic
sensor streams (`gaussian_noise_stream`, `constant_stream`,
`binary_step_stream`); Level 2 reads actual hardware sensors
via platform-specific FFI. This pass scopes the per-platform
implementation strategy without committing to specific FFI code
yet.

**Net result.** New entry LL-024 (real-sensor-deployment-
strategy, Operational tier, manual, `:argued`) + scaffold
module `src/julia/src/RealSensors.jl` with API stubs that
error meaningfully pointing to this companion. Linux is the
target first platform (sysfs/procfs reads are file I/O, no
FFI); macOS (IOKit/SMC) and Windows (WMI) follow.

LL-022 (downward trust-stack) + LL-023 (upward trust-stack) +
LL-024 (real-sensor strategy) form a three-layer commitment:
LL-024 articulates *which sensors get read at what rate*;
LL-022 articulates *what OS surfaces those sensors are
exposed through* and *what authenticity guarantees the OS
provides*; LL-023 articulates *how the verifier exposes the
resulting identity to consumers*. The triple closes the
deployment-stack scoping question alongside the existing
trust-stack pair.

---

## §1 — Computational basis

### §1.1 — Inputs

- `LAVALAMP_SPEC.md` v0.0.37 — entries that the real-sensor
  work touches: LL-004 (continuous sensor coupling), LL-005
  (sensor Nyquist condition), LL-016 (sensor authenticity
  requirement), LL-022 (OS-trust-stack-dependency).
- `src/julia/src/Sensors.jl` — current synthetic-stream
  module; the API surface (`SensorStream`, `evaluate`,
  `CouplingParams`) must remain unchanged so existing
  pipelines continue to work.
- `docs/architecture_design_companion.md` §2.4 — design-pass
  framing of the sensor coupling layer.
- `docs/os_identity_security_scoping_companion.md` §2.2.2 —
  LL-022 OS sensor APIs at LL-005-compliant bandwidths
  (existing reference).

### §1.2 — No FFI code at scaffold tier

This pass produces:
- The scoping companion (this file).
- A new spec entry LL-024.
- A scaffold module `RealSensors.jl` with API stubs that
  error pointing to this companion.
- Brief test additions confirming the scaffold imports and
  the stubs error per design.

It does **not** produce platform-specific FFI implementations.
Those land in subsequent commits, one platform at a time, per
the §2.5 roadmap. Same shape as the 0.0.36 Lean scaffold
(infrastructure-prep, no proofs); the scaffold tier here is
infrastructure-prep, no FFI.

### §1.3 — Why scoping now

The user's "Level 2 prototype" question prompted an honest
articulation of the path from current synthetic-stream work
(Level 1, done) to hardware-bound prototype (Level 2, in
progress at scoping tier as of this commit). The scoping pass
de-risks the eventual implementation by pinning the
architectural choices in advance, mirroring the 0.0.34
P-PharOS pass's pre-implementation scoping discipline.

---

## §2 — Results

### §2.1 — Per-platform sensor surface

Each major OS exposes hardware sensors through different APIs.
The real-sensor implementation provides a uniform `SensorStream`
output backed by per-platform readers:

#### Linux (target first platform)

- **Thermal**: `/sys/class/hwmon/hwmon*/temp*_input` (millidegrees C)
  + `/sys/class/thermal/thermal_zone*/temp` (millidegrees C). Pure
  file reads at any sample rate the kernel allows (~kHz
  achievable; usually limited by the sensor hardware to ~10-100
  Hz updates).
- **Battery**: `/sys/class/power_supply/BAT*/{capacity,
  current_now, voltage_now}`. Polling rate ~1-10 Hz; the kernel
  caches values, so high-frequency polling returns stale data
  until the underlying ACPI poll happens.
- **AC adapter**: `/sys/class/power_supply/AC*/online` (binary
  0/1). Discrete-state per LL-005's classification; transitions
  are the entropy-relevant events.
- **USB peripherals**: `/sys/bus/usb/devices/*/{vendor,product,
  bMaxPower}`. Discrete-state; transitions on
  attach/detach.
- **CPU thermal/governor**: `/sys/devices/system/cpu/cpu*/cpufreq/
  scaling_cur_freq` + `cpufreq/scaling_governor`. Sample at
  ~10-100 Hz.
- **Scheduler timing / load average**: `/proc/loadavg` +
  `/proc/stat`. Sample at ~1-10 Hz.

**Implementation cost**: pure file I/O via Julia's stdlib;
no FFI required. Estimated dev time: 3-5 days for the full
sensor set with tests.

#### macOS

- **Thermal / SMC**: requires FFI to `IOKit.framework` or to
  the `libSMC` user-space library. Sensor IDs are
  Mac-model-specific; a discovery step at startup is needed.
- **Battery / AC**: `IOPMPowerSource` via IOKit. Slower polling
  than Linux (~5-10 Hz typical).
- **USB**: `IOUSBLib` via IOKit. Discrete-state events similar
  to Linux.
- **Scheduler**: `sysctl kern.cp_times` via FFI. Sample at
  ~10-100 Hz.

**Implementation cost**: FFI to IOKit + per-Mac-model sensor
discovery is ~2 weeks of dev work. Apple Silicon vs Intel
differences add complexity; thermal sensor IDs differ between
M1/M2/M3 series. Defer until Linux is validated.

#### Windows

- **Thermal**: WMI (`Win32_TemperatureProbe`,
  `MSAcpi_ThermalZoneTemperature`) via `winrt` interop. Slow
  (~1 Hz typical).
- **Battery**: WMI (`Win32_Battery`).
- **USB**: WMI (`Win32_USBControllerDevice`) or
  `SetupAPI`.
- **Scheduler**: Performance Counters via PDH (`Pdh.dll`).

**Implementation cost**: ~2-3 weeks (WMI is slow + tedious;
PDH for fast counters; multiple legacy APIs to thread).
Defer until Linux + macOS land.

### §2.2 — Sensor categories per LL-004

LL-004 enumerates the design-pass sensor categories: *thermal*,
*battery*, *AC adapter*, *USB peripheral*, *CPU thermal*,
*scheduler timing*. Each category gets a corresponding API:

```julia
real_thermal_stream(; sample_rate, t_max, sensor_index=1) -> SensorStream
real_battery_stream(; sample_rate, t_max) -> SensorStream
real_ac_stream(; sample_rate, t_max) -> SensorStream
real_usb_stream(; sample_rate, t_max) -> SensorStream
real_cpu_governor_stream(; sample_rate, t_max, cpu_index=0) -> SensorStream
real_loadavg_stream(; sample_rate, t_max) -> SensorStream
```

Each returns a `SensorStream` (the existing type from
`Sensors.jl`) populated by reading the platform-specific
sensor at the requested sample rate over the requested
duration. The output type is identical to the synthetic
streams', so existing `CouplingParams` / `lorenz96_coupled` /
`verify` pipelines work without modification.

### §2.3 — Sample-rate constraints per LL-005

LL-005 (Nyquist) requires `f_SDE > 2·BW ∧ f_sensor > BW`. At
the prototype's `f_SDE = 20 Hz` (Δt = 0.05), the assumed
adversary bandwidth `BW` must be < 10 Hz for parameter
compliance, and `f_sensor > BW` for sensor-side Nyquist.

Real-sensor sample rates per platform:

| Sensor | Linux max | macOS max | Windows max | LL-005 required |
|--------|-----------|-----------|-------------|-----------------|
| Thermal | ~100 Hz | ~10 Hz | ~1 Hz | > BW (typically ≥ 5 Hz adequate) |
| Battery | ~10 Hz | ~5 Hz | ~1 Hz | > BW (discrete-state; ≥ 0.1 Hz adequate) |
| AC | event-driven | event-driven | event-driven | > BW (discrete; trivially satisfied) |
| USB | event-driven | event-driven | event-driven | > BW (discrete; trivially satisfied) |
| CPU governor | ~100 Hz | ~50 Hz | ~10 Hz | > BW (≥ 5 Hz adequate) |
| Load average | ~10 Hz | ~10 Hz | ~10 Hz | > BW (≥ 1 Hz adequate) |

**Operational design rule:** at deployment time, call
`nyquist_compliant(f_SDE, f_sensor, bandwidth)` (the LL-005
predicate landed in 0.0.32) on each `(f_sensor, BW)` pair.
If any check fails, reject the deployment configuration with
an honest error rather than silently proceeding with a non-
compliant sensor.

### §2.4 — Authenticity strategies per LL-016 in real-hardware context

LL-016 articulates four strategies; each maps onto real-hardware
deployment differently:

1. **Hardware attestation (TPM-signed reads)** — strongest;
   requires LL-022 §2.2.1 hardware root of trust. **Deferred to
   P7 hardening**: TPM integration is non-trivial, platform-
   specific, and outside the prototype-tier scope. Not
   default.
2. **Multi-sensor cross-validation (correlated readings)** —
   thermal + battery discharge rate; AC online + measured
   current; USB attach + power draw transients. **Default for
   the prototype tier.** Implementable with the §2.1 sensor
   set; cross-validation logic lives in `Audit.jl` or a new
   `RealSensors/Authenticity.jl` submodule.
3. **Anomaly-based flagging (joint-envelope filtering)** —
   sensor reads outside plausible joint envelopes get excluded
   from `U(s)` participation. Implementable as a filter on
   `SensorStream` values; design lives in
   `RealSensors/Authenticity.jl`.
4. **Accepted residual risk with deployment-context guidance**
   — fallback when the deployment can't support stronger
   strategies (e.g., embedded systems with limited sensor
   diversity). Documented per-deployment.

**Plus LL-022 §2.3.3 strategy 1.5 (eBPF on Linux)** — between
TPM and software cross-validation. eBPF programs attached to
the sensor-read syscalls cross-validate kernel-side reads
against user-space LavaLamp reads. Defeats A2-class adversaries
but not A3. Worth implementing on Linux as a strengthened
default.

**Per-platform default authenticity strategy:**

- Linux: strategy 2 (cross-validation) baseline; strategy 1.5
  (eBPF) for hardened deployments; strategy 1 (TPM) at P7.
- macOS: strategy 2 baseline; strategy 1 (Secure Enclave) at
  P7.
- Windows: strategy 2 baseline; strategy 1 (TPM) at P7.

### §2.5 — Linux-first implementation roadmap

**Phase 1 (target: 1 week post-round-3):** Linux baseline.

- Implement `RealSensors/Linux.jl` with the §2.2 API stubs
  doing actual sysfs/procfs reads.
- Sensor classes covered: thermal, battery, AC, USB, CPU
  governor, load average.
- Cross-validation (LL-016 strategy 2) skeleton in
  `RealSensors/Authenticity.jl`.
- Tests: integration against a recorded sensor-trace fixture
  (so CI can run on Linux without depending on the actual
  hardware sensor values).
- Deliverable: end-to-end Linux prototype that runs
  `lorenz96_coupled` against real hardware sensors and
  produces a working envelope + verifies trajectories.

**Phase 2 (target: 2-4 weeks post-Phase 1):** macOS support.

- IOKit FFI for thermal / SMC.
- Per-Mac-model sensor discovery.
- Same cross-validation layer.
- Tests: similar to Linux (recorded traces).

**Phase 3 (target: 4-6 weeks post-Phase 2):** Windows.

- WMI / PDH bindings.
- Same cross-validation layer.
- Tests: recorded traces on a Windows CI runner.

**Phase 4 (P7 hardening, much later):** TPM integration on
all platforms. Out of scope for the Level-2 prototype.

### §2.6 — Test strategy

**Unit tests (per platform):** verify that platform-specific
readers parse sysfs / IOKit / WMI output correctly given known
input. Mock the platform layer with recorded traces.

**Integration tests:** end-to-end pipeline using a small
recorded sensor-trace fixture. Run on at least one CI runner
(Linux first; macOS / Windows when phases 2-3 land).

**Property tests:** sensor readings satisfy LL-005
nyquist_compliant; sensor cross-validation passes for
genuine-device traces; cross-validation flags adversarial
traces (recorded with hairdryer / charge controller / etc.
during a future test-fixture-collection session).

**Determinism:** real-sensor readings are non-deterministic
by construction (hardware varies). The CI determinism check
runs against recorded traces (deterministic), not live
hardware.

### §2.7 — Connection to LL-022 / LL-023

LL-022 (OS-trust-stack-dependency) §2.2.2 already lists "OS
sensor APIs at LL-005-compliant bandwidths" as a required OS
mechanism. LL-024 instantiates that requirement
operationally: which APIs, what sample rates, what fallback
when a sensor is unavailable.

LL-023 (consumer-API-surface) is unaffected — the consumer
sees the same `register` / `verify` API regardless of
whether the underlying sensor streams are synthetic or real.
The LL-024 work is entirely below the LL-023 surface.

The triple LL-022 + LL-023 + LL-024 forms a three-layer
deployment-stack scoping commitment:

- LL-022: *what* OS surfaces are required (TPM, sensor APIs,
  TRNG, isolation).
- LL-024: *which* sensors get read at *what* rates with
  *what* authenticity strategy, per platform.
- LL-023: *how* the verifier exposes the resulting identity
  to OS-deployment consumers.

The triple closes the deployment-stack scoping question.

---

## §3 — Verification

### §3.1 — LL-024 status: :argued

**Verification status:** `:argued`.

**Evidence type:** `manual`.

The §2 design synthesis is the argument: §2.1 enumerates the
per-platform sensor surface; §2.2 maps to LL-004 categories;
§2.3 verifies LL-005 compliance; §2.4 articulates the
authenticity-strategy choice per platform; §2.5 lays out the
implementation roadmap; §2.6 specifies the test strategy.

The argument is *not* machine-checked. Promotion paths:

- **`:tested`** would require Phase 1 (Linux baseline)
  implementation + tests. Estimated 1 week post-round-3.
- **`:benchmarked`** would require empirical performance
  characterisation on real hardware (real-sensor SNR vs
  synthetic-stream SNR; detection bound preserved against
  parameter-perturbation adversaries; sensor cross-validation
  catches V-006 manipulation attempts). Estimated 2-3 weeks
  post-Phase 1.
- **`:proved`** would require Lean theorems about the
  cross-validation logic correctness. P5/P6 work; deferred.

### §3.2 — Why this is honest

The scoping companion does not commit to specific FFI code.
It commits to a *strategy* (Linux first; sysfs/procfs;
cross-validation default; per-phase rollout). The actual
implementation is a future commit; the strategy can evolve
based on real-hardware experience without revising LL-024's
core claim.

This matches the 0.0.34 P-PharOS pattern: design pass
articulates the architecture; implementation commits land
later; the spec entry's `:argued` evidence is robust to
implementation churn.

---

## §4 — Spec impact

### §4.1 — New entry

**LL-024 — real-sensor-deployment-strategy**

- *Logic tier*: Operational (parallel to LL-007 chaos-guard,
  LL-011 registration ceremony, LL-012 cold-start window,
  LL-013 cross-config, LL-014 threshold calibration —
  all Operational entries describing implementation
  behaviour).
- *Evidence type*: `manual`.
- *Status*: `:argued`.
- *Source*: this companion §2.

### §4.2 — Cross-references

- **LL-004** — gain a "real-sensor implementation roadmap"
  sub-bullet pointing to LL-024.
- **LL-005** — already references nyquist_compliant; LL-024
  operationalises the per-sensor compliance check at
  deployment-config time.
- **LL-016** — gains a "real-sensor-context default
  strategy" sub-bullet noting LL-024's choice of strategy 2
  + 1.5 (Linux eBPF) at the prototype tier; strategy 1
  (TPM) deferred to P7.
- **LL-022** — gain a "real-sensor instantiation" sub-bullet
  noting LL-024 operationalises §2.2.2 (OS sensor APIs).

### §4.3 — Spec-status counts (post-pass, version 0.0.38)

- Total: 24 (was 23; +LL-024)
- `:proved`: 0
- `:tested`: 3 (unchanged)
- `:verified`: 0
- `:benchmarked`: 4 (unchanged)
- `:argued`: 16 (was 15; +LL-024)
- `:open`: 1 (unchanged)

### §4.4 — Scaffold tier

`src/julia/src/RealSensors.jl` — new module landed at this
commit with API stubs that error meaningfully pointing to
this companion. No FFI implementations at scaffold tier;
imports clean; existing test suite continues to pass at
184/184 plus a small new testset confirming the scaffold
imports + stubs error.

The scaffold mirrors the 0.0.36 Lean scaffold pattern:
infrastructure-prep, not evidence. LL-024's `:argued`
evidence is the design synthesis here, not the scaffold
module.

---

## §5 — Lessons captured

### §5.1 — The deployment-stack triple closes scoping below LL-023

LL-022 (OS dependencies) + LL-023 (consumer-API surface)
were the trust-stack scoping pair landed in 0.0.26 / 0.0.34.
LL-024 (real-sensor strategy) is the third member of the
deployment-stack triple — articulating *which sensors at
what rates*, the operational instantiation of LL-022's
sensor-API requirement.

The pattern: spec-level scoping passes land in groups when
the architectural surface has multiple distinct ends. LL-022
+ LL-023 closed the trust-stack ends (downward + upward);
LL-024 closes the deployment-stack instantiation. Future
scoping passes may surface additional triples or pairs as
the architecture evolves.

### §5.2 — Synthetic streams + scaffold module is the right composition

The current Julia prototype uses synthetic streams for
algorithmic development. The real-sensor scaffold module
adds API stubs without implementing FFI yet. Both layers
coexist: synthetic streams remain the testing baseline;
real-sensor stubs error meaningfully pointing to this
companion when called.

The composition pattern: at the scaffold tier, the API
surface exists (so consumers can see it's planned) but
calling the stubs errors. This matches the Lean scaffold
discipline (theorem statements in comment blocks; no
`theorem` declarations until proofs land).

### §5.3 — Linux-first roadmap minimises infrastructure cost

Linux's sysfs/procfs interface lets the entire Phase 1
implementation be done with Julia stdlib file I/O — no FFI,
no platform-specific bindings. Estimated 3-5 days of dev
work for the full sensor set.

macOS / Windows require FFI which is multi-week work per
platform. Deferring those phases keeps the prototype's
implementation cost bounded while still proving out the
architecture on one platform.

The lesson generalises: when a multi-platform implementation
has dramatic cost asymmetry across platforms, target the
cheapest platform first; use it to validate the architecture
before paying the higher per-platform costs.

### §5.4 — Authenticity strategy choice is operational, not architectural

LL-016 listed four authenticity strategies as the
*architectural* design space; LL-024 picks strategy 2 + 1.5
as the *operational* default for the prototype tier. The
choice is per-deployment-context; production hardening (P7)
moves to strategy 1 (TPM).

The decision to make this an operational rather than
architectural commitment is honest: the four strategies all
work in principle; which one you deploy depends on the
deployment's threat model + available hardware. LL-024
documents the prototype-tier default; deployments are free
to override per their requirements.
