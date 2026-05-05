# Synthesis-Team Round 3 Brief — LavaLamp

Sent: **TBD — pending closure_forces_structure paper update +
engine updates landing.** This skeleton landed at 0.0.39
(2026-05-04) as parallel-safe pre-trigger preparation; the
LavaLamp-side §1, §3 Q1-Q7, §4 A1-A7, §5 / §6 sections are
substantively complete. Paper-side and engine-side blanks
(marked **`[FILL: ...]`**) get filled when the upstream events
land and round-3 actually triggers.

**Update 2026-05-05 (0.0.40):** §3 Q7 + §4 A7 added covering the
EMF / passive-emanation-adversary gap surfaced in conversation
on 2026-05-05. The Triadic Watchmen (Lazarus / LavaLamp /
PharOS) cover the software stack but miss the physical-
emanation layer; A7 is a candidate new adversary class
extending A1-A6, and LL-025 is a candidate new Boundary entry
(parallel to LL-015 A3-OOS) declaring physical-emanation
scoping. Q7 / A7 ask the synthesis + edge-witness seats
whether this is a load-bearing addition to the spec or a
deployment-context recommendation.

This is a **brief** — the document Aaron forwards to each seat
to set up Round 3. The dialogue itself lives in
`docs/synthesis_team_round3_companion.md` (to be written *after*
the reviewers respond, not before; per round-2 precedent).

---

## §1 — What changed since Round 2

Round 2 (2026-05-02, captured in
`synthesis_team_round2_companion.md`) closed three new attack
vectors V-011/012/013 and added three new spec entries
LL-019/020/021. The P-R2 design-response trio (LL-019 side-
channel hardening; LL-020 calibration confidentiality; LL-021
worst-case-adversary-bound) closed the round-2-surfaced gaps
within an afternoon's work. The :benchmarked cohort
(0.0.17/18/19) fitted concrete bound constants. Round 2's
verdict was `engage-and-formalise-after-fixes` (Gemini) /
`pass-after-fixes` (Grok) — the project on the current path.

Since round 2 close (0.0.20 closure pass), 0.0.20 → 0.0.38
landed nineteen versions across two distinct work modes:

**Mode 1: Empirical refinement of round-2 :benchmarked cohort
(0.0.20 → 0.0.32):**

