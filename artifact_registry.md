# artifact_registry.md — LavaLamp

Version: 0.0.1 (concept-stage, 2026-04-30)
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
| LL-004 | continuous sensor coupling | Core | none | — | — | :open |
| LL-005 | sensor Nyquist condition | Core | none | — | — | :open |

## Detection / verification

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-006 | Lyapunov-spectrum residue audit | Core | none | — | — | :open |
| LL-007 | chaos-guard | Operational | none | — | — | :open |
| LL-008 | resolution-bounded security claim | Core | none | — | — | :open |

## Boundary constraints

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-009 | no complex numbers in security math | Boundary | none | — | — | :open |
| LL-010 | no open-ended simulation | Boundary | none | — | — | :open |

## Open protocol questions

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-011 | registration ceremony | Operational | none | — | — | :open |
| LL-012 | cold-start window | Operational | none | — | — | :open |
| LL-013 | cross-config transition handling | Operational | none | — | — | :open |
| LL-014 | adversary-signature threshold calibration | Operational | none | — | — | :open |

## Surfaced by attack-surface enumeration

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-015 | adversary-class-A3 out of scope | Boundary | none | — | — | :open |
| LL-016 | sensor-authenticity requirement | Core | none | — | — | :open |
| LL-017 | verification no-oracle requirement | Core | none | — | — | :open |

---

## Counts (must match LAVALAMP_SPEC.md and dashboard.md)

- Total: 17
- `:proved`: 0
- `:tested`: 0
- `:verified`: 0
- `:benchmarked`: 0
- `:argued`: 0
- `:open`: 17

## Cross-audit A1–A6 self-check (initial)

- **A1 — Coverage.** Every LL-ID in `LAVALAMP_SPEC.md` has a row
  here. ✓ (17 of 17).
- **A2 — Key match.** Spec → registry keys are identical. ✓.
- **A3 — Evidence exists.** No Test/Proof or Source files yet —
  concept-stage; this becomes meaningful once implementation
  starts.
- **A4 — Status honesty.** All `:open` entries are `none`. ✓.
- **A5 — Stale counts.** Counts above match `LAVALAMP_SPEC.md`.
- **A6 — Test sync.** No tests yet — concept-stage. Becomes
  meaningful post-implementation.

## Test-coverage notes

No test infrastructure yet. Pending:

- Attack-surface enumeration document (next deliverable).
- Architectural design pass (formalising the Lyapunov-spectrum
  residue audit, the resolution-bounded security claim, the
  chaos-guard, and the sensor-coupling potential field).
- Then language-track choices and lockfiled build infrastructure
  (Haskell + Lean 4 mirroring the triadic-coordination-engine
  pattern).
- Then property tests / example tests / benchmarks as appropriate
  per spec entry.
