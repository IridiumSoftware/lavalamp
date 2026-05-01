# LAVALAMP_SPEC.md — LavaLamp

Version: 0.0.1 (concept-stage, 2026-04-30)
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
  that would have pulled toward multi-basin systems.
- Evidence type: none
- Status: :open
- Notes: Final SDE choice pending attack-surface enumeration and
  benchmark of Lyapunov exponent vs. compute cost. Lorenz-96 is the
  current candidate (high-dimensional, high Lyapunov, parameter-
  sensitive — good for hardware fingerprint amplification).

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
- Evidence type: none
- Status: :open
- Notes: Implementation must respect Nyquist condition (LL-005).

### LL-005 — sensor-Nyquist-condition
- Key: sensor sampling rate vs physical noise bandwidth
- Logic tier: Core
- Description: Sensor sampling rate `f_sensor` and SDE integration
  rate `f_SDE` must satisfy a Nyquist-like condition relative to
  the physical noise bandwidth of the underlying source: an
  adversary at sub-Nyquist sampling cannot reconstruct the genuine
  device's sensor stream, but a sufficiently fast adversary can.
  Formal requirement: `f_SDE > 2 × bandwidth ∧ f_sensor > bandwidth`.
- Evidence type: none
- Status: :open
- Notes: Concrete numbers pending hardware characterisation.

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
  multiple timescales simultaneously.
- Evidence type: none
- Status: :open
- Source: Gemini synthesis-rebuttal (2026-04-30) hardening of
  Grok's scalar-KL slow-poison attack.

### LL-007 — chaos-guard
- Key: real-time Lyapunov estimate; periodic windows reject entropy
- Logic tier: Operational
- Description: A background thread estimates the largest Lyapunov
  exponent in real time. If `λ_max ≈ 0` (the system has stalled
  into a periodic window), the entropy stream is rejected and the
  system kicks itself with a high-entropy seed to recover chaotic
  regime. Turns periodic-window failure mode into a safety signal
  rather than a vulnerability.
- Evidence type: none
- Status: :open

### LL-008 — resolution-bounded-security
- Key: S_production > S_measurement
- Logic tier: Core
- Description: LavaLamp's security claim is **resolution-bounded**:
  secure against any adversary whose measurement and compute
  resolution is exceeded by the device's chaos-production rate.
  Formally: for adversary A with measurement precision ε bounded
  by μ, the probability of A producing trajectory T' with
  Lyapunov-spectrum divergence below threshold is bounded above by
  `f(λ_min, μ, Δt, T)` for observation window T. Detection
  probability → 1 as T → ∞ under ergodicity assumptions on the
  attractor.
- Evidence type: none
- Status: :open
- Notes: NOT information-theoretically secure. NOT a no-cloning-
  theorem inheritance. Computational unclonability via measurement-
  symmetry breaking. Honest tier framing per CLAUDE.md.

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
- Status: :open
- Description: Pending. Onboarding protocol must address: how does
  a verifier acquire the registered Lyapunov-spectrum envelope of
  a device without ever physically holding it? What's the trust
  bootstrap?

### LL-012 — cold-start-window
- Key: behavior of just-booted device before trajectory has converged
- Logic tier: Operational
- Status: :open
- Description: Pending. A just-booted device hasn't run the SDE
  long enough to express its full hardware coupling. What's the
  warmup window? Is the device unauthenticated during warmup?

### LL-013 — cross-config-transition-handling
- Key: distinguishing legitimate config change from adversarial spoofing
- Logic tier: Operational
- Status: :open
- Description: Pending. When a USB is plugged in, the trajectory
  shifts. Verifier sees this shift. Is it a legitimate config
  change or an adversary's spoof attempt? Detection protocol must
  distinguish these.

### LL-014 — adversary-signature-threshold-calibration
- Key: false-positive vs false-negative tradeoff in residue threshold
- Logic tier: Operational
- Status: :open
- Description: Pending. The Lyapunov-spectrum divergence threshold
  for triggering "spoof detected" must be calibrated to balance
  false positives (genuine device variation reads as adversary)
  against false negatives (adversary stays under threshold).
  Calibration protocol pending.

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
  spoofs AC-adapter status). Without authenticity verification,
  an A4 adversary with physical proximity can drive the genuine
  device to produce a chosen trajectory ("spoofing without
  replication"). Authenticity strategy candidates:
  multi-sensor cross-validation (correlated readings sanity-
  checked against each other); hardware-attested sensors (TPM /
  Secure Enclave signatures over readings); accepted-residual-
  risk with explicit deployment-context guidance.
- Evidence type: none
- Status: :open
- Source: `docs/attack_surface_enumeration.md` §3 V-006
  (sensor-input poisoning).
- Notes: This is the largest residual risk in the current
  architecture. Sensor authenticity cannot be solved purely
  within the trajectory layer; it requires either additional
  hardware (attestation) or accepted-deployment-bound risk.

### LL-017 — verification-no-oracle
- Key: verification protocol must not expose accept/reject feedback usable for threshold probing
- Logic tier: Core
- Description: The verification protocol returning "accepted" or
  "rejected" for a submitted trajectory MUST NOT expose
  intermediate-state feedback (e.g., divergence value, distance-
  to-threshold, time-to-detection) that lets an adversary probe
  the residue threshold via repeated submissions. Without this
  no-oracle requirement, V-010 (threshold calibration gaming) is
  always possible: an adversary submits forged trajectories of
  varying parameters and uses accept/reject responses to
  triangulate the threshold's geometry. The verification
  protocol must be all-or-nothing on response.
- Evidence type: none
- Status: :open
- Source: `docs/attack_surface_enumeration.md` §3 V-010
  (threshold calibration gaming).
- Notes: A practical implementation may also include rate
  limiting on verification attempts and statistical bounds on
  repeated-submission patterns. Adaptive thresholding (where
  the threshold itself learns from history) is a stronger
  variant.

---

## Counts (must match `artifact_registry.md` and `dashboard.md`)

- Total: 17
- `:proved`: 0
- `:tested`: 0
- `:verified`: 0
- `:benchmarked`: 0
- `:open`: 17
- `:argued`: 0

**Concept-stage. Nothing verified. Attack-surface enumeration is
the next deliverable; spec entries get filled in (and new ones
added) as the architecture is hardened.**
