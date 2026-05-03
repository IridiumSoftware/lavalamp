# LL-020 Strategy 2 ε-DP Envelope Companion

Version: 0.0.23 (LL-020 Strategy 2 — ε-DP envelope stub
implemented and example-tested, 2026-05-03)

Permanent record of the ε-DP envelope stub session.
Implements Strategy 2 of LL-020 (calibration confidentiality)
per the P-R2b design (`docs/p_r2b_calibration_confidentiality_companion.md`
§2.2). Strategy 2 is the universal-fallback strategy for
deployments without TPM hardware support or where envelope
publication is required.

LL-020 entry-level status remains `:argued`. Strategy 2 is
now `:tested`-tier per the new code + tests; Strategies 1
(TPM-sealed) and 3 (Shamir threshold) remain `:argued` per
the P-R2b design. The entry's claim is the three-strategy
approach as a whole; partial implementation does not test
the entry's claim.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/src/Audit.jl`** — adds
  `differentially_private_envelope(env; ε, δ=1e-6,
  sensitivity=0.1, rng=default_rng())`. Returns a new
  `Envelope` with each component of `env.spectrum` and
  `env.σ` perturbed by `Gaussian(0, σ_DP²)` where:

  ```
  σ_DP = sensitivity · sqrt(2 · ln(1.25 / δ)) / ε
  ```

  This is the Gaussian mechanism for `(ε, δ)`-DP
  (Dwork & Roth §A.1 / Thm A.1). Implementation details:
  - σ floored at 1e-10 to prevent negative perturbations
    breaking the verifier (k·σ < 0 would reject everything).
  - DP metadata recorded: `dp_ε`, `dp_δ`,
    `dp_sensitivity`, `dp_σ`, `dp_perturbed=true`.
  - Original metadata preserved.

- **`src/julia/src/LavaLamp.jl`** — re-exports the new
  symbol.

- **`src/julia/test/runtests.jl`** — adds 23 assertions in
  one `@testset`: type checks; length preservation;
  `n_trials` preserved; DP metadata recorded; original
  metadata preserved; σ floor enforced; tight-ε produces
  large `σ_DP` and substantial perturbation; loose-ε
  produces tiny `σ_DP` and near-identity perturbation;
  argument validation (ε ≤ 0, δ ≤ 0, δ ≥ 1, sensitivity ≤ 0
  all throw); reproducibility (same seed → same result).

**Build / run.**

```bash
cd src/julia
julia --project=. -e 'using Pkg; Pkg.test()'  # 117/117 pass in ~52s
```

---

## §2 — Results

### §2.1 — The Gaussian mechanism for envelope publication

The (ε, δ)-DP Gaussian mechanism (Dwork & Roth, Thm A.1):
for a function `f` with L2-sensitivity `Δ_2`, releasing
`f(x) + N(0, σ²·I)` satisfies `(ε, δ)`-DP when

```
σ ≥ Δ_2 · sqrt(2 · ln(1.25 / δ)) / ε
```

Specialised to envelope publication: the function `f` is
"compute the envelope from the calibration trials"; the
sensitivity `Δ_2` is the maximum L2 change in the envelope
under swapping a single calibration trial.

The implementation chooses σ at the *minimum* allowed by
the formula (equality), which gives the *tightest* bound at
the chosen (ε, δ). Larger σ would also satisfy DP but would
be operationally wasteful (more noise → less detection
power for the same privacy guarantee).

### §2.2 — Sensitivity bound argument

The L2-sensitivity `Δ_2` of `register_envelope` w.r.t.
swapping a single calibration trial is bounded by the
per-exponent λ̂ deviation across trials. Empirically, with
n_trials = 5–10 and N_benettin ≈ 1200, the per-exponent σ
of the registered envelope (i.e., `env.σ`) is in the range
0.05–0.2 at the prototype's configuration.

Sensitivity choice: `Δ_2 ≈ 0.1` is the prototype's default.
This is a *conservative* bound covering most genuine
configurations. Production deployments should re-derive
sensitivity from concentration inequalities on the chosen
SDE's spectrum estimator, not from the empirical σ.

