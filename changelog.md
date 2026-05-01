# Changelog — LavaLamp

Versioned entries top-down. Each entry mirrors a commit; commit
messages match entry summaries.

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
