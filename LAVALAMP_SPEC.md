# LAVALAMP_SPEC.md — LavaLamp

Version: 0.0.44 (round-3 forward-brief engine-side blanks filled; brief forward-ready, 2026-05-05)
Authoritative reference for every named claim LavaLamp makes.

## Conventions

**LL-ID** — unique identifier. Format `LL-NNN`, zero-padded.

**Logic tier** — `Core` (load-bearing structural claim about the
primitive), `Operational` (behavior of the implementation),
`Boundary` (scope-limiting constraint inherited from corpus).

**Evidence type** (per CLAUDE.md §Evidence types):

| Type | Sufficient for `:proved`? |
|---|---|
| `lean-proved` | Yes |
| `type-checked` | Yes |
| `algebraic` | Yes |
| `property-tested` | No → `:verified` |
| `example-tested` | No → `:tested` |
| `benchmarked` | No → `:benchmarked` |
| `manual` | **No** → `:argued` only |
| `none` | No → `:open` |

**Status** — `:proved | :verified | :tested | :benchmarked | :argued | :open`.
A spec entry may have `:proved` only if evidence type is
`lean-proved`, `type-checked`, or `algebraic`.

**Update discipline.** Spec entries are append-only by LL-ID. To
revise a claim, mark the original with `Status: superseded by LL-NNN`
and add a new entry. Keys may be edited in place; identity is the
LL-ID, not the Key.

---

## Core architecture — open

### LL-001 — substrate-bound-identity-primitive
- Key: identity is the chaotic SDE trajectory on the device
- Logic tier: Core
- Description: Device identity is realised as the sustained chaotic
  trajectory of an SDE solver running on the device, with noise /
  parameter terms coupled to live hardware sensors. The identity is
  a continuous *function of (machine, configuration, time)*, not a
  static credential. Verification compares trajectory features
  against a registered hardware envelope.
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §1 — composed
  claim argued via component evidence: SDE solver (LL-003
  :tested), sensor coupling (LL-004 :tested), residue audit
  verification (LL-006 :benchmarked), real-time validity check
  (LL-007 :tested). The audit benchmark
  (`benchmark/results/p3_bound_high_res_lorenz96.txt`)
  exercises the composed identity claim end-to-end.
- Notes: :tested upgrade requires either (a) Lean / type-level
  enforcement of the composition property, or (b) a test
  suite written specifically against LL-001's higher-level
  claim. Both deferred to P5/P6.

### LL-002 — visual-security-decoupling
- Key: visual layer and security primitive are architecturally independent
- Logic tier: Core
- Description: The user-facing lava-lamp visual animation does
  *not* derive from the security-critical SDE trajectory. The
  visual can be driven by any RNG (including a simple
  `Math.random()`-style bubble simulator) and is decorative only.
  The security primitive (chaotic SDE + sensor coupling +
  Lyapunov-spectrum residue audit) runs as an independent
  background process. This decoupling resolves the
  visual-richness ↔ security tension that round-1 synthesis-team
  review (Gemini + Grok, 2026-04-30) identified as a structural
  blindspot in any design that fed the visual *from* the SDE.
- Evidence type: example-tested
- Status: :tested
- Source: `visual/lavalamp.js` (decoupled HTML/JS bubble
  simulator; ~80 lines; Math.random()-driven; no
  references to security-primitive APIs);
  `visual/index.html`, `visual/style.css`,
  `visual/README.md` (decoupling discipline documentation).
- Test: `src/julia/test/runtests.jl` — `Visual layer
  decoupling (LL-002)` testset (45 assertions covering
  the decoupling invariant). Verifies (i) `visual/`
  files exist; (ii) `visual/lavalamp.js` uses
  `Math.random()` not crypto-grade RNG; (iii)
  `visual/lavalamp.js` contains no security-primitive
  identifiers (`lyapunov_spectrum`, `register_envelope`,
  `synthetic_adversary`, `verify_full`, `Envelope(`,
  `ChaosGuard`, `nyquist_compliant`, etc.); (iv)
  `visual/lavalamp.js` has no `import` / `require(` /
  `<script src=` external references; (v)
  `src/julia/src/*.jl` contains no visual-layer
  identifiers (`requestAnimationFrame`, `getContext(`,
  `createRadialGradient`, `lavalamp.js`).
- Notes: This is a load-bearing architectural invariant. If the
  visual ever gets re-coupled to the security primitive, the
  basin-spoofing attack surface returns (multi-basin reaction-
  diffusion regimes the visual layer would want to use are
  precisely where the adversary can hide a spoof inside scalar-KL
  threshold). The `:tested` upgrade in 0.0.33 evidences the
  invariant via *static text-search assertions* across the
  `visual/` and `src/julia/src/` trees (option (a) from the
  prior `:argued` footer). Stronger guarantees (option (b):
  Lean / type-level enforcement that the security-primitive
  type-graph cannot reach the visual-layer type-graph) remain
  deferred to P5/P6.
- **`:argued` → `:tested` upgrade (2026-05-04, 0.0.33):**
  Visual layer landed at `visual/` with the decoupling discipline
  documented in `visual/README.md`. The 45 new assertions in
  `runtests.jl` make the decoupling invariant *executable* — any
  future re-coupling would fail CI. The prior `:argued`
  evidence (manual; "invariant preserved by construction") is
  superseded by example-tested evidence; the entry-level claim
  is now testable on every commit.

### LL-003 — single-attractor-chaotic-engine
- Key: security primitive uses single-attractor chaotic SDE
- Logic tier: Core
- Description: The security primitive's underlying SDE has a
  *single* strange attractor (e.g., Lorenz, Lorenz-96, Rössler,
  jerk-equation systems), not a multi-basin reaction-diffusion
  structure. Single-attractor is now viable because LL-002
  decouples visual richness from security, removing the constraint
  that would have pulled toward multi-basin systems. Lorenz-96
  (N=40, F=8) is the prototype's default: λ₁ ≈ 1.66, ~14 positive
  exponents, h_KS ≈ 10.5, Kaplan-Yorke dimension ≈ 27.
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Engine.jl (Lorenz-96 + alternate
  candidates Lorenz-63, Rössler; spectrum estimator).
- Test: src/julia/test/runtests.jl (Lorenz-96 baseline, 8
  assertions: spectrum length, sortedness, λ₁ ∈ [1.4, 1.9],
  n_pos ∈ [11, 16], h_KS ∈ [8.0, 12.5], λ_min < -3.0,
  IC-invariance under Oseledec).
- Benchmark: src/julia/benchmark/p3d_sde_selection.jl +
  src/julia/benchmark/results/p3d_sde_selection.txt +
  docs/p3d_sde_selection_companion.md. Comparative bench
  across Lorenz-96 / Lorenz-63 / Rössler at 5 trials per
  SDE. Empirical result: Lorenz-96 dominates on all
  security-relevant axes — λ₁ ≈ 1.67 (vs 0.90 / 0.07);
  n_pos ≈ 13.4 (vs 1.6 / 1.4); h_KS ≈ 10.26 (vs 0.90 /
  0.07; ratio 155× over Rössler, 11× over Lorenz-63);
  Kaplan-Yorke dimension ≈ 27.0 (vs 2.06 / 2.01). Compute
  cost ≈ 14× the cheaper alternatives but justified by
  the ~11× h_KS gain (per-h_KS efficiency comparable).
  Performance target: "Lorenz-96 dominates alternatives on
  security metrics at acceptable compute cost" — met.
- Notes: Lorenz-63 is a viable low-power-mode fallback
  (~10× lower h_KS; documented margin reduction).
  Rössler not recommended for production (h_KS too low for
  meaningful resolution-bound margin). The architecture-
  design §2.3 recommendation is empirically justified.
  Stochastic perturbation (the σ dW term in §2.4 design)
  and sensor coupling are in `lorenz96_coupled` (LL-004
  :tested).
- **N-scaling characterisation (2026-05-04):** Per
  `docs/p3e_n_scaling_companion.md`, Lorenz-96 at F=8 was
  benchmarked across N ∈ {20, 40, 80, 160} (5 trials per N).
  **Result: linear extensive-chaos scaling confirmed
  empirically.** Fitted laws: h_KS ≈ 0.2165·N^1.0370,
  n_pos ≈ 0.3019·N^1.0220, KY ≈ 0.6623·N^1.0048 (all β
  values within 4 % of theoretical β=1.0). Per-N Lyapunov
  density h_KS/N converges from 0.2383 (N=20) to 0.2591
  (N=160) — finite-N corrections decay as N grows, with
  density saturated by N≥80. **Asymptotic Lyapunov density
  s ≈ 0.255 per dimension at F=8** (operational deployment
  constant). λ₁ also grows weakly with N (1.481 at N=20 →
  1.770 at N=160). Compute scaling: O(N³) per integration
  step empirically validated; per-trial wall clock 0.1 →
  1.8 → 5.9 → 25 s. **Deployment-design rule:** for target
  chaos-production margin Δh*, pick N* ≈ Δh*/s; trades
  margin against compute predictably (audit-on-verify cost
  ≈ 25 s per spectrum at N=160; partial-spectrum audit
  modes are P7 hardening). Benchmark script:
  `src/julia/benchmark/p3e_n_scaling.jl`; result file:
  `src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt`
  (deterministic; byte-identical across runs per CLAUDE.md
  §Benchmarking discipline).

### LL-004 — continuous-sensor-coupling
- Key: sensor data couples to SDE as continuous potential field, not discrete kicks
- Logic tier: Core
- Description: Live hardware sensor reads (battery state, AC
  adapter, USB peripheral status, CPU thermal, scheduler timing)
  perturb the SDE through a smooth *external potential field*
  pulling the trajectory toward configuration-specific regions of
  the attractor. Hard step-function parameter changes from discrete
  sensor reads are forbidden — they create numerical artefacts an
  adversary could detect and resync against. Prototype implements
  the linear-in-x case: U(s, x; t) = Σ_k α_k · evaluate(streams[k], t)
  · ⟨b_k, x⟩, so ∇_x U is constant in x and reduces to a sensor-
  modulated additive forcing per dimension. Sufficient for non-zero
  δ_A (LL-006 prerequisite).
- Evidence type: example-tested
- Status: :tested
- Source: src/julia/src/Sensors.jl (SensorStream + smoothing
  primitives + CouplingParams), src/julia/src/Engine.jl
  (lorenz96_coupled_eom!, lorenz96_coupled).
- Test: src/julia/test/runtests.jl (4 new @testsets / 21
  assertions: sensor-stream primitives, no-coupling sanity,
  stepped-sensor smoothness, α-sweep non-degeneracy). Run via
  Pkg.test() from src/julia/; passes 29/29 in ~40s on Apple
  Silicon.
- Notes: Implementation respects Nyquist condition (LL-005) at
  the parameter level (sample-rate set per stream, f_SDE via Δt).
  State-dependent coupling (U quadratic-or-higher in x) is a
  future enhancement, not a prerequisite. Real-sensor FFI
  deferred to a later P3 sub-task or P6 hardening.
- **Round-2 limitation (2026-05-02):** Linear-in-x coupling
  is *linearisable* by an adversary with system-identification
  capability — the cubic Lorenz-96 dynamics protect the
  unforced terms but not the sensor coupling layer. The
  current implementation's security claim is conditional on
  the adversary not accurately modeling the sensor interface.
  See `synthesis_team_round2_companion.md` §1C-A6 / §1D-iv;
  V-013 in attack_surface_enumeration.md. State-dependent
  coupling deferred as a future architectural enhancement.

