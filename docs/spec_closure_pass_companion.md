# Spec Closure Pass — Four `:open` → `:argued` Moves

Version: 0.0.20 (closure pass — LL-001/002/009/010 →
`:argued`, 2026-05-03)

Permanent record of a focused closure-pass session: four
`:open` spec entries move to `:argued` based on evidence
already accumulated across previous sessions, without
adding new specs or new code. The moves bring the project's
`:open` count from 5 to 1 (only LL-015 A3-OOS remains, by
design — it is a scoping declaration with no verification
path).

This is finishing work, not growth. Every claim moved here
was already substantively supported by earlier sessions'
evidence; this companion makes the support explicit and
elevates the spec status to match the honest tier.

---

## §1 — LL-001 substrate-bound-identity-primitive

### §1.1 — Claim

> Device identity is realised as the sustained chaotic
> trajectory of an SDE solver running on the device, with
> noise / parameter terms coupled to live hardware sensors.
> The identity is a continuous *function of (machine,
> configuration, time)*, not a static credential.
> Verification compares trajectory features against a
> registered hardware envelope.

### §1.2 — Evidence

LL-001 is a *composed* claim — its content is realised by
the conjunction of four lower-level entries:

| Component | Spec | Status | Evidence |
|---|---|---|---|
| SDE solver producing a sustained chaotic trajectory | LL-003 | `:tested` | `src/julia/test/runtests.jl` Lorenz-96 N=40, F=8 reproduces literature (λ₁ ≈ 1.66, h_KS ≈ 10.5) |
| Sensor coupling making the trajectory a function of configuration | LL-004 | `:tested` | `src/julia/test/runtests.jl` non-degeneracy: Δλ₁ ≈ +0.30 at α=1, +0.59 at α=2 |
| Verification comparing trajectory features against a registered envelope | LL-006 | `:benchmarked` | `src/julia/benchmark/p3_bound_high_res_lorenz96.txt` detection bound P(detect) ≥ 1 - K·exp(-c·T·δ²) with K=1, c′=0.00423, T=60 fitted; `src/julia/benchmark/results/p_r2c_structured_lorenz96.txt` worst-case bound K=1, c′=0.02777 |
| Real-time validity check via λ̂₁ monitoring | LL-007 | `:tested` | `src/julia/test/runtests.jl` chaos-guard state machine + Lorenz-96 chaotic vs sub-chaotic detection |

LL-001's claim ("identity is the sustained trajectory + a
verifier compares trajectory features against an envelope")
is substantively *what the test suite + the benchmark
output realises*. The audit benchmark (LL-006) is precisely
the test of LL-001's verification mechanism: it
demonstrates that genuine devices (with their substrate-
coupled trajectories) verify correctly, and that adversaries
(without the substrate coupling) are detected with
empirically-bounded probability.

### §1.3 — Why `:argued` and not `:tested`

LL-001 is at a higher abstraction level than its components.
The components are individually `:tested` / `:benchmarked`;
LL-001's *claim* is that the components compose to realise
"identity as substrate-coupled trajectory." The composition
is honoured by the existing test infrastructure (the audit
benchmark exercises the composed system end-to-end), but
there is no separate test asserting "the composed system's
behavior implements identity-as-trajectory."

A `:tested` upgrade would require either (a) a Lean / type-
level enforcement of the composition property, or (b) a
test suite written specifically against LL-001's higher-
level claim rather than against the components.

For the prototype's closure pass, `:argued` is the honest
tier: the components are tested individually, and the
composition argument is documented here.

### §1.4 — Decision

**`:open` → `:argued`** with `manual` evidence type. Source:
this companion §1.

---

## §2 — LL-002 visual-security-decoupling invariant

### §2.1 — Claim

> The user-facing lava-lamp visual animation does *not*
> derive from the security-critical SDE trajectory. The
> visual can be driven by any RNG (including a simple
> Math.random()-style bubble simulator) and is decorative
> only. The security primitive (chaotic SDE + sensor
> coupling + Lyapunov-spectrum residue audit) runs as an
> independent background process.

### §2.2 — Evidence

LL-002 is preserved by construction across the entire P3
prototype:

- **No visual layer exists.** The Julia prototype implements
  the security primitive (`Sensors.jl`, `Engine.jl`,
  `Audit.jl`, `ChaosGuard.jl`) and the test infrastructure
  (`test/runtests.jl`, `benchmark/`). There is no visual /
  animation / RNG-decoration code in the repository.
- **The security primitive has no visual-layer dependencies.**
  Inspecting the imports of `LavaLamp.jl` and its
  submodules: `Random`, `DynamicalSystems`, `StaticArrays`,
  `Statistics`. No graphics / animation library; no signal
  channel into anything that could feed a visual.
