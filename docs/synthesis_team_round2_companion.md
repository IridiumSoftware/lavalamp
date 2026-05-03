# Synthesis-Team Round 2 Companion — 2026-05-02

Permanent record of the second round of synthesis-seat
(Gemini) + edge-witness-seat (Grok) review on LavaLamp.
Captures the dialogue, the contrast between the two seats,
and the architectural moves that landed in 0.0.12 in
response.

The forward-brief is at
`docs/synthesis_team_round2_brief.md`. The brief was
forwarded to Gemini and Grok separately by Aaron after the
0.0.11 commit. The responses arrived in a single integration
pass; this companion captures both plus Aaron's resolution.

---

## §1 — The dialogue arc

### §1A — Aaron's brief (forwarded)

`docs/synthesis_team_round2_brief.md` summarised what
changed since round 1 (six commits across 0.0.3 - 0.0.11),
pointed at the reading set in priority order, and posed six
questions per seat:

- Synthesis (Gemini): Q1 linear-in-x sufficiency, Q2 bound
  shape sharpness, Q3 round-2 likely blindspot, Q4
  C-conjugate inheritance load-bearing-ness, Q5 LL-016
  authenticity deferral honesty, Q6 Catlab tier revisit.
- Edge-witness (Grok): A1 reseed-event timing observability,
  A2 calibration-time observation, A3 isotropic-vs-structured
  adversary, A4 Wolf-vs-Benettin asymmetry exploitation, A5
  10% FPR operational viability, A6 linear-coupling
  linearisability.

Both seats received §5 response-format requests (numbered
evaluations, cumulative verdict, V-NNN net-new vectors, Lean
theorem suggestions; 2000-word cap per seat).

### §1B — Gemini synthesis seat (response)

Faithful summary of the response received:

**Substantive content:**

- Affirmed the Substrate-Bound Identity / Resolution-Bounded
  Security framing as robust against V-001 / V-002 in the
  enumerated attack surface. Confirmed A3 / V-003 as a "Hard
  No-Go" boundary — the OOS scoping in LL-015 is preserved.
- Restated the multi-scale Lyapunov audit as the LL-006
  mechanism (this is what the round-1 architecture and the P2
  design pass already specified — not a new finding, but a
  confirmation).
- **One new suggestion:** add a Transfer-Entropy test on the
  cross-correlation between the sensor suite and the SDE
  output, confirming that the SDE's entropy actually depends
  on the substrate inputs and isn't being generated locally.
  This is a novel verification statistic worth pinning as a
  follow-up benchmark.
- Three Lean theorem stubs:
  - `residue_detection`: `∃ T : Float, exp(λ * T) * ε >
    detection_threshold`. Captures the unperturbed
    divergence claim, not the detection-probability bound.
  - `entropy_inheritance`: `output_entropy ≥ input_entropy`
    given coupling. Direction is wrong for chaotic
    amplification — chaos *produces* entropy, doesn't
    preserve any input Shannon entropy.
  - `verify_without_oracle`: `matches_spectrum traj
    env.spectrum → is_authentic traj`. Trivial restatement
    of LL-006's verifier definition.
- **Verdict:** `engage-and-formalise`. LL-006 / LL-008 /
  LL-018 → `:formalizing` (a status not in our taxonomy;
  treat as "approved for Lean formalization").

**What the response did NOT cover** from the brief's Q1-Q6:

- Q1 (linear-in-x sufficiency): not addressed.
- Q2 (bound shape sharpness): not addressed.
- Q3 (round-2 blindspot): not addressed.
- Q4 (C-conjugate load-bearing): not addressed.
- Q5 (LL-016 authenticity deferral): not addressed.
- Q6 (Catlab tier revisit): not addressed.

The response is structured around the seat's own priorities
rather than the brief's questions. The verdict is positive
and consistent with continued progress, but the synthesis
content is closer to a *restatement* of the existing design
than a *deepening* of it.

