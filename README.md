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
hardening. CI runs `Pkg.test()` on every push (94 assertions
pass in ~50s).

**Spec ledger:** 21 entries with the current breakdown:

| status | count | entries |
|---|---:|---|
| `:proved` | 0 | — |
| `:verified` | 0 | — |
| `:tested` | 3 | LL-003 baseline, LL-004 sensor coupling, LL-007 chaos-guard |
| `:benchmarked` | 3 | LL-006 detection bound, LL-019 timing-indistinguishability, LL-021 worst-case bound |
| `:argued` | 14 | (P2 design + round-2 closures + closure-pass arguments) |
| `:open` | 1 | LL-015 (A3-OOS scoping declaration; permanent by design) |

**Trajectory:** 0.0.1 (concept-stage scaffold) → 0.0.3
(attack-surface enum) → 0.0.5 (P2 design pass) → 0.0.6 - 0.0.10
(P3 prototype core) → 0.0.11 (CI) → 0.0.12 (synthesis-team round
2) → 0.0.14 - 0.0.16 (P-R2 trio) → 0.0.17 - 0.0.19 (round-2
:benchmarked cohort) → 0.0.20 (closure pass).

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
├── .github/workflows/test.yml                   ← CI workflow
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
│   └── spec_closure_pass_companion.md
└── src/
    └── julia/                                   ← prototype core (P3)
        ├── Project.toml + Manifest.toml         ← lockfile-pinned deps
        ├── src/{LavaLamp,Sensors,Engine,Audit,ChaosGuard}.jl
        ├── test/runtests.jl                     ← 94 assertions, run via Pkg.test()
        └── benchmark/
            ├── p3b_detection_probability.jl
            ├── p_r2c_structured_adversary.jl
            ├── p3_bound_high_res.jl
            ├── ll019_timing_distribution.jl
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
