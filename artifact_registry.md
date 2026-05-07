# artifact_registry.md — LavaLamp

Version: 0.0.54 (LL-021/LL-006 composition theorem `LL006_worst_case_lower_than_isotropic` lands in `src/lean4/LavaLamp/Theorems.lean`; proves worst-case bound value `1 - K · exp(-c·T·(ε_A·proj)²) ≤ 1 - K · exp(-c·T·ε_A²)` via `LL021_eff_squared_bound` + `Real.exp` monotonicity + `linarith`; `Mathlib.Analysis.SpecialFunctions.Exp` import added; `lake build` clean (1901 jobs, zero warnings); LL-006 stays `:benchmarked` — composition theorem proves bound-shape monotonicity, not the full probability-space `P(detect) ≥ ...` lower bound; second composition foothold after `LL021_eff_squared_bound` (0.0.49); counts unchanged at 29/1/3/0/4/20/1; 2026-05-06)
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
| LL-006 | Lyapunov-spectrum residue audit | Core | benchmarked | src/julia/benchmark/p3_bound_high_res.jl + src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt + docs/p3_bound_companion.md + src/julia/benchmark/p3f_per_sde_detection_power.jl + src/julia/benchmark/results/p3f_per_sde_detection_power.txt + docs/p3f_per_sde_detection_power_companion.md (per-SDE detection-power across Lorenz-96 / Lorenz-63 / Rössler) + src/lean4/LavaLamp/Theorems.lean (0.0.54 — LL-021/LL-006 composition theorem `LL006_worst_case_lower_than_isotropic` proves bound-shape monotonicity; does NOT promote evidence-type, full P(detect) probability formalization is a future multi-session investment) | src/julia/src/Audit.jl | :benchmarked |
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
| LL-021 | worst-case-adversary-bound (structured directions, not isotropic) | Core | lean-proved | src/lean4/LavaLamp/Theorems.lean (0.0.48 L2 — `LL021_worst_case_bound` proved by `mul_le_of_le_one_right`; 0.0.49 — companion lemma `LL021_eff_squared_bound` for `(ε_A · proj)² ≤ ε_A²` via `pow_le_pow_left₀`, composition foothold for LL-006 detection-bound; `lake build` clean with zero warnings) + src/julia/benchmark/p_r2c_structured_adversary.jl + src/julia/benchmark/results/p_r2c_structured_lorenz96.txt + docs/ll021_benchmarked_companion.md + src/julia/benchmark/p_r2c_structured_adversary_high_res.jl + src/julia/benchmark/results/p_r2c_structured_high_res_lorenz96.txt + docs/ll021_high_res_companion.md (empirical fit-constant content K=1, c′=0.0288, T=60 at N=20 preserved as operational deployment-fit detail) | src/julia/src/Audit.jl | :proved |

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
| LL-028 | runtime-conformance-verification | Boundary | manual | docs/synthesis_team_round3_companion.md §1C.A3 + docs/attack_surface_enumeration.md §3 V-019 (deployment-stack triple specifies what must hold; LL-028 specifies how to verify it holds at runtime; four conformance requirements: attestation continuity / sensor cross-validation with adversarial probes / verifier-side LL-023 API probing / continuous TRNG attestation; `:tested` upgrade gated by P-RS Level 2 prototype's conformance-check module) | — | :argued |
| LL-029 | multi-channel-entropy-independence | Operational | manual | docs/synthesis_team_round3_companion.md §1C.A2 + docs/attack_surface_enumeration.md §3 V-018 (cross-validation requires physical-mechanism diversity, not just sensor diversity; seven-family taxonomy: thermal / acoustic / EM / electrical / optical / entropy-source-decay / quantum; calibration-window correlation test `|ρ| > 0.3` over 60s flags same-family pairs; `:tested` upgrade gated by P-RS Level 2 sensor architecture) | — | :argued |

---

## Counts (must match LAVALAMP_SPEC.md and dashboard.md)

- Total: 29 (+LL-028 +LL-029 from round-3 Tier 3 spec landing
  at 0.0.50)
- `:proved`: 1 (LL-021 — first-ever; promoted at 0.0.48 L2)
- `:tested`: 3
- `:verified`: 0
- `:benchmarked`: 4
- `:argued`: 20 (+LL-028 +LL-029)
- `:open`: 1

## Cross-audit A1–A6 self-check (post-0.0.54)

- **A1 — Coverage.** Every LL-ID in `LAVALAMP_SPEC.md` has a row
  here. ✓ (29 of 29; +LL-028 +LL-029 added at 0.0.50).
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
  entries carry `none`; the single `:proved` entry (LL-021)
  carries `lean-proved`. ✓. LL-021 promotes 0.0.48 backed by
  the Lean 4 + Mathlib v4.29.1 proof in
  `src/lean4/LavaLamp/Theorems.lean`; `lake build` returns
  767 jobs green with zero `sorry` warnings — the kernel
  verified the proof at compile time. No entry has a status
  its evidence type cannot support; CLAUDE.md §Honest framing
  rule (`:proved` requires `lean-proved`, `type-checked`, or
  `algebraic`) is satisfied.
- **A5 — Stale counts.** Counts above (29 / 1 / 3 / 0 / 4 /
  20 / 1) match `LAVALAMP_SPEC.md` 0.0.50 final-section counts
  and `dashboard.md` 0.0.50 spec-status section. **Counts
  shifted at 0.0.50** — round-3 Tier 3 spec landing added
  LL-028 (runtime-conformance-verification, Boundary,
  `:argued`) + LL-029 (multi-channel-entropy-independence,
  Operational, `:argued`); total 27 → 29; `:argued` 18 → 20;
  others unchanged. LL-019 deployment-context expansion is a
  notes-amendment to the existing LL-019 entry — status
  unchanged at `:benchmarked`, no row addition. **`:tested`
  upgrade path for both new entries:** sequenced by P-RS
  Level 2 prototype availability per round-3 §1D.viii — the
  spec entries land now (architecture-design tier);
  engineering implementation lands later when P-RS Level 2
  is built.
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
  **0.0.50:** LL-028 + LL-029 have no test/proof file beyond
  the round-3 companion + attack-surface enumeration —
  deferred operational/engineering work; sequenced by P-RS
  Level 2 prototype availability per round-3 §1D.viii.
  Implementation hooks: LL-028 needs a conformance-check
  module exercising the four runtime-verification
  requirements; LL-029 needs the registration-flow
  correlation test + per-platform physical-mechanism-family
  enumeration.
  **0.0.47:** the Lean track at `src/lean4/` enters CI via
  `.github/workflows/lean.yml` (`lake build` on every push;
  Mathlib v4.29.1 cache via `lake exe cache get`; timeout
  bumped 15 → 60 minutes for first-build-on-fresh-runner).
  At L1 the build is "clean modulo a single expected `sorry`
  warning on `LL021_worst_case_bound`". **0.0.48 (L2):** the
  `sorry` warning is gone; `lake build` returns 767 jobs
  green with zero warnings. CI now functions as a real
  correctness check on the Lean proof — any future change
  that breaks `LL021_worst_case_bound` will fail the build.

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