**Honest assessment for the record.** The Lean stubs are
placeholder-level — they do not capture the bound's
probabilistic content. `residue_detection`'s signature
states that exp(λT)·ε exceeds a threshold for some T, which
is the trivial divergence property of any chaotic system; it
does not establish P(detect) ≥ 1 - K·exp(-c·T·δ²). For Lean
work to land usefully, the theorem statements need to be
sharper than this — see §1C for Grok's improved theorem
priorities and §1D for the resolution.

### §1C — Grok edge-witness seat (response)

The edge-witness response engaged directly with A1-A6 and
surfaced **three new attack vectors** beyond V-001..V-010:

#### A1 → V-011: Reseed Oracle

The chaos-guard's `INVALID → WARMUP → VALID` state machine
plus logged reseeds creates an observable timing channel.
Reseed events correspond to brief unavailability windows
(verifier returns WARMUP-shaped responses). Because reseed
triggers are sensor-correlated (chaos-guard fires on `λ̂₁ <
τ_λ`, which can be driven by sensor-induced parameter
drift), an A4 / A5 adversary probing verification readiness
or measuring response latency obtains an *event channel
correlated with sensor-driven thermal/entropy events*. This
is not just leakage — it is a low-bandwidth oracle that lets
an adversary synchronise their spoof trajectory to the
device's internal state.

Mitigation: constant-time response (hide WARMUP behind a
uniform delay) or decorrelate reseed triggers from
observable verifier outputs. Reference standard timing-side-
channel literature (Kocher et al. on cache timing).

#### A2 → V-012: Calibration Spectrum Leakage

The 10-trial registration ceremony exposes ~10 high-fidelity
Lyapunov-spectrum estimates plus per-exponent σ to *anyone
observing the registration channel*. The TPM attestation
defence in LL-011 prevents *substitution* of the registered
envelope, but does not protect *observation* — an A5
adversary present during registration captures the registered
envelope to machine precision and can later mount a
near-genuine attack.

This directly undermines LL-017 verification-no-oracle: the
no-oracle requirement assumes the adversary doesn't know the
threshold geometry, but if the adversary *knows the registered
envelope*, they can pre-compute the rejection ball and craft
trajectories that lie just inside it.

The synthetic-adversary in P3b is irrelevant to this attack —
real adversaries get the *actual* registered envelope, not a
random parameter perturbation. This vector is not discharged
in the 0.0.5 design pass; LL-011 covers substitution but not
confidentiality.

#### A3 → V-013: Structured α-Direction Attack

The `synthetic_adversary` in `Audit.jl` perturbs α
isotropically (random unit vector × magnitude). Real-world
adversaries have *structure* in their perturbation directions:

- Sensor manipulation (V-006) perturbs only the α components
  coupled to the manipulated sensor.
- Configuration replay (V-009) shifts α toward the
  registered configuration set.
- Slow-drift threshold gaming (V-005) chooses the direction
  that maximally evades the residue test.

The empirical detection-probability surface (P3b) at the
prototype's working point is therefore an *optimistic*
bound, not a worst-case bound. Structured adversaries can
stay inside the residue ball longer by aligning ε with the
weakest-coupled directions of the linear U(s, x; t). This
under-estimates adversary capability by at least a factor
related to the condition number of the coupling matrix
(empirically visible in the α-sweep data from 0.0.8).

#### A4 — Wolf-method monitoring vs Benettin-method audit

Confirmed as exploitable. The chaos-guard uses fast Wolf λ₁
(continuously); the audit uses Benettin full spectrum (on
demand or periodic). An adversary can craft trajectories
that match λ₁ (passing the guard) while diverging in higher
exponents (caught only by the audit). If the audit runs less
frequently than the guard, the inter-audit window is the
attacker's drift budget. The prototype does *not* enforce
"audit on every verification request" — only the guard runs
continuously. This breaks the multi-scale audit story for
adversaries who can model the guard's specific cost asymmetry.