The default of 0.1 is honest at the prototype's scale; a
larger sensitivity bound would weaken the DP guarantee at
the same ε; a smaller bound would tighten it but might
violate the actual L2-sensitivity (breaking the privacy
guarantee).

### §2.3 — Privacy-vs-detection-power trade-off

The DP-perturbed envelope is wider (each `σ` component has
`Gaussian(0, σ_DP²)` noise added, then floored at 1e-10).
The verifier's threshold `k · σ_perturbed[i]` is therefore
*wider* than `k · σ_original[i]` in expectation — accept
zone enlarges, reject zone shrinks.

For the verifier:

- **Genuine acceptance** *increases* (lower FPR; the
  perturbed thresholds tolerate more genuine-device noise).
- **Adversary detection** *decreases* (lower TPR;
  adversaries that were just outside the original
  rejection ball can now slip inside the wider perturbed
  rejection ball).

The trade-off is fundamental to the DP mechanism: privacy
is bought with detection power. The DP formula's
parameters quantify this:

- **Tighter ε** (more privacy) → larger `σ_DP` → more
  detection-power loss.
- **Looser ε** (less privacy) → smaller `σ_DP` → less
  detection-power loss but weaker privacy guarantee.

A future benchmark could trace this curve empirically for
the prototype: at ε ∈ {0.1, 0.5, 1.0, 2.0, ∞}, run the
P3-bound detection-probability sweep against the
DP-perturbed envelope and fit the bound.

For this session, the curve is documented in concept; the
benchmark is deferred (it's a quadratic combination of
this session's work × the P3-bound work and adds session
volume without a substantial new claim).

### §2.4 — Why σ floor (1e-10) is DP-safe

The implementation clamps `σ_pub = max(σ_pub, 1e-10)` after
the noise addition. Without this clamp, Gaussian noise can
produce negative `σ`, which would make `k·σ < 0` and the
vector test would reject every λ̂ (because `|Δ| < negative`
is never true).

The clamp is **DP-safe** because it's a data-independent
post-processing step: applying any data-independent
transformation to a DP output preserves the DP guarantee
(Dwork & Roth Prop 2.1, "post-processing immunity"). The
clamp does not depend on the input data; it's a fixed
floor.

### §2.5 — Empirical demonstration of σ_DP scaling

From the smoke run (not committed as a benchmark; documented
here for the record):

| ε | δ | sensitivity | σ_DP | perturbation magnitude (sample) |
|---:|---:|---:|---:|---:|
| 0.5 | 1e-6 | 0.1 | 1.060 | spectrum[1] 1.887 → 1.502 (Δ=0.39) |
| 1.0 | 1e-6 | 0.1 | 0.530 | spectrum[1] perturbed by ~0.2 |
| 10.0 | 1e-6 | 0.1 | 0.053 | spectrum[1] perturbed by ~0.02 |
| 1e6 | 1e-6 | 0.001 | 5.3e-9 | essentially identity |

The σ_DP scales as expected:

- σ_DP ∝ sensitivity (linear)
- σ_DP ∝ 1/ε (linear in inverse)
- σ_DP ∝ sqrt(log(1/δ)) (very slow growth)

### §2.6 — Reproducibility

The `rng::AbstractRNG` parameter makes the noise sampling
deterministic given the seed. Same seed → same DP-perturbed
envelope, byte-for-byte. This is essential for:

- Deterministic test assertions (the test suite uses
  `Random.Xoshiro(seed)` and asserts specific output).
- Audit-trail benchmarks where the perturbed envelope must
  be reproducible from the seed alone.

Production deployments should pass `Random.default_rng()`
or a TRNG-backed RNG; the seeded path is for testing /
benchmarking only.

---

## §3 — Verification

### §3.1 — LL-020 Strategy 2 example-tested

- **Evidence type for Strategy 2:** `example-tested`.
- **Test:** `src/julia/test/runtests.jl` LL-020 `@testset`
  (23 assertions). Passes via `Pkg.test()` in the full
  suite (117/117 in ~52s).
- **Source:** `src/julia/src/Audit.jl`
  (`differentially_private_envelope`).

### §3.2 — Why LL-020 entry-level stays `:argued`

LL-020's claim is the three-strategy approach as a whole:

