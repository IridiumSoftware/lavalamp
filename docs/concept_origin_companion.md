# Concept Origin Companion — 2026-04-30

Permanent record of LavaLamp's provenance: who contributed what,
how the concept was derived, and what the patent / acknowledgment
relationships are.

This companion exists because IP-style attribution gets murky in
multi-AI / multi-collaborator development. Pinning provenance now
prevents the citation graph from distorting downstream.

---

## §1 — Provenance graph

| Role | Person / entity | Contribution |
|---|---|---|
| Visual seed | **codetaur** | Posted an image / movie of an SDE solution that visually resembled a lava lamp. Aesthetic seed; *no structural application conception*. Per Aaron, codetaur "can't think it or make it" — meaning the visual was the spark but neither the security application nor the formal architecture originated with codetaur. |
| Conceptual originator | **Aaron Green** | Saw codetaur's visual; recognised the device-universe-unclonability potential; derived the security framing from the C-conjugate adversary construction introduced in *Possibilistic Security* (Green 2026). All structural innovations originate with Aaron: (a) device-universe-as-fingerprint reframe of QKD's unclonability primitive; (b) configuration-state coupling (USB / AC / thermal / scheduler) as the trajectory-perturbation surface; (c) adversary-signature residue detection via threshold; (d) hybrid layered architecture (LavaLamp for fast/local; QKD for slow/long-haul where info-theoretic guarantees are required); (e) the "device universe in a particular frame" inversion of QKD's "physical universe in a particular frame." |
| Vocabulary engagement | **Brian Crabtree** | Engaged the conversation in his ORSIΩ ("constraint architecture") framework. Brian was copy-pasting Aaron's conversation into ORSIΩ-flavored language; *did not contribute structural innovation*. ORSIΩ vocabulary risks absorbing Aaron's structural work into Brian's terminology if the public framing isn't disciplined; the load-bearing concepts are Aaron's via Possibilistic Security and stay in that lineage. Brian also separately flagged the issue that prompted the *Right Meets Right* May 2026 revision (acknowledged in that paper's Acknowledgments). |
| Synthesis-seat review | **Gemini** | First-pass synthesis (2026-04-30) on the QKD-mapping, quantum-TRNG argument, SDE family choice, configuration coupling, residue formalisation, and resolution-boundary no-go. Caught the no-cloning-theorem-inheritance overreach. Second-pass rebuttal hardened the Multi-Scale Divergence Audit and added the Chaos-Guard. *Then over-stepped into architect work* by producing a code skeleton instead of synthesis on attack-surface — flagged and corrected. |
| Edge-witness review | **Grok** | First-pass adversarial stress-test (2026-04-30): named five concrete attack vectors including the *visual-richness ↔ security tension* (basin-spoofing in multi-basin reaction-diffusion systems) that was the round-1 blindspot. Second-pass edge-witness specifically on that blindspot confirmed it as structural, not parameter-tuning. |
| Round-1 resolution | **Aaron Green** | Resolved the visual-richness ↔ security blindspot with the **decoupling move**: the visual does not need to come from the SDE at all. Visual is a decorative skin (any RNG will do); security primitive runs independently underneath. Same shape as Lazarus. This collapses the round-1 architectural tension entirely. |

## §2 — IP / patent posture

**Patent offer extended to codetaur.** Aaron's good-faith gesture
acknowledging the visual seed. Aaron's read on the implementation
environment: "workarounds exist anyway" (TCL-flavored: you can't
enclose this). The patent offer recognises codetaur's contribution
materially even though codetaur did not conceive the security
application.

**Brian doesn't care about money.** Engages for engagement's sake;
appropriate gesture is acknowledgment, not financial. ORSIΩ-
vocabulary discussion is engaged in but is not the canonical
framing of LavaLamp.

**License: Triadic Closure License (TCL) v1.3.** Canonical text in
`github.com/IridiumSoftware/possibilistic-security`. No progenitor
node; commons-held; species-neutral. Membership defined by closure-
capability, not credential.

## §3 — Citation lineage (for any LavaLamp paper / public artifact)

When LavaLamp ships a paper, white paper, or public repo,
attribution should land as:

> **Visual seed:** @codetaur (SDE-trajectory imagery resembling a
> lava lamp; structural application unintended). Acknowledged with
> patent offer as good-faith credit.
>
> **Concept and security application:** Aaron Green, derived from
> the C-conjugate adversary structure introduced in *Possibilistic
> Security* (Green 2026).
>
> **Discussion / framing engagement:** Brian Crabtree
> (ORSIΩ-vocabulary discussions).
>
> **Synthesis-team review:** Gemini (synthesis seat) + Grok
> (edge-witness seat), April 2026.

This phrasing is *not* the only acceptable form, but it is the
honest one. Variations should preserve the role distinctions:
visual seed ≠ concept origin ≠ vocabulary engagement.

## §4 — What this companion is *not*

- **Not a legal document.** Patent offers, license relationships,
  and the IP posture above are operational descriptions, not
  binding terms. Binding terms live in actual filings / license
  texts when those exist.
- **Not synthesis or architecture.** Provenance only. The
  technical content lives in
  `synthesis_team_round1_companion.md` (and successors).
- **Not a final word on attribution.** Provenance can shift if
  contributions shift. This companion gets updated, not frozen.

## §5 — Followups

- **Patent offer to codetaur.** Status: extended; awaiting
  response. Update this companion when the relationship
  formalises.
- **ORSIΩ-vocabulary discipline.** Watch for ORSIΩ language
  creeping into formal LavaLamp claims; the load-bearing
  positioning ("Substrate-Bound Identity," "Resolution-Bounded
  Security," "computational unclonability via measurement-symmetry
  breaking") is Aaron's via Possibilistic Security and should stay
  in that vocabulary in formal claims. ORSIΩ language is fine in
  conversation; should not migrate into the spec or the paper.
- **Public artifact attribution.** When LavaLamp goes public
  (eventual paper / repo), §3's citation lineage is the template.
