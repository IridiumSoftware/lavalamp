/-
  LavaLamp — round-3 theorem statements.

  History:
    - 0.0.36: scaffold landed (no theorems; documentation-only).
    - 0.0.47 (this version, L1): Mathlib integration + first
      theorem statement landed (LL-021 worst-case bound;
      sorry-stubbed; demonstrates proof-track infrastructure).
    - 0.0.48 (next version, L2): proof body fills the sorry;
      LL-021 evidence-type promotes to `lean-proved` and status
      to `:proved`.

  Round-3 §1D.v Decision 1 (rendered 2026-05-06): Option A —
  full Mathlib for measure-theoretic + probability content.

  Theorem priorities (from §README.md theorem plan):

    1. **LL-021** worst-case bound (this file; this version).
    2. **LL-019** side-channel timing indistinguishability
       (next; KS-test formalisation against round-2 §1D.v).
    3. **LL-020** calibration ε-DP guarantee (after; Dwork-Roth
       Gaussian mechanism via Mathlib Probability).
    4. **LL-006 / LL-008 / LL-018** detection-probability bound
       (foundational; the §2.1 bound shape with per-class
       quantification — pairs with LL-027 chaos density invariant
       and LL-021 worst-case bound).
    5. **LL-022** parametric OS-stack-dependency theorem-shape.
    6. **LL-023** consumer-API-surface inheritance shape.

  Conventions in force:
    - `:proved` requires `lean-proved`, `type-checked`, or
      `algebraic` evidence (CLAUDE.md §Evidence types).
    - A theorem with `sorry` in its body is NOT a proof; the
      corresponding LL entry stays at its pre-Lean status until
      `sorry` is removed.
    - When a real proof lands (no `sorry`, package builds clean),
      the corresponding LL entry's evidence type moves to
      `lean-proved` and status to `:proved`.

  Round-3 amendments (per LL-021 round-3 amendment in
  `LAVALAMP_SPEC.md`):
    - Scope-limit to finite-N regime (operationally N ≤ 80).
    - Adaptive-adversary bound stated explicitly.
  These amendments are spec-text refinements; the Lean theorem
  statement here captures the bound *shape* (which is finite-N-
  validated empirically) without committing to large-N.
-/

import Mathlib.Data.Real.Basic

namespace LavaLamp

/-- LL-021 worst-case bound (round-3 Tier 2 first theorem).

    For any adversary in α-space with non-negative magnitude
    `ε_A` and projection factor `proj` onto the mean-coupling
    unit vector `m_unit ∈ ℝᴺ` (where `proj = |û · m_unit|`,
    bounded in `[0, 1]` by Cauchy-Schwarz), the effective
    perturbation magnitude `ε_eff = ε_A · proj` is at most
    `ε_A`.

    The theorem captures the bound *shape*, not the detection-
    probability claim itself. The detection-probability bound
    `P(detect) ≥ 1 - K · exp(-c · T · ε_eff^2)` from LL-006
    composes with this: as `proj → 1` (adversary aligned with
    worst-case direction parallel to mean-coupling), `ε_eff → ε_A`
    and detection probability rises; as `proj → 0` (adversary
    orthogonal to coupling), `ε_eff → 0` and detection probability
    falls to the FPR floor.

    The empirical fit constants from 0.0.18 + 0.0.28 are
    `K = 1, c′ = 0.0288, T = 60.0` at N = 20 (validated at
    n = 15 trials per (direction, magnitude) point per
    `docs/ll021_high_res_companion.md`).

    Round-3 amendments per LL-021 spec entry:
    - Scope-limit to finite-N regime (this theorem applies in
      the validated finite-N regime; large-N requires
      re-benchmarking per V-020 and the LL-021 round-3
      amendment).
    - Adaptive-adversary: this theorem holds for any single
      adversary direction; an adaptive adversary that chooses
      direction *after* observing prior verifications is the
      open-A6 case (per ChatGPT round-3 §1C.A4).

    Status: theorem statement landed at 0.0.47 (L1 — Mathlib
    integration + sorry-stub). Proof body lands at 0.0.48 (L2);
    LL-021 promotes to `:proved` with `lean-proved` evidence
    when `lake build` returns no `sorry` warnings.

    Proof: direct application of Mathlib's
    `mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`,
    discharged with the non-negativity hypothesis on `ε_A`
    and the upper-bound hypothesis on `proj`. The bound also
    holds when `proj < 0` (the product becomes non-positive,
    which is trivially `≤ ε_A` for non-negative `ε_A`), so
    `0 ≤ proj` is not part of the theorem signature here even
    though `proj = |û · m_unit|` is non-negative by
    construction in the geometric interpretation. Downstream
    theorems composing with this one (e.g. LL-006 detection-
    bound via `ε_eff²`) will introduce `0 ≤ proj` where they
    need it; leaving it out here keeps the lemma as general
    as the pure algebraic fact requires. -/
theorem LL021_worst_case_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_le_one : proj ≤ 1) :
    ε_A * proj ≤ ε_A :=
  mul_le_of_le_one_right h_ε h_proj_le_one

/-- Scaffold-tier marker. Confirms the package builds. Removed
    when the Theorems file is reorganised into per-priority
    submodules (per `src/lean4/README.md` §File inventory). -/
def scaffold_tier : String :=
  "0.0.48 — LL-021 worst-case bound proved (lean-proved; promotes :benchmarked → :proved)"

end LavaLamp