> registered envelope sealed against registration-channel
> observers via three layered strategies (P-R2b design):
> (1) TPM-sealed storage on the verifier; (2) ε-DP
> perturbation; (3) Shamir-style multi-party threshold
> scheme.

This session implements (2). Strategies (1) and (3) remain
unimplemented:

- Strategy 1 (TPM-sealed) requires platform FFI to TPM /
  Secure Enclave / TrustZone — out of Julia-prototype scope
  per the language-tier discipline.
- Strategy 3 (Shamir threshold) requires finite-field
  cryptography — typically implemented in Haskell (P5) or
  C/C++ (P7).

Moving LL-020 to `:tested` would overstate: the *entry*'s
claim is the multi-strategy approach, and partial
implementation tests one component, not the whole. The
honest framing per CLAUDE.md "honest framing" discipline
is `:argued` for the entry, with notes recording that
Strategy 2 has `:tested`-tier evidence in the prototype.

### §3.3 — What `:tested`-tier-for-Strategy-2 *does* establish

- The `(ε, δ)`-DP Gaussian mechanism is correctly
  implemented per Dwork & Roth §A.1.
- The σ floor (1e-10) is correct and DP-safe.
- The DP metadata is correctly recorded for downstream
  audit / reproducibility.
- Argument validation prevents nonsense parameters.
- Sensitivity bound is the prototype's choice
  (sensitivity = 0.1 default, configurable per-call).

### §3.4 — What `:tested`-tier-for-Strategy-2 does NOT establish

- **No detection-power benchmark.** §2.3 documents the
  privacy-vs-detection trade-off in concept; no benchmark
  measures detection power at varying ε. Deferred to a
  future combined benchmark with P3-bound.
- **No formal proof of (ε, δ)-DP.** The Gaussian mechanism
  has a textbook proof (Dwork & Roth Thm A.1) but is not
  formalised in Lean for the prototype. Strategy 2's Lean
  theorem statement is stub-level in
  `docs/p_r2b_calibration_confidentiality_companion.md`
  §2.6.
- **Sensitivity bound not derived analytically.** The 0.1
  default is empirical / conservative; not derived from
  Eckmann-Ruelle estimator-variance bounds. Production
  deployments would need analytic sensitivity bounds for
  formal DP.
- **No production scheduler.** The implementation is
  pure-Julia; production would integrate with
  cryptographic-library RNGs and proper secret-key
  management.

---

## §4 — Spec impact

### §4.1 — Status moves

None at the entry level. LL-020 stays `:argued`.

### §4.2 — Notes amendment on LL-020

The LL-020 spec entry's notes are amended to record that
Strategy 2 is now `:tested`-tier:

> Strategy 2 (ε-DP perturbation) is implemented in
> `src/julia/src/Audit.jl::differentially_private_envelope`
> and example-tested in
> `src/julia/test/runtests.jl` (23 assertions). See
> `docs/ll020_strategy_2_epsilon_dp_companion.md`. Strategies
> 1 (TPM-sealed) and 3 (Shamir threshold) remain
> implementation-deferred; the entry as a whole stays
> `:argued` because the multi-strategy approach is the
> claim and partial implementation tests one component, not
> the whole.

### §4.3 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 3 (LL-003, LL-004, LL-007)
- **`:benchmarked`:** 3 (LL-006, LL-019, LL-021)
- **`:argued`:** 14 (LL-001, LL-002, LL-005, LL-008, LL-009,
  LL-010, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017,
  LL-018, LL-020) — unchanged
- **`:open`:** 1 (LL-015) — unchanged

### §4.4 — Files changed

- `docs/ll020_strategy_2_epsilon_dp_companion.md` (this
  file) — new.
- `src/julia/src/Audit.jl` — `differentially_private_envelope`
  added.
- `src/julia/src/LavaLamp.jl` — re-export.
- `src/julia/test/runtests.jl` — 23 new assertions.
- `LAVALAMP_SPEC.md` — LL-020 notes amendment.
- `artifact_registry.md` — version + LL-020 row note (or no
  change if registry already references P-R2b companion).
- `dashboard.md` — version; recent companion docs.
- `changelog.md` — 0.0.23 entry.

