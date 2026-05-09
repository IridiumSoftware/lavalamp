# LavaLamp

[![Julia CI](https://github.com/IridiumSoftware/lavalamp/actions/workflows/test.yml/badge.svg)](https://github.com/IridiumSoftware/lavalamp/actions/workflows/test.yml)
[![Lean CI](https://github.com/IridiumSoftware/lavalamp/actions/workflows/lean.yml/badge.svg)](https://github.com/IridiumSoftware/lavalamp/actions/workflows/lean.yml)

A device-bound identity primitive. Prototype-stage.

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

**Cross-machine reproducibility check.** The demo's deterministic
output (numerical values, state transitions, accept/reject
decisions) is captured at `src/julia/demo/expected_output.txt`.
Run `bash src/julia/demo/verify_demo.sh` from the repo root to
execute the demo and assert the output matches; wall-clock
timings are normalized before diffing. CI runs this on every
push (see `Julia CI` badge above).

For the formal-verification side, see `THEOREMS.md` for a
single-file summary of the five Lean 4 theorems (with statements
+ proofs); `src/lean4/` for the Lake project itself; Mathlib
v4.29.1 with `LL021_worst_case_bound` proved at 0.0.48 — the
first-ever LavaLamp `:proved` entry.

## Status

Prototype-stage. The Julia prototype core (`src/julia/`)
implements the SDE substrate (Lorenz-96), sensor-coupling layer,
Lyapunov-spectrum residue audit, chaos-guard, and side-channel
hardening. The decoupled visual layer (`visual/`) lands in 0.0.33
with the LL-002 decoupling invariant made executable via static
text-search assertions on every commit. Real-hardware sensor
support (`src/julia/src/RealSensors.jl`) is **Linux Phase 1
implemented at 0.0.63** (sysfs/procfs file I/O, no FFI) and
**macOS Phase 2a + 2b implemented at 0.0.82** (hermetic shell-out
to `sysctl` / `pmset` / `ioreg` for five readers; SMC IOKit FFI
for CPU-die thermal — no privileged access required); Windows
remains scaffold-error pending Phase 3. CI runs `Pkg.test()` on
every push (488 assertions pass in ~68s).

**Spec ledger:** 38 entries with the current breakdown (0.0.82):

| status | count | entries |
|---|---:|---|
| `:proved` | 2 | LL-021 worst-case bound (Lean 4 + Mathlib v4.29.1; `mul_le_of_le_one_right`; promoted at 0.0.48); LL-006 detection bound (theorem 41 abstract concentration + theorem 43 Mathlib-probability lift via `HasSubgaussianMGF.measure_ge_le` + theorem 46 non-trivial Gaussian-residue instantiation; promoted at 0.0.80 conditional on LL-035) |
| `:verified` | 0 | — |
| `:tested` | 12 | LL-002, LL-004, LL-007, LL-029, plus eight joint-defense meta-claims (LL-030, LL-031, LL-032, LL-033, LL-034 from the v0.2.4 top-band engine pass; LL-036, LL-037, LL-038 from the v0.2.9 stratified-scan) |
| `:benchmarked` | 4 | LL-003 SDE choice, LL-019 timing-indistinguishability, LL-027 asymptotic Lyapunov density invariant, LL-035 Lorenz-96 max-residue sub-Gaussian (the empirical hypothesis backing LL-006's conditional `:proved`) |
| `:argued` | 19 | (P2 design + round-2 closures + closure-pass arguments + P-OS downward + P-PharOS upward + P-RS operational deployment-stack triple + round-3 Tier 1 + round-3 Tier 3) |
| `:open` | 1 | LL-015 (A3-OOS scoping declaration; permanent by design) |

See:
- `THEOREMS.md` — Lean 4 / Mathlib theorems with statements + proofs
- `src/julia/demo/lavalamp_demo.jl` — clone-and-run end-to-end walkthrough
- `src/lean4/README.md` — Lean track build instructions + theorem plan

## Daily-driver UX (macOS, 0.0.83)

Two new pieces of deployment infrastructure landed at v0.0.83
to give the user continuous visual feedback that LavaLamp is
running:

```bash
# Start the daemon in one terminal:
julia --project=src/julia src/julia/daemon/lavalamp_daemon.jl

# Build + start the menu bar app (one-time build):
cd src/swift/lavalamp_menubar
swiftc -framework Cocoa lavalamp_menubar.swift -o lavalamp_menubar
./lavalamp_menubar
```

The menu bar shows a small lavalamp icon — vibrant green when
the daemon is alive, faded grey when it isn't (LL-039). The
cross-process channel is a heartbeat file at
`~/.lavalamp/heartbeat` containing **only a timestamp** —
strict LL-002 compliance, no security state leaks. The browser
visual at `visual/index.html` is now positioned as the
marketing/landing-page asset; the menu bar app is the daily
driver.

## Layout

```
lavalamp/
├── README.md                                    ← you are here
├── THEOREMS.md                                  ← Lean theorems summary
├── .github/workflows/test.yml                   ← Julia CI (Pkg.test + demo verify on push)
├── .github/workflows/lean.yml                   ← Lean CI (lake build on push)
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
        ├── demo/lavalamp_demo.jl                ← clone-and-run end-to-end walkthrough
        ├── demo/expected_output.txt             ← canonical demo output (timings normalized)
        ├── demo/verify_demo.sh                  ← cross-machine reproducibility check
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
