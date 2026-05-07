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
      `algebraic` evidence per the project's evidence-type
      discipline.
    - A theorem with `sorry` in its body is NOT a proof; the
      corresponding LL entry stays at its pre-Lean status until
      `sorry` is removed.
    - When a real proof lands (no `sorry`, package builds clean),
      the corresponding LL entry's evidence type moves to
      `lean-proved` and status to `:proved`.

  Round-3 amendments to LL-021:
    - Scope-limit to finite-N regime (operationally N ≤ 80).
    - Adaptive-adversary bound stated explicitly.
  These amendments are spec-text refinements; the Lean theorem
  statement here captures the bound *shape* (which is finite-N-
  validated empirically) without committing to large-N.
-/

import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

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
    n = 15 trials per (direction, magnitude) point).

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

/-- LL-021 squared-effective-magnitude bound — composition foothold
    for LL-006 detection-probability bound (round-3 §1D.v priority 4).

    Given `0 ≤ ε_A`, `0 ≤ proj`, and `proj ≤ 1`, the squared
    effective magnitude `(ε_A · proj)² = ε_eff²` is bounded by
    `ε_A²`. This is the algebraic step that connects LL-021's
    worst-case-direction bound to LL-006's detection-probability
    bound shape `P(detect) ≥ 1 - K · exp(-c · T · ε_eff²)`:
    monotonicity of `t ↦ exp(-c · T · t)` (decreasing in `t` for
    `c · T > 0`) means `ε_eff² ≤ ε_A²` implies
    `exp(-c · T · ε_eff²) ≥ exp(-c · T · ε_A²)`, so the
    detection-probability bound at the worst-case direction is
    *lower* than at the isotropic ε_A — which is exactly LL-021's
    structural claim ("the bound shape is right; the worst-case
    direction makes detection harder, not easier").

    Unlike `LL021_worst_case_bound`, this lemma genuinely needs
    `0 ≤ proj` — without it, `ε_A * proj` could be negative, and
    while the *square* is still non-negative, we'd lose the
    monotone-squaring step `0 ≤ a ≤ b → a² ≤ b²` that
    `pow_le_pow_left` provides directly. Future call sites
    (e.g. `LL006_detection_bound_worst_case`) will pass the
    geometric `proj = |û · m_unit| ≥ 0` hypothesis here.

    Proof: `pow_le_pow_left₀` over `0 ≤ ε_A * proj` (from
    `mul_nonneg`) and `ε_A * proj ≤ ε_A` (from
    `LL021_worst_case_bound`). The `₀` subscript distinguishes
    the `GroupWithZero` variant of the monotone-pow lemma in
    Mathlib v4.29.1; the unsubscripted `pow_le_pow_left` is
    the ordered-monoid form which `ℝ` does not directly hit. -/
theorem LL021_eff_squared_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_nn : 0 ≤ proj)
    (h_proj_le_one : proj ≤ 1) :
    (ε_A * proj) ^ 2 ≤ ε_A ^ 2 :=
  pow_le_pow_left₀
    (mul_nonneg h_ε h_proj_nn)
    (LL021_worst_case_bound h_ε h_proj_le_one)
    2

