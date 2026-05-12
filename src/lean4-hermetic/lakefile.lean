-- lakefile.lean — hermetic Lean4 sibling track for LavaLamp.
--
-- LavaLamp's primary Lean tree at `src/lean4/` carries Mathlib
-- (LL-006 / LL-019 / LL-020 / LL-021 / LL-022 / LL-023 round-3
-- theorems). This sibling tree at `src/lean4-hermetic/` is a
-- separate Lake package with NO Mathlib dependency, mirroring
-- PharOS's `pharos-lean` and Lazarus's `lazarus-lean` hermetic
-- patterns.
--
-- The hermetic package exists so that cross-repo consumers
-- (currently Lazarus's `TriadBackbone.lean`, which composes
-- the No-Oracle Backbone of the Triad) can import LavaLamp's
-- LL-002 visual-output type without dragging Mathlib's
-- ~2500-job transitive build into their tree. The Mathlib-
-- track theorems live in `../lean4/` and remain unchanged.
--
-- Current contents:
--   - `LL002Visual.lean` — the LL-002 visual-security-decoupling
--     type-level surface. Two-constructor inductive
--     `VisualOutput` matching the operational surface
--     established by LL-002's `:tested` static-lint evidence in
--     `src/julia/test/runtests.jl`. Layered companion to LL-002.
--   - `TriadBackboneMirror.lean` — LL-046 cross-Triad mirror.
--     Imports `Lazarus.TriadBackbone` via Lake git dep on
--     lazarus-lean@062dcb3 and re-exports the
--     `no_oracle_triad_backbone` composition theorem under
--     LavaLamp's namespace.
--
-- Future hermetic content can be added as additional default
-- targets in this lakefile.

import Lake
open Lake DSL

package «lavalamp-hermetic» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

-- Cross-repo dependency on Lazarus's hermetic Lean tree.
-- Required by TriadBackboneMirror (LL-046 no-oracle-triad-
-- backbone), which imports Lazarus.TriadBackbone to re-export
-- the `no_oracle_triad_backbone` composition theorem (proved
-- at Lazarus v0.1.26 using PharOS Membrane + LavaLamp
-- LL002Visual + Lazarus CompanionDiscipline as the three
-- concrete legs). LL-046 cites the Lazarus theorem from
-- LavaLamp's perspective; mirror entries also exist at
-- PharOS PH-014 and Lazarus LZ-028. Lazarus's lake-manifest
-- pins lavalamp-hermetic@1a2534f transitively — Lake prefers
-- the local lavalamp-hermetic (this package, HEAD) over that
-- transitive copy of itself.
require «lazarus-lean» from git
  "https://github.com/IridiumSoftware/lazarus.git" @ "062dcb3" / "src/lean4"

@[default_target]
lean_lib «LL002Visual» where
  srcDir := "."

-- LL-046 cross-Triad No-Oracle Backbone mirror — re-exports
-- Lazarus's `no_oracle_triad_backbone` theorem under
-- LavaLamp's namespace. The Lake git dep above brings the
-- proof artifact into LavaLamp's hermetic build; this
-- lean_lib stanza makes the mirror module a default build
-- target so `lake build` validates it.
@[default_target]
lean_lib «TriadBackboneMirror» where
  srcDir := "."
