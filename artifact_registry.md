# artifact_registry.md — LavaLamp

Version: 0.0.47 (synthesis-team round 3 Lean L1; Mathlib v4.29.1 integrated at `src/lean4/`; toolchain bumped v4.18.0 → v4.29.1; LL-021 Lean theorem-statement landed sorry-stubbed at `LavaLamp/Theorems.lean` (status stays `:benchmarked` — a sorry-stub is not a proof); CI `.github/workflows/lean.yml` timeout-minutes 15 → 60 to absorb the Mathlib cache window; counts unchanged 27/0/3/0/5/18/1; 2026-05-06)
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
| LL-001 | substrate-bound identity primitive | Core | manual | docs/spec_closure_pass_companion.md §1 | — | :argued |
| LL-002 | visual ↔ security decoupling invariant | Core | example-tested | src/julia/test/runtests.jl (Visual layer decoupling testset; 45 assertions) + docs/spec_closure_pass_companion.md §2 + visual/README.md | visual/lavalamp.js + visual/index.html + visual/style.css | :tested |
| LL-003 | single-attractor chaotic engine | Core | benchmarked | src/julia/benchmark/p3d_sde_selection.jl + src/julia/benchmark/results/p3d_sde_selection.txt + docs/p3d_sde_selection_companion.md (Lorenz-96 dominates Lorenz-63 / Rössler) + src/julia/benchmark/p3e_n_scaling.jl + src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt + docs/p3e_n_scaling_companion.md (linear extensive-chaos scaling confirmed; Lyapunov density s ≈ 0.255 per dimension) | src/julia/src/Engine.jl | :benchmarked |
| LL-004 | continuous sensor coupling | Core | example-tested | src/julia/test/runtests.jl | src/julia/src/Sensors.jl + src/julia/src/Engine.jl | :tested |
| LL-005 | sensor Nyquist condition | Core | manual | docs/architecture_design_companion.md §2.4, §3.6 + src/julia/test/runtests.jl (Nyquist compliance predicate testset, LL-005 part-(a) only) + docs/ll005_part_a_companion.md | src/julia/src/Sensors.jl (`nyquist_compliant`) | :argued |

## Detection / verification

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-006 | Lyapunov-spectrum residue audit | Core | benchmarked | src/julia/benchmark/p3_bound_high_res.jl + src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt + docs/p3_bound_companion.md + src/julia/benchmark/p3f_per_sde_detection_power.jl + src/julia/benchmark/results/p3f_per_sde_detection_power.txt + docs/p3f_per_sde_detection_power_companion.md (per-SDE detection-power across Lorenz-96 / Lorenz-63 / Rössler) | src/julia/src/Audit.jl | :benchmarked |
| LL-007 | chaos-guard | Operational | example-tested | src/julia/test/runtests.jl | src/julia/src/ChaosGuard.jl | :tested |
| LL-008 | resolution-bounded security claim | Core | manual | docs/architecture_design_companion.md §2.2, §3.2 | — | :argued |

## Boundary constraints

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-009 | no complex numbers in security math | Boundary | manual | docs/spec_closure_pass_companion.md §3 | — | :argued |
| LL-010 | no open-ended simulation | Boundary | manual | docs/spec_closure_pass_companion.md §4 | — | :argued |

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
| LL-019 | side-channel hardening (reseed timing + audit-on-verify) | Core | benchmarked | src/julia/test/runtests.jl + src/julia/benchmark/results/ll019_timing_distribution.txt + docs/ll019_benchmarked_companion.md + src/julia/benchmark/ll019_timing_distribution_high_res.jl + src/julia/benchmark/results/ll019_timing_distribution_high_res.txt + docs/ll019_high_res_companion.md (regime-boundary at α=0.01/n=2000) | src/julia/src/Audit.jl | :benchmarked |
| LL-020 | calibration confidentiality (envelope sealed against observers) | Core | manual | docs/p_r2b_calibration_confidentiality_companion.md §2 + docs/ll020_strategy_2_epsilon_dp_companion.md (Strategy 2 example-tested) + docs/ll020_strategy_2_benchmarked_companion.md (Strategy 2 :benchmarked-tier; variance-convolution σ refinement) + src/julia/benchmark/results/ll020_strategy_2_detection_power_lorenz96.txt + docs/audit_2026-05-04.md | src/julia/src/Audit.jl (Strategy 2 only) | :argued |
| LL-021 | worst-case-adversary-bound (structured directions, not isotropic) | Core | benchmarked | src/julia/benchmark/p_r2c_structured_adversary.jl + src/julia/benchmark/results/p_r2c_structured_lorenz96.txt + docs/ll021_benchmarked_companion.md + src/julia/benchmark/p_r2c_structured_adversary_high_res.jl + src/julia/benchmark/results/p_r2c_structured_high_res_lorenz96.txt + docs/ll021_high_res_companion.md (n=15 refresh; c′=0.0288) + src/lean4/LavaLamp/Theorems.lean (0.0.47 L1 — sorry-stubbed `LL021_worst_case_bound`; does NOT promote evidence-type; proof body lands 0.0.48) | src/julia/src/Audit.jl | :benchmarked |

## Surfaced by P-OS OS-level scoping pass (0.0.26)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-022 | OS-trust-stack-dependency | Boundary | manual | docs/os_identity_security_scoping_companion.md §2 | — | :argued |