/-- LL-006 worst-case-detection-bound monotonicity — the LL-021/LL-006
    composition theorem (round-3 §1D.v priority 4 partial).

    The detection-probability bound shape from LL-006 is
    `P(detect) ≥ 1 - K · exp(-c · T · δ²)`. LL-021 says the
    *effective* perturbation magnitude at the worst-case
    direction is `δ = ε_eff = ε_A · proj` rather than the
    isotropic `ε_A`. This theorem composes the two: at the
    worst-case direction, the bound's lower-confidence value
    `1 - K · exp(-c · T · ε_eff²)` is *less than* the
    isotropic bound's value `1 - K · exp(-c · T · ε_A²)`.

    Operationally: the worst-case detection probability is
    *lower* than the isotropic detection probability — which
    is exactly the structural asymmetry claim LL-021 makes
    against LL-006. The empirical fit constants
    (`K=1, c′=0.0288, T=60`) are LL-021's `:benchmarked`
    content; this theorem proves the *monotonicity* of the
    bound shape independent of those constants.

    Hypotheses:
    - `0 ≤ ε_A` (non-negative magnitude; from LL-006
      formulation).
    - `0 ≤ proj`, `proj ≤ 1` (`proj = |û · m_unit|` lives in
      [0, 1] by Cauchy-Schwarz; LL-021 geometric setup).
    - `0 ≤ K` (bound prefactor non-negative; bound holds
      trivially when `K = 0`).
    - `0 ≤ c * T` (composite rate-times-window non-negative;
      true whenever both `c` and `T` are non-negative — `c`
      is the bound's exponent rate from the §2.1 derivation,
      `T` is the observation-window length).

    Conclusion: the worst-case bound value is `≤` the
    isotropic bound value.

    Proof structure:
    1. `(ε_A * proj)² ≤ ε_A²` from `LL021_eff_squared_bound`.
    2. `-(c·T) · ε_A² ≤ -(c·T) · (ε_A·proj)²` by multiplying
       step 1 by the non-positive scalar `-(c·T)`
       (`mul_le_mul_of_nonpos_left`).
    3. `Real.exp` monotonicity: step 2 implies
       `Real.exp(-(c·T)·ε_A²) ≤ Real.exp(-(c·T)·(ε_A·proj)²)`.
    4. Multiply by `K ≥ 0` (preserves inequality direction).
    5. Subtract from `1` (flips inequality direction once).

    LL-006 status implication: the theorem proves a *property*
    of the bound shape (worst-case ≤ isotropic), not the bound
    itself. LL-006's `:benchmarked` status is unchanged at
    0.0.54; promoting to `:proved` requires the full
    probability-space formalization (random variables,
    detection event predicate, the `P(detect) ≥ ...` lower
    bound itself), which is a multi-session research
    investment. This theorem demonstrates that LL-021's
    asymmetry claim against LL-006 is *mathematically
    derivable* (not just empirically observed) from the bound
    shape. -/
theorem LL006_worst_case_lower_than_isotropic
    {ε_A proj K c T : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_nn : 0 ≤ proj)
    (h_proj_le_one : proj ≤ 1)
    (h_K_nn : 0 ≤ K)
    (h_cT_nn : 0 ≤ c * T) :
    1 - K * Real.exp (-(c * T) * (ε_A * proj) ^ 2)
      ≤ 1 - K * Real.exp (-(c * T) * ε_A ^ 2) := by
  have h_sq : (ε_A * proj) ^ 2 ≤ ε_A ^ 2 :=
    LL021_eff_squared_bound h_ε h_proj_nn h_proj_le_one
  have h_neg_cT : -(c * T) ≤ 0 := neg_nonpos.mpr h_cT_nn
  have h_neg : -(c * T) * ε_A ^ 2 ≤ -(c * T) * (ε_A * proj) ^ 2 :=
    mul_le_mul_of_nonpos_left h_sq h_neg_cT
  have h_exp : Real.exp (-(c * T) * ε_A ^ 2)
                 ≤ Real.exp (-(c * T) * (ε_A * proj) ^ 2) :=
    Real.exp_le_exp.mpr h_neg
  have h_mul : K * Real.exp (-(c * T) * ε_A ^ 2)
                 ≤ K * Real.exp (-(c * T) * (ε_A * proj) ^ 2) :=
    mul_le_mul_of_nonneg_left h_exp h_K_nn
  linarith

