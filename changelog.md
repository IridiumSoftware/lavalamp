# Changelog — LavaLamp

Versioned entries top-down. Each entry mirrors a commit; commit
messages match entry summaries.

---

## 0.0.14 — 2026-05-02 — P-R2a side-channel hardening (LL-019 :tested)

Implements the round-2 LL-019 architectural response.
`Audit.jl` gains `verify_full(ds, env; ...)` (forces full
Benettin spectrum at the API level — audit-on-every-verify
per round-2 §1C-A4) and `verify_constant_time(λs, env;
target_seconds)` (pads response time to uniform target —
timing decorrelation per round-2 §1C-A1 / V-011).

12 new test assertions across two `@testset`s. Test suite
grows 82 → 94 assertions, all passing in ~50s. LL-019 closes
:open → :tested with example-tested evidence.

### Added

- **`src/julia/src/Audit.jl`** — `verify_full` (Benettin-
  enforcing wrapper) and `verify_constant_time` (timing-
  padding wrapper).
- **`src/julia/src/LavaLamp.jl`** — re-exports.
- **`src/julia/test/runtests.jl`** — 12 new LL-019
  assertions:
  - "verify_full forces full-spectrum audit": Bool return,
    result agreement with manual lyapunov_spectrum +
    verify, genuine-accept, strong-adversary-reject.
  - "verify_constant_time pads to target": elapsed ≥
    target_seconds for both genuine and adversary paths,
    result equality with plain verify, Bool-only return,
    argument validation.
- **`docs/p_r2a_side_channel_hardening_companion.md`** —
  P-R2a session companion. §2.1 documents the two LL-019
  sub-requirements (audit-on-every-verify, timing
  decorrelation); §2.2 / §2.3 document the API-level vs
  runtime-check design and the constant-time-via-sleep
  prototype trade-off; §2.4 explicitly defers the
  statistical-indistinguishability benchmark; §3 honest
  status framing. §5 captures three lessons including
  "API-level enforcement > runtime sanity-check for
  security-discipline requirements that have to hold under
  code review."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.12 → 0.0.14. LL-019
  evidence type `none` → `example-tested`; status `:open` →
  `:tested`; description expanded with implementation
  specifics. Counts: `:tested` 4 → 5; `:open` 8 → 7.
- **`artifact_registry.md`** — version 0.0.12 → 0.0.14.
  LL-019 row updated with test/source paths. Counts.
- **`dashboard.md`** — version 0.0.13 → 0.0.14. P-R2a marked
  ✓ landed in the priority block. Spec status counts.
- **`src/julia/Project.toml`** — version 0.0.10 → 0.0.14.
- **`src/julia/Manifest.toml`** — version sync.

### Why

P-R2a was the smallest of the three round-2 architectural
responses by design (round-2 companion §6.1 noted "P-R2a is
probably the smallest design lift"). Verified empirically:
a single companion doc + two API-level wrappers + 12 test
assertions, ~3s additional test wall-clock.

The implementation is intentionally minimal — `verify_full`
is a wrapper that controls which estimator runs, not a new
estimator; `verify_constant_time` is a `sleep`-based padding
wrapper, not a new scheduler. The lavalamp CLAUDE.md
"no half-finished implementations" rule is honoured by
documenting what's deferred (statistical
indistinguishability benchmark, async deadline scheduler)
rather than pretending the prototype implementation is
production-grade.

### Spec impact

- Counts: total 21 unchanged; `:tested` 4 → 5 (+ LL-019);
  `:open` 8 → 7 (- LL-019); others unchanged.
- Status moves to `:tested`: LL-019.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 5 (LL-003, LL-004, LL-006, LL-007, LL-019)
- `:benchmarked`: 0
- `:argued`: 9
- `:open`: 7

### Known gaps

- **Statistical indistinguishability deferred.** The
  `verify_constant_time` test asserts elapsed ≥ target on
  single calls; the *distributional* property (response-time
  distributions across many calls are statistically
  indistinguishable across accept/reject inputs) is a
  benchmark follow-up.
- **`sleep` blocks worker thread.** Production deployments
  need an async deadline scheduler; the prototype's `sleep`
  demonstrates the property but is not the production
  implementation.
- **LL-020 and LL-021 still :open.** P-R2b and P-R2c
  remaining.

### Followup recommendations

- **P-R2c — LL-021 worst-case-adversary-bound** is the
  natural next sub-task — analytical + benchmark work; the
  benchmark can re-use `verify_full` from this session.
- **P-R2b — LL-020 calibration confidentiality** is mostly
  cryptographic-protocol design (companion doc + spec
  refinement); can land in any order with P-R2c.
- **Side-channel statistical benchmark** — KS-test or
  Anderson-Darling distributional equality across many
  verify calls. Closes the `:benchmarked` upgrade for
  LL-019.
- **Lean side-channel theorem** (round-2 §1D.v priority 2)
  — now grounded in this companion's `verify_constant_time`
  design.

---

## 0.0.13 — 2026-05-02 — Round-2 §7 instantiator resolutions

Records Aaron's resolutions of the four outstanding decisions
the AI integrator flagged in `synthesis_team_round2_companion.md`
§7. No spec moves; no code changes. Small follow-up commit to
the 0.0.12 round-2 integration.

### Changed

- **`docs/synthesis_team_round2_companion.md`** — §7
  rewritten from "outstanding" to "resolved 2026-05-02":
  (1a) Gemini-framing accepted as fair; (1b) three new
  spec entries kept as three; (1c) P3d/P3-bound/P3-Nyq
  deferral confirmed; (2) Grok's Lean priorities adopted
  provisionally ("then we'll discuss"); (3) round-3 trigger
  shifted from "after LL-019/020/021 designs" to "after
  closure_forces_structure physics-paper update lands".
  §6.2 and §1D.v updated to reflect the resolutions.
- **`dashboard.md`** — P-R2 priority block notes Aaron's
  §1D resolution accepted; new P-R3 priority block added
  noting the corpus-event trigger.

### Why

The §7 decisions were genuinely open after 0.0.12 lands
because they involved Aaron's instantiator authority (which
parts of the AI integrator's resolution to accept; how to
weight Lean priorities; round-3 timing). Recording the
resolutions inline keeps the workflow audit trail honest
rather than relying on chat-history recall.

The round-3 timing shift is the most consequential change.
"After LL-019/020/021 designs" was a near-term local trigger;
"after closure_forces_structure paper update" is a corpus-
event trigger that depends on parallel physics work. The
two are complementary — local design work proceeds
independently — but the round-3 brief composition has to
wait for the paper.

### Spec impact

None. Counts unchanged: 21 total; 4 :tested; 9 :argued;
8 :open.

### Followup recommendations

- **P-R2a / P-R2b / P-R2c can land in any order** between now
  and the round-3 trigger.
- **Watch closure_forces_structure paper repos** for the
  update event; round-3 brief composition follows.

---

## 0.0.12 — 2026-05-02 — Synthesis-team round 2 (3 new attack vectors, 3 new spec entries)

Captures the second round of synthesis-seat (Gemini) +
edge-witness-seat (Grok) review on LavaLamp, triggered by P2
closure (0.0.5) and the substantive P3 prototype landing
(0.0.6 - 0.0.10). Brief was forwarded in 0.0.11; responses
arrived together; 0.0.12 is the integration commit.

The two seats produced asymmetric content this round. Grok's
edge-witness review surfaced three real new attack vectors
(V-011 Reseed Oracle, V-012 Calibration Spectrum Leakage,
V-013 Structured α-Direction Attack) plus a structural
concern (A6 linearisability of the linear-in-x coupling).
Gemini's synthesis review affirmed the architecture without
substantively deepening it; the Lean theorem stubs offered
were placeholder-level.

Combined verdict: `engage-and-formalise-after-fixes`. Three
new spec entries land at `:open` (LL-019 side-channel
hardening, LL-020 calibration confidentiality, LL-021
worst-case-adversary-bound). Notes amendments on LL-004 /
LL-006 / LL-007 / LL-011 / LL-014 reflect the round-2
findings. P3 prototype-extension follow-ups (P3d, P3-Nyq,
P3-bound) are *deferred* in favor of P-R2 architectural
responses to LL-019/020/021.

### Added

- **`docs/synthesis_team_round2_companion.md`** — round-2
  dialogue + AI-integrator resolution per the round-1
  pattern. §1A brief summary; §1B faithful summary of
  Gemini response (with honest assessment of its
  limitations); §1C faithful summary of Grok response (three
  new attack vectors + linearisability concern + sharper
  Lean priorities); §1D proposed resolution; §2 round-2
  architectural state; §3 verification (manual evidence);
  §4 spec impact; §5 process notes (round-2 contribution
  asymmetry; brief structure worked unevenly across seats;
  Lean priorities expanded); §6 followups; §7 outstanding
  instantiator decisions for Aaron's confirmation.
- **`docs/attack_surface_enumeration.md`** — three new attack
  vectors:
  - **V-011 — Reseed Oracle.** Chaos-guard state transitions
    observable as timing channel; sensor-correlated; gives
    A4/A5 a thermal-event oracle. Defense: LL-019 (pending).
  - **V-012 — Calibration Spectrum Leakage.** Registration
    ceremony exposes the registered envelope to channel
    observers; TPM defends substitution but not observation.
    Defense: LL-020 (pending).
  - **V-013 — Structured α-Direction Attack.** Real
    adversaries are non-isotropic in α-space; existing
    detection-probability surface is an optimistic lower
    bound. Defense: LL-021 (pending).
  Adversary-class × attack-vector matrix updated; residual-
  risks section extended with three new entries.
