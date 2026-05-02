# Architecture Design Pass — LavaLamp (P2 Companion)

Version: 0.0.5 (P2 architectural design pass, 2026-05-02)

Permanent record of the P2 architectural design pass. Closes the
five sub-items pinned in `dashboard.md` P2: Lyapunov-spectrum
residue audit, resolution-bounded security claim, chaos-guard,
sensor-coupling potential field, and the protocol layer
(registration / cold-start / cross-config / no-oracle).

This companion is design work, not implementation. The evidence
type produced is `manual`; spec entries that this companion
closes move from `:open` (`none`) to `:argued` (`manual`) per
the CLAUDE.md evidence-taxonomy rule. Entries that remain open
(no design closes them yet) stay at `:open`. Entries promoted to
`:proved` await Lean verification under P6 and are not the subject
of this companion.

P2 closure unblocks P3 (Julia prototype core). P3 is gated on the
architectural questions surfaced by attack-surface enumeration
(V-001..V-010) being closed or documented as intentional `:open`.
This companion closes the design questions; the *implementation*
questions (concrete numerical thresholds, sample-rate selection,
estimator choice) flow into P3.

---

## §1 — Computational basis

No code. Pure design synthesis from existing artefacts plus
formal restatement.

**Inputs.**

- `LAVALAMP_SPEC.md` v0.0.4 — 17 spec entries (LL-001..LL-017),
  all `:open` at session start.
- `docs/attack_surface_enumeration.md` — formal threat tree:
  six adversary classes (A1..A6, A3 out of scope), ten attack
  vectors (V-001..V-010), residual-risk enumeration.
- `docs/synthesis_team_round1_companion.md` — round-1 dialogue
  arc; the architectural moves locked here are the inputs the
  design pass formalises.
- `docs/qkd_pqc_complementarity_companion.md` — positioning
  framing: LavaLamp is resolution-bounded computational, not QKD;
  defensive-postured (detection, not prevention); inherits the
  C-conjugate adversary structurally from the Closure v5
  cross-sector autopoiesis result (0/5202).
- `docs/concept_origin_companion.md` — provenance.
- `docs/language_plan_catlab_tier_companion.md` — the five-tier
  formal stack and the LavaLamp-specific decision rule on Catlab.

**Corpus references** (Closure v5, paths under
`Research Papers/Relational_Closure_and_Emergent Gauge_Structure/Closure v5/`):

- `catlab_spec.jl` line 1855 — `Thm_Q51_autopoietic`: "Q₅₁ =
  Q(K₆³) is autopoietic… cross-sector autopoiesis fails 0/5202
  (cross_sector_autopoiesis_v1.py, 5 ICs)".
- `catlab_spec.jl` line 2415 — `Thm_Q102_structure`:
  "Cross-sector autopoiesis fails (0/5202 orig×conj compositions
  match, 5 ICs): the coproduct structure (S153) is a structural
  necessity."
- `cross_sector_autopoiesis_v1.py` — test infrastructure:
  `test_cross_sector(Q, label, threshold=0.999)`. Pairwise
  hyperedge composition test; tested on Q₄₈ and Q₁₀₂.

These references are the structural prior that LavaLamp's
adversary model (the C-conjugate at the entropy layer) inherits
from. The 0/5202 result is `:catlab` evidence — algebraic /
computational categorical proof — in the source corpus, not
hand-argued.

**No build commands** for this companion. The design pass is
prose + formal restatements; verification is `manual` per CLAUDE.md.

---

## §2 — Results

### §2.1 — Lyapunov-spectrum residue audit (LL-006)

The residue audit is the L7-equivalent compositional-identity
check in the Possibilistic Security obstruction stack: it tests
whether the candidate trajectory closes on the registered
substrate envelope, where the closure structure is the Lyapunov
spectrum (a Q₅₁-tier invariant per the §2.6 of the QKD/PQC
companion — the spectrum is the autopoietic-tier invariant; the
checkpoint-by-checkpoint trace is Q₁₀₂-tier and varies without
breaking identity).

**Definitions.**

Let M = (X, Φ, μ) be the device's substrate-coupled SDE on state
space X ⊂ ℝⁿ with flow Φ_t (driven by the Wiener increment dW
plus the external potential field of §2.4) and invariant measure
μ. The dynamics are ergodic on the support of μ (LL-010 boundary
guarantees finite-window static analysis only — ergodicity is
assumed within the bounded window, not over open-ended time).

By the Oseledec multiplicative ergodic theorem, μ-a.e. there
exists a Lyapunov spectrum λ(M) = (λ₁, ..., λₙ), real-valued,
ordered λ₁ ≥ λ₂ ≥ ... ≥ λₙ. The spectrum is an invariant of the
dynamics — it does not depend on the choice of trajectory in the
support of μ. This is the structural fact that makes
spectrum-as-identity work: the registered envelope and a live
trajectory of the same device share the same spectrum even though
they are different sample paths.

The Kolmogorov-Sinai entropy rate of M is, by Pesin's formula on
the ergodic component, h_KS(M) = Σ_i max(λᵢ, 0). This is the
*chaos-production rate* S_production cited in LL-008; the
identification is made precise in §2.2.

Let M̂ be a candidate trajectory submitted for verification, with
estimated spectrum λ̂ = (λ̂₁, ..., λ̂_k) over observation window T,
where k ≤ n is the number of exponents resolvable at the chosen
window and integration step (Wolf / Benettin / Rosenstein
algorithms; estimator selection in §2.3).

**Test definition.**

The residue test is a vector test, not a scalar threshold:

```
R(M̂; M_registered) accepts iff
    for every i ∈ {1, ..., k}:  |λ̂ᵢ - λᵢ_registered| < τᵢ
```

The threshold vector τ = (τ₁, ..., τ_k) is calibrated per-exponent
under the LL-014 calibration discipline. A scalar threshold (sum
of squared residuals below a single value) is the round-1
formulation; it is *rejected* in this design pass for the
slow-drift reason in V-005: an adversary can drift one exponent
positive and another negative while keeping the scalar sum below
threshold, which is structurally impossible to detect with a
scalar test but trivial with a vector test.

Optional cumulative-divergence audit on top of the per-snapshot
test: integrate ‖λ̂(t) - λ_registered‖_∞ over a sliding window.
This catches slow drift even when individual snapshots stay
within τ. The cumulative test is parameter-light (just the window
length and the cumulative threshold) and is recommended for
production but not load-bearing for the security claim — the
per-snapshot vector test suffices for the formal bound below.

**Probabilistic detection bound.**

The detection capability rests on three structural facts:

1. **Spectrum invariance.** λ depends on the dynamics, not the
   initial condition. An adversary who matches initial conditions
   and replays sensor inputs but does not match the substrate-
   coupled dynamics produces a different spectrum.

