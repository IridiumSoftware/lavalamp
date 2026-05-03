# P-R2b Calibration Confidentiality Companion

Version: 0.0.16 (P-R2b — LL-020 calibration confidentiality,
2026-05-02)

Permanent record of the P-R2b session: design response to
LL-020 (round-2 spec entry). Closes LL-020 from `:open` to
`:argued` with `manual` evidence. The design closes; the
implementation is platform-coupled (TPM / Secure Enclave) or
cryptographic-library-coupled (ε-DP / Shamir secret sharing)
and properly belongs in P3 hardening or P6/P7 production
work. The prototype lands the design space + recommended
default + Lean theorem shape; concrete implementation is
deferred.

This is the third and final P-R2 architectural-response
session.

---

## §1 — Computational basis

No code; pure design. Inputs:

- `LAVALAMP_SPEC.md` LL-020 (round-2 surfaced; description
  references the V-012 mechanism).
- `docs/synthesis_team_round2_companion.md` §1C-A2 / §1D-iii.
- `docs/attack_surface_enumeration.md` V-012.
- `docs/architecture_design_companion.md` §2.5.1 (LL-011
  registration ceremony — the design that V-012 surfaced as
  incomplete).
- Standard cryptographic-protocol literature (Shamir secret
  sharing, differential privacy, TPM remote attestation).

Output: this companion + a spec/registry update. Total
session size is small relative to P-R2a / P-R2c, matching the
"mostly design" framing in round-2 §6.1.

---

## §2 — Results

### §2.1 — Problem restated

The registration ceremony (LL-011) calibrates a device's
envelope by running n_trials independent SDE runs and
recording the per-exponent λᵢ and σᵢ. The verifier persists
this envelope and uses it for subsequent verification
requests.

LL-011's TPM attestation defends *substitution* of the
registered envelope: an A5 adversary cannot replace the
envelope with their chosen one without the TPM signature
failing. **But TPM attestation does not defend
*observation*.** A registration-channel observer captures the
envelope to machine precision and can:

- Reconstruct the SDE family and parameters by least-squares
  fitting.
- Compute the rejection-ball geometry exactly (mean ± k·σ
  per exponent at any chosen k).
- Craft trajectories that lie just inside the rejection
  ball — passing the LL-006 audit by construction.

This breaks LL-017 verification-no-oracle: the no-oracle
requirement assumes the adversary doesn't know the threshold
geometry. A registration-channel observer *does*.

### §2.2 — Three design strategies

#### Strategy 1 — TPM-sealed envelope storage

The verifier seals the registered envelope with a key tied
to the TPM (or Secure Enclave on macOS, Trusted Execution
Environment on ARM). The envelope never transmits in
cleartext after registration; verification computations
unseal locally and compare without exposing the envelope.

**Strength:** Cryptographically strong. An A5 adversary
without TPM-side privilege cannot read the envelope.

**Cost:** Requires hardware support. TPM 2.0 is standard on
modern PCs; Apple Secure Enclave on Apple Silicon; ARM
TrustZone on most modern phones. Older deployments lack TPM.

**Failure modes:** TPM bypass (firmware vulnerabilities,
DMA attacks on the bus); TPM key extraction (proven
difficult but not zero-cost); side-channel leakage during
unseal-and-compare.

**Default for hardware-rooted deployments.** Enterprise +
modern consumer devices are TPM-equipped; this is the
operationally-dominant choice.

#### Strategy 2 — ε-differentially-private envelope

If the envelope *must* be published (e.g., federated
verification where multiple verifiers share an envelope
across an organisation, or open-verification protocols
where users can verify devices without a central trust
root), the published version is perturbed with calibrated
Gaussian noise satisfying (ε, δ)-DP.

**Mechanism.** For each per-exponent λᵢ and σᵢ in the
envelope, publish:

```
λᵢ_dp = λᵢ + Laplace(0, Δλ / ε)   or
λᵢ_dp = λᵢ + Gaussian(0, σ_DP)    with σ_DP set per (ε, δ)
```

