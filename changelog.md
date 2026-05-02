# Changelog — LavaLamp

Versioned entries top-down. Each entry mirrors a commit; commit
messages match entry summaries.

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
