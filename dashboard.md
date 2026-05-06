# Dashboard — LavaLamp

Last updated: 2026-05-06 (0.0.50 — synthesis-team round 3 Tier 3 spec landing; LL-028 runtime-conformance-verification added (Boundary, `:argued`; defends V-019); LL-029 multi-channel-entropy-independence added (Operational, `:argued`; defends V-018); LL-019 round-3 deployment-context expansion footer (regime-1 dev-host artifact + regime-2 multi-tenant real-channel + shared-environment deployment constraint); counts 27/1/3/0/4/18/1 → 29/1/3/0/4/20/1).

## Status summary

**Project state.** Prototype-stage; round-2 architectural
debt closed. P2 architectural design pass landed; P3
prototype core has Lorenz-96 baseline (LL-003 `:tested`),
sensor-coupling layer (LL-004 `:tested`), residue audit
(LL-006 `:tested`), chaos-guard (LL-007 `:tested`).
Synthesis-team round 2 (0.0.12) surfaced three new attack
vectors (V-011/012/013) and three new spec entries
(LL-019/020/021); the P-R2 design-response trio closed all
three within a single afternoon's work: LL-019 `:tested` in
0.0.14 (P-R2a side-channel hardening — `verify_full` +
`verify_constant_time`); LL-021 `:tested` in 0.0.15 (P-R2c
worst-case-adversary-bound — analytic derivation +
structured-adversary benchmark showing dramatic asymmetry);
LL-020 `:argued` in 0.0.16 (P-R2b calibration
confidentiality — three-strategy design with TPM-sealed
default). The 0.0.17–0.0.19 :benchmarked cohort closed
LL-006 / LL-019 / LL-021 to empirically-validated bounds;
0.0.23–0.0.25 added LL-020 Strategy 2 ε-DP envelope, the
P3-Nyq negative-result benchmark, and the P3d SDE-selection
benchmark (LL-003 → :benchmarked). 0.0.26 closed the
**P-OS OS-level scoping pass**, adding LL-022
(OS-trust-stack-dependency, Boundary, `:argued`) — the
positive enumeration of OS / firmware / hardware-root
mechanisms LavaLamp's claims depend on, paired with LL-015
(downward boundary, A3 OOS) to close the trust-stack
scoping question. **0.0.27** closes Strategy 2 of LL-020
to `:benchmarked`-tier evidence: the detection-power-vs-ε
benchmark exposed an implementation bug (symmetric Gaussian
noise on σ + floor → 100% FPR), the determinism re-check
attributed it cleanly to the implementation, the fix
(variance-convolution `σ_pub = sqrt(env.σ²+σ_DP²)`) lands,
and the post-fix benchmark produces the expected
privacy/detection trade-off curve (ε_DP=10 gives K=3.106,
c'=0.01325, FPR=0). LL-020 entry-level stays `:argued`
because the multi-strategy approach is the entry's claim;
Strategy 2 component is `:benchmarked`-tier per the new
benchmark. CLAUDE.md gains a §Benchmarking discipline
section codifying determinism checks + negative-results-
as-first-class. **0.0.28** delivers the LL-021 high-
resolution P-R2c refresh: n=5 → n=15 trials per point
*confirms* the n=5 fit at higher statistical confidence;
refined `c′=0.0288` (was 0.02777; 3.8 % shift); negative-
margin points reduce 3 → 1; Wilson CIs tighten ~50 %.
**0.0.29** refreshes LL-019's KS test at 5× sample size +
α=0.01 and exposes a *methodological boundary*: at the high-
res regime, system-jitter-induced KS_stat variation is
comparable to the gap to critical, and the verdict flips
INDISTINGUISHABLE → DISTINGUISHABLE across consecutive runs.
Operational-significance unchanged (median/mean differences
~10 μs on 100 ms padded ops; ratio 1e-4). LL-019 stays
`:benchmarked` at the 0.0.19 evidence regime. The finding
generalises the §Benchmarking discipline rule from byte-
identical to *verdict-level* determinism for timing-based
benchmarks, and adds round-3 input on host-isolation
thresholds. **0.0.30** characterises LL-003's N-scaling for
the chosen SDE: Lorenz-96 at F=8 across N ∈ {20,40,80,160}
exhibits the spatially-extended-chaos prediction h_KS ≈ s·N
with asymptotic Lyapunov density s ≈ 0.255 per dimension.
**0.0.31** closes the per-SDE detection-power surface for
LL-006: parameter-space adversaries sweep F (Lorenz-96), ρ
(Lorenz-63), c (Rössler). Bound shape is universal across
the candidate set; per-SDE c′ values reflect per-param
sensitivity, not detection quality. Combined with 0.0.25
P3d's h_KS comparison: **Lorenz-96 has the right operational
balance** (high security margin AND moderate per-param
sensitivity); Lorenz-63 fails on both axes; Rössler fails on
both (narrow chaotic band → brittle to genuine calibration
drift). Architectural choice confirmed on a complementary
axis. **0.0.32** lands the LL-005 part-(a) parameter-validation
test as a sub-claim test only — `nyquist_compliant(...)`
predicate + 16 test assertions; suite 123 → 139. LL-005 stays
`:argued` because the adversary-detection sub-claim is still
open (0.0.24 P3-Nyq negative finding stands). **0.0.33** lands
the **decoupled visual layer** evidencing LL-002: pure HTML/JS
bubble simulator at `visual/` (Math.random()-driven, no
security-primitive references); 45 decoupling-assertion tests
in runtests.jl make the invariant executable on every commit.
LL-002 closes `:argued` → `:tested`. **0.0.34** lands the
**PharOS scoping pass** as the upward trust-stack complement
to the 0.0.26 P-OS pass: new entry LL-023
(consumer-API-surface, Boundary, :argued) articulates the API
contract LavaLamp commits to expose for OS-deployment
consumers. LL-022 (downward) + LL-023 (upward) close the
trust-stack scoping question on both ends. **0.0.35** ran a
full A0-A6 cross-audit (PASS post-fix; CLAUDE.md drift
fixed). **0.0.36** landed the Lean 4 scaffold
(`src/lean4/`; lake build clean). **0.0.37** added the Lean
CI workflow (`lake build` on every push). **0.0.38** lands
the **P-RS real-sensor scoping pass** + scaffold module —
new entry LL-024 (real-sensor-deployment-strategy,
Operational, :argued) articulates per-platform FFI strategy
(Linux first; macOS / Windows later); scaffold module
`src/julia/src/RealSensors.jl` exports six sensor
constructors that error at scaffold tier. **LL-022 +
LL-023 + LL-024 form the deployment-stack triple** — three-
layer commitment closing the scoping question on the
upward, downward, and operational-instantiation ends. Total
23 → 24; :argued 15 → 16. Three `:tested`; four
`:benchmarked`; sixteen `:argued`; one `:open` (LL-015 by
design). Test suite passes 202/202 in ~53s via
`Pkg.test()` (was 184; +18 RealSensors scaffold-discipline
assertions).

**Workflow.** P-R2 trio complete; previously-deferred P3
follow-ups (P3d / P3-bound / P3-Nyq) are unblocked. Round-3
review remains gated on the closure_forces_structure paper
update.

**Key architectural moves locked.**

- **Substrate-Bound Identity** as the canonical positioning. Not
  QKD-grade no-cloning inheritance; computational unclonability
  via measurement-symmetry breaking (PUF at device-universe scale).
- **Resolution-Bounded Security** as the formal claim:
  `S_production > S_measurement`. Quantum-grounded only when raw
  TRNG access is available; otherwise substrate-coupling residue
  carries the load.
- **Visual ↔ security decoupling** as a load-bearing
  architectural invariant. Lava-lamp visual is decorative;
  security primitive runs independently. Same shape as Lazarus.
  This decoupling resolves the visual-richness ↔ security
  tension that round-1 synthesis-team review identified as the
  key blindspot.
- **Single-attractor chaotic SDE** as the security-primitive
  engine candidate (Lorenz-96 leading; Lorenz / Rössler also
  viable). Multi-basin reaction-diffusion (Gray-Scott /
  Stochastic Ginzburg-Landau) explicitly rejected — they were
  rejected for visual richness, but rejection sticks because LL-002
  removes the constraint that pulled toward them in the first
  place.
- **Multi-Scale Lyapunov Divergence Audit** for
  adversary-signature residue detection (not scalar KL — counters
  slow-drift threshold-gaming).
- **Chaos-Guard** as periodic-window safety signal: real-time
  largest-Lyapunov estimate; if `λ_max ≈ 0`, reject entropy and
  reseed.
- **Continuous sensor coupling via external potential field** (no
  discrete parameter kicks; respects Nyquist condition vs physical
  noise bandwidth).

## Priority stack

P1 — **Attack-surface enumeration document.** ✓ Landed in 0.0.3
  (`docs/attack_surface_enumeration.md`). Six adversary classes
  (A1 remote, A2 unprivileged, A3 root [out of scope per
  LL-015], A4 side-channel, A5 registration-time, A6 time-
  localized). Ten attack vectors enumerated (V-001 "good
  enough" trajectory, V-002 basin-spoofing [closed by LL-002],
  V-003 quantum-seed → classical boundary, V-004 sensor Nyquist,
  V-005 slow-drift threshold gaming, V-006 sensor-input
  poisoning, V-007 registration ceremony, V-008 cold-start
  window, V-009 cross-config transition, V-010 threshold
  calibration gaming). Each has adversary class / mechanism /
  defenses (LL-IDs) / residual risk / mitigation pending.
  Document doubles as load-bearing technical content of the
  eventual LavaLamp paper.

P2 — **Architectural design pass.** ✓ Landed in 0.0.5
  (`docs/architecture_design_companion.md`). Five sub-items
  closed at design level (manual evidence, `:argued` status):
  - Lyapunov-spectrum residue audit (LL-006): vector
    per-exponent threshold; detection bound P(detect) ≥
    1 - K·exp(-c·T·δ_A²) with structural-separation prior from
    Closure v5 cross-sector autopoiesis 0/5202 result.
  - Resolution-Bounded Security claim (LL-008) + per-class
    A1..A6 quantification (new LL-018).
  - Chaos-Guard (LL-007): Benettin estimator over W ≈
    100/λ₁_expected; reseed via host TRNG on λ̂₁ < 0.1·λ₁_expected;
    2W warmup before re-mark VALID.
  - Sensor-coupling potential field (LL-004 / LL-005): smooth
    U(s, x; t) with ramped discrete-sensor smoothing and
    broadband-noise contribution; per-sensor Nyquist with f_SDE
    ≈ 10 kHz baseline; sensor authenticity (LL-016) via
    cross-validation + anomaly-flagging + TPM where available.
  - Protocol layer (LL-011 / LL-012 / LL-013 / LL-014 / LL-017):
    TPM+secret-mixing registration default; single-envelope
    WARMUP-state cold-start; per-config registered envelopes for
    cross-config transitions; vector + no-oracle + rate-limited
    threshold discipline.

P3 — **Julia prototype core.** ◐ In progress.
  - **0.0.6** Bootstrap + Lorenz-96 baseline (LL-003 `:tested`
    against literature).
  - **0.0.8** P3a sensor-coupling layer (`Sensors.jl` +
    `Engine.lorenz96_coupled`; LL-004 `:tested`; empirical
    non-degeneracy Δλ₁ ≈ +0.30 at α=1, +0.59 at α=2).
  - **0.0.9** P3b residue audit + detection-probability
    benchmark (`Audit.jl`; LL-006 `:tested`; empirical
    P(reject) curve flat ≈ 0.10 FPR for ε_A ≤ 0.75, sigmoid
    through 0.75-2.0, saturated 1.0 for ε_A ≥ 2.0).
  - **0.0.10** P3c chaos-guard (`ChaosGuard.jl`; LL-007
    `:tested`; Wolf-method λ̂₁ estimator at ~1.3 ms/call,
    state machine {INVALID, WARMUP, VALID}, reseed flow
    verified with deterministic-magnitude perturbation).

  - **CI workflow.** ✓ Landed in 0.0.11
    (`.github/workflows/test.yml`). Julia 1.12 on
    ubuntu-latest; runs `Pkg.test()` on every push to master
    and on PRs. 20-minute job timeout. Lockfile-respecting
    install via `julia-actions/julia-buildpkg`.

  **Sub-items closed since round-2:**
  - **0.0.17 P3-bound — LL-006 `:benchmarked`.** ✓ Landed.
    K=1, c′=0.00423, T=60. See `docs/p3_bound_companion.md`.
  - **0.0.18 LL-021 `:benchmarked`.** ✓ Landed. K=1,
    c′=0.02777, T=60 parameterised on ε_eff. See
    `docs/ll021_benchmarked_companion.md`.
  - **0.0.19 LL-019 `:benchmarked`.** ✓ Landed. KS-test
    confirms verify_constant_time produces statistically
    indistinguishable response-time distributions across
    accept/reject inputs (KS_stat=0.109 < critical=0.170 at
    α=0.05). See `docs/ll019_benchmarked_companion.md`.

  **Round-2 :benchmarked cohort complete.** All three
  round-2 surfaced :benchmarked targets (LL-006 detection
  bound, LL-021 worst-case bound, LL-019 timing-
  indistinguishability) have empirically-validated
  performance targets.

  **Sub-items closed since round-2 (continued):**
  - **0.0.23 LL-020 Strategy 2 ε-DP envelope stub** ✓ Landed.
    `differentially_private_envelope` in `Audit.jl`
    implements the Dwork-Roth Gaussian mechanism with σ_DP
    = sensitivity·sqrt(2·log(1.25/δ))/ε. 23 new test
    assertions. LL-020 entry-level stays `:argued` (multi-
    strategy approach as a whole; Strategy 1 TPM-sealed +
    Strategy 3 Shamir threshold remain implementation-
    deferred). See `docs/ll020_strategy_2_epsilon_dp_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.24 P3-Nyq Nyquist adversary-rate benchmark** ✓
    Landed with **negative result**. The residue audit
    (LL-006) does not detect sub-Nyquist sensor adversaries
    at the prototype's configuration because zero-mean
    Gaussian noise has invariant time-averaged statistics
    under sub-sampling. LL-005 stays :argued; the benchmark
    output is committed as audit-trail evidence. Sub-Nyquist
    detection requires LL-016 (sensor authenticity) or a
    not-yet-implemented mechanism (FFT / trajectory-
    checkpoint audit) — round-3 input. See
    `docs/p3_nyq_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.25 P3d SDE-selection benchmark** ✓ Landed.
    Comparative bench Lorenz-96 / Lorenz-63 / Rössler;
    Lorenz-96 dominates on all security axes (λ₁ ×1.86–26;
    n_pos ×8.4; h_KS ×11–155; KY dim ×13). LL-003 closes
    `:tested` → `:benchmarked`. See
    `docs/p3d_sde_selection_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.27 LL-020 Strategy 2 detection-power-vs-ε
    benchmark** ✓ Landed. Initial benchmark (2026-05-04 first
    pass) produced a pathological 100% FPR across all DP
    cells; determinism re-check (`diff` exit 0) cleanly
    attributed the result to a bug in
    `differentially_private_envelope` (symmetric Gaussian
    noise on σ + 1e-10 floor pushed σ_pub near zero,
    collapsing the threshold). Fix: variance-convolution
    `σ_pub = sqrt(env.σ² + σ_DP²)` (deterministic σ
    inflation; spectrum stays Gaussian-mechanism (ε,δ)-DP).
    Re-benchmark produces the expected privacy/detection
    trade-off: ε_DP=10 gives K=3.106, c'=0.01325, FPR=0
    (vs no-DP K=0.798, c'=0.00418, FPR=0.10); ε_DP=3 reaches
    58% detection at ε_A=3.0; ε_DP=1/0.3 are operationally
    vacuous. **σ_DP / σ_true_min** is the operationally
    meaningful predictor (ratio > ~3 → weak adversaries
    blend in). Strategy 2 closes to `:benchmarked`-tier
    evidence; LL-020 entry-level stays `:argued`. CLAUDE.md
    gains a §Benchmarking discipline section codifying
    determinism checks + negative-results-as-first-class.
    See `docs/audit_2026-05-04.md` (negative-result phase) +
    `docs/ll020_strategy_2_benchmarked_companion.md`
    (post-fix evidence).

  **Sub-items closed since round-2 (continued):**
  - **0.0.28 LL-021 high-resolution P-R2c refresh** ✓
    Landed. n=5 → n=15 trials per (direction, magnitude)
    point. New benchmark
    `src/julia/benchmark/p_r2c_structured_adversary_high_res.jl`
    + result file
    `src/julia/benchmark/results/p_r2c_structured_high_res_lorenz96.txt`.
    Refined fitted constants: K=1, c′=0.0288 (was 0.02777
    at n=5; 3.8 % shift). Binding constraint migrates from
    MIXED ε_A=1.0 (transition-region, P≈0.6 at n=5) to
    NARROW ε_A=4.0 (FPR-floor, P≈0.07 at n=15). Negative-
    margin points reduce 3 → 1 (the remaining one is FPR-
    floor and Wilson-95%-CI-consistent). Wilson CIs
    tighten ~50 % at the same P̂ (theoretical sqrt(15/5)=
    1.73× tightening). The refresh **confirms** the n=5 fit
    at higher statistical confidence rather than
    overturning it; LL-021 status stays `:benchmarked`. See
    `docs/ll021_high_res_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.29 LL-019 high-resolution KS-test refresh** ✓
    Landed with **regime-boundary finding**. The test was
    re-run at 5× sample size (1000 per source vs 200) and
    α=0.01 (vs 0.05). At the high-res regime the KS_stat for
    verify_constant_time fluctuates by ~0.04 across runs from
    system-jitter alone, and the verdict can flip
    INDISTINGUISHABLE → DISTINGUISHABLE between consecutive
    runs (Run 1: KS=0.073 INDIST; Run 2: KS=0.116 DIST;
    critical=0.093). Operational-significance is unchanged
    (median/mean differences ~10 μs on 100 ms padded
    operations; ratio 1e-4). LL-019 stays `:benchmarked` at
    the 0.0.19 evidence regime (α=0.05 / n=400). The boundary
    finding is round-3 input for §Host-OS invariants
    (timing-distribution benchmarks have a host-isolation
    threshold below which statistical power is jitter-
    limited). See `docs/ll019_high_res_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.30 LL-003 N-scaling characterisation** ✓ Landed.
    New benchmark
    `src/julia/benchmark/p3e_n_scaling.jl` + result file
    `src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt`.
    Sweeps N ∈ {20, 40, 80, 160} at F=8, 5 trials per N.
    **Linear extensive-chaos scaling confirmed empirically.**
    Fitted: h_KS ≈ 0.2165·N^1.0370 (β=1.04 ≈ theoretical 1.0).
    Per-N Lyapunov density h_KS/N converges from 0.2383
    (N=20) to 0.2591 (N=160); saturates by N≥80. **Asymptotic
    Lyapunov density s ≈ 0.255 per dimension** is a deployment-
    design constant. Compute scales as O(N³) per integration
    step (per-trial wall clock 0.1 → 1.8 → 5.9 → 25 s).
    Deployment-design rule: N* ≈ Δh*/s for target margin Δh*.
    LL-003 stays `:benchmarked`; the N-scaling adds deployment-
    guidance content. See `docs/p3e_n_scaling_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.31 LL-006 per-SDE detection-power** ✓ Landed. New
    benchmark
    `src/julia/benchmark/p3f_per_sde_detection_power.jl` +
    result file
    `src/julia/benchmark/results/p3f_per_sde_detection_power.txt`.
    Sweeps parameter-space adversaries against Lorenz-96 (F),
    Lorenz-63 (ρ), Rössler (c). **Bound shape is universal
    across the candidate SDE set.** Per-SDE c′ values:
    c′_F=0.00372 (Lorenz-96, binding ε_A=1.0); c′_ρ=0.00168
    (Lorenz-63, binding ε_A=4.0); c′_c=0.38179 (Rössler,
    binding ε_A=0.2). c′ values are NOT directly comparable
    as detection-quality rankings — they reflect per-unit
    parameter sensitivity. Combined with 0.0.25 P3d's h_KS
    comparison: **Lorenz-96 has the right operational balance**
    (high security margin AND moderate per-param sensitivity);
    Lorenz-63 fails on both axes (low h_KS AND low
    sensitivity); Rössler fails on both (low h_KS AND extreme
    brittleness — narrow chaotic band). Architectural choice
    confirmed on a complementary axis. LL-006 stays
    `:benchmarked`. See
    `docs/p3f_per_sde_detection_power_companion.md`.

  **Sub-items closed since round-2 (continued):**
  - **0.0.32 LL-005 part-(a) parameter-validation test** ✓
    Landed as a sub-claim test, not an entry-level upgrade.
    `nyquist_compliant(f_SDE, f_sensor, bandwidth)` predicate
    added to `src/julia/src/Sensors.jl` (re-exported); 16 new
    test assertions in runtests.jl. Test suite 123/123 →
    139/139. **LL-005 stays `:argued` at the entry level**
    because the adversary-detection sub-claim is still open
    per the 0.0.24 P3-Nyq negative finding. The discipline
    (sub-claim evidence ≠ entry-level upgrade) is documented
    in `docs/ll005_part_a_companion.md`.

  **All round-3-trigger memory queue items now closed.** No
  further unblocked sub-items remain. Round-3 (gated on
  `closure_forces_structure` paper update) is the only
  outstanding work-trigger.

P-R2 — **Round-2 architectural responses.** ◐ Promoted from
  followup status to active priority by 0.0.12; Aaron's §1D
  resolution accepted as-is on 2026-05-02 (3 new entries
  kept as 3; P3 deferral confirmed; Gemini-framing accepted
  as fair). Three design-response sessions, similar in shape
  to P2 sub-items; can land in any order between now and the
  round-3 trigger:
  - **P-R2a — LL-019 side-channel hardening.** ✓ Landed in
    0.0.14. `verify_full(ds, env; ...)` forces full Benettin
    at the API level (audit-on-every-verify);
    `verify_constant_time(λs, env; target_seconds)` pads
    response time to a uniform target (timing decorrelation).
    12 new test assertions; LL-019 closes :open → :tested.
    Statistical indistinguishability deferred to benchmark
    follow-up. See `docs/p_r2a_side_channel_hardening_companion.md`.
  - **P-R2b — LL-020 calibration confidentiality.** ✓ Landed
    in 0.0.16. Three-strategy design space documented:
    (1) TPM-sealed storage (primary for hardware-rooted);
    (2) ε-differential-privacy perturbation (universal
    fallback / open-verification); (3) Shamir-style
    multi-party threshold (primary for federated). LL-020
    closes :open → :argued (manual evidence). Implementation
    platform-coupled (TPM / Secure Enclave) or
    cryptographic-library-coupled (DP / Shamir); sits
    outside Julia-prototype scope per language-tier
    discipline. Lean theorem shapes per round-2 §1D.v
    priority 3 documented in §2.6.
  - **P-R2c — LL-021 worst-case-adversary-bound.** ✓ Landed
    in 0.0.15. Analytic derivation in
    `docs/p_r2c_worst_case_adversary_companion.md` §2.1
    (worst-case direction = orthogonal-to-mean-coupling-
    vector); empirical surface in
    `benchmark/results/p_r2c_structured_lorenz96.txt`
    showing dramatic asymmetry: NARROW direction at
    ε_A=4.0 → 0/5 detect; BROAD direction at ε_A=0.5 →
    3/5 detect. LL-021 closes :open → :tested. :benchmarked
    upgrade (K, c constant fitting) and Lean theorem
    (round-2 §1D.v priority 1) are P5/P6 followups.

P-RS — **Real-sensor scoping pass (Level-2 prototype prep).** ✓
  Landed in 0.0.38 (`docs/p_real_sensor_scoping_companion.md`
  + `src/julia/src/RealSensors.jl` scaffold). New entry
  LL-024 (real-sensor-deployment-strategy, Operational tier,
  `:argued`) articulates per-platform FFI strategy: Linux
  first (sysfs/procfs; ~3-5 days dev work; no FFI), macOS
  second (IOKit/SMC; ~2 weeks), Windows third (WMI; ~2-3
  weeks), TPM at P7 (months). Scaffold module exports six
  sensor constructors that error at scaffold tier pointing
  to the scoping companion (mirrors the 0.0.36 Lean
  scaffold pattern). **LL-022 (downward) + LL-023 (upward)
  + LL-024 (operational instantiation) form the
  deployment-stack triple** — three-layer commitment that
  closes the deployment-stack scoping question. Test suite
  184 → 202 (+18 scaffold-discipline assertions). Phase 1
  (Linux baseline) lands ~1 week post-round-3; the scoping
  is parallel-safe and ready for the implementation push
  when round-3 lands.

P-PharOS — **PharOS scoping pass (upward trust-stack scoping).** ✓
  Landed in 0.0.34 (`docs/pharos_scoping_companion.md`).
  Mirrors the 0.0.26 P-OS pass shape but oriented from the
  consumer side. New entry LL-023
  (consumer-API-surface, Boundary, `:argued`) articulates the
  API contract LavaLamp commits to expose for downstream
  OS-deployment consumers — four operations (`register`,
  `verify` with variants, `device_state`, `re_register`).
  PharOS is the canonical first instantiation (forthcoming
  OS-level identity layer in the Triad Deployments portfolio;
  lighthouse-metaphor reference); Lazarus and future SDK
  consumers also conform. **LL-022 (downward) + LL-023
  (upward) close the trust-stack scoping question on both
  ends** — paired Boundary entries at the trust-stack
  boundary; the asymmetry-trap defence is making both ends
  explicit. Three in-place amendments (LL-011, LL-017,
  LL-022) cross-reference LL-023. Independent of the
  closure_forces_structure paper update; landed as
  parallel-safe scaffolding work.

P-OS — **OS-level identity-security scoping pass.** ✓
  Landed in 0.0.26 (`docs/os_identity_security_scoping_companion.md`).
  Single companion design pass parallel in shape to P2.
  Closes the LavaLamp ↔ OS trust boundary that prior entries
  (LL-011, LL-012, LL-015, LL-016, LL-020) had gestured at
  without consolidating. New entry LL-022
  (OS-trust-stack-dependency, Boundary, `:argued`) pins the
  *upward* dependencies: required mechanisms (TPM/Secure-
  Enclave, OS sensor APIs at LL-005 bandwidths, host TRNG,
  user/kernel isolation) and recommended defense-in-depth
  (Secure Boot / measured boot, IMA / kernel-lockdown, eBPF-
  based sensor authentication). LL-015 (downward, A3 OOS) +
  LL-022 (upward, trust-stack) close the trust-stack scoping
  question. Five in-place amendments (LL-011, LL-012, LL-015,
  LL-016, LL-020) cross-reference LL-022. Independent of the
  closure_forces_structure paper update; landed in parallel.

P-R3 — **Synthesis-team round 3.** Trigger: *after the
  `closure_forces_structure` physics-paper update lands*
  (Aaron 2026-05-02). Parallel physics-paper work may
  surface corpus content that informs LL-021's worst-case-
  bound or the C-conjugate-inheritance argument; round-3
  brief composed after the paper update incorporates
  whatever the paper changes. P-R2a/b/c can land in any
  order before the trigger.

P4 — **Catlab categorical realisation** (optional, gated on P2).
  Use Julia + Catlab.jl / GATlab to verify the categorical
  structure of the verification protocol if P2's design pass
  surfaces enough categorical content to warrant it
  (registration ceremony LL-011, cross-config transitions
  LL-013, no-oracle response LL-017 — these are morphisms in
  a category of device-states with admissible transitions). The
  SDE / sensor-coupling primitive is dynamical-systems work and
  probably under-pulls Catlab's weight; the verification
  protocol may be different. **Decision rule:** skip by default;
  revisit when registration / cross-config transition designs
  are concrete. See `docs/language_plan_catlab_tier_companion.md`.

P5 — **Haskell compositional-completeness layer.** Spec-as-types
  + QuickCheck against the Julia prototype. Catches corollaries
  and universals the example-tested suite would miss. Haskell's
  job is *composition-space coverage*, not implementation —
  prevents an unspotted universal sailing into Lean / production.
  Same discipline that caught S-026 in the triadic-coordination-
  engine.

P6 — **Lean 4 formal verification.** Machine-verify the structural
  security claims (resolution-bounded unclonability theorem,
  ergodicity-assumption discipline, detection-probability bound).
  Lean track only justified once Haskell has closed compositional
  completeness against the Julia prototype.

P7 — **C/C++ production hardening.** Rewrite from the proven spec,
  not from the exploratory code. Reach only after P3–P6 close.

P8 — **Visual-skin scaffolding.** Decorative-only animation. Can
  be canned / `Math.random()`-driven / Cloudflare-style RNG-blob.
  Decoupled from security primitive per LL-002. Low priority,
  can land any time.

## Spec status (per LAVALAMP_SPEC.md)

- Total spec entries: 29 (was 27; +LL-028 +LL-029 from 0.0.50
  round-3 Tier 3 spec landing)
- `:proved`: 1 (LL-021 — first-ever LavaLamp `:proved` entry;
  promoted at 0.0.48 L2 by the Lean 4 + Mathlib v4.29.1 proof
  in `src/lean4/LavaLamp/Theorems.lean`)
- `:tested`: 3 (LL-002, LL-004, LL-007 — unchanged)
- `:verified`: 0
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-027 — was 5
  pre-0.0.48; LL-021 promoted out at L2)
