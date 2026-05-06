# Synthesis-Team Round 3 Companion — 2026-05-06

Permanent record of the third round of synthesis-seat +
edge-witness-seat review on LavaLamp. Round 3 ran a **seat
rotation** from rounds 1 and 2: Gemini (round-2 synthesis)
was struggling on the round-3 task and stepped out; Grok
rotated from edge-witness to synthesis; ChatGPT joined as
new edge-witness entrant.

Captures the dialogue, the contrast between the two seats,
and the metabolic synthesis (proposed integration plan
pending Aaron's instantiator confirmation) ahead of the
spec-change implementation pass.

The forward-brief is at
`docs/synthesis_team_round3_brief.md`. Per-seat split files
were `docs/round3_for_grok.md` (synthesis-seat payload) and
`docs/round3_for_chatgpt.md` (edge-witness-seat payload),
forwarded by Aaron with three supporting documents
(`docs/threat_landscape_companion.md`,
`docs/synthesis_team_round2_companion.md`, public link to
the closure_forces_structure paper v1.0 release tag). Engine
repo kept private at Aaron's direction; engine deep-dive
references in brief §2 item 8 left unfollowable.

Responses arrived sequentially — Grok first, ChatGPT second.
This companion captures both plus Aaron's pending resolution.

---

## §1 — The dialogue arc

### §1A — Aaron's brief (forwarded)

`docs/synthesis_team_round3_brief.md` summarised what
changed since round 2 (eighteen versions across 0.0.20 →
0.0.44 spanning two distinct work modes — empirical
refinement of the round-2 :benchmarked cohort, then
parallel-safe scaffolding while paused awaiting upstream),
pointed at the reading set in priority order, and posed
seven questions per seat:

- **Synthesis (Grok):** Q1 paper §10.5/§11.13 C-conjugate
  inheritance load-bearing-ness, Q2 deployment-stack triple
  vs paper closure-of-three, Q3 LL-019 host-isolation
  framing, Q4 LL-005 adversary-side mechanism, Q5 Lean
  theorem priorities + Mathlib decision, Q6 N-scaling
  production target, Q7 A7 / EMF / LL-025 spec-entry status.
- **Edge-witness (ChatGPT):** A1-A7 mirroring the synthesis
  questions but rendered adversarially.

Both seats received §5 response-format requests (numbered
evaluations, cumulative verdict, V-NNN net-new vectors, Lean
theorem suggestions, paper-update integration; 2800-word cap
per seat — up from 2000 in round 2 to accommodate paper-
update integration, EMF/A7, and the deployment-stack triple).

**Seat-rotation context.** The round-3 brief preambles
acknowledged the rotation explicitly: Grok preamble noted
his round-2 edge-witness work (V-011/012/013 attribution),
his rotation to synthesis, and Gemini's round-2 baseline
verdict; ChatGPT preamble onboarded the new entrant with a
pointer to `synthesis_team_round2_companion.md` as primary
context for what edge-witness has been doing on this project.

### §1B — Grok synthesis seat (response)

Verdict: **`engage-and-formalise-after-fixes`** — verdict
trajectory continuous with Grok's round-2 edge-witness
`pass-after-fixes` and Gemini's round-2 synthesis
`engage-and-formalise-after-fixes`. The seat-rotation did
not flip the assessment; the architecture's load-bearing
claims cohere from the synthesis lens.

Grok engaged each Q1-Q7 directly. Faithful summary below
preserves the load-bearing claims and direct quotes from the
response.

#### Q1 → C-conjugate inheritance: vocabulary borrow, not direct functor

Grok confirmed paper §10.5 + §11.13 inheritance with
qualifications. Direct quote: *"LavaLamp's 'C-conjugate
adversary' (α-space mimic with spectrum gap) is therefore a
**vocabulary borrow**, not a direct functor."*

Load-bearing claims that survive paper-update scrutiny:

- (b) **LL-001 substrate-bound identity inherits the strong
  reading** — *"the SDE trajectory IS the device (ongoing
  autopoiesis)"* per paper §11.13 *"the daughter IS the
  parent."* Identity = self-reproduction, not stored
  credential.
- (c) **LL-007 chaos-guard reseed instantiates Q102
  self-reproduction** — re-establishes self-reproduction
  when divergence-amplification crosses the audit threshold.

Aesthetic-only (no load-bearing inheritance):

- (a) C-conjugate adversary framing — analog vocabulary,
  not direct category-theoretic functor.

Numerical-threshold-tier observation: 0/5202 result at
threshold 0.999 has ~12% spurious-merge rate per §13.6;
LL-006 already operates at tighter Lyapunov-vector level
(k=5 with n_trials=10 maps to the analog of paper's
1−10⁻¹² discipline).

#### Q2 → Deployment-stack triple is faithful mirror of paper closure-of-three

