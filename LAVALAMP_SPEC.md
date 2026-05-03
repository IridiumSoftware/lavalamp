# LAVALAMP_SPEC.md — LavaLamp

Version: 0.0.20 (closure pass — LL-001/002/009/010 :argued, 2026-05-03)
Authoritative reference for every named claim LavaLamp makes.

## Conventions

**LL-ID** — unique identifier. Format `LL-NNN`, zero-padded.

**Logic tier** — `Core` (load-bearing structural claim about the
primitive), `Operational` (behavior of the implementation),
`Boundary` (scope-limiting constraint inherited from corpus).

**Evidence type** (per CLAUDE.md §Evidence types):

| Type | Sufficient for `:proved`? |
|---|---|
| `lean-proved` | Yes |
| `type-checked` | Yes |
| `algebraic` | Yes |
| `property-tested` | No → `:verified` |
| `example-tested` | No → `:tested` |
| `benchmarked` | No → `:benchmarked` |
| `manual` | **No** → `:argued` only |
| `none` | No → `:open` |

**Status** — `:proved | :verified | :tested | :benchmarked | :argued | :open`.
A spec entry may have `:proved` only if evidence type is
`lean-proved`, `type-checked`, or `algebraic`.

**Update discipline.** Spec entries are append-only by LL-ID. To
revise a claim, mark the original with `Status: superseded by LL-NNN`
and add a new entry. Keys may be edited in place; identity is the
LL-ID, not the Key.

---

## Core architecture — open

### LL-001 — substrate-bound-identity-primitive
- Key: identity is the chaotic SDE trajectory on the device
- Logic tier: Core
- Description: Device identity is realised as the sustained chaotic
  trajectory of an SDE solver running on the device, with noise /
  parameter terms coupled to live hardware sensors. The identity is
  a continuous *function of (machine, configuration, time)*, not a
  static credential. Verification compares trajectory features
  against a registered hardware envelope.
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §1 — composed
  claim argued via component evidence: SDE solver (LL-003
  :tested), sensor coupling (LL-004 :tested), residue audit
  verification (LL-006 :benchmarked), real-time validity check
  (LL-007 :tested). The audit benchmark
  (`benchmark/results/p3_bound_high_res_lorenz96.txt`)
  exercises the composed identity claim end-to-end.
- Notes: :tested upgrade requires either (a) Lean / type-level
  enforcement of the composition property, or (b) a test
  suite written specifically against LL-001's higher-level
  claim. Both deferred to P5/P6.

### LL-002 — visual-security-decoupling
- Key: visual layer and security primitive are architecturally independent
- Logic tier: Core
- Description: The user-facing lava-lamp visual animation does
  *not* derive from the security-critical SDE trajectory. The
  visual can be driven by any RNG (including a simple
  `Math.random()`-style bubble simulator) and is decorative only.
  The security primitive (chaotic SDE + sensor coupling +
  Lyapunov-spectrum residue audit) runs as an independent
  background process. This decoupling resolves the
  visual-richness ↔ security tension that round-1 synthesis-team
  review (Gemini + Grok, 2026-04-30) identified as a structural
  blindspot in any design that fed the visual *from* the SDE.
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §2 — invariant
  preserved by construction across the Julia prototype: no
  visual layer exists; the security primitive
  (`Sensors.jl`, `Engine.jl`, `Audit.jl`, `ChaosGuard.jl`)
  has no visual-layer dependencies; chaos-guard reseed
  events do not signal to a visual; round-2 reviewers
  treated LL-002 as settled (no proposed re-coupling).
- Notes: This is a load-bearing architectural invariant. If the
  visual ever gets re-coupled to the security primitive, the
  basin-spoofing attack surface returns (multi-basin reaction-
  diffusion regimes the visual layer would want to use are
  precisely where the adversary can hide a spoof inside scalar-KL
  threshold). :tested upgrade requires either (a) a visual layer
  with assertions about decoupling, or (b) Lean / type-level
  enforcement that the security-primitive type-graph cannot
  reach the visual-layer type-graph. Both deferred.

### LL-003 — single-attractor-chaotic-engine
- Key: security primitive uses single-attractor chaotic SDE
- Logic tier: Core
- Description: The security primitive's underlying SDE has a
  *single* strange attractor (e.g., Lorenz, Lorenz-96, Rössler,
  jerk-equation systems), not a multi-basin reaction-diffusion
  structure. Single-attractor is now viable because LL-002
  decouples visual richness from security, removing the constraint
  that would have pulled toward multi-basin systems. Lorenz-96
  (N=40, F=8) is the prototype's default: λ₁ ≈ 1.66, ~14 positive
  exponents, h_KS ≈ 10.5, Kaplan-Yorke dimension ≈ 27.
