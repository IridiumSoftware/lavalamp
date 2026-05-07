"""
LavaLamp.RuntimeConformance — runtime conformance verification
framework for the LL-028 deployment-stack-triple runtime
enforcement gap.

The deployment-stack triple (LL-022 + LL-023 + LL-024) specifies
*what* must hold; LL-028 specifies *how to verify it holds at
runtime*. A malicious or compromised deployer can satisfy the
LL-023 API contract while violating LL-022 invariants
internally — the type/interface vs semantic conformance gap
(V-019). LL-028 closes this gap with four runtime-verification
requirements:

    1. Attestation continuity (TPM-attested boot + measured
       runtime state).
    2. Sensor cross-validation with adversarial probes.
    3. Verifier-side LL-023 API conformance probing.
    4. Continuous TRNG attestation.

This module provides the Julia-side framework: a `ConformanceResult`
record, a four-check public API, and a composite
`verify_runtime_conformance` that aggregates results across all
four. Of the four checks, **one is fully implementable in pure
Julia** (`probe_sensor_freshness` — covers requirement 2 by
querying SensorStream values at multiple times and asserting
they vary in the expected pattern). **Three are platform-
flavored stubs** returning `DEFERRED` with documented hooks:
attestation_continuity (TPM API), api_conformance (statistical-
fingerprint queries against the deployer's API surface),
trng_health (RDRAND health-check return code). Per-platform
implementations land per the P-RS Level 2 roadmap.

The framework is composable: deployments call
`verify_runtime_conformance` with their concrete sensor stack,
TPM availability, etc., and receive a `RuntimeConformanceReport`
they can act on.

API STABILITY: stable shape. The `ConformanceResult` and
`RuntimeConformanceReport` records are the canonical return
types; downstream call-sites inspect the `status` and `detail`
fields to decide next actions.
"""
module RuntimeConformance

using ..Sensors: SensorStream, evaluate
using Statistics: std

export ConformanceStatus, PASS, FAIL, SKIPPED, DEFERRED
export ConformanceResult, RuntimeConformanceReport
export probe_sensor_freshness
export probe_attestation_continuity
export probe_api_conformance
export probe_trng_health
export verify_runtime_conformance

"""
    ConformanceStatus

Outcome of a runtime conformance check.

- `PASS` — the check actually ran and the deployment satisfies
  the requirement.
- `FAIL` — the check ran and the deployment *does not* satisfy
  the requirement; the verifier should refuse to attest.
- `SKIPPED` — the check is not applicable to this deployment
  (e.g. attestation continuity on a TPM-less device that
  explicitly opts into the LL-028 :argued tier).
- `DEFERRED` — the check is platform-specific and the
  per-platform implementation is not yet landed (LL-024
  scaffold-tier mirror; calling such a probe yields a
  diagnostic message describing the deferred work).
"""
@enum ConformanceStatus PASS FAIL SKIPPED DEFERRED

"""
    ConformanceResult(check_name, status, detail)

Single conformance-check outcome. `check_name` identifies which
of the four LL-028 requirements the result belongs to; `status`
is the `ConformanceStatus`; `detail` is a human-readable
diagnostic string.
"""
struct ConformanceResult
    check_name::String
    status::ConformanceStatus
    detail::String
end

"""
    RuntimeConformanceReport(results, overall)

Aggregate result of the four LL-028 conformance checks.

`overall` is `PASS` iff every result in `results` is `PASS` or
`SKIPPED`. Any `FAIL` produces overall `FAIL`. Any `DEFERRED`
in the absence of `FAIL` produces overall `DEFERRED` — the
verifier cannot attest the deployment is conformant when one
or more checks are pending platform-specific implementation.
"""
struct RuntimeConformanceReport
    results::Vector{ConformanceResult}
    overall::ConformanceStatus
end