Grok confirmed LL-022 + LL-023 + LL-024 mirrors paper
Theorem 3.1 + §4 three-role / three-element closure: each
LL-ID closes one dependency direction exactly as the paper's
F/A/S roles close efficient causation. Direct quote: *"No
fourth LL-ID is forced; the triple is the minimal closed
set at the deployment-stack scale."*

Universality theorem (§9.1) extends to any adhesive DPO
category satisfying the representability hypothesis; the
deployment-stack triple satisfies it by construction.
Verdict: **corpus-faithful.**

#### Q3 → LL-019 host-isolation: methodological artifact (sub-claim of LL-022)

Grok read the 0.0.29 high-res regime-boundary as a
methodological artifact of the dev-host environment. Median/
mean differences ~10 μs on 100 ms ops (ratio 1e-4) below
practical adversary sample-size budgets. Direct quote:
*"Operational claim belongs as a sub-claim of LL-022 §Host-OS
invariants ('dev-host jitter must not exceed production-host
jitter by >2× median')."*

CLAUDE.md §Benchmarking discipline already enforces verdict-
level determinism. **No new LL-ID required.**

(NB: edge-witness §1C.A1 disagrees — see ChatGPT's
multi-tenant counter-claim.)

#### Q4 → LL-005: trajectory-checkpoint comparison (not FFT/PSD)

Grok picked trajectory-checkpoint comparison as the LL-005
adversary-side mechanism. Direct quote: *"Trajectory-
checkpoint comparison (Q₁₀₂-tier identity per QKD/PQC
companion §2.6) is the winner."* FFT/PSD ruled out as
duplicative of LL-016 sensor-authenticity cross-validation.

Three-layer mapping (paper §1.2): LL-005 parameter-compliance
sub-claim is **Possibilistic-layer** (forced by
nyquist_compliant predicate); adversary detection is
**Bridge-layer** (deployment protocol). Trajectory-checkpoint
directly implements paper's "daughter IS the parent" self-
reproduction at the audit layer.

#### Q5 → Lean priority: LL-021 worst-case bound + Mathlib option A

Grok prioritised LL-021 worst-case bound as the first
theorem to land. Direct quote: *"probability/real-analysis
flavour; directly benefits from Mathlib's measure theory +
probability libraries."* Option A (full Mathlib) is the right
call because LavaLamp's claims are measure-theoretic (Born-
rule analog, ε-DP envelopes, isotropic bounds); the engine
project's option-B minimalism does not generalise.

Theorem statement proposed:

```
theorem ll021_worst_case_bound (ε_A : ℝ) (proj : ℝ) :
  ε_eff ≤ ε_A * proj ∧ ε_eff ≥ 0 := by ...
```

Subsequent: LL-019 timing indistinguishability (KS-test
formalisation) and LL-020 ε-DP envelope.

(NB: edge-witness §1C.A6-Lean disagrees — ChatGPT proposed
a different first theorem and option B custom local library.
This is a clean architectural divergence that requires
Aaron's instantiator decision; see §1D.vi decision 1.)

#### Q6 → N-scaling: Δh* = 8.0 PharOS / 4.0 Lazarus + new LL-026 chaos-density invariant

Grok proposed deployment-tier-differentiated production
targets:
- **PharOS (OS-auth):** Δh* = 8.0 (conservative).
- **Lazarus (consumer-product):** Δh* = 4.0 sufficient.

Compute-cost framing: at N=160 the per-spectrum cost is 25 s
— acceptable for PharOS; Lazarus can drop to N=80 (Δh* = 4.0)
which preserves real-time verification feasibility.

**New spec entry proposed: LL-026 — asymptotic Lyapunov
density `s ≈ 0.255` per dimension is deployment-invariant.**
This promotes the 0.0.30 N-scaling result from a deployment-
design rule (already in P3e companion) into a spec-level
invariant claim. Paper update reinforces universality across
SDE candidates (paper §10.1-10.2).

(NB: edge-witness §1C.A5 surfaces a counter-concern about
large-N attractor topology that Grok did not engage; LL-021
generalisation across N is open.)

#### Q7 → A7 / V-014 / LL-025: load-bearing parallel boundary triple

Grok rendered LL-025 as **load-bearing**, forming a parallel
boundary triple with LL-015 (A3 OOS) + LL-024 (substrate
instantiation). Direct quote: *"A7 is exactly the
'virus/cancer injection under our nose' defeat condition of
the cockroach/catapult metaphor (threat_landscape_companion
§2.4)."*

Honest-bounded-claim discipline applies exactly as LL-005
Nyquist + LL-018 per-class quantification — the entry should
articulate boundary tiers explicitly.

(NB: edge-witness §1C.A7 sharpens this with three explicit
adversary tiers — state actor / mid-tier / commodity. The
two responses are complementary rather than divergent.)

#### Grok cumulative deliverables

- **Verdict:** `engage-and-formalise-after-fixes`.
- **Spec changes proposed (4):** LL-008 cost-asymmetry
  footer, new LL-025 (A7 Boundary), LL-018 layer-tagging,
  new LL-026 (asymptotic chaos density invariant).
- **Net new V-NNN confirmed (3):** V-015 cross-sector
  autopoiesis spoofing, V-016 numerical-threshold
  calibration gaming, V-017 three-layer logical-tier
  confusion. All paper-derived (§11.13 + §13.6 + §1.2).
- **Lean target:** LL-021 worst-case bound first; Mathlib
  option A; LL-019 + LL-020 sequenced after.
- **Evidence-type promotion path:** LL-006 / 021 / 019
  move from `:benchmarked` to `:lean-proved` once theorems
  land.

### §1C — ChatGPT edge-witness seat (response)

Verdict: **`pass-after-fixes`** — verdict trajectory
continuous with Grok's round-2 edge-witness verdict; the
seat-rotation preserved the edge-witness verdict-class even
across a fresh entrant.

ChatGPT engaged each A1-A7 directly and surfaced **five new
attack vectors** beyond Grok's V-015/016/017 (the brief's
three paper-derived candidates). Faithful summary below
preserves the load-bearing claims and direct quotes.