- **`LAVALAMP_SPEC.md`** — three new spec entries:
  - **LL-019 — side-channel-hardening** (Core, `:open`).
    Constant-time / randomised-delay response on chaos-guard
    state transitions; "audit on every verification request"
    cadence requirement (full Benettin spectrum, not just
    Wolf-method guard).
  - **LL-020 — calibration-confidentiality** (Core, `:open`).
    Registered envelope sealed against registration-channel
    observers via TPM-sealed storage / ε-DP perturbation /
    multi-party threshold scheme. Complementary to LL-011's
    TPM attestation (which defends substitution, not
    observation).
  - **LL-021 — worst-case-adversary-bound** (Core, `:open`).
    Detection-probability claim (LL-006 / LL-008) re-stated
    against worst-case adversary direction (minimum δ_A over
    admissible perturbation directions), not isotropic.
    Empirical benchmarks must include structured directions.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.10 → 0.0.12. Notes
  amendments (no status changes) on:
  - LL-004 (linearisability limitation; state-dependent
    coupling deferred).
  - LL-006 (empirical detection surface is optimistic;
    worst-case is LL-021's deliverable).
  - LL-007 (reseed-timing decorrelation requirement; LL-019
    pre-condition).
  - LL-011 (calibration confidentiality requirement; LL-020
    complementary).
  - LL-014 (adaptive-thresholding promoted from optional to
    load-bearing for multi-tenant deployments).
  Counts: total 18 → 21; `:open` 5 → 8.
- **`artifact_registry.md`** — version 0.0.10 → 0.0.12.
  Three new rows for LL-019/020/021 (`:open`, evidence
  none). Counts. A1 coverage 21/21; A5 stale-counts updated.
- **`dashboard.md`** — version 0.0.11 → 0.0.12. Project state
  notes round-2 architectural debt; workflow shift from P3
  prototype-extension to P-R2 architectural-response
  sessions; P3 follow-ups marked deferred. New P-R2 priority
  block listing P-R2a/b/c sub-tasks. Recent companion docs
  gains the round-2 brief + companion entries.

### Why

Round 2 was triggered by P2 closing in 0.0.5 plus P3
substantively closing in 0.0.10 (4 of 18 entries `:tested`).
The round-1 plan was for round 2 to validate
"engage-and-formalise" or send work back to architecture.
Both happened simultaneously: the architecture is
fundamentally sound (Gemini's affirmation; Grok's
constructive criticism rather than fundamental obstruction)
*and* the prototype implementation has surfaced attack
surface that the design pass didn't enumerate.

The asymmetric contribution profile (Grok > Gemini this
round) is itself informative. Round 1 had Gemini-first
because synthesis was load-bearing for the in-flux
architecture; round 2 had Grok carrying the substantive load
because the architecture was settled and the implementation
was the new attack surface. For round 3 (after LL-019/020/021
designs land), the brief should weight edge-witness questions
accordingly.

The decision to defer P3 prototype-extension work (P3d,
P3-bound, P3-Nyq) in favor of P-R2 architectural responses
follows the same logic as P3 being gated on P2 in 0.0.5:
running comparative benchmarks against an architecture marked
as having known soft spots produces results that need re-
running. Architecture first; benchmarks once the architecture
is solid.

### Spec impact

- Counts: total 18 → 21 (+3 — LL-019, LL-020, LL-021);
  `:open` 5 → 8; `:argued` / `:tested` / others unchanged.
- Status moves: none. New entries land at `:open`.
- Notes amendments: LL-004, LL-006, LL-007, LL-011, LL-014.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 4 (LL-003, LL-004, LL-006, LL-007)
- `:benchmarked`: 0
- `:argued`: 9 (LL-005, LL-008, LL-011, LL-012, LL-013,
  LL-014, LL-016, LL-017, LL-018)
- `:open`: 8 (LL-001, LL-002, LL-009, LL-010, LL-015,
  LL-019, LL-020, LL-021)

### Known gaps

- **§7 outstanding instantiator decisions.** The companion
  doc lists items where Aaron's call should override the AI
  integrator's proposed resolution before subsequent work
  proceeds. The most consequential: whether the AI
  integrator's framing of Gemini's response as "less
  substantive than the brief asked for" is fair, and whether
  three new spec entries is the right number (versus
  consolidating to fewer).
- **No implementation responses yet.** LL-019/020/021 land
  with `:open` status; their defenses are pending P-R2
  design work. The prototype's V-011/V-012/V-013 attack
  surface is currently *exposed*.
- **Lean target updated but not Lean work landed.** Round-2's
  sharper theorem priorities (linear-coupling worst-case
  bound; side-channel indistinguishability; calibration
  ε-DP) replace Gemini's placeholder stubs but are still
  P5/P6 work.

### Followup recommendations

- **P-R2a — LL-019 design.** Constant-time response /
  decorrelation protocol for chaos-guard state transitions;
  "audit on every verification request" cadence
  specification. Companion doc + minor `Audit.jl` /
  `ChaosGuard.jl` refinement.
- **P-R2b — LL-020 design.** Calibration-data sealing
  protocol (TPM-sealed storage / ε-DP / multi-party
  threshold). Companion doc.
- **P-R2c — LL-021 design.** Worst-case adversary direction
  derivation; structured-adversary benchmark sweep. Companion
  doc + benchmark script + spec refinement.
- **Round 3 trigger** after P-R2a/b/c land. Brief should
  weight edge-witness questions per round-2 §5.1.

---

## 0.0.11 — 2026-05-02 — GitHub Actions CI workflow

Lands the CI workflow flagged as a follow-up since 0.0.7. With
the test suite at 82 assertions and ~47s local wall clock,
manual reruns after every change had become a discipline gap;
CI closes that gap by running `Pkg.test()` on every push to
master and on every PR.

### Added

- **`.github/workflows/test.yml`** — single-job workflow:
  Julia 1.12 on ubuntu-latest, 20-minute job timeout. Steps:
  `actions/checkout@v4` → `julia-actions/setup-julia@v2` (with
  `version: 1.12`) → `julia-actions/cache@v2` (caches the
  Julia depot across runs) → `julia-actions/julia-buildpkg@v1`
  with `project: src/julia` (runs `Pkg.instantiate()`,
  respecting the committed Manifest.toml — lockfile discipline
  preserved) → `julia-actions/julia-runtest@v1` with
  `project: src/julia` (runs `Pkg.test()`). Triggered on
  `push` to master and on `pull_request`. Permissions block
  `contents: read` (least privilege).

### Why

The lavalamp CLAUDE.md package-management rule requires
"verify a clean checkout + lockfile install builds before
committing"; CI mechanically enforces this on every commit
rather than relying on local discipline. For the 82-assertion
test suite, manual rerun on every edit had become slow enough
to be a real friction; CI removes that.

The workflow uses a single Julia version (1.12 to match dev)
on a single OS (ubuntu-latest) — minimal matrix to start.
Project.toml [compat] declares `julia = "1.10"` so the matrix
can expand later without forcing a recheck-everything
session.

The workflow file is the smallest YAML that exercises
`Pkg.test()` against the committed lockfile. No bells, no
benchmarks, no codecov yet — those are follow-ups if the
prototype's wall clock or cost-tracking discipline ever
warrants them.

### Spec impact

None. Workflow is project tooling, not a security claim.
Counts unchanged: 18 total; 4 `:tested`; 9 `:argued`; 5
`:open`.

### Known gaps

- Workflow has not yet been observed to pass on a remote
  runner — this commit triggers its first run. Expected
  outcome: 82/82 assertions pass; wall clock 5-8 minutes
  including precompile (vs ~47s local) on the GitHub-hosted
  ubuntu-latest runner.

---

## 0.0.10 — 2026-05-02 — P3c chaos-guard (LL-007 :tested)

Implements the periodic-window safety signal per architecture-
design §2.3. New `src/julia/src/ChaosGuard.jl` module: state
machine {INVALID, WARMUP, VALID}, GuardConfig with τ_λ /
recovery_threshold / warmup_steps thresholds, default_config
helper, update! transition logic, is_valid Bool predicate
(LL-017 no-oracle compliance), current_lambda diagnostic
field, and reseed! TRNG-derived unit-vector × magnitude state
perturbation.

Test suite grows 47 → 82 assertions, all passing in ~47s — the
runtime is *faster* than 0.0.9 because the chaos-guard tests
use Wolf-method `DynamicalSystems.lyapunov` (single-trajectory,
~1.3 ms per call at N=40) rather than full Benettin
`lyapunovspectrum` (~507 ms per call). 400× speedup confirms
the architecture-design §2.3 cost analysis.

LL-007 closes from `:argued` to `:tested` with `example-tested`
evidence. Counts: `:tested` 3 → 4; `:argued` 10 → 9; total 18
unchanged.

### Added

- **`src/julia/src/ChaosGuard.jl`** — guard module.
  - `GuardState` (`@enum`): INVALID, WARMUP, VALID.
  - `GuardConfig(τ_λ, recovery_threshold, warmup_steps)` with
    construction-time validation (τ_λ > 0; recovery > τ_λ;
    warmup_steps ≥ 1).
  - `default_config(λ₁_expected; warmup_steps=10)` —
    architecture-design §2.3 ratios: `τ_λ = 0.1·λ₁_expected`,
    `recovery_threshold = 5·τ_λ`.
  - `Guard(config)` — mutable state machine; constructor
    initialises in WARMUP (not VALID — security primitive
    must not assume entropy is good before observation).
  - `update!(guard, λ̂₁)` — applies one observation; returns
    post-update state.
  - `is_valid(guard)` → Bool — public predicate.
  - `current_lambda(guard)` → Float64 — diagnostic.
  - `reseed!(ds, guard; rng, magnitude=1.0)` — TRNG unit-
    vector × magnitude perturbation; resets state to WARMUP;
    increments reseed_count.
- **`src/julia/test/runtests.jl`** — 35 new chaos-guard
  assertions across 3 `@testset`s:
  - **State machine** (~17): config validation, initial
    WARMUP, sustained-high → VALID, gray-band dip stability,
    collapse → INVALID, recovery flow.
  - **Lorenz-96 chaotic vs sub-chaotic** (~6): F=8 chaotic →
    VALID; F=2 sub-chaotic (trivial fixed point) → INVALID.
  - **Reseed flow** (~12): VALID → reseed → WARMUP →
    recovery; deterministic-magnitude verification.
- **`docs/p3c_chaos_guard_companion.md`** — session companion.
  Documents the state machine logic, the Lorenz-96 sub-chaotic
  detection scenario, the reseed-with-deterministic-magnitude
  semantic, the cost analysis (cheap Wolf vs full Benettin),
  the LL-002 visual decoupling preservation, the
  module-name/type-name conflict gotcha (Julia docstring
  attachment fails when `module Foo` contains `struct Foo`),
  and four lessons (mod/struct naming, Wolf-vs-Benettin
  always-on monitoring choice, reseed magnitude vs direction,
  conservative-by-construction initial WARMUP).

### Changed

- **`src/julia/src/LavaLamp.jl`** — `include("ChaosGuard.jl")`
  + ChaosGuard re-exports.
- **`src/julia/Project.toml`** — version 0.0.9 → 0.0.10.
- **`LAVALAMP_SPEC.md`** — version 0.0.9 → 0.0.10. LL-007
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; description expanded with implementation
  specifics (Wolf method, exact thresholds, conservative
  initial WARMUP, no-oracle Bool return). Counts: `:tested`
  3 → 4; `:argued` 10 → 9.
- **`artifact_registry.md`** — version 0.0.9 → 0.0.10. LL-007
  row updated. A6 records 82/82 assertions in ~47s wall clock.
- **`dashboard.md`** — version 0.0.9 → 0.0.10. Project state
  summary updated with 0.0.10 numbers. P3 priority block adds
  0.0.10 sub-status; P3c is removed from the remaining list.
  Recent companion docs gains the P3c entry.

### Why

P3c is the operational complement to P3b's residue audit. The
audit is *on-demand* — it runs when verification is requested
and pays its O(N²) full-spectrum cost per request. The chaos-
guard is *always-on* — it runs continuously in the security
primitive's background to catch the periodic-window failure
mode, where the SDE has stalled into a non-chaotic orbit and
the entropy is silently broken. Without the chaos-guard, a
silent drift into a periodic regime would emit consumable
entropy that has no actual chaos behind it.

The cost asymmetry is large enough to matter: ~400× per call
at N=40. That ratio compounds when the guard runs on a
seconds-cadence schedule. The architecture-design §2.3 choice
to use single-exponent Wolf for the guard and reserve full-
spectrum Benettin for the audit is the right cost tradeoff.

The session also surfaced a Julia gotcha worth recording:
`module Foo` containing `struct Foo` breaks the docstring
system with an opaque `MethodError on doc!`. LavaLamp's
convention is now to keep module names and exported type
names distinct (Sensors → SensorStream / CouplingParams;
Audit → Envelope; ChaosGuard → Guard).

### Spec impact

- Counts: total 18 unchanged; `:tested` 3 → 4 (+ LL-007);
  `:argued` 10 → 9 (- LL-007); `:open` 5 unchanged.
- Status moves to `:tested`: LL-007.
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 4 (LL-003, LL-004, LL-006, LL-007)
- `:benchmarked`: 0
- `:argued`: 9
- `:open`: 5

### Known gaps

- **No CI integration yet.** Wall clock dropped to ~47s with
  the cheap-estimator approach, so manual reruns are tolerable
  again, but CI is still recommended before more substantive
  bench work.
- **LL-005 still :argued.** Adversary-rate Nyquist benchmark
  pending. Folds into the existing benchmark framework.
- **LL-006 :benchmarked upgrade outstanding.** Bound-constant
  fitting (K, c, δ_A(ε_A)) against the existing 0.0.9
  detection-probability surface.
- **LL-003 :benchmarked upgrade outstanding.** SDE-selection
  comparative bench (Lorenz-96 vs Lorenz-63 vs Rössler).
- **No real-time integration test.** The chaos-guard is
  exercised by feeding pre-computed λ̂₁ values; a true
  background-thread integration with concurrent SDE
  integration is a production-hardening concern, not a
  prototype-validation requirement.

### Followup recommendations

- **P3d SDE-selection benchmark** — natural next slice. Sweep
  Lorenz-96 / Lorenz-63 / Rössler through the existing
  spectrum + chaos-guard infrastructure. Closes LL-003
  `:benchmarked`.
- **P3-bound LL-006 :benchmarked** — analytic follow-up using
  the existing 0.0.9 detection surface as input. No new
  numerics needed.
- **P3-Nyq adversary-rate Nyquist benchmark** — closes
  LL-005. Requires extending the synthetic-adversary
  framework to perturb sensor sample rate, not just α.
- **CI workflow** — recommended before any of the above.

---

## 0.0.9 — 2026-05-02 — P3b residue audit + detection-probability benchmark

Implements the Lyapunov-spectrum residue audit per
architecture-design §2.1. New `Audit.jl` module: Envelope
(spectrum + per-exponent estimator σ + n_trials calibration),
register_envelope, residue, verify (vector per-exponent test,
Bool-only return per LL-017 no-oracle), synthetic_adversary
(unit-vector L2-magnitude perturbation in α-space). New
benchmark script `benchmark/p3b_detection_probability.jl` and
its committed result file
`benchmark/results/p3b_detection_lorenz96.txt`.

LL-006 closes from `:argued` to `:tested` with `example-tested`
evidence — 18 new test assertions exercising the audit
mechanism, plus the empirical detection-probability surface as
supporting data. Test suite grows 29 → 47 assertions, all
passing in ~78s via `Pkg.test()`.

### Added

- **`src/julia/src/Audit.jl`** — verifier module.
  - `Envelope(spectrum, σ, n_trials, metadata)` immutable
    struct.
  - `register_envelope(ds_factory; n_trials=3, N=1500, Δt=0.05,
    Ttr=300.0, lyapunov_fn=lyapunov_spectrum)` — calibrates
    envelope from independent runs of the genuine system.
    Per-exponent σ is the Bessel-corrected sample standard
    deviation across calibration trials.
  - `residue(λs, env)` — per-exponent absolute differences.
  - `verify(λs, env; k=4.0)` — vector per-exponent test;
    returns `Bool` only (LL-017 no-oracle compliance).
  - `synthetic_adversary(p, ε_A; rng, direction=nothing)` —
    unit-vector + L2-magnitude perturbation in α-space.
- **`src/julia/test/runtests.jl`** — 18 new audit assertions
  across 2 `@testset`s: Audit module mechanism (residue
  correctness, verify Bool semantics, synthetic_adversary
  L2-magnitude preservation, error handling); end-to-end
  exercise (envelope structure, self-acceptance at k=10
  conservative, strong-adversary rejection at k=5 with ε_A=3.0,
  residue-magnitude sanity check).
- **`src/julia/benchmark/p3b_detection_probability.jl`** —
  detection-probability sweep script. Sweeps ε_A ∈ {0.0, 0.1,
  0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0} with 10 trials per
  point; deterministic seeds; writes plain-text result to
  benchmark/results/.
- **`src/julia/benchmark/results/p3b_detection_lorenz96.txt`**
  — committed benchmark output. Empirical detection-probability
  curve at the prototype's working point (Lorenz-96 N=20, F=8,
  k=5, n_trials=10): flat ≈ 10% FPR baseline for ε_A ≤ 0.75;
  sigmoid transition through ε_A ∈ [0.75, 2.0]; saturated
  1.00 detection for ε_A ≥ 2.0. Shape matches the §2.1 bound
  P(detect) ≥ 1 - K·exp(-c·T·δ²); constants not yet derived
  (followup for `:benchmarked` upgrade).