#### A5 — 10% FPR is operationally suspect

Confirmed as a real operational concern. The benchmark
(p3b_detection_lorenz96.txt) shows ~10% baseline FPR at
k=5. For multi-tenant verifiers this is a denial-of-service
vector; for a single-user device it's just annoying. Not
fundamental — tightenable via more calibration trials, a
better test statistic (e.g., chi-squared rather than
per-exponent max), or adaptive thresholding. Required for
production-grade hardening.

#### A6 — Linear coupling is structurally soft

Critical structural finding. The coupling `U(s, x; t)` is
linear in `x`, so the gradient `∇_x U` is constant in `x`.
The sensor-to-dynamics interface is therefore *linearisable*:
a sufficiently determined adversary can build a linear model
of the forced Lorenz-96 system from observed trajectories
and recover α via least-squares or Kalman filtering.

The underlying Lorenz-96 dynamics are non-linear (cubic
terms), but the *coupling layer* is not protected by that
non-linearity — the cubic terms appear in the unforced
dynamics, while the sensor enters as a state-independent
forcing. State-dependent coupling (U quadratic-or-higher in
x, e.g., bilinear `s · ⟨x ⊗ x, ·⟩`) would raise the bar
substantially.

The prototype's security therefore rests on the assumption
that the adversary cannot accurately model the sensor
interface — a strong assumption for an "open architecture"
threat model where the SDE family and coupling form are
known.

#### Verdict and Lean priorities

- **Verdict:** `fail` with named attack vectors V-011, V-012,
  V-013. Fixes possible but non-trivial.
- **Lean theorem priorities** (replacing the synthesis-seat
  stubs):
  1. **Linear-coupling worst-case bound.** Prove that for
     linear coupling there exists a structured perturbation
     direction `û` such that residue growth is bounded by
     `O(ε)` rather than `exp(λT)·ε` for small T (i.e., the
     exponential-divergence guarantee fails in the worst-case
     direction).
  2. **Side-channel formalisation.** Model observable timing
     and reseed events; prove or disprove indistinguishability
     from legitimate load.
  3. **Calibration security.** Theorem stating that the
     registered envelope distribution is ε-differentially
     private (or equivalent) w.r.t. registration-channel
     observers.

These are sharper than the synthesis-seat stubs and target
the actual implementation gaps, not just the design's
positive claims.

### §1D — Aaron's resolution (proposed; instantiator decision)

This subsection captures the AI integrator's reading; flagged
as proposed pending Aaron's instantiator confirmation. If
Aaron disagrees with any of the architectural moves below,
they should be reverted in a follow-up commit before any
implementation work proceeds.

#### §1D.i — Honest assessment of the round

- **Gemini's review was less substantive than the brief
  asked for.** The response affirmed the existing
  architecture but did not directly engage Q1-Q6, and the Lean
  theorem stubs are placeholder-level. The Transfer-Entropy
  suggestion is the single substantive new contribution. The
  verdict (`engage-and-formalise`) is consistent with
  continued progress.
- **Grok's review was substantively stronger.** It engaged
  A1-A6 directly, surfaced three real new attack vectors,
  identified a structural concern (linearisability), and
  produced sharper Lean priorities than the synthesis seat.
  The `fail with named attack vectors` verdict is the
  operationally honest framing.
- **Combined verdict:** `engage-and-formalise-after-fixes`.
  Round 2's findings are tractable — they require new spec
  entries and architectural responses but not a fundamental
  redesign.

#### §1D.ii — New attack vectors landed in spec

Three new V-IDs added to `attack_surface_enumeration.md`:

- **V-011 — Reseed Oracle.** Chaos-guard reseed timing
  observable; sensor-correlated; gives the adversary a
  thermal-event oracle.
