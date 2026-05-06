# Synthesis-Team Round 3 Brief — LavaLamp (Synthesis Seat / Gemini)

**Forwarded:** 2026-05-06.

This is your seat's payload — synthesis seat — corresponding to
§1 + §2 + §3 + §5 of the full brief at
`docs/synthesis_team_round3_brief.md`. Edge-witness seat (Grok)
receives a parallel payload with §4 substituted for §3.

You synthesised round 2's architecture and accepted the P-R2
trio + the round-2 :benchmarked cohort. Round 3 question:
**given the empirical and architectural work landed since round
2, do the load-bearing claims still cohere — and what does the
paper update revise that should reshape LavaLamp's spec?**

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
- **0.0.36** Lean 4 scaffold landed (`src/lean4/` lakefile +
  toolchain pin + theorem placeholder; lake build clean).
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

**Paper-side status since round 2:**

The `closure_forces_structure` paper is at **v1.0
(2026-04-01 release tag)** — *"Closure Forces Structure: The
Standard Model from Rosen Closure on Ternary Causal
Hypergraphs"* (Aaron Green, April 2026). The paper has been
canonically published since round 2; what's new for round 3
is **stability-of-corpus**, not paper revisions. LavaLamp
inherits structural priors from a settled v1.0 paper rather
than a moving target.

The LavaLamp-relevant content lives at three section
clusters:

1. **§10.5 The C-Closure and Q_48** — formal definition of
   the C-closure operation: `Q_C = Q ∪ C(Q)` where `C(Q)`
   is the charge-conjugate copy. `Q_48 = Q_24 ∪ C(Q_24)`
   has 48 vertices, **zero overlap between original and
   conjugate sectors**, perfect fixed-point-free real
   structure `J`. This is the formal mathematical operation
   behind LavaLamp's "C-conjugate adversary inheritance"
   claim — an adversary that structurally co-occurs with the
   genuine system (lives in `C(Q)`) is sector-disjoint from
   the genuine.
2. **§11.13 The Self-Reproducing Fixed Point** — `Q_102 =
   Q_51 ∪ C(Q_51)` is a self-reproducing fixed point under
   DPO composition: **all 420 composition products map back
   to existing Q_102 vertices (100%)**, depth-independent
   at depths 2-4 (Theorem S130). Quote: *"The daughter IS
   the parent. Q_102 does not produce offspring that inherit
   its properties; it produces itself."* This is the
   structural anchor for LavaLamp's substrate-bound identity
   (LL-001) — identity is the ongoing pattern of self-
   reproduction, not a stored credential.
3. **§13.6 Evidence Classification and Honest Framing** —
   5 evidence types: `proof` (deductive from axioms — 130
   entries), `algebraic` (symbolic computation = proof),
   `standard` (established results invoked), `catlab` (CatLab
   machine proofs — 9 entries), `computational` (numerical
   simulation — 21 entries; reported as "verified" not
   "proved"). **Quote: *"A Julia computation using
   `Rational{BigInt}` is a proof; the same computation
   using `Float64` is evidence."* — this is exactly the same
   honest-framing discipline LavaLamp's evidence taxonomy
   articulates** (lean-proved / type-checked / algebraic /
   property-tested / example-tested / benchmarked / manual /
   none) per CLAUDE.md §Evidence types.

The 0/5202 cross-sector autopoiesis result referenced in
LavaLamp's `qkd_pqc_complementarity_companion.md` §2.5 lives
in the Closure v5 corpus's `catlab_spec.jl` (not in the
paper itself); the paper's §11.13 self-reproducing-fixed-
point theorem provides the structural reason for the
empirical 0/5202 result — `Q_102` is closed under
composition + C-closure + quotient *from within itself*; an
adversary attempting cross-sector autopoiesis would need
elements from `C(Q_51)` to autopoise elements of `Q_51`,
which §11.13 forbids structurally.

