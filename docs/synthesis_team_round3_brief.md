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

**Update 2026-05-05 (0.0.43):** Paper-side blanks filled.
The `closure_forces_structure` paper at **v1.0 2026-04-01**
is canonical and settled; what's new for round-3 is corpus-
stability, not paper revisions. The fill captures three
load-bearing section clusters in the paper (§10.5 C-Closure
operation; §11.13 Self-Reproducing Fixed Point —
*"the daughter IS the parent"*; §13.6 Evidence Classification
— same honest-framing discipline as LavaLamp's CLAUDE.md
§Evidence types) and surfaces three V-NNN candidates from
the paper's framing (cross-sector autopoiesis spoofing;
numerical-threshold calibration gaming; three-layer logical-
tier confusion).

**Update 2026-05-05 (0.0.44):** Engine-side blanks filled.
The triadic-coordination-engine landed at v0.2.2 on
2026-05-05; corpus-agnostic `Discovery.Triadic` primitive
extracted; closure-v5 + BusinessEntity corpus clients
verified; 8 QuickCheck invariant properties. Has
Discovery.Triadic been run against LavaLamp specifically?
**No** — would require writing a `lavaLampCorpus` adapter
(future-session work). Specific-deployment-next decision
deferred per memory note. **V-NNN tag collision rationalized:**
§4 A7 EMF V-014 (added 0.0.40, came first) keeps V-014;
§4 A6 paper-derived candidates renumbered to V-015 (cross-
sector), V-016 (threshold gaming), V-017 (three-layer
confusion). Brief now substantively complete on both paper
+ engine sides; ready to forward to Gemini + Grok.

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

Round 2's recommendation was `engage-and-formalise-after-fixes`.
Round 3's question: with the empirical and architectural work
landed, **do the load-bearing claims still cohere — and what
does the paper update revise?**

---

## §2 — Reading list (in priority order)

The minimum set for a round-3 review:

1. **Paper (v1.0, 2026-04-01)**:
   - Source `.tex`: `/Users/aarongreen/Library/Mobile Documents/com~apple~CloudDocs/Desktop/paper/closure_forces_structure.tex`
   - Public release: `/Users/aarongreen/Desktop/paper/closure_forces_structure.pdf` (tagged `v1.0-2026-04-01`).
   - LavaLamp-relevant sections: **§1.2** (three-layer logic
     structure: Possibilistic / Probabilistic / Bridge);
     **§10.5** (C-closure operation `Q_C = Q ∪ C(Q)`); **§10.6**
     (CCM classification → B1 derivation; anomaly cancellation);
     **§11** (Q_102 spectral triple; gauge-spacetime unification);
     **§11.3** (discrete Coleman-Mandula theorem); **§11.13**
     (self-reproducing fixed point — *the daughter IS the
     parent*); **§13.6** (evidence classification — same
     framing as LavaLamp's CLAUDE.md §Evidence types).
   - The 0/5202 cross-sector autopoiesis result lives in
     Closure v5's `catlab_spec.jl` (not in this paper); the
     paper's §11.13 provides the structural reason.
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
8. **Engine update (v0.2.2, 2026-05-05)** —
   triadic-coordination-engine repository at
   `/Users/aarongreen/Desktop/triadic-coordination-engine/`.
   Reading priority:
   - `dashboard.md` — section *"Discovery engine architecture
     (v0.2.1)"* — current-state entry point.
   - `ENGINE_SPEC.md` — sections **S-047 through S-051**
     specifically. S-047 is the type-checked engine primitive
     (`discovery-triadic-engine-primitive`); S-048 is the
     corpus-agnostic property (`discovery-triadic-corpus-
     agnostic`); S-049 is the triple-validity predicate;
     S-050 is the BusinessEntity-through-engine routing;
     S-051 is the property-tested invariant set.
   - `docs/discovery_refactor_companion.md` — large-session
     companion with §1 computational basis, §2 results, §4
     spec impact. v0.2.1 addendum at the end covers the
     second-corpus-client work.
   - `changelog.md` — v0.2.0, v0.2.1, v0.2.2 entries (top of
     file).
   For deep dive (technical audience):
   `src/haskell/Discovery/Triadic.hs` (~120 lines; the actual
   engine; doc-block at top has the conventions) and
   `src/haskell/SpecBridge.hs` (closure-v5 adapter; useful as
   the template for what `lavaLampCorpus` would look like
   when written).
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

**Question (revised post-paper-read):** with the paper at
v1.0 2026-04-01 settled and LavaLamp inheriting from a
canonical published corpus, what attack vectors does the
paper's framing imply that V-001..V-013 don't capture?

Three candidate V-NNN entries the paper surfaces (numbered to
avoid collision with §4 A7's V-014 EMF candidate):

(a) **V-015 — Cross-sector autopoiesis spoofing.** The 0/5202
empirical result (Closure v5 `catlab_spec.jl` Thm_Q51_autopoietic)
shows cross-sector autopoiesis fails at threshold 0.999. **But
the result is a *negative* — the adversary's autopoietic
attempt fails; can the residue audit *detect* the failed
attempt?** LavaLamp's chaos-guard responds to λ̂_1 collapsing
(LL-007); does it respond to a *partial* autopoiesis attempt
that produces some genuine-looking trajectory before
diverging? This is the analog of V-005 (slow-drift threshold
gaming) at the autopoietic-tier rather than the spectrum-tier.

(b) **V-016 — Numerical-threshold calibration gaming.** The
paper's §13.6 remark says spurious merges occur 5%-12% at
threshold 0.999; LL-014 (threshold calibration) sets per-
exponent τ_i = 3·σ(λ̂_i | T) baseline. Can an adversary
craft a trajectory that lies in the LavaLamp-equivalent of
the "spurious merge" zone — within the audit threshold but
not actually a genuine trajectory? The paper's tight
threshold 1-10⁻¹² gives 200/200 canonical seeds; LL-014's
analog (k=5 with n_trials=10) has 10% baseline FPR per the
P3-bound benchmark. Is the FPR-to-spurious-merge mapping
exact, and does the calibration discipline transfer?

(c) **V-017 — Three-layer logical-tier confusion attack.**
The paper's §1.2 explicit warning: *"these are not
interchangeable; conflating them produces category errors."*
LavaLamp's spec entries cluster across the three layers:
LL-001/006/008/018 are Possibilistic; LL-019/020/021 touch
Probabilistic; LL-011/012/013/017 are Bridge-tier
(deployment protocols). **Could an adversary deliberately
exploit a category error in LavaLamp's spec — e.g., apply a
Probabilistic-tier attack against a claim that's only
defended at the Possibilistic tier?** Round-3 should weigh
whether LL-018 (per-class quantification) needs explicit
layer-tagging.

**Edge-witness call:** which of V-015/016/017 is real, which
is theoretical, and which is already covered implicitly by
existing LL-IDs? Are there V-NNN candidates beyond these
three that the paper's structural priors imply? The
deployment-stack triple LL-022/023/024 + the candidate
LL-025 (A7 emanation per Q7/A7, V-014) cover four sub-
domains; V-015/016/017 might cluster into a fifth
(autopoiesis-tier attacks), warranting a fifth Boundary
entry.

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

## Internal note: brief status at 0.0.44

This brief is **substantively complete on both paper + engine
sides; ready to forward.** Status of each section:

- **§1** — LavaLamp side complete; paper-side fill landed at
  0.0.43; engine-side fill landed at 0.0.44 (TCE v0.2.2;
  Discovery.Triadic corpus-agnostic primitive; closure-v5 +
  BusinessEntity clients; 8 QuickCheck invariants;
  deployment-next decision deferred).
- **§2** — LavaLamp companions cited; paper item 1 filled at
  0.0.43; engine item 8 filled at 0.0.44 with concrete
  reading-priority list (dashboard / ENGINE_SPEC S-047..S-051
  / discovery_refactor companion / changelog top entries).
- **§3 Q1** — paper-specific reframing (0.0.43) with sub-
  questions (a/b/c) on structural-transfer-vs-vocabulary,
  "daughter IS the parent" mapping, numerical-threshold
  robustness.
- **§3 Q2-Q6** — LavaLamp-derived, unchanged.
- **§3 Q7** — EMF / A7 / LL-025 gap (0.0.40).
- **§4 A1-A5** — LavaLamp-derived, unchanged.
- **§4 A6** — paper-derived V-NNN candidates V-015/016/017
  (cross-sector autopoiesis spoofing; threshold gaming;
  three-layer logical-tier confusion). Renumbered from
  V-014/015/016 at 0.0.44 to resolve collision with §4 A7's
  V-014 EMF candidate.
- **§4 A7** — passive-emanation V-014 (added 0.0.40, came
  first; keeps the V-014 number).
- **§5** — seven-point evaluation; word cap 2800.
- **§6** — followups (8 questions).

**No remaining `[FILL: ...]` blanks at 0.0.44.** Brief is
forward-ready.

**Round-3 trigger response time at 0.0.44:** zero — Aaron
forwards §1+§2+§3 to Gemini and §1+§2+§4 to Grok at his
discretion. Both seats receive §5. §6 is internal.

**Note on Tier 2 audit (Discovery.Triadic on LavaLamp):**
not done; would require a `lavaLampCorpus` adapter. The
synthesis seat may surface this as a candidate post-round-3
work item. Not adding §3 Q9 to the brief because doing so
would commit to an audit artifact that doesn't exist — the
question is well-formed but un-answerable until the adapter
is written.

**V-NNN allocation summary post-rationalization:**
- V-001..V-010: original (attack_surface_enumeration.md)
- V-011/012/013: round-2 additions
- V-014: passive-emanation EMF (round-3, §4 A7 / Q7 / LL-025)
- V-015: cross-sector autopoiesis spoofing (round-3, §4 A6)
- V-016: numerical-threshold calibration gaming (round-3, §4 A6)
- V-017: three-layer logical-tier confusion (round-3, §4 A6)

V-014 EMF and V-015 autopoiesis-spoofing both warrant
candidate Boundary entries (LL-025 EMF; potential LL-026
autopoiesis-tier). Synthesis seat's Q7 weighs LL-025; §4 A6
implicitly suggests LL-026 as a fifth entry alongside the
deployment-stack triple. Round-3's resolution determines the
final spec-impact shape.
