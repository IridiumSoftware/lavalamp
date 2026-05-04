# LL-020 Strategy 2 — DP detection-power-vs-ε benchmark + companion

Version: 0.0.27 (LL-020 Strategy 2 :benchmarked-tier evidence; entry-level stays :argued)

Permanent record of the LL-020 Strategy 2 (ε-DP envelope
perturbation) detection-power-vs-ε benchmark. Closes Strategy 2
to `:benchmarked`-tier evidence — empirical validation of the
privacy/detection trade-off curve fitted against the Dwork-Roth
Gaussian mechanism — without changing LL-020's entry-level
status, which stays `:argued` because the multi-strategy approach
(Strategies 1+2+3) is the entry-level claim and only Strategy 2
has been empirically exercised at this level of evidence.

This companion supersedes the 2026-05-04 negative-result phase
(`docs/audit_2026-05-04.md`) by documenting the fixed
implementation and the post-fix benchmark. The diagnostic note
remains the canonical record of how the bug was discovered and
attributed; this companion is the post-fix `:benchmarked`-tier
evidence.

---

## §1 — Computational basis

### §1.1 — Implementation refinement (variance-convolution σ)

The `differentially_private_envelope` implementation in
`src/julia/src/Audit.jl` was refined on 2026-05-04 from
"add symmetric Gaussian noise to both spectrum and σ, then
floor σ at 1e-10" to:

- **Spectrum**: Gaussian-mechanism (ε, δ)-DP. `spectrum_pub_i =
  env.spectrum_i + σ_DP · z_i` with `z_i ~ N(0, 1)` per
  component.
- **σ**: variance-convolution form. `σ_pub_i = sqrt(env.σ_i² +
  σ_DP²)`. Deterministic in `env.σ` and `σ_DP`; does not consume
  RNG; strictly inflates each component (since σ_DP > 0).

The refinement is the variance-convolution form because the
verifier's residual under DP-perturbed spectrum has variance
`σ_true² + σ_DP²` (the convolution of the genuine-residual
variance with the DP-shift variance); the published σ should
reflect that combined uncertainty so the verifier's threshold
`k · σ_pub` widens correctly. The previous symmetric-noise
form pushed σ near zero ~50% of the time per component, which
the floor at 1e-10 then converted into hard-rejection traps
(diagnostic at `docs/audit_2026-05-04.md` §2.2).

**Privacy implication.** Spectrum is fully (ε, δ)-DP.
σ is **not** DP under this implementation; it leaks
`env.σ ≤ σ_pub`. Operationally σ is calibration *confidence*
metadata, strictly less sensitive than the spectrum itself,
and a deployment that needs σ to be DP-protected substitutes
Strategy 1 (TPM-sealed storage) or Strategy 3 (Shamir
threshold) for that field.

### §1.2 — Benchmark script

`src/julia/benchmark/ll020_strategy_2_detection_power.jl`.
Configuration mirrors `p3_bound_high_res.jl` (LL-006
:benchmarked) for direct comparability:

- Lorenz-96 N=20, F=8, single coupling channel `b=ones(N)`,
  α=1.0, `constant_stream(1.0)`.
- Calibration: `n_trials=10`, `N_benettin=1200`, `Δt=0.05`,
  `Ttr=200.0`; `CALIBRATION_SEED=101`.
- Verifier: `verify(λs, env_pub; k=5)`.
- Adversary: `synthetic_adversary` with isotropic unit-vector
  × ε_A; ε_A grid {0.0, 0.5, 1.0, 1.5, 2.0, 3.0}; 10 trials
  per ε_A (60 trajectories total).
- DP grid: ε_DP ∈ {0.3, 1.0, 3.0, 10.0}; δ=1e-6;
  sensitivity=0.1; 5 DP-realizations per ε_DP.
- Trajectory computation shared across (ε_DP, DP-realization)
  cells — only the published envelope changes per cell, not
  the adversary's λs.

