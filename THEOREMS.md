# THEOREMS — Lean 4 / Mathlib formal verification

Single-file summary of every theorem proved in LavaLamp's Lean 4
track. Source lives at `src/lean4/LavaLamp/Theorems.lean`;
toolchain pinned at `leanprover/lean4:v4.29.1`; Mathlib pinned
at `v4.29.1` via `src/lean4/lake-manifest.json`.

**Build verification.** From a clean checkout:

```bash
cd src/lean4
lake update
lake exe cache get
lake build
```

Expected: `Build completed successfully (1901 jobs)` with **zero
warnings** — no `sorry`, no unused-variable, no deprecation. The
Lean kernel verifies every proof at compile time.

**Status.** All ten theorems below are kernel-verified
(`lean-proved` evidence type per the project's
evidence-type discipline).
The single LavaLamp spec entry currently at `:proved` status is
**LL-021** (worst-case-adversary-bound) — promoted at 0.0.48 by
theorem 1 below. Theorems 2–10 are composition lemmas building
toward a future LL-006 `:proved` status; they currently land as
`lean-proved` content supporting LL-021 + LL-006 entries without
themselves being entry-promoting.

---

## Theorem index

| # | Name | Type | Promotes |
|---|------|------|----------|
| 1 | `LL021_worst_case_bound` | algebraic | LL-021 → `:proved` (0.0.48) |
| 2 | `LL021_eff_squared_bound` | algebraic corollary | — (supports LL-021) |
| 3 | `LL006_worst_case_lower_than_isotropic` | composition | — (supports LL-006) |
| 4 | `LL006_bound_le_one` | range | — (supports LL-006) |
| 5 | `LL006_bound_nonneg` | range | — (supports LL-006) |
| 6 | `LL006_bound_monotone_in_squared_magnitude` | monotonicity | — (supports LL-006) |
| 7 | `LL006_bound_monotone_in_T` | monotonicity | — (supports LL-006) |
| 8 | `LL006_bound_monotone_joint` | composition | — (supports LL-006) |
| 9 | `LL006_bound_strict_monotone_in_squared_magnitude` | strict monotonicity | — (supports LL-006) |
| 10 | `LL006_bound_strict_monotone_in_T` | strict monotonicity | — (supports LL-006) |

---

## 1 — `LL021_worst_case_bound` (LL-021 `:proved`)

**Statement.** For non-negative `ε_A` and `proj ≤ 1`, the
projected effective adversary magnitude `ε_A · proj` cannot
exceed the unprojected magnitude `ε_A`.

```lean
theorem LL021_worst_case_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_le_one : proj ≤ 1) :
    ε_A * proj ≤ ε_A :=
  mul_le_of_le_one_right h_ε h_proj_le_one
```

**Proof.** One-line term-mode discharge against Mathlib's
`mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`.

**Why `0 ≤ proj` is not in the signature.** The bound holds for
negative `proj` as well — the product becomes non-positive,
which is trivially `≤ ε_A` for non-negative `ε_A`. Geometric
construction `proj = |û · m_unit| ∈ [0, 1]` provides the
non-negativity at call sites where it matters; downstream
theorems (e.g. theorem 2 below) reintroduce it where the proof
genuinely needs it.

**Spec connection.** LL-021 worst-case-adversary-bound. The
empirical fit constants `K = 1, c′ = 0.0288, T = 60` at N = 20
(n = 15 trials per point) live at `:benchmarked` tier; this
theorem captures the algebraic *shape* of the bound that the
empirical fit is a fit to.

---

## 2 — `LL021_eff_squared_bound` (LL-021 / LL-006 composition foothold)

**Statement.** Under non-negative `ε_A`, non-negative `proj`,
`proj ≤ 1`, the squared effective magnitude `(ε_A · proj)²` is
bounded by `ε_A²`.

```lean
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
```

**Proof.** Direct application of Mathlib's `pow_le_pow_left₀` —
the GroupWithZero variant of the monotone-pow lemma; the
unsubscripted `pow_le_pow_left` from older Mathlib versions was
renamed during the v4.x reorganisation, so the `₀` form is what
`ℝ` hits in v4.29.1. Hypotheses: `0 ≤ ε_A · proj` (from
`mul_nonneg`) and `ε_A · proj ≤ ε_A` (from theorem 1).