- Evidence type: example-tested
- Status: :tested
- Source: src/julia/src/Engine.jl (Lorenz-96 implementation +
  Benettin spectrum estimator).
- Test: src/julia/test/runtests.jl (8 assertions: spectrum
  length, sortedness, λ₁ ∈ [1.4, 1.9], n_pos ∈ [11, 16],
  h_KS ∈ [8.0, 12.5], λ_min < -3.0, IC-invariance of λ₁
  under Oseledec). Run via `Pkg.test()` from
  `src/julia/`; passes 8/8 in ~20s wall clock on Apple Silicon.
- Notes: SDE-selection benchmark across Lorenz-96 / Lorenz-63 /
  Rössler is a follow-up; Lorenz-96 is committed as the
  prototype default. Final selection upgrades to `:benchmarked`
  when the comparative bench lands. Stochastic perturbation
  (the σ dW term in §2.4 design) and sensor coupling land in
  subsequent modules.

### LL-004 — continuous-sensor-coupling
- Key: sensor data couples to SDE as continuous potential field, not discrete kicks
- Logic tier: Core
- Description: Live hardware sensor reads (battery state, AC
  adapter, USB peripheral status, CPU thermal, scheduler timing)
  perturb the SDE through a smooth *external potential field*
  pulling the trajectory toward configuration-specific regions of
  the attractor. Hard step-function parameter changes from discrete
  sensor reads are forbidden — they create numerical artefacts an
  adversary could detect and resync against. Prototype implements
  the linear-in-x case: U(s, x; t) = Σ_k α_k · evaluate(streams[k], t)
  · ⟨b_k, x⟩, so ∇_x U is constant in x and reduces to a sensor-
  modulated additive forcing per dimension. Sufficient for non-zero
  δ_A (LL-006 prerequisite).
- Evidence type: example-tested
- Status: :tested
- Source: src/julia/src/Sensors.jl (SensorStream + smoothing
  primitives + CouplingParams), src/julia/src/Engine.jl
  (lorenz96_coupled_eom!, lorenz96_coupled).
- Test: src/julia/test/runtests.jl (4 new @testsets / 21
  assertions: sensor-stream primitives, no-coupling sanity,
  stepped-sensor smoothness, α-sweep non-degeneracy). Run via
  Pkg.test() from src/julia/; passes 29/29 in ~40s on Apple
  Silicon.
- Notes: Implementation respects Nyquist condition (LL-005) at
  the parameter level (sample-rate set per stream, f_SDE via Δt).
  State-dependent coupling (U quadratic-or-higher in x) is a
  future enhancement, not a prerequisite. Real-sensor FFI
  deferred to a later P3 sub-task or P6 hardening.
- **Round-2 limitation (2026-05-02):** Linear-in-x coupling
  is *linearisable* by an adversary with system-identification
  capability — the cubic Lorenz-96 dynamics protect the
  unforced terms but not the sensor coupling layer. The
  current implementation's security claim is conditional on
  the adversary not accurately modeling the sensor interface.
  See `synthesis_team_round2_companion.md` §1C-A6 / §1D-iv;
  V-013 in attack_surface_enumeration.md. State-dependent
  coupling deferred as a future architectural enhancement.

### LL-005 — sensor-Nyquist-condition
- Key: sensor sampling rate vs physical noise bandwidth
- Logic tier: Core
- Description: Sensor sampling rate `f_sensor` and SDE integration
  rate `f_SDE` must satisfy a Nyquist-like condition relative to
  the physical noise bandwidth of the underlying source: an
  adversary at sub-Nyquist sampling cannot reconstruct the genuine
  device's sensor stream, but a sufficiently fast adversary can.
  Formal requirement: `f_SDE > 2 × bandwidth ∧ f_sensor > bandwidth`.
  Per-sensor analysis distinguishes high-bandwidth-noise sensors
  (thermal, scheduler, governor — Nyquist binding) from
  discrete-state configuration sensors (USB, AC, battery — Nyquist
  trivially satisfied; security contribution via configuration
  discreteness, not bandwidth).
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.4, §3.6.
- Notes: Recommended starting points: f_SDE ≈ 10 kHz, sensor
  sampling at 10× sensor electronic bandwidth where supported.
  Concrete numerical calibration is P3 work.

---

## Detection / verification — open