- **`docs/p3b_residue_audit_companion.md`** — session companion.
  §2.1 documents the verifier mechanism. §2.2 records the
  unit-vector + L2 perturbation semantic (vs the noisier
  ε_A·randn alternative). §2.3 records a zero-sensor degeneracy
  bug found during smoke tests (a useful non-degeneracy
  violation example for future sessions). §2.4 reports the
  empirical detection-probability surface. §2.5 explains why
  this lands as `:tested`, not `:benchmarked`. §2.6 documents
  the Sensors-to-top-level module restructure. §5 captures
  three lessons.

### Changed

- **`src/julia/src/LavaLamp.jl`** — submodule load order
  restructured. `Sensors` is now a top-level submodule of
  `LavaLamp` (was nested inside `Engine`); `Engine` and
  `Audit` both reference Sensors via `..Sensors`. New audit
  re-exports.
- **`src/julia/src/Engine.jl`** — `using ..Sensors` instead of
  including Sensors locally.
- **`LAVALAMP_SPEC.md`** — version 0.0.8 → 0.0.9. LL-006
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; description expanded with the vector
  per-exponent test definition and the empirical detection-
  probability surface summary; Source/Test paths added; notes
  reference the bound-constant calibration follow-up. Counts:
  `:tested` 2 → 3; `:argued` 11 → 10. Total still 18.
- **`artifact_registry.md`** — version 0.0.8 → 0.0.9. LL-006
  row updated with `src/julia/test/runtests.jl` +
  `src/julia/benchmark/results/p3b_detection_lorenz96.txt` test
  paths and `src/julia/src/Audit.jl` source. Cross-audit A6
  records 47/47 assertions passing in ~78s wall clock; CI
  recommendation reiterated.
- **`dashboard.md`** — version 0.0.8 → 0.0.9. Project state
  summary updated with P3b numbers. P3 priority block adds
  0.0.9 sub-status; P3-bound (LL-006 `:benchmarked` upgrade)
  added as a new sub-item. Spec status counts updated. Recent
  companion docs gains the P3b entry.

### Why

P3b is the natural next slice after P3a's sensor-coupling
layer. The residue audit is the *security-decision* layer: it
takes the spectrum produced by the coupled SDE and produces
ACCEPT/REJECT decisions. Without it, the substrate-coupled
trajectory has nothing to compare against; with it, the device
identity has structural meaning.

The session validated three claims empirically:

1. **Mechanism correctness.** Envelope, residue, verify, and
   synthetic_adversary all behave as specified (residue is
   per-component abs differences; verify is Bool-only;
   synthetic_adversary preserves L2 magnitude exactly). 18
   new assertions cover this.
2. **Self-acceptance.** At conservative k=10, fresh genuine
   runs against the registered envelope deterministically
   accept. (At working k=5, FPR ≈ 0.10 — characterized in
   the benchmark output.)