- **V-012 — Calibration Spectrum Leakage.** Registration
  ceremony exposes the registered envelope to observers;
  TPM attestation defends substitution but not confidentiality.
- **V-013 — Structured α-Direction Attack.** Real adversaries
  have structured perturbation directions; isotropic
  synthetic_adversary is an optimistic threat model.

#### §1D.iii — New spec entries

Three new LL-IDs added to `LAVALAMP_SPEC.md`:

- **LL-019 — side-channel-hardening.** Constant-time response
  on chaos-guard state transitions; decorrelate reseed
  triggers from observable verifier outputs; require Benettin
  full-spectrum audit on every verification request (closes
  the Wolf-vs-Benettin window from A4). Defends V-011 + A4.
  Status: `:open`. Logic tier: Core.
- **LL-020 — calibration-confidentiality.** Registered
  envelope and per-exponent σ must not be exposed to
  registration-channel observers; sealed storage on the
  verifier side; ε-differential-privacy or equivalent
  perturbation if envelope must be published. Defends V-012.
  Status: `:open`. Logic tier: Core.
- **LL-021 — worst-case-adversary-bound.** The LL-006
  detection-probability claim must be stated against a
  *worst-case* adversary direction (the direction with
  minimum δ_A given the coupling structure), not against
  isotropic perturbations. Empirical benchmarks should
  include structured-direction adversaries. Defends V-013 +
  A6. Status: `:open`. Logic tier: Core.

#### §1D.iv — Notes amendments on existing entries

- **LL-004** continuous sensor coupling — *Linear-in-x
  limitation noted.* The prototype implementation uses
  linear-in-x potential; this is sufficient for the
  non-degeneracy demonstration in 0.0.8 but insufficient for
  worst-case-adversary resistance per A6. State-dependent
  coupling (U quadratic-or-higher in x) is a future
  enhancement; the current implementation's security claim is
  correspondingly conditional.
- **LL-006** Lyapunov-spectrum residue audit — *Structured-
  adversary acknowledgment.* The empirical detection-
  probability surface in `benchmark/results/p3b_detection_lorenz96.txt`
  is an optimistic bound (isotropic adversary). Worst-case
  bound is LL-021's deliverable.
- **LL-007** chaos-guard — *Reseed-timing decorrelation
  requirement.* The state-transition logic must be deployed
  with constant-time response or randomised delay to defeat
  V-011 timing observation.
- **LL-011** registration ceremony — *Calibration
  confidentiality requirement.* TPM attestation defends
  envelope substitution; calibration confidentiality
  (LL-020) defends envelope observation. The two are
  complementary and both required.
- **LL-014** threshold-calibration discipline — *Adaptive-
  thresholding follow-up.* Grok's A5 confirms 10% FPR is
  brittle; adaptive thresholding (already noted as future
  hardening in the design pass) is now load-bearing for
  multi-tenant deployments.

#### §1D.v — Lean target updates

The Round-1-era Lean target shape (P6 in the dashboard) is
amended:

- **Replaced placeholder stubs.** Gemini's
  `residue_detection`, `entropy_inheritance`,
  `verify_without_oracle` stubs do not capture the bound's
  probabilistic content. They are not adopted.
- **Adopt Grok's priorities** (Aaron 2026-05-02, provisional —
  "then we'll discuss"; treat as working set, not final P5/P6
  specification):
  1. Linear-coupling worst-case bound (LL-006 + LL-021).
  2. Side-channel timing indistinguishability (LL-019).
  3. Calibration ε-DP (LL-020).
- **Original P6 target preserved.** The §2.1 detection-
  probability bound `P(detect) ≥ 1 - K·exp(-c·T·δ_A²)`
  remains the core LL-006 / LL-008 / LL-018 Lean target;
  Grok's priorities supplement, do not replace.

#### §1D.vi — Decision: pause prototype-extension work

Round-2's findings displace some of the previously-planned
P3 follow-ups:

