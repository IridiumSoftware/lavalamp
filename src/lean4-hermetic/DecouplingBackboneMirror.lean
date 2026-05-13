-- DecouplingBackboneMirror.lean — LL-050 decoupling-triad-backbone,
-- formal track via cross-repo Lean composition.
--
-- LL-050 (LAVALAMP_SPEC.md) is LavaLamp's leg in the cross-Triad
-- Decoupling axis joint claim that the TCE Discovery.Triadic
-- cross-Triad pass surfaced at v0.2.12 (commit `a9ddfea`):
--
--   `[LL-002, LZ-001, PH-004]` at score 23.00 — three
--   deployments, three V-DECOUPLING flavors, one structural
--   claim: the Triad keeps user-facing presentation strictly
--   separated from the security state it represents.
--
-- Structurally distinct from the No-Oracle Backbone
-- `[LL-002, LZ-012, PH-004]` at 26.00 (LL-046, formalised in
-- this hermetic tree's sibling `TriadBackboneMirror.lean`)
-- despite sharing LL-002 + PH-004 legs. The No-Oracle claim is
-- about output-cardinality; the Decoupling claim is about
-- architectural separation. LL-002 + PH-004 serve both
-- invariants; the distinguishing Lazarus leg is LZ-001
-- (visual-skin decoupling) here, vs LZ-012 (companion-read-
-- only) in the No-Oracle Backbone.
--
-- Lazarus is the home of the cross-repo Lean proof — at
-- v0.1.29, Lazarus's `src/lean4/DecouplingBackbone.lean`
-- composes all three concrete leg types into an 8-element
-- finite joint output type:
--
--   - LavaLamp.LL002Visual.VisualOutput (2 states) — imported
--     from this very `lavalamp-hermetic` package.
--   - Lazarus.VisualSkinDecoupling.Mode (2 states normal /
--     shakespeare) — sibling module to DecouplingBackbone,
--     concrete formalisation of LZ-001's producer-side mode
--     vocabulary.
--   - PharOS.Membrane.MembraneOutput (2 states) — imported
--     from pharos-lean via Lake git dep.
--
-- Joint cardinality 2 × 2 × 2 = 8 (vs TriadBackbone's
-- 2 × 3 × 2 = 12, because LZ-012's LlmOutput has 3
-- constructors and LZ-001's Mode has 2).
--
-- This file is LavaLamp's mirror — it cites the Lazarus
-- theorem from LavaLamp's perspective. The `lavalamp-hermetic`
-- lakefile gains the `DecouplingBackboneMirror` library and
-- bumps its existing lazarus-lean dep from commit `062dcb3`
-- (v0.1.26, the LL-046 pin) to `5f402d1` (v0.1.29) so the
-- new DecouplingBackbone proof is genuinely available in
-- LavaLamp's hermetic build, not just referenced in prose.
--
-- The cited theorem
-- `Lazarus.DecouplingBackbone.decoupling_triad_backbone` is
-- exposed in this LavaLamp namespace via Lean's `export`
-- mechanism so LL-050's `Source:` field can cite a
-- LavaLamp-namespaced symbol.
--
-- Promotes LL-050 from `:argued` to `:proved` via this
-- cross-repo Lean citation. Mirror entries also exist at
-- PharOS PH-018 and Lazarus LZ-031 (the home of the
-- composition).
--
-- Honest framing. LL-050's evidence is the SAME theorem
-- backing Lazarus's LZ-031 and (mirror) PharOS's PH-018.
-- The joint claim is one structural fact about the Triad's
-- observer surface; each deployment cites it from its own
-- perspective. This is structurally what "mirror entries"
-- means — three rows of evidence in three specs all pointing
-- at one proof artifact.

import DecouplingBackbone

namespace LavaLamp.DecouplingBackboneMirror

open Lazarus.DecouplingBackbone

/-- LL-050's evidence for the cross-Triad Decoupling axis:
    the joint Triad decoupling output (visual × mode ×
    membrane) is an 8-element finite type. Re-exports
    `Lazarus.DecouplingBackbone.decoupling_triad_backbone`
    under LavaLamp's namespace for spec-citation symmetry. -/
theorem ll050_decoupling_triad_backbone (out : DecouplingOutput) :
    out ∈ decouplingOutputs :=
  decoupling_triad_backbone out

/-- Cardinality witness re-exported under LavaLamp's namespace. -/
theorem ll050_decoupling_output_cardinality :
    decouplingOutputs.length = 8 :=
  decoupling_output_cardinality

end LavaLamp.DecouplingBackboneMirror