- `:argued`: 20 (LL-001, LL-005, LL-008, LL-009,
  LL-010, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017,
  LL-018, LL-020, LL-022, LL-023, LL-024, LL-025, LL-026,
  LL-028, LL-029 — LL-014 gains round-3 numerical-threshold
  non-fundamentality tie; LL-025 + LL-026 added 0.0.45;
  LL-028 + LL-029 added 0.0.50)
- `:open`: 1 (LL-015 — A3-OOS scoping declaration; permanent
  by design)

Nine entries closed at the design-pass level via manual evidence;
five entries (LL-002, LL-003, LL-004, LL-006, LL-007) closed to
`:tested` / `:benchmarked` via the P3 prototype + visual layer.
None machine-verified yet — Lean (P5/P6) targets LL-006, LL-008,
LL-018 plus the round-2 priorities (linear-coupling worst-case
bound, side-channel indistinguishability, calibration ε-DP).
P-R2 follow-ups are the active priority; P3 follow-ups
deferred.

## Open structural questions

The protocol-layer questions from 0.0.1–0.0.3 (LL-011..LL-014,
LL-016, LL-017) closed at design level in 0.0.5 (`:argued`).
Remaining `:open` entries fall into two classes:

**Awaiting P5–P6 verification (2 entries):**

- **LL-001** substrate-bound identity primitive — closed in
  spirit by LL-006 detection bound; awaits Lean enforcement.
