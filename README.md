# LavaLamp

A device-bound identity primitive. Prototype-stage; private repo.

## What it is

A laptop continuously solves a hard but lightweight stochastic
differential equation locally. The trajectory is amplified by
hardware/configuration-state coupling (thermal jitter, CPU
governor, scheduler timing, sensor reads from USB / power-adapter /
battery / temperature sensors) into a substrate-unique signature.

**Identity = the sustained chaotic trajectory on the device.**
Verification = trajectory checkpoint comparison against a
registered hardware envelope, with adversary-signature detection
via Lyapunov-spectrum residue audit.

The project is structurally derived from the C-conjugate adversary
construction in *Possibilistic Security* (Green 2026), applied at
the entropy layer.

## What it isn't

- **Not QKD.** No quantum hardware. The unclonability claim is
  *computational*, resolution-bounded against adversary
  measurement capability — not information-theoretically secure
  via no-cloning theorem. Quantum no-cloning depends on
  quantum-mechanical linearity; a classical chaotic SDE is
  non-linear and the state is observable without collapse.
  Conflating the two tiers in pitches will trip careful
  reviewers.
- **Not a key-distribution protocol.** QKD distributes keys
  between two parties over an open channel. LavaLamp generates
  device-bound entropy locally; with a registration ceremony it
  supports device authentication.

## Architectural separation (load-bearing)

**Visual ↔ security decoupling.** The user-facing lava-lamp
animation is *decorative only* and runs on whatever RNG is
convenient. The security primitive (chaotic SDE + sensor coupling
+ Lyapunov-spectrum residue audit) runs as an independent
background process. Same shape as Lazarus: substance under the
hood; minimal/utilitarian UI on top.

If those two layers ever get re-coupled, the basin-spoofing
attack surface (multi-basin reaction-diffusion regimes the visual
layer would want to use) returns.

## Try it

A clone-and-run end-to-end demo lives at
`src/julia/demo/lavalamp_demo.jl`. From a fresh checkout:

```bash
julia --project=src/julia -e 'using Pkg; Pkg.instantiate()'
julia --project=src/julia src/julia/demo/lavalamp_demo.jl
```

What you should see (~4 seconds wall-clock on a 2024-vintage laptop):

1. **Engine + coupling** — Lorenz-96 SDE at N=20, F=8 with a
   linear-in-x synthetic-sensor coupling layer.
2. **Registration** — 5-trial Lyapunov-spectrum calibration
   produces an envelope with mean λ₁ ≈ +1.89 and per-exponent σ.
3. **Honest verification** — `verify_full` accepts the genuine
   system; max residue / σ ratio ≈ 3 (well under the conservative
   k=10 threshold).
4. **Adversary rejection** — a 3σ-magnitude structured-direction
   adversary produces residue ratio ≈ 14 (well above k=5);
   `verify_full` rejects.