**Why `0 ≤ proj` is needed.** The monotone-squaring step
`0 ≤ a ≤ b → a² ≤ b²` requires the lower bound to be
non-negative.

**Spec connection.** Sets the algebraic foothold for LL-006
detection-bound composition (theorem 3 below). The
detection-probability bound shape `1 - K · exp(-c·T·δ²)` in
LL-006 has `δ²` in the exponent; this lemma supplies the
squared-magnitude inequality the bound's monotonicity argument
uses.

---

## 3 — `LL006_worst_case_lower_than_isotropic` (composition theorem)

**Statement.** The worst-case detection-probability bound
*value* is less than or equal to the isotropic bound value.

```lean
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
```

**Proof.** Five-step composition:

1. `(ε_A · proj)² ≤ ε_A²` from theorem 2.
2. Multiplying by the non-positive scalar `-(c · T)` flips the
   inequality direction (`mul_le_mul_of_nonpos_left`).
3. `Real.exp` monotonicity lifts step 2 through the exponential
   (`Real.exp_le_exp.mpr`).
4. Multiplying by `K ≥ 0` preserves the direction
   (`mul_le_mul_of_nonneg_left`).
5. Subtraction from `1` flips once and `linarith` discharges.

**Why this matters.** The LL-021 / LL-006 spec text claims the
worst-case detection probability is *lower* than the isotropic
detection probability — the structural asymmetry that makes
LL-021 a containment bound rather than a closure of A6. Until
this theorem, that claim was empirically observed
(`:benchmarked`) and structurally argued. With this theorem,
it's mathematically derivable from the bound shape — composition
of the projection bound with the exponential's monotonicity in
the squared magnitude yields the asymmetry directly.

**Spec connection.** Round-3 §1D.v priority 4 partial — the
asymmetry implication of LL-021 against LL-006. Does not
promote LL-006 to `:proved` (the bound *itself* is a probability
claim; this theorem proves a *property* of the bound shape).

---

## 4 — `LL006_bound_le_one` (range theorem, upper)

**Statement.** Under `0 ≤ K`, the bound value is `≤ 1`.

```lean
theorem LL006_bound_le_one
    {δ K c T : ℝ}
    (h_K_nn : 0 ≤ K) :
    1 - K * Real.exp (-(c * T) * δ ^ 2) ≤ 1 := by
  have h_exp_pos : 0 < Real.exp (-(c * T) * δ ^ 2) := Real.exp_pos _
  have : 0 ≤ K * Real.exp (-(c * T) * δ ^ 2) :=
    mul_nonneg h_K_nn h_exp_pos.le
  linarith
```

**Proof.** `Real.exp` is always positive; `mul_nonneg` lifts to
`0 ≤ K · exp(...)` under `0 ≤ K`; `linarith` discharges.

**No constraint on `c`, `T`, or `δ` is needed** — the upper
range is independent of the bound's parametric content.

---

## 5 — `LL006_bound_nonneg` (range theorem, lower)

**Statement.** Under `K ∈ [0, 1]` and `0 ≤ c · T`, the bound
value is `≥ 0`.

```lean
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
```

**Proof.** Four steps:

1. `0 ≤ (c · T) · δ²` from `mul_nonneg` + `sq_nonneg`.
2. Negate to get `-(c · T) · δ² ≤ 0` via `linarith`.
3. `Real.exp_le_exp.mpr` lifts the inequality through `exp`;
   `Real.exp_zero` rewrite gives `Real.exp(-(c·T)·δ²) ≤ 1`.
4. `mul_le_mul_of_nonneg_left` applies `0 ≤ K`; `linarith`
   closes via `K ≤ 1`.

**Why `K ≤ 1`.** Required only for the lower bound. Matches
LL-006's fitted constant `K = 1` from the 0.0.17 P3-bound
benchmark (the bound saturates at `K = 1`); the formalisation
accepts any `K ∈ [0, 1]` for generality.

