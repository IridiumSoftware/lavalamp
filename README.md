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

See:
- `LAVALAMP_SPEC.md` — authoritative claim ledger
- `THEOREMS.md` — Lean 4 / Mathlib theorems with statements + proofs
- `artifact_registry.md` — spec-to-evidence map
- `dashboard.md` — current status + priority stack + open
  questions
- `changelog.md` — per-version diffs
- `docs/*_companion.md` — per-session permanent records

## Layout

```
lavalamp/
├── README.md                                    ← you are here
├── LAVALAMP_SPEC.md                             ← claim ledger
├── THEOREMS.md                                  ← Lean theorems summary
├── artifact_registry.md                         ← spec-to-evidence map
├── dashboard.md                                 ← status + priorities
├── changelog.md                                 ← versioned entries
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
