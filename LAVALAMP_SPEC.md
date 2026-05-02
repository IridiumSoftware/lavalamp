# LAVALAMP_SPEC.md — LavaLamp

Version: 0.0.6 (P3 prototype core — Lorenz-96 baseline, 2026-05-02)
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
- Evidence type: none
- Status: :open
- Source: TBD (formal Lean / Haskell impl pending attack-surface
  enumeration).

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
- Evidence type: none
- Status: :open
- Notes: This is a load-bearing architectural invariant. If the
  visual ever gets re-coupled to the security primitive, the
  basin-spoofing attack surface returns (multi-basin reaction-
  diffusion regimes the visual layer would want to use are
  precisely where the adversary can hide a spoof inside scalar-KL
  threshold).

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
  adversary could detect and resync against.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.4, §3.5.
- Notes: Implementation must respect Nyquist condition (LL-005).
  Concrete potential-field shape U(s, x; t) is P3 work.

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
  not scalar: M̂ accepted iff |λ̂ᵢ - λᵢ_registered| < τᵢ for every i.
  Detection-probability bound (manually argued, Lean target for
  P6): P(detect) ≥ 1 - K·exp(-c·T·δ_A²) where δ_A is adversary
  spectrum gap and T is observation window.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.1, §3.1.
  Structural-separation prior anchors on Closure v5
  catlab_spec.jl Thm_Q51_autopoietic / Thm_Q102_structure
  (cross-sector autopoiesis fails 0/5202 across 5 ICs at
  threshold 0.999) — see qkd_pqc_complementarity_companion.md
  §2.5.
- Notes: Bound is vacuous as adversary precision ε_A → 0 (honest
  resolution-bounded scoping). Concrete τᵢ values, estimator
  selection (Wolf vs Benettin vs Rosenstein), and numerical
  benchmarks are P3 work.

### LL-007 — chaos-guard
- Key: real-time Lyapunov estimate; periodic windows reject entropy
- Logic tier: Operational
- Description: A background thread estimates the largest Lyapunov
  exponent in real time (Benettin recommended; Rosenstein / Wolf
  alternatives). If `λ̂₁ < τ_λ ≈ 0.1·λ₁_expected` over a sliding
  window W ≈ 100/λ₁_expected, the entropy stream is marked
  INVALID, the SDE state is perturbed by ~1× attractor diameter
  via host TRNG (`/dev/urandom`, `getrandom(2)`, `RDRAND`), and a
  warmup of duration 2W must elapse with λ̂₁ above 5·τ_λ before
  entropy is re-marked VALID. Reseed events are logged. Turns
  periodic-window failure mode into a safety signal rather than a
  vulnerability.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.3, §3.4.
- Notes: Decoupling from visual layer (LL-002) preserved — the
  visual continues animating from its independent RNG during
  reseed events. Concrete λ₁_expected for the chosen SDE,
  reseed-magnitude calibration, and warmup tuning are P3 work.

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
- Evidence type: none
- Status: :open
- Source: Corpus-wide discipline boundary (Aaron, 2026-04-29
  Gemini conversation; reaffirmed across engine and RMR work).

### LL-010 — no-open-ended-simulation
- Key: bounded-time / finite-state SDE only; no continuum-limit dynamics
- Logic tier: Boundary
- Description: LavaLamp solves a *bounded-time* SDE on a *finite*
  state. The system explicitly does not run continuum-limit /
  hypergraph-rewriting / autopoietic dynamics. Trajectories are
  analyzed in bounded windows; no open-ended simulation regime.
- Evidence type: none
- Status: :open
- Source: Corpus-wide safety boundary (Aaron, 2026-04-29 Grok
  conversation re Q102 / continuum limit / self-reproducing
  structure).

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

## Counts (must match `artifact_registry.md` and `dashboard.md`)

- Total: 18
- `:proved`: 0
- `:tested`: 1 (LL-003)
- `:verified`: 0
- `:benchmarked`: 0
- `:argued`: 12 (LL-004, LL-005, LL-006, LL-007, LL-008,
  LL-011, LL-012, LL-013, LL-014, LL-016, LL-017, LL-018)
- `:open`: 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

**Prototype-stage. Lorenz-96 baseline (LL-003) example-tested
against literature; 12 entries argued at design level; 5 remain
open: LL-001/002 await Lean / type-level enforcement (P5/P6);
LL-009/010/015 are corpus-boundary declarations that close to
:argued under future small-session companions.**