Bottom-line framing from ChatGPT: *"Your system is strongest
at the structural level — and weakest at the interface
layers where structure meets reality. That's exactly where
the remaining attack surface lives."*

#### A1 → LL-019: BOTH artifact AND real adversary channel

ChatGPT split the LL-019 framing — *both* dev-host artifact
*and* shared-env adversary channel. Direct quote:
*"microscopic signals can be amplified statistically. Your
current regime (α=0.05/n=400) is honest for prototype-tier,
but **not composable under hostile scheduling**."*

Mitigation requirement: dedicated core / constant-time
padding / jitter randomization in shared-environment
deployments.

This **directly contradicts Grok §1B.Q3's "no new LL-ID
required"** position. Resolution path (proposed): keep LL-019
as standalone entry rather than demote to LL-022 sub-claim;
expand its text to cover both regimes (dev-host vs
multi-tenant); add the deployment constraint as a notes
amendment.

#### A2 → LL-024: insufficient against coordinated multi-channel adversaries — V-018

ChatGPT identified LL-016 Strategy 2's hidden assumption:
*"The cross-validation model assumes independent noise
sources, but a determined adversary can couple channels
physically."*

Coupled-attack examples named:
- heater → thermal + battery discharge correlation
- load injector → AC draw + thermal rise
- vibration motor → mic + accelerometer coherence

Framed as **sensor-fusion-inversion attack**: *"attacker
injects signals that satisfy constraints rather than violate
them."*

**New attack vector V-018 — Coordinated Multi-Sensor
Synthesis.** Defense gap named: **entropy-provenance
diversity** — different *physical mechanisms*, not just
different sensors. This is a sharper concept than cross-
sensor cross-validation; it demands the noise sources
*originate from physically uncorrelated phenomena*.

#### A3 → Deployment-stack triple: partial-conformance vector — V-019

ChatGPT confirmed the brief's hypothesis: partial-conformance
attack is real and currently under-specified. Direct quote:
*"system satisfies API but violates invariants internally."*

Examples:
- cached randomness reused while reporting fresh entropy
- bypassed TRNG with deterministic replay
- forged "sensor fusion" outputs upstream

**Equivalent to type-level vs semantic conformance
mismatch.** Defense gap: *"runtime invariant verification is
missing."*

**New attack vector V-019 — Runtime Conformance Bypass.**

#### A4 → LL-021: containment bound, not closure of A6

ChatGPT's sharpest synthesis: the per-SDE universality
result (0.0.31) **inverts the meaning** of the LL-021 bound.
Direct quote: *"if all SDEs share the same bound shape,
attacker needs only one successful model."*

What we read as corpus-faithful (universal bound shape) the
edge-witness reads as universal attack surface. Concrete
adversary path:
1. Adversary learns projection directions via regression.
2. Reconstructs coupling coefficients.
3. Reduces problem to system identification.

LL-021 reframed as **containment bound**, not A6-closure.
Vulnerability persists under **adaptive linear modeling**.

(This does not invalidate LL-021; it demands the bound be
stated against an *adaptive* adversary, not a static one.)

#### A5 → N-scaling: large-N opens new attack geometry — V-020

ChatGPT engaged the brief's A5 hypothesis directly. At
N=160 (52 unstable / 108 stable directions), three new
attack mechanisms:

1. **Stable-direction injection attack** — perturb along
   strongly contracting modes; minimal spectral impact.
2. **Manifold shadowing attack** — remain near attractor
   while diverging in unobserved subspace.
3. **Spectral gap flattening** — high-dimensional attractors
   reduce distinguishability margins.

LL-021 was validated at N=20; at N=160 the curvature of
attractor manifold, mixing times, and detectability
thresholds all change. Direct quote: *"LL-021 likely does
not generalize without re-benchmarking."*

**New attack vector V-020 — Stable-Manifold Stealth
Injection.** New attack class: **high-dimensional stealth
perturbation**.

#### A6 → V-015/016/017 confirmed; V-021/022 added