- **No session has proposed re-coupling.** Across 0.0.5
  (P2 design), 0.0.6 (P3 baseline), 0.0.8 (P3a), 0.0.9
  (P3b), 0.0.10 (P3c), 0.0.12 (round 2), 0.0.14 (P-R2a),
  0.0.15 (P-R2c), 0.0.16 (P-R2b), 0.0.17–0.0.19
  (:benchmarked cohort), the asymmetry-trap watch in
  `dashboard.md` was checked. No commit reintroduced visual
  coupling. The decoupling discipline has held.
- **Round-2 reviewers treated LL-002 as settled.** Per
  `docs/synthesis_team_round2_companion.md` §5.4 ("Asymmetry-
  trap watch held"), both Gemini and Grok treated the
  visual ↔ security decoupling as architectural ground; no
  proposed re-coupling.
- **Chaos-guard reseed events do not signal to a visual.**
  Per `docs/p3c_chaos_guard_companion.md` §2.5: reseeds are
  logged internally; no visual-layer integration.

### §2.3 — Why `:argued` and not `:tested`

There is no test asserting "the visual layer (which doesn't
exist) is decoupled from the security primitive." This is
a non-test by definition. To `:test` LL-002 we would need
either (a) a visual layer that demonstrably runs from
independent RNG, with a test asserting the security
primitive's outputs do not feed it, or (b) a type-level /
Lean proof that the security-primitive type-graph cannot
reach the visual-layer type-graph.

For the prototype's closure pass, `:argued` is the honest
tier: the invariant is preserved by construction and by
session discipline, and that argument is documented here.

### §2.4 — Decision

**`:open` → `:argued`** with `manual` evidence type. Source:
this companion §2.

---

## §3 — LL-009 no-complex-numbers boundary

### §3.1 — Claim

> The security primitive (SDE, sensor coupling, residue
> audit) uses only real-valued mathematics. Complex numbers
> are forbidden in any code path that contributes to
> identity / verification.

### §3.2 — Evidence

LL-009 is a corpus-wide boundary inherited from the broader
LavaLamp / Possibilistic Security context (`CLAUDE.md` §
Load-bearing scope boundaries). The closure-pass argument
specialises it to the LavaLamp-specific context.

In the Julia prototype:

- **All state vectors are `Float64` real-valued.** The
  Lorenz-96 implementation in `Engine.jl` uses
  `Vector{Float64}` throughout. No `ComplexF64` /
  `Complex{Float64}` types.
- **All coupling vectors are real.** `Sensors.jl`'s
  `CouplingParams.coupling_vectors` is
  `Vector{Vector{Float64}}`.
- **All sensor stream values are real.** `SensorStream.values`
  is `Vector{Float64}`.
- **All Lyapunov spectrum estimates are real.** `lyapunov_spectrum`
  via `DynamicalSystems.jl`'s `lyapunovspectrum` returns
  real-valued vectors for our SDE class (real-valued
  dynamics → real-valued spectrum).
- **All envelope values are real.** `Audit.jl`'s `Envelope`
  has `spectrum::Vector{Float64}` and `σ::Vector{Float64}`.
- **The residue audit's per-component test is real.**
  `verify` computes `abs(λ̂_i - λ_i)` (real Float64)
  against `k · σ_i` (real Float64).

### §3.3 — Round-1 enforcement

`docs/synthesis_team_round1_companion.md` §1D records the
round-1 SGL (Stochastic Ginzburg-Landau, complex-valued)
slip and its rejection: Gemini's premature skeleton used
`Matrix Complex Double`; the LL-009 boundary was reaffirmed
and Gray-Scott (real-valued) was the on-frame swap. The
P3 prototype does not include either; the boundary held
through the P3 implementation work.

### §3.4 — Why `:argued` and not `:tested`

The boundary is honoured by *type choice* (Float64
throughout) rather than by *runtime check*. There is no
test asserting "no complex numbers exist anywhere in the
security path." To `:test` LL-009 we would need either
(a) a static analysis pass over the code asserting no
`Complex` types touch security-critical paths, or (b) a
Lean / type-level proof. Both are out of scope for the
prototype.

For the closure pass, `:argued` is the honest tier: the
boundary is preserved by construction (Float64 type
choice) and the audit trail of session discipline.

### §3.5 — Decision

**`:open` → `:argued`** with `manual` evidence type. Source:
this companion §3.

---

## §4 — LL-010 no-open-ended-simulation boundary

### §4.1 — Claim

> LavaLamp solves a *bounded-time* SDE on a *finite* state.
> The system explicitly does not run continuum-limit /
> hypergraph-rewriting / autopoietic dynamics. Trajectories
> are analyzed in bounded windows; no open-ended simulation
> regime.