### §4.5 — Followups

- **Detection-power benchmark vs ε.** Run P3-bound-style
  sweep with `differentially_private_envelope(env; ε)`
  for ε ∈ {0.1, 0.5, 1.0, 2.0, ∞}; trace the
  privacy-vs-detection trade-off curve. Output committed
  benchmark file. This *would* support a `:benchmarked`
  upgrade for Strategy 2.
- **Analytic sensitivity bound.** Derive the L2-sensitivity
  of `register_envelope` from Eckmann-Ruelle / Pesin
  estimator-variance bounds. Replaces the empirical
  default sensitivity = 0.1.
- **Lean theorem.** The Gaussian mechanism's (ε, δ)-DP
  property has a textbook proof; formalising in Lean for
  the LavaLamp envelope is the round-2 §1D.v priority 3
  target. P5/P6 work.
- **Strategy 1 / Strategy 3 implementation.** TPM-sealed
  via platform FFI is P7 hardening work; Shamir threshold
  via finite-field cryptography is P5 Haskell work.
- **Re-deriving sensitivity per deployment.** The 0.1
  default is honest at the prototype's calibration config
  (n_trials=5–10, N_benettin≈1200). Production deployments
  with different parameters need to re-derive the
  sensitivity bound.

---

## §5 — Lessons captured

### §5.1 — Strategy-of-strategies entries land in chunks

LL-020 is structured as a multi-strategy approach (three
strategies that span the deployment-context space). Each
strategy can be implemented independently; a session can
land one strategy without all three. The honest spec
treatment: the entry-level status reflects the *whole
claim* (multi-strategy approach), and notes record per-
strategy progress.

This pattern generalises. Other entries that may follow it:

- **LL-016 (sensor authenticity)** — four strategies (TPM
  attestation; multi-sensor cross-validation;
  anomaly-flagging; accepted residual). Currently
  :argued; could land per-strategy implementations.
- **LL-014 (threshold calibration discipline)** — five
  components (vector test; per-exponent threshold; no-oracle
  protocol; rate limiting; adaptive thresholding). Some
  are tested (vector test via LL-006, no-oracle via
  LL-019); others (rate limiting, adaptive) are
  implementation-deferred.

When a multi-strategy entry has *some* strategies tested
and *some* not, the honest pattern is: entry-level status
reflects the lowest-tested strategy (i.e., the bottleneck);
notes record per-strategy progress.

### §5.2 — DP and detection-power are inversely coupled

The privacy-vs-detection-power trade-off in §2.3 is
fundamental, not an implementation artifact. Tight ε ↔
high privacy ↔ large σ_DP ↔ wide thresholds ↔ low TPR.

For LavaLamp deployments this means: choosing ε is a
**deployment policy decision**, not a pure-math choice. The
deployment context determines:

- How much privacy is needed (against what observer?).
- How much detection power can be sacrificed.
- What ε balances the two.

The prototype provides the mechanism; the policy is
deployment-side.

### §5.3 — σ floor is DP-safe via post-processing immunity

The σ floor at 1e-10 is a data-independent transformation
applied after the DP-noise addition. Per Dwork & Roth
Prop 2.1 ("post-processing immunity"), data-independent
post-processing preserves the DP guarantee.

This is worth recording because it could easily look like a
correctness compromise (clamping the noise output seems
like cheating). It isn't, because the clamp is
data-independent. The same lesson generalises: any
deterministic post-processing of a DP-sanitized output is
DP-safe; only data-dependent post-processing breaks the
guarantee.

### §5.4 — Honest entry-level status protects against partial-claim drift

The decision to keep LL-020 at `:argued` while Strategy 2
is `:tested`-tier is a small honest-framing exercise. The
opposite decision — flip LL-020 to `:tested` because one
strategy is tested — would have been *expedient* but would
have required either backing it out later (when Strategies
1 / 3 are implemented and we realise we were already
:tested) or accepting that "the multi-strategy claim is
:tested via partial implementation" forever.

The honest pattern is: entry-level status reflects the
weakest sub-claim's evidence; per-sub-claim progress lives
in notes. When all sub-claims reach :tested, the entry
moves. This protects against the gradual-overstatement
failure mode.
