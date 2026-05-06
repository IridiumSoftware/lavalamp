/-
  LavaLamp — Lean 4 formal-verification.

  Per CLAUDE.md package-management discipline:
    "Lean4 | lean-toolchain + lake-manifest.json"
    "verify a clean checkout + lockfile install builds before committing"

  Toolchain pinned in `lean-toolchain` (currently
  leanprover/lean4:v4.29.1). Mathlib v4.29.1 ships with the
  same toolchain — no version conflict. The toolchain bumped
  from v4.18.0 → v4.29.1 in 0.0.47 to resolve a macOS 25 +
  Lean 4.18.0 linker incompatibility (older toolchain's
  `cache` executable hits dyld `__DATA_CONST segment missing
  SG_READ_ONLY flag` on Darwin 25+); v4.29.1 ships with the
  fix.

  Mathlib integration landed at 0.0.47 per round-3 §1D.v
  Decision 1 (Option A: full Mathlib for measure-theoretic
  content). The first theorem (LL-021 worst-case bound) lands
  this version as a sorry-stubbed statement; the proof body
  lands in 0.0.48.

  Lockfile: `lake-manifest.json` pins Mathlib v4.29.1 + all
  transitive dependencies (Std4 / Aesop / ProofWidgets4 / Qq /
  Cli / etc.). Regenerate via `lake update`; bootstrap from a
  clean checkout via:

      cd src/lean4
      lake update             # populates manifest from Mathlib v4.29.1
      lake exe cache get      # downloads Mathlib's prebuilt .olean cache
      lake build              # builds LavaLamp library + Mathlib deps
-/

import Lake
open Lake DSL

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.29.1"

package «LavaLamp» where
  -- Default leanOptions; production-grade settings land with the
  -- first real proof work.
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩
  ]

@[default_target]
lean_lib «LavaLamp» where
  -- Library root is `LavaLamp.lean`; submodule files live under
  -- `LavaLamp/`.
  defaultFacets := #[LeanLib.leanArtsFacet]