### LL-006 — Lyapunov-spectrum-residue-audit
- Key: residue detection on Lyapunov spectrum, not scalar KL
- Logic tier: Core
- Description: Adversary-signature detection compares the *full
  Lyapunov spectrum* of the live trajectory against the registered
  hardware envelope, not a scalar KL divergence on raw trajectory.
  Spectrum comparison resists slow-drift threshold-gaming because
  an adversary can spoof location on the attractor more easily
  than they can spoof local stretching/folding rates across
  multiple timescales simultaneously. Test is *vector* per-exponent,
  not scalar: M̂ accepted iff |λ̂ᵢ - λᵢ_registered| < k·σᵢ for every i,
  where σᵢ is the per-exponent estimator standard deviation
  calibrated from n_trials registration runs. Detection-probability
  bound shape (manually argued, Lean target for P6):
  P(detect) ≥ 1 - K·exp(-c·T·δ_A²) where δ_A is adversary
  spectrum gap and T is observation window. Empirical
  detection-probability surface at N=20, n_trials=10, k=5: flat
  ≈ FPR (0.10) for ε_A ≤ 0.75; sigmoid transition through
  ε_A ∈ [0.75, 2.0]; saturated 1.00 for ε_A ≥ 2.0. Shape matches
  the bound; constants K, c, δ_A(ε_A) not yet derived.
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Audit.jl (Envelope, register_envelope,
  residue, verify, synthetic_adversary).
- Test: src/julia/test/runtests.jl (audit @testsets — 18
  assertions covering mechanism, register, self-acceptance,
  strong-adversary rejection); passes via Pkg.test().
- Benchmark: src/julia/benchmark/p3_bound_high_res.jl +
  src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt
  (high-resolution sweep, 11 ε_A points × 15 trials each).
  Fitted bound K=1, c′=0.00423, T=60 holds at all 10
  transition + saturation data points; one FPR-floor point
  (ε_A=0.50, empirical 0/15) is below bound by 0.062 but
  consistent with sampling variance (Wilson 95% CI
  [0, 0.215] covers bound prediction 0.061). Performance
  target: "fitted bound holds across the prototype's
  configuration" — met. See
  docs/p3_bound_companion.md §2 for the constrained-fit
  derivation. Earlier P3b benchmark
  (src/julia/benchmark/results/p3b_detection_lorenz96.txt)
  remains as the original :tested-tier evidence.
- Notes: Bound is vacuous as adversary precision ε_A → 0
  (honest resolution-bounded scoping). Mechanism upgraded from
  scalar to vector per-exponent test; SNR is much better than
  scalar — see docs/p3a_sensor_coupling_companion.md §2.4 for
  trajectory-vs-spectrum comparison. Calibration of the §2.1
  bound's constants (K, c, δ_A(ε_A) mapping) is the
  :benchmarked-upgrade follow-up. Structural-separation prior
  anchors on Closure v5 catlab_spec.jl Thm_Q51_autopoietic /
  Thm_Q102_structure (cross-sector autopoiesis fails 0/5202
  across 5 ICs at threshold 0.999) — see
  qkd_pqc_complementarity_companion.md §2.5.
- **Round-2 acknowledgment (2026-05-02):** The empirical
  detection-probability surface is an *optimistic* bound
  derived from an isotropic synthetic adversary. Real
  adversaries have structured perturbation directions
  (V-013); worst-case δ_A is bounded by the weakest-coupled
  direction, not the isotropic average. LL-021
  (worst-case-adversary-bound) supplies the corrected
  bound; the empirical curve here remains valid as a lower
  bound on detection difficulty.
- **Round-2 worst-case companion benchmark (0.0.15):** The
  empirical worst-case surface lives at
  `src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`
  with the analytic derivation in
  `docs/p_r2c_worst_case_adversary_companion.md` §2.1. For
  the prototype's two-channel coupling, the NARROW direction
  produces 0-20% detection across all tested magnitudes
  while the BROAD direction saturates at 100% by ε_A = 1.0.

### LL-007 — chaos-guard
- Key: real-time Lyapunov estimate; periodic windows reject entropy
- Logic tier: Operational
- Description: A background process estimates the largest
  Lyapunov exponent in real time using the Wolf single-trajectory
  algorithm (`DynamicalSystems.lyapunov`) — O(N) per step rather
  than O(N²) for full Benettin spectrum (~400× faster at N=40).
  If `λ̂₁ < τ_λ` (default 0.1·λ₁_expected ≈ 0.166), the entropy
  stream is marked INVALID immediately; `update!` returns the
  post-update state. Recovery requires `warmup_steps` consecutive
  samples ≥ recovery_threshold (default 5·τ_λ ≈ 0.83). Reseed
  perturbs the SDE state via TRNG-derived unit-vector × magnitude
  (default magnitude=1.0 ≈ attractor diameter); reset to WARMUP;
  `reseed_count` increments. Initial state is WARMUP not VALID
  (security primitive must not assume entropy is good before
  observation). Public predicate `is_valid` returns Bool only
  (LL-017 no-oracle).
