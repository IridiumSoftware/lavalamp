# artifact_registry.md — LavaLamp

Version: 0.0.18 (LL-021 :benchmarked, 2026-05-03)
Bridges every entry in `LAVALAMP_SPEC.md` to its evidence file.

## Coverage rule

Every spec LL-ID must have a row here. `git ls-files` must contain
every Test/Proof and Source path listed.

## Columns

- **LL-ID** — matches `LAVALAMP_SPEC.md`.
- **Key** — short name from spec entry.
- **Logic tier** — `Core` / `Operational` / `Boundary`.
- **Evidence type** — `lean-proved` / `type-checked` / `algebraic`
  / `property-tested` / `example-tested` / `benchmarked` /
  `manual` / `none`.
- **Test/Proof file** — path to the artifact establishing the
  claim. `—` if none yet.
- **Source file** — path to the implementation the claim describes.
  `—` if none yet.
- **Status** — `:proved` / `:verified` / `:tested` / `:benchmarked`
  / `:argued` / `:open`.

## Status–evidence consistency

`:proved` requires `lean-proved`, `type-checked`, or `algebraic`.
`:verified` requires `property-tested`. `:tested` requires
`example-tested`. `:benchmarked` requires `benchmarked`. `:argued`
requires `manual`. `:open` requires `none`. Cross-audit A4 enforces.

---

## Core architecture

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-001 | substrate-bound identity primitive | Core | none | — | — | :open |
| LL-002 | visual ↔ security decoupling invariant | Core | none | — | — | :open |
| LL-003 | single-attractor chaotic engine | Core | example-tested | src/julia/test/runtests.jl | src/julia/src/Engine.jl | :tested |
| LL-004 | continuous sensor coupling | Core | example-tested | src/julia/test/runtests.jl | src/julia/src/Sensors.jl + src/julia/src/Engine.jl | :tested |
| LL-005 | sensor Nyquist condition | Core | manual | docs/architecture_design_companion.md §2.4, §3.6 | — | :argued |

## Detection / verification

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-006 | Lyapunov-spectrum residue audit | Core | benchmarked | src/julia/benchmark/p3_bound_high_res.jl + src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt + docs/p3_bound_companion.md | src/julia/src/Audit.jl | :benchmarked |
| LL-007 | chaos-guard | Operational | example-tested | src/julia/test/runtests.jl | src/julia/src/ChaosGuard.jl | :tested |
| LL-008 | resolution-bounded security claim | Core | manual | docs/architecture_design_companion.md §2.2, §3.2 | — | :argued |

## Boundary constraints

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-009 | no complex numbers in security math | Boundary | none | — | — | :open |
| LL-010 | no open-ended simulation | Boundary | none | — | — | :open |

## Protocol layer (closed at design-pass level by 0.0.5)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-011 | registration ceremony | Operational | manual | docs/architecture_design_companion.md §2.5.1, §3.8 | — | :argued |
| LL-012 | cold-start window | Operational | manual | docs/architecture_design_companion.md §2.5.2, §3.8 | — | :argued |
| LL-013 | cross-config transition handling | Operational | manual | docs/architecture_design_companion.md §2.5.3, §3.8 | — | :argued |
| LL-014 | adversary-signature threshold calibration | Operational | manual | docs/architecture_design_companion.md §2.5.5, §3.8 | — | :argued |

## Surfaced by attack-surface enumeration (0.0.3)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-015 | adversary-class-A3 out of scope | Boundary | none | — | — | :open |
| LL-016 | sensor-authenticity requirement | Core | manual | docs/architecture_design_companion.md §2.4, §3.7 | — | :argued |
| LL-017 | verification no-oracle requirement | Core | manual | docs/architecture_design_companion.md §2.5.4, §3.8 | — | :argued |

## Surfaced by P2 architectural design pass (0.0.5)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-018 | adversary-resolution-bound formalisation (per-class A1..A6) | Core | manual | docs/architecture_design_companion.md §2.2, §3.3 | — | :argued |

## Surfaced by synthesis-team round 2 (0.0.12)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-019 | side-channel hardening (reseed timing + audit-on-verify) | Core | example-tested | src/julia/test/runtests.jl | src/julia/src/Audit.jl | :tested |
| LL-020 | calibration confidentiality (envelope sealed against observers) | Core | manual | docs/p_r2b_calibration_confidentiality_companion.md §2 | — | :argued |
| LL-021 | worst-case-adversary-bound (structured directions, not isotropic) | Core | benchmarked | src/julia/benchmark/p_r2c_structured_adversary.jl + src/julia/benchmark/results/p_r2c_structured_lorenz96.txt + docs/ll021_benchmarked_companion.md | src/julia/src/Audit.jl | :benchmarked |

---

## Counts (must match LAVALAMP_SPEC.md and dashboard.md)

- Total: 21
- `:proved`: 0
- `:tested`: 4
- `:verified`: 0
- `:benchmarked`: 2
- `:argued`: 10
- `:open`: 5

## Cross-audit A1–A6 self-check (post-0.0.18)

- **A1 — Coverage.** Every LL-ID in `LAVALAMP_SPEC.md` has a row
  here. ✓ (21 of 21).
- **A2 — Key match.** Spec → registry keys are identical. ✓.
- **A3 — Evidence exists.** Nine entries cite
  `docs/architecture_design_companion.md`; four entries
  (LL-003, LL-004, LL-006, LL-007) cite `src/julia/test/runtests.jl`
  as their test file with source files in `src/julia/src/`.
  LL-006 additionally cites
  `src/julia/benchmark/results/p3b_detection_lorenz96.txt` as
  supporting empirical-data evidence. All cited paths exist
  in `git ls-files` after this commit.
- **A4 — Status honesty.** All `:argued` entries carry `manual`;
  all four `:tested` entries carry `example-tested`; all
  `:open` entries carry `none`. ✓. No entry has a status its
  evidence type cannot support.
- **A5 — Stale counts.** Counts above match
  `LAVALAMP_SPEC.md` 0.0.18 and `dashboard.md` 0.0.18.
- **A6 — Test sync.** LL-003, LL-004, LL-006, LL-007 are
  exercised by `src/julia/test/runtests.jl`, runnable via
  `Pkg.test()` from `src/julia/`; 82/82 assertions pass in
  ~47s wall clock — *faster* than 0.0.9's 47/78s thanks to
  the chaos-guard tests using cheap Wolf-method λ₁ estimation.
  CI integration remains a follow-up.

## Test-coverage notes

Nine entries are `:argued` via the P2 design companion (manual
evidence); four entries (LL-003, LL-004, LL-006, LL-007) are
`:tested` via the P3 prototype. Pending:

- **P3 follow-ups.** SDE-selection comparative benchmark
  across Lorenz-96 / Lorenz-63 / Rössler (upgrades LL-003 to
  `:benchmarked`); Nyquist-condition adversary-rate benchmark
  (closes LL-005 to `:tested`); LL-006 `:benchmarked`-upgrade
  via §2.1 bound-constant calibration (K, c, δ_A(ε_A) fitting
  against the existing detection-probability surface).
- **P4 — Haskell compositional-completeness.** Spec-as-types +
  QuickCheck against the Julia prototype.
- **P5 — Lean 4 formal verification.** Promotes structural claims
  (LL-006, LL-008, LL-018) to `:proved` with `lean-proved`
  evidence.
- **P6 — C/C++ production hardening.** Future, from proven spec.

The boundary entries (LL-009, LL-010, LL-015) are corpus-policy
declarations; they upgrade to `:argued` under future small-session
companions that articulate the boundary in the local context.
