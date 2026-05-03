# P-R2a Side-Channel Hardening Companion

Version: 0.0.14 (P-R2a — LL-019 side-channel hardening,
2026-05-02)

Permanent record of the P-R2a session: design + implementation
of the side-channel hardening response per LL-019 (round-2
spec entry). Closes LL-019 from `:open` to `:tested` with
`example-tested` evidence (audit-on-every-verify and
constant-time-response wrappers in `Audit.jl` plus 12 new test
assertions).

---

## §1 — Computational basis

**What was built.**

- **`src/julia/src/Audit.jl`** — adds two wrappers around the
  existing `verify` primitive:
  - `verify_full(ds, env; k, N, Δt, Ttr)` — takes the
    dynamical system, computes the *full Benettin Lyapunov
    spectrum* internally, calls `verify`. Forces full-spectrum
    audit at the API level so callers cannot accidentally
    substitute the cheaper Wolf-method single-exponent
    estimator.
  - `verify_constant_time(λs, env; k, target_seconds)` —
    pads wall-clock elapsed to ≥ `target_seconds` regardless
    of the underlying `verify` result. Implements timing
    decorrelation per LL-019 / V-011.
- **`src/julia/src/LavaLamp.jl`** — re-exports the new
  symbols.
- **`src/julia/test/runtests.jl`** — adds 12 new assertions
  across two `@testset`s: `verify_full forces full-spectrum
  audit (LL-019 audit-on-verify)` and `verify_constant_time
  pads to target (LL-019 timing decorrelation)`.

**Build / run.**

```bash
cd src/julia
julia --project=. -e 'using Pkg; Pkg.test()'  # 94 assertions, ~50s
```

---

## §2 — Results

### §2.1 — The two LL-019 sub-requirements

LL-019 surfaced from round-2 §1C-A1 + §1C-A4 with two
sub-requirements:

1. **Audit-on-every-verify.** Round-2 §1C-A4 identified
   that the chaos-guard's cheap Wolf-method λ̂₁ estimator
   (`DynamicalSystems.lyapunov`, ~1.3 ms/call at N=40) is
   sufficient for *always-on monitoring* but *insufficient
   for verification*. An adversary can craft trajectories
   that match λ₁ (passing the guard) while diverging in
   higher exponents (caught only by the full Benettin
   spectrum, ~507 ms/call). If verification runs the cheaper
   guard estimator, the inter-audit window is the attacker's
   drift budget.
2. **Timing decorrelation.** Round-2 §1C-A1 identified V-011
   (Reseed Oracle): chaos-guard state transitions plus
   naturally-fast `verify` paths produce observable timing
   that correlates with sensor-driven internal state. The
   verifier's response-time distribution leaks
   accept/reject/warmup distinctions even when the response
   *value* is Bool-only per LL-017.

### §2.2 — `verify_full` design

The simplest implementation is API-level: a wrapper that
takes `ds` (the dynamical system, not pre-computed `λs`),
calls `lyapunov_spectrum` internally, then `verify`. Callers
who use `verify_full` cannot accidentally substitute Wolf-
method λ₁ for Benettin spectrum because the function
controls which estimator runs.

The plain `verify(λs, env; k)` remains in the API for
callers who already have a full spectrum on hand (e.g., the
benchmark script which sweeps spectra directly). The two
APIs are complementary: `verify` is the *primitive*,
`verify_full` is the *protocol-enforcing* wrapper.

The cost is the cost of a full Benettin spectrum: ~507 ms at
N=40, ~50-150 ms at N=20, per the 0.0.7 §2.4 cost analysis.
This is the per-verification cost a production deployment
must budget for.

### §2.3 — `verify_constant_time` design

Two design candidates per round-2 §1C-A1:

- **Constant-time response.** Pad to a fixed target time so
  the response is statistically uniform regardless of the
  internal computation path. Simplest; most observable-channel
  hardening.