### §4.2 — Evidence

LL-010 is a corpus-wide safety boundary (see `CLAUDE.md`
§ Load-bearing scope boundaries). The closure-pass argument
specialises it to the LavaLamp prototype:

- **All SDE integrations have bounded T.** Every call to
  `lyapunov_spectrum` takes explicit `N::Int` (number of
  Benettin steps) and `Δt::Float64`. The integration window
  is `T = N · Δt`, bounded. No open-ended runs.
- **All trajectory analyses are over bounded windows.**
  `verify` operates on `λs::Vector{Float64}` (a finite-
  length spectrum estimate). The chaos-guard's sliding
  window is bounded.
- **Finite state.** Lorenz-96 N=20-40 is a finite-dimensional
  state space. No hypergraph-rewriting (which would be
  unbounded-state by design); no continuum-limit dynamics
  (which would require infinite-dimensional state).
- **No autopoietic dynamics.** The prototype does not
  implement self-reproducing structure. The trajectory
  evolves under a fixed SDE; nothing about the SDE's form
  changes during integration.

### §4.3 — The closure_forces_structure corpus connection

LL-010 inherits its motivation from the closure_forces_structure
paper, where Q₁₀₂'s autopoietic structure ("Q₁₀₂ is a
self-reproducing fixed point") is the *target of analysis*
but the *physical instantiation* is explicitly out of scope. LavaLamp's residue audit anchors on the
0/5202 cross-sector autopoiesis result (per
`docs/qkd_pqc_complementarity_companion.md` §2.5) but
does NOT instantiate autopoietic dynamics in the SDE itself.

### §4.4 — Why `:argued` and not `:tested`

LL-010 is preserved by *parameter choice* (bounded N, Δt)
and *system class* (finite-dim Lorenz-96, not hypergraph-
rewriting). There is no test asserting "the system does
not run open-ended simulation." To `:test` we would need
either a Lean enforcement that all integration calls have
bounded T parameters, or a runtime guard. Both are out of
scope for the prototype.

For the closure pass, `:argued` is the honest tier.

### §4.5 — Decision

**`:open` → `:argued`** with `manual` evidence type. Source:
this companion §4.

---

## §5 — Why LL-015 stays `:open`

### §5.1 — Why this is honest

LL-015 (A3 root explicitly out of scope) is a *scoping
declaration*, not a verifiable claim. It states that
LavaLamp does not defend against kernel-level adversaries —
this is a boundary, not a property to prove or disprove.

The CLAUDE.md evidence-type taxonomy doesn't have a
specific status for "scoping declaration"; the closest is
`:open` (no verification, none planned). Moving LL-015 to
`:argued` would be slightly dishonest — there's nothing to
*argue* (no claim being made about LavaLamp's behaviour
against A3 adversaries; the entry simply declares the
adversary class out of scope).

The honest reading: LL-015 is permanently `:open` — not
because it's incomplete, but because its *content* is "no
verification path applies." Future sessions should not
attempt to upgrade it; it stays as the project's permanent
honest-scoping marker.

### §5.2 — Alternative considered: `:argued` with manual evidence

Could argue it's `:argued` ("the deployment context bounds
A3 capability; LavaLamp's scope is bounded accordingly").
But that's not what LL-015 says — LL-015 says "we don't
defend." Honest reading: stay `:open`.

This is the same shape as the lavalamp CLAUDE.md "honest
framing" rule: don't elevate status above what evidence
supports. For a scoping declaration, no evidence is
relevant; `:open` is the floor and the ceiling.

---

## §6 — Considered and dropped: LL-017 `:argued` → `:tested`

### §6.1 — The case for upgrade

LL-017 (verification no-oracle) requires that the
verifier's response not leak threshold geometry beyond
the Bool result and the protocol-level state codes. The
prototype has:

- **Bool-only return type** for `verify` (asserted in
  unit tests at LL-006 mechanism level).
- **Statistically indistinguishable response timing** for
  `verify_constant_time` (validated by KS-test in
  0.0.19 / LL-019 :benchmarked).

The verify-level no-oracle property is therefore
empirically `:tested` by these two: no information leaks
through the result value or through the timing channel.

### §6.2 — Why not upgraded

LL-017's description covers more than verify-level no-
oracle: it also covers protocol-level response codes
(WARMUP, TRANSITIONING, UNKNOWN_CONFIGURATION, RATE_LIMITED)
which are part of the verifier's user-facing surface. The
protocol layer is `:argued` per LL-011/012/013 design but
not implemented in the prototype.