### LL-005 — sensor-Nyquist-condition
- Key: sensor sampling rate vs physical noise bandwidth
- Logic tier: Core
- Description: Sensor sampling rate `f_sensor` and SDE integration
  rate `f_SDE` must satisfy a Nyquist-like condition relative to
  the physical noise bandwidth of the underlying source: an
  adversary at sub-Nyquist sampling cannot reconstruct the genuine
  device's sensor stream, but a sufficiently fast adversary can.
  Formal requirement: `f_SDE > 2 × bandwidth ∧ f_sensor > bandwidth`.
  Per-sensor analysis distinguishes high-bandwidth-noise sensors
  (thermal, scheduler, governor — Nyquist binding) from
  discrete-state configuration sensors (USB, AC, battery — Nyquist
  trivially satisfied; security contribution via configuration
  discreteness, not bandwidth).
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.4, §3.6.
- Notes: Recommended starting points: f_SDE ≈ 10 kHz, sensor
  sampling at 10× sensor electronic bandwidth where supported.
  Concrete numerical calibration is P3 work. **Round-2
  follow-up (2026-05-03):** P3-Nyq adversary-rate benchmark
  (`benchmark/p3_nyq_adversary_rate.jl` + result file
  `benchmark/results/p3_nyq_adversary_rate.txt` + companion
  `docs/p3_nyq_companion.md`) attempted to demonstrate that
  the residue audit (LL-006) detects sub-Nyquist adversaries.
  Result: NEGATIVE. The residue audit does not detect
  sub-Nyquist sensor reconstruction at the prototype's
  configuration because zero-mean Gaussian noise has the
  same time-averaged statistics under sub-sampling, and the
  Lyapunov spectrum is a time-averaged invariant. LL-005 is
  therefore a parameter-level hygiene requirement (correctly
  configured: Δt=0.05 → f_SDE=20Hz; gaussian_noise_stream at
  100Hz; both > thermal-noise BW for typical deployments)
  rather than an actively-defended attack surface. Sub-
  Nyquist adversary detection requires LL-016 sensor
  authenticity (already :argued; multi-sensor cross-validation,
  hardware attestation) or a not-yet-implemented mechanism
  (FFT-based audit on trajectory PSD; trajectory-checkpoint
  comparison — both round-3 architectural input). LL-005
  entry-level status stays :argued because the entry's
  claim has two implicit sub-claims (parameter compliance
  + adversary detection) and only the parameter side is
  evidenced.
- **Parameter-validation test (2026-05-04, part-(a) only):**
  `nyquist_compliant(f_SDE, f_sensor, bandwidth)` predicate
  added to `src/julia/src/Sensors.jl` (re-exported at
  LavaLamp top level), asserting `f_SDE > 2·bandwidth ∧
  f_sensor > bandwidth` per the formal requirement. 16 new
  test assertions in `src/julia/test/runtests.jl` (compliance
  on prototype defaults; borderline cases at strict-inequality
  edges; argument validation; type flexibility). Test suite
  123/123 → 139/139. **Entry-level status unchanged at
  `:argued`** — this evidences only the *parameter-compliance*
  sub-claim. The adversary-detection sub-claim (residue audit
  detects sub-Nyquist sensor reconstruction) was answered
  NEGATIVE in 0.0.24 P3-Nyq because zero-mean Gaussian noise
  has time-averaged statistics invariant under sub-sampling.
  A `:tested` upgrade requires both sub-claims to have direct
  evidence; round-3 must address the adversary-side via either
  LL-016 sensor authenticity or a not-yet-implemented
  mechanism (FFT/PSD audit, trajectory-checkpoint comparison).
  See `docs/ll005_part_a_companion.md` for the discipline
  rationale.

---

## Detection / verification — open

### LL-006 — Lyapunov-spectrum-residue-audit
- Key: residue detection on Lyapunov spectrum, not scalar KL
- Logic tier: Core
- Description: Adversary-signature detection compares the *full
  Lyapunov spectrum* of the live trajectory against the registered
  hardware envelope, not a scalar KL divergence on raw trajectory.
  Spectrum comparison resists slow-drift threshold-gaming because
  an adversary can spoof location on the attractor more easily
  than they can spoof local stretching/folding rates across
  multiple timescales simultaneously. Test is *vector* per-exponent,
  not scalar: M̂ accepted iff |λ̂ᵢ - λᵢ_registered| < k·σᵢ for every i,
  where σᵢ is the per-exponent estimator standard deviation
  calibrated from n_trials registration runs. Detection-probability
  bound shape (manually argued, Lean target for P6):
  P(detect) ≥ 1 - K·exp(-c·T·δ_A²) where δ_A is adversary
  spectrum gap and T is observation window. Empirical
  detection-probability surface at N=20, n_trials=10, k=5: flat
  ≈ FPR (0.10) for ε_A ≤ 0.75; sigmoid transition through
  ε_A ∈ [0.75, 2.0]; saturated 1.00 for ε_A ≥ 2.0. Shape matches
  the bound; constants K, c, δ_A(ε_A) not yet derived.
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Audit.jl (Envelope, register_envelope,
  residue, verify, synthetic_adversary).
- Test: src/julia/test/runtests.jl (audit @testsets — 18
  assertions covering mechanism, register, self-acceptance,
  strong-adversary rejection); passes via Pkg.test().
- Benchmark: src/julia/benchmark/p3_bound_high_res.jl +
  src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt
  (high-resolution sweep, 11 ε_A points × 15 trials each).
  Fitted bound K=1, c′=0.00423, T=60 holds at all 10
  transition + saturation data points; one FPR-floor point
  (ε_A=0.50, empirical 0/15) is below bound by 0.062 but
  consistent with sampling variance (Wilson 95% CI
  [0, 0.215] covers bound prediction 0.061). Performance
  target: "fitted bound holds across the prototype's
  configuration" — met. See
  docs/p3_bound_companion.md §2 for the constrained-fit
  derivation. Earlier P3b benchmark
  (src/julia/benchmark/results/p3b_detection_lorenz96.txt)
  remains as the original :tested-tier evidence.
- Notes: Bound is vacuous as adversary precision ε_A → 0
  (honest resolution-bounded scoping). Mechanism upgraded from
  scalar to vector per-exponent test; SNR is much better than
  scalar — see docs/p3a_sensor_coupling_companion.md §2.4 for
  trajectory-vs-spectrum comparison. Calibration of the §2.1
  bound's constants (K, c, δ_A(ε_A) mapping) is the
  :benchmarked-upgrade follow-up. Structural-separation prior
  anchors on the closure_forces_structure paper's Q₅₁ / Q₁₀₂
  autopoietic-fixed-point results (cross-sector autopoiesis fails 0/5202
  across 5 ICs at threshold 0.999) — see
  qkd_pqc_complementarity_companion.md §2.5.
- **Round-2 acknowledgment (2026-05-02):** The empirical
  detection-probability surface is an *optimistic* bound
  derived from an isotropic synthetic adversary. Real
  adversaries have structured perturbation directions
  (V-013); worst-case δ_A is bounded by the weakest-coupled
  direction, not the isotropic average. LL-021
  (worst-case-adversary-bound) supplies the corrected
  bound; the empirical curve here remains valid as a lower
  bound on detection difficulty.
- **Round-2 worst-case companion benchmark (0.0.15):** The
  empirical worst-case surface lives at
  `src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`
  with the analytic derivation in
  `docs/p_r2c_worst_case_adversary_companion.md` §2.1. For
  the prototype's two-channel coupling, the NARROW direction
  produces 0-20% detection across all tested magnitudes
  while the BROAD direction saturates at 100% by ε_A = 1.0.
- **Per-SDE detection-power characterisation (2026-05-04):**
  Per `docs/p3f_per_sde_detection_power_companion.md`, the
  detection-bound shape was applied across the three
  candidate SDEs (Lorenz-96 / Lorenz-63 / Rössler) using
  parameter-space adversaries (perturbations to F / ρ / c
  respectively). Per-SDE c′ values: c′_F = 0.00372 (Lorenz-96,
  binding ε_A=1.0); c′_ρ = 0.00168 (Lorenz-63, binding
  ε_A=4.0); c′_c = 0.38179 (Rössler, binding ε_A=0.2).
  **The bound shape is universal across the candidate set.**
  c′ values are NOT directly comparable as detection-quality
  rankings (parameter scales differ); they reflect per-unit
  parameter sensitivity. Combined with 0.0.25 P3d's h_KS
  comparison, **Lorenz-96 has the right operational balance**:
  high security margin (h_KS = 10× / 155× the alternatives)
  AND moderate per-param sensitivity (neither too low for
  adversary detection nor too high for genuine calibration
  tolerance). Lorenz-63 fails on both axes (low h_KS AND low
  per-param sensitivity); Rössler fails on both axes (low
  h_KS AND extreme per-param brittleness — narrow chaotic
  band makes genuine calibration drift trigger spurious
  rejections). The architectural choice from 0.0.25 is
  confirmed on this complementary axis. Benchmark script:
  `src/julia/benchmark/p3f_per_sde_detection_power.jl`;
  result file:
  `src/julia/benchmark/results/p3f_per_sde_detection_power.txt`
  (deterministic; byte-identical across runs).
- **LL-021/LL-006 composition theorem (2026-05-06, 0.0.54):**
  The Lean track at `src/lean4/LavaLamp/Theorems.lean` lands
  `LL006_worst_case_lower_than_isotropic`:

  ```
  ∀ ε_A proj K c T, 0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 →
                    0 ≤ K → 0 ≤ c·T →
    1 - K · exp(-(c·T) · (ε_A·proj)²)
      ≤ 1 - K · exp(-(c·T) · ε_A²)
  ```

  Proof: composition of `LL021_eff_squared_bound`
  ((ε_A·proj)² ≤ ε_A² from 0.0.49) with `Real.exp` monotonicity
  + `mul_le_mul_of_nonpos_left` (multiplying by non-positive
  `-(c·T)`) + `mul_le_mul_of_nonneg_left` (multiplying by
  `K ≥ 0`) + `linarith` (subtraction from 1). `lake build`
  clean — 1901 jobs (Mathlib analysis content pulled in for
  `Real.exp`); zero warnings.

  **What this proves:** the worst-case detection-probability
  bound value is *less than or equal to* the isotropic bound
  value — the structural asymmetry claim LL-021 makes
  against LL-006 is mathematically derivable (not just
  empirically observed) from the bound shape.

  **What this does NOT prove:** the bound itself
  (`P(detect) ≥ 1 - K · exp(-c · T · δ²)`). LL-006's
  `:benchmarked` status is unchanged — promoting to
  `:proved` requires the full probability-space
  formalization (random variables, detection event predicate,
  the lower-bound proof itself), which is a multi-session
  research investment. This theorem is composition-foothold
  #2 (after `LL021_eff_squared_bound` at 0.0.49) on the
  path toward that formalization.
- **LL-006 detection-bound range theorems (2026-05-06, 0.0.55):**
  Two short theorems establish that the bound *value*
  `1 - K · exp(-(c · T) · δ²)` itself sits in `[0, 1]` —
  without this, "P(detect) ≥ <bound value>" would be
  structurally meaningless when the bound exits the unit
  interval.

  - `LL006_bound_le_one : 0 ≤ K → 1 - K · exp(-(c·T)·δ²) ≤ 1`
    (one-line proof; `Real.exp_pos` + `mul_nonneg` +
    `linarith`).
  - `LL006_bound_nonneg : 0 ≤ K → K ≤ 1 → 0 ≤ c·T →
    0 ≤ 1 - K · exp(-(c·T)·δ²)` (proof:
    `0 ≤ (c·T)·δ²` from `mul_nonneg` + `sq_nonneg`,
    negate, `Real.exp_le_exp.mpr` + `Real.exp_zero` lift to
    `exp(-(c·T)·δ²) ≤ 1`, multiply by `K ≤ 1`, subtract from
    `1`).

  Together: under `0 ≤ K ≤ 1` and `0 ≤ c·T`, the bound is
  a valid probability. The fitted constant `K = 1` satisfies
  the upper bound at saturation; the formalisation accepts
  any `K` in `[0, 1]`.

  `lake build` clean — 1901 jobs, zero warnings. Composition-
  foothold inventory after 0.0.55:
  (1) `LL021_worst_case_bound` (0.0.48 :proved);
  (2) `LL021_eff_squared_bound` (0.0.49 corollary);
  (3) `LL006_worst_case_lower_than_isotropic` (0.0.54);
  (4) `LL006_bound_le_one` (this version);
  (5) `LL006_bound_nonneg` (this version).

  LL-006 status unchanged at `:benchmarked` — the range
  theorems establish the bound shape is *well-typed* as a
  lower-bound-on-probability, but the bound itself
  (`P(detect) ≥ ...`) still requires probability-space
  formalization for `:proved`.

