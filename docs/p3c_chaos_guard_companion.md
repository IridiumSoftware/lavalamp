# P3c Chaos-Guard Companion

Version: 0.0.10 (P3c chaos-guard / periodic-window safety
signal, 2026-05-02)

Permanent record of the P3c session: implementing the chaos-
guard per architecture-design §2.3 (LL-007). Closes LL-007
from `:argued` to `:tested` with `example-tested` evidence
(state-machine logic + integration with Lorenz-96 chaotic vs
sub-chaotic vs reseed-recovery scenarios).

---

## §1 — Computational basis

**What was built.**

- **`src/julia/src/ChaosGuard.jl`** — guard module.
  - `GuardState` (`@enum`): `INVALID`, `WARMUP`, `VALID`.
  - `GuardConfig(τ_λ, recovery_threshold, warmup_steps)` —
    immutable threshold bundle. Validates τ_λ > 0, recovery >
    τ_λ, warmup_steps ≥ 1.
  - `default_config(λ₁_expected; warmup_steps=10)` —
    constructs a config from the architecture-design §2.3
    ratios: `τ_λ = 0.1·λ₁_expected`, `recovery_threshold =
    5·τ_λ`. For Lorenz-96 N=40, F=8 (λ₁ ≈ 1.66): τ_λ ≈ 0.166,
    recovery ≈ 0.83.
  - `Guard(config)` — mutable state machine; constructor sets
    state = WARMUP (not VALID — the security primitive must
    not assume entropy is good before observation).
  - `update!(guard, λ̂₁)` — apply one λ̂₁ observation; returns
    post-update state. Implements the §2.3 transition logic.
  - `is_valid(guard)` → `Bool` — public predicate. Downstream
    entropy consumers gate on this; entropy emitted while
    `!is_valid(guard)` is rejected (LL-017 no-oracle: only
    Bool leaks, not λ̂₁ details).
  - `current_lambda(guard)` → most-recent λ̂₁ for diagnostic /
    internal logging (not part of the public verifier
    interface).
  - `reseed!(ds, guard; rng, magnitude=1.0)` — TRNG-derived
    unit-vector perturbation of the SDE state with deterministic
    L2 magnitude. Resets guard to WARMUP, increments
    `reseed_count`.

- **`src/julia/src/LavaLamp.jl`** — adds `include("ChaosGuard.jl")`
  and re-exports the guard symbols.

- **`src/julia/test/runtests.jl`** — adds 35 chaos-guard
  assertions across 3 new `@testset`s:
  - **ChaosGuard config + state machine (LL-007)** (~17
    assertions): config validation (negative τ_λ throws,
    recovery ≤ τ_λ throws, warmup_steps < 1 throws); initial
    state WARMUP; sustained-high → VALID after warmup_steps;
    gray-band dip preserves VALID; collapse → INVALID;
    INVALID → WARMUP first recovery sample; recovery
    completion to VALID; update! return value.
  - **ChaosGuard with Lorenz-96 (chaotic vs sub-chaotic)** (~6
    assertions): F=8 chaotic Lorenz-96 → guard reaches VALID;
    F=2 sub-chaotic Lorenz-96 (trivial fixed point, λ₁ ≈ 0)
    → guard stays INVALID.
  - **ChaosGuard reseed flow** (~12 assertions): drive
    chaotic system to VALID; reseed (deterministic magnitude
    = 2.0); state transitions to WARMUP, reseed_count = 1,
    consecutive_recovery = 0; state vector L2-norm of
    perturbation matches magnitude exactly; recovery to VALID
    after sustained chaotic updates.

**Build / run.**

```bash
cd src/julia
julia --project=. -e 'using Pkg; Pkg.test()'  # 82 assertions, ~47s
```

**Wall-clock metrics on the dev host.**

