# Dashboard — LavaLamp

Last updated: 2026-04-30 (initial commit).

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

P1 — **Attack-surface enumeration document.** The synthesis team
  named five attack vectors (good-enough trajectory, basin
  spoofing — now resolved by LL-002, side-channel timing replay,
  sensor Nyquist failure, slow-drift threshold gaming). Plus
  protocol-level open questions (registration, cold-start,
  cross-config transitions, threshold calibration). All need to
  be written out as a formal threat tree with adversary
  capabilities and architectural defense traced for each. This
  document also doubles as the load-bearing technical content of
  the eventual LavaLamp paper.

P2 — **Architectural design pass.** Formalise:
  - Lyapunov-spectrum residue audit (probabilistic detection
    bound).
  - Resolution-Bounded Security claim (Lean-tractable
    formulation).
  - Chaos-Guard implementation specifics.
  - Sensor-coupling potential field (which sensors, how mapped to
    SDE parameters, sampling rate vs Nyquist).
  - Registration / onboarding / cold-start protocols.

P3 — **Language-track infrastructure.** Mirror the
  triadic-coordination-engine pattern: Haskell core + Lean 4
  formalisation (with optional Mathlib cross-validation). Lockfile
  discipline from day 1. No code shipped before P1 + P2 land.

P4 — **Visual-skin scaffolding.** Decorative-only animation. Can
  be canned / `Math.random()`-driven / Cloudflare-style RNG-blob.
  Decoupled from security primitive per LL-002. Low priority.

## Spec status (per LAVALAMP_SPEC.md)

- Total spec entries: 14
- `:proved`: 0
- `:tested`: 0
- `:verified`: 0
- `:benchmarked`: 0
- `:open`: 14
- `:argued`: 0

All entries `:open`. Concept-stage.

## Open structural questions

The four `:open`-protocol-level entries (LL-011 through LL-014)
that block any production deployment:

- **Registration ceremony.** How does verifier acquire device's
  registered Lyapunov-spectrum envelope without holding the
  device?
- **Cold-start window.** Just-booted device behavior before SDE
  has converged. Is the device unauthenticated during warmup?
- **Cross-config transitions.** Distinguishing legitimate USB-plug
  (or AC adapter, or thermal) shift from adversarial spoofing
  attempt at the verifier.
- **Threshold calibration.** False-positive vs false-negative
  tradeoff in the Lyapunov-spectrum divergence threshold.

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

## Recent companion docs

- `docs/concept_origin_companion.md` — provenance graph (codetaur
  visual seed, Aaron concept derived from Possibilistic Security,
  Brian ORSIΩ-vocabulary engagement, patent-offer-to-codetaur).
- `docs/synthesis_team_round1_companion.md` — full dialogue arc:
  Gemini synthesis 1, Grok edge-witness 1, Gemini rebuttal +
  premature skeleton, Grok edge-witness 2 on visual-richness
  blindspot, Aaron's decoupling resolution.

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