- **Randomised-delay envelope.** Add Gaussian-distributed
  jitter so the response distribution masks the internal
  timing. Requires a noise distribution that *exceeds* the
  internal timing variance to be effective.

The prototype ships constant-time. Padding via `sleep` is the
implementation choice — production would use an async
deadline scheduler that does not block a worker thread, but
the *correctness* of the decorrelation property is the test
target, not the scheduler implementation.

`target_seconds` choice: must exceed the *slowest* legitimate
verification path so no fast-path leak occurs. For Lorenz-96
N=40 with `verify_full` (~500 ms internal), production should
use `target_seconds ≥ 0.6`. The unit test uses
`target_seconds = 0.3` against pre-computed λs (fast `verify`
path) to demonstrate the property without inflating test
wall-clock.

### §2.4 — What's tested vs what's deferred

The 12 new test assertions exercise:

- `verify_full` correctness (Bool return type; result
  matches manual `lyapunov_spectrum` + `verify`; genuine
  accept; strong adversary reject).
- `verify_constant_time` timing (elapsed ≥ target_seconds for
  both genuine and adversary paths; result equality with
  plain `verify`; Bool return type preserved; argument
  validation).

The *statistical-indistinguishability* property — verifying
that the response-time distribution is genuinely uniform
across many calls — is **deferred to a future benchmark**.
Statistical timing tests are flaky on CI runners (system
load varies); the property is asserted at the design level
and exercised at the smoke level.

A more rigorous side-channel benchmark would:

1. Run N=1000 verify calls across mixed accept/reject inputs.
2. Record elapsed times.
3. Compute the per-bucket (accept-bucket, reject-bucket)
   distributions.
4. Run a Kolmogorov-Smirnov or Anderson-Darling test for
   distributional equality.
5. Assert no significant difference at p < 0.01.

Deferred to either P-R2c (which lands a benchmark
infrastructure) or to a dedicated side-channel benchmark.

### §2.5 — `verify` primitive unchanged

`verify(λs, env; k)` retains its original semantics (Bool
only; vector per-exponent test; no oracle leak). The new
wrappers compose on top. This preserves the LL-006 / LL-017
contracts established in 0.0.9.

The lavalamp CLAUDE.md "no half-finished implementations"
rule is honoured: the wrappers are real implementations
(not stubs); the deferred statistical benchmark is documented
as future work, not pretended-done.

---

## §3 — Verification

### §3.1 — LL-019 side-channel hardening

- **Evidence type:** `example-tested`.
- **Status moves:** `:open` → `:tested`.
- **Test:** `src/julia/test/runtests.jl` LL-019 `@testset`s
  (12 assertions). 94/94 total assertions pass via
  `Pkg.test()` in ~50s.
- **Source:** `src/julia/src/Audit.jl` (`verify_full`,
  `verify_constant_time`).

### §3.2 — Sub-requirements coverage

| LL-019 sub-requirement | Implementation | Test |
|---|---|---|
| Audit-on-every-verify | `verify_full` forces Benettin | "verify_full forces full-spectrum audit" |
| Timing decorrelation | `verify_constant_time` pads | "verify_constant_time pads to target" |

Both sub-requirements have working implementations + tests.
LL-019 closes honestly to `:tested`.

### §3.3 — What `:tested` does NOT mean

- **No empirical timing-distribution analysis.** The
  constant-time *property* is asserted at the design level
  and exercised at the smoke level (elapsed ≥ target).
  Statistical decorrelation across many calls is a benchmark
  follow-up (§2.4).
- **No real-thread timing analysis.** Production deployments
  using `sleep` would block a worker thread; an async
  deadline scheduler is the correct implementation. The
  prototype's `sleep` is the simplest demonstration of the
  property.