2. **Estimator concentration.** For the largest exponent λ₁,
   under standard mixing assumptions (Pesin, Eckmann-Ruelle):
   Var(λ̂₁) ~ C/T for constant C depending on the dynamics and
   estimator. Higher exponents converge slower but at known rates;
   k (number of resolvable exponents) grows with T.

3. **Structural-separation prior.** The Closure v5 cross-sector
   autopoiesis test (0/5202 across 5 ICs at threshold 0.999) is
   the corpus precedent for the kind of structural separation the
   audit relies on: structurally-similar-but-distinct compositional
   systems fail to close. LavaLamp's C-conjugate adversary is the
   classical-dynamics analogue: an adversary running the same SDE
   family coupled to a different substrate is structurally
   analogous to a cross-sector C-conjugate copy, and the residue
   test inherits the same structural-separation prior.

**Theorem (manually argued; Lean-tractable target for P6).**

Let A be an adversary with substrate-measurement precision ε_A.
Let δ_A = ‖λ_A - λ_genuine‖_∞ be the worst-case spectrum gap
induced by ε_A — i.e., the minimum over A's strategies of the
∞-norm gap between A's reproducible spectrum and the genuine
spectrum. The mapping ε_A ↦ δ_A is determined by the
sensor-coupling potential field (§2.4) and the SDE's parameter
sensitivity; for non-degenerate substrate coupling, δ_A > 0
whenever ε_A > 0 (see §2.4 for non-degeneracy conditions).

Then for observation window T:

```
P(detect | adversary submits) ≥ 1 - K · exp(-c · T · δ_A²)
```

where c > 0 depends on the SDE, integration step, and estimator
variance; K is a small constant covering tail-probability
constants. As T → ∞, P(detect) → 1 for any δ_A > 0.

**Honest content of the bound.**

- *Resolution-bounded.* If ε_A → 0 (adversary with arbitrary
  measurement precision), δ_A → 0 and the bound becomes vacuous.
  This is the resolution-boundary claim made precise: LavaLamp is
  not unconditional.
- *Asymptotically certain at fixed margin.* For any *fixed*
  ε_A > 0 (any adversary whose measurement is bounded), detection
  is certain in the long-window limit. This is the security claim's
  positive content.
- *Exponential rate.* Detection probability rises exponentially
  in T — fast in practice for δ_A in the range where typical A4
  adversaries sit (rough estimate from the round-1E edge-witness
  analysis: 5–10% spectrum gap on the first 2–3 exponents).
- *Quadratic in margin.* Detection rate scales as δ_A². Halving
  the adversary's margin quadruples the required observation
  window for the same detection probability. This is the
  load-bearing dependence under sensor-authenticity attacks
  (V-006), where the adversary works hard to compress δ_A.

**Defenses traced.**

- **V-001 (good-enough trajectory).** Closed structurally. A
  trajectory matching scalar-distance metrics cannot
  simultaneously match per-exponent rates across the spectrum.
- **V-005 (slow-drift threshold gaming).** Closed by vector
  thresholding. Optional cumulative test hardens further.
- **V-009 (cross-config transition).** Partially defeated. The
  per-config registered envelope (§2.5) and the no-oracle
  verification protocol (LL-017) close the rest.
- **V-006 (sensor-input poisoning).** *Not closed by LL-006
  alone.* The audit detects spectrum divergence; sensor
  authenticity is the residual risk. LL-016 strategies (§2.4)
  mitigate; the audit is a post-coupling check, not a
  pre-coupling check.

**Open implementation work** (flows to P3 Julia prototype):

- Estimator choice (Wolf vs Benettin vs Rosenstein vs newer
  Eckmann-Kamphorst-Ruelle). Trade-offs: Wolf is simplest and
  reliable for λ₁; Benettin generalizes to full spectrum but is
  computationally heavier; Rosenstein is robust to short trajectories
  but biased high. Selection benchmarked under P3.
- Concrete τᵢ values. Calibrated against estimator variance at
  the chosen window length; baseline is τᵢ = 3·σ(λ̂ᵢ | T) for
  ~99% genuine-device acceptance, then tuned.
- Cumulative-test window length. Heuristic: 5–10× the spectrum
  estimator's autocorrelation time. P3 calibration.

### §2.2 — Resolution-bounded security claim (LL-008; new LL-018)

The §2.1 audit gives a detection probability bounded in
adversary precision. §2.2 is the converse: a formal statement of
the security claim itself, in the form a Lean theorem can
target, with explicit per-adversary-class quantification.

**The S_production > S_measurement claim, restated.**

Let h_KS = Σᵢ max(λᵢ, 0) be the device's Kolmogorov-Sinai
entropy rate (= chaos-production rate per Pesin's formula on the
ergodic component). Let h_meas be the rate at which adversary A
can absorb information about the device's substrate state from
measurements available to A. The resolution-bounded security
claim is:

```
S_production = h_KS(M)        > S_measurement = h_meas(A; M)
```

When this holds with margin Δh = h_KS - h_meas > 0, the formal
consequence is:

```
H(state(M, t+Δt) | observations(A, [0, t]))  ≥  Δh · Δt - O(1)
```

i.e., A's residual uncertainty about the device's near-future
state grows linearly in the time window at slope Δh, *minus* a
constant absorbing initial-information leakage. This is the
information-theoretic content of the claim — adversary cannot
reduce the next-window uncertainty below Δh · Δt regardless of
compute.

The link to §2.1: residual uncertainty of magnitude Δh · Δt
translates to a spectrum gap δ_A bounded below by a function of
Δh, Δt, and the SDE's parameter-to-spectrum sensitivity. The two
claims are dual statements of the same structural fact.

**Per-adversary-class quantification (new spec entry LL-018).**

The single-line claim "S_production > S_measurement" hides
critical per-class structure. Different adversaries have radically
different h_meas; LL-008 is silent on which classes the claim
covers. This creates a "claim shrinks under reading" failure
mode where readers project the unconditional bound and the per-
class margin is never made precise.

LL-018 (proposed): formal statement of the security bound across
adversary classes A1..A6.

| Class | h_meas | Margin Δh | Comment |
|---|---|---|---|
| **A1 — Remote software** | ≈ 0 | h_KS | Adversary observes nothing about the substrate; the bound holds with arbitrary margin. |
| **A2 — Local unprivileged** | bounded by user-space-observable timing / API resolution; ~10⁻⁶ s precision typical | h_KS - O(10⁶ Hz) | Substrate physical-noise frequencies exceed user-space-observable timing by 3+ orders of magnitude on typical hardware. Margin holds with several orders of comfort. |
| **A3 — Kernel-level** | → h_KS (root sees everything) | → 0 | **Out of scope (LL-015).** Bound does not hold; we do not claim it. |
| **A4 — Side-channel / physical proximity** | depends on attack equipment, substrate noise bandwidth, sampling rate | Sensor-dependent | The load-bearing class. Bound holds when adversary measurement bandwidth is sub-Nyquist relative to substrate (LL-005). For broadband-noise sensors (thermal, scheduler), margin holds; for narrow-band sensors (USB plug events), the security contribution is *configuration-discreteness*, not h_meas margin (V-004 in attack-surface). LL-016 sensor authenticity is the load-bearing assumption. |
| **A5 — Registration-time** | ≤ envelope-information leakage during ceremony | N/A | The claim does not address A5 directly — A5 is a trust-root problem. LL-011 protocol design (§2.5) is the response; LL-008 only holds *given* a non-compromised registration. |
| **A6 — Time-localized** | bounded by single-window observation duration | ~h_KS · T_window | A6 sees one window; under §2.5's cold-start handling, this window is post-warmup and does not include initial-condition leakage. |