- **0.0.23–0.0.25** LL-020 Strategy 2 ε-DP envelope stub;
  P3-Nyq adversary-rate benchmark (negative result —
  residue audit doesn't detect Nyquist violations); P3d
  SDE-selection benchmark (LL-003 promoted to `:benchmarked`;
  Lorenz-96 dominates Lorenz-63 / Rössler 11×-155× on h_KS).
- **0.0.27** LL-020 Strategy 2 :benchmarked-tier (negative-
  result-then-fix arc — original implementation produced
  100% FPR; variance-convolution σ refinement landed; suite
  117 → 123).
- **0.0.28** LL-021 high-resolution P-R2c refresh (n=5 → n=15;
  c'=0.02777 → 0.0288, 3.8% shift; n=5 fit confirmed at
  higher statistical confidence; binding constraint regime-
  migrates to FPR-floor at NARROW ε_A=4.0).
- **0.0.29** LL-019 high-res KS-test (regime-boundary
  finding — at α=0.01/n=2000 the verdict flips across runs
  from system jitter; LL-019 stays :benchmarked at the 0.0.19
  α=0.05/n=400 regime; CLAUDE.md gains §Benchmarking
  discipline rule for verdict-level determinism).
- **0.0.30** LL-003 N-scaling (linear extensive-chaos
  confirmed; asymptotic Lyapunov density s ≈ 0.255 per
  dimension at F=8; deployment-design rule N* ≈ Δh*/s).
- **0.0.31** LL-006 per-SDE detection-power (bound shape
  universal across candidate SDE set; combined with 0.0.25
  P3d gives a two-axis architectural argument for
  Lorenz-96).
- **0.0.32** LL-005 part-(a) parameter-validation test
  (entry stays :argued; conjunctive-claim discipline).

**Mode 2: Parallel-safe scaffolding while paused awaiting
upstream (0.0.33 → 0.0.38):**

- **0.0.26** P-OS scoping pass (LL-022 added :argued; downward
  trust-stack — what LavaLamp depends on from below).
- **0.0.33** LL-002 :tested via decoupled visual layer
  (visual/ HTML+JS bubble simulator; 45 decoupling-assertion
  tests make the LL-002 invariant executable on every commit).
- **0.0.34** P-PharOS scoping pass (LL-023 added :argued;
  upward trust-stack — what consumers depend on LavaLamp
  for; PharOS is canonical first instantiation).
- **0.0.35** Full A0-A6 cross-audit pre-round-3 (PASS
  post-fix; CLAUDE.md drift refreshed).
- **0.0.36** Lean 4 scaffold landed (`src/lean4/` lakefile
  + toolchain pin + theorem placeholder; lake build clean).
- **0.0.37** Lean 4 CI workflow (`lake build` on every push;
  mirrors Julia CI structure).
- **0.0.38** P-RS real-sensor scoping pass (LL-024 added
  :argued; Linux-first roadmap; scaffold module
  RealSensors.jl). LL-022 + LL-023 + LL-024 form the
  **deployment-stack triple** — three-layer commitment
  closing the scoping question on all three ends.

**Spec status now:** 24 entries / 3 `:tested` (LL-002, LL-004,
LL-007) / 4 `:benchmarked` (LL-003, LL-006, LL-019, LL-021) /
16 `:argued` (LL-001, LL-005, LL-008, LL-009, LL-010, LL-011,
LL-012, LL-013, LL-014, LL-016, LL-017, LL-018, LL-020,
LL-022, LL-023, LL-024) / 1 `:open` (LL-015). Test suite
202/202 in ~53s.

**Paper-side changes since round 2:**
**`[FILL: closure_forces_structure paper update — what changed in
the C-conjugate adversary structure / Q₅₁-tier identity claim /
0/5202 cross-sector autopoiesis result. Reading-list pointer to
the updated paper artifact.]`**

**Engine-side changes since round 2:**
**`[FILL: triadic-coordination-engine updates that landed —
spec changes, new theorems, scaling results, Zig kernel
status. Reading-list pointer to the engine repo's relevant
artifacts.]`**

Round 2's recommendation was `engage-and-formalise-after-fixes`.
Round 3's question: with the empirical and architectural work
landed, **do the load-bearing claims still cohere — and what
does the paper update revise?**

---

## §2 — Reading list (in priority order)

The minimum set for a round-3 review:

1. **Paper update**:
   **`[FILL: closure_forces_structure.tex / .pdf, focused on the
   C-conjugate / Q₅₁ / 0/5202 sections + any new sections.]`**
2. **`docs/synthesis_team_round2_companion.md`** — round-2
   dialogue arc + AI-integrator resolution. Round 3 builds on
   round 2's verdicts; the companion is the canonical reference
   for what was settled.
3. **`docs/audit_2026-05-04_full.md`** §9 — round-3 readiness
   checklist. Nine accumulated architectural inputs articulated
   explicitly; the reading list of LavaLamp-side companions
   per architectural input lives here.
3a. **`docs/threat_landscape_companion.md`** (0.0.41) —
   meta-architectural framing of the threat landscape the
   Triad Deployments occupy. Cockroach/catapult/castle/immune-
   system taxonomy; §2 maps threat classes; §3 maps where the
   Triad Deployments fit; §4 articulates load-bearing
   assumptions (8 named); §5 defense-in-depth complements
   across hardware/software/operational/strategic tiers; §6
   round-3 questions surfaced (LL-025 candidate plus six
   others). Required reading for the synthesis seat —
   reframes the entire Q1-Q7 / A1-A7 discussion in honest
   threat-tier terms.
4. **The deployment-stack triple companions:**
   - `docs/os_identity_security_scoping_companion.md` (LL-022;
     downward trust-stack).
   - `docs/pharos_scoping_companion.md` (LL-023; upward trust-
     stack).
   - `docs/p_real_sensor_scoping_companion.md` (LL-024;
     operational instantiation).
5. **The :benchmarked cohort companions:**
   - `docs/p3_bound_companion.md` (LL-006 isotropic).
   - `docs/ll021_benchmarked_companion.md` (LL-021 worst-case
     n=5 fit) + `docs/ll021_high_res_companion.md` (n=15
     refresh).
   - `docs/ll019_benchmarked_companion.md` (LL-019 timing
     n=400/α=0.05) + `docs/ll019_high_res_companion.md`
     (n=2000/α=0.01 regime-boundary finding).
   - `docs/ll020_strategy_2_benchmarked_companion.md` (LL-020
     Strategy 2 detection-power-vs-ε; variance-convolution σ
     refinement).
6. **Empirical refinement companions:**
   - `docs/p3d_sde_selection_companion.md` (Lorenz-96
     comparative bench).
   - `docs/p3e_n_scaling_companion.md` (linear extensive-chaos
     confirmed).
   - `docs/p3f_per_sde_detection_power_companion.md` (per-SDE
     detection-power; two-axis architectural argument).
7. **Diagnostic / discipline notes:**
   - `docs/audit_2026-05-04.md` (LL-020 Strategy 2 negative-
     result-then-fix arc; CLAUDE.md §Benchmarking discipline
     trigger).
   - `docs/ll005_part_a_companion.md` (conjunctive-claim
     discipline).
   - `docs/p3_nyq_companion.md` (LL-005 negative finding;
     round-3 architectural input).
8. **Engine update**:
   **`[FILL: triadic-coordination-engine relevant docs / spec
   diff since round 2.]`**
9. **`LAVALAMP_SPEC.md`** for current entry texts (24
   entries).

For deep dive: `src/julia/src/{Sensors.jl, Engine.jl,
Audit.jl, ChaosGuard.jl, RealSensors.jl}` and the test suite
in `src/julia/test/runtests.jl` (202 assertions). The Lean 4
scaffold at `src/lean4/` (theorem placeholder; sorry-stubs
land in round-3+ work). The decoupled visual layer at
`visual/` (LL-002 evidence; 45 decoupling-assertion tests).

---

## §3 — Synthesis-seat brief (Gemini)

You synthesised round 2's architecture and accepted the P-R2
trio + the round-2 :benchmarked cohort. Round 3 question:
**given the empirical and architectural work landed since
round 2, do the load-bearing claims still cohere — and what
does the paper update revise that should reshape LavaLamp's
spec?**

Six specific synthesis questions, drawn from the nine
accumulated architectural inputs (per
`audit_2026-05-04_full.md` §9):

### Q1 — Does the paper update revise the C-conjugate inheritance?

`docs/qkd_pqc_complementarity_companion.md` §2.5 grounds
LavaLamp's adversary model on the C-conjugate adversary
structure inherited from Closure v5's cross-sector autopoiesis
0/5202 result. The prototype realises this as: genuine system
has α; adversary has α + ε·û; spectrum gap δ_A > 0 by ∂λ/∂α
non-degeneracy. LL-021 (worst-case bound) sharpens the
claim by parameterising on direction projection.

**Question:** does the paper's revised treatment of the
C-conjugate adversary preserve the structural transfer to
LavaLamp, or does it require LL-001/LL-006/LL-018/LL-021 to be
restated?

**`[FILL: paper-specific framing — what changed in the
C-conjugate construction; how the structural-transfer
argument should be re-checked.]`**

### Q2 — Does the deployment-stack triple (LL-022 + LL-023 + LL-024) match the paper's closure-of-three framing?

Three Boundary/Operational entries close the deployment-stack
scoping on three ends: LL-022 downward (OS dependencies),
LL-023 upward (consumer-API), LL-024 operational instantiation
(real-sensor strategy). Aaron framed this as the closure-of-
three at the deployment-stack level — corpus-honest mirror of
the paper's three-element relational closures.

**Question:** is the deployment-stack triple's structure
faithful to the paper's closure semantics, or does it
under-claim / over-claim something at the spec level? If the
paper's three-element-closure formal definition would suggest
a fourth or different LL-ID grouping, name it.

### Q3 — LL-019 host-isolation regime-boundary: spec entry or sub-claim of LL-022?

The 0.0.29 LL-019 high-res refresh exposed a methodological
boundary: at α=0.01/n=2000 the timing-distribution KS test
loses statistical robustness on the prototype's dev host —
verdict flips across runs from system jitter alone. LL-019
stays :benchmarked at the 0.0.19 α=0.05/n=400 regime;
operational-significance is unaffected (median/mean differences
~10 μs on 100 ms padded operations).

**Question:** should "host-isolation threshold for timing-
based decorrelation guarantees" be a new spec entry (LL-025?)
or a sub-claim of LL-022 §Host-OS invariants? The CLAUDE.md
§Benchmarking discipline note (verdict-level determinism)
covers the methodology; what the spec needs is the
*operational* claim.

### Q4 — LL-005 adversary-side: which mechanism wins?

LL-005's two implicit sub-claims: (1) parameter compliance —
addressed at 0.0.32 via the nyquist_compliant predicate;
(2) adversary detection — answered NEGATIVE at 0.0.24
(P3-Nyq) because zero-mean noise has invariant time-averaged
statistics under sub-sampling. Sub-claim (2) requires a new
mechanism: LL-016 sensor authenticity (already :argued;
multi-sensor cross-validation, hardware attestation) or a
not-yet-implemented audit (FFT/PSD on trajectory; trajectory-
checkpoint comparison).

**Question:** which mechanism is round-3's recommended
adversary-side for LL-005? The trajectory-checkpoint approach
treats LavaLamp's identity as Q₁₀₂-tier (per the QKD/PQC
companion §2.6); the FFT/PSD approach is a separate algorithmic
addition. Are they substitutes or complements, and does the
paper update inform the choice?

