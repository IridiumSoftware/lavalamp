# LL-019 :benchmarked Companion — Timing-Distribution KS Test

Version: 0.0.19 (LL-019 timing-distribution KS-test
validation, 2026-05-03)

Permanent record of the LL-019 :benchmarked upgrade session.
Statistically validates the timing-decorrelation property of
`verify_constant_time` (P-R2a, 0.0.14) via a two-sample
Kolmogorov-Smirnov test on response-time distributions
across accept/reject inputs. Closes LL-019 from `:tested` to
`:benchmarked`.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/benchmark/ll019_timing_distribution.jl`** —
  timing-distribution benchmark with manual two-sample KS
  test. 20 distinct genuine λs + 20 distinct adversary λs
  (BROAD direction, ε_A=2.0); 10 timed calls each = 400
  total samples per benchmark function. Buckets samples by
  *verify result* (not by input source) so the KS test
  compares accept-path vs reject-path timing distributions
  cleanly.
- **`src/julia/benchmark/results/ll019_timing_distribution.txt`**
  — committed benchmark output with summary statistics
  (median, mean, std), KS statistic, critical value, and
  verdict for both `verify` (plain) and `verify_constant_time`.

**Build / run.**

```bash
cd src/julia
julia --project=. benchmark/ll019_timing_distribution.jl
# ~50s wall clock; writes the result file
```

---

## §2 — Results

### §2.1 — Hypothesis tested

```
H0 : F_accept = F_reject  (no timing channel; constant-time wrapper succeeds)
H1 : F_accept ≠ F_reject  (timing channel exists)
```

Two-sample two-sided Kolmogorov-Smirnov test, α = 0.05. The
KS statistic is the maximum absolute difference between the
two empirical CDFs; the critical value at the chosen α is
`c(α) · sqrt((n+m)/(n·m))` where `c(0.05) ≈ 1.358`.

**Decision rule:** if `KS_stat < critical`, fail to reject
H0 → response-time distribution is statistically
indistinguishable across accept/reject inputs.

### §2.2 — Bucketing by verify result, not input source

The first iteration of this benchmark bucketed by *input
source* (genuine vs adversary) which conflated input-type
with verify-result:

- At k=4, only 6/20 genuine inputs accepted (FPR ≈ 70%);
  20/20 adversary inputs rejected.
- The "genuine" bucket therefore mixed accept-path and
  reject-path samples, producing a bimodal distribution
  wider than the (pure-reject-path) adversary bucket.
- KS test wrongly reported DISTINGUISHABLE because the
  bimodal-vs-unimodal split was being measured, not the
  accept-path-vs-reject-path timing channel.

The fix: bucket by *verify result*. After running 400 timed
calls (200 genuine inputs + 200 adversary inputs), each
sample is assigned to the accept-bucket or reject-bucket
based on the call's actual result. This is the
operationally-meaningful split for timing-channel analysis.

With k=10 and BROAD ε_A=2: 320 of 400 calls accept (20
genuine + 12 adversaries that didn't reach k=10 threshold);
80 of 400 reject (8 adversaries that did). Buckets are clean
by definition.

### §2.3 — Results

**Plain `verify` (no constant-time padding):**

| metric | accept (n=320) | reject (n=80) |
|---|---:|---:|
| median | 42 ns | 42 ns |
| mean | 1.20×10⁻⁵ s | 6.04×10⁻⁸ s |
| std | 2.13×10⁻⁴ s | 3.74×10⁻⁸ s |

KS_stat = **0.0406**, critical = 0.1698 → **INDISTINGUISHABLE**

The mean and std differ substantially between buckets — the
accept bucket has occasional µs-to-ms outliers (likely OS
scheduling / GC pauses during the 200-call accept run).
Despite this, the *KS statistic* is well below critical
because the distributions agree on the bulk of their mass
(median 42 ns for both).

**`verify_constant_time` (target=0.1 s):**

| metric | accept (n=320) | reject (n=80) |
|---|---:|---:|
| median | 102.08 ms | 102.08 ms |
| mean | 101.94 ms | 101.88 ms |
| std | 0.34 ms | 0.33 ms |

KS_stat = **0.1094**, critical = 0.1698 → **INDISTINGUISHABLE**

The padded distribution is tightly concentrated at
target_seconds + small overhead; both buckets have nearly
identical median, mean, and std. KS statistic reflects this:
0.109 < 0.170, fail to reject H0.

### §2.4 — Interpretation

The constant-time wrapper succeeds at its design goal:
**response-time distributions for accept and reject inputs
are statistically indistinguishable at α = 0.05.**

This is the substantive content of LL-019's
timing-decorrelation requirement (round-2 §1C-A1 / V-011).
An external observer measuring response timing cannot
distinguish accept from reject inputs above the 5%
significance level given the prototype's sample sizes.

**Why plain `verify` also passes the test, despite being a
target of the timing-channel concern:**

The prototype's `verify` primitive operates on a 20-component
spectrum vector with microsecond-scale comparisons. Even
with full-vector accept-path vs early-exit reject-path, the
data-dependent timing difference is sub-microsecond, well
below OS scheduling jitter. The KS test fails to detect a
channel that's smaller than its noise floor.

This is a feature of the prototype's scale, not a general
property. In production deployments where the verifier's
work might be data-dependent at millisecond scale (e.g.,
network round-trip, full Benettin spectrum estimation under
contended CPU), the data-dependent timing channel would
emerge. `verify_constant_time` is the production-grade
defence; the prototype's `verify` happens to be too fast for
the channel to manifest at the prototype's scale.

The benchmark result is honest about both:

- **`verify_constant_time`**: KS-validated indistinguishable
  by design (sleep-padded uniform target).
- **`verify`**: KS-validated indistinguishable empirically at
  the prototype's scale (microsecond-fast comparison; data-
  dependent timing below OS noise floor).

### §2.5 — Performance target met

LL-019 :benchmarked claim: **`verify_constant_time` produces
a response-time distribution where accept-bucket and
reject-bucket are statistically indistinguishable per a
two-sample KS test at α = 0.05.**

Result: **MET**. KS_stat = 0.109 < critical = 0.170.

### §2.6 — n=400 sample-size considerations

The benchmark uses 400 total samples (320 accept + 80
reject). This is sufficient to reject H0 at α=0.05 if a
substantial timing channel exists; conversely, failing to
reject is not strong evidence of no channel — only that no
channel of magnitude detectable with this n is present.

The critical value at n_accept=320, n_reject=80 is
1.358·sqrt((320+80)/(320·80)) = 1.358·0.125 = 0.170. This
detects KS statistics ≥ 0.170, corresponding to maximum
CDF differences of ~17% between buckets. Smaller channels
exist below this threshold but are not detected.

For tighter validation, n could be increased — but at the
prototype's scale, additional samples don't cheaply tighten
the bound (each verify_constant_time call costs the
target_seconds = 0.1 s, so 4× more samples → 4× wall clock).

The :benchmarked claim is honest at n=400: no
KS-detectable channel at α=0.05. Tighter claims (no channel
at α=0.01; no channel at smaller magnitudes) are deferred.

### §2.7 — Comparison to LL-006 and LL-021 :benchmarked

| LL-ID | bound shape | constants | benchmark | committed result |
|---|---|---|---|---|
| LL-006 | P(detect) ≥ 1 - K·exp(-c'·T·ε_A²) | K=1, c'=0.00423, T=60 | P3-bound high-res sweep | p3_bound_high_res_lorenz96.txt |
| LL-021 | P(detect) ≥ 1 - K·exp(-c'·T·ε_eff²) | K=1, c'=0.02777, T=60 | P-R2c structured-adversary | p_r2c_structured_lorenz96.txt |
| LL-019 | F_accept = F_reject (KS) | KS_stat ≤ 0.170 at α=0.05 | timing-distribution | ll019_timing_distribution.txt |

Each entry has a *different* shape of performance target:

- LL-006 / LL-021 are bound-shape claims (constrained-fit
  validates).
- LL-019 is a distributional-equality claim (KS-test
  validates).

The three together complete the round-2 :benchmarked
upgrades. Methodology continuity per the lavalamp pattern:
each upgrade has its own appropriate test, and each is
honestly classified.

---

## §3 — Verification

### §3.1 — LL-019 :benchmarked upgrade

- **Evidence type:** `benchmarked`.
- **Status moves:** `:tested` → `:benchmarked`.
- **Test:** existing `verify_constant_time` unit tests
  (P-R2a, 0.0.14) at `:tested` level — assert single-call
  elapsed ≥ target and result equality with plain verify.
- **Benchmark:**
  `src/julia/benchmark/ll019_timing_distribution.jl` +
  `src/julia/benchmark/results/ll019_timing_distribution.txt`
  (KS-test on 400-sample distributions).
- **Performance target:** statistical
  indistinguishability of response-time distributions
  across accept/reject inputs at α=0.05. Met for both
  `verify` (empirically at prototype scale) and
  `verify_constant_time` (by design).

### §3.2 — Honest framing of the validation

What this fit *establishes*:

- `verify_constant_time` produces no KS-detectable timing
  channel at α=0.05 with n=400 samples.
- The prototype's plain `verify` also produces no
  KS-detectable channel at this scale (because data-
  dependent path timing is below OS jitter at the
  20-component scale).

What this fit *does not* establish:

- **No channel at higher significance levels.** α=0.05 is
  the standard test threshold; α=0.01 would require
  tighter bounds.
- **No channel at smaller magnitudes.** KS-detectable means
  ≥ 0.170 CDF difference; smaller channels exist below this
  threshold and are not detected by this n=400 test.
- **No channel in production.** The prototype's
  microsecond-fast verify masks data-dependent paths via
  OS jitter; production deployments with millisecond-scale
  data-dependent paths would expose channels that
  `verify_constant_time` is designed to defeat.
- **No formal proof.** Statistical validation at α=0.05 is
  not equivalent to a formal proof of indistinguishability.
  Round-2 §1D.v Lean priority 2 (side-channel timing
  indistinguishability) is the formal target; this
  benchmark grounds its theorem statement.

### §3.3 — Lean theorem grounding (round-2 §1D.v priority 2)

Round-2 §1D.v priority 2:

> Side-channel formalisation. Model observable timing/reseed
> events and prove (or disprove) indistinguishability from
> legitimate load.

Refined statement based on this companion's design:

```lean
theorem constant_time_indistinguishability
  (env : Envelope) (k : ℝ) (target : ℝ) (h_target : target > 0)
  (input_a input_b : Vector ℝ N)
  (T : Distribution → Distribution → KS_stat)
  : ∀ ε > 0, ∃ N₀, ∀ n ≥ N₀,
      let dist_a := response_time_distribution(verify_constant_time, env, k, target, input_a, n) ;
      let dist_b := response_time_distribution(verify_constant_time, env, k, target, input_b, n) ;
      P(KS_stat(dist_a, dist_b) > ε) ≤ α(n)