The sensitivity Δλ is the maximum per-exponent change a
single calibration trial can induce — bounded by the
estimator's per-trial deviation. ε-DP provides a quantifiable
information bound on what the observer learns: roughly
e^ε-fold likelihood ratio between any two genuine devices.

**Strength:** Cryptographically motivated bound. With
ε ≤ 1, observers gain bounded information (factor-of-e
likelihood ratio).

**Cost:** Detection sensitivity is reduced. Since the
perturbed envelope has wider thresholds (k·(σᵢ + σ_DP)
instead of k·σᵢ), legitimate verification is more lenient
and the detection bound is correspondingly weaker. The
trade-off is privacy-vs-detection-power.

**Failure modes:** ε-DP composes additively across queries;
many verifications eventually leak the envelope. Requires
careful ε-budget tracking. Sensitivity Δλ must be honestly
bounded — if the calibration produces an outlier exponent,
the DP guarantee weakens.

**Default for federated / open-verification deployments.**
TPM-sealed is impractical when the envelope must be shared.

#### Strategy 3 — Multi-party threshold scheme

Split the envelope across N verifiers using Shamir secret
sharing (or similar threshold cryptography). Reconstruction
requires t < N verifiers to collude; below threshold, no
information leaks.

**Mechanism.** For each per-exponent λᵢ and σᵢ:

1. At registration, generate a degree-(t-1) polynomial
   over a finite field with the value at 0 equal to (λᵢ, σᵢ).
2. Distribute the polynomial's evaluations at 1, 2, …, N to
   the N verifiers.
3. Reconstruction requires interpolating from t shares.

**Strength:** Information-theoretically secure below
threshold. No computational assumptions.

**Cost:** Operational complexity; multiple verifiers must
coordinate. Verification latency higher.

**Failure modes:** Collusion of t verifiers reveals the
envelope. Choosing t/N is an operational policy decision.

**Default for high-assurance federated deployments.**
Multi-party = multi-trust-root, which matches federated
threat models.

### §2.3 — Recommended default for the prototype

Layered defaults by deployment:

| Deployment | Primary | Fallback |
|---|---|---|
| Hardware-rooted (consumer / enterprise PC) | TPM-sealed (1) | ε-DP (2) for any published statistics |
| Federated (organisation / federation) | Multi-party threshold (3) | TPM-sealed at each verifier (1) |
| Open-verification (no trust root) | ε-DP (2) only | None (accepted bound) |
| No hardware root, single verifier | ε-DP (2) | Documented residual risk |

For the prototype's documentation purposes, the *primary*
recommendation is TPM-sealed (1), because consumer and
enterprise PC deployments are TPM-equipped and TPM-sealed is
the operationally-dominant choice. ε-DP is the universal
fallback when hardware support is absent or when envelope
publication is required.

### §2.4 — Composition with LL-011 / LL-017

LL-011 (registration ceremony) defends **substitution** via
TPM attestation. LL-020 defends **observation**. They are
*complementary*; production deployments need both.

LL-017 (verification no-oracle) defends against
**threshold-probing via accept/reject feedback**. LL-020
extends this by defending against **threshold-knowledge via
calibration observation**. The two together close the
threshold-leakage path: the adversary cannot probe the
threshold (LL-017) and cannot read it from registration data
(LL-020).

The composed claim: an adversary who is not TPM-privileged
and not below the multi-party threshold and not within ε-DP's
quantifiable information bound *cannot* learn the registered
threshold geometry to better than the bound's leakage rate.

### §2.5 — What the prototype lands

This companion lands the *design*. The prototype does NOT
implement any of the three strategies; the implementations
are platform-coupled (TPM / Secure Enclave) or
cryptographic-library-coupled (Shamir / DP libraries) and
sit outside the Julia-prototype scope per the
language-tier-and-phase discipline (`CLAUDE.md` § Language
tiers and phase discipline).

Expected implementation phases:

- **Strategy 1 (TPM-sealed):** P3 hardening sub-task in Julia
  via FFI to platform TPM libraries. More naturally lands
  in P7 (C/C++ production hardening) where platform-level
  cryptographic plumbing belongs.
- **Strategy 2 (ε-DP):** Plausible as a pure-Julia stub
  using `Random` for Gaussian perturbation; would close
  LL-020 to `:tested` for that strategy specifically. Not
  done in this session per "P-R2b is mostly design" framing.
