# Synthesis-Team Round 2 Brief — LavaLamp

Sent: 2026-05-02 (after 0.0.11 / CI workflow).
Trigger met: P2 closed in 0.0.5; P3 substantively closed
in 0.0.10 (4 of 18 spec entries `:tested` via Julia prototype;
detection-probability surface committed as benchmark output).

This is a **brief** — the document you (Aaron) forward to each
seat to set up Round 2. The dialogue itself lives in
`docs/synthesis_team_round2_companion.md` (to be written
*after* the reviewers respond, not before).

---

## §1 — What changed since Round 1

Round 1 (2026-04-30, captured in
`synthesis_team_round1_companion.md`) closed an architectural
blindspot on visual-richness ↔ security tension via Aaron's
decoupling resolution (LL-002). Spec entries LL-001..LL-014
were `:open` at round-1 close.

Since then, six commits across 2026-05-01 / 2026-05-02:

- **0.0.3 attack-surface enumeration.** Six adversary classes
  (A1..A6, A3 OOS), ten attack vectors V-001..V-010, residual-
  risk enumeration. Three new spec entries (LL-015 A3-OOS,
  LL-016 sensor-authenticity, LL-017 verification-no-oracle).
- **0.0.5 P2 architectural design pass.** Five design
  sections formalising LL-006 residue audit (vector
  per-exponent threshold + detection-probability bound shape),
  LL-008 resolution-bounded security claim + per-class
  A1..A6 quantification (new LL-018), LL-007 chaos-guard
  specifics, LL-004/005/016 sensor coupling, and LL-011/012/
  013/017 protocol layer. 12 entries moved to `:argued`.
- **0.0.6 P3 baseline.** Lorenz-96 N=40, F=8 reproduces
  literature: λ₁ ≈ 1.66, h_KS ≈ 10.5, Kaplan-Yorke dim ≈ 27.
  LL-003 `:tested`.