### Q5 — Lean theorem priorities: which theorem first?

The Lean 4 scaffold (0.0.36) + CI (0.0.37) provides
buildable infrastructure. The `LavaLamp/Theorems.lean`
placeholder articulates six priority statements: LL-021
worst-case bound, LL-019 timing indistinguishability, LL-020
calibration ε-DP, LL-006/008/018 isotropic detection bound,
LL-022/023 parametric theorem-shapes. The Mathlib-or-not
architectural decision is round-3-driven (option A: full
Mathlib; option B: project-local minimal substitute; option C:
hybrid).

**Question:** which Lean priority ought to land first, and
what's the right Mathlib decision? The triadic-coordination-
engine project uses option B (project-local Category typeclass);
LavaLamp's claims are probability/real-analysis-flavoured, which
points option A more. But option A has multi-minute build
times and ecosystem-version risk.

### Q6 — N-scaling deployment rule: what's the production target?

The 0.0.30 LL-003 N-scaling benchmark established
`s ≈ 0.255` per dimension at F=8 (asymptotic Lyapunov density;
saturated by N≥80). Deployment-design rule: `N* ≈ Δh*/s` for
target chaos-production margin Δh*. Compute scales as O(N³)
per integration step; per-spectrum wall clock is 25 s at
N=160.