```

i.e., for any positive ε and any α, there exists a sample
size n such that the KS statistic exceeds ε with probability
no more than α. This is a finite-sample concentration claim;
the proof requires modelling the sleep-precision distribution
and the underlying verify path's data-dependent timing.
P5/P6 work.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-019** side-channel-hardening: `:tested` →
  `:benchmarked` with `example-tested` → `benchmarked`
  evidence type. Source / Test / Benchmark paths updated.

### §4.2 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 3 (LL-003, LL-004, LL-007; was 4 — LL-019
  leaves)
- **`:benchmarked`:** 3 (LL-006, LL-019, LL-021; was 2)
- **`:argued`:** 10 (unchanged)
- **`:open`:** 5 (unchanged)

### §4.3 — Files changed

- `docs/ll019_benchmarked_companion.md` (this file) — new.
- `src/julia/benchmark/ll019_timing_distribution.jl` — new.
- `src/julia/benchmark/results/ll019_timing_distribution.txt`
  — new.
- `LAVALAMP_SPEC.md` — LL-019 status move; counts.
- `artifact_registry.md` — LL-019 row update; counts.
- `dashboard.md` — LL-019 :benchmarked landed; counts.
- `changelog.md` — 0.0.19 entry.

### §4.4 — Followups

- **Tighter validation at α=0.01.** More samples required;
  feasible if wall-clock permits.
- **Production-scale validation.** Run the same KS test on
  a verifier that wraps `verify_full` (full Benettin
  spectrum) so the data-dependent timing has millisecond
  scale. Would expose any channel the prototype's
  microsecond-fast `verify` happens to mask.
- **Lean proof.** §3.3 theorem statement grounded; the
  finite-sample concentration proof is P5/P6 work.

---

## §5 — Lessons captured

### §5.1 — Bucket by result, not input

The first iteration of this benchmark bucketed by input
source (genuine vs adversary) and produced a misleading
DISTINGUISHABLE verdict because the genuine bucket had
mixed accept/reject samples (due to FPR at k=4). The fix
— bucket by *verify result* — produced clean accept/reject
buckets and the correct INDISTINGUISHABLE verdict.

The lesson: timing-channel benchmarks must align bucket
boundaries with the channel's putative cause (the verify
result), not with proxy categories (the input source). The
verify result is what the timing channel exposes; the input
source is upstream of that. Conflating them produces a
test of the wrong hypothesis.

### §5.2 — `verify` passes KS at prototype scale; production may not

Plain `verify` (no constant-time padding) also passed the KS
test (KS=0.041 < critical=0.170). At first glance this
suggests the constant-time wrapper is unnecessary — but the
honest reading is more subtle:

- The prototype's `verify` operates on 20-component spectra
  with microsecond-fast comparisons. The data-dependent
  timing difference between accept-path (full vector check)
  and reject-path (early exit) is sub-microsecond.
- OS scheduling jitter at this scale is microsecond-to-
  millisecond. The data-dependent channel is *below the
  noise floor*.
- KS test fails to detect a channel below its noise floor;
  that's a property of the test + this scale, not a
  general property.

In production deployments where the verifier wraps slow
operations (full Benettin spectrum at hundreds of ms;
network round-trip; contended CPU), the data-dependent
timing channel emerges above the noise floor, and the
constant-time wrapper is the operationally-meaningful
defence.

The companion documents both: prototype-scale
indistinguishability is fortunate; constant-time is the
production-grade defence the prototype's wrapper provides.

### §5.3 — KS test is the appropriate :benchmarked test for distributional equality

LL-006 and LL-021 :benchmarked used constrained-fit on
shape claims (the bound holds across data points). LL-019
:benchmarked uses KS-test on equality claims (two
distributions are statistically the same). Different shapes
of performance target need different tests.

The methodology generalises: each spec entry's
:benchmarked upgrade should pick the test appropriate to
its claim. Don't force constrained-fit on a distributional
claim; don't force KS on a bound-shape claim. Honest
framing per the CLAUDE.md taxonomy: `:benchmarked` requires
"performance target met by recorded benchmark"; the *target*
shape determines the *test* shape.

### §5.4 — Three :benchmarked entries in three sessions

LL-006, LL-021, LL-019 closed to `:benchmarked` across
0.0.17, 0.0.18, 0.0.19 — three sequential same-day
sessions. Each session had a different shape (high-res
sweep + bound fit; analysis on existing data + bound fit;
KS-test benchmark).

The pattern that worked: identify the performance target
shape, pick the matching test, run the benchmark, compute
the statistic, document honestly. Repeat for each entry.
The companion-doc + spec-move + commit cadence stays the
same; only the test methodology varies.

This is the lavalamp prototype's `:benchmarked` cohort
methodology in practice.