- **LL-002** visual ↔ security decoupling — invariant; awaits
  type-level / Lean enforcement to demonstrate the architectural
  separation cannot be re-coupled by accident.

**Corpus-policy boundaries (3 entries):**

- **LL-009** no complex numbers in security math — invariant
  honored by §2.4 design; closes to `:argued` under a future
  small-session companion articulating the boundary locally.
- **LL-010** no open-ended simulation — invariant honored
  (bounded-window static analysis only); same companion path.
- **LL-015** A3 (root) explicitly out of scope — scoping
  declaration, not a claim with verifiable evidence; remains
  `:open` as the honest framing of what LavaLamp does *not*
  cover.

## Live discipline notes

- **Asymmetry-trap watch is engaged.** Visual ↔ security
  decoupling (LL-002) is precisely the kind of move that future
  "tidying" might re-couple for performance reasons. The 0.0.5
  design pass preserves the decoupling: chaos-guard reseeds do
  not signal to the visual; high f_SDE / sensor sampling does
  not couple into the visual layer. If re-coupling is ever
  proposed, the basin-spoofing attack surface (V-002) returns.
- **No-complex-numbers boundary** (LL-009) honored by §2.4 — the
  potential field U(s, x; t) is real-valued throughout; the SDE
  is real-valued; the residue audit operates on real Lyapunov
  exponents.