3. **Adversary detection.** Strong adversaries (ε_A=3.0)
   deterministically reject at k=5. Weaker adversaries
   transition smoothly: ε_A=1.0 detects 50%; ε_A=0.5
   detects ≈ FPR. Curve shape matches §2.1 bound.

The transition from `:argued` to `:tested` is honest: the
audit *mechanism* is exercised; the *bound's constants* (K, c,
δ_A as a function of ε_A) are not yet derived from the
empirical curve. A future session can fit those constants and
verify the empirical curve is above the bound prediction;
that closes LL-006 to `:benchmarked`.

### Spec impact

- Counts: total 18 unchanged; `:tested` 2 → 3 (+ LL-006);
  `:argued` 11 → 10 (- LL-006); `:open` 5 unchanged.
- Status moves to `:tested`: LL-006.
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-006)
- `:benchmarked`: 0
- `:argued`: 10
- `:open`: 5

### Known gaps

- **LL-006 `:benchmarked` upgrade outstanding.** Requires
  fitting the §2.1 bound's constants K, c, δ_A(ε_A) from the
  empirical curve and demonstrating the empirical P(detect)
  is above the bound prediction. The committed benchmark
  output has the empirical curve; the fit is the missing
  step.
- **No CI integration yet.** Test wall clock now ~78s; manual
  reruns starting to feel slow. Recommended before P3c.
- **LL-005 (sensor Nyquist) still `:argued`.** Adversary-rate
  benchmark folds into the existing benchmark framework but
  hasn't been run.
- **LL-007 chaos-guard untouched.** Cheaper than P3b
  (single-exponent vs full spectrum); should be next.
- **Stub-stream layer only.** Real-sensor FFI deferred per
  the 0.0.8 followups.

### Followup recommendations

- **P3c chaos-guard** is the natural next slice. Cheapest
  remaining sub-task per the 0.0.7 §2.4 cost analysis (single
  exponent vs full spectrum; O(N) vs O(N²)). Closes LL-007 to
  `:tested`.
- **CI workflow** before P3c. With test wall-clock at ~78s,
  manual reruns are getting expensive. GitHub Actions
  `Pkg.test()` on push closes the gap; small lift.
- **P3-bound LL-006 `:benchmarked` upgrade.** Can land in
  parallel with P3c; uses the existing benchmark output as
  input. Modest analytical work to fit (K, c) and predict
  δ_A(ε_A); compare empirical to fitted prediction.

---

## 0.0.8 — 2026-05-02 — P3a sensor-coupling layer

Implements the smooth sensor-to-SDE coupling layer per
architecture-design §2.4. LL-004 (continuous sensor coupling)
closes from `:argued` to `:tested` with example-tested evidence:
a sensor-stream module + a coupled Lorenz-96 variant + 21 new
test assertions exercising sensor primitives, the no-coupling
sanity reduction, stepped-sensor smoothness, and α-sweep
non-degeneracy. Test suite total grows 8 → 29 assertions, all
passing in ~40s via `Pkg.test()`.

### Added

- **`src/julia/src/Sensors.jl`** — sensor stream module.
  - `SensorStream` struct (immutable, validated at construction).
  - `evaluate(stream, t)` — linear interpolation, clamped at
    endpoints, O(log n) lookup via `searchsortedlast`.
  - `constant_stream(value; t_max)` — fixed-baseline fixture.
  - `binary_step_stream(t_step, before, after; ramp_τ, t_max,
    n_samples)` — sigmoid-smoothed binary state transition;
    models AC plug-in / USB plug events.
  - `gaussian_noise_stream(σ; sample_rate, t_max, rng)` —
    pre-sampled white-Gaussian stream; models thermal /
    scheduler-jitter sensors.
  - `CouplingParams(F_base, streams, alphas, coupling_vectors)` —
    parameter bundle threaded through `CoupledODEs`. Validates
    equal stream/alpha/coupling-vector lengths and uniform N
    across coupling vectors.
  - `no_coupling(F_base)` — empty `CouplingParams` reducing the
    coupled SDE to uncoupled Lorenz-96.
- **`src/julia/test/runtests.jl`** — 4 new `@testset` blocks
  (21 assertions) covering: sensor-stream primitives;
  no-coupling sanity (`lorenz96_coupled` with `no_coupling()`
  reproduces uncoupled `lorenz96` to within 0.05 spectrum
  tolerance); stepped-sensor smoothness (binary 0→1 step
  smoothed by sigmoid τ=0.5; trajectory bounded throughout, no
  step-time anomaly, time-windowed mean ⟨x⟩ shifts in predicted
  direction); α-sweep non-degeneracy (constant sensor, sweep
  α ∈ {0, 1, 2}, Δλ₁ measurable per step and cumulatively).
- **`docs/p3a_sensor_coupling_companion.md`** — session
  companion. §2.1 defines the linear-in-x potential
  U(s, x; t) = Σ_k α_k · s_k(t) · ⟨b_k, x⟩; §2.2/§2.3
  document sanity and smoothness results; §2.4 records the
  corrected ⟨x⟩(F) prediction (chaotic-regime mean ≈ 2.34, not
  fixed-point F=8) and its implication that trajectory-mean
  detection is ~10× weaker than spectrum-based detection,
  empirically validating round-1's architectural choice for
  Lyapunov-spectrum residue audit; §2.5 reports non-degeneracy
  measurements (Δλ₁ ≈ +0.30 at α=1, +0.59 at α=2). §5 captures
  three lessons: spectrum vs trajectory-mean SNR, fixed-point
  ⟨x⟩ ≠ chaotic-regime ⟨x⟩, and lockfile `[deps]` vs `[extras]`.

### Changed

- **`src/julia/src/Engine.jl`** — adds:
  - `lorenz96_coupled_eom!(du, u, p::CouplingParams, t)` —
    sensor-perturbed forcing per architecture-design §2.4. Per-
    component perturbation `F_i = F_base + Σ_k α_k · s_k(t) ·
    b_k[i]`. Sensor evaluations hoisted out of the per-component
    loop.
  - `lorenz96_coupled(N; F, coupling, u0)` — public constructor
    of the coupled `CoupledODEs`.
  - Re-exports new symbols.
- **`src/julia/src/LavaLamp.jl`** — re-exports the coupled
  variant + sensor primitives.
- **`src/julia/Project.toml`** — `Random` moves from `[extras]`
  (test-only) to `[deps]` (regular). `gaussian_noise_stream`
  uses `Random.AbstractRNG` and `randn` at module level, so
  Random must be a regular dep. The Manifest does not require
  re-resolution because Random is a stdlib (already
  transitively pinned).
- **`LAVALAMP_SPEC.md`** — version 0.0.6 → 0.0.8. LL-004
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; Source/Test paths added; description expanded
  with the linear-in-x prototype form. Counts: `:tested` 1 →
  2; `:argued` 12 → 11. Total still 18.
- **`artifact_registry.md`** — version 0.0.6 → 0.0.8. LL-004
  row updated. Cross-audit A6 records 29/29 assertions passing
  ~40s wall clock. CI integration explicitly recommended
  before P3b.
- **`dashboard.md`** — version 0.0.6 → 0.0.8. Project state
  summary updated with P3a numbers. P3 priority block adds
  0.0.8 sub-status; P3a marked landed; P3e (non-degeneracy
  benchmark) folded into P3a's test suite (closed in 0.0.8).
  P3-Nyq sub-task added explicitly. CI workflow listed as a
  P3-level deliverable. Spec status counts updated. Recent
  companion docs gains the P3a entry.

### Why

P3a is the next slice after the 0.0.6 baseline. The substrate-
coupling layer is the *substantive* security mechanism: without
it, Lorenz-96 is just a chaotic SDE; with it, the SDE is bound
to the substrate's sensor reads in a way that makes the
device's identity inseparable from its hardware envelope.

The session validated three structural claims empirically:

1. **Smoothness (LL-004 core content).** A discrete sensor
   transition smoothed by a sigmoid ramp does not produce
   numerical artefacts in the SDE integration. The §2.3 stepped-
   sensor `@testset` confirms this directly.
2. **Tracking.** Trajectory-mean ⟨x⟩ shifts in the predicted
   direction with measurable magnitude. The shift is small
   (~0.2 for α=1) — much smaller than the spectrum shift
   (~0.30). This empirically validates round-1's architectural
   choice to detect via the spectrum, not the trajectory.
3. **Non-degeneracy (LL-006 prerequisite).** ∂λ₁/∂α ≠ 0 across
   the α-sweep. For any non-zero adversary deviation in the
   coupling parameter, the spectrum gap δ_A is non-zero, and
   the §2.1 detection bound P(detect) ≥ 1 - K·exp(-c·T·δ²) has
   positive content.

Each of these is `manual` evidence at the design-pass level
(P2, 0.0.5), now upgraded to `example-tested` for LL-004 by
the prototype.

### Spec impact

- Counts: total 18 unchanged; `:tested` 1 → 2 (+ LL-004);
  `:argued` 12 → 11 (- LL-004); `:open` 5 unchanged.
- Status moves to `:tested`: LL-004.
- Partial evidence contributed (no status move): LL-005
  (Nyquist condition — code-level parameter support);
  LL-006 (residue audit — non-degeneracy prerequisite
  empirically demonstrated; detection bound itself remains
  argued).
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 2 (LL-003, LL-004)
- `:benchmarked`: 0
- `:argued`: 11
- `:open`: 5

### Known gaps

- **LL-005 not yet `:tested`.** Adversary-rate Nyquist benchmark
  requires the residue-audit framework from P3b; folds in there.
- **LL-006 detection bound not yet `:tested` / `:benchmarked`.**
  Non-degeneracy prerequisite empirically demonstrated; the
  P(detect) ≥ 1 - K·exp(-c·T·δ²) bound itself is the P3b
  deliverable.
- **LL-016 sensor authenticity unchanged.** Synthetic stub
  layer cannot address authenticity (TPM attestation /
  cross-validation / anomaly-flagging are deployment-time
  questions). Real-sensor FFI deferred.
- **No CI integration yet.** Recommended before P3b; manual
  rerun after every change becomes burdensome once detection
  benchmarks land.