**Together with theorem 4:** the bound value is in `[0, 1]` —
well-typed as a lower-bound-on-probability.

---

## 6 — `LL006_bound_monotone_in_squared_magnitude` (monotonicity, δ²-axis)

**Statement.** Stronger adversary makes detection easier:
the bound value is monotone non-decreasing in the squared
magnitude argument.

```lean
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
```

**Proof.** Five-step composition mirroring theorem 3:
multiply `s₁ ≤ s₂` by the non-positive scalar `-(c · T)` to
flip; lift through `Real.exp`; multiply by `K ≥ 0` to
preserve direction; subtract from `1`; `linarith`.

**Statement uses `s` directly** rather than `δ^2` because the
monotonicity holds for any reals `s₁ ≤ s₂` — the sign of `s`
is not part of the monotonicity claim. For the LL-006 default
case `s = δ²`, theorems 5 + 6 together say "the bound is in
`[0, 1]` *and* monotone in `δ²`."

**Spec connection.** The LL-006 statement
"P(detect) ≥ 1 - K · exp(-c · T · δ²)" implicitly claims that
larger adversary magnitudes give tighter detection bounds.
Theorem 6 makes that implicit claim formal on the bound shape
itself. The probability claim — that `P(detect)` actually
satisfies the inequality — still requires the probability-
space formalization (multi-session work).

---

## 7 — `LL006_bound_monotone_in_T` (monotonicity, T-axis)

**Statement.** Longer observation makes detection easier: the
bound value is monotone non-decreasing in the observation
window `T`.

```lean
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
```

**Proof.** Five-step composition: chain `T₁ ≤ T₂` by `c ≥ 0`
and `s ≥ 0` to get `c·T₁·s ≤ c·T₂·s`; flip via `nlinarith` for
the negation step (handles the product rearrangement
automatically); lift through `Real.exp`; multiply by `K ≥ 0`;
subtract from `1`; `linarith` closes.

**Hypotheses unpacked.** `0 ≤ K` (prefactor non-negative;
fitted constant `K = 1`). `0 ≤ c` (exponent rate; bound
calibration gives `c′ > 0`). `0 ≤ s` (squared-magnitude
non-negative; for the LL-006 default `s = δ²` automatic via
`sq_nonneg`). `T₁ ≤ T₂` is the monotonicity claim itself.

**Spec connection.** Pairs with theorem 6 to give the LL-006
detection bound a complete shape characterisation: the bound
is **monotone in both axes** — larger T tightens detection,
larger δ² tightens detection. Composing this with the LL-021
worst-case bound (`ε_eff ≤ ε_A`) and the squared form
(`ε_eff² ≤ ε_A²`) yields theorem 3's asymmetry conclusion as
a direct consequence: the worst-case bound *value* sits below
the isotropic bound *value* on the same `(K, c, T)` calibration.

---

## 8 — `LL006_bound_monotone_joint` (joint axes — composition)

**Statement.** Bound improves when *both* the observation
window and the squared adversary magnitude improve
simultaneously. Pure composition of theorems 6 and 7 by
transitivity — exists as a single citation point for
operational deployments that upgrade on multiple axes at once
(longer observation *and* tighter calibration of `δ²`).

```lean
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
```

**Proof.** Three-step composition: theorem 6 gives
`bound(T₁, s₁) ≤ bound(T₁, s₂)`; theorem 7 gives
`bound(T₁, s₂) ≤ bound(T₂, s₂)`; `linarith` chains them.
Hypothesis bookkeeping: `0 ≤ T₁` plus `0 ≤ c` give the
`0 ≤ c·T₁` that theorem 6 wants; `0 ≤ s₂` follows from
`0 ≤ s₁ ≤ s₂` by transitivity for theorem 7's hypothesis.

**Why this exists.** Real deployments don't pick one axis to
improve. A move from "calibrated at N=20 / T=60" to
"calibrated at N=80 / T=300" tightens both `δ²` and `T`
simultaneously; this theorem says the bound on the new
calibration dominates the bound on the old one without
needing the operator to reason axis-by-axis.

---

## 9 — `LL006_bound_strict_monotone_in_squared_magnitude` (strict, δ²-axis)

