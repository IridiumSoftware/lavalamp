# Dashboard — LavaLamp

Last updated: 2026-05-02 (0.0.7 — P3 baseline companion + dev-host
field observations).

## Status summary

**Project state.** Prototype-stage. P2 architectural design pass
landed (`docs/architecture_design_companion.md`); P3 Julia
prototype core started (`src/julia/`) with Lorenz-96 (N=40, F=8)
baseline reproducing literature: λ₁ ≈ 1.66 (estimated 1.658 at
seed 42, 2000 Benettin steps), 14 positive exponents, h_KS ≈
10.27, Kaplan-Yorke dimension ≈ 27.1. LL-003 closes to `:tested`
with `example-tested` evidence. Twelve entries remain `:argued`
(P2 design); five remain `:open`. Test suite passes 8/8 in ~20s
via `Pkg.test()` from `src/julia/`.

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

P2 — **Architectural design pass.** ✓ Landed in 0.0.5
  (`docs/architecture_design_companion.md`). Five sub-items
  closed at design level (manual evidence, `:argued` status):
  - Lyapunov-spectrum residue audit (LL-006): vector
    per-exponent threshold; detection bound P(detect) ≥
    1 - K·exp(-c·T·δ_A²) with structural-separation prior from
    Closure v5 cross-sector autopoiesis 0/5202 result.
  - Resolution-Bounded Security claim (LL-008) + per-class
    A1..A6 quantification (new LL-018).
  - Chaos-Guard (LL-007): Benettin estimator over W ≈
    100/λ₁_expected; reseed via host TRNG on λ̂₁ < 0.1·λ₁_expected;
    2W warmup before re-mark VALID.
  - Sensor-coupling potential field (LL-004 / LL-005): smooth
    U(s, x; t) with ramped discrete-sensor smoothing and
    broadband-noise contribution; per-sensor Nyquist with f_SDE
    ≈ 10 kHz baseline; sensor authenticity (LL-016) via
    cross-validation + anomaly-flagging + TPM where available.
  - Protocol layer (LL-011 / LL-012 / LL-013 / LL-014 / LL-017):
    TPM+secret-mixing registration default; single-envelope
    WARMUP-state cold-start; per-config registered envelopes for
    cross-config transitions; vector + no-oracle + rate-limited
    threshold discipline.

P3 — **Julia prototype core.** ◐ In progress. Bootstrap +
  Lorenz-96 baseline landed in 0.0.6 (`src/julia/`); LL-003
  closes to `:tested` against literature (λ₁ ≈ 1.66, n_pos ≈ 14,
  h_KS ≈ 10.5). Remaining sub-items, in approximate order of
  dependence:
  - **P3a — Sensor coupling.** Implement the smooth potential
    field U(s, x; t) per design §2.4. Per-sensor Nyquist and
    bandwidth analysis. Closes LL-004 / LL-005 to `:tested` once
    the coupling is exercised end-to-end.
  - **P3b — Residue audit.** Implement the vector per-exponent
    threshold test from design §2.1, with synthetic adversary
    trajectories and detection-probability benchmark vs
    observation window T. Closes LL-006 to `:tested` /
    `:benchmarked`.
  - **P3c — Chaos-guard.** Real-time λ̂₁ estimator running
    concurrently; reseed-on-collapse protocol per design §2.3.
    Closes LL-007 to `:tested`.
  - **P3d — SDE-selection benchmark.** Comparative bench across
    Lorenz-96 / Lorenz-63 / Rössler on Lyapunov richness,
    parameter sensitivity, compute cost. Upgrades LL-003 to
    `:benchmarked` with the comparative artefact pinned in the
    registry.
  - **P3e — Non-degeneracy benchmark.** ∂λ/∂s rank check that
    the §2.1 detection bound's δ_A > 0 condition holds for the
    chosen coupling.

P4 — **Catlab categorical realisation** (optional, gated on P2).
  Use Julia + Catlab.jl / GATlab to verify the categorical
  structure of the verification protocol if P2's design pass
  surfaces enough categorical content to warrant it
  (registration ceremony LL-011, cross-config transitions
  LL-013, no-oracle response LL-017 — these are morphisms in
  a category of device-states with admissible transitions). The
  SDE / sensor-coupling primitive is dynamical-systems work and
  probably under-pulls Catlab's weight; the verification
  protocol may be different. **Decision rule:** skip by default;
  revisit when registration / cross-config transition designs
  are concrete. See `docs/language_plan_catlab_tier_companion.md`.

