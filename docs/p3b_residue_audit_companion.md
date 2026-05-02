# P3b Residue-Audit Companion

Version: 0.0.9 (P3b residue audit + detection-probability
benchmark, 2026-05-02)

Permanent record of the P3b session: implementing the
Lyapunov-spectrum residue audit per architecture-design §2.1
(LL-006) and the synthetic-adversary detection-probability
benchmark. Closes LL-006 to `:tested` with `example-tested`
evidence (mechanism unit tests + a committed
detection-probability sweep). Does *not* close to
`:benchmarked` — that requires deriving the §2.1 bound's
constants (K, c, δ_A as a function of ε_A) from the empirical
data, which is a follow-up.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/src/Audit.jl`** — verifier module.
  - `Envelope` struct: registered spectrum + per-exponent
    estimator σ + n_trials + metadata.
  - `register_envelope(ds_factory; n_trials, N, Δt, Ttr,
    lyapunov_fn=lyapunov_spectrum)` — calibrates an envelope
    from `n_trials` independent runs of the genuine device.
    Per-exponent σ is the Bessel-corrected sample standard
    deviation across calibration trials.
  - `residue(λs, env)` — per-exponent absolute differences.
  - `verify(λs, env; k=4.0)` — vector per-exponent test:
    ACCEPT iff `|λs[i] - env.spectrum[i]| < k · env.σ[i]` for
    every i. Returns `Bool` only — no oracle leak (LL-017).
  - `synthetic_adversary(p, ε_A; rng, direction=nothing)` —
    unit-vector perturbation in α-space, magnitude exactly ε_A
    (rather than the noisier `ε_A · randn` semantics). Cleaner
    detection-probability sweeps.

- **`src/julia/src/LavaLamp.jl`** — restructured submodule
  loading. `Sensors` is now a top-level submodule (was nested
  inside `Engine`); `Engine` and `Audit` both reference
  Sensors types via `..Sensors`. New re-exports for the audit
  primitives.

- **`src/julia/src/Engine.jl`** — adjusts imports to the
  flattened submodule layout.

- **`src/julia/test/runtests.jl`** — adds 18 audit-related
  assertions across 2 new `@testset`s:
  - **Audit module: mechanism + envelope smoke** (10
    assertions): direct `Envelope` construction, residue
    correctness (zero-residue + offset-residue), `verify`
    Bool return semantics, `synthetic_adversary` L2-magnitude
    preservation and ε_A=0 identity, wrong-length residue
    error.
  - **Audit: register, self-accept, strong-adversary reject**
    (8 assertions): envelope structure, self-acceptance at
    conservative k=10 (deterministic pass), strong adversary
    (ε_A=3.0) rejected at working k=5.0, residue-magnitude
    sanity. `n_trials=10` calibration at `N_benettin=1200`.

- **`src/julia/benchmark/p3b_detection_probability.jl`** —
  benchmark script. Sweeps `ε_A ∈ {0.0, 0.1, 0.3, 0.5, 0.75,
  1.0, 1.5, 2.0, 3.0, 5.0}` with 10 trials per point;
  deterministic seeds; writes a plain-text result table to
  `benchmark/results/p3b_detection_lorenz96.txt`. Total wall
  clock ~25 s (calibration ~4 s + sweep ~20 s).

- **`src/julia/benchmark/results/p3b_detection_lorenz96.txt`**
  — committed benchmark output. The empirical detection-
  probability data backing LL-006's `example-tested` upgrade.

**Build / run.**

```bash
cd src/julia
julia --project=. -e 'using Pkg; Pkg.test()'         # 47 tests, ~78s
julia --project=. benchmark/p3b_detection_probability.jl  # ~25s
```

**Wall-clock metrics on the dev host.**

- Test suite: 47 assertions / 77.6 s wall clock (was 29 / 40 s
  in 0.0.8). Increase comes mainly from the 10-trial envelope
  calibration (~30 s) plus 2 verify spectra (~3 s). Roughly
  consistent with the cost predictions in `p3_baseline_companion.md`
  §2.4: full-spectrum Benettin at N=20 is ~1.5 s per estimate.
- Benchmark script: ~25 s total. 10 ε_A points × 10 trials = 100
  spectrum estimates at N=20.

---

## §2 — Results

### §2.1 — Verifier mechanism

The vector per-exponent test is implemented exactly as the
design-companion §2.1 specifies. Threshold is `k · σ_i` where
`σ_i` is the per-exponent estimator standard deviation
calibrated from n_trials registration runs, and `k` is the
caller-supplied multiplier. Default `k=4` corresponds to the
~99.997% per-component coverage of a Gaussian estimator;
simultaneous coverage over ~20 components is ~99.9%.

Strict comparison `res ≥ k·σ` rejects on equality, so a
zero-σ component (degenerate calibration) rejects any
non-exact match. This is the safe-default behaviour for
single-trial calibrations.

### §2.2 — Synthetic-adversary semantics: unit-vector + magnitude

Initial implementation used `ε_A · randn(n)` for the adversary
perturbation. This produced highly variable realized
perturbation magnitudes per trial, especially for small `n`
(the genuine system here has `n=1` coupling channel). At
`ε_A=2.0` for example, individual trials saw realized
perturbations of -0.5 to +3.5, so the spectrum gap δ_A
fluctuated wildly across nominally-identical-ε_A trials.

Fix: `synthetic_adversary(p, ε_A; rng)` now constructs a unit
vector `û = randn(rng, n) / ‖randn(rng, n)‖` and returns
`alphas + ε_A · û`. The realized perturbation has L2 magnitude
exactly `ε_A`, removing the per-trial magnitude variability
and producing a clean detection-probability curve.

For n=1, this reduces to alphas + ε_A · sign(randn) — i.e.,
deterministic ±ε_A perturbation. For larger n, û is uniformly
distributed on the unit sphere.

### §2.3 — Bug found in initial smoke test

Worth recording: the first detection-probability sweep returned
0/5 rejection at ε_A=1.0, which seemed inconsistent with the
sensor-coupling non-degeneracy result from 0.0.8 (Δλ₁ ≈ 0.30
at α=1, +0.59 at α=2). The cause: the smoke test used a
constant sensor *value of 0.0* with α=1.0. The dynamics depend
on `α · sensor_value · b[i]` per dim, so when sensor_value=0
the alphas are dynamically irrelevant — adversary perturbations
of α had zero effect on the trajectory. Genuine and adversary
systems were dynamically identical; the residue audit was
measuring noise-vs-noise.

Fix: smoke + benchmark + tests use `constant_stream(1.0)` so
α perturbations actually propagate into the dynamics.

This is a useful design-time gotcha to record. In production,
`b[i]` and stream values would be calibrated so the
sensor-coupling has measurable effect; this kind of degenerate
zero-sensor configuration would be caught at registration time
(σ would be tiny because the dynamics never sees the sensors).
The architecture-design §2.4 non-degeneracy condition
(∂λ/∂s full rank) is the formal name for this requirement.

### §2.4 — Empirical detection-probability surface

Committed result `benchmark/results/p3b_detection_lorenz96.txt`:

```
ε_A     p_reject   max_residue_max   max_residue_mean
-----   --------   ---------------   ----------------
 0.00       0.10            0.4567             0.2256
 0.10       0.00            0.2935             0.2062
 0.30       0.10            0.4089             0.2432
 0.50       0.10            0.3802             0.2472
 0.75       0.10            0.5301             0.3716
 1.00       0.50            0.8103             0.4569
 1.50       0.60            0.6795             0.5118
 2.00       1.00            0.9870             0.7783
 3.00       1.00            1.2547             1.0962
 5.00       1.00            2.0832             1.7910