- Evidence type: example-tested
- Status: :tested
- Source: src/julia/src/ChaosGuard.jl.
- Test: src/julia/test/runtests.jl (chaos-guard @testsets — 35
  assertions: state-machine logic with synthetic λ̂₁ sequences,
  Lorenz-96 chaotic vs sub-chaotic integration, reseed flow with
  exact magnitude verification). Passes via Pkg.test() in ~47s
  total wall clock.
- Notes: Decoupling from visual layer (LL-002) preserved — the
  guard module has no visual-layer references; reseed events are
  internal to the security primitive. Cost analysis: Wolf method
  ~1.3 ms per call vs Benettin ~507 ms; suitable for always-on
  ambient monitoring at sub-1% CPU. Concrete λ₁_expected for the
  chosen SDE is set per-deployment; the prototype uses 1.66 from
  the Lorenz-96 N=40, F=8 baseline.
- **Round-2 timing-channel concern (2026-05-02):** Reseed
  events and state transitions are *observable as timing
  channels* if the verifier emits WARMUP responses
  distinguishably from VALID/REJECT. LL-019 (side-channel
  hardening) is the corrective requirement — production
  deployments must use constant-time response or
  randomised-delay protocol around state transitions.
  Without LL-019, V-011 (Reseed Oracle) gives an A4/A5
  adversary a sensor-correlated event channel.

### LL-008 — resolution-bounded-security
- Key: S_production > S_measurement
- Logic tier: Core
- Description: LavaLamp's security claim is **resolution-bounded**:
  secure against any adversary whose measurement and compute
  resolution is exceeded by the device's chaos-production rate.
  S_production = h_KS(M) = Σ_i max(λᵢ, 0) (Pesin's formula on the
  ergodic component); S_measurement = h_meas(A; M) is A's
  information-absorption rate from substrate observations. The
  bound S_production > S_measurement + log(1/η)/Δt yields
  residual-uncertainty growth Δh·Δt - O(1) and the §2.1 detection
  bound P(detect) ≥ 1 - K·exp(-c·T·δ_A²). Per-class adversary
  quantification is split out as LL-018.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.2, §3.2.
- Notes: NOT information-theoretically secure. NOT a no-cloning-
  theorem inheritance. Computational unclonability via measurement-
  symmetry breaking. Honest tier framing per CLAUDE.md. Lean
  theorem shape pinned in §2.2 of the design companion; P6 work.

---

## Boundary constraints — open

### LL-009 — no-complex-numbers
- Key: security-critical math stays real-valued
- Logic tier: Boundary
- Description: The security primitive (SDE, sensor coupling,
  residue audit) uses only real-valued mathematics. Complex
  numbers are forbidden in any code path that contributes to
  identity / verification. The visual skin (decorative only) is
  not bound by this constraint, but its outputs do not feed the
  security primitive (per LL-002).
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §3 — boundary
  preserved by Float64 type choice across the Julia prototype:
  state vectors, coupling vectors, sensor stream values,
  Lyapunov spectrum estimates, envelope values, and residue
  audit per-component test all use Float64. Round-1's SGL
  complex-valued slip was rejected; the boundary held through
  P3 implementation. Originating corpus boundary: Aaron
  2026-04-29 Gemini conversation; reaffirmed across engine
  and RMR work.
- Notes: :tested upgrade requires either (a) static analysis
  asserting no Complex types touch security paths, or (b)
  Lean / type-level proof. Both deferred.

### LL-010 — no-open-ended-simulation
- Key: bounded-time / finite-state SDE only; no continuum-limit dynamics
- Logic tier: Boundary
- Description: LavaLamp solves a *bounded-time* SDE on a *finite*
  state. The system explicitly does not run continuum-limit /
  hypergraph-rewriting / autopoietic dynamics. Trajectories are
  analyzed in bounded windows; no open-ended simulation regime.
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §4 — boundary
  preserved by parameter and system class: every SDE
  integration takes explicit bounded N (Benettin steps) and
  Δt; trajectories analysed over bounded windows; finite-
  dimensional Lorenz-96 N=20-40 (not hypergraph-rewriting,
  not continuum-limit); no autopoietic dynamics in the SDE
  itself. The Closure v5 corpus' Q₁₀₂ autopoietic structure
  is the *target of analysis* per
  qkd_pqc_complementarity_companion.md §2.5, not the
  *physical instantiation* — explicitly out of scope here.
  Originating corpus boundary: Aaron 2026-04-29 Grok
  conversation re Q102 / continuum limit / self-reproducing
  structure.
