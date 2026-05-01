# Dashboard — LavaLamp

Last updated: 2026-05-01 (0.0.3 — attack-surface enumeration).

## Status summary

**Project state.** Concept-stage. Architecture has been
synthesized through one round of synthesis-seat (Gemini) +
edge-witness-seat (Grok) review on 2026-04-30. No code yet.

**Key architectural moves locked.**

- **Substrate-Bound Identity** as the canonical positioning. Not
  QKD-grade no-cloning inheritance; computational unclonability
  via measurement-symmetry breaking (PUF at device-universe scale).
- **Resolution-Bounded Security** as the formal claim:
  `S_production > S_measurement`. Quantum-grounded only when raw
  TRNG access is available; otherwise substrate-coupling residue
  carries the load.
- **Visual ↔ security decoupling** as a load-bearing
  architectural invariant. Lava-lamp visual is decorative;
  security primitive runs independently. Same shape as Lazarus.
  This decoupling resolves the visual-richness ↔ security
  tension that round-1 synthesis-team review identified as the
  key blindspot.
- **Single-attractor chaotic SDE** as the security-primitive
  engine candidate (Lorenz-96 leading; Lorenz / Rössler also
  viable). Multi-basin reaction-diffusion (Gray-Scott /
  Stochastic Ginzburg-Landau) explicitly rejected — they were
  rejected for visual richness, but rejection sticks because LL-002
  removes the constraint that pulled toward them in the first
  place.
- **Multi-Scale Lyapunov Divergence Audit** for
  adversary-signature residue detection (not scalar KL — counters
  slow-drift threshold-gaming).
- **Chaos-Guard** as periodic-window safety signal: real-time
  largest-Lyapunov estimate; if `λ_max ≈ 0`, reject entropy and
  reseed.
- **Continuous sensor coupling via external potential field** (no
  discrete parameter kicks; respects Nyquist condition vs physical
  noise bandwidth).

## Priority stack

P1 — **Attack-surface enumeration document.** ✓ Landed in 0.0.3
  (`docs/attack_surface_enumeration.md`). Six adversary classes
  (A1 remote, A2 unprivileged, A3 root [out of scope per
  LL-015], A4 side-channel, A5 registration-time, A6 time-
  localized). Ten attack vectors enumerated (V-001 "good
  enough" trajectory, V-002 basin-spoofing [closed by LL-002],
  V-003 quantum-seed → classical boundary, V-004 sensor Nyquist,
  V-005 slow-drift threshold gaming, V-006 sensor-input
  poisoning, V-007 registration ceremony, V-008 cold-start
  window, V-009 cross-config transition, V-010 threshold
  calibration gaming). Each has adversary class / mechanism /
  defenses (LL-IDs) / residual risk / mitigation pending.
  Document doubles as load-bearing technical content of the
  eventual LavaLamp paper.

P2 — **Architectural design pass.** Formalise:
  - Lyapunov-spectrum residue audit (probabilistic detection
    bound).
  - Resolution-Bounded Security claim (Lean-tractable
    formulation).
  - Chaos-Guard implementation specifics.
  - Sensor-coupling potential field (which sensors, how mapped to
    SDE parameters, sampling rate vs Nyquist).
  - Registration / onboarding / cold-start protocols.

P3 — **Julia prototype core.** Implement the architecture (LL-001
  through LL-008 substantively) using Julia's chaos-and-SDE stack:
  `DifferentialEquations.jl` for the SDE solver,
  `DynamicalSystems.jl` / `ChaosTools.jl` for Lyapunov-spectrum
  estimation and basin diagnostics, native sensor FFI for
  configuration coupling. Lockfile discipline (`Manifest.toml`)
  from day 1. No code shipped before P1 + P2 land.

P4 — **Haskell compositional-completeness layer.** Spec-as-types
  + QuickCheck against the Julia prototype. Catches corollaries
  and universals the example-tested suite would miss. Haskell's
  job is *composition-space coverage*, not implementation —
  prevents an unspotted universal sailing into Lean / production.
  Same discipline that caught S-026 in the triadic-coordination-
  engine.

P5 — **Lean 4 formal verification.** Machine-verify the structural
  security claims (resolution-bounded unclonability theorem,
  ergodicity-assumption discipline, detection-probability bound).
  Lean track only justified once Haskell has closed compositional
  completeness against the Julia prototype.

