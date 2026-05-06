# src/lean4/ — Lean 4 Formal-Verification Track

This directory contains the Lean 4 formal-verification track
for LavaLamp's structural security claims. **Mathlib-integrated
as of 0.0.47** (per round-3 §1D.v Decision 1 — Option A: full
Mathlib v4.29.1). The first theorem statement
(`LL021_worst_case_bound`) lands at 0.0.47 sorry-stubbed; L2
(0.0.48) replaces the `sorry` with a real proof and promotes
LL-021 to `:proved` with `lean-proved` evidence.

## What this is

- A buildable Lean 4 Lake project (`lakefile.lean`,
  `lean-toolchain`, root `LavaLamp.lean`) with Mathlib v4.29.1
  pinned via `lake-manifest.json`.
- `LavaLamp/Theorems.lean` carrying the first real theorem
  statement (`LL021_worst_case_bound`, sorry-stubbed at 0.0.47);
  subsequent theorems (LL-019 / LL-020 / LL-006 / LL-022 /
  LL-023) build on this Mathlib environment and land in
  per-priority files.
- This README capturing the discipline + theorem plan + package-
  management notes.

## What this isn't

- **Not proofs (yet).** At 0.0.47 the only theorem in this
  directory is sorry-stubbed; per CLAUDE.md §Honest framing,
  a sorry-stubbed theorem is not a proof. LL-021 stays at
  `:benchmarked` until L2 (0.0.48) removes the `sorry`.
- **Not evidence (yet).** `artifact_registry.md` includes
  `src/lean4/LavaLamp/Theorems.lean` in LL-021's Test/Proof
  column at 0.0.47 as a forward pointer to L2; the evidence
  type stays `benchmarked` until L2 replaces the `sorry`.

## Build verification

From a clean checkout:

```bash
cd src/lean4
lake update             # populates lake-manifest.json from Mathlib v4.29.1
lake exe cache get      # downloads Mathlib's prebuilt .olean cache (~8k files)
lake build              # builds the LavaLamp library on top of cached Mathlib
```

At 0.0.47 `lake build` returns 767 jobs green with a single
expected `declaration uses 'sorry'` warning on
`LL021_worst_case_bound`. Once L2 lands, the warning disappears
and the build becomes a real correctness check (Lean's kernel
verifies the proof at compile time).

Per CLAUDE.md package-management discipline, every commit
landing in this directory verifies a clean checkout +
`lake update` + `lake exe cache get` + `lake build` cycle
before commit.

## Theorem-statement plan

Six priorities, drawn from round-2 §1D.v + the 0.0.26 P-OS
companion + the 0.0.34 P-PharOS companion. See
`Theorems.lean` for the comment-block forms; brief here:

| Priority | LL-IDs | Statement shape | Round-3 dependencies |
|---|---|---|---|
| 1 | LL-021 | `P_detect ≥ 1 - K·exp(-c·T·ε_eff²)` worst-case parameterised on `ε_eff = ε_A · proj(û onto m_unit)` with `K=1, c=0.0288, T=60` | Mathlib Real / exp |
| 2 | LL-019 | Constant-time wrapper produces equal timing distributions across accept/reject inputs (operationally; statistical at the LL-019 :benchmarked tier) | Mathlib Probability + LL-029 host-isolation theorem (per the 0.0.29 regime-boundary finding) |
| 3 | LL-020 | `(ε, δ)`-DP guarantee on the variance-convolution Strategy 2 `differentially_private_envelope` per Dwork-Roth Gaussian mechanism | Mathlib Probability |
| 4 | LL-006 / LL-008 / LL-018 | `P_detect ≥ 1 - K·exp(-c·T·δ_A²)` isotropic, with the per-class A1..A6 quantification | Mathlib Real + the SDE / Lyapunov-spectrum primitives |
| 5 (parametric) | LL-022 OS-stack dependency | `forall (os : OSAssumptions) (proof_os : LL022.satisfies os), <LL_property>` | Theorem-shape discipline only; no Mathlib needed at the shape level |
| 6 (parametric) | LL-023 consumer-API surface | `forall (consumer : LL023.Consumer) (proof : LL023.conforms consumer), ConsumerInheritsProperty consumer LL_property` | Same shape discipline as priority 5 |

## Mathlib integration

**Mathlib integrated at 0.0.47** per round-3 §1D.v Decision 1
(Aaron rendered 2026-05-06: Option A — full Mathlib).
LavaLamp's theorem priorities are probability / real-analysis-
flavoured (different from the category-theory of the
triadic-coordination-engine project, which uses a project-
local `Category` typeclass with an opt-in Mathlib track at
`src/lean4-cv/`); Option A pulls the full Mathlib ecosystem
to give probability / measure / Real / exp lemmas in their
full generality, accepting the build-time cost.

Three options were on the table pre-decision (kept here for
historical reference):

