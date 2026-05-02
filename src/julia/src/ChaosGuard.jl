"""
ChaosGuard — real-time periodic-window safety signal for the
LavaLamp security primitive (LL-007).

Architecture-design §2.3: a background process estimates the
largest Lyapunov exponent λ̂₁ in real time. If `λ̂₁ < τ_λ` the
system has stalled into a periodic window; mark the entropy
INVALID and reseed via host TRNG. After reseed, require
sustained `λ̂₁ ≥ recovery_threshold` over `warmup_steps` updates
before re-marking VALID.

Conventions in force:
- The chaos-guard runs on the *security primitive* only. It
  does not signal to a notional visual layer (LL-002 decoupling
  preserved).
- λ̂₁ estimation uses the cheap Wolf-style single-trajectory
  algorithm (`DynamicalSystems.lyapunov`) — O(N) per step
  rather than O(N²) for full Benettin spectrum. The guard
  needs only λ₁; full spectrum is the residue audit's job.
- Strict comparison `λ̂₁ < τ_λ` triggers INVALID; equality
  passes (conservative on the genuine-device side).
- Reseed perturbation magnitude is ≈ 1× attractor diameter by
  default, sufficient to escape periodic-window basins per
  §2.3.

API STABILITY: experimental (P3c-stage).
"""
module ChaosGuard

using Random: AbstractRNG, default_rng
using DynamicalSystems: DynamicalSystem, current_state, set_state!

export GuardState, INVALID, WARMUP, VALID
export GuardConfig, default_config
export Guard, update!, is_valid, current_lambda, reseed!

"""
    GuardState

Three-state machine for the entropy validity signal:
- `INVALID`: λ̂₁ has dropped below `τ_λ`. Entropy is rejected.
- `WARMUP`: post-reseed (or initial) state. λ̂₁ is climbing
  but not yet sustained above `recovery_threshold` for the
  required number of updates.
- `VALID`: λ̂₁ has been sustained above `recovery_threshold`
  for at least `warmup_steps` updates. Entropy is accepted.

State transitions:
- Any → INVALID when `λ̂₁ < τ_λ`.
- INVALID → WARMUP when `λ̂₁ ≥ recovery_threshold` for the
  first time after the drop.
- WARMUP → VALID when `λ̂₁ ≥ recovery_threshold` for
  `warmup_steps` consecutive updates.
- VALID → VALID while `λ̂₁ ≥ τ_λ`. (Brief dips in the
  recovery-to-τ_λ range do *not* invalidate; only true
  collapse to ≤ τ_λ does.)
"""
@enum GuardState INVALID WARMUP VALID

"""
    GuardConfig(τ_λ, recovery_threshold, warmup_steps)

Configuration for a `Guard`. All thresholds are absolute
values of λ̂₁ (chaos-production rate per unit time).

Recommended starting values for Lorenz-96 N=40, F=8:
- `τ_λ = 0.1 · λ₁_expected ≈ 0.17` (factor-of-10 collapse from
  expected λ₁ ≈ 1.66 is a safe periodic-window signature).
- `recovery_threshold = 5 · τ_λ ≈ 0.83` (avoids flapping
  between regimes; chaotic Lorenz-96 sits well above this).
- `warmup_steps = 10` for the prototype (architecture-design
  §2.3 suggests `2W` of sliding-window updates; W ≈ 100
  Lyapunov times). The prototype's per-update window length
  is the user's choice; warmup_steps counts updates.
"""
struct GuardConfig
    τ_λ::Float64
    recovery_threshold::Float64
    warmup_steps::Int

    function GuardConfig(τ_λ::Real, recovery_threshold::Real,
                              warmup_steps::Integer)
        τ_λ > 0 || throw(ArgumentError("τ_λ must be positive"))
        recovery_threshold > τ_λ ||
            throw(ArgumentError(
                "recovery_threshold ($recovery_threshold) must exceed τ_λ ($τ_λ); "
                * "otherwise WARMUP→VALID can fire from a sample below the rejection floor"))
        warmup_steps >= 1 ||
            throw(ArgumentError("warmup_steps must be ≥ 1"))
        return new(Float64(τ_λ), Float64(recovery_threshold), Int(warmup_steps))
    end
end

"""
    default_config(λ₁_expected::Real=1.66; warmup_steps::Int=10)

Construct a `GuardConfig` from a single expected-λ₁ value
using the architecture-design §2.3 ratios:
- `τ_λ = 0.1 · λ₁_expected`
- `recovery_threshold = 5 · τ_λ = 0.5 · λ₁_expected`
- `warmup_steps` defaults to 10.
"""
function default_config(λ₁_expected::Real=1.66; warmup_steps::Int=10)
    τ_λ = 0.1 * Float64(λ₁_expected)
    recovery = 5 * τ_λ
    return GuardConfig(τ_λ, recovery, warmup_steps)