- **0.0.7 baseline companion.** Three field observations from
  the dev host: empirical robustness against host
  non-stationarity; substrate-coupling self-demonstration;
  compute-load and h_KS structurally linked (the security
  primitive's thermal signature is a *feature*, not a tax).
- **0.0.8 P3a sensor coupling.** Linear-in-x potential field
  `U(s, x; t) = Σ_k α_k · s_k(t) · ⟨b_k, x⟩`; smoothness +
  non-degeneracy demonstrated empirically (Δλ₁ ≈ +0.30 at
  α=1, +0.59 at α=2). LL-004 `:tested`.
- **0.0.9 P3b residue audit.** Vector per-exponent verifier;
  unit-vector + L2-magnitude synthetic-adversary semantic;
  detection-probability surface at N=20, k=5: flat ≈ 10% FPR
  for ε_A ≤ 0.75; sigmoid through 0.75-2.0; saturated 1.00
  for ε_A ≥ 2.0. LL-006 `:tested`. Bound constants K, c,
  δ_A(ε_A) not yet derived (pending `:benchmarked` upgrade).
- **0.0.10 P3c chaos-guard.** State machine {INVALID, WARMUP,
  VALID}; Wolf-method λ̂₁ estimator at ~1.3 ms/call (400×
  faster than Benettin spectrum); reseed flow with
  deterministic-magnitude TRNG perturbation. LL-007 `:tested`.
- **0.0.11 CI.** GitHub Actions running `Pkg.test()` on push.

**Spec status now:** 18 entries / 4 `:tested` (LL-003, LL-004,
LL-006, LL-007) / 9 `:argued` (LL-005, LL-008, LL-011..014,
LL-016, LL-017, LL-018) / 5 `:open` (LL-001, LL-002, LL-009,
LL-010, LL-015).

Round 1's recommendation was "engage-and-formalise after
fixes." Round 2's question: did the design pass and prototype
*actually* realise that, or did the formalisation drift?

---

## §2 — Reading list (in priority order)

The minimum set for a round-2 review:

1. **`docs/architecture_design_companion.md`** (0.0.5). The P2
   design pass. Five §2 sub-sections corresponding to LL-006,
   LL-008/018, LL-007, LL-004/005/016, LL-011..014/017.
   §3 verification (every result `manual` evidence with
   explicit argument); §4 spec impact (status moves and new
   LL-018); §5 process notes.
2. **`docs/attack_surface_enumeration.md`**. The threat tree
   the design pass discharges. Six adversary classes; ten
   attack vectors; residual-risk enumeration. Maintained
   document.
3. **`docs/p3a_sensor_coupling_companion.md`** (0.0.8).
   Sensor-coupling implementation companion. Records the
   correction: trajectory-mean detection has ~10× lower SNR
   than spectrum-based detection, *empirically validating*
   round-1's audit choice.
4. **`docs/p3b_residue_audit_companion.md`** (0.0.9).
   Verifier-implementation companion. Records the
   zero-sensor degeneracy bug; the unit-vector + L2-magnitude
   synthetic-adversary semantic; why this lands as `:tested`
   not `:benchmarked` (bound constants undetermined).
5. **`docs/p3c_chaos_guard_companion.md`** (0.0.10).
   Chaos-guard companion. State-machine logic, Lorenz-96
   chaotic vs sub-chaotic detection, reseed flow.
6. **`src/julia/benchmark/results/p3b_detection_lorenz96.txt`**.
   The committed empirical detection-probability surface.
   Plain text; the actual numbers backing LL-006's `:tested`
   status.
7. **`docs/synthesis_team_round1_companion.md`**. For
   continuity. Contains the round-1 dialogue arc, the original
   blindspot resolution, and the round-1 final-state
   architecture.
8. **`docs/qkd_pqc_complementarity_companion.md`** (0.0.4).
   Positioning analysis. The C-conjugate adversary inheritance
   from Closure v5's cross-sector autopoiesis 0/5202 result.
   Critical for round-2 reviewers to challenge whether the
   structural-prior transfer to LavaLamp is load-bearing or
   hand-wavy.
9. **`LAVALAMP_SPEC.md`** for current entry texts.

For deep dive: `src/julia/src/{Sensors.jl, Engine.jl,
Audit.jl, ChaosGuard.jl}` and the test suite in
`src/julia/test/runtests.jl`.

---

## §3 — Synthesis-seat brief (Gemini)

You synthesised the round-1 architecture (`Substrate-Bound
Identity`, `Resolution-Bounded Security`, multi-scale Lyapunov
audit, chaos-guard). Round 2 question: **does the formalised
design + implemented prototype hang together as a coherent
security primitive, or has formalisation drift introduced
weakness?**

Six specific synthesis questions:

### Q1 — Is the linear-in-x potential coupling sufficient?

The prototype implements `U(s, x; t) = Σ_k α_k · s_k(t) ·
⟨b_k, x⟩` (linear in state). This is the simplest coupling
that propagates sensor reads into the Lyapunov spectrum, and
the empirical α-sweep shows ∂λ/∂α ≠ 0. **But:** linear U has
a constant gradient ∇_x U, so the sensor enters as a
state-independent forcing perturbation — the adversary's job
is essentially to match a parameter shift, not to reproduce a
state-dependent coupling pattern.

Is this enough for the LL-006 detection bound to have
practical bite, or does the security claim need
state-dependent coupling (U quadratic-or-higher in x)? If the
latter, what's the right structural shape — a Polyakov-style
exponential coupling? A bilinear `s · x ⊗ x`? Something else?

### Q2 — Is the §2.1 detection bound's shape sharp enough?

`P(detect) ≥ 1 - K · exp(-c · T · δ_A²)` is the design's
formal claim. Empirically (P3b) the bound's *shape* validates
— sigmoid transition with ε_A. But the **constants K, c, and
the ε_A → δ_A mapping are not yet derived**. The prototype
sits at `:tested`, not `:benchmarked`.

Is the exponential-in-T-times-δ² shape the right shape, or
should it be tighter (e.g., a Chernoff bound with explicit
moment-generating-function content)? If sharper bounds are
available in the dynamical-systems literature, name them — we
want the Lean target (P6) to be as tight as is honestly
provable.

### Q3 — Where does Round 2's blindspot likely live?

Round 1's blindspot was visual-richness ↔ security. Round 2's
likely blindspot is *probably not* obvious — by definition. But
educated guesses might surface it:

- **Calibration-time leak.** The 10-trial envelope calibration
  exposes ~10 spectrum estimates to whoever observes the
  registration ceremony. Could that leak enough information
  to spoof verification later? (Cf. LL-011 registration
  ceremony — but the design didn't enumerate "calibration
  observation" as a specific attack vector.)
- **State-vector reseed forensics.** Reseed events (LL-007)
  are logged; reseed events from a remote observer's
  perspective look like brief unavailability windows. Does
  this leak deployment fingerprint?
- **Unit-vector adversary geometry.** The
  `synthetic_adversary` model perturbs α uniformly on the
  unit sphere. Real adversaries probably aren't isotropic in
  α-space — they have specific perturbation directions
  (sensor manipulation favours certain α components over
  others). Does the prototype's isotropic threat model
  underestimate adversary capability?

Surface anything you see that we missed.

### Q4 — Does the C-conjugate inheritance still hold?

`qkd_pqc_complementarity_companion.md` §2.5 claims LavaLamp
inherits the C-conjugate adversary structurally from Closure
v5's cross-sector autopoiesis 0/5202 result. The prototype
realises this as: genuine system has α; adversary has α + ε·û;
spectrum gap δ_A > 0 by ∂λ/∂α non-degeneracy.

Is this transfer load-bearing — does the discrete-categorical
0/5202 result actually structure the continuous-dynamics
prototype, or is the prototype a weaker analog that just
shares vocabulary with the corpus result? If the latter, what
structural property of the prototype would make the transfer
load-bearing rather than aesthetic?

### Q5 — LL-016 sensor authenticity: papered over?

LL-016 (sensor authenticity) is the largest residual risk per
attack-surface §V-006. The design proposes four mitigation
strategies (TPM attestation; multi-sensor cross-validation;
anomaly-flagging; accepted-residual deployment-context). The
prototype implements *none* of them — the synthetic stub
streams bypass authenticity entirely.

Is "deferred to a later sub-task or P6 hardening" the honest
deferral the design claims, or does this mean the security
claim is conditional on a bet that's not been placed? If
LL-016 fundamentally requires hardware attestation, that
should be a primary architectural commitment, not a
deployment-time choice. Push back.

### Q6 — Should Catlab tier still be skipped for LavaLamp?

Round 1.D and `language_plan_catlab_tier_companion.md` set the
default to skip Catlab unless the verification protocol
surfaces categorical structure. Now that LL-011/012/013/017
protocol layer is concrete, **does the verification protocol
have categorical content worth Catlab?** The registration
ceremony has multi-party threshold-scheme structure; the
cross-config transition has state-machine + sensor-authentic
gating; the cold-start / WARMUP states have multi-state
transitional structure. Is any of this naturally
multicategory / functorial / would-benefit-from-formal-
categorical-structure?

Default still skip; revisit decision is your call.

---

## §4 — Edge-witness-seat brief (Grok)

You stress-tested round 1's architecture and produced V-001
through V-010 (most vectors enumerated by name in
`attack_surface_enumeration.md`). Round 2 question: **what
does the prototype implementation expose that the round-1
attack-surface enumeration didn't, and what attack vectors
emerge from the Julia code now visible?**

Six specific stress-test questions:

### A1 — Reseed-event timing observability

The chaos-guard reseeds via TRNG when λ̂₁ < τ_λ. Reseed
events are logged. From an external observer's perspective,
reseeds correspond to brief "unavailability" windows on the
verifier (the device is in WARMUP for warmup_steps updates,
returning UNKNOWN_CONFIGURATION-like response per LL-012).

Does this create a side-channel? An adversary who can probe
the device's verification readiness gets an event channel
correlated with reseed timing. If reseed timing is itself
sensor-correlated (e.g., thermal events trigger reseeds via
chaos-guard rejection), the adversary has a *thermal-event
oracle* against the device.

### A2 — Calibration-time observation

Per Q3 above, the 10-trial calibration during registration
exposes 10 spectrum estimates. An A5 adversary present during
registration captures these. Can they:
- Reconstruct the SDE parameter set well enough to mount a
  near-genuine attack later?
- Estimate the per-exponent σ accurately, then craft an
  adversary trajectory that lies just inside the calibration
  noise envelope?

The design (LL-011) discusses TPM attestation but not
calibration-data confidentiality. Is this gap material?

### A3 — Unit-vector adversary is too kind

The `synthetic_adversary` model is isotropic: random unit
vector × magnitude. Real-world adversaries have *structure*
to their perturbation directions:
- **Sensor manipulation** (V-006) tends to perturb specific α
  components (the components coupled to the manipulated
  sensor), not all α isotropically.
- **Configuration replay** (V-009) shifts α toward the
  registered-configuration set, not random directions.
- **Slow-drift threshold gaming** (V-005) chooses the
  direction that maximally evades the residue test.

Does the prototype's isotropic adversary substantially
under-estimate detection difficulty? If so, the empirical
P(detect) curve at the prototype's working point is an
*optimistic* bound, not a worst-case bound.

### A4 — Wolf-method monitoring vs Benettin-method audit

The chaos-guard uses Wolf single-trajectory λ₁ (fast). The
audit uses Benettin full spectrum (slower). An adversary who
knows the chaos-guard uses Wolf can construct trajectories
that have ~genuine λ₁ (passing the guard) but diverge in
higher exponents (caught only by the audit on demand). If
the audit runs less frequently than the guard, there's an
exploitable window.

How frequently must the audit run to close the window? Is
"on every verification request" sufficient, or does the
attacker get inter-verification-request time to drift their
trajectory?

### A5 — 10% FPR is operationally suspect

The detection-probability benchmark shows ~10% baseline
false-positive rate at k=5 with n_trials=10 calibration.
That means in a deployment with N legitimate users, ~N/10
verification attempts per session fail spuriously.

For a single-user device this is annoying; for a
multi-tenant verifier it's a denial-of-service vector. Is
the 10% number the prototype's choice or a fundamental limit
of the architecture? If it's the former, what would tighten
it (more calibration trials? Different test statistic? Both?).

### A6 — The "linear in x" admission

Q1 above asks the synthesis side whether linear-in-x
coupling is sufficient. The edge-witness perspective: **if
the security primitive is linear in state, isn't it
linearisable?** A sufficiently determined adversary builds a
linear model of the dynamics from observation, then matches
α via least-squares fit on the observed trajectory. With
enough samples, ε_A → 0.

The dynamics is non-linear (Lorenz-96 has cubic terms), but
the *coupling* to sensors is linear. Does that distinction
hold against an adversary with first-principles modeling
capability, or is the prototype's coupling layer a structural
soft spot?

---

## §5 — Response format request

Following the round-1 dialogue norm, both seats:

1. **Six-point evaluation per seat.** One bullet per question
   in your section (Q1-Q6 for synthesis; A1-A6 for
   edge-witness). Each bullet: short answer + reasoning + any
   pointer to a corpus reference or formal source. ~80-120
   words per bullet.
2. **Cumulative verdict.**
   - Synthesis seat: `engage-and-formalise` /
     `engage-and-formalise-after-fixes` /
     `redirect-to-X` / `obstruct`. If `obstruct`, name the
     structural barrier; if `redirect`, name where to.
   - Edge-witness seat: `pass` / `pass-after-fixes` / `fail`
     with named attack vector.
3. **Net new attack vectors / blindspots.** If you surface
   anything that V-001..V-010 didn't cover, name it with a
   provisional V-NNN tag (we'll allocate the actual numbers
   on integration).
4. **Lean / proof-track suggestions.** If you can name the
   theorem statement that should land in Lean (P6), do so —
   this gates whether LL-006 / LL-008 / LL-018 reach
   `:proved`.

Length cap: 2000 words per seat. We want substance, not bulk.

---

## §6 — Followups (after dialogue lands)

1. **`docs/synthesis_team_round2_companion.md`** — written
   *after* the dialogue, capturing the full arc (Aaron's
   forward → Gemini synthesis → Grok edge-witness → Aaron
   resolution / instantiation). Mirrors the round-1 companion
   shape.
2. **Spec impact.** Round 2 may surface new spec entries
   (LL-019..) for discovered blindspots; existing entries may
   need refinement. Process: companion doc lands first,
   spec/registry/dashboard updates land in a separate commit
   per the "small / large session" CLAUDE.md discipline.
3. **Decision point.** Round 2 verdicts of
   `engage-and-formalise` (with or without fixes) keep the
   project on the current path — next sub-task is whichever
   is highest-leverage (P3-bound, P3d, P5 Haskell, P6 Lean).
   Verdicts of `redirect` or `obstruct` send us back to
   architecture work before more code.

---

**Aaron's instructions to forward:** copy-paste §1 + §2 + §3
to Gemini; copy-paste §1 + §2 + §4 to Grok. Both seats receive
§5. §6 is internal — stays here. Run them in either order, or
in parallel; the two reviews are independent of each other
this round (round 1 had Gemini-first because synthesis was
load-bearing for the architecture; round 2 has both seats
reviewing a settled architecture).