ChatGPT confirmed all three brief-proposed paper-derived
vectors and added two more:

- **V-015 (cross-sector autopoiesis spoofing):** confirmed
  real and not fully covered. Sharpened: *"detection of
  partial trajectories is not guaranteed"* — LL-007 (λ
  collapse) triggers only on full divergence, not early-
  stage. Analog of prefix-valid cryptographic forgery.
- **V-016 (numerical-threshold calibration gaming):**
  confirmed real and **directly mapped**. Sharp claim:
  *"The paper's 5–12% spurious merge region maps almost
  exactly to LL-014 FPR baseline (~10%). This is not
  coincidence — it is the same phenomenon in different
  language: threshold ≠ structure."*
- **V-017 (logical-tier confusion):** confirmed *"very real
  and dangerous."* Meta-attack: apply probabilistic
  reasoning to possibilistic claims; exploit guarantee-type
  mismatch. Example given: *"LL-008 claims forbidden region;
  adversary reframes as low probability. This breaks
  security proofs at the reasoning layer."*

**New attack vector V-021 — Prefix-Trajectory Mimicry.**
Sharpening of V-015 mechanism (early-stage trajectory
mimicry before divergence triggers detection). Proposed
disposition: merge into V-015 as the attack-mechanism axis;
keep V-015 as the umbrella vector ID.

**New attack vector V-022 — Threshold Equivalence Exploit.**
Sharpening of V-016 — exploits equivalence between
statistical FPR and structural merge ambiguity. Proposed
disposition: merge into V-016 as the same insight in
different language; keep V-016 as the umbrella vector ID.

#### A7 → V-014 EMF: real but tier-bounded

ChatGPT confirmed V-014 as real but offered explicit tier
scoping:

- **Tier 1 — State actor (sub-meter, lab equipment):**
  partial leakage feasible; targeted reconstruction possible.
- **Tier 2 — Mid-tier (room-scale SDR):** signal extraction
  possible; full reconstruction unlikely.
- **Tier 3 — Commodity adversary:** negligible capability.

Direct quote: *"V-014 is real but bounded: should be
explicitly scoped, not universalized."*

Combined with Grok §1B.Q7 "load-bearing parallel boundary
triple": both seats agree LL-025 lands; ChatGPT's tier-
bounding sharpens the entry text rather than contradicting
Grok's load-bearing framing. The combined synthesis is
**stronger than either alone**.

#### ChatGPT cumulative deliverables

- **Verdict:** `pass-after-fixes`. Reason: *"Core
  architecture still holds under adversarial scrutiny, but
  four non-trivial gaps remain: partial-conformance runtime
  gap (A3), coordinated sensor spoofing (A2), large-N
  topology attack surface (A5), threshold equivalence
  (V-016)."*
- **Net new V-NNN (5):** V-018 Coordinated Multi-Sensor
  Synthesis, V-019 Runtime Conformance Bypass, V-020
  Stable-Manifold Stealth Injection, V-021 Prefix-Trajectory
  Mimicry, V-022 Threshold Equivalence Exploit.