- **Linear-in-x coupling only.** State-dependent coupling
  (U quadratic-or-higher in x) is a future enhancement.
  Architecture §2.1 detection bound's structural-separation
  prior does not require state-dependent coupling, so this is
  not a blocker.

### Followup recommendations

- **P3b — Residue audit + detection-probability benchmark** is
  the natural next slice. Synthetic adversary trajectories by
  parameter perturbation (ε_A); sweep ε_A and observation
  window T; populate the detection-probability surface.
  Closes LL-006 to `:tested`/`:benchmarked` and folds in
  LL-005's adversary-rate Nyquist content. Inner-loop N likely
  10–20 to manage compute (per 0.0.7 §2.4 budget analysis);
  headline assertions at N=40.
- **CI workflow** before P3b. GitHub Actions running
  `Pkg.test()` on push.
- **P3c chaos-guard** can land in parallel with P3b — different
  files, different test scenarios. Cheaper than P3b
  (single-exponent estimator vs full spectrum).

---

## 0.0.7 — 2026-05-02 — P3 baseline companion + dev-host field observations

Late-landing companion for the 0.0.6 P3 baseline session, plus
three empirical observations from the development host that
surfaced during the canonical baseline test run. The 0.0.6
commit was a "large session" per CLAUDE.md workflow rules and
should have included its companion in the same commit; 0.0.7
corrects the omission. The empirical observations are field
signal worth pinning before they get lost between sessions.

### Added

- **`docs/p3_baseline_companion.md`** — P3 baseline companion.
  - **§1 Computational basis.** Files, build commands, dev-host
    wall-clock metrics (~200s first instantiate, ~20s test).
  - **§2.1 Lorenz-96 baseline reproduces literature.** Numbers
    table: λ₁ = 1.6577 (literature ≈ 1.66, 0.2% match);
    n_pos = 14 (literature 13–14); h_KS = 10.27 (literature
    ≈ 10.5); λ_min = -4.90; Kaplan-Yorke dim = 27.11
    (literature ≈ 27).
  - **§2.2 Empirical robustness against host non-stationarity.**
    Documents that a real configuration event occurred during
    the canonical seed=42 baseline run on the dev M5 Max Pro:
    thermal climb to fan-on threshold + AC adapter plug-in
    (battery had dropped below 15%) + battery state-of-charge
    shift. All 8 test assertions still passed. The bounds
    calibrated for finite-window estimator variance + IC
    randomness also absorbed real-world non-stationarity. This
    is stronger evidence for LL-003 than a clean-machine pass.
  - **§2.3 Substrate-coupling self-demonstration.** The §2.2
    events match the architecture-design §2.4 sensor categories
    one-for-one (high-bandwidth thermal noise; discrete-state
    AC-adapter binary; slow-drift battery SOC). Lorenz-96 in
    0.0.6 ignored them because sensor coupling is P3a; once
    P3a lands, repeating with these triggers would propagate
    the events into the trajectory via U(s, x; t) and would
    require LL-013 cross-config classification to distinguish
    legitimate config change from spoofing. The unintended
    self-demo previews the canonical P3a test scenario shape.
  - **§2.4 Compute load and h_KS are structurally linked.**
    Reframes the dev-host fan-spin event from a "compute cost
    concern" to a *structural indicator*: S_production = h_KS
    sets the resolution-boundary margin Δh per LL-008/LL-018,
    and producing h_KS at a meaningful rate requires sustained
    integration cost. A "warm box" is the security primitive
    operating in the chaos-production regime its claim depends
    on; not a tax on security but a signature of it. Three
    sub-implications: (i) hardware deployment is not free, and
    that is correct; (ii) chaos-guard (P3c) is much cheaper
    than residue audit (P3b) — single exponent vs full
    spectrum, O(N) vs O(N²); (iii) P3b benchmarking budget
    will multiply per-trajectory cost across many synthetic
    adversaries, so inner loops likely use smaller N (10 or
    20) with N=40 reserved for headline assertions.
  - **§3 Verification.** LL-003 already :tested in 0.0.6; the
    §2.2/§2.3/§2.4 observations are `manual` evidence and do
    not move other entries on their own.
  - **§4 Spec impact.** No new entries; no further status
    moves. Positioning language captured for future paper /
    pitch use.
  - **§5 Followups.** P3a/b/c/d test-design and budgeting
    lessons distilled from the observations.

### Changed

- **`dashboard.md`** — version bumped to 0.0.7.
  - Recent companion docs section gains
    `p3_baseline_companion.md` entry.
  - **New section: "Live empirical observations".** Three
    bullets capturing the structural h_KS↔compute link, the
    dev host as a free P3a test-scenario source, and the test
    bounds' demonstrated real-world non-stationarity
    robustness.

### Why

Two independent reasons drove this commit:

1. **Workflow discipline.** The 0.0.6 commit introduced the
   Julia track substantively — a "large session" by CLAUDE.md
   criteria — and should have landed with a companion doc in
   the same commit. 0.0.6 missed step 6 of the large-session
   checklist; 0.0.7 closes that gap. Future sessions: keep the
   companion inside the substantive commit.

2. **Field observations worth pinning.** Three observations
   from the dev host during the 0.0.6 baseline test run are
   not faults but useful signal:
   - The test passed under documented host non-stationarity,
     strengthening LL-003's evidence (§2.2).
   - The host events match the design-§2.4 sensor categories
     one-for-one and preview P3a test design (§2.3).
   - Compute cost and h_KS are structurally linked: a warm
     box indicates the security primitive is producing entropy
     at a rate commensurate with its security margin claim
     (§2.4).
   The third observation is the most consequential: it
   reframes pitch language ("LavaLamp runs cheaply in the
   background" would mis-describe the primitive) and informs
   the P3b benchmarking budget directly.

### Spec impact

None. No new spec entries; no status moves. LL-003 was already
:tested in 0.0.6. The §2.2/§2.3/§2.4 observations are `manual`
evidence supporting LL-003 / LL-004 / LL-016 but do not move
those entries — LL-004 / LL-016 close to :tested only when P3a
implements sensor coupling.

### Counts

Unchanged from 0.0.6: 18 entries total; 1 :tested (LL-003);
12 :argued; 5 :open; 0 :proved / :verified / :benchmarked.

### Followup recommendations

- **Companion doc inside the same commit as the substantive
  work.** The 0.0.6 → 0.0.7 split is honest but slightly out
  of sync; future large-session commits include the companion.
- **CI integration before P3a.** Recommended in the §5.5
  followup; currently the only thing protecting LL-003 is a
  manual `Pkg.test()` on the dev host. GitHub Actions running
  tests on push gives the test suite a real chance to catch
  regressions.
- **P3a sensor coupling slice scoping.** §5.1 distills the
  test-design lessons; the natural minimal P3a slice is a
  synthetic sensor stream coupling to U(s, x; t), exercised by
  a test that injects a sensor event mid-run and asserts the
  trajectory tracks it. Real-sensor IOKit / SMC FFI work
  defers to a later sub-task (or P6 hardening).

---

## 0.0.6 — 2026-05-02 — P3 prototype core (bootstrap + Lorenz-96 baseline)

First substantive Julia prototype work. Establishes the
`src/julia/` track with pinned dependencies (lockfile discipline)
and exercises Lorenz-96 (the leading single-attractor candidate
per the design pass) end-to-end against literature reference
values. LL-003 (single-attractor chaotic engine) moves from
`:open` to `:tested` with `example-tested` evidence; project
state moves from design-stage to prototype-stage.

### Added

- **`src/julia/Project.toml`** — package manifest. Name
  `LavaLamp`, UUID `706f996e-…-8ce7c656a42c`, version 0.0.6.
  Pinned direct dependencies (semver compat in `[compat]`):
  - DifferentialEquations 7
  - DynamicalSystems 3
  - StaticArrays 1
  - Statistics (stdlib)
  Test extras: Random, Test (stdlib).
- **`src/julia/Manifest.toml`** — full transitive lockfile,
  resolved against the local registry. Pins 481 transitive
  packages including DifferentialEquations 7.17.0,
  DynamicalSystems 3.6.7, StaticArrays 1.9.18. Committed
  per the lavalamp CLAUDE.md package-management discipline:
  the Manifest IS the reproducibility lockfile in Julia.
- **`src/julia/src/LavaLamp.jl`** — top-level package module.
  Re-exports `lorenz96` and `lyapunov_spectrum` from `Engine`.
  Documents the conventions in force (real-valued math per
  LL-009; bounded-window analysis per LL-010; security-only,
  visual-decoupled per LL-002).
- **`src/julia/src/Engine.jl`** — Lorenz-96 implementation +
  Benettin spectrum estimator.
  - `lorenz96(N=40; F=8.0, u0=nothing)` constructs a
    `CoupledODEs` from `DynamicalSystems.jl` with the in-place
    Lorenz (1996) right-hand side, periodic boundary by 1-based
    modular index arithmetic.
  - `lyapunov_spectrum(ds; N=5000, Δt=0.05, Ttr=1000.0)`
    estimates the full Lyapunov spectrum via QR
    re-orthonormalization. Defaults calibrated for Lorenz-96
    at N=40, F=8.
  - File-level docstring documents the convention set, the
    "why this primitive" rationale (Lorenz-96's high λ₁,
    parameter sensitivity, and rich spectrum vs Lorenz-63 /
    Rössler), the literature reference values, and the
    performance assumption (memory-fits-in-RAM at N ≤ ~10⁴).
- **`src/julia/test/runtests.jl`** — test suite, 8 assertions
  across three `@testset`s:
  - Lorenz-96 construction smoke.
  - Spectrum length = 40, sorted decreasing.
  - λ₁ ∈ [1.4, 1.9] (literature ≈ 1.66; Lorenz, 1996 +
    Karimi-Paul 2010).
  - Number of positive exponents ∈ [11, 16] (literature 13–14).
  - h_KS = Σ max(λᵢ, 0) ∈ [8.0, 12.5] (literature ≈ 10.5).
  - λ_min < -3.0 (strange attractor has contraction).
  - IC-invariance: |λ₁(seed=7) - λ₁(seed=13)| < 0.2 (Oseledec).
  Run via `Pkg.test()` from `src/julia/`. Wall clock ~20s on
  Apple Silicon (M-class). All 8 assertions pass.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.5 → 0.0.6. LL-003
  evidence type `none` → `example-tested`; status `:open` →
  `:tested`; Source/Test paths added; description expanded with
  Lorenz-96 reference values (λ₁ ≈ 1.66, ~14 positive exponents,
  h_KS ≈ 10.5, Kaplan-Yorke dim ≈ 27). Counts: `:tested` 0 → 1;
  `:open` 6 → 5. Total still 18.
- **`artifact_registry.md`** — version 0.0.5 → 0.0.6. LL-003
  row updated (evidence type, Test/Proof file, Source file,
  status). Counts updated. Cross-audit A6 (test sync)
  meaningful for the first time: LL-003 has a runnable test
  exercising it. A1 coverage 18/18 unchanged.
- **`dashboard.md`** — version 0.0.5 → 0.0.6. Project state
  moves from "design-stage" to "prototype-stage." P3 marked
  ◐ in progress with sub-items P3a..P3e enumerated. Spec
  status counts updated. Open structural questions reduced
  (LL-003 leaves the list). Recent companion docs / formal
  artefacts gains a `src/julia/` entry.
- **`.gitignore`** — Julia build/coverage artefact patterns
  added with comment that Project.toml + Manifest.toml ARE
  committed (lockfile discipline).

### Why

P3 is gated on P2 (closed in 0.0.5). The first slice of P3 is
the lockfile + the smallest substantive numerical result that
exercises the toolchain — Lorenz-96 with literature-comparison
test bounds. The bootstrap and the baseline land in one commit
because the bootstrap is the *first* lockfile (no diff to slip
past); the lavalamp CLAUDE.md "lockfiles in their own commit"
rule is about *subsequent* updates, where lockfile changes
without rationale are the failure mode being prevented.

The Lorenz-96 baseline produces concrete numbers cited
elsewhere in the spec:
- **LL-003** is `:tested` against λ₁ ≈ 1.66.
- **LL-007** chaos-guard's λ₁_expected baseline (and τ_λ ≈
  0.1·λ₁_expected ≈ 0.17 reseed threshold) flows from this
  number.
