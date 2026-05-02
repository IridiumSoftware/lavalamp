# artifact_registry.md — LavaLamp

Version: 0.0.5 (P2 architectural design pass, 2026-05-02)
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
| LL-003 | single-attractor chaotic engine | Core | none | — | — | :open |
| LL-004 | continuous sensor coupling | Core | manual | docs/architecture_design_companion.md §2.4, §3.5 | — | :argued |
| LL-005 | sensor Nyquist condition | Core | manual | docs/architecture_design_companion.md §2.4, §3.6 | — | :argued |

## Detection / verification

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-006 | Lyapunov-spectrum residue audit | Core | manual | docs/architecture_design_companion.md §2.1, §3.1 | — | :argued |
| LL-007 | chaos-guard | Operational | manual | docs/architecture_design_companion.md §2.3, §3.4 | — | :argued |
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

---

## Counts (must match LAVALAMP_SPEC.md and dashboard.md)

- Total: 18
- `:proved`: 0
- `:tested`: 0
- `:verified`: 0
- `:benchmarked`: 0
- `:argued`: 12
- `:open`: 6

## Cross-audit A1–A6 self-check (post-0.0.5)

- **A1 — Coverage.** Every LL-ID in `LAVALAMP_SPEC.md` has a row
  here. ✓ (18 of 18).
- **A2 — Key match.** Spec → registry keys are identical. ✓.
- **A3 — Evidence exists.** Twelve entries cite
  `docs/architecture_design_companion.md` as their Test/Proof
  file; that file exists in `git ls-files` after this commit.
  Source files remain `—` for all entries (no implementation
  yet).
- **A4 — Status honesty.** All `:argued` entries carry `manual`
  evidence; all `:open` entries carry `none`. ✓. No entry has
  a status its evidence type cannot support.
- **A5 — Stale counts.** Counts above match
  `LAVALAMP_SPEC.md` 0.0.5 and `dashboard.md` 0.0.5.
- **A6 — Test sync.** No machine-runnable tests yet — design-stage.
  Becomes meaningful post-P3 implementation. The companion
  document discharges the design-level argument; running tests
  flow from P3.

## Test-coverage notes

No test infrastructure yet. Twelve entries are `:argued` via the
P2 design companion (manual evidence). Pending:

- **P3 — Julia prototype core.** Implements LL-003 through
  LL-008 substantively. Produces example-tested / property-tested
  / benchmarked evidence per entry.
- **P4 — Haskell compositional-completeness.** Spec-as-types +
  QuickCheck against the Julia prototype.
- **P5 — Lean 4 formal verification.** Promotes structural claims
  (LL-006, LL-008, LL-018) to `:proved` with `lean-proved`
  evidence.
- **P6 — C/C++ production hardening.** Future, from proven spec.

The boundary entries (LL-009, LL-010, LL-015) are corpus-policy
declarations; they upgrade to `:argued` under future small-session
companions that articulate the boundary in the local context.