- **Defer P3d (SDE-selection benchmark) and P3-bound (LL-006
  `:benchmarked` upgrade)** until LL-019 / LL-020 / LL-021
  architectural responses are designed. Both follow-ups
  build on top of the audit + chaos-guard infrastructure
  that V-011 / V-012 / V-013 mark as needing hardening; doing
  the comparative SDE bench against a known-soft architecture
  would just need to be re-run later.
- **Promote: design responses to LL-019 / LL-020 / LL-021.**
  These are not P3 implementation slices; they are
  architecture-design follow-ups that go through the same
  shape as P2: write the design, argue manually, optionally
  prototype, advance. May produce a third synthesis-team
  round before any implementation lands.
- **Round 3 trigger:** after design responses to LL-019 /
  LL-020 / LL-021 are drafted (similar to how Round 2
  triggered after P2 closed). Estimated 1-2 sessions of
  design work.

---

## §2 — Round-2 architectural state (post-resolution)

The architecture's load-bearing claims after Round 2:

| Layer | Claim | Status |
|---|---|---|
| Substrate-bound identity | Identity = sustained chaotic trajectory on the device | Affirmed (no change) |
| Resolution-bounded security | S_production > S_measurement | Affirmed; per-class quantification (LL-018) unchanged |
| Visual ↔ security decoupling | Visual driven by independent RNG | Affirmed (LL-002) |
| Multi-scale Lyapunov audit | Vector per-exponent residue test | Affirmed (LL-006) |
| Linear-in-x coupling | Sensor enters as constant gradient ∇_x U | **Limitation noted** (LL-004) |
| Reseed timing observability | Constant-time response required | **New requirement** (LL-019) |
| Calibration confidentiality | Registered envelope sealed against observers | **New requirement** (LL-020) |
| Worst-case adversary direction | Detection bound stated against minimum-δ_A direction | **New requirement** (LL-021) |
| Chaos-guard cheap monitoring | Wolf-method λ₁ at ~1.3 ms/call | Affirmed; coupled to LL-019 cadence requirement |
| Audit-on-verify cadence | Full Benettin spectrum on every verification request | **New requirement** (folded into LL-019) |

---

## §3 — Verification

The round-2 outputs are review responses (`manual` evidence)
captured permanently in this companion. The companion does not
move any spec entry's status — the new entries (LL-019, LL-020,
LL-021) land at `:open` because their architectural responses
are pending. The notes amendments on LL-004 / LL-006 / LL-007 /
LL-011 / LL-014 do not change those entries' statuses.

The decision to defer P3d / P3-bound and promote the LL-019 /
LL-020 / LL-021 design responses is a workflow shift, not a
spec action.

---

## §4 — Spec impact

### §4.1 — New entries

- **LL-019** side-channel-hardening (Core, `:open`, evidence
  `none`). Source: this companion §1D + V-011 / A4 in
  attack-surface enumeration.
- **LL-020** calibration-confidentiality (Core, `:open`,
  evidence `none`). Source: this companion §1D + V-012 in
  attack-surface enumeration.
- **LL-021** worst-case-adversary-bound (Core, `:open`,
  evidence `none`). Source: this companion §1D + V-013 + A6
  in attack-surface enumeration.

### §4.2 — Notes amendments (no status changes)

- LL-004: linearisability limitation noted; state-dependent
  coupling deferred as future enhancement.
- LL-006: structured-adversary acknowledgment; empirical
  surface is optimistic bound, worst-case is LL-021's
  deliverable.
- LL-007: reseed-timing decorrelation requirement (LL-019
  pre-condition).
- LL-011: calibration confidentiality requirement (LL-020
  complementary to TPM attestation).
- LL-014: adaptive-thresholding promoted to load-bearing for
  multi-tenant deployments.

### §4.3 — Updated counts (post-round-2)