- **No open-ended simulation** (LL-010) honored — observation
  windows are bounded T; the Oseledec / Pesin / Eckmann-Ruelle
  results invoked in §2.1 apply within the bounded ergodic
  regime, not over open-ended simulation.
- **Sensor-authenticity residual** (V-006 / LL-016) remains the
  largest residual risk even after 0.0.5. The design pass
  identifies four authenticity strategies and recommends a
  default; no strategy fully eliminates V-006. High-assurance
  deployments must specify which A4 capability level they assume.

## Recent companion docs / formal artefacts

- **Round-3 Tier 3 spec landing** (0.0.50, 2026-05-06) —
  Spec-only pass landing the three Tier 3 changes per round-3
  §1D.iii / §1D.iv / §1D.vii. Engineering implementation is
  separately sequenced by P-RS Level 2 prototype availability
  per round-3 §1D.viii — this version lands the architecture-
  design content for the gaps round-3 surfaced; the
  engineering pass comes later. Three changes:
  - **LL-028 — runtime-conformance-verification** added
    (Boundary, manual, `:argued`; defends V-019). The
    deployment-stack triple LL-022 + LL-023 + LL-024
    specifies *what* must hold; LL-028 specifies *how to
    verify it holds at runtime*. Four conformance
    requirements: (1) attestation continuity (TPM-attested
    boot + measured runtime state); (2) sensor cross-
    validation with adversarial probes; (3) verifier-side
    LL-023 API conformance probing; (4) continuous TRNG
    attestation. Closes the API-conformance vs invariant-
    conformance gap (V-019: deployer satisfies API while
    violating invariants). `:tested` upgrade gated by P-RS
    Level 2 conformance-check module. Per ChatGPT §1C.A3.
  - **LL-029 — multi-channel-entropy-independence** added
    (Operational, manual, `:argued`; defends V-018).
    Cross-validation requires *physical-mechanism* diversity,
    not just sensor diversity. A heater-coupled thermal +
    battery-discharge + AC-current readings are correlated
    (one mechanism, three sensors); LL-029 forces enumeration
    of uncorrelated physical-mechanism families
    (thermal / acoustic / EM / electrical / optical /
    entropy-source-decay / quantum) before cross-validation
    qualifies. Calibration-window correlation test
    (`|ρ| > 0.3` over 60s) flags same-family pairs at
    registration. `:tested` upgrade gated by P-RS Level 2
    sensor architecture. Per ChatGPT §1C.A2 (sensor-fusion-
    inversion attack class).
  - **LL-019 round-3 deployment-context expansion footer**
    (status unchanged at `:benchmarked`). Two-regime framing
    of the timing-channel claim: regime 1 = dev-host artifact
    (the 0.0.19 benchmark regime, sub-microsecond channel
    below jitter floor); regime 2 = multi-tenant shared
    environment (real channel, observable by co-tenant
    adversary). Regime-2 deployments need shared-environment
    deployment constraints — dedicated core / pinned
    scheduling, constant-time padding above shared-host noise
    floor (≥ 10 ms), jitter randomisation (≥ 1 ms uniform
    offset). The 0.0.19 `:benchmarked` evidence is unchanged;
    the amendment is a scope-honesty refinement on the
    regime-2 generalisation. Per ChatGPT §1C.A1 (LL-019 is
    BOTH artifact AND real channel).
  - **Counts:** 27/1/3/0/4/18/1 → 29/1/3/0/4/20/1
    (+LL-028 +LL-029 to `:argued`).
  - **Round-3 closure check:** Tier 1 (0.0.45) ✓ + Tier 2
    (0.0.46) ✓ + Lean L1 (0.0.47) ✓ + Lean L2 (0.0.48) ✓ +
    LL-006 composition foothold (0.0.49) ✓ + Tier 3 spec
    (0.0.50) ✓. Round-3 spec-side deliverables fully landed
    end-to-end; engineering work (P-RS Level 2 prototype
    implementation; LL-028 / LL-029 conformance modules) is
    sequenced separately as it requires hardware availability
    and multi-version implementation passes. Round-3 §1D.viii
    ("Round 4 trigger: after Tier 1 + Tier 2 land *and* the
    first Lean theorem is type-checked") is now satisfied —
    Round 4 may be initiated when ready.
- **LL-021 squared-effective-magnitude composition foothold**
  (0.0.49, 2026-05-06) — A corollary lemma
  `LL021_eff_squared_bound : 0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 →
  (ε_A · proj)² ≤ ε_A²` lands in
  `src/lean4/LavaLamp/Theorems.lean` next to the worst-case
  bound. **Proof:** `pow_le_pow_left₀ (mul_nonneg h_ε
  h_proj_nn) (LL021_worst_case_bound h_ε h_proj_le_one) 2` —
  one term-mode line; `pow_le_pow_left₀` is Mathlib v4.29.1's
  GroupWithZero-form monotone-pow lemma (the unsubscripted
  `pow_le_pow_left` from older Mathlib versions was renamed
  during the v4.x reorganisation; the `₀` form is what `ℝ`
  hits). **Why it matters:** this is the algebraic step that
  connects LL-021 to LL-006. The detection-probability bound
  `P(detect) ≥ 1 - K · exp(-c · T · ε_eff²)` from LL-006
  inherits squared-magnitude monotonicity from this lemma —
  `ε_eff² ≤ ε_A²` and `t ↦ exp(-c·T·t)` decreasing together
  imply `exp(-c·T·ε_eff²) ≥ exp(-c·T·ε_A²)`, so the
  worst-case detection probability is *lower* than the
  isotropic-ε_A detection probability (which is exactly the
  asymmetry claim LL-021 is making). Unlike
  `LL021_worst_case_bound`, this lemma genuinely uses
  `0 ≤ proj` — reintroduced in the signature here because
  without it the squared product could equal the unsquared
  product without the monotone-squaring step working.
  **Build:** `lake build` clean — 767 jobs, zero warnings.
  **Status discipline:** counts unchanged at 27/1/3/0/4/18/1.
  The corollary is additional `lean-proved` content
  supporting the existing LL-021 `:proved` entry, not a new
  entry. **Sets up:** round-3 §1D.v priority-4 LL-006
  detection-bound theorem (when LL-006 lands as a Lean
  theorem in a future version, it will use this corollary as
  a composition step; LL-006 evidence-type
  `benchmarked` → `lean-proved` and status `:benchmarked` →
  `:proved` at that point).
- **Round-3 Lean L2 — LL-021 worst-case bound `:proved`**
  (0.0.48, 2026-05-06) — The L1 `sorry` body in
  `LavaLamp.LL021_worst_case_bound` is replaced by a real
  Lean 4 proof: `mul_le_of_le_one_right h_ε h_proj_le_one`,
  a direct application of Mathlib's
  `mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`. The
  hypothesis `0 ≤ proj` was dropped from the L1 signature
  (the bound holds for negative `proj` too — the product
  becomes non-positive, trivially `≤ ε_A` for non-negative
  `ε_A`); downstream theorems composing with this one will
  introduce the non-negativity hypothesis where they need it.
  **`lake build` clean** — 767 jobs green; zero warnings (no
  `sorry` warning, no unused-variable warning). The Lean
  kernel verified the proof at compile time. **Status flip:**
  LL-021 evidence-type `benchmarked` → `lean-proved`; status
  `:benchmarked` → `:proved`. **First-ever LavaLamp `:proved`
  entry.** Counts: 27/0/3/0/5/18/1 → 27/1/3/0/4/18/1 (+1
  :proved / −1 :benchmarked). The `:benchmarked` empirical
  fit-constant content (`K=1, c′=0.0288, T=60` at N=20,
  n=15 trials per point) is preserved as the operational
  deployment-fit detail in the spec entry's notes; the Lean
  theorem captures the bound *shape* (the algebraic content
  the empirical fit is a *fit to*) and is what `:proved`
  refers to. **Round-3 closure on the Lean track:** Aaron's
  resolution decision 1 (Option A — full Mathlib, theorem 1
  = LL-021 worst-case bound) is now fully landed end-to-end.
  Theorem 2 (LL-019 timing-indistinguishability) is the next
  Lean priority; the Mathlib environment now in place at L1
  carries it.
- **Round-3 Lean L1 — Mathlib integration + LL-021 theorem-
  statement landed** (0.0.47, 2026-05-06) — Per round-3 §1D.v
  Decision 1 (Option A — full Mathlib), the Lean 4 track at
  `src/lean4/` integrates Mathlib v4.29.1 and lands the first
  theorem statement (sorry-stubbed). **Toolchain bumped**
  `leanprover/lean4:v4.18.0` → `v4.29.1` to resolve a Darwin
  25 (macOS 25+) dyld error on the v4.18.0 cache binary
  (`__DATA_CONST segment missing SG_READ_ONLY flag`); v4.29.1
  ships with the fix and matches the Mathlib v4.29.1 release.
  **`lakefile.lean` adds** `require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @
  "v4.29.1"`; **`lake-manifest.json`** regenerated with
  Mathlib + 8 transitive deps pinned (plausible, LeanSearchClient,
  importGraph, proofwidgets, aesop, Qq, batteries, Cli).
  `lake exe cache get` populated 8232 prebuilt `.olean` files.
  **`LavaLamp/Theorems.lean`** rewritten from comment-block
  placeholder to a real theorem statement: `theorem
  LL021_worst_case_bound {ε_A proj : ℝ} (h_ε : 0 ≤ ε_A)
  (h_proj_nn : 0 ≤ proj) (h_proj_le_one : proj ≤ 1) : ε_A *
  proj ≤ ε_A := by sorry`. The theorem captures the bound
  *shape* — the projected effective magnitude `ε_eff = ε_A ·
  proj` cannot exceed `ε_A` — leaving the empirical
  fit-constant content (`K=1, c′=0.0288, T=60` at N=20) at
  the `:benchmarked` tier where it lives. **`lake build`
  clean** (767 jobs; single expected `declaration uses
  'sorry'` warning on `LL021_worst_case_bound`). **CI
  workflow** `.github/workflows/lean.yml` timeout-minutes
  15 → 60 to absorb Mathlib first-build + cache-download
  window on a fresh ubuntu runner. **Status discipline:**
  LL-021 stays `:benchmarked` per CLAUDE.md §Honest framing
  — a sorry-stubbed theorem is not a proof. **L2 (next
  version, 0.0.48):** replace `sorry` with a real proof
  (likely `mul_le_one_of_le_one_right` one-liner or
  `nlinarith`); LL-021 evidence-type promotes to
  `lean-proved` and status to `:proved`; counts shift
  27/0/3/0/5/18/1 → 27/1/3/0/4/18/1. Counts unchanged this
  version.
- **Round-3 Tier 2 spec pass** (0.0.46, 2026-05-06) —
  paper-grounded spec evolution per round-3 §1D.vii rendered
  sequencing. Three changes:
  - **LL-027 — asymptotic-Lyapunov-density-invariant**
    added (Core, benchmarked, `:benchmarked`). Promotes the
    0.0.30 P3e N-scaling result (`s ≈ 0.255` per dimension
    at F=8) from a deployment-design rule into a spec-level
    invariant claim. Deployment-design rule: `N* ≈ Δh*/s`;
    PharOS Δh*=8.0 → N*≈32; Lazarus Δh*=4.0 → N*≈16. The
    0.0.30 benchmark *is* the empirical evidence; no new
    benchmarking required to land the entry. Per Grok §1B.Q6
    proposal + ChatGPT §1C.A5 large-N caveat (V-020 / LL-021
    amendment).
  - **LL-021 round-3 amendment** added (status unchanged at
    `:benchmarked`). Two-pronged: (a) explicit scope-limit
    to finite-N regime (operationally N ≤ 80; large-N at
    N ≥ 160 requires re-benchmarking per V-020); (b)
    adaptive-adversary bound stated explicitly. Per ChatGPT
    §1C.A4 critique that LL-021 is a containment bound, not
    closure of A6 — the per-SDE universality result means
    one successful linear-model fit applies to all candidate
    SDEs.
  - **LL-014 round-3 amendment** added (status unchanged at
    `:argued`). Numerical-threshold non-fundamentality tie:
    the 10% FPR baseline and paper §13.6's 5-12% spurious-
    merge zone are the same phenomenon expressed in different
    vocabulary ("threshold ≠ structure"). Defends V-016
    by making non-fundamentality explicit. Per ChatGPT
    §1C.A6.
  Tier 2 first Lean theorem deferred to a separate version
  pass — adding Mathlib + writing real measure-theoretic
  proofs is multi-hour work that warrants its own session
  focus. Counts 26/0/3/0/4/18/1 → 27/0/3/0/5/18/1.
- **`docs/synthesis_team_round3_companion.md` + Tier 1 spec
  pass** (0.0.45, 2026-05-06) — synthesis-team round 3
  metabolic synthesis + Tier 1 implementation. Round 3 ran a
  seat rotation (Gemini stepped out; Grok rotated edge-witness
  → synthesis; ChatGPT joined as new edge-witness entrant).
  Both seats responded substantively. **Verdicts:** Grok
  (synthesis) `engage-and-formalise-after-fixes`; ChatGPT
  (edge-witness) `pass-after-fixes` — complementary lenses,
  neither says fail. Aaron rendered three resolution
  decisions on 2026-05-06 (V-021/022 merge into V-015/016;
  Tier 1/2/3 sequencing confirmed; Lean Option A — LL-021
  worst-case bound + Mathlib full). Tier 1 (this version)
  lands: **LL-025 A7-passive-emanation-boundary** (parallel
  boundary triple with LL-015 + LL-024; tier-bounded scope
  per ChatGPT A7); **LL-026 three-layer-logic-tier-
  annotation-discipline** (paper §1.2-derived governance;
  defends V-017 by construction); **V-014..V-020 enumerated**
  in `docs/attack_surface_enumeration.md` (V-014 EMF / V-015
  cross-sector autopoiesis spoofing absorbing V-021 / V-016
  numerical-threshold gaming absorbing V-022 / V-017 logical-
  tier confusion / V-018 coordinated multi-sensor synthesis /
  V-019 runtime conformance bypass / V-020 stable-manifold
  stealth). §5 residual-risks list extended with entries 10-13.
  §4 matrix updated. **LL-008 cost-asymmetry footer** already
  landed in 0.0.42 — no additional change needed; ratified by
  Grok §1B.Q1. Tier 2 (next version) pairs with first Lean
  theorem and lands LL-027 (asymptotic chaos density invariant)
  + LL-021 scope-limit + adaptive-adversary amendment + LL-014
  numerical-threshold non-fundamentality tie. Tier 3 sequenced
  by P-RS Level 2 prototype availability (LL-028 runtime
  conformance + LL-029 multi-channel entropy independence +
  LL-019 deployment-context expansion). Counts 24/0/3/0/4/16/1
  → 26/0/3/0/4/18/1; 7 new V-IDs added.
- **`docs/synthesis_team_round3_brief.md` engine-side fill +
  V-NNN rationalization** (0.0.44, 2026-05-05) — round-3
  brief engine-side blanks filled. Engine status delivered
  by parallel TCE Claude session: TCE v0.2.2 (2026-05-05);
  corpus-agnostic `Discovery.Triadic.findTriadicClosures`
  primitive extracted; `closureV5Corpus` (240,745 candidates
  on v167+2 corpus) + `businessEntityCorpus` clients
  verified; 8 QuickCheck invariant properties; spec at 51
  entries (13 :proved / 24 :tested / 6 :verified / 3
  :benchmarked / 5 :open). Has Discovery.Triadic been run
  against LavaLamp specifically? **No** — would require
  writing a `lavaLampCorpus` adapter (future-session work);
  not gating round-3. Specific-deployment-next decision
  (Lazarus / LavaLamp / PharOS) deferred per memory note
  `project_engine_redirect_to_triad.md`. **V-NNN tag
  collision rationalized:** §4 A7 EMF V-014 (added 0.0.40,
  came first) keeps V-014; §4 A6 paper-derived candidates
  renumbered to V-015 (cross-sector autopoiesis spoofing),
  V-016 (threshold gaming), V-017 (three-layer logical-tier
  confusion). §2 reading-list item 8 fills with concrete
  pointers (engine repo dashboard.md / ENGINE_SPEC.md
  S-047..S-051 / discovery_refactor companion /
  changelog.md top entries). **Brief is now substantively
  complete on both paper + engine sides; forward-ready.**
  Counts unchanged at 24/0/3/0/4/16/1.
- **`docs/synthesis_team_round3_brief.md` paper-side fill**
  (0.0.43, 2026-05-05) — round-3 brief paper-side blanks
  filled. Aaron 2026-05-05: *"paper done. almost done with
  engine."* The `closure_forces_structure` paper is at v1.0
  2026-04-01 (canonical public release; tagged); LavaLamp
  inherits structural priors from a *settled* corpus rather
  than a moving target. §1 paper-side paragraph captures
  three load-bearing section clusters: §10.5 (C-closure
  operation `Q_C = Q ∪ C(Q)`; structural disjointness of
  original + conjugate sectors); §11.13 (Q_102 self-
  reproducing fixed point — *"the daughter IS the parent"*;
  100% closure of 420 composition products); §13.6 (evidence
  classification — same honest-framing discipline as
  LavaLamp's CLAUDE.md §Evidence types: `proof` /
  `algebraic` / `standard` / `catlab` / `computational`;
  *"Float64 is evidence; Rational{BigInt} is a proof"*).
  Plus the §1.2 three-layer logical structure framing
  (Possibilistic / Probabilistic / Bridge — LavaLamp's
  adversary model lives in Possibilistic) and the §13.6
  numerical-threshold remark (5%-12% spurious merges at
  threshold 0.999; 200/200 canonical at 1−10⁻¹²) mapping
  onto LL-014 threshold calibration. §2 reading list item 1
  fills with concrete file paths + section pointers. §3 Q1
  reframed with three sub-questions
  (structural-transfer-vs-vocabulary; "daughter IS the
  parent" mapping; threshold robustness). §4 A6 reframed
  with three V-NNN candidates: V-014 cross-sector autopoiesis
  spoofing; V-015 numerical-threshold calibration gaming;
  V-016 three-layer logical-tier confusion. Engine-side
  blanks (§1 engine paragraph; §2 reading-list item 8)
  remain pending engine completion. Round-3 trigger response
  time at 0.0.43: ~15-30 min when engine completes, to fill
  engine-side and rationalize the V-NNN tags. Counts unchanged
  at 24/0/3/0/4/16/1.
- **`docs/threat_landscape_companion.md` §2.6/§2.7 + §6Q8 +
  §7.6 update** (0.0.42, 2026-05-05) — adds the **metabolic-
  value / predator-prey ecology axis** to the threat-landscape
  framing. Aaron 2026-05-05 (post-§2.5): *"the metabolic value
  of the target. If the defense is such that it is not worth
  the risk for the attacker (not enough value) they will go
  find something else. This is how we achieve symbiosis in
  the ecosystem. Lions and Gorillas... Hyenas and Lions..."*
  §2.6 articulates the predator-prey ecology axis (orthogonal
  to scale and to defense-architecture) — most attackers
  don't bother because cost > benefit; symbiosis is the
  default; gut-microbiome / immune-incorporation extends the
  metaphor to "most non-self isn't attacked." §2.7 reframes
  LavaLamp's security claim as *cost-asymmetry* — "attacking
  this device costs more than the result is worth, relative
  to easier targets" — with translations across the four
  threat tiers (cockroach trivially repelled / catapult must
  not be cheapest target / state-level needs structural
  disconnection / symbiotic is the default for most). New §6
  Q8 surfaces three architectural options for spec-level
  cost-asymmetry articulation: (a) explicit boundary entry,
  (b) LL-008 footer (taken in this commit), (c) deployment-
  context only. §7.6 lesson: "symbiosis is the equilibrium
  goal, not victory" — defense-in-depth = cost amplification,
  not perimeter strengthening; the corpus's autopoietic-
  closure principle expressed at predator-prey level. LL-008
  footer cross-references §2.7 — the resolution-bounded-
  security claim IS a cost-asymmetry claim formalised. No new
  spec entries; counts unchanged at 24/0/3/0/4/16/1.
- **`docs/threat_landscape_companion.md`** (0.0.41) — meta-
  architectural threat-landscape framing for the Triad
  Deployments. Surfaced 2026-05-05 in conversation: *"lavalamp
  is important but we need to frame the context IN WHICH it
  is important."* Aaron's cockroach/catapult/castle/immune-
  system metaphor as the load-bearing frame: cockroach-class
  threats (small-scale, persistent — phishing, composability
  seams, drift, slow-drift threshold gaming) vs catapult-class
  (large-scale, resourced — TEMPEST, supply-chain interdiction,
  cryptographic primitive failure, Q-Day) vs the rare-and-lethal
  combination at state-actor tier. Castle/membrane/immune-
  system architecture as defense; the immune-system metaphor
  maps directly onto Possibilistic Security's autopoietic-
  closure principle. §3 maps Triad Deployments onto the
  metaphor (LavaLamp = identity foundation; PharOS = membrane
  checkpoint; Lazarus = inner sanctum). §4 honestly catalogs
  in-scope vs OOS threat classes + 8 load-bearing assumptions.
  §5 complementary defenses across hardware/software/
  operational/strategic tiers. §6 surfaces 7 round-3
  questions beyond Q7/A7 (supply-chain integrity boundary;
  substrate-stability boundary; composability-seam discipline;
  quantum-threat horizon framing; closure-of-N at multiple
  scales). §7 captures five lessons including "the corpus's
  defensive principle is structurally faithful" and "state-
  level threats require structural responses, not just better
  defenses." Cross-references added to LL-015, LL-018, LL-022
  footers. No new spec entries (companion is meta-architectural;
  round-3 may surface LL-025+ from the §6 questions). Counts
  unchanged at 24/0/3/0/4/16/1.
- **`docs/synthesis_team_round3_brief.md` Q7 + A7 update**
  (0.0.40, 2026-05-05) — round-3 brief gains a synthesis-seat
  Q7 + edge-witness-seat A7 covering the **EMF /
  passive-emanation-adversary gap** surfaced in conversation
  2026-05-05. The Triadic Watchmen (Lazarus / LavaLamp /
  PharOS) cover the software stack but miss the physical-
  emanation layer; A7 is the candidate new adversary class
  (passive emanation interceptor; structurally distinct from
  A4 software-channel) and LL-025 is the candidate new
  Boundary entry (parallel to LL-015 A3-OOS framing).
  Synthesis seat's Q7 weighs three architectural options
  (new entry / sub-claim of LL-022 / deployment-time
  documentation only) and asks whether the deployment-stack
  triple should extend to a quartet or form a parallel
  boundary triple with LL-015 + LL-024. Edge-witness seat's
  A7 asks whether passive-emanation reconstruction is
  realistic at modern multi-GHz CPU speeds and what
  capability tier (close-proximity-state-actor /
  mid-tier-SDR / wide-spread) bounds A7. Word cap raised
  2500 → 2800. No spec changes; counts unchanged at
  24/0/3/0/4/16/1.
- **`docs/synthesis_team_round3_brief.md`** (0.0.39) — round-3
  brief skeleton landed pre-trigger. Substantively complete on
  the LavaLamp side: §1 What changed (0.0.20 → 0.0.38 work-set
  in two modes — empirical refinement + parallel-safe
  scaffolding); §2 Reading list (LavaLamp companions cited;
  paper / engine entries marked **`[FILL: ...]`**); §3
  synthesis-seat Q1-Q6 (drawn from the nine accumulated
  architectural inputs in audit_2026-05-04_full.md §9; Q1 has
  paper-specific blank); §4 edge-witness A1-A6 (A6 is paper-
  specific blank); §5 response format (2500-word cap; verdicts
  + Lean priorities + paper-update integration ask); §6
  followups. When the closure_forces_structure paper update
  lands and round-3 triggers, the `[FILL: ...]` blanks fill in
  ~30-60 min, then the brief forwards to Gemini + Grok.
  Reduces round-3 trigger response time from "several hours of
  composition" to "fill blanks + forward." No spec entry
  changes; counts unchanged at 24/0/3/0/4/16/1.
- **`docs/p_real_sensor_scoping_companion.md`** + **`src/julia/src/RealSensors.jl`**
  (0.0.38) — P-RS real-sensor scoping pass + scaffold module.
  §1 inputs (LL-004 / LL-005 / LL-016 / LL-022). §2.1 per-
  platform sensor surface (Linux sysfs/procfs simplest;
  macOS IOKit/SMC; Windows WMI). §2.2 maps the §2.1 surface
  to LL-004's six sensor categories. §2.3 per-sensor
  sample-rate constraints with LL-005 nyquist_compliant
  table. §2.4 authenticity strategies in real-hardware
  context (strategy 2 cross-validation as prototype
  default; strategy 1.5 eBPF on Linux for hardened
  deployments; strategy 1 TPM at P7 hardening). §2.5
  Linux-first implementation roadmap (Phase 1 ~1 week post-
  round-3; Phase 2 macOS ~2-4 weeks; Phase 3 Windows ~4-6
  weeks; Phase 4 P7 TPM). §2.6 test strategy (recorded
  sensor traces; CI on Linux). §2.7 connection to LL-022 /
  LL-023 (deployment-stack triple). §5 captures four
  lessons including "the deployment-stack triple closes
  scoping below LL-023" and "Linux-first roadmap minimises
  infrastructure cost." Scaffold module
  `src/julia/src/RealSensors.jl` exports six sensor
  constructors (real_thermal_stream, real_battery_stream,
  real_ac_stream, real_usb_stream, real_cpu_governor_stream,
  real_loadavg_stream); each errors at scaffold tier
  pointing to the companion. New entry LL-024
  (real-sensor-deployment-strategy, Operational, `:argued`).
  Test suite 184 → 202 (+18 scaffold-discipline assertions).
- **`.github/workflows/lean.yml`** (0.0.37) — Lean 4 CI
  workflow. `leanprover/lean-action@v1` runs `lake build` on
  push to master + PRs (mirror of the Julia CI structure).
  Reads the pinned `src/lean4/lean-toolchain` (v4.18.0) and
  `lake-manifest.json` (empty packages at scaffold tier). At
  the scaffold tier the build is trivial (smoke def +
  comment-block placeholder); when proofs land in round-3+,
  the same workflow becomes a correctness check (real proofs
  without `sorry` are what CI starts catching). 15-min
  timeout, ubuntu-latest. Counts unchanged at
  23 / 0 / 3 / 0 / 4 / 15 / 1.
- **`src/lean4/`** (0.0.36) — Lean 4 formal-verification
  scaffold. Buildable Lake project with toolchain pin
  (`leanprover/lean4:v4.18.0`), root `LavaLamp.lean` smoke,
  `LavaLamp/Theorems.lean` round-3 placeholder (comment-block
  forms of six priority theorem statements: LL-021 worst-case
  bound, LL-019 timing indistinguishability, LL-020
  calibration ε-DP, LL-006/008/018 isotropic detection bound,
  LL-022/023 parametric theorem-shape disciplines). README
  documents the Mathlib-or-not architectural decision as
  round-3-driven (currently no deps; build time is seconds).
  `lake build` clean post-commit. No spec entry status
  changes — scaffold is infrastructure-prep, not evidence.
  When proofs land, per-priority files split out and the
  corresponding LL entries upgrade to `:proved` (lean-proved).
- **`docs/audit_2026-05-04_full.md`** (0.0.35) — Full A0–A6
  cross-audit pre-round-3. Triggered by the seven-version
  session arc 0.0.26 → 0.0.34. Result: **PASS across all six
  checks** post-fix; one drift item found and fixed (CLAUDE.md
  §Status section was 14 versions stale, frozen at 0.0.20 /
  21 entries; refreshed to 0.0.34 / 23 entries). §9 documents
  round-3 readiness — the prototype side is ready for round-3
  brief composition when the `closure_forces_structure` paper
  update lands. Distinguished from `audit_2026-05-04.md` (the
  same-date LL-020 negative-result diagnostic from 0.0.26.5).
- **`docs/pharos_scoping_companion.md`** (0.0.34) — PharOS
  scoping pass. §1 inputs from existing LL-011/013/014/017/022
  + 0.0.26 P-OS companion + portfolio reference. §2.1
  articulates PharOS's role (lighthouse / persistent reference
  for OS authentication; consumer of LavaLamp's verifier API,
  not a re-implementation of the security primitive). §2.2
  enumerates the four LL-023 API operations (register, verify
  variants, device_state, re_register) with inputs / outputs /
  errors / use cases. §2.3 maps OS integration points (PAM
  module on Linux, Authorization Plug-in on macOS, Credential
  Provider on Windows; SSH key wrapping + biometric
  replacement as advanced integrations). §2.4 articulates
  PharOS's narrower threat model (defends authentication
  spoofing / replay / config-transition; transitively
  inherits LavaLamp's exclusions for A3 / V-006 / V-012 /
  side-channel). §2.5 closes the Triad Deployments trust-
  stack picture (Lazarus / LavaLamp / PharOS as a closure-of-
  three; Watchmen-reframe → no single deployment is the unit
  of security). §2.6 pins the parametric Lean theorem-shape
  for consumer inheritance (paired with LL-022's parametric
  shape for OS dependency). §5 captures four lessons
  including "the trust-stack scoping question has two ends"
  and "PharOS's role is reference, not gate."