end

"""
    Guard

Mutable state machine for the chaos-guard. Construct with a
`GuardConfig`; the new guard starts in `WARMUP` (not
`VALID` — the security primitive must not assume entropy is
good before the dynamics has been observed to be chaotic).

Fields:
- `config::GuardConfig` — fixed thresholds.
- `state::GuardState` — current state.
- `consecutive_recovery::Int` — count of recent samples ≥
  `recovery_threshold` (resets on dips and on reseed).
- `last_lambda::Float64` — most-recent λ̂₁ fed to `update!`;
  `NaN` before any update. Diagnostic only — does not leak
  through public verifier output (LL-017).
- `reseed_count::Int` — number of `reseed!` calls since
  construction. Diagnostic.
"""
mutable struct Guard
    config::GuardConfig
    state::GuardState
    consecutive_recovery::Int
    last_lambda::Float64
    reseed_count::Int

    function Guard(config::GuardConfig)
        return new(config, WARMUP, 0, NaN, 0)
    end
end

"""
    update!(guard::Guard, λ̂₁::Real) -> GuardState

Apply one λ̂₁ observation to the guard, transitioning the state
machine per the §2.3 logic. Returns the post-update state.
"""
function update!(guard::Guard, λ̂₁::Real)
    λ = Float64(λ̂₁)
    guard.last_lambda = λ
    cfg = guard.config

    # Highest priority: rejection on collapse.
    if λ < cfg.τ_λ
        guard.state = INVALID
        guard.consecutive_recovery = 0
        return guard.state
    end

    # Above τ_λ. If below recovery_threshold, the sample is in
    # the gray band: not rejected but not graduating.
    if λ < cfg.recovery_threshold
        if guard.state == WARMUP
            guard.consecutive_recovery = 0
        end
        # VALID stays VALID through brief dips in the gray band
        # (chaotic systems fluctuate); INVALID stays INVALID.
        return guard.state
    end

    # Above recovery_threshold. Counts toward graduation.
    if guard.state == VALID
        # Already valid; nothing to do.
        return guard.state
    end

    if guard.state == INVALID
        # First recovery sample after collapse → enter WARMUP.
        guard.state = WARMUP
        guard.consecutive_recovery = 1
        if guard.consecutive_recovery >= cfg.warmup_steps
            guard.state = VALID
        end
        return guard.state
    end

    # In WARMUP, sample above recovery_threshold counts.
    guard.consecutive_recovery += 1
    if guard.consecutive_recovery >= cfg.warmup_steps
        guard.state = VALID
    end
    return guard.state
end

"""
    is_valid(guard::Guard) -> Bool

True iff the guard is currently in `VALID`. Downstream entropy
consumers MUST gate on this predicate; entropy emitted while
`!is_valid(guard)` is rejected.
"""
is_valid(guard::Guard) = guard.state == VALID

"""
    current_lambda(guard::Guard) -> Float64

The most recently fed λ̂₁. Returns `NaN` before any `update!`.
Diagnostic only — does *not* leak through the public verifier
interface (LL-017). For internal logging / off-line analysis.
"""
current_lambda(guard::Guard) = guard.last_lambda

"""
    reseed!(ds::DynamicalSystem, guard::Guard;
            rng::AbstractRNG=default_rng(),
            magnitude::Real=1.0) -> GuardState

Reseed the dynamical system's state by adding a TRNG-derived
unit-vector perturbation of L2 magnitude `magnitude` to the
current state. Resets the guard to `WARMUP` with
`consecutive_recovery = 0`; increments `reseed_count`.

`magnitude=1.0` is the prototype default (≈ 1× attractor
diameter for the Lorenz-96 N=40, F=8 baseline). Production
deployments should calibrate against the chosen SDE's
attractor radius.

The reseed source is the supplied `rng`; production should
pass `Random.default_rng()` or a seeded TRNG-backed RNG. The
perturbation is unit-direction × magnitude (deterministic
magnitude per call), matching the synthetic-adversary
semantic from `Audit.synthetic_adversary`.
"""
function reseed!(ds::DynamicalSystem, guard::Guard;
                 rng::AbstractRNG=default_rng(),
                 magnitude::Real=1.0)
    u = copy(current_state(ds))
    n = length(u)
    n > 0 || throw(ArgumentError("cannot reseed empty state"))
    perturbation = randn(rng, n)
    nrm = sqrt(sum(perturbation .^ 2))
    if nrm > 0
        u .+= perturbation .* (Float64(magnitude) / nrm)
    end
    set_state!(ds, u)
    guard.state = WARMUP
    guard.consecutive_recovery = 0
    guard.reseed_count += 1
    return guard.state
end

end # module ChaosGuard