**Question:** what's the production-target Δh* for the Triad
Deployments? Lazarus / LavaLamp / PharOS imply different
margin requirements (consumer-product Lazarus ≠ OS-auth
PharOS). What's the round-3 sense of where each lands on the
N axis, and does the paper update suggest the asymptotic
density is itself an invariant we should formalise?

### Q7 — A7 / EMF / LL-025: should physical-emanation scoping land as a new spec entry?

The current spec has six adversary classes (A1-A6 from
`attack_surface_enumeration.md` §2). All six implicitly assume
the adversary observes the device through some software /
I/O surface — A4 (side-channel / physical proximity) is the
closest to physical-layer threats but in current usage means
*software-side timing channels* (LL-019 hardening) and
*sensor manipulation* (LL-016 authenticity strategies).

**The gap:** an **A7-class** adversary — *passive-emanation
interceptor* — passively monitors RF / acoustic / power-line
emanations from the substrate hardware and in principle
reconstructs SDE state without any software access. If the
trajectory is recoverable from substrate emanations, **the
substrate-bound-identity claim is bypassed at the physical
layer** — not by attacking the audit / TPM / sensors /
verifier, but by reading the trajectory directly through the
substrate's electromagnetic skin.

The structural problem: LL-022 + LL-023 + LL-024 form the
deployment-stack triple but all live *above* the OS
abstraction. A7 lives *below* the OS, in the physical
substrate itself.

**Three architectural options:**

(a) **New Boundary entry LL-025** — physical-emanation-
adversary-boundary. Parallel shape to LL-015 (A3 OOS) and
LL-022 (downward trust-stack). Articulates required
deployment context (Faraday-rated enclosure / TEMPEST hardware
/ distance + interior rooms / EMI-filtered power / shielded
cables) for LavaLamp's primitive-tier claim to hold; A7 OOS
outside those bounds. Same honest-bounded-claim framing as
LL-005 Nyquist + LL-018 per-class quantification.

(b) **Sub-claim of LL-022 + sub-class of A4** — fold into
existing entries. Cheaper but blurs the architectural
distinction (A4 software-channel vs A7 physical-channel are
structurally distinct adversary capabilities).

(c) **Defer to deployment-time documentation** — leave the
spec untouched; document mitigation guidance separately.
Honest only if A7 is provably outside any plausible threat
model for LavaLamp's intended deployments.