- **`visual/`** (0.0.33) — Decorative-only lava-lamp animation
  layer evidencing LL-002. Self-contained HTML/JS canvas
  animation (~80 lines `lavalamp.js`); Math.random()-driven
  bubble simulator with no security-primitive references. The
  `Visual layer decoupling (LL-002)` testset in
  `src/julia/test/runtests.jl` (45 assertions) makes the
  decoupling invariant executable on every commit: visual JS
  contains no security-primitive identifiers; `src/julia/src/`
  contains no visual-layer identifiers; visual uses
  Math.random() not crypto-grade RNG; visual has no
  imports/requires/external script references. LL-002 closes
  `:argued` → `:tested`. Counts shift: `:tested` 2 → 3;
  `:argued` 15 → 14. See `visual/README.md` for the
  decoupling-discipline rationale.
- **`docs/ll005_part_a_companion.md`** (0.0.32) — Brief
  permanent record of the LL-005 part-(a) parameter-validation
  test. §1.2 documents why the test landed despite the
  "consider deferring to avoid misleading partial upgrade"
  warning: add the test, but keep LL-005 `:argued`. §2.2
  distinguishes what the test shows (parameter-compliance
  predicate works) from what it does not show (adversary
  detection still open per 0.0.24 P3-Nyq negative). §5.1
  generalises the discipline: a spec entry whose claim is a
  conjunction of N sub-claims needs evidence on all N to
  upgrade to `:tested`. §5.3 confirms all
  round-3-trigger-memory queue items are closed.