5. **Chaos-guard state machine** — five honest λ̂₁ samples drive
   `WARMUP → VALID`; one sub-threshold sample collapses the guard
   to `INVALID` (the reseed flow's trigger condition).

The demo exits with `✅ All three pillars of the LavaLamp pipeline
behave as specified.` if the LL-003 / LL-004 / LL-006 / LL-007 /
LL-019 / LL-021 layers are all working as the spec requires.

For the formal-verification side, see `src/lean4/` — Lean 4 +
Mathlib v4.29.1 with `LL021_worst_case_bound` proved at 0.0.48
(the first-ever LavaLamp `:proved` entry).

## Status

Prototype-stage. The Julia prototype core (`src/julia/`)
implements the SDE substrate (Lorenz-96), sensor-coupling layer,
Lyapunov-spectrum residue audit, chaos-guard, and side-channel
hardening. The decoupled visual layer (`visual/`) lands in 0.0.33
with the LL-002 decoupling invariant made executable via static
text-search assertions on every commit. The real-sensor scaffold
(`src/julia/src/RealSensors.jl`) lands in 0.0.38 with API stubs
for hardware-bound deployment (Linux-first roadmap; FFI
implementations forthcoming post-round-3). CI runs `Pkg.test()`
on every push (202 assertions pass in ~53s).

**Spec ledger:** 29 entries with the current breakdown:

| status | count | entries |
|---|---:|---|
| `:proved` | 1 | LL-021 worst-case bound (Lean 4 + Mathlib v4.29.1; `mul_le_of_le_one_right` over the bound shape `0 ≤ ε_A → proj ≤ 1 → ε_A · proj ≤ ε_A`; first-ever LavaLamp `:proved` entry; promoted at 0.0.48 L2) |
| `:verified` | 0 | — |
| `:tested` | 3 | LL-002 visual ↔ security decoupling, LL-004 sensor coupling, LL-007 chaos-guard |
| `:benchmarked` | 4 | LL-003 SDE choice, LL-006 detection bound, LL-019 timing-indistinguishability, LL-027 asymptotic Lyapunov density invariant |
| `:argued` | 20 | (P2 design + round-2 closures + closure-pass arguments + P-OS downward + P-PharOS upward + P-RS operational deployment-stack triple + round-3 Tier 1: LL-025 A7-passive-emanation-boundary + LL-026 three-layer-logic-tier-annotation-discipline + round-3 Tier 3: LL-028 runtime-conformance-verification + LL-029 multi-channel-entropy-independence) |
| `:open` | 1 | LL-015 (A3-OOS scoping declaration; permanent by design) |

**Trajectory:** 0.0.1 (concept-stage scaffold) → 0.0.3
(attack-surface enum) → 0.0.5 (P2 design pass) → 0.0.6 - 0.0.10
(P3 prototype core) → 0.0.11 (CI) → 0.0.12 (synthesis-team round
2) → 0.0.14 - 0.0.16 (P-R2 trio) → 0.0.17 - 0.0.19 (round-2
:benchmarked cohort) → 0.0.20 (closure pass) → 0.0.23 - 0.0.25
(LL-020 ε-DP envelope, P3-Nyq negative result, P3d
SDE-selection) → 0.0.26 (P-OS OS-level scoping pass) →
0.0.27 (LL-020 Strategy 2 :benchmarked-tier; variance-
convolution σ refinement) → 0.0.28 (LL-021 high-resolution
P-R2c refresh; c′=0.0288 at n=15) → 0.0.29 (LL-019 high-res
refresh; regime-boundary at α=0.01/n=2000) → 0.0.30
(LL-003 N-scaling characterisation; Lyapunov density ≈ 0.255)
→ 0.0.31 (LL-006 per-SDE detection-power; Lorenz-96 has best
operational balance) → 0.0.32 (LL-005 part-(a) parameter-
validation test; entry stays :argued — last unblocked queue
item now closed) → 0.0.33 (LL-002 :tested via decoupled
visual layer + decoupling-assertion testset) → 0.0.34
(P-PharOS scoping pass; LL-023 added :argued — upward trust-
stack scoping paired with LL-022 to close the trust-stack
scoping question on both ends) → 0.0.35 (full A0–A6 cross-
audit pre-round-3; CLAUDE.md drift fixed; PASS across all
six checks) → 0.0.36 (Lean 4 scaffold landed at src/lean4/;
lake build clean; round-3 proof work picks up from a
buildable starting point) → 0.0.37 (Lean 4 CI workflow at
.github/workflows/lean.yml; lake build on every push) →
0.0.38 (P-RS real-sensor scoping pass + RealSensors.jl
scaffold; LL-024 added :argued; deployment-stack triple
LL-022 + LL-023 + LL-024 closes scoping on all three ends) →
0.0.39 (round-3 brief skeleton at
docs/synthesis_team_round3_brief.md; pre-trigger prep
substantively complete on LavaLamp side; paper-side blanks
fill in ~30-60 min when round-3 triggers) → 0.0.40 (round-3
brief Q7 + A7 added; EMF / A7 / LL-025 gap surfaced
post-skeleton 2026-05-05; Triadic Watchmen miss physical-
emanation layer; round-3 to weigh whether LL-025 is
load-bearing) → 0.0.41 (threat-landscape companion;
cockroach/catapult/castle/immune-system framing for the
Triad Deployments; meta-architectural context surfaced via
the same 2026-05-05 conversation) → 0.0.42 (threat-landscape
companion §2.6/§2.7 added — metabolic-value / predator-prey
ecology axis; LavaLamp's claim reframed explicitly as
cost-asymmetry; symbiosis-as-equilibrium-not-victory; LL-008
gains cost-asymmetry footer) → 0.0.43 (round-3 brief paper-
side blanks filled; closure_forces_structure v1.0 2026-04-01
paper-grounded; three load-bearing section clusters captured;
three V-NNN candidates surfaced; engine-side blanks pending)
→ 0.0.44 (round-3 forward-brief engine-side blanks filled;
V-NNN tag collision rationalized to V-014..V-017; brief
substantively complete on both paper + engine sides;
forward-ready) →
0.0.45 (synthesis-team round 3 Tier 1; seat rotation Grok →
synthesis + ChatGPT → edge-witness; both verdicts non-fail;
LL-025 A7-passive-emanation-boundary + LL-026 three-layer-
logic-tier-annotation-discipline added; V-014..V-020
enumerated in attack-surface — V-021/V-022 absorbed into
V-015/V-016 per Aaron's resolution decision) → 0.0.46
(round-3 Tier 2 spec changes; LL-027 asymptotic Lyapunov
density invariant `s ≈ 0.255` per dimension added
:benchmarked from the existing 0.0.30 P3e benchmark; LL-021
round-3 finite-N scope-limit + adaptive-adversary amendment;
LL-014 round-3 numerical-threshold non-fundamentality tie;
first Lean theorem deferred to a separate version pass for
session-focus reasons — adding Mathlib + writing measure-
theoretic proofs warrants its own session) → 0.0.47
(round-3 Lean L1; toolchain bumped `leanprover/lean4:v4.18.0`
→ `v4.29.1` to resolve a Darwin 25 dyld linker error on the
v4.18.0 cache binary; Mathlib v4.29.1 integrated at
`src/lean4/lakefile.lean` per round-3 §1D.v Decision 1
Option A — full Mathlib; `lake-manifest.json` pins Mathlib
+ 8 transitive deps; `LavaLamp/Theorems.lean` comment-block
placeholder replaced with real theorem statement
`LL021_worst_case_bound : 0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 →
ε_A * proj ≤ ε_A := by sorry` capturing the bound shape;
`lake build` clean with single expected sorry warning;
`.github/workflows/lean.yml` `timeout-minutes` 15 → 60 to
absorb Mathlib first-build window; LL-021 stays
`:benchmarked` per CLAUDE.md §Honest framing — sorry-stub is
not a proof; L2 fills the sorry next version with a
one-liner real proof) → 0.0.48 (round-3 Lean L2; the L1
`sorry` body in `LavaLamp.LL021_worst_case_bound` is replaced
with a real Lean 4 proof — `mul_le_of_le_one_right h_ε
h_proj_le_one`, a direct application of Mathlib's
`mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`; the
unused `0 ≤ proj` hypothesis is dropped from the signature
since the bound holds without it; `lake build` returns 767
jobs green with **zero warnings**; LL-021 evidence-type
`benchmarked` → `lean-proved` and status `:benchmarked` →
`:proved` — **first-ever LavaLamp `:proved` entry**; counts
27/0/3/0/5/18/1 → 27/1/3/0/4/18/1; closes Aaron's round-3
§1D.v Decision 1 path end-to-end) → 0.0.49 (LL-021 squared-
effective-magnitude composition foothold; corollary lemma
`LL021_eff_squared_bound : 0 ≤ ε_A → 0 ≤ proj → proj ≤ 1 →
(ε_A · proj)² ≤ ε_A²` proved by `pow_le_pow_left₀` over the
worst-case bound; sets up the round-3 §1D.v priority-4 LL-006
detection-bound theorem composition step (squared-magnitude
monotonicity into LL-006's `exp(-c·T·ε_eff²)` shape); `lake
build` clean with 767 jobs and zero warnings; counts
unchanged — corollary is additional `lean-proved` content
supporting the existing LL-021 `:proved` entry) → 0.0.50
(round-3 Tier 3 spec landing per §1D.iii / §1D.iv; LL-028
runtime-conformance-verification added Boundary `:argued`
defending V-019 with four runtime-verification requirements
— attestation continuity / sensor cross-validation with
adversarial probes / verifier-side LL-023 API probing /
continuous TRNG attestation; LL-029 multi-channel-entropy-
independence added Operational `:argued` defending V-018
with seven-family physical-mechanism taxonomy and
calibration-window correlation test `|ρ| > 0.3` over 60s;
LL-019 round-3 deployment-context expansion footer covering
regime-1 dev-host artifact + regime-2 multi-tenant real-
channel + shared-environment deployment constraint;
engineering implementation deferred to P-RS Level 2
prototype availability per §1D.viii; counts 27/1/3/0/4/18/1
→ 29/1/3/0/4/20/1; round-3 spec-side trajectory closes
end-to-end and §1D.viii Round-4-trigger condition is now
satisfied) → 0.0.51 (clone-and-run demo at
`src/julia/demo/lavalamp_demo.jl` lands for publication-day
shipability; exercises LL-003 / LL-004 / LL-006 / LL-007 /
LL-019 / LL-021 end-to-end in ~4 s wall-clock with honest
ACCEPT (residue/σ ≈ 3 < k=10) + adversary REJECT at ε_A=3σ
(residue/σ ≈ 14 > k=5) + chaos-guard `WARMUP → VALID →
INVALID` transition; top-level README gains a "Try it"
quickstart; counts unchanged at 29/1/3/0/4/20/1).

**Round 3 ran 2026-05-06.** Forwarded to Grok (synthesis,
rotated from edge-witness in rounds 1/2) and ChatGPT (new
edge-witness entrant; Gemini stepped out due to round-3 task
difficulty). Verdicts: Grok `engage-and-formalise-after-
fixes`; ChatGPT `pass-after-fixes` — complementary, neither
fail. Aaron's three resolution decisions rendered same day:
V-021/V-022 merge into V-015/V-016; Tier 1/2/3 sequencing
confirmed; Lean Option A — LL-021 worst-case bound + Mathlib
full as first theorem. **Tier 1 landed 0.0.45** (LL-025 +
LL-026 + V-014..V-020). **Tier 2 spec landed 0.0.46**
(LL-027 + LL-021 amendment + LL-014 amendment); first Lean
theorem deferred to a separate session pass given Mathlib
integration scope. **Lean L1 landed 0.0.47** (Mathlib
v4.29.1 integrated; `LL021_worst_case_bound` theorem-statement
sorry-stubbed). **Lean L2 landed 0.0.48** (sorry replaced
with real proof; LL-021 promoted to `:proved` —
first-ever LavaLamp `:proved` entry). **LL-006 composition
foothold 0.0.49** (`LL021_eff_squared_bound` corollary
lemma; sets up round-3 §1D.v priority-4 detection-bound
theorem). **Tier 3 spec landed 0.0.50** (LL-028 runtime
conformance + LL-029 multi-channel entropy independence
added; LL-019 deployment-context expansion footer). Tier 3
*engineering* (P-RS Level 2 prototype + LL-028 conformance-
check module + LL-029 sensor-architecture enumeration) is
sequenced separately as engineering work. **Round-3 spec-
side trajectory complete; §1D.viii Round-4 trigger
condition satisfied** (Tier 1 + Tier 2 landed; first Lean
theorem type-checked). See
`docs/synthesis_team_round3_companion.md` for the full
metabolic synthesis.

See:
- `LAVALAMP_SPEC.md` — authoritative claim ledger
- `artifact_registry.md` — spec-to-evidence map
- `dashboard.md` — current status + priority stack + open
  questions
- `CLAUDE.md` — project governance + scope boundaries
- `changelog.md` — per-version diffs
- `docs/*_companion.md` — per-session permanent records

## Layout

```
lavalamp/
├── README.md                                    ← you are here
├── LAVALAMP_SPEC.md                             ← claim ledger
├── artifact_registry.md                         ← spec-to-evidence map
├── dashboard.md                                 ← status + priorities
├── changelog.md                                 ← versioned entries
├── CLAUDE.md                                    ← project governance
├── .github/workflows/test.yml                   ← Julia CI (Pkg.test on push)
├── .github/workflows/lean.yml                   ← Lean CI (lake build on push)
├── docs/                                        ← per-session companion docs
│   ├── concept_origin_companion.md
│   ├── synthesis_team_round1_companion.md
│   ├── synthesis_team_round2_brief.md
│   ├── synthesis_team_round2_companion.md
│   ├── attack_surface_enumeration.md
│   ├── architecture_design_companion.md
│   ├── language_plan_catlab_tier_companion.md
│   ├── qkd_pqc_complementarity_companion.md
│   ├── p3_baseline_companion.md
│   ├── p3a_sensor_coupling_companion.md
│   ├── p3b_residue_audit_companion.md
│   ├── p3c_chaos_guard_companion.md
│   ├── p_r2a_side_channel_hardening_companion.md
│   ├── p_r2b_calibration_confidentiality_companion.md
│   ├── p_r2c_worst_case_adversary_companion.md
│   ├── p3_bound_companion.md
│   ├── ll021_benchmarked_companion.md
│   ├── ll019_benchmarked_companion.md
│   ├── spec_closure_pass_companion.md
│   ├── audit_2026-05-03.md
│   ├── ll020_strategy_2_epsilon_dp_companion.md
│   ├── p3_nyq_companion.md
│   ├── p3d_sde_selection_companion.md
│   ├── os_identity_security_scoping_companion.md
│   ├── audit_2026-05-04.md
│   ├── ll020_strategy_2_benchmarked_companion.md
│   ├── ll021_high_res_companion.md
│   ├── ll019_high_res_companion.md
│   ├── p3e_n_scaling_companion.md
│   ├── p3f_per_sde_detection_power_companion.md
│   ├── ll005_part_a_companion.md
│   ├── pharos_scoping_companion.md
│   ├── audit_2026-05-04_full.md
│   ├── p_real_sensor_scoping_companion.md
│   ├── synthesis_team_round3_brief.md
│   └── threat_landscape_companion.md
├── visual/                                     ← decoupled visual layer (LL-002)
│   ├── index.html                              ← canvas entry point
│   ├── lavalamp.js                             ← Math.random() bubble simulator
│   ├── style.css                               ← lamp-frame styling
│   └── README.md                               ← decoupling discipline
└── src/
    ├── lean4/                                   ← Lean 4 formal-verification track (Mathlib v4.29.1; 0.0.47)
    │   ├── lakefile.lean                       ← Lake build config (Mathlib v4.29.1 require)
    │   ├── lean-toolchain                      ← Lean version pin (v4.29.1; bumped 0.0.47)
    │   ├── lake-manifest.json                  ← Lockfile (Mathlib + 8 transitive deps pinned)
    │   ├── LavaLamp.lean                       ← root module
    │   ├── LavaLamp/Theorems.lean              ← round-3 theorems (LL021_worst_case_bound sorry-stubbed at 0.0.47; L2 0.0.48)
    │   └── README.md                           ← discipline + theorem plan
    └── julia/                                   ← prototype core (P3)
        ├── Project.toml + Manifest.toml         ← lockfile-pinned deps
        ├── src/{LavaLamp,Sensors,Engine,Audit,ChaosGuard,RealSensors}.jl
        ├── test/runtests.jl                     ← 202 assertions, run via Pkg.test()
        ├── demo/lavalamp_demo.jl                ← clone-and-run end-to-end walkthrough (0.0.51)
        └── benchmark/
            ├── p3b_detection_probability.jl
            ├── p_r2c_structured_adversary.jl
            ├── p3_bound_high_res.jl
            ├── ll019_timing_distribution.jl
            ├── p3_nyq_adversary_rate.jl
            ├── p3d_sde_selection.jl
            ├── ll020_strategy_2_detection_power.jl
            ├── p_r2c_structured_adversary_high_res.jl
            ├── ll019_timing_distribution_high_res.jl
            ├── p3e_n_scaling.jl
            ├── p3f_per_sde_detection_power.jl
            └── results/*.txt                    ← committed benchmark outputs

# Future language tracks (per dashboard priority stack):
#   P4  Catlab.jl (default skip; revisit when verification protocol
#       surfaces categorical content)
#   P5  src/haskell/ — spec-as-types + QuickCheck against the Julia
#       prototype for compositional-completeness
#   P6  src/lean4/   — formal verification of structural security claims
#       (round-2 §1D.v Lean priorities + the §2.1 detection bound)
#   P7  src/cpp/     — production hardening from the proven spec
#   P8  visual/      — decorative skin (per LL-002; any framework)
```

## Portfolio

LavaLamp is one of *The Triad Deployments — Digital Identity
Resilience*, alongside Lazarus and PharOS (forthcoming). The
three deployments share a defensive-postured, resolution-bounded
identity stance: detection over prevention, structurally
inherited from the C-conjugate adversary construction in
*Possibilistic Security*.

## License

Triadic Closure License (TCL) v1.3. Canonical text and original
discussion in `github.com/IridiumSoftware/possibilistic-security`.

## Provenance

Visual seed credit: codetaur (SDE imagery resembling a lava lamp;
structural application unintended). Patent-offer extended as
good-faith credit for the seed.

Concept and security application: Aaron Green, derived from the
C-conjugate adversary structure introduced in *Possibilistic
Security*.

Discussion / framing engagement: Brian Crabtree (ORSIΩ-vocabulary
discussions).

Synthesis-team review: Gemini (synthesis seat) + Grok (edge-witness
seat), 2026-04-30.