To `:test` LL-017 wholly we would need either (a) protocol-
level implementation + tests, or (b) a subdivision of
LL-017 into LL-017a (verify-level) and LL-017b (protocol-
level). Subdivision counts as adding a new spec entry,
which the closure pass excludes by scope.

Honest tier: LL-017 stays `:argued`. The verify-level
component is :tested-grade evidence supporting the entry,
but the entry as a whole isn't :tested until the protocol-
level component lands.

This is documented here so a future session knows the
verify-level upgrade is *available* once LL-017 is
subdivided or the protocol-level is implemented.

---

## §7 — Spec impact

### §7.1 — Status moves

Four entries move `:open` → `:argued` with `none` →
`manual` evidence type:

| LL-ID | from | to | notes |
|---|---|---|---|
| LL-001 | :open | :argued | composed claim, evidence from LL-003/004/006/007 |
| LL-002 | :open | :argued | preserved by construction (no visual layer) |
| LL-009 | :open | :argued | Float64 throughout the security path |
| LL-010 | :open | :argued | bounded N, Δt; finite-dim system |

### §7.2 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 3 (LL-003, LL-004, LL-007)
- **`:benchmarked`:** 3 (LL-006, LL-019, LL-021)
- **`:argued`:** 14 (was 10; +LL-001, LL-002, LL-009, LL-010)
- **`:open`:** 1 (was 5; only LL-015 remains)

### §7.3 — Files changed

- `docs/spec_closure_pass_companion.md` (this file) — new.
- `LAVALAMP_SPEC.md` — 4 status moves; counts.
- `artifact_registry.md` — 4 row updates; counts.
- `dashboard.md` — status summary; counts; open structural
  questions section now reduced to LL-015.
- `changelog.md` — 0.0.20 entry.

No code changes; no test changes. Pure spec-state finishing.

### §7.4 — What the closure pass establishes

After this commit, **only LL-015 remains `:open`** —
permanently, by design (scoping declaration). Every other
spec entry has at least `:argued` evidence (via design
companions or this closure pass), with seven entries (six
:tested/:benchmarked) having empirical evidence beyond
the design level.

The project's `:open`-count trajectory:

| commit | :open | event |
|---|---|---|
| 0.0.1 | 14 | concept-stage foundation |
| 0.0.3 | 17 | attack-surface enumeration adds LL-015/016/017 |
| 0.0.5 | 6 | P2 design pass closes 11 to :argued; LL-018 added |
| 0.0.6 | 5 | LL-003 :tested |
| 0.0.12 | 8 | round-2 adds LL-019/020/021 |
| 0.0.14 | 7 | LL-019 :tested |
| 0.0.15 | 6 | LL-021 :tested |
| 0.0.16 | 5 | LL-020 :argued |
| 0.0.20 | **1** | this closure pass |

The single remaining `:open` entry (LL-015) is permanent
by honest scoping — not an incomplete TODO.

---

## §8 — Process notes

### §8.1 — Closure-pass discipline

This session demonstrates a useful pattern: periodically,
audit the spec for entries whose evidence is *implicit*
in already-completed work but whose *spec status* has
lagged. Elevate the status to match the evidence.

The pattern depends on:

- **Honest tier framing.** Without it, every "things should
  be argued" intuition produces a status upgrade; with it,
  only entries whose evidence actually meets the
  taxonomy's requirements move.
- **Full audit trail.** Each closed entry needs a clear
  pointer to the evidence. This companion provides those
  pointers per entry.
- **Permanent-`:open` honesty.** Some entries are scoping
  declarations and should stay `:open` permanently.
  Forcing them up is the opposite of honest framing.

### §8.2 — Closure passes don't unblock work

This session does not unblock anything new. The remaining
queue (P3d SDE-selection, P3-Nyq adversary-rate, ε-DP
envelope stub, LL-001/002 :tested via Lean) was already
unblocked by the round-2 :benchmarked cohort completion
(0.0.19). The closure pass just makes the spec state
internally consistent at the new floor.

### §8.3 — Round-3 trigger unchanged

Per `project_lavalamp_round3_trigger.md`: round 3 fires
after the `closure_forces_structure` paper update lands.
The closure pass does not affect this trigger.

### §8.4 — No new specs surfaced

The user's constraint ("no new specs unless discovered via
a proving path") was satisfied. The four moves are state
upgrades on existing entries; the dropped LL-017 upgrade
was held back specifically because subdividing the entry
would have created new specs.

### §8.5 — One-time-agent recommendation

A one-time agent in ~2 weeks to verify the round-3 trigger
event has fired (or not) and remind about the resume
queue would be appropriate — the project is in a clean
pause state and the next move depends on an external
event (paper update). Not committing here; user's call.