- **`docs/p3f_per_sde_detection_power_companion.md`** (0.0.31) —
  Per-SDE detection-power benchmark for LL-006. §1.1 explains
  the parameter-space-adversary model (perturbing F / ρ / c).
  §1.3 documents the determinism PASS. §2.1 reports per-SDE
  detection sigmoids and fitted c′. §2.2 cautions that c′
  values are not directly comparable across parameters with
  different scales. §2.3 articulates the operational-balance
  argument: Lorenz-96 wins on both axes (h_KS + per-param
  sensitivity); Lorenz-63 / Rössler fail on both. §2.4
  explains Rössler's narrow-chaotic-band brittleness as
  intrinsic to the Rössler system. §2.5 compares F-space (this)
  to α-space (0.0.17) for Lorenz-96 — both yield similar c′
  within ~12 %, confirming the bound's parameterisation
  flexibility. §5 captures five lessons including "detection
  bound shape is universal across the candidate set" and
  "all known unblocked sub-items now closed."
- **`docs/p3e_n_scaling_companion.md`** (0.0.30) — Lorenz-96
  N-scaling benchmark for LL-003 / LL-008. §1 documents
  configuration + determinism PASS. §2.1-§2.2 reports per-N
  spectrum statistics and fits power-law scaling
  (h_KS ≈ 0.2165·N^1.0370, n_pos ≈ 0.3019·N^1.0220, KY ≈
  0.6623·N^1.0048). §2.3 tabulates per-N Lyapunov density
  convergence (0.2383 → 0.2591 across N=20 → N=160, ~9%
  finite-N correction). §2.4 validates O(N³) compute
  scaling. §2.5 articulates the deployment-design rule
  (N* ≈ Δh*/s for target margin Δh*). §3.2 grounds LL-008's
  Lean theorem in N-dependent form. §5 captures five
  lessons including the methodology continuity across the
  three high-res refreshes 0.0.28-0.0.30.