**Reproducibility.** Deterministic via fixed RNG seeds for
calibration (101), adversary (Xoshiro 2000+trial), trial IC
(3000+trial), DP realization (Xoshiro 4000+round(ε_DP·10)+
r·1000). Two consecutive runs produce byte-identical output
(`diff` exit 0) confirmed both pre-fix (the negative result
was deterministic) and post-fix (the working result is
deterministic).

**Wall clock.** ~13 seconds total on Apple Silicon: ~4 s
calibration + ~8 s for the 60 trajectory computations +
~1 s for the cheap O(N) verify checks across all (ε_DP,
DP-realization) cells.

### §1.3 — Pre-fix vs post-fix results

The pre-fix benchmark output (committed at `8574670` in the
result file as audit-trail evidence then overwritten by the
post-fix re-run) showed P(reject) = 1.000 across every
(ε_DP, ε_A) cell — including ε_A=0 (genuine device rejected
100% of the time at every ε_DP). The post-fix benchmark
produces the expected trade-off curve documented in §2.

The pre-fix result is preserved in commit `8574670` and in
the diagnostic note `docs/audit_2026-05-04.md`.

---

## §2 — Results

### §2.1 — Detection-power surface

Empirical P(reject) at each (ε_DP, ε_A) cell, mean ± std
across 5 DP-realizations:

```
ε_A    P_no_DP   P_ε=10            P_ε=3             P_ε=1             P_ε=0.3
----   -------   ---------------   ---------------   ---------------   ---------------
0.00     0.100   0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000
0.50     0.000   0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000
1.00     0.500   0.020 ± 0.045     0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000
1.50     0.500   0.040 ± 0.055     0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000
2.00     1.000   0.900 ± 0.071     0.000 ± 0.000     0.000 ± 0.000     0.000 ± 0.000
3.00     1.000   1.000 ± 0.000     0.580 ± 0.164     0.000 ± 0.000     0.000 ± 0.000
```

**FPR (ε_A=0 row).** Genuine-device rejection is **0% across
all DP cells**, vs **10% at no-DP baseline**. The wider
thresholds from σ_DP-inflation eliminate the baseline FPR
floor — a clean side-benefit of DP at the prototype's k=5 /
n_trials=10 calibration regime. (The baseline 10% FPR is
operationally a denial-of-service vector at scale per round-2
§1C-A5; a deployment willing to pay ε-DP perturbation gains
an FPR reduction along with the privacy guarantee.)

**Detection transition shifts right with smaller ε_DP.** The
no-DP curve saturates at ε_A=2.0 (P_reject=1.000); ε_DP=10
saturates at ε_A=3.0 (P=1.000); ε_DP=3 reaches only 0.58 at
ε_A=3.0; ε_DP=1 and ε_DP=0.3 stay at 0% across the entire
tested ε_A range. This is the intended privacy/detection
trade-off: more privacy → larger σ_DP → wider threshold →
weak adversaries slip through.

### §2.2 — σ_DP at each privacy budget

Per the Dwork-Roth Gaussian mechanism, `σ_DP =
sensitivity · sqrt(2 · ln(1.25/δ)) / ε`:

| ε_DP   | σ_DP (analytic) | σ_DP / σ_true_min | Threshold widening |
|--------|-----------------|-------------------|---------------------|
| 10.00  | 0.0530          | 3.4×              | sqrt(σ²+σ_DP²) ≈ 1.2× σ_min |
| 3.00   | 0.1766          | 11.4×             | ≈ 11.5× σ_min |
| 1.00   | 0.5299          | 34.2×             | ≈ 34.3× σ_min |
| 0.30   | 1.7663          | 113.9×            | ≈ 114.0× σ_min |

(σ_true_min = 0.0155 at the prototype's calibration; sensitivity
= 0.1; δ = 1e-6.)

