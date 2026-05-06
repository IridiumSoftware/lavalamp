# Synthesis-Team Round 3 Brief — LavaLamp (Edge-Witness Seat / Grok)

**Forwarded:** 2026-05-06.

This is your seat's payload — edge-witness seat — corresponding
to §1 + §2 + §4 + §5 of the full brief at
`docs/synthesis_team_round3_brief.md`. Synthesis seat (Gemini)
receives a parallel payload with §3 substituted for §4.

You stress-tested round 2's architecture and produced
V-011/012/013 (Reseed Oracle, Calibration Spectrum Leakage,
Structured α-Direction Attack). Round 3 question: **given the
empirical refinement work since round 2 and the deployment-
stack triple, what new attack vectors emerge from the broader
architecture, and does the paper update reveal vectors the
prototype hadn't enumerated?**

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
   the entire A1-A7 stress-test in honest threat-tier terms.
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

## §4 — Edge-witness-seat brief

Seven specific stress-test questions:

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

The closure_forces_structure paper at v1.0 2026-04-01 is
canonical and settled; LavaLamp inherits from a published
corpus. **What attack vectors does the paper's framing imply
that V-001..V-013 don't capture?**

Three candidate V-NNN entries the paper surfaces (numbered to
avoid collision with §A7's V-014 EMF candidate):

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
LL-025 (A7 emanation per A7, V-014) cover four sub-domains;
V-015/016/017 might cluster into a fifth (autopoiesis-tier
attacks), warranting a fifth Boundary entry.

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

Following round-2's dialogue norm:

1. **Seven-point evaluation.** One bullet per question
   (A1-A7). Each bullet: short answer + reasoning + any
   pointer to a corpus reference, paper section, or formal
   source. ~80-120 words per bullet.
2. **Cumulative verdict.** `pass` / `pass-after-fixes` /
   `fail` with named attack vector.
3. **Net new attack vectors / blindspots.** If you surface
   anything that V-001..V-014 didn't cover, name it with a
   provisional V-NNN tag (we'll allocate the actual numbers
   on integration).
4. **Lean / proof-track suggestions.** Round 3 has the Lean 4
   scaffold landed (0.0.36) + CI (0.0.37) — name the theorem
   statement that should land first, with the Mathlib-or-not
   call.
5. **Paper-update integration.** If the paper update implies
   spec changes (new LL-IDs; existing-entry refinements;
   evidence-type promotions), name them. The paper is the
   load-bearing input for round 3's distinct value over
   round 2.

Length cap: **2800 words** (was 2000 in round 2 — the
deployment-stack triple + Lean scaffold + paper integration +
the post-skeleton EMF / A7 question add material; we want
substance not bulk but the surface is broader).