- **Spec changes proposed:** new LL-025 (Logical-layer
  tagging — note ID conflict with Grok's LL-025 for A7);
  LL-014 strengthen (numerical-threshold non-fundamentality);
  LL-021 explicit scope-limit (finite-N regime); new LL-026
  (Runtime conformance verification — note ID conflict with
  Grok's LL-026 for chaos density); new LL-027 (Multi-channel
  entropy independence).
- **Lean target:** **Closure Detection Soundness theorem**
  formalising LL-007 / LL-014 / LL-021 interplay; **Mathlib
  option B** (custom local library; *"custom dynamical
  systems + spectral theory needed; Mathlib lacks"*).

### §1D — Aaron's resolution (proposed; instantiator decision)

This subsection captures the AI integrator's reading of the
combined seat responses; flagged as proposed pending Aaron's
instantiator confirmation. Three decision points are open
(see §1D.vi); the metabolic synthesis below proceeds on
provisional default answers but must be revised against
Aaron's call before any spec or implementation work lands.

#### §1D.i — Honest assessment of the round

- **Both seats engaged substantively.** Unlike round 2
  (where Gemini's synthesis response was thin and Grok's
  edge-witness response carried the round's substance),
  round 3 had two substantive responses. The seat rotation
  worked.
- **Verdicts complementary, not contradictory.** Grok
  (synthesis) `engage-and-formalise-after-fixes`; ChatGPT
  (edge-witness) `pass-after-fixes`. Neither says fail. The
  difference is lens: synthesis sees the cohering pattern +
  structural extensions; edge-witness sees the gaps where
  structure meets implementation.
- **Verdict-rotation invariant.** The round-3 verdicts
  match the round-2 verdicts (Grok's `pass-after-fixes`
  edge-witness; Gemini's `engage-and-formalise-after-fixes`
  synthesis) even though the seats rotated. Independent
  verdicts from different seat-occupants converge on the
  same assessment-class — robust signal.
- **Combined verdict:** `engage-and-formalise-after-fixes`
  with **four named composability gaps** (partial-
  conformance, coordinated sensor-spoofing, large-N
  topology, threshold equivalence) requiring engineering
  responses. Round 3's findings are tractable — they grow
  the spec from 24 to 29 entries but do not require a
  fundamental redesign.

#### §1D.ii — New attack vectors landed in spec (proposed)

Nine V-NNN candidates surfaced across rounds 1+2+3. After
deduplication (V-021 → V-015 mechanism axis; V-022 → V-016
language axis — see §1D.vi decision 2):

- **V-014 — Passive-emanation reconstruction (TEMPEST).**
  Already allocated 0.0.40. Tier-bounded per ChatGPT A7.
- **V-015 — Cross-sector autopoiesis spoofing** (paper-
  derived, both seats).
- **V-016 — Numerical-threshold calibration gaming**
  (paper-derived, both seats; same phenomenon as LL-014 FPR
  baseline per ChatGPT A6).
- **V-017 — Three-layer logical-tier confusion** (paper-
  derived, both seats).
- **V-018 — Coordinated Multi-Sensor Synthesis** (ChatGPT
  A2; defeats LL-016 Strategy 2's independent-noise
  assumption).
- **V-019 — Runtime Conformance Bypass** (ChatGPT A3;
  interface-level satisfaction with invariant violation).
- **V-020 — Stable-Manifold Stealth Injection** (ChatGPT
  A5; large-N attack class; LL-021 doesn't generalise from
  N=20).

**Net: 7 new V-IDs (V-014 through V-020).** V-021 and V-022
absorbed as sharpening axes of V-015 / V-016 respectively.

#### §1D.iii — New spec entries (proposed; clean LL-NNN allocation)

Resolving the Grok/ChatGPT LL-NNN ID conflicts using paper-
tier and edge-witness-tier separation:

- **LL-025 — A7 / passive-emanation Boundary.** Both seats
  confirm load-bearing. Tier-bounded explicitly per ChatGPT
  (state actor / mid-tier / commodity); load-bearing
  parallel-boundary-triple framing per Grok (LL-015 +
  LL-024 + LL-025). Status: `:argued`. Logic tier: Boundary.
- **LL-026 — Three-layer logic-tier annotation discipline.**
  Possibilistic / Probabilistic / Bridge per paper §1.2.
  Both seats surface (Grok via LL-018 amendment; ChatGPT
  via "LL-025 logical-layer tagging"); cleaner as a fresh
  spec-level discipline entry. Status: `:argued`. Logic
  tier: Core (governance).
- **LL-027 — Asymptotic Lyapunov density invariant.**
  Grok proposal. `s ≈ 0.255` per dimension is deployment-
  invariant; formalises the 0.0.30 N-scaling result. Status:
  `:benchmarked` (the 0.0.30 result *is* the benchmark
  evidence). Logic tier: Core.
- **LL-028 — Runtime conformance verification.** ChatGPT
  proposal. Interface-level satisfaction insufficient;
  invariant-level enforcement required. Defends V-019.
  Status: `:argued`. Logic tier: Boundary.
- **LL-029 — Multi-channel entropy independence.** ChatGPT
  proposal. Physical-mechanism diversity (not just sensor
  diversity). Defends V-018. Status: `:argued`. Logic tier:
  Operational.

Spec growth: **24 → 29 entries.**

#### §1D.iv — Notes amendments on existing entries (proposed)

- **LL-008** — *Cost-asymmetry footer.* Append explicit
  framing: *"LavaLamp's resolution-bounded security claim
  is cost-asymmetry: attacking this device costs more than
  the result is worth relative to easier targets
  (threat_landscape_companion §2.7)."* (Grok)
- **LL-014** — *Numerical-threshold non-fundamentality tie.*
  Add explicit annotation that the 10% FPR baseline and
  paper §13.6's 5-12% spurious-merge zone are **the same
  phenomenon in different language**. Threshold is
  calibration convenience, not structure. (ChatGPT)
- **LL-019** — *Deployment-context framing.* Expand text to
  cover both regimes: dev-host artifact vs multi-tenant
  shared-environment real channel. Add deployment constraint
  for shared-env: dedicated core / constant-time padding /
  jitter randomization. (ChatGPT — supersedes Grok's "no
  new LL-ID required" position; LL-019 stays as standalone
  entry rather than collapsing into LL-022 sub-claim.)
- **LL-021** — *Explicit scope-limit + adaptive-adversary
  amendment.* Two-pronged:
  1. Scope-limit text: bound stated for **finite-N regime
     (N ≤ 80)**; large-N regime requires re-benchmarking.
     (ChatGPT A5)
  2. Adaptive-adversary amendment: bound must be stated
     against an *adaptive* linear-model adversary, not a
     static one. The 0.0.31 per-SDE universality result
     means *one* successful linear model defeats the bound
     for all SDEs in the candidate set; this is a structural
     consequence, not a contingent one. (ChatGPT A4)

#### §1D.v — Lean target updates (rendered 2026-05-06)

**Decision rendered (2026-05-06): Option A — LL-021 worst-
case bound, Mathlib full.** First theorem:

```
theorem ll021_worst_case_bound
  (ε_A : ℝ) (proj : ℝ) (h_proj : 0 ≤ proj ∧ proj ≤ 1) :
  ∀ adversary, ε_eff adversary ≤ ε_A * proj := ...
```

Subsequent theorems: LL-019 KS-test (timing
indistinguishability) → LL-020 ε-DP envelope. Theorem 2 is
**Closure Detection Soundness** over LL-007 + LL-014 +
LL-021 interplay (originally ChatGPT's option B); the
dynamical-systems machinery built for theorem 2 amortizes
across subsequent theorems.

Original alternatives preserved for record:

1. **(Chosen — Grok)** LL-021 worst-case bound. Mathlib
   option A (full Mathlib). Probability/measure-theoretic
   flavour.
2. **(Deferred to theorem 2 — ChatGPT)** Closure Detection
   Soundness over LL-007 + LL-014 + LL-021 interplay.
   Originally proposed with Mathlib option B (custom local
   library); now lands as theorem 2 atop theorem 1's Mathlib
   environment, with custom DS-machinery introduced as
   needed.

**Reasoning.** Mathlib's measure theory + probability
libraries are mature; Option A's first-theorem cost is low.
Option B's custom DS-machinery is a multi-session research
investment before the first theorem lands; landing it as
theorem 2 instead lets the proof track demonstrate viability
sooner. The engine project's option-B precedent (project-
local Category typeclass; no Mathlib) was for category
theory, not measure theory — different ecosystem maturity.
ChatGPT's adaptive-adversary critique (A4) lands in spec
text via the LL-021 amendment in Tier 2; the Lean theorem
proves the bound shape, with the spec articulating what the
bound does and doesn't close.

#### §1D.vi — Decision points (rendered 2026-05-06)

Aaron rendered all three decisions on 2026-05-06 in the
order `2 → 3 → 1` (V-merge first, sequencing second, Lean
third — dependency-ordered: decision 2 affects V-NNN list
size for Tier 1; decision 3 sets implementation order;
decision 1 only blocks Tier 2). Original framings preserved;
rendered calls follow each.

1. **Lean first theorem + Mathlib option.** LL-021 worst-
   case bound (Grok, Mathlib A) vs. Closure Detection
   Soundness (ChatGPT, Mathlib B). Picks the Lean ecosystem
   for round 3 onward.
   - **Decision rendered: Option A** — LL-021 worst-case
     bound, Mathlib full. Theorem 2 will be Closure
     Detection Soundness atop theorem 1's environment. See
     §1D.v for theorem statement target and reasoning.

2. **V-021 / V-022 disposition.** Merge into V-015 / V-016
   (cleaner spec; integrator default) vs. keep separate
   (preserves edge-witness attribution; sharper attack
   taxonomy).
   - **Decision rendered: Merge.** V-021 absorbs into V-015
     as the attack-mechanism axis (early-stage prefix mimicry
     before LL-007 reseed); V-022 absorbs into V-016 as the
     language axis (LL-014's 10% FPR ≡ paper §13.6's 5-12%
     spurious-merge zone). Full ChatGPT framings preserved
     in §1C.A6 with attribution; merge keeps the V-NNN
     roster clean without losing information. **Net new
     V-IDs after merge: 7** (V-014 through V-020).

3. **Sequencing across the five new LL-IDs.** Default tiers
   below; Aaron may reorder.
   - **Decision rendered: Confirm default.** Tier 1 → Tier 2
     → Tier 3 as proposed in §1D.vii. Internal ordering
     within each tier specified in §1D.vii (rendered
     version).

#### §1D.vii — Sequencing recommendation (rendered 2026-05-06)

**Tier 1 — Consensus / framing fixes (one version bump,
likely 0.0.45).** Internal ordering:

1. `attack_surface_enumeration.md` — V-014..V-020 enumerated
   (attack vectors first because they motivate the new
   LL-IDs).
2. `LAVALAMP_SPEC.md` — LL-025 (A7 Boundary) + LL-026
   (logic-tier annotation discipline) + LL-008 cost-
   asymmetry footer.
3. `artifact_registry.md` — new rows for LL-025 / LL-026.
4. `dashboard.md` — status update (24 → 26 entries; 7 with
   evidence; 19 `:argued`).
5. `changelog.md` — versioned entry.
6. README count refresh.
7. Single commit, push.

Low engineering cost; both seats converge.

**Tier 2 — Paper-grounded spec evolution (one version bump,
likely 0.0.46) paired with first Lean theorem.** Internal
ordering:

1. `LAVALAMP_SPEC.md` — LL-027 (asymptotic chaos density
   invariant) + LL-021 scope-limit + adaptive-adversary
   amendment + LL-014 numerical-threshold non-fundamentality
   tie.
2. First Lean theorem landed in `src/lean4/` (LL-021 worst-
   case bound; Mathlib option A per §1D.v).
3. `artifact_registry.md` — LL-027 row + LL-021 evidence-
   type promotion to `:lean-proved` once theorem builds.
4. `dashboard.md` + `changelog.md` + README + commit + push.

Paper §13.6 + §10.1-10.2 + §1.2 -derived claims.

**Tier 3 — Engineering / composability gaps (multiple
version bumps).** Sequenced by P-RS prototype availability
and PharOS scope.

1. LL-028 (runtime conformance verification) — engineering.
2. LL-029 (multi-channel entropy independence) —
   engineering.
3. LL-019 deployment-context expansion — engineering.
4. P-RS Level 2 prototype implementation.

Real engineering work; per-entry version bumps as
engineering completes.

#### §1D.viii — Decision: integrate before next prototype slice

Round 3's findings displace some of the previously-planned
work:

- **Defer P-RS Level 2 prototype implementation** until
  Tier 1 + Tier 2 spec changes land. The deployment-stack
  triple (LL-022 + LL-023 + LL-024) was scoped in 0.0.26 /
  0.0.34 / 0.0.38 against round-2 architecture; round-3
  surfaced LL-025 + LL-028 + LL-029 which sit in the same
  conformance/operational layer. Implementing P-RS before
  these land would require re-design.
- **Promote: round-3 spec integration pass.** Tier 1 first
  (single version bump; consensus changes); Tier 2 next
  (paper-grounded; can pair with first Lean theorem); Tier 3
  sequenced by engineering availability.
- **Round 4 trigger:** after Tier 1 + Tier 2 land *and* the
  first Lean theorem is type-checked. Not after Tier 3 —
  Tier 3 is engineering execution, not architecture-design
  work that needs synthesis-team review.

---

## §2 — Round-3 architectural state (post-metabolism, pre-resolution)

The architecture's load-bearing claims after round 3
metabolism (provisional; subject to §1D.vi decisions):

| Layer | Claim | Status |
|---|---|---|
| Substrate-bound identity | Identity = sustained chaotic trajectory on the device | **Strengthened** — paper §11.13 self-reproducing-fixed-point provides structural anchor (LL-001) |
| Resolution-bounded security | S_production > S_measurement | **Reframed** — explicit cost-asymmetry footer per LL-008 amendment |
| Visual ↔ security decoupling | Visual driven by independent RNG | Affirmed (LL-002 `:tested`) |
| Multi-scale Lyapunov audit | Vector per-exponent residue test | Affirmed; LL-014 numerical-threshold non-fundamentality tied to paper §13.6 |
| Linear-in-x coupling | Sensor enters as constant gradient ∇_x U | Limitation noted (LL-004); adaptive-adversary scope added (LL-021) |
| Reseed timing observability | Constant-time response required | Affirmed (LL-019); deployment-context framing expanded |
| Calibration confidentiality | Registered envelope sealed against observers | Affirmed (LL-020) |
| Worst-case adversary direction | Detection bound stated against minimum-δ_A direction | **Scope-limited** — finite-N regime only (LL-021); adaptive-adversary amendment |
| Deployment-stack triple | Closure-of-three at deployment-stack scale | Affirmed (LL-022 + LL-023 + LL-024); paper §3 + §4 corpus-faithful |
| Passive-emanation boundary | TEMPEST-class A7 attacks are tier-bounded | **New** (LL-025 proposed); parallel boundary triple with LL-015 + LL-024 |
| Three-layer logic-tier discipline | Possibilistic / Probabilistic / Bridge annotation per claim | **New** (LL-026 proposed); paper §1.2-derived |
| Asymptotic chaos density | `s ≈ 0.255` per dimension is deployment-invariant | **New** (LL-027 proposed); 0.0.30-benchmarked |
| Runtime conformance | Interface-level satisfaction insufficient; invariant verification required | **New** (LL-028 proposed); defends V-019 |
| Multi-channel entropy independence | Physical-mechanism diversity, not just sensor diversity | **New** (LL-029 proposed); defends V-018 |
| Stable-manifold stealth | Large-N attractor topology opens new attack class | **Open** (V-020); LL-021 generalisation across N is open task |

---

## §3 — Verification status

This companion documents a *metabolic synthesis* — neither
seat's response is itself test data; the integration plan
above is *manually argued* per CLAUDE.md §Evidence types.

For each new spec entry destined for the spec:

- **LL-025 (A7 Boundary):** *Manually argued.* Both seats
  confirm load-bearing. Status `:argued`. Verification path:
  scoping companion (mirror P-OS / P-PharOS / P-RS shape).
- **LL-026 (logic-tier annotation):** *Manually argued.*
  Paper §1.2 is the structural source. Status `:argued`.
  Verification path: spec-level governance discipline; no
  test artifact required (annotation is a documentation
  practice).
- **LL-027 (chaos density invariant):** *Benchmarked.* The
  0.0.30 N-scaling benchmark *is* the verification evidence;
  the linear extensive-chaos fit at four N values gives
  `s ≈ 0.255` with statistical confidence. Status
  `:benchmarked`. Logic tier: Core.
- **LL-028 (runtime conformance):** *Manually argued.* No
  test artifact yet. Status `:argued`. Verification path:
  P-RS Level 2 prototype must include conformance-check
  module.
- **LL-029 (multi-channel entropy independence):** *Manually
  argued.* No test artifact yet. Status `:argued`.
  Verification path: P-RS Level 2 sensor architecture must
  enumerate physical-mechanism families.

For amendments to existing entries (LL-008 / LL-014 / LL-019
/ LL-021): documentation changes only; do not alter status
columns of those entries. The amendments are *clarifications*,
not new evidence.

---

## §4 — Spec impact

Per CLAUDE.md companion-doc standard §4. Five new spec
entries proposed:

| S-ID | Key | Logic tier | Evidence type | Status | Depends_on |
|---|---|---|---|---|---|
| LL-025 | A7 passive-emanation Boundary | Boundary | manual | `:argued` | LL-015, LL-022, LL-024 |
| LL-026 | Logic-tier annotation discipline | Core (governance) | manual | `:argued` | (paper §1.2) |
| LL-027 | Asymptotic chaos density invariant | Core | benchmarked | `:benchmarked` | LL-003 |
| LL-028 | Runtime conformance verification | Boundary | manual | `:argued` | LL-022, LL-023, LL-024 |
| LL-029 | Multi-channel entropy independence | Operational | manual | `:argued` | LL-016, LL-024 |

Registry status (`:in-design`, `:in-test`, `:in-bench`,
`:open`): all five enter as **`:in-design`** pending Tier 1
/ Tier 2 implementation pass.

Plus four amendments to existing entries (LL-008 / LL-014 /
LL-019 / LL-021) — not new entries, do not require new
registry rows.

V-NNN allocations: V-014 already in
`attack_surface_enumeration.md`; V-015 through V-020 to be
added (six new entries) in Tier 1 implementation pass.

---

## §5 — Process notes

- **Seat rotation worked.** Grok's transition from edge-
  witness to synthesis preserved the verdict-rotation
  invariant; ChatGPT's onboarding as new edge-witness
  entrant landed substantive A1-A7 engagement on first pass.
  Memory note: keep both rotations available as protocol
  options for round 4+ if circumstances warrant.
- **Forwarding context discipline.** The 3-files-plus-link
  recipe (per-seat brief + threat_landscape_companion +
  round-2 companion + paper public link) gave both seats
  sufficient context. ChatGPT explicitly drew on round-2
  companion for orientation.
- **LL-NNN ID conflict at allocation time.** Both seats
  proposed "LL-025" and "LL-026" with different content.
  Resolution required the integrator to assign to paper-
  derived (LL-025/026) vs operational (LL-028/029) tiers.
  Process note: future briefs should explicitly request
  seats to *not* allocate LL-NNN IDs, only propose entry
  *content*; integrator allocates IDs at metabolism time.
- **Mathlib divergence is real.** Grok's option A (full
  Mathlib for measure-theoretic LL-021) and ChatGPT's
  option B (custom local for dynamical-systems first
  theorem) reflect different first-theorem choices, not
  arbitrary preferences. Decision is architectural; defer
  to Aaron.
- **Verbatim-reproduction discipline.** Round-3 responses
  preserved as direct quotes in §1B / §1C rather than
  paraphrased. This companion is the authoritative record;
  the source responses themselves are ephemeral chat
  context.

---

## §6 — Followups

- **Companion files referenced above must exist.** Verify:
  `threat_landscape_companion.md` ✓ (0.0.41-0.0.42),
  `synthesis_team_round2_companion.md` ✓ (0.0.12),
  `synthesis_team_round3_brief.md` ✓ (0.0.39 → 0.0.44).
  All exist in `git ls-files`.
- **Aaron's resolution.** Three open decisions per §1D.vi.
  After Aaron's call, this companion's §1D should be
  amended in-place (not replaced) with the actual decisions
  rendered.
- **Tier 1 implementation pass.** Once decisions are
  rendered, sequence: (1) `attack_surface_enumeration.md`
  V-015..V-020 enumeration; (2) `LAVALAMP_SPEC.md` LL-025
  + LL-026 + LL-008 footer; (3) `artifact_registry.md` rows;
  (4) `dashboard.md` status update; (5) `changelog.md` entry;
  (6) version bump (likely 0.0.45). Single commit.
- **Tier 2 implementation pass.** Sequencing: (1) LL-027 +
  LL-021 scope-limit + LL-014 amendment in spec; (2) registry
  rows updated; (3) first Lean theorem landed (per decision
  1); (4) version bump. May be one or two commits depending
  on Lean-theorem readiness.
- **Tier 3 implementation pass.** Engineering availability;
  P-RS Level 2 prototype scope.