- Notes: :tested upgrade requires either Lean enforcement of
  bounded-T integration calls, or runtime guard. Both deferred.

---

## Open protocol questions — pending design

### LL-011 — registration-ceremony
- Key: how a verifier learns a device's hardware fingerprint envelope
- Logic tier: Operational
- Description: Trust-root protocol for the verifier acquiring a
  device's registered Lyapunov-spectrum envelope. Default
  recommendation: TPM / Secure Enclave attestation (B) +
  device-derived secret mixing (D) for hardware-rooted
  deployments; multi-party registration (A, threshold scheme) when
  no hardware root is available; time-bounded re-registration (C)
  as defense-in-depth. Defeats single-A5 adversaries; A5 hardware-
  tamper still possible but moved down-stack.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.1, §3.8.
- Notes: Concrete protocol implementation (Julia client +
  Haskell verifier-side spec) is P3+P4 work.
- **Round-2 confidentiality requirement (2026-05-02):** The
  TPM attestation defence in this entry prevents envelope
  *substitution* but does not prevent envelope *observation*.
  V-012 (Calibration Spectrum Leakage) gives a registration-
  channel observer the full registered envelope. LL-020
  (calibration-confidentiality) is the complementary
  requirement: registered envelope must be sealed against
  observers via TPM-sealed storage, ε-DP perturbation of
  any published statistics, or multi-party threshold scheme.
  Both LL-011 and LL-020 are required for production.

### LL-012 — cold-start-window
- Key: behavior of just-booted device before trajectory has converged
- Logic tier: Operational
- Description: Just-booted device must distinguish three states to
  the verifier: WARMUP (SDE has not converged; "retry in
  T_remaining" reported via chaos-guard's λ̂₁ trace, signed by
  device identity key), OPERATIONAL (steady state; ACCEPT/REJECT),
  DEGRADED (chaos-guard rejection in flight; same response as
  WARMUP). Default: single-envelope registration (steady state
  only), unauthenticated during warmup; dual-envelope (cold-start
  + steady-state) reserved for high-availability deployments.
  Early-boot integrity (Secure Boot, measured boot, cold-boot RAM)
  is OS-level concern explicitly out of scope.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.2, §3.8.

### LL-013 — cross-config-transition-handling
- Key: distinguishing legitimate config change from adversarial spoofing
- Logic tier: Operational
- Description: Per-config registered envelopes (PRE): registration
  captures envelopes for all expected configurations
  (USB/AC/peripheral combinations). Verifier receives candidate
  trajectory + sensor-authentic configuration claim (LL-016) and
  selects matching envelope. Brief TRANSITIONING window
  (~τ_config) during equilibration of the smoothed potential
  field. Unknown configurations rejected with
  UNKNOWN_CONFIGURATION; re-registration required. Transition-
  pattern fingerprint deferred as future hardening.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.3, §3.8.
- Notes: Inherits V-006 risk via dependency on LL-016 sensor
  authenticity.

### LL-014 — adversary-signature-threshold-calibration
- Key: false-positive vs false-negative tradeoff in residue threshold
- Logic tier: Operational
- Description: Calibration *discipline* for the residue threshold
  τ. (1) τ is vector-valued per exponent, not scalar (defeats
  V-005 slow-drift). (2) Per-exponent threshold τᵢ baseline
  τᵢ = 3·σ(λ̂ᵢ | T). (3) No-oracle verification protocol
  (LL-017) prevents threshold-probing. (4) Rate limiting on
  verification attempts (10/min/source, 100/hour/device) hardens
  further. (5) Adaptive thresholding learning from genuine-device
  history is recommended future hardening; round-1 production uses
  fixed τ.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.5, §3.8.
- Notes: Concrete numerical τᵢ values depend on the chosen SDE
  family / parameters / estimator and are produced by P3
  benchmarks against estimator variance at the chosen window
  length.
- **Round-2 promotion (2026-05-02):** Adaptive thresholding
  (history-aware τ that learns from genuine-device traces)
  is now *load-bearing for multi-tenant deployments*, not
  optional hardening. The prototype's 10% baseline FPR at
  k=5 / n_trials=10 is operationally a denial-of-service
  vector at scale; tightening requires more trials, a chi-
  squared aggregate test, or adaptive-threshold history.
  See `synthesis_team_round2_companion.md` §1C-A5.