- **Strategy 3 (Multi-party threshold):** Cryptographic-
  library-coupled (Shamir secret sharing). P5 (Haskell)
  could implement type-safe abstractions; P7 production-
  grade implementation.

### §2.6 — Lean theorem shape

Round-2 §1D.v priority 3:

> Calibration security. Theorem stating that the registered
> envelope distribution is ε-differentially private (or
> equivalent) w.r.t. registration observers.

Refined statement:

```lean
theorem ε_dp_envelope_bound
  (env_published : Envelope)         -- the perturbed envelope
  (env_genuine : Envelope)           -- the unperturbed registered one
  (observer : ObserverView)          -- what the registration-channel observer sees
  (ε δ : ℝ) (hε : ε > 0) (hδ : 0 ≤ δ ∧ δ < 1)
  : (∀ neighbouring_env : Envelope,
      |neighbouring_env.spectrum - env_genuine.spectrum|_∞ ≤ Δλ →
      P_observer_sees(env_published, observer) ≤
        e^ε · P_observer_sees(perturb(neighbouring_env), observer) + δ)
  → adversary_information_gain(observer) ≤ ε
```

The statement is the standard (ε, δ)-DP definition specialised
to envelope perturbation. The prerequisite is that the
calibration sensitivity Δλ is honestly bounded — typically
via concentration inequalities on the spectrum estimator's
per-trial deviation.

For Strategy 1 (TPM-sealed) the corresponding theorem is a
standard cryptographic indistinguishability claim:

```lean
theorem tpm_sealed_indistinguishability
  (env : Envelope) (key : TPMKey)
  : seal(env, key) is indistinguishable from random
    given an observer without TPM access
```

For Strategy 3 (Multi-party threshold), the standard
threshold-cryptography theorem:

```lean
theorem shamir_threshold_security
  (env : Envelope) (shares : Vector ShamirShare N) (t : ℕ)
  (h : t ≤ N)
  : ∀ subset : Vector Fin t-1,
      reconstruct(shares[subset]) = ⊥
```

These are all standard cryptographic lemmas adapted to the
envelope context; the LavaLamp-specific content is the
*sensitivity bound* Δλ for the envelope vs the unperturbed
genuine spectrum.

---

## §3 — Verification

### §3.1 — LL-020 calibration confidentiality

- **Evidence type:** `manual` (design closes; implementation
  deferred).
- **Status moves:** `:open` → `:argued`.
- **Source:** this companion §2.

### §3.2 — Why `:argued` and not `:tested`

- The three strategies are designs; none is implemented in
  the prototype.
- A stub of Strategy 2 (ε-DP) is plausible as a small Julia
  function but would over-state the claim — a "naive
  Gaussian-perturbation" stub does not satisfy (ε, δ)-DP
  without sensitivity tracking and composition discipline.
- The honest tier per CLAUDE.md "honest framing" discipline
  is `:argued` for design-only work.

`:tested` would require either:

1. A pure-Julia ε-DP envelope-perturbation stub with
   sensitivity calibration, plus tests asserting the
   perturbed envelope satisfies the (ε, δ)-DP bound. Possibly
   a follow-up session.
2. A stub of Strategy 3 (Shamir secret sharing) over a
   small finite field with reconstruction tests. Less
   useful operationally; mostly for demonstration.
3. FFI integration with the platform TPM. Out of Julia
   prototype scope.

None of these is in this session's scope.

### §3.3 — What `:argued` does NOT mean

- **Not implemented in the prototype.** No Julia code
  changes from this session.
- **Not Lean-verified.** §2.6 sketches the theorem shape;
  the proofs are P5/P6 work.
- **Not benchmarked.** ε-DP's privacy-vs-detection trade-off
  has empirical content (how does detection power degrade
  as ε decreases?) that would require an extended P-R2c-
  style benchmark; not in this session.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-020** calibration-confidentiality: `:open` →
  `:argued` with `none` → `manual` evidence type. Source:
  this companion.

### §4.2 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 6 (LL-003, LL-004, LL-006, LL-007, LL-019,
  LL-021)
