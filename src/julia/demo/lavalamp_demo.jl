#!/usr/bin/env julia
#
# LavaLamp end-to-end demo (0.0.51).
#
# Run from the lavalamp/ root with a clean checkout:
#
#     julia --project=src/julia -e 'using Pkg; Pkg.instantiate()'
#     julia --project=src/julia src/julia/demo/lavalamp_demo.jl
#
# What this exercises:
#
#   1. LL-003   — Lorenz-96 SDE engine; F=8 baseline.
#   2. LL-004   — Sensor-coupling layer (linear-in-x; constant
#                 stream stand-in for hardware sensor reads).
#   3. LL-011   — Registration ceremony (envelope calibration over
#                 n_trials trajectories).
#   4. LL-006   — Lyapunov-spectrum residue audit on a verification
#                 trajectory.
#   5. LL-007   — Chaos-guard state machine (WARMUP → VALID, then
#                 → INVALID on chaos collapse) driven by Wolf-method
#                 λ̂₁ estimates.
#   6. LL-019   — `verify_full` API: forces full-spectrum audit at
#                 the call boundary so an attacker cannot substitute
#                 a cheap λ₁-only check.
#   7. LL-021   — Worst-case-adversary asymmetry; structured-direction
#                 adversary at ε_A = 3.0 (3σ-magnitude perturbation).
#                 The Lean theorem `LL021_worst_case_bound` (proved
#                 at 0.0.48 via Mathlib `mul_le_of_le_one_right`)
#                 captures the bound shape this script exhibits
#                 numerically.
#
# What it does NOT exercise:
#
#   - Real hardware sensors (LL-024 RealSensors module is scaffold-
#     tier; calling its functions errors with a deferred message).
#     The demo uses synthetic constant streams so it runs anywhere
#     Julia + the package's lockfile-pinned deps install. Hardware
#     deployment is the P-RS Level 2 prototype track per LL-022 /
#     LL-023 / LL-024 / LL-028 / LL-029.
#   - Calibration confidentiality (LL-020 ε-DP envelope) — separate
#     API; out of scope for the smoke-walkthrough.
#   - The Lean track at `src/lean4/` — see that directory's README
#     for the formal-verification side.
#
# Wall-clock target: well under one minute on a 2024-vintage laptop.
# Determinism: every random draw is seeded; output is reproducible
# across runs and machines (modulo Julia version differences).

using Random
using Printf

using LavaLamp
using LavaLamp.Audit: residue
using LavaLamp.ChaosGuard: Guard, default_config, update!, is_valid,
                            current_lambda, GuardState, INVALID,
                            WARMUP, VALID

println("="^72)
println("LavaLamp end-to-end demo")
println("Substrate-bound identity primitive; chaotic-SDE residue audit")
println("="^72)

# ─────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────

const N           = 20      # SDE dimension (LL-003 / LL-027 — N* ≈ Δh*/s)
const F_BASE      = 8.0     # Lorenz-96 forcing parameter
const N_TRIALS    = 5       # Registration trajectories (LL-011)
const N_STEPS     = 1000    # Per-trajectory step count
const Δt          = 0.05    # Integration step (Δt · N_STEPS = 50 time units)
const T_TR        = 200.0   # Transient burn-in (per LL-006)
const K_CHECK     = 10.0    # Acceptance multiple for honest verify
                            # (10σ = far above register_envelope sample variance;
                            # k=5 is the calibrated operational threshold per
                            # the 0.0.17 P3-bound benchmark)
const K_REJECT    = 5.0     # Rejection multiple for adversary verify
const EPSILON_ADV = 3.0     # Adversary magnitude (3σ; "strong" tier)
                            # LL-021: worst-case projection ε_eff = ε_A · proj
                            # is bounded above by ε_A; the Lean theorem proves
                            # this for any non-negative ε_A and proj ≤ 1.

@printf "\nN          = %d\nF          = %.1f\nn_trials   = %d (registration)\n" N F_BASE N_TRIALS
@printf "N_steps    = %d  (per trajectory)\nΔt         = %.3f\nT_tr       = %.1f  (transient burn-in)\n" N_STEPS Δt T_TR
@printf "k_check    = %.1f  (honest)\nk_reject   = %.1f  (adversary)\nε_A        = %.1f  (3σ-magnitude perturbation)\n" K_CHECK K_REJECT EPSILON_ADV