---

## Surfaced by attack-surface enumeration (0.0.3)

### LL-015 — adversary-class-A3-out-of-scope
- Key: kernel-level (A3) adversaries explicitly not defended against
- Logic tier: Boundary
- Description: LavaLamp does *not* claim defense against
  adversaries with kernel-level (root) execution on the device.
  At that capability level the device's identity is irrelevant —
  the attacker can simulate any trajectory directly. Honest
  scoping. The architecture defends against adversary classes
  A1 (remote software), A2 (unprivileged user-space software),
  A4 (side-channel / physical proximity), A5 (registration-time
  insider), and A6 (time-localized observer); A3 is explicitly
  out of scope.
- Evidence type: none
- Status: :open
- Source: `docs/attack_surface_enumeration.md` §2 (adversary
  taxonomy) + §5 (residual risks).
- Notes: This is a honest-scoping claim parallel to LL-009 (no
  complex numbers in security math) and LL-010 (no open-ended
  simulation). Documenting the boundary prevents drift toward
  overclaiming; consumers of the spec must understand which
  adversary capabilities LavaLamp covers.

### LL-016 — sensor-authenticity-requirement
- Key: sensor reads used in the security primitive require independent authenticity check
- Logic tier: Core
- Description: Hardware sensor reads (battery, AC adapter, USB
  status, thermal, scheduler timing) participating in the
  external-potential-field coupling (LL-004) must satisfy an
  independent authenticity check beyond simply trusting the
  reported value. Sensors can be manipulated at the source
  (V-006: a hairdryer drives thermal up; a flashed USB device
  reports plug-events without attaching; a charge controller
  spoofs AC-adapter status). Authenticity strategies in
  decreasing strength: (1) hardware attestation (TPM / Secure
  Enclave-signed reads); (2) multi-sensor cross-validation
  (correlated readings sanity-checked — thermal + battery
  discharge rate; AC + measured current draw; mic + accelerometer);
  (3) anomaly-based flagging (sensor reads outside plausible joint
  envelopes excluded from U(s) participation); (4) accepted
  residual risk with explicit deployment-context guidance.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.4, §3.7;
  docs/attack_surface_enumeration.md §3 V-006.
- Notes: Default strategy for the prototype is (2) + (3); (1)
  added when deployment supports it; (4) as fallback with
  documented deployment context. Largest residual risk in the
  architecture.

### LL-017 — verification-no-oracle
- Key: verification protocol must not expose accept/reject feedback usable for threshold probing
- Logic tier: Core
- Description: The verification protocol returns exactly one of
  ACCEPT, REJECT, WARMUP, TRANSITIONING, UNKNOWN_CONFIGURATION,
  RATE_LIMITED — no divergence value, no per-exponent residual,
  no distance-to-threshold, no time-to-detection. Rate-limit
  policy: 10 attempts per minute per (device, source); 100 per
  hour per device-identity across sources. Verifier logs all
  attempts internally for calibration discipline (LL-014) and
  forensics; logs are never exposed to the requester.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.4, §3.8;
  docs/attack_surface_enumeration.md §3 V-010.
- Notes: Adaptive thresholding (threshold learning from genuine-
  device history) is recommended future hardening; round-1 uses
  fixed τ.

---

## Surfaced by P2 architectural design pass (0.0.5)

### LL-018 — adversary-resolution-bound-formalisation
- Key: per-class A1..A6 quantification of LL-008's resolution margin
- Logic tier: Core
- Description: Formal statement of the resolution-bounded
  security bound across the six adversary classes from
  attack-surface §2. (A1 remote software: h_meas ≈ 0; arbitrary
  margin.) (A2 local unprivileged: bounded by user-space-
  observable timing/API resolution ~10⁻⁶ s; comfortable margin.)
  (A3 kernel-level: out of scope per LL-015; bound does not
  hold and is not claimed.) (A4 side-channel / physical proximity:
  load-bearing class; margin holds when adversary measurement
  bandwidth is sub-Nyquist relative to substrate per LL-005;
  LL-016 sensor authenticity is the load-bearing assumption.)
  (A5 registration-time: addressed by LL-011 protocol, not by
  the resolution bound directly.) (A6 time-localized: bounded by
  single-window observation; addressed by LL-012 cold-start
  protocol.) Prevents the "claim shrinks under reading" failure
  mode where readers project an unconditional bound.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.2, §3.3;
  docs/attack_surface_enumeration.md §2.