The threshold `k · σ_pub` for the smallest-σ component grows
roughly proportionally to σ_DP/σ_min when σ_DP ≫ σ_min. At
ε_DP=10, σ_pub on that component is sqrt(0.0155² + 0.0530²)
≈ 0.0552 vs the un-perturbed 0.0155 — a 3.6× threshold
widening for that component, manageable. At ε_DP=0.3, σ_pub
≈ 1.77, a 114× widening — every isotropic adversary in the
ε_A range up to 3.0 fits inside the rejection ball.

### §2.3 — Fitted bound constants

Recasting the LL-006 detection-probability bound shape under
DP perturbation:

```
P(detect | ε_DP, ε_A) ≥ 1 - K(ε_DP) · exp(-c'(ε_DP) · T · ε_A²)
```

The privacy budget enters as a parameter on K and c'. Fitting
`log(1 - P_reject) = log(K) - c'·T·ε_A²` per ε_DP, excluding
FPR-floor (P=baseline) and saturation (P≥0.95) points:

| ε_DP   | σ_DP    | n_fit | K     | c'        | P_genuine_FPR |
|--------|---------|-------|-------|-----------|---------------|
| no DP  | 0.0000  | 3     | 0.798 | 0.00418   | 0.100         |
| 10.00  | 0.0530  | 3     | 3.106 | 0.01325   | 0.000         |
| 3.00   | 0.1766  | 1     | (insufficient transition-region points) | 0.000 |
| 1.00   | 0.5299  | 0     | (saturated at FPR floor across full range) | 0.000 |
| 0.30   | 1.7663  | 0     | (saturated at FPR floor across full range) | 0.000 |

**Reading the fits.**