**Honest framings (load-bearing).**

- *Not information-theoretic in QKD's sense.* The bound is
  classical-resolution-bounded; it holds against adversaries with
  bounded measurement bandwidth, not against arbitrary
  computation. The adversary's classical compute may match the
  SDE solver; what cannot match is the substrate measurement.
- *Not a no-cloning theorem.* No-cloning depends on QM linearity.
  LavaLamp's classical chaotic SDEs are non-linear and the state
  is observable without collapse. Using "no-cloning" in formal
  claims is wrong (Round 1B; reaffirmed in CLAUDE.md "Honest
  tier framing").
- *A4 is the meaningful class.* A1 is trivially defeated; A2 has
  comfortable margin on typical hardware; A3 is OOS; A5/A6 are
  protocol-layer concerns. The honest claim's hard part is A4 with
  good attack equipment, where the bound depends on the
  substrate noise bandwidth being broadband enough and the
  Nyquist condition (LL-005) being satisfied. This is where
  LL-016 sensor authenticity matters most.
- *Per-deployment threat model.* High-assurance deployments need
  to specify which A4 capability level they assume — coffee-shop
  attacker (low equipment) vs nation-state (high equipment). The
  bound is *parametric* on this; it is not a single number.

**Lean theorem shape (target for P6).**

Approximate statement:

```lean
theorem detection_complete
  (M : SDE) (A : Adversary)
  (δ : ℝ) (h_δ : δ > 0)
  (h_gap : adversary_spectrum_gap A M ≥ δ)
  (T : ℝ) (h_T : T > 0)
  (η : ℝ) (h_η : η > 0)
  : T ≥ T_required δ η →
    detect_probability M A T ≥ 1 - η :=
  sorry
```

The target is to prove the §2.1 bound as a theorem with explicit
T_required(δ, η) = log(K/η) / (c · δ²) and explicit c, K
parameters. P6 work; not closed in this companion.

**Recommended new spec entry: LL-018.**

Status: `:argued` (manual). Evidence: this companion §2.2 +
attack-surface §2 + qkd_pqc companion §2.1.

### §2.3 — Chaos-Guard specifics (LL-007)

LL-007 turns periodic-window failure into a safety signal: a
real-time estimator of λ_max running concurrently with the SDE;
if λ_max ≈ 0, reject entropy and reseed. This subsection
specifies the estimator, the rejection criterion, and the reseed
protocol.

**Estimator choice.**

Rosenstein's algorithm (Phys. D 1993) is the recommended default:

- Computes λ₁ from a single trajectory's average exponential
  divergence rate of nearest neighbours in delay-coordinate
  embedding space.
- Robust to short data (works with O(10³) samples once embedded).
- Bias-aware variant available if production needs tighter bounds.
- Available in Julia's `ChaosTools.jl` as
  `ChaosTools.lyapunov_from_data` (Rosenstein) or
  `ChaosTools.lyapunov` (Benettin).

Wolf's algorithm is the simpler alternative; preferred when the
SDE is integrated explicitly and the variational equation is
available (we can compute λ₁ directly from the integrator state).

**Recommendation: Benettin** for the chaos-guard, Rosenstein
or Wolf for the residue audit. Benettin gives clean per-exponent
estimates online; the chaos-guard only needs λ₁ but Benettin has
no-extra-cost robustness for slightly-non-stationary regimes (the
device's coupling means the system is technically non-autonomous,
which Wolf assumes is autonomous).

**Window and sampling.**

The estimator runs over a sliding window W. Trade-off: short W
→ fast detection of periodic-window onset, but more variance;
long W → more precise λ̂₁ but slower detection.

Recommended starting point:

- W = 100 / λ₁_expected — i.e., 100 Lyapunov times. For a
  Lorenz-96 system at the candidate parameters (N = 40, F = 8),
  λ₁ ≈ 1.7 → W ≈ 60 seconds at the chosen integration step.
- Sliding-window stride = W / 10. Update λ̂₁ every 6 seconds.
- Rejection threshold: λ̂₁ < τ_λ where τ_λ ≈ 0.1 · λ₁_expected.
  A factor-of-10 collapse from expected is a safe periodic-window
  signature.

These are starting points; P3 prototype calibrates against
recorded periodic-window incidents.

**Reseed protocol when λ̂₁ < τ_λ.**

1. Mark the entropy stream `INVALID` from the moment λ̂₁ crossed
   τ_λ. Downstream consumers must discard entropy emitted during
   the rejected window.
2. Inject a high-entropy reseed: pull from the host TRNG
   (`/dev/urandom`, `getrandom(2)`, `RDRAND`) and perturb the SDE
   state by a vector of magnitude comparable to the attractor
   diameter. The reseed must be enough to escape the periodic
   window's basin of attraction.
3. Run a *warmup period* before re-marking entropy `VALID`.
   Warmup duration: 2W (twice the chaos-guard window). During
   warmup, λ̂₁ must climb back above 5·τ_λ continuously for at
   least W. This prevents flapping between periodic and chaotic
   regimes.
4. Log the reseed event with timestamp, λ̂₁ trace, and reseed
   entropy source. Periodic-window incidents are *signal*, not
   noise — they may indicate either substrate fluctuation or
   adversary-induced parameter drift; the log allows post-hoc
   analysis.

**Interaction with LL-002 (visual decoupling).**

The chaos-guard runs entirely within the security primitive. The
visual skin is unaffected by reseed events; decoupling means the
visual continues animating from its independent RNG even when the
security primitive is in warmup. This is correct — the visual
must not signal the security state to the user (or to a remote
observer who could infer the security state from a visual freeze).

**Defenses traced.**

- **V-005 (slow-drift threshold gaming).** Chaos-guard catches
  the case where the adversary's drift accidentally pushes the
  forged trajectory into a periodic window. Composition: the
  residue audit catches the spectrum-divergence; chaos-guard
  catches the special case of stalling.
- **V-008 (cold-start window).** Chaos-guard's warmup logic is
  the input to LL-012's protocol design (§2.5).
- **V-001 (good-enough trajectory).** A forged trajectory in a
  periodic window — the most common "lazy" adversary attempt —
  fails chaos-guard immediately, before the residue audit
  matters.

**Open implementation work** (flows to P3):

- Concrete λ₁_expected for the chosen SDE / parameters. Lorenz-96
  at N = 40, F = 8: λ₁ ≈ 1.7 (literature). Other candidates
  (Lorenz-63: λ₁ ≈ 0.91; Rössler: λ₁ ≈ 0.07) have different time
  scales.
- Reseed-magnitude calibration. Too small: stays in periodic
  basin. Too large: leaves the strange attractor entirely.
  Heuristic: reseed magnitude ≈ 1× attractor diameter; tune in P3.
- Warmup-duration tuning under realistic noise.

### §2.4 — Sensor-coupling potential field (LL-004 / LL-005 / LL-016)

This is the most operationally-detailed subsection. The
sensor-coupling design has three coupled spec entries: continuous
coupling via potential field (LL-004); Nyquist condition vs
physical noise bandwidth (LL-005); and sensor authenticity
requirement (LL-016) — the largest residual risk.

**Sensor catalogue.**

A typical laptop / desktop / phone exposes the following sensors
relevant to substrate-bound identity:

| Sensor | Class | Bandwidth (typical) | Coupling role |
|---|---|---|---|
| **CPU temperature (per core)** | High-bandwidth noise | 1–10 Hz reportable; 10⁶–10⁹ Hz physical | Drives broadband potential perturbation |
| **CPU governor / frequency** | High-bandwidth noise | 100 Hz reportable; 10⁶ Hz scheduler-event physical | Drives parameter drift |
| **Scheduler timing jitter** | High-bandwidth noise | 10⁹ Hz physical (rdtsc resolution) | Highest-bandwidth source; load-bearing for A2/A4 margin |
| **Battery state-of-charge** | Discrete + slow drift | 1 Hz | Configuration discreteness + slow drift |
| **Battery instantaneous current** | Slow drift | 1 Hz | Slow drift |
| **AC adapter status** | Discrete (binary) | Event-driven (~100 ms latency) | Configuration discreteness |
| **USB device list** | Discrete (set) | Event-driven (~1 ms latency) | Configuration discreteness |
| **Ambient light (laptops)** | Slow drift | 10 Hz | Slow drift |
| **Accelerometer (phones)** | High-bandwidth noise | 100 Hz reportable; 10³ Hz physical | Broadband noise |
| **Microphone** | High-bandwidth noise | 44 100 Hz | High-bandwidth, but privacy-sensitive — **only with explicit user consent** |
| **WiFi RSSI** | Slow drift + event | 1 Hz | Environmental fingerprint |

Two distinct security contributions:

1. **High-bandwidth noise sensors** (thermal, governor, scheduler
   jitter, accelerometer) contribute to h_meas margin (§2.2):
   their physical noise bandwidth exceeds A2/A4-typical
   measurement bandwidth, so they widen Δh.

2. **Discrete-state configuration sensors** (USB, AC adapter,
   battery state) contribute *configuration-discreteness*: the
   genuine device's trajectory shifts to a different region of the
   attractor when configuration changes. This is not a margin
   contribution but an *envelope-multiplicity* contribution — the
   verifier compares against per-config envelopes (§2.5 LL-013).

**Continuous coupling via potential field (LL-004 formalisation).**

Discrete sensor reads must *not* enter the SDE as step-function
parameter kicks. Reasons (rejected at round 1):

- Step kicks create numerical artefacts (transients) at the
  integration timestep, detectable by side-channel observation.
- The trajectory's response to a step has a deterministic shape
  (resolvent kernel of the integrator), giving an adversary a
  "shape" to spoof.
- Multiple step kicks at integration-timestep granularity can
  align coherently, creating a low-bandwidth signal embedded in
  the SDE that an adversary's slow sampling can capture.

Instead, sensor reads are smoothed to a continuous external
potential field U(s, t) that pulls the SDE state toward
configuration-specific regions. Formal definition:

```
dx = f(x) dt + σ dW + ∇U(s(t), x; t) dt
```

where f(x) is the unperturbed SDE drift (e.g., Lorenz-96 vector
field), σ dW is the Wiener increment with σ scaling thermal/
scheduler-noise input, and ∇U(s(t), x; t) is the
sensor-induced potential gradient.

The potential U is designed to:

- Have separated minima for distinct discrete configurations
  (USB-plugged vs unplugged minimum at distinguishable regions of
  the attractor). The gap between minima is calibrated so the
  trajectory equilibrates to a new minimum within τ_config
  seconds after a configuration change.
- Be *smooth* in the discrete-sensor inputs: a USB plug event
  triggers a Gaussian ramp in U, not a step. Ramp time ~10 ms is
  sufficient to suppress transients while remaining well below
  human-perceptible reaction time.
- Have a *broadband* contribution from high-bandwidth noise
  sensors: U includes a term σ_thermal · ξ_thermal(t) · h_thermal(x)
  where ξ_thermal is the (smoothed) thermal sensor reading and
  h_thermal(x) is a state-dependent coupling shape. This term
  injects continuous broadband noise into the dynamics.

The ramp-smoothing function (Gaussian or sigmoidal) is the
LL-004 implementation; specific shape is P3 work.

**Nyquist condition (LL-005 formalisation).**

The Nyquist requirement applies *per sensor*:

- For high-bandwidth noise sensors: f_sensor > BW_physical, where
  BW_physical is the physical noise bandwidth. Thermal noise
  bandwidth is ~kT/h ≈ 6 × 10¹² Hz at room temperature in
  principle, but the *useful* bandwidth (where the noise is
  uncorrelated with adversary-observable signals) is bounded by
  the sensor electronics — typically 10³–10⁶ Hz for thermal
  sensors. *Use the sensor's own electronic bandwidth as
  BW_physical*, not the abstract physical bandwidth.
- For discrete-state sensors: Nyquist is automatically satisfied
  if f_sensor ≥ event-arrival rate. USB plug events ≪ 1 Hz on
  typical workloads; sub-Hz sampling suffices.

The integration step f_SDE must satisfy f_SDE > 2 · max(BW_used)
across sensors contributing high-bandwidth content. For Lorenz-96
at λ₁ ≈ 1.7 and the typical numerical-stability constraint f_SDE
~ 100 · λ₁ ≈ 170 Hz, the integration step is ~6 ms. To bring
high-bandwidth thermal-sensor noise into the dynamics, integrate
at ~10⁴ Hz (Δt ≈ 100 µs) — well above Lorenz-96's stability floor
and within typical scheduler resolution.

**Recommendation:** integrate at f_SDE ≈ 10 kHz; sample
high-bandwidth sensors at 10× this rate (100 kHz where the sensor
electronics support it; otherwise fall back to the sensor's own
limit and document the reduced security contribution).

**Non-degeneracy of substrate coupling.**

For the §2.1 detection bound to hold (δ_A > 0 whenever ε_A > 0),
the sensor coupling must be *non-degenerate*: small changes in
sensor reads produce non-zero changes in the Lyapunov spectrum.
Formal condition: the Jacobian ∂λ/∂s of the spectrum with respect
to the sensor reading vector s has full rank in the relevant
neighbourhood.

This is a property of the SDE + potential design. For
single-attractor SDEs (Lorenz, Lorenz-96, Rössler) with
parameter-coupled potential fields, non-degeneracy is generically
true but should be verified numerically for the chosen
configuration. P3 includes a non-degeneracy benchmark before any
security claim is made.

**Sensor authenticity (LL-016) — the load-bearing residual risk.**

LL-016 makes explicit what V-006 calls out: a sensor read
participating in U(s) must satisfy an independent authenticity
check, because hardware sensors can be manipulated at the source
(hairdryer drives thermal up; flashed USB device announces
without attaching; charge controller spoofs AC status). Without
authenticity, an A4 adversary with physical proximity drives the
genuine device's trajectory toward a chosen output —
"spoofing without replication" — and the residue audit cannot
distinguish a genuine-but-manipulated trajectory from a genuine
one. This is the largest residual risk in the architecture.

**Authenticity strategies (in decreasing strength, in increasing
deployability):**

1. **Hardware attestation.** TPM / Secure Enclave signs sensor
   reads. The signature is verified before the read enters U(s).
   *Strongest.* Requires hardware support and OS plumbing.
2. **Multi-sensor cross-validation.** Reads from physically-
   coupled sensors must correlate. Examples:
   - Thermal reading + battery discharge rate (discharge rate
     correlates with thermal load on a physical battery; spoofing
     thermal but not discharge-rate spoofs only one side).
   - AC adapter status + measured current draw via ACPI
     (legitimate AC adapter draws power; a spoofed
     "AC-on" status from a flashed charger that doesn't actually
     deliver power fails the cross-check).
   - Microphone + accelerometer (acoustic events should
     correlate with physical vibration).
   *Medium-strong.* Defeats one-sided sensor poisoning. Vulnerable
   to coordinated multi-sensor poisoning if the adversary can
   manipulate multiple sensors coherently.
3. **Anomaly-based sensor flagging.** Sensor reads outside
   plausible joint-distribution envelopes are flagged separately
   from trajectory anomalies. A thermal reading climbing 30 °C in
   3 minutes without corresponding load increase is anomalous
   even if the absolute value is in-range. Flagged sensors
   *exclude themselves from U(s) participation* until anomaly
   resolves.
   *Medium.* Catches obvious manipulation; vulnerable to subtle
   attacks staying within plausible envelopes.
4. **Accepted residual risk + deployment context.** For
   deployment contexts where physical proximity is implicitly
   defended (corporate desktop in locked office; phone on
   person), accept that V-006 is partially undefended and
   document the deployment-context dependence in the threat
   model. *Weakest.* Honest scoping.

**Recommendation.** Default authenticity strategy is multi-sensor
cross-validation (#2) with anomaly-based flagging (#3) on top.
Hardware attestation (#1) is added when the deployment supports
it — TPM-attested sensors are strict superset of cross-validated
ones. Strategy #4 (accepted residual) is the fallback when no
others apply, with explicit deployment-context documentation
required.

The choice flows into LL-013 (cross-config transition handling,
§2.5) because cross-config inherits the V-006 risk: a "config
change" claim from a manipulated sensor reads as legitimate
unless authenticity gates the read.

**Defenses traced.**

- **V-003 (quantum-seed → classical-software boundary).**
  Defended by f_SDE high enough that side-channel observation at
  the integration step is below the substrate-noise bandwidth.
  10 kHz f_SDE is safe vs typical A2 side-channel; insufficient
  vs nation-state A4 with high-resolution probes — at that
  capability level, accept the bound is tight.
- **V-004 (sensor Nyquist failure).** Defended by per-sensor
  Nyquist analysis above. Discrete-state sensors are *not*
  Nyquist-violated even at 1 Hz; they contribute via configuration
  discreteness, not bandwidth.
- **V-006 (sensor-input poisoning).** Mitigated by LL-016
  authenticity strategies; not eliminated. Largest residual risk.
- **V-009 (cross-config transition spoofing).** Inherits V-006
  risk; LL-013 protocol design (§2.5) responds.

**Open implementation work** (flows to P3):

- SDE choice: Lorenz-96 leading; final choice benchmarked
  against Lyapunov-spectrum richness, parameter sensitivity,
  computational cost, and non-degeneracy.
- Potential-field shape U(s, t). Concrete functional form:
  U(s, t) = Σ_i α_i · ramp(s_i, t) · ⟨b_i, x⟩ where ramp is the
  smoothing function and b_i is a per-sensor coupling vector.
- Coupling-strength constants α_i. Calibrated so that the
  *typical*-configuration trajectory has Lyapunov spectrum
  matching a target signature (chosen for richness and
  estimator-friendliness).
- Authenticity-strategy implementation choice for the prototype.
  Default: cross-validation + anomaly-flagging.

### §2.5 — Protocol layer (LL-011 / LL-012 / LL-013 / LL-017)

The protocol layer is the four open structural questions from
0.0.1 plus the no-oracle requirement from 0.0.3. These are not
properties of the SDE itself but of the *deployment*: how a
verifier acquires the registered envelope, how a just-booted
device authenticates, how a configuration change is
distinguished from a spoofing attempt, and how the verification
response avoids leaking threshold geometry.

#### §2.5.1 — Registration ceremony (LL-011)

The trust root. An A5 attacker at registration defeats every
per-trajectory defense.

**Threat model in registration.** A5 has access to the device
during the ceremony, can substitute the registered envelope
with their chosen one, can observe the genuine envelope to
inform later attacks, or can manipulate sensors during registration
so the recorded envelope is non-genuine.

**Design candidates.**

A. **Multi-party registration.** *N* independent verifiers each
record the envelope; collusion of *t < N* required to substitute
or observe. Recorded envelopes are signed and committed to a
public log (Merkle tree); later verification consults the
committed envelope.

- *Strength:* defeats single-A5 attackers. Threshold scheme
  bounds collusion attack.
- *Cost:* requires *N* independent verifiers. Suitable for
  enterprise / federated deployments; overkill for consumer.

B. **TPM / Secure Enclave attestation.** The envelope is
recorded *signed* by a hardware root of trust the device's
software cannot impersonate. The verifier records the envelope
and the attestation chain; later verifications check both.

- *Strength:* defeats A5 software attackers; A5 hardware-tamper
  attackers still possible but moved down-stack.
- *Cost:* requires TPM / Secure Enclave + endorsement-key
  infrastructure. Mainstream-laptop-feasible.

C. **Time-bounded registration with re-registration.** Envelope
valid only for window ΔT_reg (e.g., 30 days); re-registration
required. Limits A5 persistence — an attacker who poisons the
ceremony has at most ΔT_reg before the device re-registers and
the poisoned envelope is replaced.

- *Strength:* limits A5 dwell time; combines well with A and B.
- *Cost:* re-registration UX burden; A5 can re-attack each
  re-registration window.

D. **Device-derived secret mixing.** The registered envelope
includes a hash of a device-only-knowable secret baked at
manufacture (factory key, TPM endorsement key, or similar). An
A5 who substitutes the envelope must also know the device secret;
hardware-rooted A5s can know it, but software-only A5s cannot.

- *Strength:* defeats software A5; hardware A5 still possible.
- *Cost:* requires factory-bake or TPM. Compatible with B.

**Recommendation.** Default protocol: B (TPM attestation) + D
(device-secret mixing) for hardware-rooted deployments; A
(multi-party) when no hardware root is available; C
(time-bounded) as a defense-in-depth layer that is always
worth adding.

For the LavaLamp paper, document protocol B+D as the canonical
high-assurance ceremony and A as the no-TPM fallback.

**LL-011 status after this design pass.** `:argued` — protocol
candidates analyzed; deployment-specific selection pending.
Concrete protocol implementation is P3+P4 work (Julia client +
Haskell verifier-side spec).

#### §2.5.2 — Cold-start window (LL-012)

A just-booted device has not run the SDE long enough for the
substrate-coupled envelope to express. During this warmup
window, verification reliability is degraded.

**Design.**

The verifier's interface must distinguish three states:

- **WARMUP** — device is booting / SDE has not converged. Verifier
  returns "WARMUP, retry in T_remaining seconds." T_remaining is
  reported by the device based on chaos-guard's λ̂₁ trace (§2.3
  warmup logic).
- **OPERATIONAL** — SDE has converged; verifier returns ACCEPT or
  REJECT.
- **DEGRADED** — SDE is in chaos-guard rejection (entropy
  invalid). Same as WARMUP from the verifier's perspective: "retry
  in T_remaining."

The state is reported by the device-side daemon and is itself
authenticated (signed by the device's identity key). An adversary
cannot spoof "WARMUP" indefinitely to evade authentication — a
device that is "perpetually warming up" is itself a flag.

**Cold-start envelope vs steady-state envelope.**

Two design options:

- **Single envelope, warmup unauthenticated.** The registered
  envelope is the steady-state envelope. During warmup, the
  device returns WARMUP and is not authenticated. Simple;
  appropriate when the use case can tolerate brief
  unauthenticated periods (consumer login).
- **Dual envelope.** Registration captures both a cold-start
  envelope and a steady-state envelope; verifier knows which to
  compare against based on device-reported state. Allows
  authentication during warmup; doubles registration burden.

**Recommendation.** Single envelope + WARMUP-state response is
the default. Dual envelope is justified only for high-availability
deployments where post-boot unauthenticated periods are
unacceptable.

**Boot-time integrity.** Cold-start logically extends to early-
boot integrity (cold-boot RAM attacks, controlled-USB-at-boot
state seeding). LL-012 does not solve early-boot integrity in
general; it solves the "is the SDE warmed up" question. Early-boot
integrity is an OS-level concern (Secure Boot, measured boot)
that LavaLamp inherits — LL-012 explicitly does not cover it,
which is honest scoping.

**LL-012 status.** `:argued` — protocol candidates analyzed;
single-envelope + WARMUP recommended.

#### §2.5.3 — Cross-config transition handling (LL-013)

When configuration changes (USB plug, AC adapter, sleep/wake),
the trajectory shifts to a different region of the attractor.
Verifier distinguishes legitimate config change from adversarial
spoofing.

**Inherited V-006 risk.** Sensor reads themselves are
manipulable; a "USB-plugged" claim from a manipulated sensor
reads as legitimate unless LL-016 authenticity gates the read.
LL-013 sits *on top of* LL-016: the protocol assumes
authentic sensor reads as input.

**Design: per-config registered envelopes (PRE).**

Registration captures envelopes for all expected configurations
(USB-A unplugged + AC unplugged; USB-A plugged + AC unplugged;
USB-A unplugged + AC plugged; etc.). The configuration space is
discrete, finite, small — typical laptop has O(10) common
configurations. Each gets a recorded envelope.

The verifier:

1. Receives the candidate trajectory + the device's reported
   configuration (signed via LL-016 authentication).
2. Selects the matching registered envelope.
3. Runs the residue test against that envelope.

**Transition handling.** When configuration changes, the device
enters a brief *transition window* (~τ_config seconds, the
equilibration time of the potential field's smoothing in §2.4).
During this window, the verifier returns "TRANSITIONING, retry in
τ_config" — same shape as the WARMUP response but driven by
configuration-change rather than boot.

**Adversary defeated.** An A4 adversary cannot claim "I'm now in
a configuration that matches my forged trajectory" because:

- The configuration-change claim must be sensor-authentic
  (LL-016).
- The trajectory must match the *registered envelope for that
  specific configuration*, not just *some* envelope.
- Cross-configuration substitution (claim "USB-plugged" while
  submitting USB-unplugged trajectory) fails the residue test
  immediately.

**Configurations not in the registered set** are rejected with
"UNKNOWN CONFIGURATION, register first." Re-registration is
required to add a new configuration. This is a usability cost
but a security necessity.

**Alternative: transition-pattern fingerprint.**

The *manner* in which a device transitions between configurations
— the timing, the coupling intensity, the attractor-flow during
the smoothing window — is itself substrate-coupled and harder to
spoof than steady-state envelopes. LL-013 could be hardened
further by registering transition fingerprints in addition to
endpoint envelopes.

This is more complex; defer to a follow-up. The PRE approach is
sufficient for round-1 production.

**LL-013 status.** `:argued` — PRE protocol recommended;
transition fingerprinting as future hardening.

#### §2.5.4 — Verification no-oracle requirement (LL-017)

The verification response must not expose accept/reject feedback
that lets an adversary probe the residue threshold via repeated
submissions. This closes V-010.

**Design.**

The verifier's response to a verification attempt is exactly one
of:

- ACCEPT
- REJECT
- WARMUP (retry in T_remaining)
- TRANSITIONING (retry in τ_config)
- UNKNOWN_CONFIGURATION

No additional information is returned. In particular: no
divergence value, no per-exponent residual, no distance-to-
threshold, no time-to-detection, no "you're getting warmer."

**Rate limiting.**

In addition to the no-oracle protocol, the verifier rate-limits
verification attempts per (device, source-IP, time-window) tuple:

- Soft limit: 10 attempts per minute per (device, source).
- Hard limit: 100 attempts per hour per device-identity, across
  all sources.

Rate-limit responses are themselves no-oracle: "RATE_LIMITED" and
nothing else. An adversary cannot use rate-limit timing to infer
threshold geometry.

**Adaptive thresholding (optional hardening).**

The threshold τ may be adaptive — learned from history of
genuine-device verifications. Adaptive τ is harder for the
adversary to predict because it changes; the cost is a more
complex calibration story.

Recommendation: fixed τ for round-1; adaptive τ as future
hardening once enough genuine-device traces are recorded to
calibrate.

**Logging.**

Verifier logs all verification attempts (device, timestamp,
result, configuration, residue values). The log is *internal*
to the verifier and never exposed to the requester. Logs feed
into the calibration discipline (LL-014) and into post-incident
forensics.

**LL-017 status.** `:argued` — no-oracle response set defined;
rate-limit policy specified; adaptive thresholding deferred.

#### §2.5.5 — Threshold calibration discipline (LL-014, partial)

LL-014 (calibration of the residue threshold τ) is partially
addressed by the design pass:

- §2.1 establishes that τ is *vector-valued* per exponent, not
  scalar.
- §2.5.4 establishes that the verification protocol must not
  leak threshold information.
- The starting heuristic τᵢ = 3·σ(λ̂ᵢ | T) — three sigma of the
  estimator variance at the chosen window — is reasonable for
  ~99% genuine-device acceptance.

What remains for LL-014 is *concrete numerical calibration*: this
is benchmarking work in P3, not design work in P2. LL-014
status moves to `:argued` for the *discipline* (vector + no-
oracle + rate-limit + adaptive-future); the *concrete τ values*
remain `:open` until P3 produces measurements.

---

## §3 — Verification

For each result in §2 destined for the spec, this section states
the evidence type and the substantive argument supporting the
claim.

### §3.1 — LL-006 Lyapunov-spectrum residue audit

- **Evidence type:** `manual` (will become `lean-proved` if the
  detection-probability theorem is verified in Lean under P6;
  P3-prototype benchmarking will move it to `:tested` /
  `:verified` first).
- **Manually argued.** Premises: spectrum invariance (Oseledec),
  estimator concentration (Pesin / Eckmann-Ruelle, standard
  results in dynamical systems), structural-separation prior
  (Closure v5 catlab_spec.jl `Thm_Q51_autopoietic` / `Thm_Q102_structure`,
  cross_sector_autopoiesis test 0/5202 at 0.999, 5 ICs —
  computational evidence at the corpus layer). Argument: vector
  per-exponent thresholding combined with these three premises
  yields the §2.1 detection-probability bound P(detect) ≥
  1 - K·exp(-c·T·δ²). Conclusion: detection probability rises
  exponentially in T at fixed adversary margin δ_A; bound is
  vacuous as δ_A → 0.
- **Status moves:** `:open` → `:argued`.

### §3.2 — LL-008 resolution-bounded security claim

- **Evidence type:** `manual`.
- **Manually argued.** Premises: Pesin's formula identifying h_KS
  with Σ max(λᵢ, 0) (standard); information-theoretic bound on
  reconstruction-from-bounded-bandwidth-observations (standard
  Shannon-rate result); §2.1 detection-probability bound. Argument:
  S_production > S_measurement implies residual uncertainty grows
  linearly in time at slope Δh, which translates to non-zero
  spectrum gap, which translates to detection by §2.1. The
  per-class quantification in §2.2 is honest scoping.
- **Status moves:** `:open` → `:argued`.

### §3.3 — LL-018 (new) per-class adversary quantification

- **Proposed entry**: explicit A1..A6 quantification of the
  resolution-boundary margin Δh.
- **Evidence type:** `manual`.
- **Manually argued.** Premises: attack-surface §2 adversary
  taxonomy; LL-008 bound. Argument: each class has a per-class
  h_meas; explicit quantification prevents readers from
  projecting an unconditional bound.
- **Status:** new entry, `:argued`.

### §3.4 — LL-007 chaos-guard

- **Evidence type:** `manual`.
- **Manually argued.** Premises: Rosenstein / Benettin estimators
  recover λ₁ in finite windows (literature); periodic-window
  collapse is detectable as λ̂₁ → 0 (definition); reseed restores
  chaotic regime under adequate magnitude (numerical-experiment-
  level fact, to be verified in P3). Argument: real-time λ̂₁
  estimate + reject-and-reseed protocol turns periodic-window
  failure into a safety signal. The decoupling from visual layer
  (LL-002) is preserved; reseed events are logged for post-hoc
  analysis.
- **Status moves:** `:open` → `:argued`.

### §3.5 — LL-004 continuous sensor coupling

- **Evidence type:** `manual`.
- **Manually argued.** Premises: step-kick parameter changes
  create numerical artefacts (numerical-analysis fact); smooth
  potential fields avoid these artefacts (standard); ramped
  smoothing functions equilibrate within τ_config (well-known for
  Gaussian / sigmoidal ramps). Argument: the SDE form
  dx = f(x) dt + σ dW + ∇U(s, x) dt with smooth U avoids
  V-002-style multi-basin pathologies (LL-002 closure)
  and V-003-style integration-step artefacts.
- **Status moves:** `:open` → `:argued`.

### §3.6 — LL-005 sensor Nyquist condition

- **Evidence type:** `manual`.
- **Manually argued.** Premises: Nyquist-Shannon sampling theorem
  (standard); per-sensor bandwidth analysis in §2.4. Argument:
  high-bandwidth noise sensors must satisfy f_sensor > BW_used >
  BW_adversary; discrete-state sensors trivially satisfy Nyquist
  at sub-Hz sampling; integration step f_SDE ~10 kHz suffices for
  typical thermal / scheduler / governor noise sensors.
- **Status moves:** `:open` → `:argued`.

### §3.7 — LL-016 sensor authenticity

- **Evidence type:** `manual`.
- **Manually argued.** Premises: V-006 attack (sensors can be
  manipulated at source); LL-016 strategies analysis (§2.4).
  Argument: the four authenticity strategies (TPM attestation /
  multi-sensor cross-validation / anomaly-flagging /
  accepted-residual) span the deployment space; default is
  cross-validation + anomaly-flagging with TPM as superset and
  accepted-residual as fallback. Residual risk under each
  strategy named.
- **Status moves:** `:open` → `:argued`.

### §3.8 — LL-011 / LL-012 / LL-013 / LL-014 / LL-017

Protocol-layer entries (§2.5).

- **Evidence type:** `manual` for all five.
- **Manually argued.** Premises: attack-surface §V-007 / V-008 /
  V-009 / V-010 + adversary-class taxonomy. Arguments:
  per-section in §2.5.
- **Status moves:** `:open` → `:argued` for all five.

### §3.9 — LL-001 / LL-002 / LL-003 / LL-009 / LL-010 / LL-015

These entries are the architectural *frame* — they were closed
substantively by round-1 / 0.0.3, not by this design pass. They
remain at their existing statuses (:open with manual evidence
where the qkd_pqc and round-1 companions argue them). This
companion does not re-litigate them.

---

## §4 — Spec impact

### §4.1 — Status moves (from `:open` → `:argued`)

This companion's design closes the following entries to `:argued`
(manual evidence):

- **LL-004** continuous sensor coupling
- **LL-005** sensor Nyquist condition
- **LL-006** Lyapunov-spectrum residue audit
- **LL-007** chaos-guard
- **LL-008** resolution-bounded security claim
- **LL-011** registration ceremony
- **LL-012** cold-start window
- **LL-013** cross-config transition handling
- **LL-014** threshold calibration discipline (vector + protocol;
  numerical calibration remains :open as P3 work)
- **LL-016** sensor authenticity requirement
- **LL-017** verification no-oracle requirement

### §4.2 — Entries staying `:open`

The following entries do not close to `:argued` in this pass:

- **LL-001** substrate-bound identity primitive — closed in
  spirit by the residue audit (§2.1) but the formal Lean
  statement awaits P6.
- **LL-002** visual ↔ security decoupling — invariant; honored
  by §2.3 (chaos-guard does not signal to visual) and §2.4
  (security primitive's f_SDE / sensor sampling does not couple
  to visual). Remains `:open` until a Lean / type-level
  enforcement closes it.
- **LL-003** single-attractor chaotic engine — choice of SDE
  (Lorenz-96 candidate) framed but not benchmarked. P3 work.
- **LL-009** no complex numbers — invariant honored; closure to
  `:argued` requires the §3 argument made formal in a corpus
  reference. Defer to a future small-session companion.
- **LL-010** no open-ended simulation — invariant honored. Same
  comment as LL-009.
- **LL-015** A3 out of scope — boundary, remains `:open` (it is
  a scoping declaration, not a claim with evidence to upgrade).

### §4.3 — New spec entry

**LL-018** — adversary-resolution-bound formalisation
(per-class A1..A6 quantification of LL-008's margin). Logic
tier: Core. Evidence type: `manual`. Status: `:argued`. Source:
this companion §2.2 + attack-surface §2.

### §4.4 — Updated counts

After this design pass:

- **Total entries:** 18 (was 17; +LL-018)
- **`:proved`:** 0 (unchanged)
- **`:verified`:** 0
- **`:tested`:** 0
- **`:benchmarked`:** 0
- **`:argued`:** 12 (LL-004, LL-005, LL-006, LL-007, LL-008,
  LL-011, LL-012, LL-013, LL-014, LL-016, LL-017, LL-018)
- **`:open`:** 6 (LL-001, LL-002, LL-003, LL-009, LL-010,
  LL-015)

The :argued count includes claims of varying strength: some
(LL-004, LL-005, LL-006, LL-007, LL-008, LL-018) are
substantive structural claims with full arguments;
others (LL-011..LL-014, LL-017) are protocol-layer claims
where the design space has been mapped and a default selected.
All are honestly `:argued`, not `:verified` or `:proved`.

### §4.5 — Files changed in this commit

- `docs/architecture_design_companion.md` (this file) — new.
- `LAVALAMP_SPEC.md` — 11 status transitions to `:argued`; new
  entry LL-018; counts updated.
- `artifact_registry.md` — 11 evidence-type and status updates;
  new row for LL-018; counts updated; A1 coverage 18/18.
- `dashboard.md` — P2 marked ✓ done; spec status updated;
  open structural questions reduced (LL-011..LL-017 closed at
  design level); P3 unblocked; live discipline notes kept (the
  decoupling watch and the no-complex-numbers / no-open-ended
  boundaries still in force).
- `changelog.md` — 0.0.5 entry top-of-file.

### §4.6 — Followups

- **P3 — Julia prototype core.** Unblocked by this companion.
  Entry points:
  - SDE selection benchmark (Lorenz-96 vs Lorenz-63 vs Rössler
    on dimension, Lyapunov richness, parameter sensitivity,
    compute cost).
  - Estimator implementation (Benettin for chaos-guard,
    Rosenstein/Wolf alternatives for the audit).
  - Sensor-coupling potential field — concrete U(s, x; t) form
    with parameterised α_i and ramp shape.
  - Non-degeneracy benchmark (∂λ/∂s rank).
  - Initial threshold calibration: τᵢ = 3σ(λ̂ᵢ | T) baseline.
  - LockfileDiscipline: Manifest.toml from day 1 (LavaLamp
    CLAUDE.md package management rule).
- **Round-2 synthesis-team review.** Trigger: after P2 closes
  (this commit). Forward this companion + attack-surface
  enumeration to Gemini (synthesis seat) and Grok (edge-witness
  seat); ask whether the design pass closes the round-1
  blindspots and whether new attack vectors are surfaced. The
  triggering condition described in attack-surface §7 is now
  met.
- **Catlab tier decision (P4).** Per
  `language_plan_catlab_tier_companion.md`, the decision rule for
  P4 was "default skip; revisit when registration ceremony /
  cross-config transition designs are concrete." They are now
  concrete (§2.5). The protocol-layer designs are *operational*
  rather than *categorical* — there is no functor / natural
  transformation / multicategory structure that obviously asks
  for Catlab over Haskell. **Recommendation:** still skip
  Catlab for LavaLamp; the protocol layer is plain old
  state-machine + cryptographic protocol, well-served by Haskell
  + Lean directly. Document the decision in
  `language_plan_catlab_tier_companion.md` follow-up.
- **LL-018 in Lean.** The per-class quantification is a
  parametric theorem; the Lean theorem in §2.2 is the natural
  formal object. P6 work.

---

## §5 — Process notes

- **One-task-per-conversation discipline.** This session is the
  P2 architectural design pass. No code, no positioning revision,
  no new attack vectors. The threat tree from 0.0.3 is treated
  as input.
- **Honest framing reaffirmed.** Every status move to `:argued`
  is `manual` evidence. None of these become `:proved` until
  Lean (P6) verifies the structural claims; none becomes
  `:verified` or `:tested` until P3 prototype benchmarks them.
  The CLAUDE.md "honest tier framing" boundary is held.
- **Decoupling watch is engaged.** §2.3 (chaos-guard) and §2.4
  (sensor coupling) explicitly preserve the LL-002 visual ↔
  security decoupling. Any future refactor that proposes
  re-coupling reopens V-002 (basin spoofing). The asymmetry-trap
  watch in `dashboard.md` covers this.
- **Corpus citations checked.** The Closure v5 grounding
  citations used in §2.1 (`Thm_Q51_autopoietic`, `Thm_Q102_structure`,
  `cross_sector_autopoiesis_v1.py`) were verified against
  `catlab_spec.jl` lines 1855, 1858, and 2415 directly during
  this session. The earlier `qkd_pqc_complementarity_companion.md`
  named the citations; this companion ties them to the precise
  corpus loci.