- Notes: Per-deployment threat model must specify which A4
  capability level is assumed. The bound is parametric on this;
  it is not a single number. Lean theorem shape (parametric in
  δ_A and T) pinned in §2.2 of the design companion; P6 work.

---

## Surfaced by synthesis-team round 2 (0.0.12)

### LL-019 — side-channel-hardening
- Key: chaos-guard state transitions and audit cadence must not leak timing/correlation oracles
- Logic tier: Core
- Description: The chaos-guard (LL-007) state-transition
  responses (WARMUP / INVALID / VALID) must be emitted with
  *constant-time* or *randomised-delay* envelope so that an
  external observer cannot distinguish reseed events from
  legitimate verification load. Reseed triggers are sensor-
  correlated; observable reseed timing is a sensor-event
  oracle for an A4/A5 adversary (V-011). Additionally: the
  full Benettin spectrum audit (LL-006) MUST run on every
  verification request — the chaos-guard's cheap Wolf-method
  λ₁ alone is insufficient because adversaries can craft
  trajectories that match λ₁ but diverge in higher exponents
  (A4 finding from round 2). The Wolf-method guard remains
  the always-on monitor; the Benettin audit on every
  verification closes the inter-audit window. Prototype
  implementation: `verify_full(ds, env; ...)` forces full
  Benettin at the API level (audit-on-every-verify);
  `verify_constant_time(λs, env; target_seconds)` pads
  response time to a uniform target (timing decorrelation).
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Audit.jl (verify_full,
  verify_constant_time).
- Test: src/julia/test/runtests.jl LL-019 @testsets (12
  assertions: verify_full forces Benettin + result equality
  with manual lyapunov_spectrum + verify; strong adversary
  reject; verify_constant_time elapsed ≥ target_seconds;
  result equality with plain verify; Bool-only return;
  argument validation).
- Benchmark:
  src/julia/benchmark/ll019_timing_distribution.jl +
  src/julia/benchmark/results/ll019_timing_distribution.txt
  + docs/ll019_benchmarked_companion.md (two-sample KS test
  on 400 timed verify_constant_time calls bucketed by
  verify result; KS_stat=0.109 < critical=0.170 at α=0.05
  → fail to reject H0 → distributions statistically
  indistinguishable). Performance target: "verify_constant_time
  produces a response-time distribution where accept-bucket
  and reject-bucket are statistically indistinguishable per
  a two-sample KS test at α=0.05" — met.
- Notes: Plain verify also passes the KS test (KS_stat=0.041)
  at the prototype's scale because the data-dependent timing
  channel is sub-microsecond, below OS scheduling jitter.
  At production scale (millisecond-scale data-dependent
  paths) the channel emerges; verify_constant_time is the
  operationally-meaningful defence. Production constant-
  time-response should use an async deadline scheduler
  rather than sleep (which blocks a worker thread); the
  prototype's sleep demonstrates the property at the
  benchmark level. Lean target per round-2 §1D.v: side-
  channel timing indistinguishability theorem; this
  benchmark grounds its theorem statement (see
  docs/ll019_benchmarked_companion.md §3.3).

### LL-020 — calibration-confidentiality
- Key: registered envelope sealed against registration-channel observers, not just substitution
- Logic tier: Core
- Description: The registration ceremony (LL-011) calibrates
  the device's envelope by exposing n_trials Lyapunov-spectrum
  estimates plus per-exponent σ on the registration channel.
  TPM attestation in LL-011 defends *substitution* but not
  *observation* — an A5 adversary present during registration
  captures the registered envelope to machine precision and
  can craft trajectories that lie just inside the rejection
  ball, defeating LL-006 + LL-017 by knowing the threshold
  geometry exactly (V-012). LL-020 requires that the
  registered envelope and per-exponent σ be sealed against
  observers via three layered strategies (P-R2b design):
  (1) TPM-sealed storage on the verifier — primary default
  for hardware-rooted deployments; (2) ε-differentially-
  private perturbation of any published envelope statistics
  — universal fallback when hardware support is absent or
  publication is required; (3) Shamir-style multi-party
  threshold scheme on envelope reconstruction — primary
  default for federated / multi-trust-root deployments.
- Evidence type: manual
- Status: :argued
- Source: docs/p_r2b_calibration_confidentiality_companion.md
  §2 (three-strategy design space + recommended default
  layering by deployment context); §2.6 (Lean theorem shapes
  per round-2 §1D.v priority 3). Originating attack vector:
  docs/attack_surface_enumeration.md V-012 +
  docs/synthesis_team_round2_companion.md §1C-A2.