- **Total:** 21 (was 18; +3 — LL-019, LL-020, LL-021)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 4 (unchanged — LL-003, LL-004, LL-006, LL-007)
- **`:benchmarked`:** 0
- **`:argued`:** 9 (unchanged)
- **`:open`:** 8 (was 5; +3 new entries)

### §4.4 — Files changed in this commit

- `docs/synthesis_team_round2_companion.md` (this file) — new.
- `docs/attack_surface_enumeration.md` — V-011, V-012, V-013
  added; matrix updated.
- `LAVALAMP_SPEC.md` — LL-019, LL-020, LL-021 added; notes
  amendments on LL-004, LL-006, LL-007, LL-011, LL-014;
  counts.
- `artifact_registry.md` — rows for LL-019, LL-020, LL-021;
  counts.
- `dashboard.md` — round-2 state; spec status updated;
  workflow shift to LL-019/020/021 design responses.
- `changelog.md` — 0.0.12 entry top-of-file.

---

## §5 — Process notes

### §5.1 — Round 1 had Gemini-first; Round 2 had Grok-substantive

Round 1 (2026-04-30) led with Gemini synthesis because the
architecture was in flux and synthesis was load-bearing. Grok
followed with edge-witness stress-test against the synthesised
architecture. Both seats produced substantive content.

Round 2 inverted the contribution profile: Gemini affirmed
the settled architecture without deepening it; Grok stress-
tested the *implementation* and surfaced real attack surface.
This is informative for round 3 — when the architecture is
settled, edge-witness review tends to be the higher-content
seat. Brief structure for round 3 should emphasise the edge-
witness questions and treat the synthesis-seat questions as
secondary unless an architectural revision is on the table.

### §5.2 — The brief's Q1-Q6 / A1-A6 scaffolding worked unevenly

Grok engaged A1-A6 directly. Gemini structured the response
around the seat's own priorities rather than the brief's
questions. Both behaviours are legitimate; the brief should
allow the synthesis seat more latitude in future rounds while
keeping the edge-witness numbered structure (which clearly
worked).

### §5.3 — Lean theorem priorities now reflect implementation gaps

The Round-1-era Lean target was the §2.1 detection-probability
bound. Round 2 expands the target to also include:

- Linear-coupling worst-case bound (the bound's optimism vs
  structured adversaries).
- Side-channel timing indistinguishability.
- Calibration ε-DP.

These are operationally smaller theorems than the full §2.1
bound and arguably easier to formalise first. P6 entry-point
is now plausibly LL-019 / LL-020 / LL-021's structural claims
rather than the LL-006 / LL-008 / LL-018 detection-probability
bound directly.

### §5.4 — Asymmetry-trap watch held

Both seats treated the visual ↔ security decoupling (LL-002)
as settled architectural ground; neither proposed re-coupling.
The decoupling discipline is intact post-round-2.

### §5.5 — No-complex-numbers / no-open-ended-simulation
boundaries held

LL-009 / LL-010 not relitigated. Both seats accepted the
real-valued / bounded-window scope.

---

## §6 — Followups

### §6.1 — Architectural responses to LL-019 / LL-020 / LL-021

Three design sessions, similar in shape to P2 sub-items:

- **LL-019 design.** Constant-time chaos-guard response
  protocol; decorrelation strategy for reseed-trigger ↔
  observable timing; specification of "audit-on-every-
  verification-request" cadence. Possibly a small companion
  doc per the round-1/round-2 pattern.
- **LL-020 design.** Calibration-data sealing protocol.
  Options: TPM-sealed storage; ε-DP perturbation of
  published envelope; multi-party threshold scheme on
  envelope reconstruction. Companion doc.
- **LL-021 design.** Worst-case adversary direction
  derivation; structured-adversary benchmark to supplement
  the existing isotropic surface. Likely needs both an
  analytic argument (worst case = direction with minimum
  ∂λ/∂α magnitude) and an empirical benchmark sweep over
  structured directions.