1. **Full Mathlib import** — `require Mathlib`. **(chosen.)**
   Pulls the entire ecosystem; build time grows from seconds
   to minutes on a fresh runner (mitigated by `lake exe cache
   get` pulling prebuilt oleans); theorems gain access to
   Real / exp / Probability / Measure theory in their full
   generality.
2. **Project-local minimal substitute** — define `Real`,
   `exp`, `Distribution` etc. as opaque types. Lighter; loses
   Mathlib's breadth.
3. **Hybrid** — project-local stubs for shape-level priorities;
   Mathlib for real-analysis priorities.

**0.0.47 implementation:**

- `lakefile.lean`: `require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @
  "v4.29.1"`.
- `lean-toolchain`: `leanprover/lean4:v4.29.1` (bumped from
  v4.18.0 in 0.0.47 — see §Package-management discipline below).
- `lake-manifest.json`: pins Mathlib v4.29.1 + 8 transitive
  deps (`plausible`, `LeanSearchClient`, `importGraph`,
  `proofwidgets`, `aesop`, `Qq`, `batteries`, `Cli`).
- `LavaLamp/Theorems.lean`: imports `Mathlib.Data.Real.Basic`;
  states `LL021_worst_case_bound` sorry-stubbed.
- `lake exe cache get` populates `.lake/packages/mathlib/.lake/build/`
  with 8232 prebuilt `.olean` files.
- `.github/workflows/lean.yml`: `timeout-minutes` 15 → 60 to
  absorb Mathlib first-build window on a fresh ubuntu runner;
  `lean-action` invokes `lake exe cache get` automatically.

## Package-management discipline

Per CLAUDE.md:

> Lean4 | `lean-toolchain` + `lake-manifest.json`
>
> Rules: never commit a lockfile-less ecosystem; pin transitive
> dependencies (`latest` is forbidden); update lockfiles
> deliberately in their own commit with rationale; verify a
> clean checkout + lockfile install builds before committing.

Current state at 0.0.47:

- `lean-toolchain` pinned to `leanprover/lean4:v4.29.1`
  (bumped from v4.18.0 at 0.0.47). **Reason for bump:** Darwin
  25 (macOS 25+) hit a dyld linker error on the v4.18.0 cache
  binary — `__DATA_CONST segment missing SG_READ_ONLY flag`;
  v4.29.1 ships with the macOS-25-compatible binary. Mathlib's
  v4.29.1 release tags the matching toolchain, so toolchain +
  Mathlib are co-versioned.
- `lake-manifest.json` is **committed** (was uncommitted at
  scaffold tier when no deps existed). Pins Mathlib v4.29.1 +
  8 transitive deps with full commit hashes; `lake update`
  regenerates the manifest deliberately on dependency-update
  commits per CLAUDE.md.

## Round-3 trigger conditions

**All three conditions met as of 0.0.47:**

1. ✓ The `closure_forces_structure` paper landed (v1.0
   2026-04-01); round-3 brief composed against it; round-3
   ran 2026-05-06.
2. ✓ The Mathlib-or-not decision rendered: Option A — full
   Mathlib (round-3 §1D.v Decision 1, Aaron 2026-05-06).
3. ✓ The first priority's theorem statement finalised:
   `LL021_worst_case_bound` capturing the bound shape
   `0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 → ε_A * proj ≤ ε_A`.

This directory is now active proof-work territory.
`LavaLamp/Theorems.lean` is the canonical reference for
"where Lean work picks up next" — currently the L2 sorry-fill
on `LL021_worst_case_bound`, then theorems 2-6 per the table
above.

## File inventory

- `lean-toolchain` — Lean 4 version pin (v4.29.1; bumped 0.0.47).
- `lakefile.lean` — Lake build config; Mathlib v4.29.1 require
  (added 0.0.47).
- `lake-manifest.json` — pinned dependency manifest; Mathlib +
  8 transitive deps (committed 0.0.47).
- `LavaLamp.lean` — root module; imports `LavaLamp.Theorems`;
  smoke `def hello` confirms the package builds.
- `LavaLamp/Theorems.lean` — first theorem `LL021_worst_case_bound`
  (sorry-stubbed at 0.0.47; L2 fills proof body at 0.0.48);
  comment blocks describe priorities 2-6.
- `README.md` (this file) — discipline + theorem plan +
  package-management notes.

As subsequent priorities' theorems are stated, the
`Theorems.lean` file may split into per-priority files (one
file per priority keeps each session's diff focused and the
build incremental):

- `LavaLamp/Spec.lean` — primitive type declarations (SDE,
  Envelope, Adversary, Distribution, etc.); introduced when
  the first non-LL-021 theorem needs a shared type vocabulary.
- `LavaLamp/LL006DetectionBound.lean`
- `LavaLamp/LL019TimingIndistinguishability.lean`
- `LavaLamp/LL020CalibrationDP.lean`
- `LavaLamp/LL021WorstCaseBound.lean` (currently inlined in
  `LavaLamp/Theorems.lean`; moves out when LL-019 lands).
- `LavaLamp/LL022OSStackDependency.lean`
- `LavaLamp/LL023ConsumerAPI.lean`