**Statement.** Strict version of theorem 6: when `0 < K`,
`0 < c·T`, and `s₁ < s₂` (all strict), the bound is
*strictly* tighter at `s₂`. Operationally: any *real*
improvement in the adversary-magnitude bound produces a
*real* improvement in the detection bound — the bound has
no plateau regions along the adversary axis.

```lean
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
```

**Proof.** Same five-step shape as theorem 6 with strict-
variant Mathlib lemmas: `mul_lt_mul_of_pos_left` instead of
`mul_le_mul_of_nonneg_left`, `Real.exp_lt_exp.mpr` instead of
`Real.exp_le_exp.mpr`. Strict propagation requires `0 < K`
and `0 < c·T` (otherwise zero factors collapse the strict
inequality to equality).

**Why this exists.** Non-strict monotonicity (theorem 6)
allows that a "trivial" improvement (e.g. `s₁ = s₂`) gives
*at most* a tightening of the bound — but doesn't say
strictly more. Theorem 9 closes that gap when the underlying
inequality is genuinely strict.

---

## 10 — `LL006_bound_strict_monotone_in_T` (strict, T-axis)

**Statement.** Strict version of theorem 7: extending the
observation window — even by an infinitesimal — produces a
*strict* improvement in the detection bound, provided
there's actually adversary signal to detect (`0 < s`) and
the bound has nonzero sensitivity (`0 < c`).

```lean
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
```

**Proof.** Same shape as theorem 7 with strict variants:
`mul_lt_mul_of_pos_left/right` and `Real.exp_lt_exp.mpr`.
All four strict hypotheses (`0 < K`, `0 < c`, `0 < s`,
`T₁ < T₂`) are needed; relaxing any one collapses strict
inequality to non-strict.

---

## What this collectively proves

The ten theorems chain to give:

- **LL-021 worst-case bound** (theorem 1) — projected adversary
  magnitude is bounded by unprojected magnitude.
- **Squared form** (theorem 2) — the squared bound that LL-006
  composes with.
- **Asymmetry** (theorem 3) — worst-case detection bound
  *value* is less than isotropic detection bound *value*.
- **Well-typedness** (theorems 4 + 5) — the bound *value* is in
  `[0, 1]`, making it a valid lower bound on a probability.
- **Monotonicity in adversary magnitude** (theorem 6) — larger
  `δ²` tightens the detection bound.
- **Monotonicity in observation window** (theorem 7) — larger
  `T` tightens the detection bound.
- **Joint monotonicity** (theorem 8) — bound improves when
  *both* axes improve simultaneously; single citation point
  for multi-axis deployment upgrades.
- **Strict monotonicity in `δ²`** (theorem 9) — under positive
  prefactor and exponent, any *real* improvement in adversary-
  magnitude bound produces a *real* improvement in detection
  bound; no plateau regions.
- **Strict monotonicity in `T`** (theorem 10) — under positive
  prefactor, exponent, and adversary signal, extending
  observation by any positive duration produces a strict
  detection improvement.

## What this does NOT prove

The probability bound itself — `P(detect) ≥ 1 - K · exp(-c · T · δ²)`
— is a probability-space claim. Promoting LL-006 to `:proved`
requires:

- A probability space modeling trajectory sampling.
- Random variables for the spectrum estimator output.
- The detection-event predicate (when do we say a trajectory
  was "detected as adversarial"?).
- The lower-bound proof itself (probabilistic concentration
  inequality on the spectrum residue).

Each is a multi-session research investment. The ten
theorems above prove every *algebraic* and *real-analysis*
property the eventual `:proved` proof will compose with —
the missing piece is the probability-space side.

## Source

`src/lean4/LavaLamp/Theorems.lean`. Build instructions in the
top-level README §"Try it" or in `src/lean4/README.md`.

## Honest framing reminder

Per the project's evidence-type discipline: a theorem with
`sorry` in its body is **not** a proof. All ten theorems
above are kernel-verified with no `sorry`. The build is configured so any `sorry` regression
would surface as a `declaration uses 'sorry'` linter warning —
the current build returns zero warnings, so the proofs are
honest.