- **LL-008 / LL-018** S_production = h_KS ≈ 10.5 is the
  device's chaos-production rate, which feeds the
  resolution-boundary margin computation per adversary class.
- **LL-006** detection bound P(detect) ≥ 1 - K·exp(-c·T·δ²)
  has c implicitly bounded by the Lyapunov spectrum's
  estimator-variance; concrete c calibration is a P3b
  follow-up.

Honest framing: LL-003 is `:tested`, not `:verified` or
`:proved`. The test exercises one set of parameters with
deterministic seeds and asserts against literature ranges.
QuickCheck-style property tests over the parameter space
(`:verified`) and Lean proofs of structural claims (`:proved`)
remain follow-ups in P4 / P6.

### Spec impact

- Counts: total 18 unchanged; `:tested` 0 → 1; `:open` 6 → 5;
  `:argued` 12 unchanged; `:proved` / `:verified` /
  `:benchmarked` all 0.
- Status moves to `:tested`: LL-003.
- No new spec entries; no removed entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 1 (LL-003)
- `:benchmarked`: 0
- `:argued`: 12
- `:open`: 5

### Known gaps

- **No CI integration yet.** Tests run via `Pkg.test()` from a
  local checkout. GitHub Actions workflow is a follow-up.
- **No sensor coupling yet.** LL-004 / LL-005 / LL-016 still
  `:argued` only. P3a is the next slice.
- **No residue audit yet.** LL-006 still `:argued` only.
  Detection-probability benchmark (P3b) is the next big
  numerical result after sensor coupling lands.
- **No chaos-guard yet.** LL-007 still `:argued` only.
- **SDE-selection benchmark not yet run.** Lorenz-96 is
  committed as the prototype default; comparative bench (P3d)
  upgrades LL-003 to `:benchmarked` once it lands.

### Followup recommendations

- **P3a — sensor coupling implementation** is the natural next
  step. Touches LL-004 / LL-005 / LL-016. Concrete deliverables:
  potential-field U(s, x; t) functional form (Gaussian-ramp for
  discrete inputs, multiplicative for broadband-noise inputs);
  per-sensor coupling vector calibration; Nyquist analysis for
  the chosen coupling under realistic sensor bandwidths.
- **P3d — SDE selection benchmark** could land in parallel with
  P3a since they touch different files. Lorenz-63 and Rössler
  baselines for comparison.
- **CI workflow** (GitHub Actions running `Pkg.test()` on
  push) is small lift; recommend adding before P3a so the
  test suite is the regression discipline from now on.

---

## 0.0.5 — 2026-05-02 — P2 architectural design pass

P2 closure: the architectural design pass formalising the
Lyapunov-spectrum residue audit, the resolution-bounded security
claim, the chaos-guard, the sensor-coupling potential field, and
the protocol layer (registration / cold-start / cross-config /
no-oracle). Twelve spec entries move from `:open` to `:argued`
with `manual` evidence; one new entry (LL-018) added for
per-adversary-class quantification of the resolution-boundary
margin. P3 (Julia prototype core) unblocked.

### Added

- **`docs/architecture_design_companion.md`** — P2 companion.
  Five §2 sub-sections corresponding to dashboard P2 sub-items:
  - **§2.1 Lyapunov-spectrum residue audit (LL-006).** Vector
    per-exponent threshold τᵢ, not scalar. Detection-probability
    bound P(detect) ≥ 1 - K·exp(-c·T·δ_A²) on observation
    window T and adversary spectrum gap δ_A; structural-separation
    prior anchored on Closure v5 catlab_spec.jl
    Thm_Q51_autopoietic / Thm_Q102_structure (cross-sector
    autopoiesis fails 0/5202 across 5 ICs at threshold 0.999;
    cross_sector_autopoiesis_v1.py is the source).
  - **§2.2 Resolution-Bounded Security claim (LL-008) +
    LL-018.** S_production = h_KS = Σ max(λᵢ, 0) (Pesin); bound
    S_production > S_measurement + log(1/η)/Δt; per-class A1..A6
    quantification split into new LL-018 to prevent the "claim
    shrinks under reading" failure mode. Lean theorem shape
    pinned for P6.
  - **§2.3 Chaos-Guard specifics (LL-007).** Benettin
    estimator over W ≈ 100/λ₁_expected; rejection threshold
    τ_λ ≈ 0.1·λ₁_expected; reseed via host TRNG (`/dev/urandom`
    / `getrandom(2)` / `RDRAND`) at ~1× attractor diameter
    magnitude; 2W warmup before re-marking VALID. Decoupling
    from visual layer (LL-002) preserved — reseeds do not signal
    to the visual.
  - **§2.4 Sensor-coupling potential field (LL-004 / LL-005 /
    LL-016).** Per-sensor catalogue (high-bandwidth noise vs
    discrete-state configuration); SDE form
    dx = f(x) dt + σ dW + ∇U(s, x; t) dt with smoothed ramps
    in U for discrete-sensor inputs and broadband-noise terms
    for high-bandwidth sensors; per-sensor Nyquist analysis;
    f_SDE ≈ 10 kHz baseline. LL-016 sensor authenticity
    strategies in decreasing strength: TPM attestation /
    multi-sensor cross-validation / anomaly-flagging /
    accepted-residual-deployment-context. Default for prototype:
    cross-validation + anomaly-flagging.
  - **§2.5 Protocol layer (LL-011 / LL-012 / LL-013 / LL-014 /
    LL-017).** Registration: TPM + device-derived secret mixing
    default; multi-party threshold scheme as no-TPM fallback;
    time-bounded re-registration as defense-in-depth.
    Cold-start: device-reported WARMUP / OPERATIONAL /
    DEGRADED; single-envelope default with WARMUP "retry in T"
    response. Cross-config: per-config registered envelopes
    (PRE) selected by sensor-authentic configuration claim;
    UNKNOWN_CONFIGURATION rejection. No-oracle:
    {ACCEPT, REJECT, WARMUP, TRANSITIONING,
    UNKNOWN_CONFIGURATION, RATE_LIMITED} response set; rate
    limit 10/min/source + 100/hour/device.
  Companion §3 (verification) marks each result `manual`
  evidence with the explicit argument; §4 (spec impact)
  enumerates the status moves and the new LL-018.

### Changed

- **`LAVALAMP_SPEC.md`** — version bumped to 0.0.5. Eleven
  entries (LL-004, LL-005, LL-006, LL-007, LL-008, LL-011,
  LL-012, LL-013, LL-014, LL-016, LL-017) move from `:open`
  /`none` to `:argued`/`manual` with citation to the design
  companion. New entry **LL-018** added (Core / `:argued` /
  `manual`) for per-class A1..A6 resolution-bound quantification.
  Counts: 17 → 18 total; 0 → 12 `:argued`; 17 → 6 `:open`.
  No `:proved` / `:verified` / `:tested` / `:benchmarked`
  changes.
- **`artifact_registry.md`** — version bumped to 0.0.5. Twelve
  registry rows updated with `manual` evidence type, design-
  companion path, and `:argued` status. New row for LL-018.
  Cross-audit A1 coverage now 18/18; A4 status-honesty preserved.
- **`dashboard.md`** — version bumped to 0.0.5. Project state
  changes from "concept-stage" to "design-stage." P2 marked
  ✓ landed with sub-item summary. P3 marked unblocked. Spec
  status counts updated. Open structural questions reclassified
  into "awaiting P3 / P5–P6 verification" (LL-001/002/003) and
  "corpus-policy boundaries" (LL-009/010/015). Live discipline
  notes consolidated into the structural-questions section
  rather than a separate block (the asymmetry-trap watch and
  the no-complex-numbers / no-open-ended boundaries remain in
  force; their wording is preserved in-place).

### Why

P2 is the gate for P3. The attack-surface enumeration (P1,
0.0.3) listed ten attack vectors with "mitigation pending"
sections naming the design work each vector required. P2
discharges that design work for every vector except the
fundamental sensor-authenticity gap (V-006), which is mitigated
by LL-016's strategy menu but not eliminated — and that
limitation is now honestly stated in the spec rather than
implicit.