/-- LL-006 detection-bound upper-range — the bound value never exceeds 1.

    For the LL-006 detection-probability bound shape
    `1 - K · exp(-(c · T) · δ²)` to make sense as a *lower
    bound* on a probability, the bound value must itself sit
    in `[0, 1]` — otherwise `P(detect) ≥ <bound value>` is
    either vacuous (bound < 0) or structurally meaningless
    (bound > 1).

    This theorem establishes the upper-range half: given only
    `0 ≤ K`, the bound is `≤ 1`. (No constraint on `c`, `T`,
    or `δ` is needed — `Real.exp` is always positive, so the
    `K · exp(...)` term is always non-negative when `K ≥ 0`,
    and subtracting a non-negative quantity from `1` gives
    something `≤ 1`.) Pairs with `LL006_bound_nonneg` below
    to establish the bound is a valid probability. -/
theorem LL006_bound_le_one
    {δ K c T : ℝ}
    (h_K_nn : 0 ≤ K) :
    1 - K * Real.exp (-(c * T) * δ ^ 2) ≤ 1 := by
  have h_exp_pos : 0 < Real.exp (-(c * T) * δ ^ 2) := Real.exp_pos _
  have : 0 ≤ K * Real.exp (-(c * T) * δ ^ 2) :=
    mul_nonneg h_K_nn h_exp_pos.le
  linarith

/-- LL-006 detection-bound lower-range — the bound value is non-negative.

    Pairs with `LL006_bound_le_one` to establish the bound is
    in `[0, 1]`. Requires three hypotheses:
    - `0 ≤ K` (prefactor non-negative).
    - `K ≤ 1` (prefactor at most 1; without this, `K = 5` for
      example would push the bound below zero even at `δ = 0`).
    - `0 ≤ c · T` (composite rate-times-window non-negative —
      same hypothesis as `LL006_worst_case_lower_than_isotropic`).

    Proof structure:
    1. `0 ≤ (c · T) · δ²` from `0 ≤ c·T` and `0 ≤ δ²`
       (`mul_nonneg` + `sq_nonneg`).
    2. `-(c · T) · δ² ≤ 0` (negation of step 1).
    3. `Real.exp (-(c · T) · δ²) ≤ Real.exp 0 = 1`
       (`Real.exp_le_exp.mpr` + `Real.exp_zero`).
    4. `K · Real.exp(...) ≤ K · 1 = K ≤ 1`
       (`mul_le_mul_of_nonneg_left` + `K ≤ 1` hypothesis).
    5. `1 - K · Real.exp(...) ≥ 0` by subtraction.

    The `K ≤ 1` hypothesis matches the LL-006 spec entry's
    fitted constant `K = 1` — the bound is calibrated for
    `K = 1` (saturation of the bound prefactor); the
    formalisation accepts any `K` in `[0, 1]` for generality. -/
theorem LL006_bound_nonneg
    {δ K c T : ℝ}
    (h_K_nn : 0 ≤ K)
    (h_K_le_one : K ≤ 1)
    (h_cT_nn : 0 ≤ c * T) :
    0 ≤ 1 - K * Real.exp (-(c * T) * δ ^ 2) := by
  have h_sq_nn : 0 ≤ δ ^ 2 := sq_nonneg δ
  have h_prod_nn : 0 ≤ (c * T) * δ ^ 2 := mul_nonneg h_cT_nn h_sq_nn
  have h_neg_le : -(c * T) * δ ^ 2 ≤ 0 := by linarith
  have h_exp_le_one : Real.exp (-(c * T) * δ ^ 2) ≤ 1 := by
    have h := Real.exp_le_exp.mpr h_neg_le
    rwa [Real.exp_zero] at h
  have h_mul : K * Real.exp (-(c * T) * δ ^ 2) ≤ K * 1 :=
    mul_le_mul_of_nonneg_left h_exp_le_one h_K_nn
  linarith

/-- Scaffold-tier marker. Confirms the package builds. Removed
    when the Theorems file is reorganised into per-priority
    submodules (per `src/lean4/README.md` §File inventory). -/
def scaffold_tier : String :=
  "0.0.55 — LL-006 detection-bound range theorems landed (bound ∈ [0,1])"

end LavaLamp
