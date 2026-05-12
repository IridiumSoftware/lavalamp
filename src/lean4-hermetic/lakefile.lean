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

@[default_target]
lean_lib «LL002Visual» where
  srcDir := "."
