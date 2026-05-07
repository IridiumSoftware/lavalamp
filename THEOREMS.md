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

**Status.** All five theorems below are kernel-verified
(`lean-proved` evidence type per `CLAUDE.md` §Evidence types).
The single LavaLamp spec entry currently at `:proved` status is
**LL-021** (worst-case-adversary-bound) — promoted at 0.0.48 by
theorem 1 below. Theorems 2–5 are composition lemmas building
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

## What this collectively proves

The five theorems chain to give:

- **LL-021 worst-case bound** (theorem 1) — projected adversary
  magnitude is bounded by unprojected magnitude.
- **Squared form** (theorem 2) — the squared bound that LL-006
  composes with.
- **Asymmetry** (theorem 3) — worst-case detection bound
  *value* is less than isotropic detection bound *value*.
- **Well-typedness** (theorems 4 + 5) — the bound *value* is in
  `[0, 1]`, making it a valid lower bound on a probability.

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

Each is a multi-session research investment. The five theorems
above prove every *algebraic* and *real-analysis* property the
eventual `:proved` proof will compose with — the missing piece
is the probability-space side.

## Source

`src/lean4/LavaLamp/Theorems.lean`. Build instructions in the
top-level README §"Try it" or in `src/lean4/README.md`.

## Honest framing reminder

Per `LAVALAMP_SPEC.md` and the project's evidence-type
discipline: a theorem with `sorry` in its body is **not** a
proof. All five theorems above are kernel-verified with no
`sorry`. The build is configured so any `sorry` regression
would surface as a `declaration uses 'sorry'` linter warning —
the current build returns zero warnings, so the proofs are
honest.