The design pass produces `manual` evidence — the weakest
upgrade-tier under the CLAUDE.md taxonomy. This is honest tier
framing: a written argument is not a Lean proof, a Haskell
type-check, or a benchmark. Each `:argued` entry has a clear
upgrade path: P3 prototype produces `:tested` /
`:verified` / `:benchmarked` evidence; P5 Haskell QuickCheck
extends compositional coverage; P6 Lean machine-verifies the
core structural theorems (LL-006 detection bound, LL-008
resolution-boundary, LL-018 per-class quantification).

The Closure v5 corpus citations used to ground LL-006's
structural-separation prior were verified directly against
`catlab_spec.jl` (lines 1855, 1858, 2415) and
`cross_sector_autopoiesis_v1.py`. The earlier
`qkd_pqc_complementarity_companion.md` named the citations; this
companion ties them to specific corpus loci. The
0/5202-on-primary-seed result is `:catlab` evidence — algebraic
/ computational categorical proof at the source — which makes
LavaLamp's structural-separation prior load-bearing rather than
hand-waved.

### Spec impact

- Counts: total 17 → 18; `:argued` 0 → 12; `:open` 17 → 6.
- Status moves to `:argued`: LL-004, LL-005, LL-006, LL-007,
  LL-008, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017.
- New entry: LL-018 (Core, `:argued`).
- Stays `:open`: LL-001, LL-002, LL-003 (await Lean / type / P3
  benchmarks), LL-009, LL-010, LL-015 (corpus-boundary
  declarations).

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 0
- `:benchmarked`: 0
- `:argued`: 12
- `:open`: 6

### Known gaps

- **No code yet.** P3 (Julia prototype core) unblocked but not
  yet started. Lockfile discipline (`Manifest.toml`) from day 1
  per CLAUDE.md rule.
- **Sensor-authenticity residual (V-006 / LL-016)** is the
  largest residual risk even after 0.0.5. The design pass
  surfaces four mitigation strategies and recommends a default;
  no strategy fully eliminates V-006. High-assurance deployments
  must specify their A4 capability assumption.
- **Lean theorems remain at sketch level.** §2.2 of the
  companion pins the theorem shape for `detection_complete`;
  the proof is P6 work. None of the `:argued` entries become
  `:proved` until Lean verifies them.
- **Round-2 synthesis-team review** trigger is now met (P2
  closed); not yet invoked. Plan: forward this companion +
  attack-surface enumeration to Gemini (synthesis seat) and
  Grok (edge-witness seat) before P3 prototype work begins.

### Followup recommendations

- **P3 entry points** are listed in dashboard `Priority stack`
  P3 paragraph: SDE selection benchmark, Benettin /
  Rosenstein / Wolf estimator implementation, U(s, x; t)
  concrete form, ∂λ/∂s non-degeneracy benchmark, baseline τᵢ
  threshold calibration.
- **Catlab tier decision (P4)** revisited with concrete
  protocol-layer designs in hand. The protocols (registration /
  cold-start / cross-config) are state-machine + cryptographic
  protocol shape, not categorical structure that obviously
  benefits from Catlab over Haskell. **Recommendation
  unchanged: skip Catlab for LavaLamp.** Document in a
  follow-up to `language_plan_catlab_tier_companion.md`.
- **LL-009 / LL-010** boundary entries should close to
  `:argued` under a small-session companion that articulates
  each boundary in the LavaLamp-specific context. Candidates
  for a future small task; not a P3 dependency.

---

## 0.0.4 — 2026-05-01 — Methodology + positioning refinements

Two related refinements landed in the same session: (1) Catlab.jl
inserted as a fifth tier in the formal stack between numerical
verification and Haskell compositional completeness, motivated by
the Closure v5 corpus's `:catlab` evidence-type precedent (9 of
145 `:proved` entries); (2) a positioning companion capturing the
QKD / PQC / possibilistic-identity complementarity worked through
earlier in the session.

### Added

- **`docs/language_plan_catlab_tier_companion.md`** — captures the
  Catlab tier insertion. Establishes the three-jobs distinction
  (Catlab computational-categorical / Haskell compositional /
  Lean formal), the productivity ordering rationale (Catlab
  iterates faster than Haskell or Lean for "does the model close
  at all"), and the LavaLamp-specific decision rule (skip Catlab
  by default; revisit if P2 verification-protocol design surfaces
  categorical structure). Anchors the tier on Closure v5
  corpus precedent — `:catlab` is an audited evidence type with
  9 `:proved` entries currently in the corpus.

- **`docs/qkd_pqc_complementarity_companion.md`** — captures the
  positioning analysis: LavaLamp is not QKD (different problem,
  different security tier — resolution-bounded computational,
  not information-theoretic); is defensive-postured (detect via
  Lyapunov-spectrum residue, not prevent observation); composes
  with PQC rather than replacing it (PQC defends transit
  confidentiality; possibilistic identity defends authentication
  — different layers); replaces MFA under identity-as-closure;
  and inherits the C-conjugate adversary from the Closure v5
  cross-sector autopoiesis result (0/5202 on primary seed,
  v156). Records the resolution of an earlier misreading by
  Claude of the Possibilistic Security paper's PQC claim. Adds
  a §2.6 noting the implication of the Q₅₁-as-autopoietic
  reframing (Closure v5 v157, S157) for the identity layer:
  identity is Q₅₁-tier, and the residue audit is a spectrum
  check, not a checkpoint trace match.

### Changed

- **`CLAUDE.md`** — "Language tiers and phase discipline" section
  revised. Catlab.jl / GATlab inserted between verify / obstruct
  and prove (compositional). The three-jobs distinction (Catlab /
  Haskell / Lean) made explicit with explicit "do not collapse"
  warnings for each pairwise collapse. LavaLamp-specific priority
  list updated: P4 is now Catlab (gated on P2), P5–P8 are the
  former P4–P7 (Haskell, Lean, C / C++, visual skin) renumbered.

- **`dashboard.md`** — recent companion docs section updated with
  the two new companions; priority stack renumbered to match
  CLAUDE.md (P1–P8 instead of P1–P7); Catlab decision rule noted
  in P4.

### Why

The 0.0.2 language plan correction (Haskell + Lean → Julia /
Haskell / Lean) covered the prototype-core mistake. It missed the
Catlab tier, which has independent corpus precedent (Closure v5
has 9 `:catlab` `:proved` entries via CatLab.jl) and serves a
distinct job: *computational* category theory that fits between
numerical verification and Haskell's compositional-completeness
check.

The three-jobs distinction is load-bearing: collapsing Catlab into
Haskell (or vice versa) loses content. Catlab computes with
categorical objects; Haskell enumerates composition space; Lean
proves theorems formally. Closure v5's evidence taxonomy already
treats `:catlab` as a distinct evidence type capable of
proved-tier status, so this is precedent, not speculation.

The productivity ordering — Catlab iterates faster than Haskell
or Lean for "does the model close at all" questions — means by
the time a result reaches Haskell the morphisms are known to
compose, and by the time it reaches Lean the theorem statement is
known to be right. Cheaper iteration buys correctness gradient
before more expensive tiers see the work.

The positioning companion is independent of the methodology
refinement but lands in the same session because the conversation
covered both. It captures conclusions about LavaLamp's security
tier, defensive posture, and complementarity with QKD / PQC /
identity-as-closure that were settled earlier in the session and
risked being lost to chat history. The §2.6 connection between
LavaLamp identity and the Q₅₁-as-autopoietic Closure v5 result
is new — it grounds the residue audit's spectrum-vs-trace
distinction in a corpus reframing, which strengthens the
conceptual argument behind LL-006.

### Spec impact

None. Both refinements are methodology / positioning, not
security-primitive claims. Spec entry counts unchanged (still 17
entries, all `:open`). No new LL-IDs; no `LAVALAMP_SPEC.md`
change; no `artifact_registry.md` change. The
`artifact_registry.md` cross-audit A1 coverage check still passes
at 17/17.

### Counts

Unchanged: 17 entries, all `:open`. The revisions land in
governance and companion-doc files only.

---

## 0.0.3 — 2026-05-01 — Attack-surface enumeration (P1)

The load-bearing technical artefact: formal threat tree against
LavaLamp's architecture as currently specified (LL-001..LL-014).

### Added

- **`docs/attack_surface_enumeration.md`** — formal threat tree
  document. Six adversary classes taxonomised (A1 remote
  software, A2 unprivileged user-space, A3 root [out of scope],
  A4 side-channel / physical proximity, A5 registration-time,
  A6 time-localized). Ten attack vectors enumerated:
  - **V-001** "good enough" trajectory (defended by LL-006
    Lyapunov-spectrum + LL-003 single-attractor + LL-002 visual
    decoupling)
  - **V-002** basin-spoofing (closed by LL-002 decoupling;
    documented as historical attack with discipline-watch)
  - **V-003** quantum-seed → classical software boundary
    (defended by LL-005 Nyquist + LL-004 continuous coupling)
  - **V-004** sensor Nyquist failure (defended by LL-005)
  - **V-005** slow-drift threshold gaming (defended by LL-006
    multi-scale spectrum + LL-007 chaos-guard)
  - **V-006** sensor-input poisoning (largest residual risk;
    surfaces LL-016 sensor-authenticity-requirement as new
    spec entry)
  - **V-007** registration ceremony (trust-root attack; LL-011
    pending design)
  - **V-008** cold-start window exploitation (LL-012 pending
    design)
  - **V-009** cross-config transition spoofing (LL-013 pending
    design; inherits V-006 risk)
  - **V-010** threshold calibration gaming (surfaces LL-017
    no-oracle requirement; defended partially by LL-006)
  Document also includes adversary-class × attack-vector matrix
  (§4), residual-risks-not-yet-defeated enumeration (§5),
  spec-impact recommendations (§6), followups (§7), and document
  discipline (§8). Maintained artefact, not session companion —
  will be updated as architecture evolves.

### Changed