"""
    probe_sensor_freshness(streams, expected_dynamic;
                            t_probe_times,
                            freshness_floor_relative=0.001,
                            freshness_floor_absolute=1e-9)
        -> ConformanceResult

LL-028 conformance check #2 (sensor cross-validation with
adversarial probes), partially implemented for the SensorStream
abstraction. Detects cached/scripted sensor responses by
probing each stream at multiple times and asserting that the
observed variability matches the deployment's expected
dynamic/constant profile.

For each stream `i`:

- If `expected_dynamic[i]` is `true`, the stream is supposed
  to vary over time. The check evaluates the stream at each
  time in `t_probe_times`, computes the standard deviation of
  the resulting values, and asserts:

      std(values) > freshness_floor_relative * |mean(values)|
      OR
      std(values) > freshness_floor_absolute

  Whichever floor is exceeded counts. The relative floor
  catches caching adversaries when the mean is well-defined;
  the absolute floor catches caching when the mean is near
  zero (so the relative floor would be vanishingly small).

- If `expected_dynamic[i]` is `false`, the stream is supposed
  to be a designed constant (e.g. a calibration baseline). The
  check evaluates at each time and asserts std == 0 exactly.
  A non-zero std on a designed-constant stream indicates the
  deployer has substituted a different (possibly adversarial)
  source for the calibration baseline — `FAIL`.

Returns `PASS` iff every stream satisfies its profile;
otherwise `FAIL` with detail listing which streams failed.

This check is **load-bearing for V-019 defense** (TRNG-replacement,
sensor-fusion forgery, cached-randomness reuse). It runs in
pure Julia against the SensorStream interface and works for
both synthetic streams (the prototype) and real-hardware
streams (when LL-024 P-RS Level 2 implementations slot in —
the same SensorStream interface).
"""
function probe_sensor_freshness(streams::AbstractVector{SensorStream},
                                 expected_dynamic::AbstractVector{Bool};
                                 t_probe_times::AbstractVector{<:Real}=
                                     [0.0, 1.0, 2.0, 5.0, 10.0],
                                 freshness_floor_relative::Real=0.001,
                                 freshness_floor_absolute::Real=1e-9)
    n = length(streams)
    n == length(expected_dynamic) ||
        throw(ArgumentError("streams and expected_dynamic must have equal length"))
    length(t_probe_times) >= 2 ||
        throw(ArgumentError("t_probe_times must have at least 2 entries"))
    freshness_floor_relative >= 0 ||
        throw(ArgumentError("freshness_floor_relative must be non-negative"))
    freshness_floor_absolute >= 0 ||
        throw(ArgumentError("freshness_floor_absolute must be non-negative"))

    if n == 0
        return ConformanceResult("sensor_freshness", PASS,
                                  "no streams to probe; trivially conformant")
    end

    failures = String[]
    for i in 1:n
        s = streams[i]
        is_dynamic = expected_dynamic[i]
        vals = Float64[evaluate(s, Float64(t)) for t in t_probe_times]
        sigma = std(vals)
        mu_abs = abs(sum(vals) / length(vals))
        threshold_rel = freshness_floor_relative * mu_abs
        threshold = max(threshold_rel, freshness_floor_absolute)

        if is_dynamic
            if sigma <= threshold
                push!(failures,
                      "stream[$i] expected_dynamic=true but std=$(sigma) " *
                      "≤ freshness threshold $(threshold) " *
                      "(possible cached/scripted source)")
            end
        else
            if sigma > 0
                push!(failures,
                      "stream[$i] expected_dynamic=false but std=$(sigma) > 0 " *
                      "(possible substituted calibration baseline)")
            end
        end
    end

    if isempty(failures)
        return ConformanceResult("sensor_freshness", PASS,
                                  "all $n streams match their expected " *
                                  "dynamic/constant profile")
    else
        return ConformanceResult("sensor_freshness", FAIL,
                                  join(failures, "; "))
    end
end

"""
    probe_attestation_continuity(; deployment_context=nothing) -> ConformanceResult

LL-028 conformance check #1 (attestation continuity). Verifies
that the running binary matches the boot-time-attested
measurement via TPM-attested boot + measured runtime state.

**Deferred.** Returns `DEFERRED` until per-platform TPM hooks
land. Required mechanism: query the platform's TPM PCR
registers (`/sys/class/tpm/tpm0/pcrs` on Linux,
`SecureEnclave` API on Darwin), compare against
boot-time-attested measurement, return `PASS` iff they match.
LL-022(a) hardware-root-of-trust requirement gates this; on
TPM-less deployments the check returns `SKIPPED` (caller
declared via `deployment_context`).
"""
function probe_attestation_continuity(; deployment_context=nothing)
    return ConformanceResult(
        "attestation_continuity",
        DEFERRED,
        "Per-platform TPM hooks not yet landed. Required: TPM PCR " *
        "register query + comparison against boot-time-attested " *
        "measurement. Linux hook: /sys/class/tpm/tpm0/pcrs. Darwin " *
        "hook: SecureEnclave attestation API. P-RS Level 2 roadmap " *
        "tracks per-platform implementation."
    )