The paper also articulates a **three-layer logical structure**
(§1.2): Possibilistic Layer (forced/forbidden/compatible —
LavaLamp's adversary model lives here), Probabilistic Layer
(Born rule + Gleason — measurement), Bridge Layer (NCG-derived
unconditional). LavaLamp's claims should be reviewed for which
layer they sit in; the resolution-bounded security claim
(LL-008) is Possibilistic-Layer (cost-asymmetry; what's
*forbidden* under the constraint surface), per the
`threat_landscape_companion.md` §2.7 cost-asymmetry framing.

**Numerical-threshold note (§13.6 Remark):** at threshold
`0.999`, spurious merges occur for ~5% (Q_48) to ~12% (Q_102)
of Haar-random initial conditions; at threshold `1 − 10⁻¹²`,
200/200 seeds give the canonical vertex counts. This maps
directly onto LavaLamp's residue-audit threshold-calibration
discipline (LL-014) — the threshold is *numerical
convenience*, not part of the mathematical definition.

**Engine-side status since round 2:**

The triadic-coordination-engine landed at **v0.2.2 on
2026-05-05**. The architectural arc (v0.1.13 → v0.2.0 →
v0.2.1 → v0.2.2) extracted a **corpus-agnostic discovery
primitive** `Discovery.Triadic.findTriadicClosures` from what
was previously a closure-v5-specific implementation. The
primitive consumes a `DiscoveryCorpus n` record (fields:
`dcAnchors`, `dcRelated`, `dcTripleValid`, `dcScore`,
`dcCollapsed`) and returns ranked triadic candidates over
any node type. Two corpus clients exist:
`closureV5Corpus` (similarity-based; run end-to-end on the
v167+2 corpus producing 240,745 candidates) and
`businessEntityCorpus` (directed-graph cycles; the original
smoke-fixture pipeline now routed through the engine). Eight
QuickCheck invariant properties on randomly-generated
`DiscoveryCorpus Int` lift the engine's structural claims to
`:verified`. Spec at 51 entries (13 `:proved` / 24 `:tested`
/ 6 `:verified` / 3 `:benchmarked` / 5 `:open`); ~96 assertions
across five cabal test suites, all green.

**The engine is now a generic primitive available to any
deployment that can supply a corpus adapter — including
LavaLamp.** Has Discovery.Triadic been run against
LavaLamp's spec or repo? **No.** That would require writing
a `lavaLampCorpus :: <inputs> → DiscoveryCorpus n` adapter
with domain-specific definitions for `dcRelated`,
`dcTripleValid`, `dcScore`, `dcCollapsed`, plus a decision
on what `n` should be (LL-NNN spec IDs? V-NNN candidates?
sensor events? threat-vector primitives?). Future-session
work; not gating round-3.

**Which deployment gets engine work next:** *deferred, not
decided.* Aaron's session-close framing on 2026-05-05 was
*"moving the engine to triadic deployments to assist that
project"* — singular framing but no named deployment. Memory
note `project_engine_redirect_to_triad.md` records this with
explicit "ask on resume" instruction. Round-3 should treat
the engine as available to all three deployments (Lazarus /
LavaLamp / PharOS) without specific assignment; the
deployment selection is a post-round-3 architectural decision.

Round 2's recommendation was `engage-and-formalise-after-fixes`.
Round 3's question: with the empirical and architectural work
landed, **do the load-bearing claims still cohere — and what
does the paper update revise?**

---

## §2 — Reading list (in priority order)

The minimum set for a round-3 review:

1. **Paper (v1.0, 2026-04-01)** — public release.
   LavaLamp-relevant sections: **§1.2** (three-layer logic
   structure: Possibilistic / Probabilistic / Bridge);
   **§10.5** (C-closure operation `Q_C = Q ∪ C(Q)`); **§10.6**
   (CCM classification → B1 derivation; anomaly cancellation);
   **§11** (Q_102 spectral triple; gauge-spacetime unification);
   **§11.3** (discrete Coleman-Mandula theorem); **§11.13**
   (self-reproducing fixed point — *the daughter IS the
   parent*); **§13.6** (evidence classification — same
   framing as LavaLamp's honest-framing discipline).
2. **`synthesis_team_round2_companion.md`** — round-2
   dialogue arc + AI-integrator resolution. Round 3 builds
   on round 2's verdicts.
3. **`audit_2026-05-04_full.md`** §9 — round-3 readiness
   checklist; nine accumulated architectural inputs.
3a. **`threat_landscape_companion.md`** (0.0.41-0.0.42) —
   meta-architectural framing of the threat landscape the
   Triad Deployments occupy. **Required reading.**
   Cockroach/catapult/castle/immune-system taxonomy + §2.6/§2.7
   metabolic-value / predator-prey ecology axis. §2 maps
   threat classes; §3 maps where the Triad Deployments fit;
   §4 articulates load-bearing assumptions (8 named); §5
   defense-in-depth complements; §6 round-3 questions
   surfaced (LL-025 candidate plus seven others including the
   cost-asymmetry-as-explicit-claim framing); §7 lessons
   including symbiosis-as-equilibrium-not-victory. Reframes
   the entire Q1-Q7 discussion in honest threat-tier terms.
4. **The deployment-stack triple companions:**
   `os_identity_security_scoping_companion.md` (LL-022;
   downward trust-stack); `pharos_scoping_companion.md`
   (LL-023; upward trust-stack);
   `p_real_sensor_scoping_companion.md` (LL-024; operational
   instantiation).
5. **The :benchmarked cohort companions:**
   `p3_bound_companion.md` (LL-006 isotropic);
   `ll021_benchmarked_companion.md` + `ll021_high_res_companion.md`;
   `ll019_benchmarked_companion.md` + `ll019_high_res_companion.md`;
   `ll020_strategy_2_benchmarked_companion.md`.
6. **Empirical refinement companions:**
   `p3d_sde_selection_companion.md`; `p3e_n_scaling_companion.md`;
   `p3f_per_sde_detection_power_companion.md`.
7. **Diagnostic / discipline notes:**
   `audit_2026-05-04.md` (LL-020 Strategy 2 negative-result-
   then-fix); `ll005_part_a_companion.md`
   (conjunctive-claim discipline); `p3_nyq_companion.md`
   (LL-005 negative finding).
8. **Engine update (TCE v0.2.2, 2026-05-05)** — engine repo's
   `dashboard.md` (Discovery engine architecture v0.2.1
   section); `ENGINE_SPEC.md` S-047 through S-051;
   `docs/discovery_refactor_companion.md` (with v0.2.1
   addendum); `changelog.md` v0.2.0/0.2.1/0.2.2 entries. For
   deep dive: `src/haskell/Discovery/Triadic.hs` (~120 lines)
   + `src/haskell/SpecBridge.hs` (closure-v5 adapter; template
   for what `lavaLampCorpus` would look like).
9. **`LAVALAMP_SPEC.md`** for current entry texts (24
   entries).

---

## §3 — Synthesis-seat brief

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

**Question (revised post-paper-read):** the paper at v1.0
2026-04-01 articulates the C-closure as a *fully-derived
structural operation* (§10.5 Definition C-closure: `Q_C =
Q ∪ C(Q)`), with the conjugate sector being charge-
conjugated and zero-overlap with the original. LavaLamp's
"C-conjugate adversary" claim transfers this structural
disjointness to the security setting: an adversary that
co-occurs structurally with the genuine system lives in the
conjugate sector and is autopoietically disjoint per §11.13's
self-reproducing-fixed-point theorem.

**Is the structural-transfer argument load-bearing or
aesthetic?** Specifically:

(a) The paper's §10.5 C-closure is defined for *charge-
conjugate* sectors of a hypergraph spectral triple. LavaLamp's
adversary is in *coupling-strength α-space*, not a charge-
conjugate sector in the paper's formal sense. Is the
"C-conjugate" terminology in `qkd_pqc_complementarity_companion.md`
§2.5 a structural inheritance or a vocabulary borrow? If the
former, what's the precise functor / construction that maps
α-space adversaries to the paper's `C(Q)` sector? If the
latter, what's the right corpus-faithful framing for
LavaLamp's structural-mimic adversary?

(b) The paper's §11.13 quote *"the daughter IS the parent"*
is the strongest possible autopoiesis statement: `Q_102` is
its own fixed point. LavaLamp's substrate-bound identity
(LL-001) claims the SDE trajectory is the device's identity.
Is this the *same* claim transposed (the trajectory IS the
device — substrate identity = ongoing autopoietic activity)?
Or a weaker analog (the trajectory tags the device, but the
device persists across trajectory restarts)? The chaos-guard
reseed flow (LL-007) deliberately restarts the trajectory
when λ̂_1 < τ_λ — does this break the "daughter IS the
parent" claim or instantiate it (re-establishing self-
reproduction at each chaos-guard re-cohering event)?

(c) The 0/5202 result is empirical evidence at threshold
0.999; per §13.6's numerical-threshold remark, that
threshold's spurious-merge rate is ~12% on Haar-random ICs.
Is the 0/5202 result robust under the tighter threshold
1 − 10⁻¹² that gives 200/200 canonical-vertex-count seeds?
LL-006's residue audit operates on Lyapunov spectra, not on
hypergraph fidelities — what's the analog of "tighter
numerical threshold" in LavaLamp's spectrum-residue setting?

The synthesis seat's call: which of (a)/(b)/(c) is the
load-bearing inheritance, which is aesthetic vocabulary, and
which is empirical-evidence-at-prototype's-threshold? The
honest framing for round-3 should distinguish.

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
based decorrelation guarantees" be a new spec entry or a
sub-claim of LL-022 §Host-OS invariants? The CLAUDE.md
§Benchmarking discipline note (verdict-level determinism)
covers the methodology; what the spec needs is the
*operational* claim. (Note: LL-025 is now reserved for the
A7 EMF candidate per Q7 below; if a host-isolation entry is
warranted, it would be LL-025+ or LL-026.)

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

## §5 — Response format request

Following round-2's dialogue norm:

1. **Seven-point evaluation.** One bullet per question
   (Q1-Q7). Each bullet: short answer + reasoning + any
   pointer to a corpus reference, paper section, or formal
   source. ~80-120 words per bullet.
2. **Cumulative verdict.** `engage-and-formalise` /
   `engage-and-formalise-after-fixes` /
   `redirect-to-X` / `obstruct`. If `obstruct`, name the
   structural barrier; if `redirect`, name where to.
3. **Net new attack vectors / blindspots.** If you surface
   anything that V-001..V-014 didn't cover, name it with a
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

Length cap: **2800 words** (was 2000 in round 2 — the
deployment-stack triple + Lean scaffold + paper integration +
the post-skeleton EMF / A7 question add material; we want
substance not bulk but the surface is broader).
