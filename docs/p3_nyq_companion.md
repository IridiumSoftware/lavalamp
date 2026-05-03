# P3-Nyq Companion — Negative Result on Nyquist Detection

Version: 0.0.24 (P3-Nyq adversary-rate benchmark; **negative
result**, 2026-05-03)

Permanent record of the P3-Nyq Nyquist adversary-rate
benchmark session. The benchmark attempted to demonstrate
that the LL-006 residue audit detects sub-Nyquist sensor
adversaries, per the LL-005 architecture-design claim
("an adversary at sub-Nyquist sampling cannot reconstruct
the genuine device's sensor stream"). **The benchmark
returned a negative result**: at the prototype's
configuration, the residue audit does NOT detect sub-Nyquist
adversaries.

This is honest architectural feedback. LL-005's parameter
condition (`f_SDE > 2·BW ∧ f_sensor > BW`) is correctly
configured in the prototype, but the residue audit does not
*enforce* it as an attack vector. Detection of sub-Nyquist
sensor reconstruction requires a different mechanism than
spectrum-residue analysis.

LL-005 entry-level status remains `:argued`. The benchmark
output is committed as audit-trail evidence that this
testing attempt was made and produced a negative result.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/benchmark/p3_nyq_adversary_rate.jl`** —
  benchmark script. Constructs a genuine system with
  `gaussian_noise_stream(σ=1.0, sample_rate=100 Hz,
  t_max=200)`. Constructs adversaries that *observe* the
  genuine stream at sub-Nyquist sample rate `f_adv` and
  *reconstruct* via linear interpolation. Sweeps `f_adv ∈
  {1, 2, 5, 10, 20, 50, 100} Hz` with 20 trials per point.
  Total: 7 × 20 = 140 verify_full calls + 5 calibration +
  20 self-acceptance baseline.
- **`src/julia/benchmark/results/p3_nyq_adversary_rate.txt`**
  — committed result. The negative-finding empirical data.

**Build / run.**

```bash
cd src/julia
julia --project=. benchmark/p3_nyq_adversary_rate.jl
# ~70s wall clock
```

---

## §2 — Results

### §2.1 — Empirical detection-probability sweep

```
Genuine self-acceptance FPR baseline: 1/20 = 0.05

f_adv (Hz)    P(reject)    rejects/trials
----------    ---------    --------------
     1.00        0.00       0 / 20
     2.00        0.20       4 / 20
     5.00        0.10       2 / 20
    10.00        0.10       2 / 20
    20.00        0.00       0 / 20
    50.00        0.05       1 / 20
   100.00        0.15       3 / 20
```

**No monotonic detection trend.** The data scatters between
0% and 20% rejection with no relation to `f_adv`. The
lowest `f_adv` (1 Hz, severely sub-Nyquist) produces the
*lowest* detection rate (0%), while `f_adv = 100` Hz
(matching the genuine sample rate) produces a higher rate
(15%). This is the *opposite* of the Nyquist-detection
prediction.

Wilson 95% confidence intervals for the n=20 samples are
all overlapping; no point is statistically distinguishable
from the FPR baseline at α=0.05.

### §2.2 — Why the negative result

**The residue audit measures time-averaged spectrum
properties; sub-sampling a zero-mean noise stream preserves
time-averaged statistics.** The adversary's reconstructed
stream is low-pass-filtered at `f_adv/2` but has the same
mean (≈ 0 for Gaussian noise) and similar (lower) variance.
The Lorenz-96 spectrum at effective `F = F_base + α · ⟨s⟩`
depends primarily on the time-averaged `⟨F⟩`, which is
invariant under sensor sub-sampling for a zero-mean
sensor.

In other words: the sensor's *bandwidth* is what
sub-sampling destroys; the sensor's *mean* is what the
spectrum cares about. These are decoupled.

This generalizes: **for any zero-mean stochastic sensor,
the residue audit cannot detect sub-Nyquist adversaries.**
The audit's failure mode here is not a calibration issue
or a noise-floor issue — it's structural.

### §2.3 — Architectural implication

The residue audit (LL-006) is the prototype's primary
detection mechanism. Round-2 §1C-A4 already noted that the
chaos-guard (LL-007) is insufficient as a verification
mechanism because adversaries can match λ₁ while diverging
in higher exponents. This benchmark surfaces a related
gap: the residue audit itself doesn't catch sub-Nyquist
adversaries when the sensor is zero-mean.

What the residue audit *does* defend (per existing
benchmarks):

- **V-001 / V-013 parameter-perturbation attacks** (P3-bound
  + LL-021 :benchmarked): adversaries that perturb `α`
  produce different time-averaged forcings, detectable in
  the spectrum.
- **V-005 slow-drift threshold gaming** (LL-006 design):
  per-exponent vector test catches drift in any single
  component.

What the residue audit does NOT defend (this benchmark):

- **V-004 sensor Nyquist failure**: adversaries that
  sub-sample the sensor produce different *temporal
  bandwidth* in the forcing but the same *mean*; spectrum
  analysis is invariant.

LL-005 (Nyquist condition) is therefore a **parameter-level
hygiene requirement**, not an actively-defended attack
surface. It says "configure your SDE and sensor sampling
rates to exceed twice the physical noise bandwidth." The
prototype satisfies this:

- `f_SDE = 1/Δt = 20 Hz` (effective)
- `f_sensor = 100 Hz` (gaussian_noise_stream default)
- For a noise source with bandwidth `BW < 10 Hz`, both
  Nyquist constraints are met.

But satisfying the parameter constraint does not mean
adversaries who violate Nyquist are *detected* by the
residue audit. They aren't, at this configuration.

### §2.4 — What would detect Nyquist violations

Three potential mechanisms not currently in the prototype:

1. **Trajectory-level checkpoint comparison.** Compare the
   trajectory at specific time-points against the
   registered trajectory at those points. Sub-Nyquist
   adversaries' trajectories diverge from genuine's even
   when their spectra agree. Round-1 explicitly *rejected*
   this approach (scalar-KL audit on raw trajectory) in
   favour of the spectrum audit. Re-introducing it for the
   Nyquist case would require careful round-3 review: it
   exposes the trajectory-level comparison's slow-drift
   weakness (V-005) that the spectrum audit fixed.

2. **FFT-based audit.** Compute the Fourier transform of
   the trajectory's components; compare power-spectral
   density against a registered baseline. Sub-Nyquist
   adversaries lose high-frequency components, detectable
   in the PSD. This adds substantial new infrastructure;
   not in the prototype's current shape.

3. **Sensor-authenticity check (LL-016).** If the adversary
   physically samples the sensor at sub-Nyquist, that
   manipulation is itself observable — multi-sensor
   cross-validation would catch the rate mismatch (e.g.,
   the genuine device's thermal sensor varies at f_genuine
   while the adversary's reconstructed sensor varies at
   f_adv; correlation with battery discharge rate would
   distinguish). LL-016 is :argued; this benchmark
   reinforces that LL-016 is the load-bearing defence
   against sub-Nyquist attacks, not LL-006.

### §2.5 — Honest tier framing for LL-005

LL-005's claim has two parts:

- **(a) Parameter constraint:** `f_SDE > 2·BW ∧ f_sensor >
  BW`. The prototype satisfies this by construction
  (Δt=0.05; gaussian_noise_stream default sample rate). This
  part is :argued via inspection; could move to :tested
  via a dedicated parameter-validation test.
- **(b) Adversary detection:** sub-Nyquist adversaries are
  detected. This benchmark shows: **NOT by the residue
  audit at the prototype's configuration.** Detection
  requires LL-016 sensor authenticity (already :argued) or
  a not-yet-implemented mechanism.

The honest reading: LL-005 entry-level stays `:argued`. The
benchmark output is committed as evidence that the
parameter-level constraint is correctly configured AND that
the adversary-detection claim is not validated by the
residue audit alone. The notes amendment captures this
distinction.

This is the round-2 lesson generalised: spec entries
sometimes have *implicit sub-claims* (parameter compliance
+ attack defence). Implementing one without the other is
honest as `:argued` until both sub-claims have evidence.

---

## §3 — Verification

### §3.1 — LL-005 entry-level status

- **Evidence type:** `manual` (unchanged).
- **Status:** `:argued` (unchanged).
- **Source:** `docs/architecture_design_companion.md` §2.4,
  §3.6 + this companion's §2 (negative result on adversary
  detection via residue audit).

### §3.2 — Why no upgrade

Round-2 § "honest framing" + this benchmark's negative
result establishes that:

- The parameter side (`f_SDE > 2·BW`) is correctly
  configured.
- The adversary side (detection of sub-Nyquist
  reconstruction) is NOT validated by the residue audit at
  the prototype's configuration.

Moving LL-005 to `:tested` would require either a
parameter-validation test (one half of the claim) or a
working adversary-detection mechanism (the other half).
The honest framing stays at `:argued`: the claim's full
content isn't `:tested`-tier evidenced.

### §3.3 — Benchmark output as audit-trail evidence

Even though the benchmark returns a negative result, its
output is committed as audit-trail evidence:

- A future session attempting LL-005 :tested can see this
  prior attempt and learn from it.
- Round-3 reviewers can use this as architectural feedback.
- The discipline of "every benchmark run produces a
  committed result, positive or negative" is honoured.

The output file format documents the negative finding
inline, so a reader of just the file (without this
companion) gets the context.

---

## §4 — Spec impact

### §4.1 — Status moves

None. LL-005 stays `:argued`.

### §4.2 — Notes amendment on LL-005

The LL-005 spec entry's notes are amended to record the
benchmark's negative finding:

> P3-Nyq adversary-rate benchmark (0.0.24,
> `docs/p3_nyq_companion.md`) attempted to demonstrate
> that the residue audit detects sub-Nyquist adversaries.
> Result: negative. The residue audit does not detect
> sub-Nyquist sensor reconstruction at the prototype's
> configuration because zero-mean Gaussian noise has the
> same time-averaged statistics under sub-sampling. LL-005
> is therefore a parameter-level hygiene requirement
> (correctly configured) rather than an actively-defended
> attack surface. Sub-Nyquist adversary detection requires
> LL-016 sensor authenticity (already :argued) or a
> different mechanism (FFT-based audit; trajectory
> checkpoint comparison) — neither in the prototype's
> current shape.

### §4.3 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 3 (LL-003, LL-004, LL-007)
- **`:benchmarked`:** 3 (LL-006, LL-019, LL-021)
- **`:argued`:** 14 (unchanged)
- **`:open`:** 1 (LL-015) (unchanged)

Counts unchanged. The benchmark adds evidence to LL-005
without changing its status.

### §4.4 — Files changed

- `docs/p3_nyq_companion.md` (this file) — new.
- `src/julia/benchmark/p3_nyq_adversary_rate.jl` — new.
- `src/julia/benchmark/results/p3_nyq_adversary_rate.txt`
  — new (committed empirical data).
- `LAVALAMP_SPEC.md` — LL-005 notes amendment; version.
- `artifact_registry.md` — version.
- `dashboard.md` — P3-Nyq landed (negative result); spec
  status counts (unchanged).
- `changelog.md` — 0.0.24 entry.

### §4.5 — Followups

- **Round-3 architectural input.** This benchmark's
  finding ("residue audit doesn't catch Nyquist
  violations") is round-3 input. The synthesis-team should
  evaluate whether (a) the prototype's residue-audit-only
  defence is sufficient given LL-016 covers the gap, or
  (b) an FFT / trajectory-checkpoint audit is needed.
- **LL-016 implementation.** The benchmark reinforces that
  LL-016 (sensor authenticity) is the load-bearing
  defence against this attack class. Implementation is P7
  / P5 work per the P-R2b design (TPM attestation,
  multi-sensor cross-validation, anomaly-flagging).
- **FFT-based audit (deferred).** A new audit mechanism
  using PSD comparison would close the gap. New
  spec entry; out of scope per current constraints.
- **Parameter-validation test for LL-005.** A trivial
  test asserting f_SDE > 2·BW and f_sensor > BW for
  given parameters could move part-(a) of LL-005 to
  `:tested`. Cost is small but the entry's claim is
  larger than just parameter compliance; the partial
  upgrade would be misleading without addressing the
  adversary-side gap.

---

## §5 — Lessons captured

### §5.1 — Negative results are valuable evidence

The benchmark didn't demonstrate the expected Nyquist
detection. This is *not a failure*; it's empirical data
that surfaces an architectural gap. The lavalamp CLAUDE.md
"honest framing" rule applies here: don't elevate LL-005
to `:tested` because the benchmark didn't support the
upgrade.

The committed benchmark output is the audit trail. Future
sessions or round-3 reviewers can see exactly what was
tested, with what configuration, and what was found. That's
more useful than either "no benchmark exists" or
"benchmark exists with a fudged positive result."

### §5.2 — Spec entries can have implicit sub-claims

LL-005's claim has two parts: parameter-constraint
compliance, and adversary detection. The prototype handles
the first part (correctly-configured rates) but not the
second (the residue audit doesn't catch the attack).

This pattern generalises. When a spec entry has multiple
implicit sub-claims, the entry-level status reflects the
*weakest* sub-claim's evidence. Notes record per-sub-claim
progress. This is the same lesson as 0.0.23 (LL-020's
multi-strategy approach + Strategy 2 implementation
without entry-level upgrade).

The honest pattern: don't promote entry-level status until
*all* sub-claims have evidence at the target tier. Partial
implementations live in notes.

### §5.3 — The audit catches some attack classes, not all

This benchmark surfaces what the round-1 → round-2 design
arc had implicitly: the residue audit (LL-006) is one
detection mechanism. It catches parameter-perturbation
attacks well (V-001, V-005, V-013). It does not catch
sensor-bandwidth attacks (V-004 Nyquist failure) at the
prototype's configuration.

Defence-in-depth means multiple mechanisms covering
different attack surfaces:

- LL-006 residue audit → parameter perturbations
- LL-007 chaos-guard → periodic-window stalls
- LL-016 sensor authenticity → sensor-input poisoning + Nyquist
- LL-017 + LL-019 no-oracle / constant-time → response-channel
  side channels
- LL-019 cadence requirement → Wolf-vs-Benettin asymmetry
- LL-020 calibration confidentiality → registration-channel
  observation
- LL-021 worst-case bound → structured adversary geometry

Each mechanism covers a slice. No single mechanism covers
all attack surfaces; the architecture's security posture
depends on the *composition* of mechanisms.

### §5.4 — When in doubt, document the negative

The temptation when a benchmark fails: try different
parameters until it succeeds. Sometimes that's right
(sampling-noise-induced scatter that more trials would
fix). Sometimes it's wrong (the underlying mechanism
genuinely doesn't apply at this scale, and parameter
fiddling is overfitting).

The discipline check: does the negative result come from
*sampling noise* (trials too few; effect smaller than
detection threshold) or from *structural gap* (the
mechanism the benchmark tests for doesn't exist in the
implementation)?

For this benchmark, increasing from 5 to 20 trials didn't
produce a trend — the negative result is structural, not
sample-size-limited. Documenting it honestly is the right
move.