```

Three regimes:

- **Sub-threshold (ε_A ≤ 0.75).** P(reject) ≈ 0.10 = baseline
  FPR. Adversary perturbation produces a spectrum gap δ_A
  comparable to or below the estimator noise floor, and the
  audit cannot distinguish adversary from genuine. The 0/10
  at ε_A=0.10 vs 1/10 at ε_A=0 is sampling variance, not
  signal.
- **Transition (0.75 < ε_A < 2.0).** P(reject) climbs from
  0.10 to 1.00 sigmoidally. At ε_A=1.0, half the adversaries
  evade detection, half are caught. The transition midpoint
  is the operationally-meaningful detection threshold for this
  configuration.
- **Saturation (ε_A ≥ 2.0).** P(reject) = 1.00 across all 10
  trials. The spectrum gap δ_A is well above the estimator
  noise floor; rejection is deterministic.

The shape — flat low-FPR baseline, sigmoidal transition,
saturated-1 high regime — is exactly what the design-companion
§2.1 detection-probability bound P(detect) ≥ 1 - K·exp(-c·T·δ²)
predicts. Empirically validates the bound's *shape*; deriving
the constants (K, c, and the ε_A-to-δ_A mapping) is a
`:benchmarked`-level upgrade follow-up.

### §2.5 — Why the framing stops at `:tested`, not `:benchmarked`

The CLAUDE.md taxonomy distinguishes `example-tested` (passes
hand-written tests) from `benchmarked` (performance target met
by recorded benchmark). The benchmark script produces
quantitative data, but does not assert "P(detect) ≥ 0.95 at
ε_A ≥ X" or any other concrete performance target. The bound's
constants (K, c, δ_A(ε_A)) have not been derived from the
data; without them, "the bound holds" is a shape claim, not a
numeric claim.

For LL-006 to upgrade to `:benchmarked`, a follow-up needs to:

1. Calibrate the ε_A → δ_A mapping (run a separate sweep
   measuring the actual spectrum gap, not just the rejection
   rate).
2. Fit K, c against the empirical curve.
3. Verify `P_empirical(detect) ≥ 1 - K·exp(-c·T·δ_A²)` holds
   with the fitted constants — i.e., verify that the empirical
   curve is *above* the bound, not just that they're shape-
   compatible.

Until this calibration is done, the honest classification is
`:tested` with `example-tested` evidence and a benchmark output
file in the registry.

### §2.6 — Module restructure: Sensors at top level

The 0.0.8 layout had `Sensors` nested inside `Engine` (Engine
included Sensors). Adding `Audit` as a sibling of Engine would
have required either reaching back through the parent
(`..Engine.Sensors`) or duplicating Sensors. Cleaner: pull
`Sensors` to top level under `LavaLamp`; `Engine` and `Audit`
both reference it via `..Sensors`.

LavaLamp.jl now has:

```julia
include("Sensors.jl")  # first — others depend on it
include("Engine.jl")   # uses ..Sensors
include("Audit.jl")    # uses ..Sensors and ..Engine
```

This is a minor refactor with no external API change. Re-exports
through LavaLamp are unchanged in semantics.

---

## §3 — Verification

### §3.1 — LL-006 Lyapunov-spectrum residue audit

- **Evidence type:** `example-tested`.
- **Status moves:** `:argued` → `:tested`.
- **Test:** `src/julia/test/runtests.jl` audit `@testset`s
  (18 new assertions; 47/47 pass via `Pkg.test()` in ~78 s).
  Backed by `src/julia/benchmark/results/p3b_detection_lorenz96.txt`
  for the empirical detection-probability surface.
- **Source:** `src/julia/src/Audit.jl`.

### §3.2 — Why other entries don't move

- **LL-005 (sensor Nyquist condition).** The residue audit
  exercises sensor coupling at the prototype's chosen f_SDE
  but does not benchmark adversary-rate vs detection. Stays
  `:argued`. P3-Nyq follow-up.
- **LL-007 (chaos-guard).** Untouched this session. Stays
  `:argued`. P3c.
- **LL-008 (resolution-bounded security claim).** The
  detection-probability surface is consistent with the §2.1
  bound's shape — but the bound's *constants* (K, c) and the
  per-class A1..A6 quantification (LL-018) are not derived
  here. Stays `:argued`. P5/P6 Lean target.
- **LL-017 (verification no-oracle).** `verify` returns Bool
  only. The mechanism is implemented per the design; whether
  it leaks information through timing or other side channels
  is a deployment-side concern not exercisable in pure-Julia
  unit tests. Stays `:argued`.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-006**: `:argued` → `:tested` with `manual` →
  `example-tested` evidence type. Source `src/julia/src/Audit.jl`;
  Test `src/julia/test/runtests.jl`; supporting benchmark
  `src/julia/benchmark/results/p3b_detection_lorenz96.txt`.

### §4.2 — Updated counts

- **Total:** 18 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 3 (LL-003, LL-004, LL-006)
- **`:benchmarked`:** 0
- **`:argued`:** 10 (LL-005, LL-007, LL-008, LL-011, LL-012,
  LL-013, LL-014, LL-016, LL-017, LL-018)
- **`:open`:** 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

### §4.3 — Files changed in this commit

- `docs/p3b_residue_audit_companion.md` (this file) — new.
- `src/julia/src/Audit.jl` — new.
- `src/julia/src/Sensors.jl` — unchanged.
- `src/julia/src/Engine.jl` — adjusted imports (Sensors now
  sibling).
- `src/julia/src/LavaLamp.jl` — submodule load order; new
  Audit re-exports.
- `src/julia/test/runtests.jl` — 18 new assertions.
- `src/julia/benchmark/p3b_detection_probability.jl` — new.
- `src/julia/benchmark/results/p3b_detection_lorenz96.txt` —
  new (committed benchmark output).
- `LAVALAMP_SPEC.md` — LL-006 status move.
- `artifact_registry.md` — LL-006 row update; counts.
- `dashboard.md` — version, status summary, P3 sub-status.
- `changelog.md` — 0.0.9 entry top-of-file.

### §4.4 — Followups

- **Calibrate the §2.1 bound constants** for `:benchmarked`
  upgrade. Two paths:
  - Empirical: fit (K, c, δ_A(ε_A)) to the existing curve;
    verify monotonic margin against the bound.
  - Theoretical: derive c from Eckmann-Ruelle estimator
    variance results; derive δ_A(ε_A) from a small ∂λ/∂α
    benchmark; predict P(detect) and compare to empirical.
  - A combined fit-and-bound approach is the standard
    chaos-detection-bound methodology.
- **P3c — Chaos-guard.** Now the natural next slice. Uses
  Audit's envelope structure to detect when the live spectrum
  has collapsed to periodic-window. Cheaper than P3b
  (single-exponent estimator).
- **P3-Nyq — Adversary-rate Nyquist benchmark.** Closes LL-005
  to `:tested`. Folds into the existing benchmark framework:
  generate adversaries with sub-Nyquist sensor sampling and
  measure whether they can evade detection.
- **CI workflow.** Recommended in 0.0.7 / 0.0.8 followups; not
  yet landed. With test wall-clock now at 78 s, manual reruns
  start to feel slow. GitHub Actions running `Pkg.test()` on
  push closes the gap. Small-lift landing.
- **Test compute budget revisit.** P3a closed in ~40 s; P3b
  added ~38 s (calibration dominates). P3c will add another
  spectrum-running `@testset`. By P3-Nyq the test suite will
  likely be ~3 min. Worth either (a) splitting into a fast
  smoke suite + a slow full suite, or (b) reducing test
  trial counts in the suite while keeping the headline
  benchmarks separate.

---

## §5 — Lessons captured

### §5.1 — Stub-stream gotcha: zero-sensor degeneracy

The first smoke test used a constant sensor at value 0.0 and
saw zero detection signal. Cause: the dynamics' dependence on
α is multiplicative through the sensor value; zero sensor
makes α dynamically irrelevant. The spectrum was unchanged
between genuine and adversary systems.

This is a *non-degeneracy violation* in the architecture-
design §2.4 sense. The dev-host gotcha generalises: any
calibration where the genuine system happens to sit at a
zero-σ component (degenerate manifold in coupling-parameter
space) is undetectable by the residue audit. Production
deployments need to pick coupling-parameter combinations that
empirically verify ∂λ/∂α full rank at the operating point.

For the prototype, the rule is: **don't use zero sensor values
for non-degeneracy tests.** Documented in the Audit module
docstring and reflected in the benchmark/test parameters
(constant_stream(1.0) in all cases).

### §5.2 — Unit-vector vs randn perturbation

For detection-probability sweeps, deterministic perturbation
magnitude matters more than direction-distribution. `randn`
perturbations of magnitude ε_A produce per-trial magnitudes
that vary as much as 5× across trials at small n; this
artificially flattens the detection-probability curve and
masks the §2.1 bound's actual shape.

The cleaner semantic — `unit-vector × ε_A` — gives:
- Deterministic perturbation magnitude across trials;
- Direction sampled from the unit sphere (uniform in n>1, ±1
  in n=1);
- L2 magnitude `‖perturbed - genuine‖₂ = ε_A` exactly.

This matches the standard adversarial-ML threat-model
parameterisation ("ε-ball perturbation"), and reproduces
sigmoid detection curves cleanly.

Documented in the `synthetic_adversary` docstring.

### §5.3 — Benchmark output as `:benchmarked` evidence requires bound-fitting

The CLAUDE.md taxonomy distinction between `:tested` and
`:benchmarked` is not just "ran a benchmark" vs "ran a test."
`:benchmarked` requires *meeting a performance target*. For
LL-006's detection-probability surface, "meeting the bound"
requires deriving the bound's constants and comparing.

This session's benchmark validates the bound's *shape*, which
is `:tested`-level evidence. A separate session can derive
K, c, and the ε_A → δ_A mapping, and check the empirical
data against the bound's prediction; that closes LL-006 to
`:benchmarked`.

This is honest framing per the architecture-design §2.5 norm:
calibrated quantitative claims live in the implementation
and benchmark output, not in the spec entry itself, until
they can be verified against a stated target.