- The **no-DP** baseline reproduces the P3-bound fit exactly
  (K=0.798, c'=0.00418, T=60) — same data, same methodology;
  this is a sanity-check confirming the DP benchmark is on
  the same footing as the LL-006 :benchmarked surface.
- **ε_DP=10** is the most informative DP fit. K=3.106 and
  c'=0.01325. The c' value is ~3× larger than the no-DP
  baseline because the transition region is *compressed* into
  a narrower ε_A band (ε_A ∈ [1, 2] vs ε_A ∈ [0.5, 1.5] at
  baseline) — the FPR floor moves from 0.10 to 0.00 (an
  expansion of the dead zone), then the slope is steeper on
  the way to saturation. Operationally: a deployment using
  ε_DP=10 has *both* lower FPR than the baseline *and* a
  shifted detection threshold.
- **ε_DP=3** has only one transition-region point (ε_A=3.0,
  P=0.58); insufficient for a 2-parameter fit. The trade-off
  is visible but not quantitatively closed at this resolution.
- **ε_DP=1 and 0.3** saturate at the FPR floor (P=0) across
  the entire tested ε_A range; the bound is operationally
  vacuous in this regime. A deployment wanting privacy budget
  this tight needs either larger ε_A discrimination
  (architectural change) or a different strategy (1 or 3).

### §2.4 — Operational interpretation

The benchmark surface gives a deployment three tunable knobs:

1. **ε_DP** (privacy budget) — set by deployment privacy
   requirements.
2. **k** (verifier threshold multiplier) — set by acceptable
   FPR.
3. **n_trials** (calibration sample size) — set by
   registration ceremony cost; affects σ_true and therefore
   the σ_DP / σ_true ratio.

The trade-off shape:

- **High privacy (small ε_DP)** is bought at the cost of
  detection power against weak adversaries. The benchmark
  shows ε_DP < 3 is operationally vacuous at the prototype's
  N=20 / k=5 / n_trials=10 config — adversaries in the
  ε_A ≤ 3.0 range pass through unnoticed.
- **Low privacy (large ε_DP)** approaches the no-DP baseline
  but with the side-benefit of FPR elimination. ε_DP=10 gives
  a clean detection sigmoid shifted right by ~1.0 in ε_A
  with FPR=0.000.
- **The σ_DP / σ_true_min ratio** is the operationally
  meaningful predictor. When σ_DP > 3 × σ_true_min, the
  threshold widens enough that ε_A < σ_DP-equivalent
  adversaries blend into the rejection ball. A deployment
  that needs detection power at adversary magnitudes ε_A ≈ X
  must satisfy σ_DP < X / 3 approximately, which gives
  `ε_DP > 3 · sensitivity · sqrt(2·ln(1.25/δ)) / X`.

For a deployment targeting detection at ε_A=2.0 with
δ=1e-6 and sensitivity=0.1: `ε_DP > 3 · 0.1 · 5.30 / 2.0 ≈
0.80`. At the prototype's n=10 / k=5 calibration, ε_DP=1
is right at the edge of operationally vacuous; ε_DP=3 is
approaching the saturated regime; ε_DP=10 is well-clear
of the FPR floor.

---

## §3 — Verification

### §3.1 — Strategy 2 :benchmarked-tier evidence

**Verification status:** `:benchmarked` (Strategy 2 component
of LL-020).

**Evidence type:** `benchmarked`.

**Empirical measurement:** Detection-probability surface across
(ε_DP, ε_A) plane; fitted bound constants per ε_DP per the
LL-006 P3-bound shape.

**Reproducibility:** byte-deterministic (`diff` exit 0 across
two consecutive runs, both pre-fix and post-fix).

**Performance target:** "ε-DP envelope perturbation produces a
quantifiable privacy/detection trade-off curve at the
prototype's calibration regime, with σ_DP / σ_true_min as the
operationally meaningful predictor of detection degradation"
— met.

### §3.2 — LL-020 entry-level stays :argued

The entry-level claim of LL-020 is the *multi-strategy
approach*: Strategy 1 (TPM-sealed storage), Strategy 2 (ε-DP
perturbation), Strategy 3 (Shamir threshold) layered by
deployment context. Strategy 2 closing to `:benchmarked`-tier
evidence does not close the entry-level claim because:

- Strategy 1 remains implementation-deferred (P7 hardening;
  TPM/Secure-Enclave coupling).
- Strategy 3 remains implementation-deferred (P5 Haskell
  cryptographic-library coupling).
- The entry-level claim is that *the layered design space
  closes the V-012 calibration-leakage attack surface*, not
  that *any single strategy alone closes it*.

`:tested`/`:benchmarked`-tier upgrade for the entry-level
claim requires evidence on at least two of the three strategies
(or a structural argument that one is sufficient). The current
status is honest: Strategy 2 has empirical detection-power
evidence; the multi-strategy claim is design-level argument
only.

This pattern is precedent — round-2 §1D-iii articulated it
explicitly during the P-R2b design pass (multi-strategy
robustness as the load-bearing claim, not single-strategy
sufficiency).

### §3.3 — Lean theorem implications

Per round-2 §1D.v priority 3 (calibration ε-DP):

The (ε, δ)-DP guarantee on `spectrum_pub` is a Lean-statable
theorem about the Gaussian mechanism applied to a function with
L2-sensitivity ≤ `sensitivity`. Proof shape: standard Dwork-
Roth construction; theorem holds for any spectrum vector with
bounded sensitivity. **No LL-022 OS dependency at theorem
level.**

The `σ_pub = sqrt(σ_true² + σ_DP²)` form is *not* DP; it is
a deterministic post-processing of `env.σ`. A separate Lean
theorem could state the variance-convolution lemma: if
`Y = X + N(0, σ_DP²)` and `Var(X) = σ_true²`, then
`Var(Y) = σ_true² + σ_DP²`. This is straightforward.

The *operational* theorem — "verification using the perturbed
envelope rejects at most as often as verification using the
true envelope at the same threshold k" — requires a coupling
argument between the two verifiers. P5/P6 work.

---

## §4 — Spec impact

### §4.1 — LL-020 amendment

Append to LL-020's "Round-2 follow-up (2026-05-03)" footer
a new note documenting:

- The 2026-05-04 implementation refinement (variance-
  convolution σ) and the diagnostic that surfaced it.
- Strategy 2's `:benchmarked`-tier evidence via this benchmark.
- Entry-level status remains `:argued`.

Registry row updated to cite the benchmark + this companion.

### §4.2 — No new entries

This companion does not introduce a new LL-ID. The variance-
convolution σ refinement is a Strategy 2 implementation detail,
not a new spec claim. The implementation follows the
multi-strategy design space already documented in LL-020 +
`p_r2b_calibration_confidentiality_companion.md`.

### §4.3 — Counts (post-pass, version 0.0.27)

- Total: 22 (unchanged)
- `:proved`: 0 (unchanged)
- `:tested`: 2 (unchanged)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (unchanged — entry-level status, not
  Strategy-component status)
- `:argued`: 15 (unchanged)
- `:open`: 1 (unchanged)

The 0.0.27 version bump is for the Strategy 2 implementation
fix + benchmark + companion, not for a status change at the
entry level.

---

## §5 — Lessons

1. **End-to-end correctness lives in benchmarks, not unit
   tests.** The original 23 test assertions on
   `differentially_private_envelope` covered formula,
   metadata, argument validation, and reproducibility — every
   function-level invariant. None checked that the function's
   output preserved verification correctness against a genuine
   device. The benchmark caught a clear bug that the unit
   tests missed; this is exactly the test/benchmark split
   discipline articulated in CLAUDE.md §Benchmarking
   discipline (the §added 2026-05-04 in response to this
   finding). Generalisable: every function whose output is
   consumed by a verifier or estimator must have *at least
   one* end-to-end test exercising the consumer, not just the
   producer.
2. **Variance convolution is the right σ mechanism for DP
   over verifier-consumed envelopes.** The naive Gaussian
   mechanism applied to σ creates negativity + floor traps
   that operationally collapse the verifier. The variance-
   convolution form `sqrt(σ² + σ_DP²)` is deterministic,
   strictly inflating, matches the docstring's stated intent,
   and reflects the actual variance of the verifier's residual.
   Trade-off: σ leaks `env.σ` (not DP-protected) — but σ is
   calibration *confidence*, less sensitive than the spectrum
   itself.
3. **DP at moderate ε_DP gives a side-benefit of FPR
   elimination.** The wider σ_pub at ε_DP=10 brought baseline
   FPR from 0.100 to 0.000 across the entire ε_A range,
   alongside the privacy guarantee on the spectrum. This is
   not free — detection saturation moves from ε_A=2 to ε_A=3
   — but it eliminates a denial-of-service vector flagged in
   round-2 §1C-A5. Deployments that already accept some
   detection-power loss for privacy gain FPR reduction
   automatically.
4. **σ_DP / σ_true_min is the operationally meaningful
   predictor of detection degradation.** When this ratio
   exceeds ~3, the smallest-σ component's threshold widens
   enough that adversaries below the σ_DP-equivalent
   magnitude are operationally indistinguishable from the
   genuine device. A deployment design rule: choose ε_DP such
   that `σ_DP ≤ X/3` where X is the smallest adversary
   magnitude that must be detected. This converts the (ε,δ)
   privacy budget into an operational adversary-magnitude
   bound, which is more directly useful for threat-model
   reasoning than the abstract DP guarantee alone.
5. **Negative results enable positive results faster than
   silent retries do.** The 2026-05-04 diagnostic (negative
   result + bug attribution) ran in one session and produced
   a clean fix-and-rerun in the next. A "retry until it
   works" approach would have either papered over the bug
   (Option C in the diagnostic) or produced a result without
   understanding why. The CLAUDE.md §Benchmarking discipline
   addendum codifies this discipline going forward.