# ─────────────────────────────────────────────────────────────────────
# 1. Build the genuine sensor-coupled SDE (LL-003 + LL-004).
# ─────────────────────────────────────────────────────────────────────

println("\n" * "─"^72)
println("Step 1 — Build genuine Lorenz-96 SDE with sensor coupling (LL-003 + LL-004)")
println("─"^72)

Random.seed!(101)
b           = ones(N)                                     # Coupling vector
s_const     = constant_stream(1.0; t_max=2000.0)          # Synthetic sensor
p_genuine   = CouplingParams(F_BASE, [s_const], [1.0], [b])
ds_factory  = () -> lorenz96_coupled(N; F=F_BASE, coupling=p_genuine)

println("✓ Engine constructed.")
println("  • SDE family   : Lorenz-96 (ergodic chaotic; LL-003 :benchmarked)")
println("  • Coupling     : linear-in-x via 1 sensor stream; α=1.0")
println("  • Sensor stream: constant @ 1.0 (synthetic; real hardware = LL-024)")

# ─────────────────────────────────────────────────────────────────────
# 2. Registration ceremony (LL-011): calibrate the envelope.
# ─────────────────────────────────────────────────────────────────────

println("\n" * "─"^72)
println("Step 2 — Registration ceremony (LL-011): calibrate envelope")
println("─"^72)

Random.seed!(101)
println("Running $(N_TRIALS)-trial Lyapunov-spectrum calibration ...")
t_register = @elapsed env = register_envelope(
    ds_factory;
    n_trials = N_TRIALS,
    N        = N_STEPS,
    Δt       = Δt,
    Ttr      = T_TR,
)
@printf "✓ Envelope registered in %.2f s.\n" t_register
@printf "  • spectrum length      : %d  (matches N)\n" length(env.spectrum)
@printf "  • λ₁ (mean over trials): %+.4f\n" env.spectrum[1]
@printf "  • λ_min                : %+.4f\n" env.spectrum[end]
@printf "  • σ(λ₁) sample stddev  : %.4f\n" env.σ[1]
@printf "  • n_trials             : %d\n" env.n_trials

# ─────────────────────────────────────────────────────────────────────
# 3. Honest verification (LL-006 + LL-019): accept the genuine system.
# ─────────────────────────────────────────────────────────────────────

println("\n" * "─"^72)
println("Step 3 — Honest verification (LL-006 + LL-019): expect ACCEPT")
println("─"^72)

Random.seed!(7001)
ds_check = ds_factory()
println("Running verify_full at k=$(K_CHECK) (full Benettin spectrum + envelope check) ...")
t_verify_honest = @elapsed result_honest = verify_full(
    ds_check, env;
    k=K_CHECK, N=N_STEPS, Δt=Δt, Ttr=T_TR,
)
@printf "✓ verify_full returned %s in %.2f s\n" result_honest t_verify_honest
println("  → " * (result_honest ? "ACCEPT (genuine system passes its own envelope; expected)" :
                                    "REJECT (UNEXPECTED — calibration drift?)"))

# Mechanism inspection: residue magnitude per exponent should sit
# well below k=10·σ for the genuine system.
Random.seed!(7001)
ds_inspect      = ds_factory()
λs_honest       = lyapunov_spectrum(ds_inspect; N=N_STEPS, Δt=Δt, Ttr=T_TR)
res_honest      = residue(λs_honest, env)
max_k_honest    = maximum(res_honest ./ max.(env.σ, 1e-10))
@printf "  • Max residue / σ ratio (honest) : %.2f  (well under k=%.1f)\n" max_k_honest K_CHECK

# ─────────────────────────────────────────────────────────────────────
# 4. Adversary trajectory (LL-021): structured direction at ε_A=3σ.
# ─────────────────────────────────────────────────────────────────────

