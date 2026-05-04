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

**Spec ledger:** 24 entries with the current breakdown:

| status | count | entries |
|---|---:|---|
| `:proved` | 0 | — |
| `:verified` | 0 | — |
| `:tested` | 3 | LL-002 visual ↔ security decoupling, LL-004 sensor coupling, LL-007 chaos-guard |
| `:benchmarked` | 4 | LL-003 SDE choice, LL-006 detection bound, LL-019 timing-indistinguishability, LL-021 worst-case bound |
| `:argued` | 16 | (P2 design + round-2 closures + closure-pass arguments + P-OS downward + P-PharOS upward + P-RS operational deployment-stack triple) |
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
LL-022 + LL-023 + LL-024 closes scoping on all three ends).

**Round 3** (next synthesis-team review) is gated on the
`closure_forces_structure` physics-paper update.

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
│   └── p_real_sensor_scoping_companion.md
├── visual/                                     ← decoupled visual layer (LL-002)
│   ├── index.html                              ← canvas entry point
│   ├── lavalamp.js                             ← Math.random() bubble simulator
│   ├── style.css                               ← lamp-frame styling
│   └── README.md                               ← decoupling discipline
└── src/
    ├── lean4/                                   ← Lean 4 formal-verification scaffold (0.0.36)
    │   ├── lakefile.lean                       ← Lake build config (no deps at scaffold tier)
    │   ├── lean-toolchain                      ← Lean version pin (v4.18.0)
    │   ├── lake-manifest.json                  ← Lockfile (empty packages at scaffold)
    │   ├── LavaLamp.lean                       ← root module
    │   ├── LavaLamp/Theorems.lean              ← round-3 theorem placeholders
    │   └── README.md                           ← discipline + theorem plan
    └── julia/                                   ← prototype core (P3)
        ├── Project.toml + Manifest.toml         ← lockfile-pinned deps
        ├── src/{LavaLamp,Sensors,Engine,Audit,ChaosGuard,RealSensors}.jl
        ├── test/runtests.jl                     ← 202 assertions, run via Pkg.test()
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