### LL-007 — chaos-guard
- Key: real-time Lyapunov estimate; periodic windows reject entropy
- Logic tier: Operational
- Description: A background process estimates the largest
  Lyapunov exponent in real time using the Wolf single-trajectory
  algorithm (`DynamicalSystems.lyapunov`) — O(N) per step rather
  than O(N²) for full Benettin spectrum (~400× faster at N=40).
  If `λ̂₁ < τ_λ` (default 0.1·λ₁_expected ≈ 0.166), the entropy
  stream is marked INVALID immediately; `update!` returns the
  post-update state. Recovery requires `warmup_steps` consecutive
  samples ≥ recovery_threshold (default 5·τ_λ ≈ 0.83). Reseed
  perturbs the SDE state via TRNG-derived unit-vector × magnitude
  (default magnitude=1.0 ≈ attractor diameter); reset to WARMUP;
  `reseed_count` increments. Initial state is WARMUP not VALID
  (security primitive must not assume entropy is good before
  observation). Public predicate `is_valid` returns Bool only
  (LL-017 no-oracle).
- Evidence type: example-tested
- Status: :tested
- Source: src/julia/src/ChaosGuard.jl.
- Test: src/julia/test/runtests.jl (chaos-guard @testsets — 35
  assertions: state-machine logic with synthetic λ̂₁ sequences,
  Lorenz-96 chaotic vs sub-chaotic integration, reseed flow with
  exact magnitude verification). Passes via Pkg.test() in ~47s
  total wall clock.
- Notes: Decoupling from visual layer (LL-002) preserved — the
  guard module has no visual-layer references; reseed events are
  internal to the security primitive. Cost analysis: Wolf method
  ~1.3 ms per call vs Benettin ~507 ms; suitable for always-on
  ambient monitoring at sub-1% CPU. Concrete λ₁_expected for the
  chosen SDE is set per-deployment; the prototype uses 1.66 from
  the Lorenz-96 N=40, F=8 baseline.
- **Round-2 timing-channel concern (2026-05-02):** Reseed
  events and state transitions are *observable as timing
  channels* if the verifier emits WARMUP responses
  distinguishably from VALID/REJECT. LL-019 (side-channel
  hardening) is the corrective requirement — production
  deployments must use constant-time response or
  randomised-delay protocol around state transitions.
  Without LL-019, V-011 (Reseed Oracle) gives an A4/A5
  adversary a sensor-correlated event channel.

### LL-008 — resolution-bounded-security
- Key: S_production > S_measurement
- Logic tier: Core
- Description: LavaLamp's security claim is **resolution-bounded**:
  secure against any adversary whose measurement and compute
  resolution is exceeded by the device's chaos-production rate.
  S_production = h_KS(M) = Σ_i max(λᵢ, 0) (Pesin's formula on the
  ergodic component); S_measurement = h_meas(A; M) is A's
  information-absorption rate from substrate observations. The
  bound S_production > S_measurement + log(1/η)/Δt yields
  residual-uncertainty growth Δh·Δt - O(1) and the §2.1 detection
  bound P(detect) ≥ 1 - K·exp(-c·T·δ_A²). Per-class adversary
  quantification is split out as LL-018.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.2, §3.2.
- Notes: NOT information-theoretically secure. NOT a no-cloning-
  theorem inheritance. Computational unclonability via measurement-
  symmetry breaking. Honest tier framing per CLAUDE.md. Lean
  theorem shape pinned in §2.2 of the design companion; P6 work.
- **Cost-asymmetry framing (2026-05-05, 0.0.42):** The
  resolution-bounded-security claim is fundamentally a
  *cost-asymmetry* claim — the adversary's measurement
  resolution is bounded by their *cost budget*, and the
  device's chaos-production rate exceeds plausible adversary
  resolution at typical adversary cost levels. The
  threat-landscape companion §2.7 makes this explicit:
  LavaLamp's claim is "attacking this device costs more than
  the result is worth, relative to easier targets" — the
  metabolic-value / predator-prey-ecology framing of
  resolution-bounded security. Combined with detection-
  postured-not-prevention-postured framing (per
  `qkd_pqc_complementarity_companion.md`), this gives the
  honest end-to-end claim: we raise the attacker's cost; we
  don't promise no attacks; we detect the rare ones who pay
  the cost anyway. See
  `docs/threat_landscape_companion.md` §2.7.

### LL-009 — no-complex-numbers
- Key: security-critical math stays real-valued
- Logic tier: Boundary
- Description: The security primitive (SDE, sensor coupling,
  residue audit) uses only real-valued mathematics. Complex
  numbers are forbidden in any code path that contributes to
  identity / verification. The visual skin (decorative only) is
  not bound by this constraint, but its outputs do not feed the
  security primitive (per LL-002).
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §3 — boundary
  preserved by Float64 type choice across the Julia prototype:
  state vectors, coupling vectors, sensor stream values,
  Lyapunov spectrum estimates, envelope values, and residue
  audit per-component test all use Float64. Round-1's SGL
  complex-valued slip was rejected; the boundary held through
  P3 implementation. Originating corpus boundary: Aaron
  2026-04-29 Gemini conversation; reaffirmed across engine
  and RMR work.
- Notes: :tested upgrade requires either (a) static analysis
  asserting no Complex types touch security paths, or (b)
  Lean / type-level proof. Both deferred.

### LL-010 — no-open-ended-simulation
- Key: bounded-time / finite-state SDE only; no continuum-limit dynamics
- Logic tier: Boundary
- Description: LavaLamp solves a *bounded-time* SDE on a *finite*
  state. The system explicitly does not run continuum-limit /
  hypergraph-rewriting / autopoietic dynamics. Trajectories are
  analyzed in bounded windows; no open-ended simulation regime.
- Evidence type: manual
- Status: :argued
- Source: docs/spec_closure_pass_companion.md §4 — boundary
  preserved by parameter and system class: every SDE
  integration takes explicit bounded N (Benettin steps) and
  Δt; trajectories analysed over bounded windows; finite-
  dimensional Lorenz-96 N=20-40 (not hypergraph-rewriting,
  not continuum-limit); no autopoietic dynamics in the SDE
  itself. The the closure_forces_structure corpus' Q₁₀₂ autopoietic structure
  is the *target of analysis* per
  qkd_pqc_complementarity_companion.md §2.5, not the
  *physical instantiation* — explicitly out of scope here.
  Originating corpus boundary: Aaron 2026-04-29 Grok
  conversation re Q102 / continuum limit / self-reproducing
  structure.
- Notes: :tested upgrade requires either Lean enforcement of
  bounded-T integration calls, or runtime guard. Both deferred.

---

## Open protocol questions — pending design

### LL-011 — registration-ceremony
- Key: how a verifier learns a device's hardware fingerprint envelope
- Logic tier: Operational
- Description: Trust-root protocol for the verifier acquiring a
  device's registered Lyapunov-spectrum envelope. Default
  recommendation: TPM / Secure Enclave attestation (B) +
  device-derived secret mixing (D) for hardware-rooted
  deployments; multi-party registration (A, threshold scheme) when
  no hardware root is available; time-bounded re-registration (C)
  as defense-in-depth. Defeats single-A5 adversaries; A5 hardware-
  tamper still possible but moved down-stack.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.1, §3.8.
- Notes: Concrete protocol implementation (Julia client +
  Haskell verifier-side spec) is P3+P4 work.
- **Round-2 confidentiality requirement (2026-05-02):** The
  TPM attestation defence in this entry prevents envelope
  *substitution* but does not prevent envelope *observation*.
  V-012 (Calibration Spectrum Leakage) gives a registration-
  channel observer the full registered envelope. LL-020
  (calibration-confidentiality) is the complementary
  requirement: registered envelope must be sealed against
  observers via TPM-sealed storage, ε-DP perturbation of
  any published statistics, or multi-party threshold scheme.
  Both LL-011 and LL-020 are required for production.
- **OS-dependency (2026-05-03, P-OS):** The default protocol
  B+D (TPM/Secure-Enclave attestation + device-derived
  secret mixing) requires a hardware root of trust per
  LL-022 §2.2.1. Deployments without TPM / Secure-Enclave
  fall back to multi-party registration (variant A) per
  LL-022 §2.2.1's stated graceful-fallback path. See
  `docs/os_identity_security_scoping_companion.md`.
- **Consumer framing (2026-05-04, P-PharOS):** The
  registration ceremony is called from the consumer-side
  (PharOS install / first-boot flow; Lazarus onboarding;
  future SDK consumers) per LL-023's `register(...)`
  surface. PharOS is the canonical first consumer; the
  protocol's variants (B+D / A / C) map to deployment-time
  consumer choices. See
  `docs/pharos_scoping_companion.md` §2.2.1.

### LL-012 — cold-start-window
- Key: behavior of just-booted device before trajectory has converged
- Logic tier: Operational
- Description: Just-booted device must distinguish three states to
  the verifier: WARMUP (SDE has not converged; "retry in
  T_remaining" reported via chaos-guard's λ̂₁ trace, signed by
  device identity key), OPERATIONAL (steady state; ACCEPT/REJECT),
  DEGRADED (chaos-guard rejection in flight; same response as
  WARMUP). Default: single-envelope registration (steady state
  only), unauthenticated during warmup; dual-envelope (cold-start
  + steady-state) reserved for high-availability deployments.
  Early-boot integrity (Secure Boot, measured boot, cold-boot
  RAM hardening) is *out of LavaLamp's implementation scope* but
  is articulated as a *recommended* (not required) OS-level
  dependency per LL-022 §2.3.1; the broader OS-level boundary
  is covered by LL-015. WARMUP-state authentication remains the
  load-bearing line during cold start when measured boot is
  unavailable; deployments with measured boot compose a second
  parallel chain of custody (the boot path attests to a known-
  good measurement before the SDE engine starts).
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.2, §3.8;
  docs/os_identity_security_scoping_companion.md §2.3.1.

### LL-013 — cross-config-transition-handling
- Key: distinguishing legitimate config change from adversarial spoofing
- Logic tier: Operational
- Description: Per-config registered envelopes (PRE): registration
  captures envelopes for all expected configurations
  (USB/AC/peripheral combinations). Verifier receives candidate
  trajectory + sensor-authentic configuration claim (LL-016) and
  selects matching envelope. Brief TRANSITIONING window
  (~τ_config) during equilibration of the smoothed potential
  field. Unknown configurations rejected with
  UNKNOWN_CONFIGURATION; re-registration required. Transition-
  pattern fingerprint deferred as future hardening.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.3, §3.8.
- Notes: Inherits V-006 risk via dependency on LL-016 sensor
  authenticity.

### LL-014 — adversary-signature-threshold-calibration
- Key: false-positive vs false-negative tradeoff in residue threshold
- Logic tier: Operational
- Description: Calibration *discipline* for the residue threshold
  τ. (1) τ is vector-valued per exponent, not scalar (defeats
  V-005 slow-drift). (2) Per-exponent threshold τᵢ baseline
  τᵢ = 3·σ(λ̂ᵢ | T). (3) No-oracle verification protocol
  (LL-017) prevents threshold-probing. (4) Rate limiting on
  verification attempts (10/min/source, 100/hour/device) hardens
  further. (5) Adaptive thresholding learning from genuine-device
  history is recommended future hardening; round-1 production uses
  fixed τ.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.5, §3.8.
- Notes: Concrete numerical τᵢ values depend on the chosen SDE
  family / parameters / estimator and are produced by P3
  benchmarks against estimator variance at the chosen window
  length.
- **Round-2 promotion (2026-05-02):** Adaptive thresholding
  (history-aware τ that learns from genuine-device traces)
  is now *load-bearing for multi-tenant deployments*, not
  optional hardening. The prototype's 10% baseline FPR at
  k=5 / n_trials=10 is operationally a denial-of-service
  vector at scale; tightening requires more trials, a chi-
  squared aggregate test, or adaptive-threshold history.
  See `synthesis_team_round2_companion.md` §1C-A5.
- **Round-3 numerical-threshold non-fundamentality tie
  (2026-05-06, 0.0.46):** Surfaced by synthesis-team round
  3 §1C.A6 (ChatGPT edge-witness): the 10% FPR baseline at
  k=5 / n_trials=10 maps almost exactly to the
  closure_forces_structure paper §13.6's 5-12% spurious-
  merge zone. Quote: *"This is not coincidence — it is the
  same phenomenon in different language: threshold ≠
  structure."* The paper's resolution at threshold
  `1 − 10⁻¹²` (200/200 canonical seeds; vs ~5-12% spurious
  at threshold `0.999`) maps to LL-014's resolution by
  tightening: more trials, chi-squared aggregate test, or
  adaptive-threshold history. The threshold is *calibration
  convenience*, not part of the spec's structural claim.
  Status unchanged at `:argued` — framing amendment, not
  new evidence. Defends V-016 (numerical-threshold
  calibration gaming) by making non-fundamentality
  explicit. PharOS-tier deployments should tighten beyond
  the prototype's 10% baseline; the prototype's threshold
  is honest residual-risk.