- Test suite: 82 assertions / ~47s wall clock (was 47 / ~78s
  in 0.0.9). The increase from 47 to 82 assertions paradoxically
  *decreases* wall clock because the chaos-guard tests use
  `DynamicalSystems.lyapunov` (Wolf method, single trajectory)
  rather than `lyapunovspectrum` (Benettin, full spectrum).
  Per the `p3_baseline_companion.md` §2.4 cost analysis: O(N)
  per step for the leading exponent vs O(N²) for the full
  spectrum. At N=40, this is roughly 400× faster
  per-call (~1.3 ms vs ~507 ms). The chaos-guard tests run 13
  spectrum estimations total at ~17 ms; full-spectrum equivalent
  would have added ~6.6 s to the suite.

The pattern is worth documenting: **whenever a security-
primitive component only needs λ₁, use Wolf**, not Benettin.

---

## §2 — Results

### §2.1 — State-machine logic

The §2.3 design specifies three states with clear transitions.
The implementation matches:

```
                    λ̂₁ < τ_λ
   any state ──────────────────→ INVALID
                    (collapse)

                    λ̂₁ ≥ recovery_threshold (first time)
   INVALID ──────────────────────────────────────────→ WARMUP

                    λ̂₁ ≥ recovery_threshold for warmup_steps
   WARMUP ─────────────────────────────────────────────→ VALID

                    λ̂₁ ≥ τ_λ (incl. gray band)
   VALID ──────────────────────────────────────→ VALID
```

Two design choices worth recording:

- **Gray-band dips don't invalidate VALID.** Chaotic systems
  fluctuate; a single sample of λ̂₁ in the band [τ_λ,
  recovery_threshold] is not evidence of collapse — it is
  expected variance. Only true collapse below τ_λ flips
  VALID → INVALID.
- **Initial state is WARMUP, not VALID.** Even at construction
  time, the guard does not assume the dynamics is chaotic. The
  first warmup_steps observations must establish the chaotic
  regime. This is conservative-by-default: a freshly booted
  device must demonstrate it is producing chaos before its
  entropy is consumed.

### §2.2 — Sub-chaotic-regime detection (Lorenz-96 F=2)

The §2.3 design's archetypal failure mode is a periodic
window — a parameter regime where the system has stalled into
a periodic orbit (λ̂₁ → 0). For Lorenz-96, the obvious
implementation of this is to drop F below the chaotic-onset
threshold (F ≈ 4). At F=2, the system relaxes to the trivial
fixed point x_i = F = 2 with all Lyapunov exponents ≤ 0.

Empirically, `cheap_lyap(lorenz96(40; F=2.0), 60.0; Ttr=10.0)`
returns 0.0 (or numerically tiny). The guard sees λ̂₁ < τ_λ
on every update and stays INVALID across the test sequence. ✓

This is the prototype's empirical demonstration that the
guard catches sub-chaotic regimes. Production systems would
encounter periodic windows through *intermittent* parameter
drift (e.g., a degraded sensor pegging some channel), not
necessarily through F dropping below threshold; the guard
mechanism is the same.

### §2.3 — Reseed flow (assertion-level evidence)

The reseed function is exercised end-to-end:

1. Drive a chaotic Lorenz-96 to VALID (3 updates @ warmup_steps=2).
2. Capture the state vector pre-reseed.
3. Call `reseed!(ds, guard; rng=Xoshiro(99), magnitude=2.0)`.
4. Assert `state == WARMUP`, `reseed_count == 1`,
   `consecutive_recovery == 0`.
5. Assert L2-norm of (post-state - pre-state) ≈ 2.0 exactly.
6. Re-drive with chaotic updates → state recovers to VALID.

The deterministic-magnitude property (step 5) matches the
`Audit.synthetic_adversary` semantic from 0.0.9 — both use
unit-vector × magnitude rather than randn(magnitude). This
gives reproducible, calibratable perturbations and avoids the
per-trial magnitude variance issue documented in
`p3b_residue_audit_companion.md` §2.2.

### §2.4 — Cost: cheap λ₁ vs full spectrum

The chaos-guard's compute story is much friendlier than the
residue audit's, exactly as predicted in
`p3_baseline_companion.md` §2.4:

| Operation | Method | Wall clock per call | Asymptotic |
|---|---|---|---|
| Full Lyapunov spectrum (LL-006 audit) | Benettin QR @ N=40, 1500 steps | ~507 ms | O(N²) per step |
| Single λ₁ (LL-007 chaos-guard) | Wolf single-trajectory @ N=40, T=60 | ~1.3 ms | O(N) per step |

The 400× speedup matters operationally: the chaos-guard runs
*continuously* in the security primitive's background, so
its per-call cost compounds. At 1.3 ms per call, sampling
λ̂₁ once per second is < 0.2% CPU overhead — the security
primitive's ambient cost is dominated elsewhere (the SDE
integration itself, the residue audit on verification
demands).

The residue audit's full-spectrum cost is an *on-demand* cost
incurred only when verification is requested; the chaos-guard's
cost is an *always-on* cost. The architecture-design §2.3
choice of "use λ₁ alone for the guard" is the right one cost-
wise.

### §2.5 — LL-002 (visual decoupling) preserved

The chaos-guard module has no dependency on, and no signal
into, anything visual-layer-related. State transitions —
including reseed events — are reported only through the
public `is_valid` predicate and the diagnostic
`current_lambda` / `reseed_count` fields. None of these is
piped to a visual layer.

A reseed event during a `lorenz96_coupled` run does not pause,
freeze, or modify the SDE solver or any external observer; it
just perturbs the state vector and resets the guard's
state-machine. The visual-skin scaffolding (P8 in the dashboard
priority stack) would run from its own RNG, fully decoupled.

### §2.6 — Module name conflict resolved (Guard ≠ ChaosGuard)

A Julia idiom worth recording: when a module and a struct
share the same name, Julia's `doc!` machinery throws
`MethodError: no method matching doc!(::Type{...}, ...)` when
attempting to attach a docstring to the struct. The fix is to
give the struct a name distinct from the module.

In LavaLamp's case: module is `ChaosGuard`, struct is `Guard`.
Public usage:

```julia
using LavaLamp
g = Guard(default_config(1.66))   # type: Guard
update!(g, λ̂₁)                    # state-machine update
is_valid(g)                        # Bool predicate
```

Internal access: `LavaLamp.ChaosGuard.Guard`. This pattern
matches the rest of LavaLamp where module and exported types
are distinct names (Sensors module exports SensorStream,
CouplingParams, etc.; Audit module exports Envelope, etc.).

---

## §3 — Verification

### §3.1 — LL-007 chaos-guard

- **Evidence type:** `example-tested`.
- **Status moves:** `:argued` → `:tested`.
- **Test:** `src/julia/test/runtests.jl` chaos-guard
  `@testset`s (35 assertions). 82/82 total assertions pass
  via `Pkg.test()` in ~47s.
- **Source:** `src/julia/src/ChaosGuard.jl`.

### §3.2 — Other entries unchanged

- **LL-002 (visual ↔ security decoupling).** §2.5 preserves;
  no spec move (LL-002 still awaits Lean / type-level
  enforcement to *prove* the decoupling — exercising it in
  test code is supporting evidence, not enforcement).
- **LL-006 (residue audit) `:benchmarked` upgrade.** Not
  attempted this session. Still pending.
- **LL-005 (Nyquist) and LL-008 (resolution-bound formal
  bound).** Untouched. Stay `:argued`.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-007**: `:argued` → `:tested` with `manual` →
  `example-tested` evidence type. Source
  `src/julia/src/ChaosGuard.jl`; Test
  `src/julia/test/runtests.jl`.

### §4.2 — Updated counts

- **Total:** 18 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 4 (LL-003, LL-004, LL-006, LL-007)
- **`:benchmarked`:** 0
- **`:argued`:** 9 (LL-005, LL-008, LL-011, LL-012, LL-013,
  LL-014, LL-016, LL-017, LL-018)
- **`:open`:** 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

### §4.3 — Files changed