P6 — **C/C++ production hardening.** Rewrite from the proven spec,
  not from the exploratory code. Reach only after P3–P5 close.

P7 — **Visual-skin scaffolding.** Decorative-only animation. Can
  be canned / `Math.random()`-driven / Cloudflare-style RNG-blob.
  Decoupled from security primitive per LL-002. Low priority,
  can land any time.

## Spec status (per LAVALAMP_SPEC.md)

- Total spec entries: 17 (was 14 in 0.0.2; +3 from attack-surface
  enumeration: LL-015 A3-out-of-scope, LL-016 sensor-authenticity,
  LL-017 verification-no-oracle)
- `:proved`: 0
- `:tested`: 0
- `:verified`: 0
- `:benchmarked`: 0
- `:open`: 17
- `:argued`: 0

All entries `:open`. Concept-stage.

## Open structural questions

The four `:open`-protocol-level entries from 0.0.1 (LL-011..LL-014)
plus the three surfaced by 0.0.3 attack-surface enumeration
(LL-015..LL-017) that block any production deployment:

- **Registration ceremony** (LL-011). How does verifier acquire
  device's registered Lyapunov-spectrum envelope without holding
  the device? Trust-root attack surface (V-007).
- **Cold-start window** (LL-012). Just-booted device behavior
  before SDE has converged. Authentication during warmup
  (V-008).
- **Cross-config transitions** (LL-013). Distinguishing
  legitimate USB-plug (or AC adapter, or thermal) shift from
  adversarial spoofing attempt at the verifier (V-009).
- **Threshold calibration** (LL-014). False-positive vs
  false-negative tradeoff in the Lyapunov-spectrum divergence
  threshold (V-010).
- **Sensor authenticity** (LL-016). The largest residual risk:
  hardware sensors can be manipulated at the source (V-006).
  Solution requires multi-sensor cross-validation, hardware
  attestation, or accepted-deployment-context risk.
- **Verification no-oracle** (LL-017). Verification protocol
  must not expose accept/reject feedback usable for threshold
  probing.
- **A3 (root) explicitly out of scope** (LL-015). Honest scoping
  boundary; prevents drift toward overclaiming.

## Live discipline notes

- **Asymmetry-trap watch is engaged.** Visual ↔ security
  decoupling (LL-002) is precisely the kind of move that future
  "tidying" might re-couple for performance reasons. If that
  re-coupling is ever proposed, the basin-spoofing attack surface
  returns. Refactors in this area must be checked against
  load-bearing chirality.
- **No-complex-numbers boundary** (LL-009) is in force. The
  initial Gemini skeleton used Stochastic Ginzburg-Landau (complex-
  valued); that violated the boundary and was rejected in favor of
  staying real-valued. Future implementation work must be checked.
- **No open-ended simulation** (LL-010) is in force. Bounded-time
  windows only.

## Recent companion docs / formal artefacts

- `docs/concept_origin_companion.md` — provenance graph (codetaur
  visual seed, Aaron concept derived from Possibilistic Security,
  Brian ORSIΩ-vocabulary engagement, patent-offer-to-codetaur).
- `docs/synthesis_team_round1_companion.md` — full dialogue arc:
  Gemini synthesis 1, Grok edge-witness 1, Gemini rebuttal +
  premature skeleton, Grok edge-witness 2 on visual-richness
  blindspot, Aaron's decoupling resolution; §7 captures 0.0.2
  language-plan revision.
- **`docs/attack_surface_enumeration.md`** — formal threat tree.
  Adversary taxonomy (A1–A6, with A3 explicitly out of scope),
  attack vectors V-001..V-010, defenses by LL-ID, residual
  risks, spec-impact recommendations. Maintained artefact (not
  a session companion); will be updated as architecture evolves.

## Out of scope (explicit)

- Quantum hardware. LavaLamp is classical chaos with optional
  quantum-grounded TRNG seed; no photonic infrastructure.
- Information-theoretic security claims. Resolution-bounded
  computational tier only.
- Open-ended simulation regimes (per LL-010).
- Complex-valued security math (per LL-009).
- Visual richness as part of the security claim (per LL-002).
- Network protocol design (key distribution between distant
  parties — that's QKD's problem, LavaLamp does locally-bound
  device entropy).