---

## Surfaced by attack-surface enumeration (0.0.3)

### LL-015 — adversary-class-A3-out-of-scope
- Key: kernel-level (A3) adversaries explicitly not defended against
- Logic tier: Boundary
- Description: LavaLamp does *not* claim defense against
  adversaries with kernel-level (root) execution on the device.
  At that capability level the device's identity is irrelevant —
  the attacker can simulate any trajectory directly. Honest
  scoping. The architecture defends against adversary classes
  A1 (remote software), A2 (unprivileged user-space software),
  A4 (side-channel / physical proximity), A5 (registration-time
  insider), and A6 (time-localized observer); A3 is explicitly
  out of scope.
- Evidence type: none
- Status: :open
- Source: `docs/attack_surface_enumeration.md` §2 (adversary
  taxonomy) + §5 (residual risks).
- Notes: This is a honest-scoping claim parallel to LL-009 (no
  complex numbers in security math) and LL-010 (no open-ended
  simulation). Documenting the boundary prevents drift toward
  overclaiming; consumers of the spec must understand which
  adversary capabilities LavaLamp covers.
- **OS-stack pairing (2026-05-03, P-OS):** LL-015 is the
  *downward* OS-stack boundary (what LavaLamp does not defend
  against); LL-022 is the *upward* boundary (what LavaLamp
  depends on). The two together close the trust-stack scoping
  question. LL-015 stays `:open` (a non-defence declaration has
  no positive evidence to provide); LL-022 is `:argued` (it has
  positive design argument backing). See
  `docs/os_identity_security_scoping_companion.md` §2.1.
- **Threat-landscape framing (2026-05-05, 0.0.41):** A3
  (kernel-level adversary) is a *catapult-class* threat in
  the cockroach/catapult/castle taxonomy of
  `docs/threat_landscape_companion.md` §2. State-level actors
  who can deploy A3-class capabilities (NSA TAO etc.) are
  rare-and-lethal; LavaLamp's substrate-bound identity claim
  is bounded against this tier by design. Round-3 may
  surface additional A-classes (A7 passive-emanation per
  brief Q7 + companion §2.3) requiring parallel OOS or
  bounded-claim entries.

### LL-016 — sensor-authenticity-requirement
- Key: sensor reads used in the security primitive require independent authenticity check
- Logic tier: Core
- Description: Hardware sensor reads (battery, AC adapter, USB
  status, thermal, scheduler timing) participating in the
  external-potential-field coupling (LL-004) must satisfy an
  independent authenticity check beyond simply trusting the
  reported value. Sensors can be manipulated at the source
  (V-006: a hairdryer drives thermal up; a flashed USB device
  reports plug-events without attaching; a charge controller
  spoofs AC-adapter status). Authenticity strategies in
  decreasing strength: (1) hardware attestation (TPM / Secure
  Enclave-signed reads — depends on LL-022 §2.2.1); (1.5)
  eBPF-based kernel-side sensor-read cross-validation on Linux
  (depends on kernel eBPF support; weaker than TPM-signed reads
  but stronger than pure software cross-validation; defeats A2
  but not A3); (2) multi-sensor cross-validation (correlated
  readings sanity-checked — thermal + battery discharge rate;
  AC + measured current draw; mic + accelerometer); (3)
  anomaly-based flagging (sensor reads outside plausible joint
  envelopes excluded from U(s) participation); (4) accepted
  residual risk with explicit deployment-context guidance.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.4, §3.7;
  docs/attack_surface_enumeration.md §3 V-006;
  docs/os_identity_security_scoping_companion.md §2.3.3
  (strategy 1.5 derivation).
- Notes: Default strategy for the prototype is (2) + (3); (1)
  added when deployment supports it; (1.5) added on Linux
  deployments where TPM is unavailable but eBPF is supported;
  (4) as fallback with documented deployment context. Largest
  residual risk in the architecture.

### LL-017 — verification-no-oracle
- Key: verification protocol must not expose accept/reject feedback usable for threshold probing
- Logic tier: Core
- Description: The verification protocol returns exactly one of
  ACCEPT, REJECT, WARMUP, TRANSITIONING, UNKNOWN_CONFIGURATION,
  RATE_LIMITED — no divergence value, no per-exponent residual,
  no distance-to-threshold, no time-to-detection. Rate-limit
  policy: 10 attempts per minute per (device, source); 100 per
  hour per device-identity across sources. Verifier logs all
  attempts internally for calibration discipline (LL-014) and
  forensics; logs are never exposed to the requester.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.5.4, §3.8;
  docs/attack_surface_enumeration.md §3 V-010.
- Notes: Adaptive thresholding (threshold learning from genuine-
  device history) is recommended future hardening; round-1 uses
  fixed τ.
- **Consumer framing (2026-05-04, P-PharOS):** The no-oracle
  protocol is enforced at the LL-023 consumer-API surface.
  PharOS's `verify(...)` returns Bool only (or one of the
  enumerated state codes); platform shims (PAM module on
  Linux, Authorization Plug-in on macOS, Credential Provider
  on Windows) translate the Bool into platform-native
  authentication results without leaking distance information.
  See `docs/pharos_scoping_companion.md` §2.2.2.

---

## Surfaced by P2 architectural design pass (0.0.5)

### LL-018 — adversary-resolution-bound-formalisation
- Key: per-class A1..A6 quantification of LL-008's resolution margin
- Logic tier: Core
- Description: Formal statement of the resolution-bounded
  security bound across the six adversary classes from
  attack-surface §2. (A1 remote software: h_meas ≈ 0; arbitrary
  margin.) (A2 local unprivileged: bounded by user-space-
  observable timing/API resolution ~10⁻⁶ s; comfortable margin.)
  (A3 kernel-level: out of scope per LL-015; bound does not
  hold and is not claimed.) (A4 side-channel / physical proximity:
  load-bearing class; margin holds when adversary measurement
  bandwidth is sub-Nyquist relative to substrate per LL-005;
  LL-016 sensor authenticity is the load-bearing assumption.)
  (A5 registration-time: addressed by LL-011 protocol, not by
  the resolution bound directly.) (A6 time-localized: bounded by
  single-window observation; addressed by LL-012 cold-start
  protocol.) Prevents the "claim shrinks under reading" failure
  mode where readers project an unconditional bound.
- Evidence type: manual
- Status: :argued
- Source: docs/architecture_design_companion.md §2.2, §3.3;
  docs/attack_surface_enumeration.md §2.
- Notes: Per-deployment threat model must specify which A4
  capability level is assumed. The bound is parametric on this;
  it is not a single number. Lean theorem shape (parametric in
  δ_A and T) pinned in §2.2 of the design companion; P6 work.
- **Threat-landscape framing (2026-05-05, 0.0.41):** A1-A6 are
  the spec's currently-enumerated adversary classes, but the
  threat-landscape companion (`docs/threat_landscape_companion.md`)
  surfaces the broader cockroach/catapult/castle taxonomy:
  cockroach-class threats (small-scale, persistent — A2/A4/A6
  cluster here) vs catapult-class (large-scale, resourced —
  A1/A3/A5 partially; A7 passive-emanation candidate). LL-018
  quantifies per-class margins for A1-A6; if round-3 adds A7
  (LL-025 candidate), LL-018 should extend to A1-A7. See
  threat-landscape companion §2.3-§2.4.

---

## Surfaced by synthesis-team round 2 (0.0.12)

### LL-019 — side-channel-hardening
- Key: chaos-guard state transitions and audit cadence must not leak timing/correlation oracles
- Logic tier: Core
- Description: The chaos-guard (LL-007) state-transition
  responses (WARMUP / INVALID / VALID) must be emitted with
  *constant-time* or *randomised-delay* envelope so that an
  external observer cannot distinguish reseed events from
  legitimate verification load. Reseed triggers are sensor-
  correlated; observable reseed timing is a sensor-event
  oracle for an A4/A5 adversary (V-011). Additionally: the
  full Benettin spectrum audit (LL-006) MUST run on every
  verification request — the chaos-guard's cheap Wolf-method
  λ₁ alone is insufficient because adversaries can craft
  trajectories that match λ₁ but diverge in higher exponents
  (A4 finding from round 2). The Wolf-method guard remains
  the always-on monitor; the Benettin audit on every
  verification closes the inter-audit window. Prototype
  implementation: `verify_full(ds, env; ...)` forces full
  Benettin at the API level (audit-on-every-verify);
  `verify_constant_time(λs, env; target_seconds)` pads
  response time to a uniform target (timing decorrelation).
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Audit.jl (verify_full,
  verify_constant_time).
- Test: src/julia/test/runtests.jl LL-019 @testsets (12
  assertions: verify_full forces Benettin + result equality
  with manual lyapunov_spectrum + verify; strong adversary
  reject; verify_constant_time elapsed ≥ target_seconds;
  result equality with plain verify; Bool-only return;
  argument validation).
- Benchmark:
  src/julia/benchmark/ll019_timing_distribution.jl +
  src/julia/benchmark/results/ll019_timing_distribution.txt
  + docs/ll019_benchmarked_companion.md (two-sample KS test
  on 400 timed verify_constant_time calls bucketed by
  verify result; KS_stat=0.109 < critical=0.170 at α=0.05
  → fail to reject H0 → distributions statistically
  indistinguishable). Performance target: "verify_constant_time
  produces a response-time distribution where accept-bucket
  and reject-bucket are statistically indistinguishable per
  a two-sample KS test at α=0.05" — met.
- Notes: Plain verify also passes the KS test (KS_stat=0.041)
  at the prototype's scale because the data-dependent timing
  channel is sub-microsecond, below OS scheduling jitter.
  At production scale (millisecond-scale data-dependent
  paths) the channel emerges; verify_constant_time is the
  operationally-meaningful defence. Production constant-
  time-response should use an async deadline scheduler
  rather than sleep (which blocks a worker thread); the
  prototype's sleep demonstrates the property at the
  benchmark level. Lean target per round-2 §1D.v: side-
  channel timing indistinguishability theorem; this
  benchmark grounds its theorem statement (see
  docs/ll019_benchmarked_companion.md §3.3).
- **High-resolution refresh (2026-05-04, regime-boundary
  finding):** Per `docs/ll019_high_res_companion.md`, the
  P-R2a timing-distribution benchmark was re-run at 5× sample
  size (1000 per source vs 200) and at α=0.01 (vs 0.05). At
  the high-res regime the KS test loses statistical robustness
  on the prototype's dev host: KS_stat for verify_constant_time
  fluctuates by ~0.04 across runs from system-jitter alone, and
  the verdict can flip from INDISTINGUISHABLE to DISTINGUISHABLE
  between consecutive runs (Run 1: KS=0.073, INDIST; Run 2:
  KS=0.116, DIST; critical_α=0.01=0.093). The 0.0.19 fit at
  α=0.05 / n=400 had margin 0.061 between KS_stat (0.109) and
  critical (0.170) — well above any plausible jitter range.
  **Operational-significance is unchanged**: median/mean
  timing differences across accept/reject buckets remain ~10 μs
  on 100 ms padded operations (ratio 1e-4); adversary
  exploitability is operationally negligible regardless of the
  KS verdict at this regime. The high-res refresh produces
  **regime-boundary documentation**, not a status change:
  LL-019 stays `:benchmarked` at the 0.0.19 evidence regime
  (α=0.05 / n=400). The boundary finding is round-3 input for
  the §Host-OS invariants discipline note in CLAUDE.md (added
  0.0.26.5) — timing-distribution benchmarks have a
  host-isolation threshold below which statistical power is
  jitter-limited. Benchmark script:
  `src/julia/benchmark/ll019_timing_distribution_high_res.jl`;
  result file:
  `src/julia/benchmark/results/ll019_timing_distribution_high_res.txt`.
