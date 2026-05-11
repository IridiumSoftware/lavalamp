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

**Spec ledger:** 44 entries with the current breakdown (0.0.89, whitepaper v1.3):

| status | count | entries |
|---|---:|---|
| `:proved` | 2 | LL-021 worst-case bound (Lean 4 + Mathlib v4.29.1; `mul_le_of_le_one_right`; promoted at 0.0.48); LL-006 detection bound (theorem 41 abstract concentration + theorem 43 Mathlib-probability lift via `HasSubgaussianMGF.measure_ge_le` + theorem 46 non-trivial Gaussian-residue instantiation; promoted at 0.0.80 conditional on LL-035) |
| `:verified` | 0 | — |
| `:tested` | 18 | LL-002, LL-004, LL-007, LL-029 + eight joint-defense meta-claims (LL-030..LL-034, LL-036..LL-038) + six operational-layer entries (LL-039 daemon-visual-status, LL-040 v1 verify-result IPC, LL-041 v2 HMAC anti-replay, LL-042 v3 Ed25519 asymmetric signing, LL-043 v4 ECDSA P-256, LL-044 Linux TPM2 binding's fallback dispatch) |
| `:benchmarked` | 4 | LL-003 SDE choice, LL-019 timing-indistinguishability, LL-027 asymptotic Lyapunov density invariant, LL-035 Lorenz-96 max-residue sub-Gaussian (the empirical hypothesis backing LL-006's conditional `:proved`) |
| `:argued` | 19 | (P2 design + round-2 closures + closure-pass arguments + P-OS downward + P-PharOS upward + P-RS operational deployment-stack triple + round-3 Tier 1 + round-3 Tier 3) |
| `:open` | 1 | LL-015 (A3-OOS scoping declaration; permanent by design) |

See:
- `THEOREMS.md` — Lean 4 / Mathlib theorems with statements + proofs
- `src/julia/demo/lavalamp_demo.jl` — clone-and-run end-to-end walkthrough
- `src/lean4/README.md` — Lean track build instructions + theorem plan

## How do I know this actually protects?

Three layers of evidence ship with the prototype. None require
trust in the author.

**Layer 1 — Run the demo and watch the math.** `julia --project=
src/julia src/julia/demo/lavalamp_demo.jl` runs the full pipeline
in ~12 seconds. Steps 3 and 4 don't just print `ACCEPT` / `REJECT`
— they show the underlying calculation: max residue/σ ratio, the
LL-006 detection-bound formula `P(detect ε_A) ≥ 1 - exp(-c'·T·ε_A²)`
with calibrated constants `c'=0.00423` and `T=60`, and the bound
percentages at ε_A=3σ (89.85%) and ε_A=5σ (99.998%). The decision
is no longer opaque — you can see what was computed and what an
adversary would need to overcome.

**Layer 2 — Step 11 attack curve.** The same demo runs N=10 adversary
attempts at each of 6 ε_A magnitudes, computes empirical detection
rate with Wilson 95% CIs, and compares to the LL-006 theoretical
bound. The output looks like this:

```
  ε_A     empirical [Wilson 95% CI]      LL-006 bound   honest?
  ────    ──────────────────────────     ────────────   ───────
   0.5    [ 6/10]  60.0% [ 31.3%,  83.2%]    6.1%         ✓ yes
   1.0    [ 8/10]  80.0% [ 49.0%,  94.3%]   22.4%         ✓ yes
   1.5    [ 9/10]  90.0% [ 59.6%,  98.2%]   43.5%         ✓ yes
   2.0    [10/10] 100.0% [ 72.2%, 100.0%]   63.8%         ✓ yes
   2.5    [10/10] 100.0% [ 72.2%, 100.0%]   79.5%         ✓ yes
   3.0    [10/10] 100.0% [ 72.2%, 100.0%]   89.8%         ✓ yes
```

The bound is a *lower* floor — empirical detection is consistent
with or higher than the theoretical bound for every ε_A. If the
bound were ever above the upper edge of the empirical CI, that
would falsify it; the demo prints `✗ NO` for any such row. Run
the demo yourself and watch.

**Layer 3 — Read the proofs.** The detection bound shape, the
worst-case-adversary bound, and 51 supporting algebraic /
analytic / compositional theorems are machine-verified at Lean 4
toolchain pin v4.29.1 against Mathlib v4.29.1
(`src/lean4/LavaLamp/Theorems.lean`; `lake build` returns 2872
jobs with zero `sorry` warnings). Two LavaLamp spec entries are
at status `:proved`: LL-021 (worst-case-adversary bound, theorem 1)
and LL-006 (detection-probability bound, theorems 41 + 43 + 46,
conditional on the empirically-validated LL-035 sub-Gaussian
hypothesis). The conditionalisation is honest — the strengthen-
pass empirical evidence (50 trials × 11 ε_A points; χ² p=0.041)
backs the hypothesis; making the conditional explicit is spec
hygiene, not goalpost-moving.

**What this is not.** It is not unconditional security. It is
not a panacea. It is not (yet) public-falsification-validated —
the gold standard is a published challenge with a bounty for
spoofing, which is multi-month deployment-infrastructure work
listed under §10.6 of the whitepaper. What ships today is the
mathematical floor + an empirical demonstration that the floor
holds + machine-verified proofs of the floor's structural
properties. A skeptic who ran this demo, watched Step 11's
attack curve, and read theorems 41+43+46 in Lean has the
evidence to evaluate the claim on its merits — they are not
asked to take any of it on faith.

## Daily-driver UX (macOS, 0.0.83+)

Two new pieces of deployment infrastructure landed at v0.0.83
to give the user continuous visual feedback that LavaLamp is
running. The IPC channel and signing protocol have since been
hardened through four protocol versions (LL-040..LL-043) and
gained an optional TPM 2.0 binding on Linux (LL-044):

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

**OS-level integration (PharOS).** As of v0.0.88 the daemon
exposes an AF_UNIX verify-result IPC at
`~/.lavalamp/verify.sock` speaking the LL-043 v4 ECDSA P-256
protocol (33-byte SEC1-compressed pubkey at
`~/.lavalamp/verify.pub`, 17-byte challenge, 74-byte signed
response). The
[PharOS](https://github.com/IridiumSoftware/pharos) deployment
consumes this channel from Linux PAM (`pam_lavalamp.so`),
macOS Authorization Plug-in
(`LavaLampMechanism.bundle`), and Windows Credential Provider
Filter (`LavaLampCredentialProvider.dll`) — so `sudo`, login,
screen-unlock, System Settings privileged panes, and Windows
LogonUI all gate on substrate-bound verify. On Linux hosts
with `tpm2-tools` available, LL-044 binds the daemon's
signing key inside the TPM 2.0 chip (persistent handle
`0x81FF0001`) so the private key never leaves the TPM —
closing the same-UID forgery limit on Linux.

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

LavaLamp is the substrate-tier deployment in *The Triad
Deployments — Digital Identity Resilience*. All three
deployments are now public:

- **[LavaLamp](https://github.com/IridiumSoftware/lavalamp)** —
  substrate-bound identity primitive (this repo). Chaotic-SDE
  residue audit at the entropy layer. Whitepaper v1.3
  (`lavalamp_whitepaper.txt` / `lavalamp_whitepaper.pdf`).
- **[PharOS](https://github.com/IridiumSoftware/pharos)** —
  OS-membrane shim. Linux PAM module + macOS Authorization
  Plug-in + Windows Credential Provider Filter. Consumes
  LavaLamp's LL-043 v4 IPC. Whitepaper v1.0
  (`pharos_whitepaper.txt` / `pharos_whitepaper.pdf`).
- **[Lazarus](https://github.com/IridiumSoftware/lazarus)** —
  runtime-integrity sentinel. Face check, keystroke lockout,
  network anomaly detection. Whitepaper v0.0.x in repo.

The three deployments share a defensive-postured, resolution-
bounded identity stance: detection over prevention,
structurally inherited from the C-conjugate adversary
construction in *Possibilistic Security*. They compose at the
deployment-policy level — no shared runtime processes, no
architectural coupling beyond the LL-023 Bool-only consumer
API.

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