### §6.2 — Round 3 review trigger

**Resolved 2026-05-02 (Aaron):** trigger after the
`closure_forces_structure` physics-paper update lands (not
strictly after LL-019 / LL-020 / LL-021 design responses).
Parallel physics-paper work may surface structural content
that informs LL-021's worst-case-bound formulation or the
C-conjugate-inheritance question; round-3 brief composed
*after* the paper update so it incorporates whatever the
paper changes. LL-019 / LL-020 / LL-021 design responses can
land in any order between now and the round-3 trigger.

Brief for round 3 should focus on whether (a) the
LL-019/020/021 design responses adequately close V-011 /
V-012 / V-013, (b) the updated paper revises any corpus
result LavaLamp anchors on, and (c) new gaps emerge.
Round-3 brief should weight edge-witness questions per §5.1.

### §6.3 — Deferred

- **P3d — SDE-selection benchmark.** Deferred until LL-021's
  worst-case adversary framework lands; running comparative
  benchmarks against an optimistic bound would need re-running.
- **P3-bound — LL-006 `:benchmarked` upgrade.** Deferred to
  the same trigger; the bound's constants need to be
  calibrated against worst-case δ_A, not isotropic.
- **P5 Haskell compositional check.** Naturally fits after
  LL-019 / LL-020 / LL-021 design responses — Haskell can
  exercise the constant-time / sealed-envelope / structured-
  adversary structures via QuickCheck.
- **P6 Lean formal verification.** Targets expanded per
  §5.3.

### §6.4 — One-time-agent recommendation

A one-time agent in ~2 weeks to verify the round-2 fixes
*landed* would be appropriate — this is a multi-session
architectural-response window with concrete deliverables
(LL-019/020/021 design companions). Recommend:
`/schedule "verify LL-019/020/021 design responses landed
within 2 weeks of 2026-05-02"`.

---

## §7 — Outstanding instantiator decisions

Items where Aaron's call should override the AI integrator's
proposal in §1D before subsequent work proceeds.

**Resolved 2026-05-02 (Aaron):**

1. **§1D resolution accepted as-is.**
   - **1a.** AI-integrator's framing of Gemini's review as
     "less substantive than the brief asked for" — *fair*. No
     revision needed.
   - **1b.** Three new spec entries (LL-019/020/021) — *kept
     as three*. No consolidation.
   - **1c.** Deferral of P3d / P3-bound / P3-Nyq pending
     LL-019/020/021 design responses — *confirmed*.
2. **Lean target priorities:** *adopt Grok's three priorities*
   (linear-coupling worst-case bound; side-channel timing
   indistinguishability; calibration ε-DP) as the working
   P5/P6 target. *"Then we'll discuss"* — adoption is
   provisional pending later refinement; treat as the round-2
   working set, not the final P5/P6 specification. The
   Round-1-era target (the §2.1 detection-probability bound)
   remains the core LL-006 / LL-008 / LL-018 theorem; Grok's
   three supplement.
3. **Round 3 timing:** *trigger after the
   `closure_forces_structure` physics-paper update lands*,
   not strictly after LL-019/020/021 designs. The physics-
   paper work is ongoing in parallel and may surface
   structural content that informs LL-021's worst-case-bound
   formulation or the C-conjugate-inheritance question (round
   2 §1C-A6 / Q4-equivalent) — running round 3 against the
   updated paper avoids a wasted round if the paper revises
   the corpus result LavaLamp anchors on.

**Workflow consequence.** P-R2a / P-R2b / P-R2c can land
between now and the physics-paper update without triggering
round 3. The round-3 brief itself will be written *after* the
paper update so it incorporates whatever the paper changes.

This shifts round 3 from a near-term ("after design responses
land") trigger to a corpus-event trigger ("after paper
update"). The two are complementary, not in tension —
LL-019/020/021 design work is gated by Aaron's local schedule;
round 3 is gated by the corpus.