- **Round-3 deployment-context expansion (2026-05-06, 0.0.50):**
  Per round-3 §1D.iv (ChatGPT edge-witness, A1) and Aaron's
  resolution decision 3 (Tier 3 sequencing), LL-019's scope
  is expanded to cover both deployment regimes:

  **Regime 1 — Dev-host artifact (the 0.0.19 benchmark
  regime).** On a dedicated dev workstation, the data-
  dependent timing channel is sub-microsecond and below the
  OS scheduling-jitter floor; KS-test results at α=0.05 /
  n=400 show statistical indistinguishability with margin.
  Adversary exploitability is operationally negligible
  because the channel sits below the jitter floor. The 0.0.19
  benchmark + 0.0.29 high-res refresh together characterise
  this regime and are the basis for LL-019's
  `:benchmarked` status.

  **Regime 2 — Multi-tenant shared environment (real
  channel).** On shared hosts (cloud VMs; container
  orchestrators with neighbouring workloads; co-tenant CPUs)
  the data-dependent timing channel is *not* below the
  jitter floor — it can be observed and aggregated by a
  co-tenant adversary. The dev-host benchmark does *not*
  characterise this regime. LL-019's `:benchmarked` status
  applies only to deployments that meet the
  shared-environment deployment constraint below.

  **Shared-environment deployment constraint (load-bearing
  for the LL-019 claim under Regime 2).** Deployments in
  multi-tenant or shared-CPU environments must include:

  1. **Dedicated core / pinned scheduling.** LavaLamp's
     verify path runs on a CPU core not shared with
     adversary-accessible workloads (e.g. via `taskset` /
     CPU-affinity / dedicated container with cpu-set).
  2. **Constant-time padding above shared-host noise floor.**
     The padded response duration must be calibrated to
     dominate observable shared-host jitter (operationally
     `pad_target ≥ 10 ms` for typical container hosts;
     calibrated empirically per deployment).
  3. **Jitter randomisation.** A randomised offset
     (uniform on `[0, jitter_window]` with `jitter_window
     ≥ 1 ms`) is added to the response time so that even
     systematic timing leakage is decorrelated from the
     verify result.

  Deployments that do not meet these constraints fall outside
  LL-019's `:benchmarked` claim space. The constraint is
  documented here rather than at LL-022 because it's
  specifically about the LL-019 timing-channel claim, not
  about the broader OS-trust-stack scope LL-022 covers.

  **Why this isn't a status change.** The 0.0.19 benchmark
  evidence is unchanged; the regime-1 claim still holds at
  `:benchmarked`. The amendment surfaces an honest scope-
  limit on the regime-2 generalisation — without the
  shared-environment constraint, the dev-host benchmark
  doesn't transfer. Per ChatGPT's framing in §1C.A1: LL-019
  is *both* a methodological artifact (regime 1) *and* a real
  channel (regime 2); the dev-host benchmark addresses the
  artifact regime, not the channel regime. Status remains
  `:benchmarked` for regime 1; regime 2 has the deployment
  constraint as its `:argued`-tier defence.

  **Round-3 disposition note.** Grok proposed collapsing
  LL-019 into an LL-022 sub-claim ("no new LL-ID required");
  ChatGPT countered that LL-019 stays as a standalone entry
  because the timing-channel structural claim is independent
  of the OS-trust-stack scoping declaration. Aaron's
  resolution decision 3 confirmed the standalone entry
  framing — this amendment is the integration of ChatGPT's
  position.

### LL-020 — calibration-confidentiality
- Key: registered envelope sealed against registration-channel observers, not just substitution
- Logic tier: Core
- Description: The registration ceremony (LL-011) calibrates
  the device's envelope by exposing n_trials Lyapunov-spectrum
  estimates plus per-exponent σ on the registration channel.
  TPM attestation in LL-011 defends *substitution* but not
  *observation* — an A5 adversary present during registration
  captures the registered envelope to machine precision and
  can craft trajectories that lie just inside the rejection
  ball, defeating LL-006 + LL-017 by knowing the threshold
  geometry exactly (V-012). LL-020 requires that the
  registered envelope and per-exponent σ be sealed against
  observers via three layered strategies (P-R2b design):
  (1) TPM-sealed storage on the verifier — primary default
  for hardware-rooted deployments (depends on LL-022 §2.2.1);
  (2) ε-differentially-private perturbation of any published
  envelope statistics — universal fallback when hardware
  support is absent or publication is required (no LL-022
  dependency; cryptographic-library-coupled); (3) Shamir-
  style multi-party threshold scheme on envelope
  reconstruction — primary default for federated /
  multi-trust-root deployments (no LL-022 dependency;
  cryptographic-library-coupled).
- Evidence type: manual
- Status: :argued
- Source: docs/p_r2b_calibration_confidentiality_companion.md
  §2 (three-strategy design space + recommended default
  layering by deployment context); §2.6 (Lean theorem shapes
  per round-2 §1D.v priority 3). Originating attack vector:
  docs/attack_surface_enumeration.md V-012 +
  docs/synthesis_team_round2_companion.md §1C-A2.
- Notes: LL-011 (registration ceremony) defends substitution;
  LL-020 defends observation; both are required for
  production. LL-017 (verification no-oracle) defends
  accept/reject probing; the three together close the
  threshold-geometry leakage path. Implementation is
  platform-coupled (TPM/Secure Enclave/TrustZone) or
  cryptographic-library-coupled (Shamir / DP libraries)
  and sits outside the Julia-prototype scope per the
  language-tier discipline. **Round-2 follow-up
  (2026-05-03):** Strategy 2 (ε-DP perturbation) is
  implemented in
  `src/julia/src/Audit.jl::differentially_private_envelope`
  and example-tested in `src/julia/test/runtests.jl` (23
  assertions covering Gaussian-mechanism σ_DP formula, σ
  floor, DP metadata recording, argument validation,
  reproducibility). See
  `docs/ll020_strategy_2_epsilon_dp_companion.md` for the
  Dwork-Roth §A.1 derivation and the privacy-vs-detection
  trade-off discussion. Strategies 1 (TPM-sealed) and 3
  (Shamir threshold) remain implementation-deferred (P7 /
  P5 respectively); LL-020 entry-level stays `:argued`
  because the multi-strategy approach is the entry's
  claim and partial implementation tests one component,
  not the whole.