- **`docs/ll019_high_res_companion.md`** (0.0.29) — LL-019
  high-res refresh exposing a methodological boundary, not a
  tightening. §1.2 establishes the verdict-level determinism
  convention for timing-based benchmarks (byte-level
  determinism is structurally inapplicable). §2.1-§2.2 report
  the verdict instability across two consecutive runs at α=0.01
  / n=2000 (KS_stat fluctuates 0.073 → 0.116; verdict flips).
  §2.4 explains why critical value shrinks faster than KS_stat
  in the jitter-dominated regime. §2.5 distinguishes statistical
  from operational distinguishability (mean/median differences
  ~10 μs on 100 ms padded ops). §5.1 generalises the
  §Benchmarking discipline rule to multiple determinism levels;
  §5.4 captures "some refreshes find boundaries, not
  tightenings" as a first-class outcome.
- **`docs/ll021_high_res_companion.md`** (0.0.28) — LL-021
  high-resolution refresh of the P-R2c structured-adversary
  surface. §1.2 documents the determinism check (PASS after
  stripping wall_s from result file). §2 reports the n=15
  empirical surface and the n=5↔n=15 sample-frequency
  comparison. §2.3 refits c′=0.0288 at n=15 (was 0.02777 at
  n=5; 3.8 % shift). §2.4 tabulates Wilson CI tightening
  (~50 % at same P̂). §2.5 verifies bound holds at 11 of
  12 points pointwise (was 9 of 12 at n=5). §5 captures
  five lessons including "confirmation is a positive
  result" and the binding-point regime migration from
  transition-region (MIXED ε_A=1.0 at n=5) to FPR-floor
  (NARROW ε_A=4.0 at n=15).
- **`docs/audit_2026-05-04.md`** (between 0.0.26 and 0.0.27) —
  Diagnostic finding from the LL-020 Strategy 2 benchmark
  attempt. §2.1 documents the determinism re-check (PASS;
  byte-identical across two runs). §2.2 attributes the
  pathological 100% FPR to a bug in
  `differentially_private_envelope` (symmetric Gaussian noise
  on σ + 1e-10 floor). §3 lays out three architectural fix
  options; recommends variance-convolution form. Same shape
  as a P3-Nyq negative result + diagnostic note; this
  pre-dated the fix and grounds the post-fix companion.
- **`docs/ll020_strategy_2_benchmarked_companion.md`** (0.0.27) —
  Strategy 2 detection-power-vs-ε benchmark + companion. §1.1
  documents the variance-convolution σ refinement (response
  to the diagnostic above). §2.1 reports the empirical
  detection-power surface across the (ε_DP, ε_A) plane. §2.2
  tabulates σ_DP per privacy budget. §2.3 fits bound
  constants per ε_DP. §2.4 articulates the operational design
  rule σ_DP ≤ X/3 (where X is the smallest adversary
  magnitude that must be detected). §3 explains why Strategy 2
  closes to `:benchmarked`-tier while LL-020 entry-level stays
  `:argued`. §5 captures five lessons including end-to-end
  correctness lives in benchmarks not unit tests, and the
  σ_DP/σ_true_min ratio as the meaningful predictor.
- **`docs/os_identity_security_scoping_companion.md`** (0.0.26) —
  P-OS OS-level identity-security scoping pass. §2.1 lays out the
  trust stack (LavaLamp / OS userspace / kernel / bootloader /
  firmware / TPM) with each layer's role formally defined as
  in-scope / depended-upon / out-of-scope. §2.2 enumerates four
  required OS mechanisms (TPM/Secure-Enclave, OS sensor APIs at
  LL-005 bandwidths, host TRNG, user/kernel isolation) with
  graceful-fallback paths for three of the four; the host TRNG is
  the only no-fallback case. §2.3 enumerates three recommended
  defense-in-depth mechanisms (Secure Boot / measured boot, IMA /
  kernel-lockdown, eBPF-based sensor authentication on Linux).
  §2.4 articulates the LL-015 boundary against the trust stack.
  §2.5 maps the dependency to five existing entries (LL-011,
  LL-012, LL-015, LL-016, LL-020). §2.6 pins the Lean / Haskell
  theorem-shape implication: future formal proofs of LavaLamp
  claims must be parametric in OSAssumptions, not unconditional.
  New entry LL-022 closes to `:argued`; five existing entries
  amended in place.