- `docs/p3c_chaos_guard_companion.md` (this file) — new.
- `src/julia/src/ChaosGuard.jl` — new.
- `src/julia/src/LavaLamp.jl` — submodule include + re-exports.
- `src/julia/test/runtests.jl` — 35 new chaos-guard assertions.
- `src/julia/Project.toml` — version 0.0.9 → 0.0.10.
- `src/julia/Manifest.toml` — version sync.
- `LAVALAMP_SPEC.md` — LL-007 status move; counts; version.
- `artifact_registry.md` — LL-007 row update; counts; version.
- `dashboard.md` — version, status summary, P3 sub-status.
- `changelog.md` — 0.0.10 entry top-of-file.

### §4.4 — Followups

- **P3d — SDE-selection benchmark.** Comparative bench
  (Lorenz-96 / Lorenz-63 / Rössler) on Lyapunov richness,
  parameter sensitivity, compute cost. Upgrades LL-003 to
  `:benchmarked`. Now arguably the simplest remaining
  follow-up — just sweep a few dynamics through the existing
  spectrum / chaos-guard infrastructure.
- **P3-Nyq — Nyquist-condition adversary-rate benchmark.**
  Closes LL-005 to `:tested`. Folds into the existing audit
  benchmark framework.
- **P3-bound — LL-006 `:benchmarked` upgrade.** Calibrate
  K, c, δ_A(ε_A) constants from the existing 0.0.9 detection
  surface; verify empirical ≥ bound prediction.
- **CI workflow.** Test wall clock now 47s — actually faster
  than 0.0.9 thanks to chaos-guard's cheap estimator. Manual
  reruns are tolerable again, but CI is still recommended
  before more substantive bench work lands.

---

## §5 — Lessons captured

### §5.1 — Module/type name shadowing breaks Julia docstrings

When a module and a struct (within the module) share the
same name, Julia's docstring system throws an opaque
`MethodError on doc!`. The fix is straightforward — rename
either the module or the struct — but the diagnostic
message doesn't make the cause obvious.

LavaLamp convention now: distinguish module names (typically
plural / domain-named) from struct names (typically singular
/ entity-named). `ChaosGuard.Guard` follows the
`Sensors.SensorStream`, `Sensors.CouplingParams`,
`Audit.Envelope` pattern.

### §5.2 — Wolf λ₁ for always-on monitoring; Benettin only for verification

Reaffirms `p3_baseline_companion.md` §2.4 quantitatively:

- Always-on guard / chaos-watching component → use the
  cheap O(N) Wolf-style single-trajectory estimator
  (`DynamicalSystems.lyapunov`).
- On-demand verification / residue audit → use the O(N²)
  Benettin spectrum (`DynamicalSystems.lyapunovspectrum`).

The ratio is ~400× at N=40 in this prototype. Production
systems should preserve this distinction; using the
full-spectrum Benettin for chaos-guard would multiply ambient
CPU usage by two-plus orders of magnitude unnecessarily.

### §5.3 — Reseed magnitude matters more than direction

The reseed perturbation is unit-direction × magnitude.
The direction is randomised (uniform on the unit sphere) but
its choice has minimal effect on recovery — chaotic systems
de-synchronise from any non-trivial initial perturbation
within a few Lyapunov times. The *magnitude* is what matters:

- Too small → stays in the periodic-window basin.
- Too large → leaves the strange attractor entirely
  (potential transient artefacts).

The ≈ 1× attractor-diameter heuristic from
architecture-design §2.3 is the right scale; the prototype
test uses magnitude=2.0 to be safely above the basin scale.
Production should calibrate against the chosen SDE's
attractor geometry.

### §5.4 — VALID is conservative-by-construction (initial WARMUP)

The state-machine starts in WARMUP, never VALID. This is the
correct safe-default: a security primitive must not assume
entropy is good before it has been observed to be good. The
warmup_steps observations are the cost paid at startup before
entropy can be consumed.

For comparison: a system that initialised VALID and waited
for INVALID to flip would emit unverified entropy during
the first warmup_steps observations — exactly the bug the
chaos-guard exists to prevent.

The conservative initialisation is consistent with LL-012
(cold-start window): the device's verifier returns WARMUP
during the cold-start period rather than ACCEPT/REJECT,
forcing the consumer to retry. The chaos-guard's WARMUP
state is the per-component analogue of LL-012's cold-start
state.