- **Round-2 follow-up (2026-05-04, Strategy 2 :benchmarked-
  tier):** The Strategy 2 implementation was refined from
  symmetric Gaussian noise on σ + 1e-10 floor (which
  produced 100% FPR — see `docs/audit_2026-05-04.md`) to a
  variance-convolution form: `σ_pub = sqrt(env.σ² + σ_DP²)`.
  Spectrum stays Gaussian-mechanism (ε,δ)-DP; σ becomes
  deterministic in `env.σ`+`σ_DP` (leaks `env.σ` lower bound
  but is operationally usable for verification). The fix is
  documented in
  `docs/ll020_strategy_2_benchmarked_companion.md` §1.1.
  The detection-power-vs-ε benchmark
  (`src/julia/benchmark/ll020_strategy_2_detection_power.jl`
  + result file
  `src/julia/benchmark/results/ll020_strategy_2_detection_power_lorenz96.txt`)
  produces the expected privacy/detection trade-off curve:
  ε_DP=10 (σ_DP≈0.053) gives K=3.106, c'=0.01325, FPR=0
  (vs no-DP baseline K=0.798, c'=0.00418, FPR=0.10);
  ε_DP=3 (σ_DP≈0.18) reaches 58% detection at ε_A=3.0;
  ε_DP=1/0.3 are operationally vacuous at the prototype's
  N=20 / k=5 / n_trials=10 calibration. **σ_DP /
  σ_true_min** is the operationally meaningful predictor:
  when this ratio exceeds ~3, weak adversaries blend into
  the rejection ball. Strategy 2 closes to `:benchmarked`-
  tier evidence; LL-020 entry-level stays `:argued`
  (multi-strategy approach is the entry's claim).

### LL-021 — worst-case-adversary-bound
- Key: detection-probability claim stated against worst-case adversary direction, not isotropic
- Logic tier: Core
- Description: The LL-006 detection-probability bound shape
  P(detect) ≥ 1 - K·exp(-c·T·δ_A²) must use the *worst-case*
  spectrum gap δ_A_worst — the minimum over all admissible
  adversary directions in α-space — rather than the isotropic-
  average. LL-021 derives the worst-case direction analytically
  (the û orthogonal to the mean-coupling vector
  m = (mean(b_1), …, mean(b_n)), reducing δ_A by a factor
  set by the coupling matrix's condition number) and
  demonstrates the asymmetry empirically via the structured-
  adversary benchmark. For the prototype's two-channel system
  with b_1 = e_1 (narrow) vs b_2 = ones(N) (broad), the
  worst-case (NARROW direction) detection probability is at
  the FPR baseline across ε_A ∈ {0.5, 1.0, 2.0, 4.0} while
  the best-case (BROAD direction) saturates at 1.00 for
  ε_A ≥ 1.0 — the empirical asymmetry is essentially
  unbounded at this configuration's calibration noise floor.
- Evidence type: lean-proved (promoted from `benchmarked` at
  0.0.48 — see "Lean theorem proved" footer below)
- Status: :proved (promoted from `:benchmarked` at 0.0.48)
- Source: src/julia/src/Audit.jl synthetic_adversary
  (direction parameter supports explicit û).
- Test: src/julia/benchmark/p_r2c_structured_adversary.jl +
  src/julia/benchmark/results/p_r2c_structured_lorenz96.txt
  (committed empirical surface; 12 data points across 3
  directions × 4 magnitudes × 5 trials at N=20, k=5,
  verify_full audit-on-every-verify).
- Benchmark: docs/ll021_benchmarked_companion.md §2 — fitted
  worst-case constants K=1, c′=0.02777, T=60 (parameterised
  on ε_eff = ε_A · proj(û onto m_unit) where m is the
  mean-coupling vector). Bound holds at 9 of 12 data
  points pointwise; the 3 with negative margin have Wilson
  95% CIs covering the bound prediction (sampling-variance
  consistent at n=5). c′_worst = 0.02777 is 6.6× larger
  than c′_isotropic = 0.00423 from P3-bound (LL-006);
  the two bounds describe the same shape under different
  parameterisations. Performance target: "fitted worst-case
  bound holds across the prototype's structured-adversary
  surface" — met within sampling-variance bounds.
- Notes: Production deployments have three options for
  reducing worst-case under-estimation: (1) choose coupling
  vectors with uniform support (reduces condition number);
  (2) increase n (more channels) so the orthogonal-to-mean-
  coupling subspace is high-dimensional and adversaries
  cannot easily place ε in it; (3) accept the bound and
  document the deployment-context-bounded weakness. The
  prototype lands option 3 with documented benchmark.
  :benchmarked upgrade (calibrating K, c constants against
  the empirical worst-case curve) and Lean theorem (round-2
  §1D.v priority 1) are P5/P6 followups. See
  docs/p_r2c_worst_case_adversary_companion.md.
- **High-resolution refresh (2026-05-04, n=5 → n=15):** Per
  `docs/ll021_high_res_companion.md`, the P-R2c surface was
  re-benchmarked at 15 trials per (direction, magnitude)
  point (vs the original 5). Refined fitted constants:
  `K=1, c′=0.0288, T=60.0` (vs n=5 fit's c′=0.02777 — 3.8 %
  shift, well within sampling-variance bounds). The binding
  constraint migrates from MIXED ε_A=1.0 (P≈0.6 at n=5) to
  NARROW ε_A=4.0 (P≈0.07 at n=15, FPR-floor regime — 1 of 15
  trials reject). 11 of 12 points now hold pointwise (was
  9 of 12 at n=5); the single remaining negative-margin
  point (NARROW ε_A=1.00, margin -0.004) is FPR-floor and
  Wilson-95%-CI-consistent ([0, 0.218] covers bound 0.004).
  Wilson CIs tighten by ~50 % at the same P̂ (theoretical
  sqrt(15/5)=1.73× tightening; empirical 0.5-0.7× width).
  The high-res refresh **confirms** the n=5 fit at higher
  statistical confidence rather than overturning it; LL-021
  status stays `:benchmarked`. Benchmark script:
  `src/julia/benchmark/p_r2c_structured_adversary_high_res.jl`;
  result file:
  `src/julia/benchmark/results/p_r2c_structured_high_res_lorenz96.txt`
  (deterministic; wall-clock timings excluded from result
  file per the CLAUDE.md §Benchmarking discipline byte-
  identical convention).
- **Round-3 scope-limit + adaptive-adversary amendment
  (2026-05-06, 0.0.46):** Two-pronged amendment surfaced by
  synthesis-team round 3 §1C.A4 + §1C.A5 (ChatGPT edge-
  witness):

  (a) **Scope-limit to finite-N regime.** The benchmark fit
  constants (K=1, c′=0.0288, T=60.0) were validated at N=20
  in 0.0.18 + 0.0.28; the bound shape `ε_eff = ε_A · proj`
  applies in the finite-N regime (operationally N ≤ 80).
  Large-N regime (N ≥ 160) requires re-benchmarking — at
  N=160 the attractor has 52 unstable / 108 stable
  directions, and the curvature of the attractor manifold,
  mixing times, and per-mode detectability thresholds may
  shift the parametric constants. See V-020 (stable-manifold
  stealth injection) for the attack-class surfaced at
  large N.

  (b) **Adaptive-adversary bound.** The bound is stated
  against an *adaptive* linear-model adversary, not a
  static one. The 0.0.31 per-SDE detection-power result
  shows the bound shape is universal across Lorenz-96 /
  Lorenz-63 / Rössler at the prototype configuration; this
  is structurally consequential for adversary capability —
  *one* successful linear-model fit by an adversary applies
  to all candidate SDEs at the same configuration. Real
  adversaries adapt; the bound must be honest about that.
  See `synthesis_team_round3_companion.md` §1C.A4 — ChatGPT
  *"if all SDEs share the same bound shape, attacker needs
  only one successful model. LL-021 is a containment bound,
  not closure of A6."*

  Status unchanged at `:benchmarked` — these are scope /
  framing amendments to the existing benchmark evidence,
  not new evidence requirements. Future Lean formalization
  (Tier 2 first theorem; round-3 §1D.v decision: Option A
  Mathlib full) will state the bound parametric in
  adversary-tier and N regime, capturing the scope-limits in
  the theorem statement.
- **Lean theorem-statement landed (2026-05-06, 0.0.47):**
  Per round-3 §1D.v Decision 1 (Option A — full Mathlib),
  the Lean 4 track at `src/lean4/` integrates Mathlib v4.29.1
  (toolchain bumped v4.18.0 → v4.29.1; Mathlib + 8 transitive
  deps pinned in `lake-manifest.json`) and lands a
  sorry-stubbed theorem statement
  `LavaLamp.LL021_worst_case_bound` capturing the bound
  shape: `0 ≤ ε_A → proj ≤ 1 → ε_A * proj ≤ ε_A`
  (i.e. the projected effective magnitude `ε_eff = ε_A · proj`
  cannot exceed `ε_A`). Build clean (767 jobs; single
  expected `declaration uses 'sorry'` warning on the theorem).
  Status stays `:benchmarked` per CLAUDE.md §Honest framing —
  a sorry-stubbed theorem is not a proof.
- **Lean theorem proved (2026-05-06, 0.0.48 — L2):** The
  `sorry` body in `LavaLamp.LL021_worst_case_bound` is
  replaced by `mul_le_of_le_one_right h_ε h_proj_le_one`, a
  direct application of Mathlib's
  `mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`.
  `lake build` returns 767 jobs green with **zero `sorry`
  warnings** — the kernel verifies the proof at compile time.
  The hypothesis `0 ≤ proj` was dropped from the theorem
  signature: the bound holds for negative `proj` too (the
  product becomes non-positive, trivially `≤ ε_A` for
  non-negative `ε_A`), and the geometric construction
  `proj = |û · m_unit|` already guarantees `0 ≤ proj` at the
  call sites where it matters; downstream theorems (LL-006
  detection-bound via `ε_eff²`) will introduce that hypothesis
  where they need it. **Evidence type promotes** `benchmarked`
  → `lean-proved`; **status promotes** `:benchmarked` →
  `:proved`. This is the first-ever LavaLamp `:proved` entry.
  Counts: 27/0/3/0/5/18/1 → 27/1/3/0/4/18/1 (+1 :proved /
  −1 :benchmarked). The `:benchmarked` empirical fit-constant
  content (`K=1, c′=0.0288, T=60` at N=20) is preserved as
  the operational deployment-fit detail; the Lean theorem
  captures the bound *shape* and is the `:proved` content.
- **Squared-effective-magnitude composition foothold (2026-05-06,
  0.0.49):** A corollary lemma `LL021_eff_squared_bound :
  0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 → (ε_A · proj)² ≤ ε_A²`
  lands in `src/lean4/LavaLamp/Theorems.lean` alongside the
  worst-case bound, proved by `pow_le_pow_left₀` over the
  worst-case bound and `mul_nonneg`. This is the algebraic
  step that connects LL-021 to LL-006: the detection-
  probability bound shape `P(detect) ≥ 1 - K · exp(-c · T ·
  ε_eff²)` from LL-006 inherits the squared-magnitude
  monotonicity from this lemma — `ε_eff² ≤ ε_A²` and `t ↦
  exp(-c · T · t)` decreasing in `t` together imply
  `exp(-c · T · ε_eff²) ≥ exp(-c · T · ε_A²)`, so the
  worst-case detection probability is *lower* than the
  isotropic-ε_A detection probability (the structural claim
  LL-021 is making about asymmetry). Unlike the worst-case
  bound itself, this lemma genuinely uses `0 ≤ proj` —
  reintroduced in the signature here even though
  `LL021_worst_case_bound` does not need it. Status unchanged
  at `:proved` (LL-021 was already promoted at 0.0.48; this
  is additional `lean-proved` content supporting the same
  entry, not a new entry). Sets the composition foothold for
  the round-3 §1D.v priority-4 LL-006 detection-bound theorem.
- **LL-006 composition theorem cashes the foothold (2026-05-06,
  0.0.54):** `LL006_worst_case_lower_than_isotropic` lands in
  `src/lean4/LavaLamp/Theorems.lean`, composing
  `LL021_eff_squared_bound` (this entry) with `Real.exp`
  monotonicity to prove the asymmetry claim — the worst-case
  detection-probability bound value is `≤` the isotropic
  bound value. See LL-006's "LL-021/LL-006 composition
  theorem" footer for the full statement + proof structure;
  LL-021 status unchanged at `:proved`.

---

## Surfaced by P-OS OS-level scoping pass (0.0.26)

### LL-022 — OS-trust-stack-dependency
- Key: positive enumeration of OS / firmware / hardware-root mechanisms LavaLamp's claims depend on
- Logic tier: Boundary
- Description: Formal statement of what LavaLamp's security
  claims *depend on* from the OS / firmware / hardware-root
  layers, and what is *recommended* as defense-in-depth.
  **Required (load-bearing for spec claims):** (a) hardware
  root of trust — TPM 2.0 / Secure Enclave / TrustZone API
  exposing attestation, sealing, and device-bound identity-
  key primitives (LL-011 default protocol B+D, LL-016
  strategy 1, LL-020 strategy 1); (b) OS sensor APIs at
  LL-005-compliant bandwidths (sysfs / IOKit / similar; per-
  platform syscalls; LL-004 / LL-005); (c) host TRNG —
  `getrandom(2)` / `SecRandomCopyBytes` / `BCryptGenRandom`
  for LL-007 chaos-guard reseed (the only required mechanism
  with no graceful fallback); (d) user/kernel process
  isolation (LL-018 A2-margin assumption — without it, A2
  collapses to A3 and LL-015 applies).
  **Recommended (defense-in-depth, not load-bearing):**
  (e) Secure Boot / measured boot / cold-boot RAM hardening
  for LL-012 cold-start integrity (composes a parallel chain-
  of-custody to WARMUP-state authentication); (f) IMA /
  kernel-lockdown / mandatory access control to raise A3
  capability cost without claiming defence (LL-015 unchanged);
  (g) eBPF-based sensor authentication on Linux as LL-016
  strategy 1.5 between hardware attestation and pure software
  cross-validation. LL-022 is the *upward* OS-stack boundary;
  LL-015 is the *downward* OS-stack boundary; the two together
  close the trust-stack scoping question.
- Evidence type: manual
- Status: :argued
- Source: docs/os_identity_security_scoping_companion.md §2.
- Notes: Parallel boundary entry to LL-009 / LL-010 / LL-015.
  LL-022 is `:argued` (positive dependency claim with manual
  argument backing); LL-015 stays `:open` (non-defence
  declaration with no positive evidence to provide). Three of
  the four required mechanisms have graceful fallbacks (TPM
  → multi-party registration; sensor APIs → reduced channel
  set; user/kernel isolation → A2 collapses to A3 and LL-015
  applies). The host TRNG (c) is the no-fallback case —
  embedded deployments must verify TRNG availability before
  anything else and treat its absence as a deployment blocker.
  :tested upgrade would require deployment-spec tooling that
  checks each required mechanism's presence; deferred to P7.
  :proved is structurally infeasible in the prototype scope —
  LL-022 is a meta-claim about other LL claims and depends on
  Lean proofs of those first (P5/P6 work). LL-022 stays
  `:argued` permanently in the prototype's scope.
- **Theorem-shape implication:** Any future Lean theorem about
  an LL claim that depends on an LL-022 mechanism must be
  stated parametrically — `forall (os : OSAssumptions)
  (proof_os : LL022.satisfies os), <LL_property>` — rather
  than unconditionally. The asymmetry-trap defence is making
  the OS dependency explicit in the theorem statement, not
  implicit in surrounding text. See
  `docs/os_identity_security_scoping_companion.md` §2.6.
- **Closure with LL-023 (2026-05-04, P-PharOS):** LL-022 is the
  *downward* trust-stack boundary (what LavaLamp depends on
  from below); LL-023 is the *upward* trust-stack boundary
  (what consumers depend on LavaLamp for). The pair closes the
  trust-stack scoping question on both ends. Either alone is
  incomplete; together they are the asymmetry-trap defence at
  the trust-stack boundary. See
  `docs/pharos_scoping_companion.md` §2.5.
- **Threat-landscape framing (2026-05-05, 0.0.41):** LL-022's
  required + recommended OS mechanisms are the *castle walls'
  structural requirements* in the cockroach/catapult/castle
  taxonomy of `docs/threat_landscape_companion.md` §2.5. The
  companion surfaces additional load-bearing assumptions
  (§4.3) that LL-022 implicitly makes but doesn't articulate:
  software dependency-graph integrity; cryptographic-primitive
  correctness; substrate stability over deployment lifetime;
  quantum-threat-horizon proximity. Round-3 may surface
  whether any of these deserve explicit Boundary entries
  paralleling LL-022's shape (companion §6 questions 2-5).

### LL-023 — consumer-API-surface
- Key: stable API surface LavaLamp exposes to OS-deployment consumers
- Logic tier: Boundary
- Description: Formal statement of the consumer-API contract
  LavaLamp commits to expose for downstream OS-deployment
  consumers. Four operations: `register(device,
  envelope_storage_path) → registration_handle` (called once
  at install / first-boot per LL-011); `verify(handle,
  trajectory) → Bool` (per-request authentication; LL-017
  no-oracle; variants `verify_full` per LL-019 and
  `verify_constant_time` per LL-019); `device_state() →
  GuardState` (chaos-guard status per LL-007; INVALID /
  WARMUP / VALID); `re_register(handle, new_path) →
  new_handle` (time-bounded re-registration per LL-011
  variant C). PharOS is the canonical first instantiation
  (forthcoming OS-level identity layer; lighthouse-metaphor
  reference in the Triad Deployments portfolio); Lazarus and
  future embedded SDK consumers also conform. The surface is
  Boundary-tier because it scopes what LavaLamp exposes, not
  what the security primitive does internally — analogous to
  LL-022 (downward) and LL-015 (kernel OOS).
- Evidence type: manual
- Status: :argued
- Source: docs/pharos_scoping_companion.md §2.
- Notes: PharOS does not yet exist as a separate repo. This
  entry documents LavaLamp's *commitment to expose* the
  surface; the consumer-side conformance evidence (PharOS's
  spec / tests) will land in PharOS's future repo. LL-023
  pairs with LL-022 to close the trust-stack scoping question
  (downward + upward). `:tested` upgrade requires a
  deployment-spec test suite that loads a candidate consumer
  and verifies LL-023 conformance — operational tooling that
  lands when consumers themselves exist; deferred. `:proved`
  requires Lean meta-theorems on consumer inheritance
  (P5/P6 work).
- **Theorem-shape implication:** A consumer (PharOS) that
  conforms to LL-023's API contract inherits LavaLamp's
  properties parametric in the consumer's OS assumptions.
  The closure of LL-022 (downward) + LL-023 (upward) gives
  the Triad Deployments collective security claim its formal
  grounding. See `docs/pharos_scoping_companion.md` §2.6.

---

## Surfaced by P-RS real-sensor scoping pass (0.0.38)

### LL-024 — real-sensor-deployment-strategy
- Key: per-platform FFI strategy bridging synthetic-stream prototype to hardware-bound deployment
- Logic tier: Operational
- Description: Articulates the per-platform real-sensor
  implementation strategy that bridges the current
  synthetic-stream prototype (Level 1 — Sensors.jl
  primitives) to a hardware-bound deployment (Level 2 —
  RealSensors.jl FFI). Six sensor categories per LL-004
  enumeration: thermal, battery, AC adapter, USB peripheral,
  CPU governor, scheduler timing / load average. Per-platform
  surface: Linux uses pure file I/O via sysfs/procfs (target
  first platform; ~3-5 days dev work; no FFI); macOS uses
  IOKit / SMC FFI (~2 weeks; per-Mac-model sensor discovery);
  Windows uses WMI + PDH (~2-3 weeks). Sample rates per LL-005
  nyquist_compliant must hold per (sensor, assumed adversary
  bandwidth) pair at deployment-config time. Authenticity
  strategies per LL-016 in real-hardware context: strategy 2
  (multi-sensor cross-validation) is the prototype-tier
  default; strategy 1.5 (eBPF on Linux) for hardened
  deployments; strategy 1 (TPM-signed reads) deferred to P7
  hardening per LL-022 §2.2.1. Phase 1 roadmap: Linux baseline
  first (~1 week post-round-3); Phase 2 macOS; Phase 3
  Windows; Phase 4 (P7) TPM integration on all platforms.
- Evidence type: manual
- Status: :argued
- Source: docs/p_real_sensor_scoping_companion.md §2.
- Notes: Scaffold module `src/julia/src/RealSensors.jl`
  landed at 0.0.38 with API stubs that error meaningfully
  pointing to the scoping companion. Scaffold tier
  (mirrors the 0.0.36 Lean scaffold pattern: infrastructure-
  prep, not evidence). LL-024's `:argued` evidence is the
  design synthesis at the scoping-companion level, not the
  scaffold module. `:tested` upgrade requires Phase 1
  (Linux baseline) implementation + tests on real or
  recorded sensor traces; `:benchmarked` upgrade requires
  empirical performance characterisation on real hardware
  (real-sensor SNR vs synthetic-stream SNR; detection bound
  preserved against parameter-perturbation adversaries;
  cross-validation catches V-006 manipulation attempts).
  Both promotion paths are post-round-3 and post-engine.
- **Three-layer deployment-stack triple (2026-05-04, P-RS):**
  LL-022 (downward — what OS surfaces are required) +
  LL-023 (upward — what consumers see) + LL-024 (operational
  — which sensors get read at what rates with what
  authenticity strategy) form a three-layer commitment
  that closes the deployment-stack scoping question. The
  triple is corpus-honest: Aaron's closure work targets
  three-element relational closures, and the three Boundary/
  Operational entries here mirror that pattern at the
  spec level.

---

## Surfaced by synthesis-team round 3 (0.0.45+)

### LL-025 — A7-passive-emanation-boundary
- Key: tier-bounded scoping of TEMPEST-class side-channel attacks (A7)
- Logic tier: Boundary
- Description: Formal statement of LavaLamp's defense posture
  against passive-emanation reconstruction attacks (TEMPEST-
  class A7). The claim is **tier-bounded**, not universal, and
  parallels the LL-015 shape (A3 OOS) in declaring scope rather
  than promising defense. Three adversary tiers:

  **Tier 1 — State actor (sub-meter, lab equipment, targeted
  device).** Modern TEMPEST research (Genkin et al. 2014 RSA-
  from-acoustic; DDR3/DDR4 EM leakage; van Eck phreaking)
  demonstrates partial state recovery from EM / acoustic /
  optical emanations at this tier. LavaLamp's primitive does
  not defend against Tier 1 adversaries; deployments requiring
  Tier 1 resistance must use TEMPEST-rated enclosures +
  hardware-platform-tier guidance (PharOS scope). LL-025
  declares scope, not defense.

  **Tier 2 — Mid-tier (room-scale SDR, commercial equipment).**
  Signal extraction is possible; full trajectory reconstruction
  is unlikely at LavaLamp's chaos-production rate (h_KS · N).
  LL-025 applies deployment-context guidance: avoid co-located
  shared-environment deployments where Tier 2 capture is
  plausible.

  **Tier 3 — Commodity adversary (no specialized equipment).**
  The noise floor of multi-GHz CPUs plus the decode complexity
  at LavaLamp's chaos-production rate makes A7 attacks
  negligible at this tier. LL-025 implicitly defends Tier 3.

  LL-025 forms a **parallel boundary triple** with LL-015
  (downward adversary boundary — A3 OOS) and LL-024
  (operational sensor instantiation). The three close adversary
  scoping at three levels: *what's structurally out of scope*
  (LL-015), *what's tier-bounded* (LL-025), *what we
  instantiate operationally* (LL-024).
- Evidence type: manual
- Status: :argued
- Source: docs/synthesis_team_round3_companion.md §1B.Q7 +
  §1C.A7; attack-surface entry V-014.
- Notes: LL-025 mirrors LL-015's "scope declaration" pattern at
  the side-channel boundary rather than the kernel boundary.
  The tier-bounded honest framing (per ChatGPT round 3 §1C.A7
  *"V-014 is real but bounded: should be explicitly scoped, not
  universalized"*) is the load-bearing structure. Promotion
  paths: `:tested` would require empirical EM / acoustic
  emanation measurements on a reference deployment +
  reconstruction attempts at each tier (operational-tooling
  work; deferred); `:proved` is structurally infeasible (LL-025
  is a deployment-context scoping commitment, not a property of
  the primitive). LL-025 stays `:argued` permanently in the
  prototype's scope, paralleling LL-015's permanent `:open`
  status.
- **Theorem-shape implication:** Future Lean theorems about
  trajectory privacy or unobservability must be stated
  parametrically in adversary tier — `forall (tier :
  AdversaryTier) (h_tier : tier ≤ Tier3),
  <unobservability_property>` — rather than unconditionally.
  The asymmetry-trap defense is making tier-boundedness
  explicit in the theorem statement. See
  `synthesis_team_round3_companion.md` §1C.A7.
- **Threat-landscape framing:** LL-025 covers the "virus /
  cancer injection under our nose" defeat condition of the
  cockroach / catapult / castle metaphor
  (`threat_landscape_companion.md` §2.4). Tier 1 (state actor)
  is the adversary class for which this defeat is real; LL-025
  declares scope honestly rather than promising defense.

### LL-026 — three-layer-logic-tier-annotation-discipline
- Key: every spec entry tagged Possibilistic / Probabilistic / Bridge per paper §1.2
- Logic tier: Core
- Description: Spec-level governance discipline requiring every
  LL entry to carry an explicit logical-tier annotation per the
  closure_forces_structure paper §1.2 three-layer logic
  structure:

  - **Possibilistic Layer.** Claims about what is *forced*,
    *forbidden*, or *compatible* under the constraint surface.
    Discrete combinatorial. Examples: LL-001 substrate-bound
    identity (forbidden: cloning); LL-008 resolution-bounded
    security (forbidden: forge below resolution boundary);
    LL-018 per-class quantification (forced: A1 / A2 / A4
    capability bounds).

  - **Probabilistic Layer.** Claims about statistical bounds,
    detection probabilities, FPR / FNR, ε-DP envelopes.
    Measurement-tier. Examples: LL-006 detection bound
    `P(detect) ≥ 1 - K·exp(-c·T·δ²)`; LL-019 KS-test timing-
    indistinguishability; LL-020 ε-DP envelope; LL-021 worst-
    case bound `ε_eff ≤ ε_A · proj`.

  - **Bridge Layer.** Claims spanning the layers: deployment
    protocols, ceremonies, transition-handling. Examples:
    LL-011 registration ceremony; LL-012 cold-start; LL-013
    cross-config; LL-017 verification-no-oracle.

  The discipline is the defense against V-017 (logical-tier
  confusion attacks): an adversary cannot apply Probabilistic
  reasoning to a claim that's tagged Possibilistic. Per-entry
  tags are added to existing LL-001..LL-024 entries in a
  follow-up small-session pass; new entries (LL-027+) carry
  tags from creation.
- Evidence type: manual
- Status: :argued
- Source: docs/synthesis_team_round3_companion.md §1B.Q1 +
  §1C.A6 + closure_forces_structure paper §1.2.
- Notes: LL-026 is a **governance discipline**, not an
  engineering primitive. The "test" is consistency: every spec
  entry has a tag; cross-audit can include layer-consistency
  check. `:tested` upgrade meaningless for a documentation
  discipline; `:proved` similarly inapplicable. LL-026 stays
  `:argued` permanently — the discipline IS the evidence.
- **Round-3 origin:** Both seats independently surfaced this
  discipline. Grok §1B.Q1 noted LL-005's parameter-compliance
  sub-claim is Possibilistic and adversary detection is Bridge-
  layer. ChatGPT §1C.A6 named V-017 explicitly as *"meta-
  attack: apply probabilistic reasoning to possibilistic
  claims; exploit mismatch in guarantee type"*. The discipline
  defends V-017 by construction.
- **Per-entry annotation pass (pending):** existing LL-001..
  LL-024 entries will be annotated in a follow-up pass (small-
  session scope). The annotation is documentation-only;
  existing entry text remains unchanged.

### LL-027 — asymptotic-Lyapunov-density-invariant
- Key: asymptotic Lyapunov density `s ≈ 0.255` per dimension is deployment-invariant for Lorenz-96 at F=8
- Logic tier: Core
- Description: The Lorenz-96 SDE at F=8 exhibits **linear
  extensive-chaos scaling**: the metric (Kolmogorov-Sinai)
  entropy rate `h_KS(N)` scales linearly with system size N
  with asymptotic density `s ≈ 0.255` per dimension.
  Empirically validated at N ∈ {20, 40, 80, 160} via the
  0.0.30 P3e benchmark (linear fit `h_KS(N) = s · N` with
  `s ≈ 0.2547` at N=160). The density is deployment-
  invariant: it depends on the SDE's parametric family +
  forcing, not on N or on coupling structure; it emerges
  from the Lorenz-96 attractor's geometry.

  **Deployment-design rule.** For a target chaos-production
  rate `Δh*`, choose `N* ≈ Δh* / s = Δh* / 0.255`. PharOS
  (high-assurance, OS-auth identity) targets `Δh* = 8.0` at
  N* ≈ 32; Lazarus (consumer-product) targets `Δh* = 4.0`
  at N* ≈ 16. The 0.0.30 benchmark validates the linear
  scaling through N=160; deployments at larger N inherit the
  invariant by extrapolation (modulo LL-021 large-N caveat
  on stable-direction attack surface — see V-020).

  **Paper-tier framing (paper §10.1-10.2):** the linear
  extensive-chaos result aligns with the
  closure_forces_structure paper's §10.1-10.2 treatment of
  bound-shape universality across SDE families. The density
  `s` is a property of the attractor, not of the candidate
  SDE family — Lorenz-63 / Rössler at their natural
  F-equivalent forcing exhibit different density values, but
  the *linear scaling form* is universal.
- Evidence type: benchmarked
- Status: :benchmarked
- Source: src/julia/src/Engine.jl (Lorenz-96 at F=8;
  parametric over N).
- Test: src/julia/benchmark/p3e_n_scaling.jl +
  src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt
  (deterministic per-N spectrum; linear fit
  `h_KS(N) = s · N` with `s ≈ 0.255` at F=8 across N ∈
  {20, 40, 80, 160}).
- Benchmark: docs/p3e_n_scaling_companion.md (linear
  extensive-chaos scaling confirmed; Lyapunov density
  `s ≈ 0.255` per dimension at F=8; per-N spectrum compute
  cost O(N³)).
- Notes: LL-027 promotes the 0.0.30 N-scaling result from a
  *deployment-design rule* (in the P3e companion) to a
  *spec-level invariant claim*. The promotion is what
  Grok §1B.Q6 proposed and Aaron's resolution decision 3
  confirmed (Tier 2 sequencing). Depends on LL-003 (single-
  attractor chaotic engine — Lorenz-96 at F=8 is the target
  SDE). LL-027's `:benchmarked` status comes from the 0.0.30
  benchmark *being* the empirical evidence; no additional
  benchmarking required to land the entry.
- **Lean theorem-shape implication:** Future Lean theorem
  about deployment-config sizing must use LL-027 as a
  parametric input — `N ≥ ceil(Δh_target / s_invariant)`
  where `s_invariant = 0.255` is the LL-027 constant. The
  invariant lifts to a real-valued constant in the Lean
  formalization with provenance traced to the P3e benchmark
  result file.
- **Round-3 origin:** Grok §1B.Q6 surfaced this as a
  parametric-invariant promotion candidate; ChatGPT §1C.A5
  surfaced V-020 as the large-N caveat that LL-027 must
  acknowledge (the linear scaling form holds; the *attack
  surface* at large N is open per V-020 and the LL-021
  amendment in this version).

### LL-028 — runtime-conformance-verification
- Key: deployment-stack triple specifies what must hold; runtime conformance specifies how to verify it holds at runtime
- Logic tier: Boundary
- Description: The deployment-stack triple (LL-022 + LL-023 +
  LL-024) defines what LavaLamp's claims *depend on* (LL-022:
  OS-trust-stack required mechanisms), what LavaLamp *exposes*
  (LL-023: consumer-API-surface), and *how* LavaLamp
  instantiates against real sensors (LL-024: real-sensor-
  deployment-strategy). Each entry specifies *requirements*;
  none specifies *runtime enforcement* of those requirements.
  A malicious or compromised deployer can satisfy the LL-023
  API contract while violating LL-022 invariants internally —
  the type/interface-level conformance vs semantic/invariant-
  level conformance gap (V-019).

  **Concrete bypass shapes (V-019 scenarios):**

  - **TRNG-replacement.** LL-022(c) requires OS-grade entropy
    sources (e.g. `getrandom` on Linux, `SecRandomCopyBytes`
    on Darwin). Adversary substitutes a deterministic PRNG
    seeded once at boot; verifier sees the API-shape
    `getrandom(buf, len, 0)` succeed; under the hood, the
    entropy is replayable.
  - **Sensor-fusion forgery.** LL-024 Strategy 2 requires
    multi-sensor cross-validation. Adversary replaces sensor
    reads with cached or scripted values that satisfy the
    cross-validation algorithm without actually reading
    hardware.
  - **TPM-attestation stub.** LL-022(a) requires hardware
    root of trust. Adversary returns hardcoded `valid` from
    the attestation API stub without invoking TPM hardware.
  - **Cached-randomness reuse.** Verifier reads "fresh"
    randomness from a buffer that was filled once and is
    silently re-served; LL-022(c) freshness invariant
    violated, API contract preserved.

  **Conformance requirement.** LavaLamp deployments must
  include runtime invariant verification — the deployment is
  not just *configured* to satisfy LL-022/023/024 but is
  *continuously verified* to be doing so:

  1. **Attestation continuity.** TPM-attested boot (where
     LL-022(a) requires hardware root of trust) PLUS measured
     runtime state — periodic re-attestation that the running
     binary matches the boot-time-attested measurement.
  2. **Sensor cross-validation with adversarial probes.**
     Periodic LL-024 cross-validation runs include
     adversarial test inputs (e.g. challenge-response patterns
     across sensor families) to detect cached / scripted
     sensor responses.
  3. **Verifier-side LL-023 API probing.** Verifier issues
     LL-023 API queries with embedded conformance probes —
     queries whose results would diverge if the deployer were
     stubbing rather than executing the underlying
     mechanisms (e.g. statistical fingerprints of TRNG output;
     cross-call entropy decorrelation tests).
  4. **Continuous TRNG attestation.** Where the platform
     supports it (e.g. Intel CPU `RDRAND` health-check
     return-code), verifier reads the health-check status
     alongside random output.

  These four requirements are operational-tier; they must be
  satisfied by the deployment, not by LavaLamp's internal
  logic. LL-028 is the spec-level statement that runtime
  conformance is a Boundary requirement: LavaLamp's
  resolution-bounded security claim (LL-008) holds *only* in
  deployments where runtime conformance is verified.
- Evidence type: manual
- Status: :argued
- Source: docs/synthesis_team_round3_companion.md §1C.A3
  (ChatGPT round-3 edge-witness seat) +
  docs/attack_surface_enumeration.md §3 V-019.
- Notes: LL-028 is a **Boundary** entry: it specifies a
  scope-limit on LL-022/023/024's claim space rather than
  introducing a new internal mechanism. Without runtime
  conformance verification, the deployment-stack triple is
  *honest about its scope* (configuration trust) but the
  attack surface is real for adversaries who control the
  deployment context (A2 deployer; occasionally A3 in deeper
  bypass).

  **`:tested` upgrade path.** P-RS Level 2 prototype must
  include a conformance-check module that exercises the four
  requirements above on the prototype's reference deployment
  (Linux + TPM-equipped host). Deferred — engineering work,
  sequenced by P-RS Level 2 prototype availability per
  round-3 §1D.viii.
- **Round-3 origin:** ChatGPT §1C.A3 surfaced this as a gap
  in the deployment-stack triple's runtime-enforcement
  posture: *"system satisfies API but violates invariants
  internally. This is equivalent to type-level vs semantic
  conformance mismatch."* Defends V-019. Logic tier
  Boundary because it scopes the claim-space of LL-022 +
  LL-023 + LL-024 rather than introducing a new
  load-bearing internal mechanism. Depends on LL-022, LL-023,
  LL-024 (the triple LL-028 scopes); composes with LL-026
  (the conformance check is a Bridge-layer protocol per the
  three-layer logic-tier discipline).

### LL-029 — multi-channel-entropy-independence
- Key: cross-validation requires physical-mechanism diversity, not just sensor diversity
- Logic tier: Operational
- Description: LL-016 Strategy 2 (multi-sensor cross-
  validation) defends against *naive* spoofing where the
  adversary manipulates one sensor in isolation. The defence
  rests on the implicit assumption that distinct sensors
  carry *independent* entropy. The assumption fails when
  sensors share an underlying *physical mechanism* — a
  determined adversary can physically couple channels to
  satisfy the cross-validation constraints rather than
  violate them (V-018):

  - **Heater → thermal sensor + battery-discharge sensor.**
    Both downstream of the heat-injection mechanism;
    correlated under coupling.
  - **Load injector → AC current draw + thermal rise sensor.**
    Both downstream of the load mechanism; correlated.
  - **Vibration motor → microphone + accelerometer.** Both
    downstream of the mechanical mechanism; correlated.

  The cross-validation algorithm sees correlated readings —
  which is *exactly the signal it's looking for* — and
  passes. The attack defeats LL-016 Strategy 2 *because the
  independence assumption is wrong*, not because the
  cross-validation mechanism is wrong.

  **Independence requirement.** Sensor selection must span
  *uncorrelated physical mechanisms*, not merely uncorrelated
  sensors. LavaLamp deployments must enumerate the
  physical-mechanism families their sensors draw from, and
  cross-validation must operate across at least two
  uncorrelated families.

  **Physical-mechanism family taxonomy (initial; deployment-
  expandable):**

  1. **Thermal.** Temperature sensors; battery-discharge
     curves; CPU thermal-throttle telemetry; cooler-fan PWM;
     thermal-runaway timers.
  2. **Acoustic / vibrational.** Microphones; accelerometers;
     gyroscopes; mechanical-resonance sensors.
  3. **Electromagnetic / RF.** EMI sensors; antenna noise
     floor; magnetic-field sensors; RFID-tag detection.
  4. **Electrical.** Voltage rails; AC current draw; ground-
     plane impedance; PSU noise; bus contention timing.
  5. **Optical.** Ambient-light sensors; camera sensor noise;
     IR proximity; OLED display refresh patterns.
  6. **Entropy-source-decay.** Hardware TRNG drift over time;
     CPU jitter accumulation; clock-skew envelope.
  7. **Quantum-flavoured.** Where available — radioactive-
     decay sensors; quantum-tunneling diodes; vacuum-
     fluctuation sensors. (Most consumer hardware lacks
     these; PharOS-tier deployments may include them.)

  Cross-validation across families: at least two
  *uncorrelated* families must contribute, with correlation
  measured empirically over a calibration window during
  registration. Within-family multi-sensor cross-validation
  is *not* sufficient — heater-correlated thermal + battery
  is one family, not two.

  **Calibration-window correlation test.** During the
  LL-011 registration ceremony, the cross-correlation matrix
  across all sensor pairs must be computed; pairs with
  correlation magnitude exceeding a calibration threshold
  (operationally `|ρ| > 0.3` over a 60-second window) are
  flagged as same-family and counted as one entropy source
  for cross-validation purposes.
- Evidence type: manual
- Status: :argued
- Source: docs/synthesis_team_round3_companion.md §1C.A2
  (ChatGPT round-3 edge-witness seat) +
  docs/attack_surface_enumeration.md §3 V-018.
- Notes: LL-029 is **Operational**: it specifies a sensor-
  architecture requirement that operates at deployment-time
  during registration and at runtime during cross-validation.
  Depends on LL-016 (sensor-authenticity, the entry it
  refines) and LL-024 (real-sensor-deployment-strategy, the
  entry that hosts the sensor-architecture decisions in
  practice).

  **`:tested` upgrade path.** P-RS Level 2 sensor architecture
  must enumerate the physical-mechanism families each
  prototype platform supports + implement the calibration-
  window correlation test in the registration flow.
  Deferred — engineering work, sequenced by P-RS Level 2
  prototype availability per round-3 §1D.viii.

  **Within-family correlation is NOT a defence.** A common
  early implementation mistake is to add *more sensors of the
  same family* (e.g. four thermal sensors instead of one) and
  conclude that diversity is achieved. The V-018 attack
  defeats this — coupling the heat-injection mechanism still
  produces correlated readings across all four thermal
  sensors. LL-029 is explicit that *family count*, not
  *sensor count*, is the load-bearing quantity.
- **Round-3 origin:** ChatGPT §1C.A2 surfaced this as a
  sensor-fusion-inversion attack class: *"the cross-validation
  model assumes independent noise sources, but a determined
  adversary can couple channels physically. This is a classic
  sensor-fusion-inversion attack: attacker injects signals
  that satisfy constraints rather than violate them."*
  Defends V-018. Logic tier Operational because it operates
  at the sensor-architecture / registration-time / runtime
  layer rather than the spec-statement-of-claim layer.
  Depends on LL-016 (sensor-authenticity), LL-024 (P-RS
  deployment-strategy); compounds with V-006 (sensor-input
  poisoning) by raising the adversary capability required to
  defeat cross-validation.

---

## Counts (must match `artifact_registry.md` and `dashboard.md`)

- Total: 29 (was 27; +LL-028 + LL-029 from 0.0.50 round-3 Tier 3
  spec landing)
- `:proved`: 1 (LL-021 — first-ever LavaLamp `:proved` entry;
  Lean 4 + Mathlib v4.29.1; promoted at 0.0.48)
- `:tested`: 3 (LL-002, LL-004, LL-007)
- `:verified`: 0
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-027)
- `:argued`: 20 (LL-001, LL-005, LL-008, LL-009,
  LL-010, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017,
  LL-018, LL-020, LL-022, LL-023, LL-024, LL-025, LL-026,
  LL-028, LL-029)
- `:open`: 1 (LL-015 — A3-OOS scoping declaration; permanent
  by design)

**Prototype-stage; spec fully evidenced through round-3
Tier 2. Five empirically-validated :benchmarked entries
(LL-003 SDE choice via comparative bench, LL-006 detection
bound, LL-019 timing-indistinguishability, LL-021 worst-case
bound — with round-3 finite-N scope-limit + adaptive-
adversary amendment, LL-027 asymptotic Lyapunov density
invariant — paper-§10.1-10.2-aligned linear extensive-chaos
density `s ≈ 0.255`); three :tested entries (LL-002 visual
↔ security decoupling via the visual layer + decoupling-
assertion testset added in 0.0.33; LL-004 sensor coupling;
LL-007 chaos-guard); eighteen :argued at design level
(LL-025 A7-passive-emanation-boundary parallel boundary
triple with LL-015 / LL-024; LL-026 three-layer-logic-tier-
annotation-discipline paper-§1.2 governance; LL-014 gains
round-3 numerical-threshold non-fundamentality tie); only
LL-015 remains :open as the honest scoping declaration that
A3 (kernel-level) adversaries are out of scope.**
