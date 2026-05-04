# src/lean4/ — Lean 4 Formal-Verification Scaffold

This directory contains the Lean 4 scaffold for formal
verification of LavaLamp's structural security claims. **Scaffold
tier only at 0.0.36** — no theorems are stated yet; the directory
exists as parallel-safe infrastructure for round-3 work.

## What this is

- A buildable Lean 4 Lake project (`lakefile.lean`,
  `lean-toolchain`, root `LavaLamp.lean`).
- A `Theorems.lean` placeholder documenting the round-3 theorem
  statements that will land here.
- This README capturing the discipline + theorem plan + package-
  management notes.

## What this isn't

- **Not proofs.** The scaffold contains no `theorem` declarations
  at this tier. The plan-level statements in `Theorems.lean` are
  in comment blocks; uncommenting + filling in `sorry` proofs is
  round-3 work.
- **Not evidence.** No LL entry in `LAVALAMP_SPEC.md` cites this
  directory at the scaffold tier. When proofs land, the
  corresponding entries' evidence types move to `lean-proved` and
  statuses move to `:proved`.

## Build verification

From a clean checkout:

```bash
cd src/lean4
lake update    # generates lake-manifest.json (empty at scaffold tier)
lake build     # builds the LavaLamp library (smoke def only)
```

Per CLAUDE.md package-management discipline, the scaffold's
build was verified before commit. At the scaffold tier the build
is trivial (smoke def + comment-block placeholder); production-
grade build discipline lands with the first real proof.

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

**Open round-3 architectural decision.** Three options:

1. **Full Mathlib import** — `require Mathlib`. Pulls the entire
   ecosystem; build time grows from seconds to minutes; theorems
   gain access to Real / exp / Probability / Measure theory in
   their full generality.
2. **Project-local minimal substitute** — define `Real`,
   `exp`, `Distribution` etc. as opaque types with the algebraic
   structure each theorem needs. Lighter; lets us avoid Mathlib
   dependency churn; loses the breadth of Mathlib's lemmas.
3. **Hybrid** — start with project-local stubs at the shape
   level (priorities 5 / 6), import Mathlib only when reaching
   priorities 1-4 that need real-analysis content.

The decision is round-3-driven for two reasons:

- The `closure_forces_structure` paper update may revise some of
  the theorem statements (especially priorities 1 / 4 if the
  C-conjugate adversary structure or the `0/5202` cross-sector
  autopoiesis result shifts). Committing to Mathlib before that
  revision risks rework.
- The triadic-coordination-engine project uses **option 2**
  (project-local `Category` typeclass; no Mathlib on default
  build path) with an opt-in `src/lean4-cv/` Mathlib track. The
  same shape may apply here — but LavaLamp's claims are
  probability / real-analysis-flavoured (different from the
  category-theory of the engine project), so the decision
  isn't auto-inherited.

For the scaffold tier, **no Mathlib** — the project builds with
no dependencies. The `lakefile.lean` will gain a `require` line
when the decision lands.

## Package-management discipline

Per CLAUDE.md:

> Lean4 | `lean-toolchain` + `lake-manifest.json`
>
> Rules: never commit a lockfile-less ecosystem; pin transitive
> dependencies (`latest` is forbidden); update lockfiles
> deliberately in their own commit with rationale; verify a
> clean checkout + lockfile install builds before committing.

Current state at 0.0.36:

- `lean-toolchain` pinned to `leanprover/lean4:v4.18.0`. Update
  in a separate commit with rationale when the toolchain bumps.
- `lake-manifest.json` is **not committed yet** because no
  dependencies exist at the scaffold tier (`lake update`
  produces an empty manifest). When Mathlib or any other
  dependency is added, `lake update` regenerates the manifest
  and that commit pins the version.

## Round-3 trigger conditions

This scaffold becomes active proof-work territory when:

1. The `closure_forces_structure` paper update lands (the
   round-3 trigger condition; see
   `~/.claude/projects/.../memory/project_lavalamp_round3_trigger.md`).
2. The Mathlib-or-not decision is made (per §Mathlib integration
   above).
3. The first priority's theorem statement is finalised in
   conversation with the round-3 brief composition.

Until all three conditions, this directory stays at scaffold
tier. The `Theorems.lean` comment block + this README are the
canonical references for "where Lean work picks up."

## File inventory

- `lean-toolchain` — Lean 4 version pin.
- `lakefile.lean` — Lake build config; no deps at scaffold tier.
- `LavaLamp.lean` — root module; imports `LavaLamp.Theorems`;
  smoke `def hello` confirms the package builds.
- `LavaLamp/Theorems.lean` — round-3 theorem-statement
  placeholder; comment blocks describe each priority's intended
  shape.
- `README.md` (this file) — discipline + theorem plan +
  package-management notes.

When proofs land, expect the directory to grow:

- `LavaLamp/Spec.lean` — primitive type declarations (SDE,
  Envelope, Adversary, Distribution, etc.).
- `LavaLamp/LL006DetectionBound.lean`
- `LavaLamp/LL019TimingIndistinguishability.lean`
- `LavaLamp/LL020CalibrationDP.lean`
- `LavaLamp/LL021WorstCaseBound.lean`
- `LavaLamp/LL022OSStackDependency.lean`
- `LavaLamp/LL023ConsumerAPI.lean`
- `lake-manifest.json` — pinned dependency manifest.

The split into per-priority files happens when proof work
begins; one file per priority keeps each session's diff
focused and the build incremental.