- `docs/concept_origin_companion.md` — provenance graph (codetaur
  visual seed, Aaron concept derived from Possibilistic Security,
  Brian ORSIΩ-vocabulary engagement, patent-offer-to-codetaur).
- `docs/synthesis_team_round1_companion.md` — full dialogue arc:
  Gemini synthesis 1, Grok edge-witness 1, Gemini rebuttal +
  premature skeleton, Grok edge-witness 2 on visual-richness
  blindspot, Aaron's decoupling resolution; §7 captures 0.0.2
  language-plan revision.
- **`docs/attack_surface_enumeration.md`** — formal threat tree.
  Adversary taxonomy (A1–A6, with A3 explicitly out of scope),
  attack vectors V-001..V-010, defenses by LL-ID, residual
  risks, spec-impact recommendations. Maintained artefact (not
  a session companion); will be updated as architecture evolves.
- **`docs/language_plan_catlab_tier_companion.md`** (0.0.4) —
  methodology refinement inserting Catlab.jl / GATlab as a
  fifth tier between numerical verification and Haskell
  compositional completeness. Anchors on Closure v5 corpus
  precedent (`:catlab` evidence type, 9 of 145 `:proved`
  entries). Establishes the three-jobs distinction: Catlab
  (computational categorical), Haskell (compositional), Lean
  (formal). Default for LavaLamp: skip Catlab; revisit if P2
  surfaces categorical structure in the verification protocol.
- **`docs/qkd_pqc_complementarity_companion.md`** (0.0.4) —
  positioning analysis. LavaLamp is not QKD (different problem,
  different security tier); is defensive-postured (detect via
  residue audit, not prevent observation); composes with PQC
  rather than replacing it; replaces MFA under
  identity-as-closure; inherits the C-conjugate adversary
  structurally from Closure v5's cross-sector autopoiesis
  failure (0/5202 on primary seed). §2.6 connects identity to
  the Q₅₁-as-autopoietic reframing (Closure v5 v157, S157):
  identity is Q₅₁-tier; the residue audit is a spectrum check,
  not a checkpoint trace match.
- **`docs/architecture_design_companion.md`** (0.0.5) — P2
  architectural design pass. Five sub-sections closing the design
  questions for the residue audit, resolution-bounded security,
  chaos-guard, sensor coupling, and protocol layer (registration
  / cold-start / cross-config / no-oracle). Twelve spec entries
  move from `:open` to `:argued` (manual evidence); new entry
  LL-018 added for per-class A1..A6 quantification of the
  resolution-boundary margin. P3 unblocked. Round-2
  synthesis-team review trigger now met.
- **`src/julia/`** (0.0.6) — P3 prototype core bootstrap +
  Lorenz-96 baseline. Pinned Julia project (`Project.toml` +
  `Manifest.toml`) on DifferentialEquations 7.17,
  DynamicalSystems 3.6.7, StaticArrays 1.9.18.
  `src/julia/src/{LavaLamp.jl, Engine.jl}` implements Lorenz-96
  (N=40, F=8) and the Benettin Lyapunov spectrum estimator
  (LL-003 / LL-006 / LL-007 substrate). Test suite
  (`test/runtests.jl`, 8 assertions) verifies λ₁ ≈ 1.66 vs
  literature, n_pos ∈ [11, 16], h_KS ≈ 10.5, IC-invariance per
  Oseledec. LL-003 closes to `:tested`.
- **`docs/p3_baseline_companion.md`** (0.0.7) — P3 baseline
  companion + dev-host field observations. §2.1 documents the
  Lorenz-96 reproduction of literature; §2.2 records empirical
  test robustness against host non-stationarity (a real
  thermal-climb + AC-plug-in + battery-state-shift event
  occurred during the canonical baseline run, all 8 assertions
  still passed); §2.3 frames this as a substrate-coupling
  self-demonstration previewing P3a test design; §2.4 reframes
  compute load as a *structural indicator* of h_KS-margin, not
  a tax on the security primitive. §5 captures lessons for
  P3a/b/c/d sub-tasks. No spec status moves; positioning
  language captured for future paper.
- **`docs/p3a_sensor_coupling_companion.md`** (0.0.8) — P3a
  sensor-coupling layer companion. §2.1 specifies the linear-in-x
  potential field U(s, x; t) = Σ_k α_k · s_k(t) · ⟨b_k, x⟩
  implementing architecture-design §2.4. §2.2 documents the
  no-coupling sanity (mathematical reduction to baseline). §2.3
  documents stepped-sensor smoothness (sigmoid ramp through a
  binary sensor transition; trajectory bounded throughout, no
  step-time excursion). §2.4 records the corrected ⟨x⟩(F)
  prediction (chaotic-regime mean ≈ 2.34, not fixed-point F=8)
  and the implication: trajectory-mean detection has ~10× lower
  signal-to-noise than spectrum-based detection, *empirically
  validating* the round-1 architectural choice to detect via the
  Lyapunov spectrum. §2.5 demonstrates non-degeneracy
  (∂λ₁/∂α ≠ 0): Δλ₁ ≈ +0.30 at α=1, +0.59 at α=2 — the
  prerequisite δ_A > 0 condition for LL-006's detection bound.
  LL-004 closes to `:tested`. Lessons §5 captures the
  trajectory-mean vs spectrum signal/noise observation, the
  fixed-point ⟨x⟩ ≠ chaotic-regime ⟨x⟩ subtlety for future SDE
  prototyping, and the lockfile-discipline subtlety of
  `[deps]` vs `[extras]` for module-level imports.
- **`docs/p3b_residue_audit_companion.md`** (0.0.9) — P3b
  residue-audit companion. §2.1 documents the Audit.jl
  verifier (Envelope + register_envelope + residue + verify
  + synthetic_adversary). §2.2 records the unit-vector
  perturbation semantic for synthetic adversaries (deterministic
  L2 magnitude rather than `ε_A · randn` magnitude variance).
  §2.3 records a stub-stream zero-sensor degeneracy bug found
  during prototype development. §2.4 reports the empirical
  detection-probability surface; §2.5 explains why this is
  `:tested` and not yet `:benchmarked`. §2.6 documents the
  Sensors-to-top-level module restructure. LL-006 closes to
  `:tested`.
- **`docs/p3c_chaos_guard_companion.md`** (0.0.10) — P3c
  chaos-guard companion. §2.1 documents the state machine
  ({INVALID, WARMUP, VALID}) and the §2.3 transition logic.
  §2.2 records sub-chaotic-regime detection at Lorenz-96 F=2
  (λ̂₁ ≈ 0 at the trivial fixed point → guard stays INVALID).
  §2.3 documents the reseed flow with deterministic-magnitude
  unit-vector perturbation. §2.4 records the cost story:
  Wolf-method λ₁ estimator at ~1.3 ms/call vs Benettin
  full-spectrum at ~507 ms — 400× speedup, suitable for
  always-on monitoring at sub-1% CPU. §2.5 confirms LL-002
  visual decoupling preserved. §2.6 documents the Julia
  module/struct name-conflict gotcha (`module ChaosGuard` +
  `struct Guard`). §5 captures four lessons including the
  conservative-by-construction initial WARMUP state and its
  parallel to LL-012 cold-start handling. LL-007 closes to
  `:tested`.
- **`docs/synthesis_team_round2_brief.md`** (0.0.11) — Brief
  forwarded to Gemini and Grok for round 2 of the synthesis-
  team review. Six questions per seat; reading-list set; 2000-
  word response cap. Brief itself does not capture responses
  — those land in the round-2 companion.
- **`docs/synthesis_team_round2_companion.md`** (0.0.12) —
  Round-2 dialogue + AI-integrator resolution. §1B faithfully
  summarises Gemini's response (affirmed architecture without
  deepening; placeholder Lean stubs; one new suggestion of
  Transfer-Entropy verification statistic). §1C summarises
  Grok's response (engaged A1-A6 directly; surfaced V-011
  Reseed Oracle, V-012 Calibration Spectrum Leakage, V-013
  Structured α-Direction Attack; identified linearisability
  concern A6; sharper Lean priorities). §1D proposes
  resolution: 3 new spec entries (LL-019/020/021), notes
  amendments on LL-004/006/007/011/014, deferral of P3d /
  P3-bound / P3-Nyq, promotion of P-R2 architectural
  responses. §7 lists outstanding instantiator decisions
  pending Aaron's confirmation.

## Live empirical observations

- **Compute and h_KS are structurally linked** (per
  `p3_baseline_companion.md` §2.4). The chaos-production rate
  S_production = h_KS sets the resolution-boundary margin Δh
  per LL-008/LL-018. Producing h_KS at the rate required for a
  meaningful margin requires sustained integration cost. A
  measurable thermal signature on the genuine device under load
  is *expected*, not a bug. Pitch language must reflect this.
- **Dev host is a free test-scenario source for P3a.** Thermal
  climb, AC plug-in, USB plug-in events on the developer's
  workstation are real substrate events of exactly the
  categories design §2.4 enumerates. P3a's synthetic
  sensor-stream stub should mirror these statistics; the dev
  host itself becomes a usable real-sensor test platform once
  IOKit / SMC FFI work is in scope.
- **Test bounds robust to real-world non-stationarity.** The
  ±15% bound on λ₁ and the ±25% bound on h_KS in
  `runtests.jl` absorbed a real configuration event during the
  canonical 0.0.6 run without false-failing. Future bound
  tightenings should keep this margin to preserve real-world
  robustness.

## Out of scope (explicit)

- Quantum hardware. LavaLamp is classical chaos with optional
  quantum-grounded TRNG seed; no photonic infrastructure.
- Information-theoretic security claims. Resolution-bounded
  computational tier only.
- Open-ended simulation regimes (per LL-010).
- Complex-valued security math (per LL-009).
- Visual richness as part of the security claim (per LL-002).
- Network protocol design (key distribution between distant
  parties — that's QKD's problem, LavaLamp does locally-bound
  device entropy).