end

"""
    probe_api_conformance(; deployment_context=nothing) -> ConformanceResult

LL-028 conformance check #3 (verifier-side LL-023 API probing).
Issues queries with embedded conformance probes whose results
would diverge if the deployer were stubbing the underlying
mechanisms — statistical fingerprints of TRNG output,
cross-call entropy decorrelation tests, etc.

**Deferred.** Returns `DEFERRED` until the LL-023 consumer-API
surface is concrete enough to encode probe-vs-stub-divergent
queries. The probe set is API-shape-specific and lands per the
LL-023 entry's resolution.
"""
function probe_api_conformance(; deployment_context=nothing)
    return ConformanceResult(
        "api_conformance",
        DEFERRED,
        "Per-API probe set not yet landed. Required: LL-023 " *
        "consumer-API surface concrete enough to encode " *
        "probe-vs-stub-divergent queries (statistical " *
        "fingerprints of TRNG output; cross-call entropy " *
        "decorrelation tests). Sequenced by LL-023 resolution."
    )
end

"""
    probe_trng_health(; deployment_context=nothing) -> ConformanceResult

LL-028 conformance check #4 (continuous TRNG attestation).
Where the platform supports it (Intel CPU `RDRAND`
health-check return code, Linux `getrandom` GRND_INSECURE flag
behavior, etc.), reads the health-check status alongside
random output.

**Deferred.** Returns `DEFERRED` until per-platform TRNG
health hooks land. Required mechanism: invoke platform TRNG
with health-check semantics, compare returned health flags
against deployment's expected baseline, return `PASS` iff
healthy. P-RS Level 2 roadmap tracks per-platform
implementation; on platforms without TRNG health-check
semantics, the check returns `SKIPPED`.
"""
function probe_trng_health(; deployment_context=nothing)
    return ConformanceResult(
        "trng_health",
        DEFERRED,
        "Per-platform TRNG health hooks not yet landed. " *
        "Required: invoke platform TRNG with health-check " *
        "semantics (Intel RDRAND return code; Linux " *
        "getrandom flags), compare against expected baseline. " *
        "P-RS Level 2 roadmap tracks per-platform implementation."
    )
end

"""
    verify_runtime_conformance(streams, expected_dynamic;
                                t_probe_times, deployment_context, kwargs...)
        -> RuntimeConformanceReport

Composite LL-028 runtime conformance check. Runs all four
sub-checks (sensor freshness + three deferred-stub probes)
and aggregates into a single report.

`overall` status:
- `FAIL` if any sub-check is `FAIL`.
- `DEFERRED` if no sub-checks are `FAIL` but at least one is
  `DEFERRED` (the verifier cannot attest until those land).
- `PASS` iff every sub-check is `PASS` or `SKIPPED`.

The `deployment_context` keyword is passed through to the
deferred-stub probes; it has no effect on `probe_sensor_freshness`
which operates purely on the supplied streams.
"""
function verify_runtime_conformance(streams::AbstractVector{SensorStream},
                                     expected_dynamic::AbstractVector{Bool};
                                     t_probe_times::AbstractVector{<:Real}=
                                         [0.0, 1.0, 2.0, 5.0, 10.0],
                                     deployment_context=nothing,
                                     freshness_floor_relative::Real=0.001,
                                     freshness_floor_absolute::Real=1e-9)
    results = ConformanceResult[]
    push!(results,
          probe_attestation_continuity(deployment_context=deployment_context))
    push!(results,
          probe_sensor_freshness(streams, expected_dynamic;
                                  t_probe_times=t_probe_times,
                                  freshness_floor_relative=freshness_floor_relative,
                                  freshness_floor_absolute=freshness_floor_absolute))
    push!(results,
          probe_api_conformance(deployment_context=deployment_context))
    push!(results,
          probe_trng_health(deployment_context=deployment_context))

    overall = if any(r -> r.status == FAIL, results)
        FAIL
    elseif any(r -> r.status == DEFERRED, results)
        DEFERRED
    else
        PASS  # only PASS or SKIPPED remain
    end

    return RuntimeConformanceReport(results, overall)
end

end # module RuntimeConformance