## Surfaced by P-PharOS scoping pass (0.0.34)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-023 | consumer-API-surface | Boundary | manual | docs/pharos_scoping_companion.md §2 | — | :argued |

## Surfaced by P-RS real-sensor scoping pass (0.0.38)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-024 | real-sensor-deployment-strategy | Operational | manual | docs/p_real_sensor_scoping_companion.md §2 + src/julia/test/runtests.jl (Real-sensor scaffold testset; 18 assertions) | src/julia/src/RealSensors.jl (scaffold tier) | :argued |

## Surfaced by synthesis-team round 3 (0.0.45+)

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-025 | A7-passive-emanation-boundary | Boundary | manual | docs/synthesis_team_round3_companion.md §1B.Q7 + §1C.A7 + docs/attack_surface_enumeration.md §3 V-014 | — | :argued |
| LL-026 | three-layer-logic-tier-annotation-discipline | Core | manual | docs/synthesis_team_round3_companion.md §1B.Q1 + §1C.A6 + docs/attack_surface_enumeration.md §3 V-017 | — | :argued |
| LL-027 | asymptotic-Lyapunov-density-invariant | Core | benchmarked | src/julia/benchmark/p3e_n_scaling.jl + src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt + docs/p3e_n_scaling_companion.md (linear extensive-chaos scaling; `s ≈ 0.255` per dimension) | src/julia/src/Engine.jl | :benchmarked |

---

## Counts (must match LAVALAMP_SPEC.md and dashboard.md)

- Total: 27
- `:proved`: 0
- `:tested`: 3
- `:verified`: 0
- `:benchmarked`: 5
- `:argued`: 18
- `:open`: 1

## Cross-audit A1–A6 self-check (post-0.0.47)

- **A1 — Coverage.** Every LL-ID in `LAVALAMP_SPEC.md` has a row
  here. ✓ (27 of 27).
- **A2 — Key match.** Spec → registry keys are identical. ✓.
  LL-025 / LL-026 / LL-027 registry keys match spec keys
  (`A7-passive-emanation-boundary`, `three-layer-logic-tier-
  annotation-discipline`, `asymptotic-Lyapunov-density-
  invariant`).
- **A3 — Evidence exists.** Nine entries cite
  `docs/architecture_design_companion.md`; four entries
  (LL-003, LL-004, LL-006, LL-007) cite
  `src/julia/test/runtests.jl` as their test file with source
  files in `src/julia/src/`. LL-022 cites
  `docs/os_identity_security_scoping_companion.md`. LL-025 +
  LL-026 cite `docs/synthesis_team_round3_companion.md` plus
  `docs/attack_surface_enumeration.md` (V-014 for LL-025;
  V-017 for LL-026). LL-027 cites
  `src/julia/benchmark/p3e_n_scaling.jl` +
  `src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt` +
  `docs/p3e_n_scaling_companion.md` (the 0.0.30 N-scaling
  result is the empirical evidence for the deployment-
  invariant density claim). All cited paths exist in
  `git ls-files` after this commit.
- **A4 — Status honesty.** All `:argued` entries carry `manual`;
  all `:tested` entries carry `example-tested`; all
  `:benchmarked` entries carry `benchmarked`; all `:open`
  entries carry `none`. ✓. LL-025 + LL-026 are `:argued` with
  `manual` evidence; LL-027 is `:benchmarked` with
  `benchmarked` evidence (the 0.0.30 P3e benchmark fits the
  invariant). No entry has a status its evidence type cannot
  support.
- **A5 — Stale counts.** Counts above (27 / 0 / 3 / 0 / 5 /
  18 / 1) match `LAVALAMP_SPEC.md` 0.0.47 final-section counts
  and `dashboard.md` 0.0.47 spec-status section. Counts
  **unchanged from 0.0.46** — the L1 Mathlib integration +
  LL-021 sorry-stubbed theorem-statement landing does not
  promote evidence-type or status (sorry-stub ≠ proof per
  CLAUDE.md §Honest framing); LL-021 stays `:benchmarked`.
  L2 (next version, 0.0.48) replaces `sorry` with a real
  proof, at which point LL-021 evidence-type promotes to
  `lean-proved` and status to `:proved` (counts shift
  27/0/3/0/5/18/1 → 27/1/3/0/4/18/1).
- **A6 — Test sync.** LL-002, LL-003, LL-004, LL-005 (part-
  (a) only), LL-006, LL-007 are exercised by
  `src/julia/test/runtests.jl`, runnable via `Pkg.test()`
  from `src/julia/`; 202/202 assertions pass in ~53 s
  (unchanged from 0.0.38; round-3 Tier 1 + Tier 2 add no
  new code or tests — spec / governance only). LL-027's
  empirical evidence is the existing 0.0.30 P3e benchmark
  result file (no new test required). LL-025 has no
  test/proof file beyond the companions and attack-surface
  enumeration (deferred operational-tooling work). LL-026 is
  governance discipline; no runtime test artifact applies.
  **0.0.47:** the Lean track at `src/lean4/` enters CI via
  `.github/workflows/lean.yml` (`lake build` on every push;
  Mathlib v4.29.1 cache via `lake exe cache get`; timeout
  bumped 15 → 60 minutes for first-build-on-fresh-runner).
  At L1 the build is "clean modulo a single expected `sorry`
  warning on `LL021_worst_case_bound`"; once L2 lands the
  warning disappears and `lake build` becomes a real
  correctness check.

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