**Question:** which option is load-bearing? If the deployment-
stack triple LL-022 + LL-023 + LL-024 needs to extend to a
quartet (+ LL-025), does the closure-of-three philosophy
survive? If yes, *how* — does LL-025 form a parallel triadic
structure with LL-015 + LL-024 (boundary triple covering the
substrate)? Does the paper update inform the right framing?

A candidate **P-EMF scoping pass** (analogous to P-OS /
P-PharOS / P-RS shape) would land LL-025 + a scoping companion
mirroring `os_identity_security_scoping_companion.md`. The
question is whether to do this *before* round-3-driven
implementation work or whether round-3 itself should produce
the scoping. Synthesis seat's call.

---

## §4 — Edge-witness-seat brief (Grok)

You stress-tested round 2's architecture and produced
V-011/012/013 (Reseed Oracle, Calibration Spectrum Leakage,
Structured α-Direction Attack). Round 3 question: **given the
empirical refinement work since round 2 and the deployment-
stack triple, what new attack vectors emerge from the broader
architecture, and does the paper update reveal vectors the
prototype hadn't enumerated?**

Six specific stress-test questions:

### A1 — LL-019 host-isolation: real-world adversary or methodological artifact?

The 0.0.29 high-res refresh found verdict instability at
α=0.01/n=2000 — KS_stat fluctuates ~0.04 across runs from
system jitter. **Operationally**, the channel is
microscopic (median/mean differences ~10 μs on 100 ms padded
ops; ratio 1e-4); an adversary extracting information needs
extraordinary sample sizes.

**Question:** is the host-isolation regime-boundary a real
adversary-exploitable channel that the prototype's
deployment must mitigate (e.g., on shared cloud VMs where
jitter is adversary-influenced), or a methodological artifact
of the dev-host measurement environment? If the former, what
deployment-config rules close the gap? If the latter, the
spec's :benchmarked-at-0.0.19-regime framing is honest.

### A2 — LL-024 real-sensor authenticity: hairdryer attack realistic?

LL-024 §2.4 commits to LL-016 strategy 2 (multi-sensor
cross-validation) as the prototype-tier default — thermal +
battery discharge rate; AC + measured current; mic +
accelerometer. V-006 (sensor manipulation) lists the hairdryer
attack on thermal as the canonical example.

**Question:** is the cross-validation pattern *actually*
sufficient against a determined V-006 adversary, or are there
sensor combinations where coordinated manipulation defeats
the cross-check? Specifically: a charge controller + heater
pair could spoof both AC and thermal coherently. What's the
attack-vector enumeration looking like in the post-LL-024
landscape?

### A3 — Deployment-stack triple: hidden non-conformance attack?

LL-022 + LL-023 + LL-024 close scoping on three ends. PharOS
conforms to LL-023; LavaLamp conforms to LL-022; the
real-sensor module conforms to LL-024. **But:** what about a
*partial-conformance* PharOS? An adversary controlling
PharOS's internals could conform to LL-023's API surface
while violating LL-022's required mechanisms (e.g., bypass
the host TRNG by reusing cached randomness).

**Question:** does the deployment-stack triple commit
LavaLamp to *checking* consumer conformance at runtime, or
is conformance a deployment-time configuration trust? If
the latter, what attack vectors does that open up?

### A4 — Linear-coupling adversary: still linearisable post-LL-021?

Round 2 §1C-A6 raised linearisability — if the *coupling* to
sensors is linear (`U = α·s·⟨b,x⟩`), an adversary builds a
linear model and matches α via least-squares. LL-021's
worst-case bound at 0.0.18/0.0.28 sharpens the claim
parametrically (`ε_eff = ε_A · proj(û onto m_unit)`).

**Question:** does the LL-021 sharpening *actually* close
A6, or does it just rebound the worst-case at the same
linear-model attack? The 0.0.31 per-SDE benchmark showed
the bound shape is universal across SDE candidates (Lorenz-
96 / Lorenz-63 / Rössler) — does the bound preserve under
linear-model adversary, or does the per-SDE c′ collapse for
some SDE that's "easier to linearise"?

### A5 — N-scaling: large-N attractor shape changes attack surface?

The 0.0.30 N-scaling benchmark validated linear extensive-
chaos `h_KS ≈ s·N` at F=8 across N ∈ {20, 40, 80, 160}.
Compute scales O(N³). At N=160 the per-spectrum cost is 25 s.

