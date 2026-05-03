# Dashboard — LavaLamp

Last updated: 2026-05-03 (0.0.17 — P3-bound LL-006 :benchmarked).

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
default). Six entries `:tested`; ten `:argued`; five `:open`
(LL-001/002 await Lean; LL-009/010/015 corpus-boundary).
Test suite passes 94/94 in ~50s via `Pkg.test()`.

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
    High-resolution detection-probability sweep + constrained
    constant fit. K=1, c′=0.00423, T=60 validated; bound
    holds at 10/11 data points (FPR-floor point consistent
    with sampling variance). See
    `docs/p3_bound_companion.md`.

  **Remaining unblocked sub-items:**
  - P3d — SDE-selection benchmark (LL-003 `:benchmarked`).
  - P3-Nyq — Nyquist-condition adversary-rate benchmark
    (LL-005 `:tested`).
  - LL-019 `:benchmarked` upgrade (statistical timing-
    indistinguishability via response-time KS-test).
  - LL-021 `:benchmarked` upgrade (constrained fit on the
    P-R2c worst-case surface; same shape as P3-bound).
  - ε-DP envelope stub for LL-020 Strategy 2 → would close
    LL-020 to `:tested`.

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

- Total spec entries: 21 (no change in 0.0.17)
- `:proved`: 0
- `:tested`: 5 (LL-003, LL-004, LL-007, LL-019, LL-021)
- `:verified`: 0
- `:benchmarked`: 1 (LL-006)
- `:argued`: 10 (LL-005, LL-008, LL-011, LL-012, LL-013,
  LL-014, LL-016, LL-017, LL-018, LL-020)
- `:open`: 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

Nine entries closed at the design-pass level via manual
evidence; four entries (LL-003, LL-004, LL-006, LL-007) closed
to `:tested` via the P3 prototype. None machine-verified yet —
Lean (P5/P6) targets LL-006, LL-008, LL-018 plus the round-2
priorities (linear-coupling worst-case bound, side-channel
indistinguishability, calibration ε-DP). P-R2 follow-ups are
the active priority; P3 follow-ups deferred.

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