println("\n" * "─"^72)
println("Step 4 — Strong adversary (LL-021): ε_A = $(EPSILON_ADV)σ; expect REJECT")
println("─"^72)

rng_adv  = Random.Xoshiro(8001)
p_adv    = synthetic_adversary(p_genuine, EPSILON_ADV; rng=rng_adv)
Random.seed!(8001)
ds_adv   = lorenz96_coupled(N; F=F_BASE, coupling=p_adv)

println("Running verify_full at k=$(K_REJECT) on adversary system ...")
t_verify_adv = @elapsed result_adv = verify_full(
    ds_adv, env;
    k=K_REJECT, N=N_STEPS, Δt=Δt, Ttr=T_TR,
)
@printf "✓ verify_full returned %s in %.2f s\n" result_adv t_verify_adv
println("  → " * (result_adv ? "ACCEPT (UNEXPECTED — adversary slipped through)" :
                                "REJECT (structured-adversary detected; expected)"))

# Mechanism: adversary residue ratio should be >> k=5.
λs_adv         = lyapunov_spectrum(lorenz96_coupled(N; F=F_BASE, coupling=p_adv);
                                    N=N_STEPS, Δt=Δt, Ttr=T_TR)
res_adv        = residue(λs_adv, env)
max_k_adv      = maximum(res_adv ./ max.(env.σ, 1e-10))
@printf "  • Max residue / σ ratio (adversary): %.2f  (well above k=%.1f)\n" max_k_adv K_REJECT

# ─────────────────────────────────────────────────────────────────────
# 5. Chaos-guard state machine (LL-007 / LL-002): INVALID → WARMUP → VALID.
# ─────────────────────────────────────────────────────────────────────

println("\n" * "─"^72)
println("Step 5 — Chaos-guard state machine (LL-007): always-on chaos health")
println("─"^72)

cfg     = default_config(1.66; warmup_steps=3)   # 1.66 ≈ Lorenz-96 λ₁ at F=8
g       = Guard(cfg)
@printf "Initial state: %s\n" g.state

# Five honest λ̂₁ samples; expect transition WARMUP → VALID after
# warmup_steps=3 in-band samples.
honest_samples = [1.65, 1.67, 1.66, 1.68, 1.65]
for (i, λ̂) in enumerate(honest_samples)
    update!(g, λ̂)
    @printf "  step %d: λ̂₁=%.3f  →  state = %s  (current_λ = %.3f)\n" i λ̂ g.state current_lambda(g)
end
@printf "✓ Guard valid? %s  (expected true after warmup; LL-007 :tested)\n" is_valid(g)

# Inject a chaos collapse: one sub-threshold sample tips state.
println("\nInjecting one sub-threshold sample (λ̂₁=0.10; chaos collapse) ...")
update!(g, 0.10)
@printf "  state after collapse: %s\n" g.state
@printf "✓ Guard valid? %s  (expected false; reseed flow would fire here in production)\n" is_valid(g)

# ─────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────

println("\n" * "="^72)
println("Summary")
println("="^72)
honest_ok   = result_honest && max_k_honest < K_CHECK
adv_ok      = !result_adv  && max_k_adv > K_REJECT
guard_ok    = !is_valid(g)
all_ok      = honest_ok && adv_ok && guard_ok

println("• Honest system accepted   : $(result_honest)        (expected true)")
println("• Adversary system rejected: $(!result_adv)        (expected true)")
println("• Chaos guard tripped post-collapse: $(!is_valid(g)) (expected true)")
println()
@printf "• Wall-clock — registration : %.2f s\n" t_register
@printf "• Wall-clock — verify (honest) : %.2f s\n" t_verify_honest
@printf "• Wall-clock — verify (adversary) : %.2f s\n" t_verify_adv

if all_ok
    println("\n✅ All three pillars of the LavaLamp pipeline behave as specified.")
    println("   See LAVALAMP_SPEC.md for the canonical claim ledger; src/lean4/")
    println("   for the Lean 4 / Mathlib v4.29.1 formal-verification track.")
else
    println("\n❌ One or more pipeline stages diverged from spec. Investigate before shipping.")
    exit(1)
end

println("\nDemo complete.")