P5 — **Haskell compositional-completeness layer.** Spec-as-types
  + QuickCheck against the Julia prototype. Catches corollaries
  and universals the example-tested suite would miss. Haskell's
  job is *composition-space coverage*, not implementation —
  prevents an unspotted universal sailing into Lean / production.
  Same discipline that caught S-026 in the triadic-coordination-
  engine.

P6 — **Lean 4 formal verification.** Machine-verify the structural
  security claims (resolution-bounded unclonability theorem,
  ergodicity-assumption discipline, detection-probability bound).
  Lean track only justified once Haskell has closed compositional
  completeness against the Julia prototype.

P7 — **C/C++ production hardening.** Rewrite from the proven spec,
  not from the exploratory code. Reach only after P3–P6 close.

P8 — **Visual-skin scaffolding.** Decorative-only animation. Can
  be canned / `Math.random()`-driven / Cloudflare-style RNG-blob.
  Decoupled from security primitive per LL-002. Low priority,
  can land any time.

## Spec status (per LAVALAMP_SPEC.md)

- Total spec entries: 18 (no change in 0.0.6)
- `:proved`: 0
- `:tested`: 1 (LL-003 — Lorenz-96 baseline against literature)
- `:verified`: 0
- `:benchmarked`: 0
- `:argued`: 12 (LL-004, LL-005, LL-006, LL-007, LL-008,
  LL-011, LL-012, LL-013, LL-014, LL-016, LL-017, LL-018)
- `:open`: 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

Twelve entries closed at the design-pass level via manual
evidence; one entry (LL-003) closes to `:tested` via the P3
prototype's Lorenz-96 baseline. None machine-verified yet —
Lean (P5/P6) targets LL-006, LL-008, LL-018; P3 follow-ups
target LL-004 through LL-007 substantively for further
`:tested`/`:verified`/`:benchmarked` upgrades.

## Open structural questions

The protocol-layer questions from 0.0.1–0.0.3 (LL-011..LL-014,
LL-016, LL-017) closed at design level in 0.0.5 (`:argued`).
Remaining `:open` entries fall into two classes:

**Awaiting P5–P6 verification (2 entries):**

- **LL-001** substrate-bound identity primitive — closed in
  spirit by LL-006 detection bound; awaits Lean enforcement.
- **LL-002** visual ↔ security decoupling — invariant; awaits
  type-level / Lean enforcement to demonstrate the architectural
  separation cannot be re-coupled by accident.

**Corpus-policy boundaries (3 entries):**

- **LL-009** no complex numbers in security math — invariant
  honored by §2.4 design; closes to `:argued` under a future
  small-session companion articulating the boundary locally.
- **LL-010** no open-ended simulation — invariant honored
  (bounded-window static analysis only); same companion path.
- **LL-015** A3 (root) explicitly out of scope — scoping
  declaration, not a claim with verifiable evidence; remains
  `:open` as the honest framing of what LavaLamp does *not*
  cover.

## Live discipline notes

- **Asymmetry-trap watch is engaged.** Visual ↔ security
  decoupling (LL-002) is precisely the kind of move that future
  "tidying" might re-couple for performance reasons. The 0.0.5
  design pass preserves the decoupling: chaos-guard reseeds do
  not signal to the visual; high f_SDE / sensor sampling does
  not couple into the visual layer. If re-coupling is ever
  proposed, the basin-spoofing attack surface (V-002) returns.
- **No-complex-numbers boundary** (LL-009) honored by §2.4 — the
  potential field U(s, x; t) is real-valued throughout; the SDE
  is real-valued; the residue audit operates on real Lyapunov
  exponents.
- **No open-ended simulation** (LL-010) honored — observation
  windows are bounded T; the Oseledec / Pesin / Eckmann-Ruelle
  results invoked in §2.1 apply within the bounded ergodic
  regime, not over open-ended simulation.
