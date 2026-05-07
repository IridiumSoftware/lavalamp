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
import Mathlib.Order.Filter.AtTopBot.Field

open Filter

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

/-- LL-006 detection-bound monotonicity in squared adversary
    magnitude — stronger adversary makes detection easier.

    For fixed `K ≥ 0`, `c · T ≥ 0`, the bound value
    `1 - K · exp(-(c · T) · s)` is monotone non-decreasing in
    the squared-magnitude argument `s`. Operationally: a larger
    adversary perturbation (larger `δ²`) produces a higher
    detection-probability lower bound — the LL-006 statement's
    "stronger adversary → tighter detection bound" structural
    claim made formal.

    Statement uses `s` directly rather than `δ^2` because the
    monotonicity holds for any reals `s₁ ≤ s₂` (the sign of `s`
    isn't part of the monotonicity claim). The
    `LL006_bound_nonneg` theorem above takes `s = δ^2 ≥ 0` as
    its case where the bound is also `≥ 0`; this monotonicity
    theorem is the orthogonal axis.

    Proof structure (mirrors `LL006_worst_case_lower_than_isotropic`):
    1. `-(c · T) ≤ 0` from `0 ≤ c·T`.
    2. Multiplying `s₁ ≤ s₂` by the non-positive scalar
       `-(c · T)` flips: `-(c·T) · s₂ ≤ -(c·T) · s₁`
       (`mul_le_mul_of_nonpos_left`).
    3. `Real.exp` monotonicity lifts step 2.
    4. Multiplying by `K ≥ 0` preserves direction.
    5. Subtract from `1` (flips once); `linarith` closes. -/
theorem LL006_bound_monotone_in_squared_magnitude
    {s₁ s₂ K c T : ℝ}
    (h_K_nn : 0 ≤ K)
    (h_cT_nn : 0 ≤ c * T)
    (h_s_le : s₁ ≤ s₂) :
    1 - K * Real.exp (-(c * T) * s₁)
      ≤ 1 - K * Real.exp (-(c * T) * s₂) := by
  have h_neg_cT : -(c * T) ≤ 0 := neg_nonpos.mpr h_cT_nn
  have h_inner : -(c * T) * s₂ ≤ -(c * T) * s₁ :=
    mul_le_mul_of_nonpos_left h_s_le h_neg_cT
  have h_exp : Real.exp (-(c * T) * s₂) ≤ Real.exp (-(c * T) * s₁) :=
    Real.exp_le_exp.mpr h_inner
  have h_mul : K * Real.exp (-(c * T) * s₂) ≤ K * Real.exp (-(c * T) * s₁) :=
    mul_le_mul_of_nonneg_left h_exp h_K_nn
  linarith

/-- LL-006 detection-bound monotonicity in observation window T —
    longer observation makes detection easier.

    For fixed `K ≥ 0`, `c ≥ 0`, and any squared-magnitude
    argument `s ≥ 0` (default LL-006 statement uses `s = δ^2`,
    automatically non-negative), the bound value
    `1 - K · exp(-(c · T) · s)` is monotone non-decreasing in
    the observation window `T`. Operationally: doubling the
    observation duration tightens the detection bound — the
    LL-006 statement's "longer observation → tighter detection
    bound" structural claim made formal.

    Hypotheses:
    - `0 ≤ K` (prefactor non-negative).
    - `0 ≤ c` (exponent rate non-negative; bound calibration
      gives `c′ > 0`).
    - `0 ≤ s` (squared-magnitude argument non-negative; for
      the default `s = δ²` case this is automatic via
      `sq_nonneg`).
    - `T₁ ≤ T₂` (the monotonicity claim's argument).

    Proof structure:
    1. `c · T₁ · s ≤ c · T₂ · s` from `T₁ ≤ T₂` and
       `0 ≤ c`, `0 ≤ s` (two applications of
       `mul_le_mul_of_nonneg_*`).
    2. Negate: `-(c · T₂) · s ≤ -(c · T₁) · s` via `nlinarith`
       (handles the product rearrangement).
    3. `Real.exp` monotonicity lifts step 2.
    4. Multiply by `K ≥ 0` preserves direction.
    5. Subtract from `1`; `linarith` closes.

    Note `T₁` and `T₂` may be negative — the monotonicity
    claim is purely about ordering. Operationally, observation
    windows are positive; this generality costs nothing. -/
theorem LL006_bound_monotone_in_T
    {s K c T₁ T₂ : ℝ}
    (h_K_nn : 0 ≤ K)
    (h_c_nn : 0 ≤ c)
    (h_s_nn : 0 ≤ s)
    (h_T_le : T₁ ≤ T₂) :
    1 - K * Real.exp (-(c * T₁) * s)
      ≤ 1 - K * Real.exp (-(c * T₂) * s) := by
  have h_cT_le : c * T₁ ≤ c * T₂ := mul_le_mul_of_nonneg_left h_T_le h_c_nn
  have h_inner_pos : c * T₁ * s ≤ c * T₂ * s :=
    mul_le_mul_of_nonneg_right h_cT_le h_s_nn
  have h_inner : -(c * T₂) * s ≤ -(c * T₁) * s := by nlinarith [h_inner_pos]
  have h_exp : Real.exp (-(c * T₂) * s) ≤ Real.exp (-(c * T₁) * s) :=
    Real.exp_le_exp.mpr h_inner
  have h_mul : K * Real.exp (-(c * T₂) * s) ≤ K * Real.exp (-(c * T₁) * s) :=
    mul_le_mul_of_nonneg_left h_exp h_K_nn
  linarith

/-- LL-006 detection-bound joint monotonicity — both axes together.

    Composition of theorems 6 + 7 by transitivity. When *both*
    the observation window and the adversary magnitude
    improve, the bound tightens in both directions. The
    statement covers the operational case where a deployment
    upgrades on multiple axes at once: longer observation
    *and* a tighter calibration that bounds the worst-case
    `δ²` more sharply.

    Hypotheses:
    - `0 ≤ K` (prefactor non-negative).
    - `0 ≤ c` (exponent rate non-negative).
    - `0 ≤ T₁` (lower-bound observation window non-negative;
      needed to give `0 ≤ c·T₁` for theorem 6's hypothesis).
    - `0 ≤ s₁` (lower-bound squared magnitude non-negative;
      `s₂ ≥ 0` follows from `s₁ ≤ s₂` by transitivity).
    - `T₁ ≤ T₂`, `s₁ ≤ s₂` — the monotonicity claim itself.

    Proof: chain through the intermediate point `(T₁, s₂)`.
    First, theorem 6 gives bound at `(T₁, s₁) ≤ (T₁, s₂)`.
    Then, theorem 7 gives bound at `(T₁, s₂) ≤ (T₂, s₂)`.
    Compose by `linarith`. -/
theorem LL006_bound_monotone_joint
    {s₁ s₂ K c T₁ T₂ : ℝ}
    (h_K_nn : 0 ≤ K)
    (h_c_nn : 0 ≤ c)
    (h_T₁_nn : 0 ≤ T₁)
    (h_s₁_nn : 0 ≤ s₁)
    (h_T_le : T₁ ≤ T₂)
    (h_s_le : s₁ ≤ s₂) :
    1 - K * Real.exp (-(c * T₁) * s₁)
      ≤ 1 - K * Real.exp (-(c * T₂) * s₂) := by
  have h_cT₁_nn : 0 ≤ c * T₁ := mul_nonneg h_c_nn h_T₁_nn
  have h_step1 : 1 - K * Real.exp (-(c * T₁) * s₁)
                  ≤ 1 - K * Real.exp (-(c * T₁) * s₂) :=
    LL006_bound_monotone_in_squared_magnitude h_K_nn h_cT₁_nn h_s_le
  have h_s₂_nn : 0 ≤ s₂ := le_trans h_s₁_nn h_s_le
  have h_step2 : 1 - K * Real.exp (-(c * T₁) * s₂)
                  ≤ 1 - K * Real.exp (-(c * T₂) * s₂) :=
    LL006_bound_monotone_in_T h_K_nn h_c_nn h_s₂_nn h_T_le
  linarith

/-- LL-006 detection-bound *strict* monotonicity in squared
    adversary magnitude.

    Strict version of theorem 6. When `0 < K`, `0 < c·T`, and
    `s₁ < s₂` (strict), the bound is strictly tighter at `s₂`
    than at `s₁`. Operationally: any *real* improvement in the
    adversary-magnitude bound produces a *real* improvement in
    the detection bound — the bound has no "plateau" regions
    along the adversary axis.

    Hypotheses are strict where the non-strict version had
    `≤` — `0 < K`, `0 < c·T`, `s₁ < s₂`. The proof mirrors
    theorem 6 with strict-variant Mathlib lemmas
    (`mul_lt_mul_of_pos_left`, `Real.exp_lt_exp.mpr`,
    `mul_lt_mul_of_pos_left`). -/
theorem LL006_bound_strict_monotone_in_squared_magnitude
    {s₁ s₂ K c T : ℝ}
    (h_K_pos : 0 < K)
    (h_cT_pos : 0 < c * T)
    (h_s_lt : s₁ < s₂) :
    1 - K * Real.exp (-(c * T) * s₁)
      < 1 - K * Real.exp (-(c * T) * s₂) := by
  have h_inner_pos : c * T * s₁ < c * T * s₂ :=
    mul_lt_mul_of_pos_left h_s_lt h_cT_pos
  have h_inner : -(c * T) * s₂ < -(c * T) * s₁ := by nlinarith [h_inner_pos]
  have h_exp : Real.exp (-(c * T) * s₂) < Real.exp (-(c * T) * s₁) :=
    Real.exp_lt_exp.mpr h_inner
  have h_mul : K * Real.exp (-(c * T) * s₂) < K * Real.exp (-(c * T) * s₁) :=
    mul_lt_mul_of_pos_left h_exp h_K_pos
  linarith

/-- LL-006 detection-bound *strict* monotonicity in observation
    window T.

    Strict version of theorem 7. When `0 < K`, `0 < c`, `0 < s`,
    and `T₁ < T₂`, the bound is strictly tighter at `T₂` than
    at `T₁`. Operationally: extending observation duration —
    even by an infinitesimal — produces a *real* improvement
    in detection bound, provided there's actually adversary
    signal to detect (`0 < s`) and the bound has nonzero
    sensitivity (`0 < c`). -/
theorem LL006_bound_strict_monotone_in_T
    {s K c T₁ T₂ : ℝ}
    (h_K_pos : 0 < K)
    (h_c_pos : 0 < c)
    (h_s_pos : 0 < s)
    (h_T_lt : T₁ < T₂) :
    1 - K * Real.exp (-(c * T₁) * s)
      < 1 - K * Real.exp (-(c * T₂) * s) := by
  have h_cT_lt : c * T₁ < c * T₂ := mul_lt_mul_of_pos_left h_T_lt h_c_pos
  have h_inner_pos : c * T₁ * s < c * T₂ * s :=
    mul_lt_mul_of_pos_right h_cT_lt h_s_pos
  have h_inner : -(c * T₂) * s < -(c * T₁) * s := by nlinarith [h_inner_pos]
  have h_exp : Real.exp (-(c * T₂) * s) < Real.exp (-(c * T₁) * s) :=
    Real.exp_lt_exp.mpr h_inner
  have h_mul : K * Real.exp (-(c * T₂) * s) < K * Real.exp (-(c * T₁) * s) :=
    mul_lt_mul_of_pos_left h_exp h_K_pos
  linarith

/-- LL-006 detection-bound asymptotic: bound → 1 as T → ∞.

    For fixed `0 ≤ K`, `0 < c`, `0 < s`, the bound value
    `1 - K · exp(-(c · T) · s)` tends to `1` as the
    observation window `T` grows without bound. Operationally:
    given enough observation time, the detection probability
    bound becomes arbitrarily tight — the "asymptotic
    detectability" structural claim made formal.

    Hypothesis discipline:
    - `0 < c` (strict) — exponent rate positive; required so
      the inner argument actually grows.
    - `0 < s` (strict) — squared-magnitude positive; required
      so the inner argument actually grows. Vacuous for
      `s = 0` (bound is constantly `1 - K`).

    No `0 ≤ K` hypothesis: the limit holds for any real `K`
    because `exp(-(c·T)·s) → 0` regardless of sign and
    `K · 0 = 0`. The downstream `:proved` LL-006 theorem
    will add `0 ≤ K ≤ 1` to keep the bound a valid
    probability; the asymptote itself is sign-agnostic.

    Proof structure:
    1. `0 < c · s` from `mul_pos`.
    2. Tendsto chain on the inner argument:
       `T → ∞` ⇒ `c · T → ∞` (via `const_mul_atTop`)
       ⇒ `c · T · s → ∞` (via `atTop_mul_const`)
       ⇒ `-(c · T · s) → -∞` (via `tendsto_neg_atTop_atBot.comp`).
    3. `convert` to `-(c · T) * s` form (definitionally equal
       up to `ring`).
    4. `Real.tendsto_exp_atBot.comp` lifts to
       `exp(-(c · T) · s) → 0`.
    5. `Tendsto.const_mul K` gives
       `K · exp(...) → K · 0 = 0`; rewrite via `mul_zero`.
    6. `Tendsto.const_sub 1` gives the final result;
       rewrite via `sub_zero`. -/
theorem LL006_bound_tendsto_one_at_T_infty
    {s K c : ℝ}
    (h_c_pos : 0 < c)
    (h_s_pos : 0 < s) :
    Tendsto (fun T : ℝ => 1 - K * Real.exp (-(c * T) * s))
            atTop (nhds 1) := by
  have h_inner : Tendsto (fun T : ℝ => -(c * T) * s) atTop atBot := by
    have h1 : Tendsto (fun T : ℝ => c * T) atTop atTop :=
      Tendsto.const_mul_atTop h_c_pos tendsto_id
    have h2 : Tendsto (fun T : ℝ => c * T * s) atTop atTop :=
      Tendsto.atTop_mul_const h_s_pos h1
    have h3 : Tendsto (fun T : ℝ => -(c * T * s)) atTop atBot :=
      tendsto_neg_atTop_atBot.comp h2
    convert h3 using 1
    funext T; ring
  have h_exp : Tendsto (fun T : ℝ => Real.exp (-(c * T) * s))
                       atTop (nhds 0) :=
    Real.tendsto_exp_atBot.comp h_inner
  have h_K_exp : Tendsto (fun T : ℝ => K * Real.exp (-(c * T) * s))
                          atTop (nhds 0) := by
    have h := h_exp.const_mul K
    rw [mul_zero] at h
    exact h
  have h_final := h_K_exp.const_sub 1
  rw [sub_zero] at h_final
  exact h_final

/-- LL-006 detection-bound asymptotic: bound → 1 as s → ∞.

    Symmetric to theorem 11 with `s` as the variable axis.
    For fixed `0 ≤ K`, `0 < c`, `0 < T`, the bound value
    `1 - K · exp(-(c · T) · s)` tends to `1` as the
    squared-magnitude argument `s` grows without bound.

    Operationally: stronger and stronger adversaries become
    arbitrarily detectable in the limit — there is no upper
    plateau on detection probability under unbounded
    adversary magnitude. -/
theorem LL006_bound_tendsto_one_at_s_infty
    {K c T : ℝ}
    (h_c_pos : 0 < c)
    (h_T_pos : 0 < T) :
    Tendsto (fun s : ℝ => 1 - K * Real.exp (-(c * T) * s))
            atTop (nhds 1) := by
  have h_cT_pos : 0 < c * T := mul_pos h_c_pos h_T_pos
  have h_inner : Tendsto (fun s : ℝ => -(c * T) * s) atTop atBot := by
    have h1 : Tendsto (fun s : ℝ => (c * T) * s) atTop atTop :=
      Tendsto.const_mul_atTop h_cT_pos tendsto_id
    have h2 : Tendsto (fun s : ℝ => -((c * T) * s)) atTop atBot :=
      tendsto_neg_atTop_atBot.comp h1
    convert h2 using 1
    funext s; ring
  have h_exp : Tendsto (fun s : ℝ => Real.exp (-(c * T) * s))
                       atTop (nhds 0) :=
    Real.tendsto_exp_atBot.comp h_inner
  have h_K_exp : Tendsto (fun s : ℝ => K * Real.exp (-(c * T) * s))
                          atTop (nhds 0) := by
    have h := h_exp.const_mul K
    rw [mul_zero] at h
    exact h
  have h_final := h_K_exp.const_sub 1
  rw [sub_zero] at h_final
  exact h_final

/-! ## LL-022 / LL-023 parametric shape theorems

These two namespaces encode the **type-level discipline** for
deployment-stack conformance theorems (round-3 §1D.v
priorities 5 + 6). The structures define the conformance
witnesses; the predicates are the conformance content; the
extraction lemmas demonstrate that conformance witnesses
yield each individual sub-claim. Evidence type:
`type-checked` (Lean's type system enforces the propagation
shape).

Per round-3 §1D.v: "shape-discipline only; no Mathlib needed
at the shape level." These declarations encode the form of
how conditional security claims compose; concrete LL-022 /
LL-023 theorems with full security content land in
subsequent versions when the consumer-API surface and the
TPM-attestation API are concretized.
-/

namespace LL022

/-- LL-022 OS-trust-stack assumptions. Mirror of the spec
    entry's required-mechanism enumeration:
    (a) hardware root of trust (TPM / SecureEnclave / TrustZone),
    (b) OS sensor APIs at sufficient bandwidth,
    (c) host-grade entropy sources.

    Each field is a `Bool` representing whether the deployment
    *claims* to provide the mechanism; the conformance
    predicate then asserts they're all `true`. Real
    deployments populate this from a TPM attestation +
    capability discovery; this scaffold encodes the type
    shape. -/
structure OSAssumptions where
  has_hardware_root_of_trust : Bool
  has_os_sensor_apis : Bool
  has_host_grade_random : Bool

/-- LL-022 conformance predicate: deployment satisfies all
    three required-mechanism claims. -/
def conformant (os : OSAssumptions) : Prop :=
  os.has_hardware_root_of_trust = true ∧
  os.has_os_sensor_apis = true ∧
  os.has_host_grade_random = true

end LL022

namespace LL023

/-- LL-023 consumer-API surface. The three load-bearing
    invariants from the LL-023 spec entry:
    - Register/verify pair exposed (LL-011 + LL-006 surfaces).
    - LL-017 no-oracle response discipline preserved through
      the API. -/
structure ConsumerAPI where
  exposes_register : Bool
  exposes_verify : Bool
  preserves_no_oracle : Bool

/-- LL-023 conformance predicate: consumer API meets all
    three surface invariants. -/
def conforms (api : ConsumerAPI) : Prop :=
  api.exposes_register = true ∧
  api.exposes_verify = true ∧
  api.preserves_no_oracle = true

end LL023

/-- LL-022 parametric shape — extraction lemma: conformance
    witnesses the hardware-root-of-trust sub-claim.

    Theorem-shape demonstration: from a `LL022.conformant`
    proof, extract the individual `has_hardware_root_of_trust`
    sub-claim. Real LL-022 theorems will use this same
    pattern to extract the relevant sub-claim for whichever
    LavaLamp property the deployment cites. -/
theorem LL022_conformance_implies_hardware_root_of_trust
    {os : LL022.OSAssumptions}
    (h : LL022.conformant os) :
    os.has_hardware_root_of_trust = true :=
  h.1

/-- LL-023 parametric shape — extraction lemma: conformance
    witnesses the no-oracle sub-claim.

    Theorem-shape demonstration mirroring theorem 13. From a
    `LL023.conforms` proof, extract the LL-017 no-oracle
    invariant — the most security-relevant of the three
    consumer-API surface claims. -/
theorem LL023_conforms_implies_no_oracle
    {api : LL023.ConsumerAPI}
    (h : LL023.conforms api) :
    api.preserves_no_oracle = true :=
  h.2.2

/-- Scaffold-tier marker. Confirms the package builds. Removed
    when the Theorems file is reorganised into per-priority
    submodules (per `src/lean4/README.md` §File inventory). -/
def scaffold_tier : String :=
  "0.0.66 — LL-006 asymptotic limits + LL-022/LL-023 parametric shape landed"

end LavaLamp