- **No formal proof of indistinguishability.** Lean target
  per round-2 §1D.v: "Side-channel formalisation. Model
  observable timing/reseed events and prove (or disprove)
  indistinguishability from legitimate load." This is P5/P6
  work; this companion is the prerequisite design.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-019** side-channel-hardening: `:open` → `:tested`
  with `none` → `example-tested` evidence type. Source
  `src/julia/src/Audit.jl` (`verify_full`,
  `verify_constant_time`); Test
  `src/julia/test/runtests.jl`.

### §4.2 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 5 (LL-003, LL-004, LL-006, LL-007, LL-019)
- **`:benchmarked`:** 0
- **`:argued`:** 9 (unchanged)
- **`:open`:** 7 (was 8; − LL-019)

### §4.3 — Files changed

- `docs/p_r2a_side_channel_hardening_companion.md` (this
  file) — new.
- `src/julia/src/Audit.jl` — `verify_full` +
  `verify_constant_time` added.
- `src/julia/src/LavaLamp.jl` — re-exports.
- `src/julia/test/runtests.jl` — 12 new assertions.
- `src/julia/Project.toml` — version 0.0.10 → 0.0.14.
- `src/julia/Manifest.toml` — version sync.
- `LAVALAMP_SPEC.md` — LL-019 status move; counts.
- `artifact_registry.md` — LL-019 row update; counts.
- `dashboard.md` — P-R2a marked done; status summary.
- `changelog.md` — 0.0.14 entry.

### §4.4 — Followups

- **Side-channel statistical benchmark.** Future session:
  measure the response-time distribution across many calls
  with mixed accept/reject inputs; KS-test or Anderson-
  Darling for distributional equality. Closes the
  `:benchmarked` upgrade for LL-019.
- **P-R2c — LL-021 worst-case-adversary-bound** is the next
  P-R2 sub-task in the natural ordering (analytical +
  benchmark work; can re-use the `verify_full` API).
- **P-R2b — LL-020 calibration confidentiality** is mostly
  design (cryptographic-protocol thinking); can land in any
  order with P-R2c.
- **Lean target.** Round-2 §1D.v Lean priority 2 (side-
  channel timing indistinguishability) is now grounded in
  this companion's `verify_constant_time` design. Theorem
  shape: a constant-time wrapper produces a response-time
  distribution that is ε-close (in some distributional
  metric) to a uniform target distribution, given that the
  target_seconds exceeds the slowest legitimate path.

---

## §5 — Lessons captured

### §5.1 — API-level enforcement vs runtime check

The "audit on every verify" requirement could have been
expressed as a runtime check (`verify` rejects if `λs` looks
like Wolf-method output), but that's ad-hoc and unreliable.
Expressing it as a *wrapper that controls which estimator
runs* is cleaner: callers literally cannot substitute the
cheaper estimator without writing different code, and the
substitution is visible in code review (it's a different
function name).

API-level enforcement > runtime sanity-check for security-
discipline requirements that have to hold under code review.

### §5.2 — Constant-time padding via sleep is honest at prototype scale

Production constant-time response is a real research problem
— OS scheduler jitter, garbage collection pauses, network
latency, all introduce timing variance that the
prototype's `sleep` does not address. But for the
prototype's job (demonstrating the *property* that the
verifier's response is Bool-only and uniform-time), `sleep`
suffices.

The companion documents this honestly: "production would use
an async deadline scheduler that does not block a worker
thread." The prototype isn't pretending to be production;
it's asserting the property and pinning the production
followup.

### §5.3 — Statistical indistinguishability deferred is honest framing

The "constant-time" property is fundamentally statistical
(distribution of response times, not single-call elapsed).
The prototype's tests assert single-call elapsed ≥ target
which is the correctness-of-the-padding property, not the
statistical-indistinguishability property.

`:tested` is the honest status for what the implementation +
tests cover. `:benchmarked` (or `:proved` via Lean) requires
either a statistical benchmark or a formal proof of
distributional equality; both are deferred. The lavalamp
CLAUDE.md "honest framing" discipline matches.