**Question:** does the *attractor topology* change at large
N in ways that open new attack vectors? Specifically: at
N=160 the attractor has ~52 positive Lyapunov exponents and
~108 KY dimensions. Are there attack vectors that exploit
this high-dimensional structure (e.g., perturbations along
the most-stable directions that reduce the spectrum gap)?
The 0.0.18/0.0.28 LL-021 work was at N=20; does the
worst-case bound generalise to N=160?

### A6 — Paper revisions: net new attack vectors?

The closure_forces_structure paper update may revise the
C-conjugate adversary structure or surface new structural
content.

**Question:** **`[FILL: paper-specific stress questions —
what attack-vector enumeration does the paper's revised
treatment imply? Are V-011/012/013 still adequate? Are
there new V-NNN candidates the paper's framing surfaces?]`**

### A7 — A7 / V-014: is passive-emanation reconstruction realistic?

Surfaced 2026-05-05 (post-skeleton). Modern TEMPEST-class
research has demonstrated:
- Cryptographic key extraction from acoustic emanations
  (Genkin et al. 2014, RSA from CPU acoustic side-channel).
- Memory state recovery from EM side-channels (RowHammer-
  via-EMF papers; DDR3/DDR4 reads from radiated RAM bus).
- CPU register state under specific attack-controlled
  conditions (e.g., ROP-style controlled execution + EM
  capture).
- van Eck phreaking on modern displays at varying ranges.

For LavaLamp specifically: the SDE solver runs on a CPU; the
trajectory state lives in registers + memory; integration
steps emanate at the pipeline's clock rate. The question is
whether full or partial trajectory reconstruction is feasible
at modern multi-GHz CPU speeds (where emanations are noisy +
fast) or whether the noise floor + decode complexity bound
A7 to specific narrow attacks.

**Question:** what's the realistic A7 capability tier at
the prototype's deployment context?
- **Close-proximity-state-actor-only** (sub-meter range; bespoke
  TEMPEST equipment; targeted device): if so, A7 is in the
  threat model but only for high-stakes deployments (not
  consumer-product Lazarus; possibly OS-auth PharOS in
  high-assurance contexts).
- **Mid-tier** (across-the-room SDR equipment; commercial
  hardware): broader threat surface; LL-025 should be a
  primary architectural commitment.
- **Wide-spread** (everyday adversary; ambient passive
  capture): would force a reconsideration of LavaLamp's
  hardware-platform-choice; might invalidate consumer-laptop
  deployment.

Is V-014 (passive-emanation reconstruction of SDE trajectory)
a real attack vector worth enumerating, or a theoretical
concern that doesn't make it into the practical threat model?
What does the literature say about substrate emanation at
multi-GHz CPU speeds — recoverable trajectory bits per second
at distance D vs LavaLamp's chaos-production rate `h_KS · N`?

**Round-3 deliverable for edge-witness:** if A7 is real, name
the deployment-context bounds (distance, equipment tier,
threat model) under which LavaLamp's primitive-tier claim
*does* hold; outside those bounds, the claim doesn't hold and
LL-025 should articulate that boundary explicitly.

---

## §5 — Response format request

Following round-2's dialogue norm, both seats:

1. **Seven-point evaluation per seat.** One bullet per question
   in your section (Q1-Q7 for synthesis; A1-A7 for
   edge-witness). Each bullet: short answer + reasoning + any
   pointer to a corpus reference, paper section, or formal
   source. ~80-120 words per bullet.
2. **Cumulative verdict.**
   - Synthesis seat: `engage-and-formalise` /
     `engage-and-formalise-after-fixes` /
     `redirect-to-X` / `obstruct`. If `obstruct`, name the
     structural barrier; if `redirect`, name where to.
   - Edge-witness seat: `pass` / `pass-after-fixes` / `fail`
     with named attack vector.
3. **Net new attack vectors / blindspots.** If you surface
   anything that V-001..V-013 didn't cover, name it with a
   provisional V-NNN tag (we'll allocate the actual numbers
   on integration).
4. **Lean / proof-track suggestions.** Round 3 has the Lean 4
   scaffold landed (0.0.36) + CI (0.0.37) — name the theorem
   statement that should land first, with the Mathlib-or-not
   call (per Q5).