- **Sensor-authenticity residual** (V-006 / LL-016) remains the
  largest residual risk even after 0.0.5. The design pass
  identifies four authenticity strategies and recommends a
  default; no strategy fully eliminates V-006. High-assurance
  deployments must specify which A4 capability level they assume.

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
- **`docs/language_plan_catlab_tier_companion.md`** (0.0.4) —
  methodology refinement inserting Catlab.jl / GATlab as a
  fifth tier between numerical verification and Haskell
  compositional completeness. Anchors on Closure v5 corpus
  precedent (`:catlab` evidence type, 9 of 145 `:proved`
  entries). Establishes the three-jobs distinction: Catlab
  (computational categorical), Haskell (compositional), Lean
  (formal). Default for LavaLamp: skip Catlab; revisit if P2
  surfaces categorical structure in the verification protocol.
- **`docs/qkd_pqc_complementarity_companion.md`** (0.0.4) —
  positioning analysis. LavaLamp is not QKD (different problem,
  different security tier); is defensive-postured (detect via
  residue audit, not prevent observation); composes with PQC
  rather than replacing it; replaces MFA under
  identity-as-closure; inherits the C-conjugate adversary
  structurally from Closure v5's cross-sector autopoiesis
  failure (0/5202 on primary seed). §2.6 connects identity to
  the Q₅₁-as-autopoietic reframing (Closure v5 v157, S157):
  identity is Q₅₁-tier; the residue audit is a spectrum check,
  not a checkpoint trace match.
- **`docs/architecture_design_companion.md`** (0.0.5) — P2
  architectural design pass. Five sub-sections closing the design
  questions for the residue audit, resolution-bounded security,
  chaos-guard, sensor coupling, and protocol layer (registration
  / cold-start / cross-config / no-oracle). Twelve spec entries
  move from `:open` to `:argued` (manual evidence); new entry
  LL-018 added for per-class A1..A6 quantification of the
  resolution-boundary margin. P3 unblocked. Round-2
  synthesis-team review trigger now met.
- **`src/julia/`** (0.0.6) — P3 prototype core bootstrap +
  Lorenz-96 baseline. Pinned Julia project (`Project.toml` +
  `Manifest.toml`) on DifferentialEquations 7.17,
  DynamicalSystems 3.6.7, StaticArrays 1.9.18.
  `src/julia/src/{LavaLamp.jl, Engine.jl}` implements Lorenz-96
  (N=40, F=8) and the Benettin Lyapunov spectrum estimator
  (LL-003 / LL-006 / LL-007 substrate). Test suite
  (`test/runtests.jl`, 8 assertions) verifies λ₁ ≈ 1.66 vs
  literature, n_pos ∈ [11, 16], h_KS ≈ 10.5, IC-invariance per
  Oseledec. LL-003 closes to `:tested`.
- **`docs/p3_baseline_companion.md`** (0.0.7) — P3 baseline
  companion + dev-host field observations. §2.1 documents the
  Lorenz-96 reproduction of literature; §2.2 records empirical
  test robustness against host non-stationarity (a real
  thermal-climb + AC-plug-in + battery-state-shift event
  occurred during the canonical baseline run, all 8 assertions
  still passed); §2.3 frames this as a substrate-coupling
  self-demonstration previewing P3a test design; §2.4 reframes
  compute load as a *structural indicator* of h_KS-margin, not
  a tax on the security primitive. §5 captures lessons for
  P3a/b/c/d sub-tasks. No spec status moves; positioning
  language captured for future paper.

## Live empirical observations

- **Compute and h_KS are structurally linked** (per
  `p3_baseline_companion.md` §2.4). The chaos-production rate
  S_production = h_KS sets the resolution-boundary margin Δh
  per LL-008/LL-018. Producing h_KS at the rate required for a
  meaningful margin requires sustained integration cost. A
  measurable thermal signature on the genuine device under load
  is *expected*, not a bug. Pitch language must reflect this.
- **Dev host is a free test-scenario source for P3a.** Thermal
  climb, AC plug-in, USB plug-in events on the developer's
  workstation are real substrate events of exactly the
  categories design §2.4 enumerates. P3a's synthetic
  sensor-stream stub should mirror these statistics; the dev
  host itself becomes a usable real-sensor test platform once
  IOKit / SMC FFI work is in scope.
- **Test bounds robust to real-world non-stationarity.** The
  ±15% bound on λ₁ and the ±25% bound on h_KS in
  `runtests.jl` absorbed a real configuration event during the
  canonical 0.0.6 run without false-failing. Future bound
  tightenings should keep this margin to preserve real-world
  robustness.

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