- **`LAVALAMP_SPEC.md`** — three new spec entries surfaced by
  the enumeration:
  - **LL-015 — adversary-class-A3-out-of-scope** (Boundary).
    Honest scoping: LavaLamp does not claim defense against
    kernel-level adversaries. Parallel to LL-009 / LL-010 in
    pinning a corpus boundary explicitly.
  - **LL-016 — sensor-authenticity-requirement** (Core). Sensor
    reads used in security primitive require independent
    authenticity check. Largest residual risk in current
    architecture; mitigation strategies pending (multi-sensor
    cross-validation / hardware attestation /
    accepted-deployment-context risk).
  - **LL-017 — verification-no-oracle** (Core). Verification
    protocol must not expose accept/reject feedback usable for
    threshold probing. Required for LL-014 calibration to
    deliver intended security.
  Counts: 14 → 17 entries; all `:open`.
- **`artifact_registry.md`** — three new rows for LL-015..LL-017.
  Counts updated. A1 coverage check updated to 17/17.
- **`dashboard.md`** — P1 marked ✓ landed. Spec status updated
  (17 entries). Open structural questions section expanded to
  include the three new entries surfaced by enumeration. Recent
  companion docs / formal artefacts section now distinguishes
  session companions from maintained artefacts.

### Why

P1 is the load-bearing technical content of LavaLamp. Without a
formal threat model, the architectural claims in
`LAVALAMP_SPEC.md` are defensible only against the attacks that
happen to come to mind during informal discussion. The
enumeration produces:

1. **Defensible claims.** Each LL-ID's defensive coverage is
   traced to specific attack vectors. The architecture's
   security posture is now stateable in concrete terms.
2. **Honest residual risks.** Five risks the current
   architecture does *not* defeat are named explicitly: sensor
   authenticity (V-006); registration ceremony (V-007);
   cold-start window (V-008); cross-config transitions (V-009);
   threshold calibration (V-010). Each is mapped to its `:open`
   spec entry. No covert overclaiming.
3. **Spec growth.** Three architectural claims that were
   *implicit* in 0.0.1–0.0.2 are now *explicit*: A3 boundary
   (LL-015), sensor authenticity (LL-016), no-oracle requirement
   (LL-017). Pinning prevents drift.
4. **Foundation for P2 (architectural design pass).** Each
   attack vector's "mitigation pending" section lists the design
   work needed. P2 closes those.

### Spec impact

Spec entries 14 → 17. All `:open`. Counts in
`LAVALAMP_SPEC.md`, `artifact_registry.md`, and `dashboard.md`
synchronized.

### Known gaps

- **Sensor authenticity (V-006 / LL-016) is the biggest residual
  risk** in the current architecture. Mitigation strategies are
  named but not yet selected.
- **Registration ceremony (V-007 / LL-011)** is the trust root;
  any deployment is undefended at registration time until
  designed.
- **Cold-start window, cross-config transitions, threshold
  calibration (V-008..V-010)** all pending P2 design work.
- **No code yet.** P3 (Julia prototype core) gated on P2 closure.
- **Round-2 synthesis-team review** of the attack-surface
  enumeration not yet triggered. Plan: forward this document +
  P2 outputs (when ready) to Gemini and Grok and ask them to
  validate the threat tree against attacks the enumeration may
  have missed.

---

## 0.0.2 — 2026-05-01 — Language-plan correction

Pattern-match correction on the priority-stack language assignments.
0.0.1 inherited the triadic-coordination-engine's "Haskell core +
Lean 4 formalisation" stack via pattern-matching, without checking
whether it fit LavaLamp's actual technical needs. Aaron flagged
the mismatch: LavaLamp is continuous-numerical / real-time /
sensor-coupled, which is Julia's natural register, not Haskell's.

### Changed

- **`CLAUDE.md`** — new "Language tiers and phase discipline"
  section between "Honest tier framing" and "Workflow rules".
  Codifies the explore / verify-or-obstruct / prove-compositional
  / prove-formal / harden methodology, with stage-appropriate
  language choices and the rationale for each tier.
- **`dashboard.md`** — priority stack restated. P3 was previously
  "Language-track infrastructure (Haskell + Lean)"; now split
  into P3 (Julia prototype core), P4 (Haskell compositional-
  completeness via spec-as-types + QuickCheck), P5 (Lean 4 formal
  verification of structural security claims), P6 (C/C++ future
  hardening from proven spec), P7 (decoupled visual skin).
- **`README.md`** — layout-comment updated to reflect the language
  plan; placeholder src-subdirectory map shows
  `src/{julia, haskell, lean4, cpp}` rather than just
  `src/{haskell, lean4}`, with which-language-for-which-priority
  explicit.
- **`docs/synthesis_team_round1_companion.md`** — new §7
  capturing the language-plan revision, including Aaron's
  articulated stage-tiered methodology and the rationale for the
  Julia / Haskell / Lean split.

### Why

LavaLamp's prototype core needs to live where the chaos / SDE /
real-time-numerical community has done the algorithmic work, which
is Julia's `DifferentialEquations.jl` + `DynamicalSystems.jl` +
`ChaosTools.jl` stack. Haskell still has a role — but a *different*
role from the engine project: as the **compositional-completeness
checker** at the prove stage, expressing the spec as types and
running QuickCheck-style universal coverage to catch corollaries
the example tests miss. The S-026 `semanticSimilarity` symmetry
bug in the engine is the canonical example of why this stage
matters: hand-built example tests passed; QuickCheck immediately
falsified symmetry. Without that stage, an unspotted universal
sails into Lean and any C/C++ rewrite. Lean stays at "prove
(formal) — is the theorem true," which is a different job from
"prove (compositional) — did we enumerate everything."

C/C++ stays as future hardening from the proven spec, not from the
exploratory code.

### Spec impact

None. LL-001 through LL-014 are unchanged. The correction is
about *which language implements each stage of the methodology*,
not about the architectural claims themselves. All entries remain
`:open` at this commit.

### Counts

Unchanged: 14 entries, all `:open`. The revision is about how
those entries get implemented and verified, not what they assert.

---

## 0.0.1 — 2026-04-30 — Concept-stage foundation

Bootstrap the project's discipline scaffolding before any code or
attack-surface enumeration. Mirrors the triadic-coordination-engine
foundation pattern (spec → registry → dashboard → companion docs →
governance).

### Added

- **`CLAUDE.md`** — project governance. Identity, orientation,
  ground-truth hierarchy, evidence types, load-bearing scope
  boundaries (no complex numbers in security-critical math; no
  open-ended simulation), honest tier framing
  (resolution-bounded computational unclonability, NOT QKD-grade),
  workflow rules, companion-doc standard, cross-audit protocol,
  key principles, what-not-to-do.
- **`LAVALAMP_SPEC.md` v0.0.1** — 14 named claims with LL-IDs,
  logic tiers, evidence types, statuses. All `:open`. Covers:
  - Core architecture (LL-001..LL-005): substrate-bound identity,
    visual/security decoupling, single-attractor SDE engine,
    continuous sensor coupling, sensor Nyquist condition.
  - Detection / verification (LL-006..LL-008): Lyapunov-spectrum
    residue audit, chaos-guard, resolution-bounded security claim.
  - Boundary constraints (LL-009..LL-010): no complex numbers, no
    open-ended simulation.
  - Open protocol questions (LL-011..LL-014): registration
    ceremony, cold-start window, cross-config transitions,
    threshold calibration.
- **`artifact_registry.md` v0.0.1** — registry rows for every
  LL-ID, with self-check against cross-audit A1–A6.
- **`dashboard.md`** — status summary, priority stack, spec
  status, open structural questions, live discipline notes.
- **`changelog.md`** — this file.
- **`docs/concept_origin_companion.md`** — provenance graph
  (codetaur visual seed, Aaron concept derived from Possibilistic
  Security, Brian ORSIΩ-vocabulary engagement,
  patent-offer-to-codetaur).
- **`docs/synthesis_team_round1_companion.md`** — full dialogue
  arc: Gemini synthesis 1, Grok edge-witness 1, Gemini rebuttal +
  premature skeleton, Grok edge-witness 2 on visual-richness
  blindspot, Aaron's decoupling resolution.
- **`README.md`** — project overview (private repo register).
- **`.gitignore`** — Haskell + Lean + macOS standard.

### Why

Concept-stage projects accumulate decisions in chat history that
get lost. Mirroring the triadic-coordination-engine foundation
pattern: every named claim gets an LL-ID with status; every
substantive session produces a companion doc; the spec is ground
truth. This commit captures the architecture as currently
synthesized — the result of one full round of synthesis-team
(Gemini) + edge-witness-team (Grok) review, with Aaron's
decoupling-resolution closing the round-1 blindspot.

The decision to scaffold the discipline *before* attack-surface
enumeration mirrors the engine project's spec-first arc and is
consistent with the corpus-wide spec → registry → companion → code
sequence. Code work is gated on attack-surface enumeration, which
is gated on this scaffold.

### Known gaps

- **No code.** Concept-stage. Language tracks (Haskell + Lean 4)
  pending after attack-surface enumeration.
- **Attack-surface enumeration not yet drafted.** P1 priority.
- **Architectural details still informal** in places: the
  Lyapunov-spectrum residue audit's probabilistic detection
  bound, the chaos-guard implementation specifics, the
  sensor-coupling potential field definition (which sensors, how
  mapped, sampling rate calibration). All marked `:open` in the
  spec.
- **The four protocol-level open questions** (registration
  ceremony, cold-start window, cross-config transitions, threshold
  calibration) block any production deployment.
- **Visual-skin scaffolding** not yet drafted. Decorative-only
  per LL-002; low priority.

### Provenance note

Visual seed credit: codetaur (SDE imagery resembling a lava lamp;
structural application unintended). Patent offer extended as
good-faith credit. Concept and security application: Aaron Green,
derived from the C-conjugate adversary structure introduced in
*Possibilistic Security*. Discussion / framing engagement: Brian
Crabtree (ORSIΩ vocabulary). Synthesis-team review: Gemini
(synthesis seat) + Grok (edge-witness seat), 2026-04-30.

---

## Pre-changelog history

None. This commit is the project's foundation.