5. **Paper-update integration.** If the paper update implies
   spec changes (new LL-IDs; existing-entry refinements;
   evidence-type promotions), name them. The paper is the
   load-bearing input for round 3's distinct value over
   round 2.

Length cap: **2800 words per seat** (was 2000 in round 2 — the
deployment-stack triple + Lean scaffold + paper integration +
the post-skeleton EMF / A7 question add material; we want
substance not bulk but the surface is broader).

---

## §6 — Followups (after dialogue lands)

1. **`docs/synthesis_team_round3_companion.md`** — written
   *after* the dialogue, capturing the full arc. Mirrors
   round-1 / round-2 companion shapes.
2. **Spec impact.** Round 3 may surface new spec entries
   (LL-025..) for paper-revised content or for new attack
   vectors; existing entries may need refinement post-paper.
   Process: companion lands first, spec/registry/dashboard
   updates land in a separate commit per CLAUDE.md "small /
   large session" discipline.
3. **Decision point.** Round-3 verdicts of
   `engage-and-formalise` (with or without fixes) keep the
   project on the current path — next sub-task is the highest-
   leverage Lean priority (per Q5) plus Phase 1 Linux
   real-sensor implementation (per LL-024 §2.5 roadmap).
   Verdicts of `redirect` or `obstruct` send us back to
   architecture work before more code.
4. **Phase 1 real-sensor implementation.** Per the
   `docs/p_real_sensor_scoping_companion.md` §2.5 roadmap,
   ~1 week of focused dev work post-round-3. The Phase 1
   commit lands the actual Linux sysfs/procfs FFI; LL-024
   moves `:argued` → `:tested` (with possible `:benchmarked`
   follow-up via real-hardware SNR characterisation).
5. **First Lean theorem implementation.** Per Q5's verdict,
   land the highest-priority theorem statement (with `sorry`
   first, then proof). The chosen theorem moves from comment-
   block placeholder to actual `theorem` declaration; the
   corresponding LL entry's evidence type moves to
   `lean-proved` and status to `:proved` only when the proof
   is `sorry`-free.

---

**Aaron's instructions to forward:** copy-paste §1 + §2 + §3
to Gemini; copy-paste §1 + §2 + §4 to Grok. Both seats receive
§5. §6 is internal — stays here. Run them in either order, or
in parallel; the round-3 reviews are independent of each
other (same convention as round 2).

---

## Internal note: skeleton status at 0.0.40

This brief is at **skeleton tier**. Substantively complete:
- §1 (LavaLamp side; paper / engine paragraphs blank)
- §2 (LavaLamp companions cited; paper / engine entries
  blank)
- §3 Q1-Q7 (LavaLamp-derived; Q1 has paper-specific blank;
  Q3/Q4 are answer-pending pending paper insight; Q7 added
  2026-05-05 covering EMF / A7 / LL-025 gap)
- §4 A1-A7 (LavaLamp-derived; A6 is paper-specific blank;
  A7 added 2026-05-05 covering passive-emanation V-014
  candidate)
- §5 (response format; updated to seven-point evaluation;
  word cap 2500 → 2800)
- §6 (followups; complete)

When the closure_forces_structure paper update lands and
round-3 actually triggers, the **`[FILL: ...]`** blanks
get filled in with paper-side content (~30-60 minutes of
focused work post-trigger), then the brief gets forwarded to
Gemini and Grok per §Aaron's instructions.

The skeleton's value: round-3 trigger response time drops from
"several hours of brief composition" to "fill in the paper-
specific blanks then forward." Pre-trigger preparation that's
parallel-safe to the round-3-blocked content (C-conjugate /
Q₅₁ / 0/5202 specifics live in the paper, not the brief
skeleton).

**0.0.40 update note:** Q7 + A7 add ~1500 words covering the
EMF / passive-emanation gap surfaced in conversation
2026-05-05. The Triadic Watchmen (Lazarus / LavaLamp /
PharOS) cover the software stack but miss the physical-
emanation layer; A7 is the candidate new adversary class and
LL-025 is the candidate new Boundary entry. Round-3
synthesis + edge-witness seats are positioned to weigh in on
whether this is a load-bearing spec addition (option a:
new entry; option b: sub-claim of LL-022; option c: defer to
deployment-time documentation). The closure-of-three
philosophy may need to extend to closure-of-four at the
deployment-stack level — or LL-025 may form a parallel
boundary triple with LL-015 + LL-024 covering the substrate.
The synthesis seat's Q7 framing surfaces both options.