- **`:benchmarked`:** 0
- **`:argued`:** 10 (was 9; + LL-020)
- **`:open`:** 5 (was 6; − LL-020)

### §4.3 — Files changed

- `docs/p_r2b_calibration_confidentiality_companion.md`
  (this file) — new.
- `LAVALAMP_SPEC.md` — LL-020 status move; counts.
- `artifact_registry.md` — LL-020 row update; counts.
- `dashboard.md` — P-R2b marked done; spec status counts;
  P-R2 block fully closed.
- `changelog.md` — 0.0.16 entry.

### §4.4 — Followups

- **ε-DP envelope stub** as a follow-up session: pure-Julia
  Gaussian perturbation with sensitivity calibration.
  Closes LL-020 to `:tested` for Strategy 2. Plausible
  small session.
- **TPM-sealed envelope FFI** is P3 hardening or P7
  production work; not a near-term Julia-prototype task.
- **Multi-party threshold scheme stub** is interesting but
  operationally specialised; defer.
- **Lean theorems per §2.6** are P5/P6 work; refined
  shapes documented here.

---

## §5 — Lessons captured

### §5.1 — Design-only work is honest at `:argued`

The lavalamp CLAUDE.md "honest framing" discipline maps
cleanly onto the design-vs-implementation distinction.
A design that argues a claim and identifies the right
mitigation strategies is `:argued` evidence (manual). A
prototype implementation is `:tested` (example-tested).
Lean-verified is `:proved`.

LL-020 is `:argued` because the design closes and the
implementation belongs in a different language tier (P5/P6/
P7). This is the same shape as the round-1 / 0.0.5 P2 design
pass — twelve entries closed at `:argued` because the
design closed but no Julia implementation existed yet.
Several of those entries (LL-004, LL-006, LL-007) later
upgraded to `:tested` in P3a/b/c; LL-020 follows the same
trajectory.

### §5.2 — Three strategies layered by deployment context

The deployment-context layering in §2.3 is the right shape
for security designs that have multiple legitimate
implementations. No single strategy dominates; the choice
depends on the deployment's hardware availability and trust
model. Documenting the layering explicitly avoids the
"papered over" framing the round-2 brief flagged for
LL-016.

The same shape would benefit other prototype components
that have similar deployment-context choices: LL-016 sensor
authenticity (TPM-attested vs cross-validation vs
anomaly-flagging vs accepted residual) is exactly this
pattern — landed in the 0.0.5 P2 design pass with the same
strategy-layering shape.

### §5.3 — TPM is the dominant default for modern hardware

For consumer + enterprise PC deployments with TPM 2.0
support, TPM-sealed envelope storage is the operationally-
dominant choice — strongest cryptographic guarantee,
requires no envelope publication, no DP-induced detection
power loss, no operational coordination. Federated and
open-verification deployments need different strategies.

The prototype's documentation should reflect this: the
default recommendation is TPM-sealed unless deployment
context rules it out.

### §5.4 — P-R2 design-response trio is now complete

Round-2 surfaced three architectural debts (V-011, V-012,
V-013); P-R2a / P-R2c / P-R2b respond to them
(LL-019/021/020). All three closed within a single
afternoon's work — much faster than the round-2 §6.1
estimate of "1-2 sessions of design work." The fast turn-
around reflects the tractability of the round-2 findings
(named attack vectors with clear mitigation strategies) vs
the round-1 finding (visual ↔ security tension, which
required architectural restructuring).

The P-R2 trio's collective output:

- Two new working Julia primitives (`verify_full`,
  `verify_constant_time`) from P-R2a.
- One committed empirical benchmark
  (`p_r2c_structured_lorenz96.txt`) from P-R2c.
- Three companion docs documenting design + implementation +
  results.
- Three spec entries closed (LL-019/021 to `:tested`,
  LL-020 to `:argued`).

The dashboard's Round-3 trigger (after `closure_forces_structure`
paper update) is now the only gate on further round-3 review.
Local prototype-extension work can resume — the previously-
deferred P3d / P3-Nyq / P3-bound sub-tasks are unblocked.