- Notes: LL-011 (registration ceremony) defends substitution;
  LL-020 defends observation; both are required for
  production. LL-017 (verification no-oracle) defends
  accept/reject probing; the three together close the
  threshold-geometry leakage path. Implementation is
  platform-coupled (TPM/Secure Enclave/TrustZone) or
  cryptographic-library-coupled (Shamir / DP libraries)
  and sits outside the Julia-prototype scope per the
  language-tier discipline; ε-DP envelope stub is plausible
  as a pure-Julia follow-up (would upgrade Strategy 2 to
  :tested).

### LL-021 — worst-case-adversary-bound
- Key: detection-probability claim stated against worst-case adversary direction, not isotropic
- Logic tier: Core
- Description: The LL-006 detection-probability bound shape
  P(detect) ≥ 1 - K·exp(-c·T·δ_A²) must use the *worst-case*
  spectrum gap δ_A_worst — the minimum over all admissible
  adversary directions in α-space — rather than the isotropic-
  average. LL-021 derives the worst-case direction analytically
  (the û orthogonal to the mean-coupling vector
  m = (mean(b_1), …, mean(b_n)), reducing δ_A by a factor
  set by the coupling matrix's condition number) and
  demonstrates the asymmetry empirically via the structured-
  adversary benchmark. For the prototype's two-channel system
  with b_1 = e_1 (narrow) vs b_2 = ones(N) (broad), the
  worst-case (NARROW direction) detection probability is at
  the FPR baseline across ε_A ∈ {0.5, 1.0, 2.0, 4.0} while
  the best-case (BROAD direction) saturates at 1.00 for
  ε_A ≥ 1.0 — the empirical asymmetry is essentially
  unbounded at this configuration's calibration noise floor.
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Audit.jl synthetic_adversary
  (direction parameter supports explicit û).
- Test: src/julia/benchmark/p_r2c_structured_adversary.jl +
  src/julia/benchmark/results/p_r2c_structured_lorenz96.txt
  (committed empirical surface; 12 data points across 3
  directions × 4 magnitudes × 5 trials at N=20, k=5,
  verify_full audit-on-every-verify).
- Benchmark: docs/ll021_benchmarked_companion.md §2 — fitted
  worst-case constants K=1, c′=0.02777, T=60 (parameterised
  on ε_eff = ε_A · proj(û onto m_unit) where m is the
  mean-coupling vector). Bound holds at 9 of 12 data
  points pointwise; the 3 with negative margin have Wilson
  95% CIs covering the bound prediction (sampling-variance
  consistent at n=5). c′_worst = 0.02777 is 6.6× larger
  than c′_isotropic = 0.00423 from P3-bound (LL-006);
  the two bounds describe the same shape under different
  parameterisations. Performance target: "fitted worst-case
  bound holds across the prototype's structured-adversary
  surface" — met within sampling-variance bounds.
- Notes: Production deployments have three options for
  reducing worst-case under-estimation: (1) choose coupling
  vectors with uniform support (reduces condition number);
  (2) increase n (more channels) so the orthogonal-to-mean-
  coupling subspace is high-dimensional and adversaries
  cannot easily place ε in it; (3) accept the bound and
  document the deployment-context-bounded weakness. The
  prototype lands option 3 with documented benchmark.
  :benchmarked upgrade (calibrating K, c constants against
  the empirical worst-case curve) and Lean theorem (round-2
  §1D.v priority 1) are P5/P6 followups. See
  docs/p_r2c_worst_case_adversary_companion.md.

---

## Counts (must match `artifact_registry.md` and `dashboard.md`)

- Total: 21
- `:proved`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:verified`: 0
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 14 (LL-001, LL-002, LL-005, LL-008, LL-009,
  LL-010, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017,
  LL-018, LL-020)
- `:open`: 1 (LL-015 — A3-OOS scoping declaration; permanent
  by design)

**Prototype-stage; spec essentially fully argued. Three
empirically-validated :benchmarked entries (LL-006 detection
bound, LL-021 worst-case bound, LL-019 timing-
indistinguishability); three :tested entries (LL-003 baseline,
LL-004 sensor coupling, LL-007 chaos-guard); fourteen
:argued at design level; only LL-015 remains :open as the
honest scoping declaration that A3 (kernel-level) adversaries
are out of scope. The closure pass at 0.0.20 elevated
LL-001/002/009/010 from :open to :argued based on evidence
already accumulated across earlier sessions.**
