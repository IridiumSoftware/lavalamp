# Attack-Surface Enumeration — LavaLamp

Version: 0.0.3 (initial draft, 2026-05-01)

This document is the formal threat tree for LavaLamp. It enumerates
the adversary classes the architecture must contend with, the
attack vectors each class can mount, the architectural defenses
(by LL-ID) that respond to each, and — honestly — the residual
risks the current architecture does *not* yet defeat.

This is the load-bearing technical content of any future
LavaLamp paper. Spec entries (`LAVALAMP_SPEC.md`) declare what is
*claimed*; this document declares what is *defended against*.

The document is also the gate for P3 (Julia prototype core) in the
priority stack: implementation must trace each LL-ID's coverage of
the threat tree below before code ships.

---

## §1 — Scope and use

**In scope.**

- Adversary attempts to spoof a genuine device's substrate-bound
  identity (LL-001).
- Adversary attempts to make a verifier accept a non-genuine
  trajectory.
- Adversary attempts to suppress legitimate detection of spoofing
  (drift threshold-gaming, residue suppression).
- Adversary attempts to exploit the registration ceremony,
  cold-start window, or cross-config transition seams.
- Adversary attempts to manipulate the genuine device's sensors
  to drive its trajectory toward a chosen output ("spoofing
  without replication").

**Out of scope.**

- Adversaries with full root + DMA + arbitrary code execution on
  the genuine device (at that capability level the device's
  identity is irrelevant; the attacker can simulate any
  trajectory directly).
- Network protocol design (key distribution between distant
  parties — that's QKD's problem; LavaLamp is locally-bound
  device entropy + verification).
- Attacks on the visual skin (per LL-002, the visual is
  decorative and not part of the security primitive).
- Quantum-mechanical attacks beyond no-cloning analogues (we
  explicitly do *not* claim quantum-grade unclonability).
- Cryptographic attacks on key derivation downstream of the
  unclonability primitive (those are downstream-protocol
  concerns; LavaLamp produces the entropy / identity, doesn't
  decide how it's consumed).

**How to read this document.**

Each attack vector is `V-NNN`-tagged (parallel to the spec's
LL-NNN convention). Defenses cite LL-IDs from
`LAVALAMP_SPEC.md`. Residual risks are explicit. The
adversary-class × attack-vector matrix in §4 summarises the
coverage at a glance.

---

## §2 — Adversary model taxonomy

LavaLamp's security posture varies sharply by adversary
*capability*, not adversary intent. The taxonomy below classifies
adversaries by what they can observe and what they can do:

| Class | Capability summary | Examples |
|---|---|---|
| **A1 — Remote software** | Can communicate with the device over the network; cannot execute code on it; cannot observe physical signals. | Remote attacker hitting a verifier endpoint; man-in-the-middle on the verification channel. |
| **A2 — Local software (unprivileged)** | Can run user-space code on the device (no root). Can read process timings, OS clock, public sensors. | Malicious app installed by phishing; supply-chain compromise of a non-privileged dependency. |
| **A3 — Local software (privileged / root)** | Can run kernel-level code on the device. Can read all sensors, all memory, all timing. **Capability boundary** — at this level the architecture's trust assumptions begin to fail; LavaLamp does not claim defense against a true A3. | Malicious kernel module; rootkit; compromised firmware. |
| **A4 — Side-channel / physical proximity** | Cannot run code on the device but can observe physical signals: power consumption, EM emissions, acoustic emissions, sensor cables, USB bus traffic. Can also manipulate the physical environment (heat the laptop, supply false sensor inputs via injected USB or charge controller flash). | Coffee-shop adversary with a laptop next to the target; supply-chain interposer between device and external sensor. |
| **A5 — Insider / registration-time** | Has access to the device during the registration ceremony. Can observe the registered hardware envelope as it's being committed. Can also influence the registration to commit a non-genuine envelope. | Compromised registration provider; insider at deployment time. |
| **A6 — Time-localized** | Can briefly capture trajectory data (e.g., a single observation window during which the device is unguarded) but cannot maintain continuous observation. | Drive-by recorder; brief window of physical access. |

**Capability boundary clarification.** LavaLamp's
**resolution-bounded security** claim (LL-008) holds against
adversaries up through A4. A1 adversaries are defeated by the
substrate-coupling alone (they have nothing to model with). A2 is
defeated by the entropy gap between user-space-observable and
physical-signal-grounded noise. A4 is the *interesting* class —
the architecture must show that the entropy gap holds against
side-channel observation. **A3 is the explicit boundary**: if an
adversary owns the kernel, LavaLamp does not pretend to defend.
Documenting this boundary honestly is part of the load-bearing
positioning.

A5 (registration-time adversary) is its own class because the
registration ceremony establishes the trust root; an A5 attacker
defeats verification by poisoning the envelope, no matter how
strong the per-trajectory defenses are. LL-011 (registration
ceremony) is the key spec entry; until that protocol is designed,
A5 is undefended in the current architecture.

A6 (time-localized) interacts with the cold-start window
(LL-012): a brief observation right after boot, before the
trajectory has converged, could leak information that's harder to
extract once the substrate-coupling is fully expressed.

---

## §3 — Attack vectors

Each vector lists: which adversary classes can mount it, the
mechanism, the architectural defenses (LL-IDs), residual risk
not yet defeated, and what mitigation work is pending.

### V-001 — "Good enough" trajectory attack

**Adversary classes:** A2, A4 (side-channel-heavy)

**Mechanism.** The adversary doesn't attempt to *clone* the
device's substrate state. Instead, they generate their own
chaotic trajectory in the same SDE family, with parameters
matched closely enough that the verifier's residue test does not
trigger. If the residue test is a scalar threshold on
trajectory-distance metric (e.g., simple KL on raw trajectory),
the adversary only needs to keep their trajectory within the
threshold ball — they don't need to be genuine, just plausible.

**Defenses.**

- **LL-006 (Lyapunov-spectrum residue audit).** Replaces scalar
  KL with multi-scale spectrum comparison. Adversary may match
  trajectory location on the attractor; matching local
  stretching/folding rates across multiple timescales is much
  harder.
- **LL-003 (single-attractor chaotic engine).** Single-attractor
  systems eliminate multi-basin hiding space. Adversary cannot
  hide in a different basin that visually / location-wise passes
  while diverging on spectrum.
- **LL-002 (visual ↔ security decoupling).** Visual richness no
  longer constrains the choice of SDE; single-attractor systems
  with high Lyapunov exponent become viable.

**Residual risk.** Lyapunov-spectrum estimation has finite
resolution; adversary with sufficient compute can match the first
2–3 exponents within ~5–10% tolerance. Detection becomes a
statistical hypothesis test, not a deterministic check. Quantitative
adversary-resolution bounds pending **LL-014 (threshold
calibration)** — until calibration is formal, the residual risk is
underspecified.

**Mitigation pending.** Formal probabilistic detection bound
(LL-008's correct theorem shape): for adversary with measurement
precision μ, detection probability → 1 as observation window T
grows, with explicit dependence on μ, λ_min, Δt.

### V-002 — Basin-spoofing (resolved by LL-002)

**Adversary classes:** A2, A4 — *would have applied* in any
architecture that fed the visual *from* the SDE.

**Mechanism (would have been).** Reaction-diffusion systems
chosen for rich visual flow (Gray-Scott, Stochastic
Ginzburg-Landau in their lava-lamp-aesthetic regimes)
characteristically have multiple co-existing attractors. An
adversary who modeled the sensor-coupling could *steer the
genuine device* into a different basin by manipulating sensors
(A4) or emit a forged trajectory in a different basin that
visually passes (A2). The visual richness *requires* basin
proximity, which is exactly the adversary's hiding space.

**Resolution.** Closed by **LL-002 (visual ↔ security
decoupling)** before any code shipped. The visual is now driven
by any RNG and is not part of the security claim; the security
primitive uses single-attractor systems where this attack is
structurally impossible.

**Residual risk.** **The decoupling is load-bearing.** If a
future refactor proposes re-coupling the visual to the SDE for
performance / aesthetic / "elegance" reasons, V-002 returns. The
asymmetry-trap watch (in `dashboard.md` Live Discipline Notes)
exists specifically to catch this.

**Mitigation pending.** None at architecture level. Discipline-
maintenance only: any refactor in this area must be reviewed
against the V-002 historical attack.

### V-003 — Quantum-seed → classical-software boundary attack

**Adversary classes:** A4

**Mechanism.** Even when the SDE is seeded by a genuine quantum-
grounded hardware TRNG (raw entropy access, not whitened), the
SDE *integration step* is classical software. An A4 adversary
with side-channel resolution exceeding the SDE timestep can:

1. Record the sensor stream that drives the external potential
   field at higher temporal resolution than the integration
   timestep.
2. Reconstruct the genuine device's per-step parameter trajectory
   from side-channel observation.
3. Replay that parameter trajectory in their own simulation,
   producing a visually and statistically indistinguishable
   trajectory.

The "quantum seed" becomes classical data the moment it hits
software; from then on, classical side-channel observation
applies.

**Defenses.**

- **LL-005 (sensor Nyquist condition).** Sampling rate must
  exceed adversary's side-channel resolution for the classical-
  software-boundary attack to fail. Formal requirement: `f_SDE >
  2 × bandwidth ∧ f_sensor > bandwidth` where bandwidth is the
  underlying physical-noise bandwidth of the substrate.
- **LL-004 (continuous sensor coupling via potential field).**
  Avoids the discrete-step artifacts that would let an adversary
  detect and synchronize with the integration timestep.

**Residual risk.** Substantial when adversary has high-resolution
side-channel access. The mitigation is *making the side-channel
expensive enough* (high f_SDE, high f_sensor, fine-grained
sampling) that A4 capabilities don't close the gap. There is no
defense against a sufficiently capable A4. The honest claim is:
defended *up to* an A4 of bounded resolution, which is the
resolution-boundary claim itself (LL-008).

**Mitigation pending.** Concrete f_SDE / f_sensor target
numbers calibrated against realistic side-channel adversary
capabilities. Pending P2 (architectural design pass).

### V-004 — Sensor Nyquist failure

**Adversary classes:** A4

**Mechanism.** Even with smooth external-potential-field coupling
(LL-004) avoiding discrete-step artifacts, if the *sensor
sampling rate* is below the underlying physical noise bandwidth,
the adversary doesn't need to capture all the noise — they only
need to replay a pre-recorded statistical distribution of sensor
values that passes the verifier's residue test. The genuine
device's actual instantaneous state has more entropy than the
sampling captures; that uncaptured entropy is wasted on
fingerprinting.

Concrete example: thermal sensors typically sample at ~1 Hz;
thermal noise's physical bandwidth extends much higher. An
adversary recording the genuine device's 1-Hz thermal stream
could replay it indefinitely without any actual hardware
coupling.

**Defenses.**

- **LL-005 (sensor Nyquist condition).** Direct response. The
  formal requirement is that `f_sensor > bandwidth` where
  bandwidth is the physical-noise bandwidth of the source. If the
  Nyquist condition is violated, the security claim does not
  hold for that sensor.

**Residual risk.** Many useful configuration sensors (USB
plugged/unplugged, AC adapter on/off, battery percentage) are
*low-frequency* by physical nature — they don't generate
high-bandwidth noise that needs sampling fast. The security
contribution of these sensors is *configuration discreteness*
(USB is plugged or it isn't), not high-bandwidth noise. The
Nyquist condition needs to be applied per-sensor: high-bandwidth
sources (thermal, CPU governor jitter, scheduler timing) need
fast sampling; discrete-state sensors need authenticity (the
sensor read can't be spoofed at the source, V-006-flavored).

**Mitigation pending.** Per-sensor Nyquist analysis. Concrete
sampling rate selections for each sensor type. Distinction
between "high-bandwidth noise sensor" and "discrete configuration
sensor" in the architecture.

### V-005 — Slow-drift threshold gaming

**Adversary classes:** A2, A4

**Mechanism.** Adversary maintains a forged trajectory that stays
*just below* the residue-detection threshold and gradually drifts
its parameters over time. Each individual snapshot looks
acceptable; the drift accumulates over many observation windows
into a fully spoofed trajectory. Classic anomaly-detector failure
mode: any single-threshold detector is gameable by an attacker
who can model the threshold's response.

**Defenses.**

- **LL-006 (Lyapunov-spectrum residue audit).** Multi-scale
  spectrum comparison resists slow-drift far better than scalar
  threshold. An adversary may drift trajectory location, but
  drifting the *Lyapunov spectrum* requires drifting local
  stretching/folding rates simultaneously across multiple
  timescales — much harder.
- **LL-007 (chaos-guard).** If the adversary's drift accidentally
  pushes the forged trajectory into a periodic window (`λ_max ≈
  0`), chaos-guard rejects the entropy stream entirely, providing
  an additional detection signal.

**Residual risk.** A sufficiently sophisticated adversary may be
able to drift the spectrum itself, slowly enough to stay within
the spectral threshold's calibration tolerance. The defense
ultimately reduces to the **threshold calibration** problem
(LL-014): how tight can the threshold be without false
positives?

**Mitigation pending.** Formal characterization of the drift-rate
the architecture can detect. This may require a *cumulative*
divergence audit (integrate residue over a sliding window) on top
of the per-snapshot spectrum check. Pending P2.

### V-006 — Sensor-input poisoning (spoofing without replication)

**Adversary classes:** A4 (physical proximity)

**Mechanism.** Rather than spoofing the device, the adversary
manipulates the *genuine device's actual sensor inputs* to drive
its trajectory toward a chosen output. Examples:

- Heat the laptop with a hairdryer to push thermal sensors toward
  a target reading.
- Inject simulated USB-plug events via firmware-flashed USB
  device that announces itself but doesn't actually attach.
- Spoof AC adapter status by intercepting / replacing the charge
  controller.
- Manipulate ambient EMI via a co-located transmitter to perturb
  hardware RNG output.

The genuine device produces a genuine trajectory; the trajectory
just happens to be in a basin chosen by the adversary's sensor
manipulation.

**Defenses.**

- **LL-004 (continuous sensor coupling).** Smooth coupling means
  small sensor manipulations produce small trajectory shifts —
  large enough sensor manipulations produce large enough shifts
  that fall outside the configuration's expected envelope. But
  this is a *threshold*, not a hard barrier.
- **LL-013 (cross-config transition handling).** Detection
  protocol distinguishes legitimate sensor changes (user plugged
  in their AC adapter) from adversarial sensor manipulation
  (charge controller is reporting AC-on but actual charge isn't
  flowing). Pending design.

**Residual risk.** **Substantial.** Sensor authenticity is
genuinely hard. The defense reduces to "the sensor wasn't lied
to" — a property that depends on the sensor's own integrity,
which LavaLamp doesn't control. Hardware sensors can be fooled
by physical manipulation; the attack moves down the stack to
"can the sensor itself be trusted?"

**Mitigation pending.** Sensor-authenticity strategy as part of
**LL-013**. Possibilities:

- Multi-sensor cross-validation (heat reading should correlate
  with battery-discharge rate; AC adapter status should correlate
  with measured current draw).
- Sensor-tamper detection (anomalous sensor readings flagged
  separately from trajectory anomalies).
- Acceptance that sensor-input poisoning is a class of attack
  the architecture *partially* defends against and that
  high-assurance deployments need additional physical security.

This is the most significant residual risk in the current
architecture.

### V-007 — Registration ceremony attack (LL-011 surface)

**Adversary classes:** A5, A4 (during ceremony only)

**Mechanism.** The verifier learns the device's hardware envelope
during a registration ceremony. An A5 adversary present during
the ceremony can:

1. **Substitute envelope.** Replace the genuine device's envelope
   with the adversary's chosen envelope, so subsequent
   verification accepts the adversary's trajectory.
2. **Observe envelope.** Record the genuine envelope to inform a
   later trajectory-spoofing attack.
3. **Inject during ceremony.** Manipulate the device's sensors
   during the ceremony so the recorded envelope is non-genuine
   (it captures the genuine device under adversary-controlled
   conditions, then later legitimate-config trajectories fail).

**Defenses.** *None yet — protocol pending design.*

**Residual risk.** **The registration ceremony is the trust root
of the entire system.** An A5 attacker at registration time
defeats every per-trajectory defense. LL-011 must be designed
before LavaLamp can be deployed.

**Mitigation pending.** LL-011 is `:open`. Possible designs:

- Multi-party registration (multiple verifiers commit the
  envelope; collusion required).
- Envelope-derived from device-only-knowable secret (e.g., hash
  of cryptographic identity baked at manufacture, mixed into the
  registered envelope).
- Time-bounded registration (envelope valid only for short
  windows, with re-registration required at intervals — limits
  A5's persistence).
- TPM / Secure Enclave attestation (envelope signed by a hardware
  root of trust the adversary cannot impersonate).

The choice depends on deployment context (consumer vs
enterprise; offline vs networked).

### V-008 — Cold-start window exploitation (LL-012 surface)

**Adversary classes:** A2, A4, A6

**Mechanism.** A just-booted device hasn't run the SDE long
enough for its hardware coupling to fully express in the
trajectory. During this warmup window:

- The Lyapunov spectrum hasn't stabilized; spectrum-based
  detection is unreliable.
- Hardware sensors may not be initialized; sensor coupling is
  partial.
- The adversary may be able to drive the device deterministically
  during boot (controlled USB at boot, cold-boot RAM
  manipulation) to seed the trajectory toward a known starting
  state.

If the verifier doesn't distinguish "device in warmup" from
"device fully running," the warmup window is an exploitation
surface.

**Defenses.** *None yet — protocol pending design.*

**Residual risk.** A device that is *unauthenticatable during
warmup* leaves a window after every boot where verification
either (a) accepts non-genuine state, or (b) rejects genuine
state. Both are problems.

**Mitigation pending.** LL-012 is `:open`. Possible designs:

- Explicit warmup state where verification produces "warmup,
  retry in T seconds" rather than accept/reject.
- Cold-start envelope distinct from steady-state envelope
  (registered separately; verifier knows which to compare
  against).
- Convergence diagnostic on the device side (chaos-guard's
  Lyapunov estimate exposed as "I'm warmed up").

### V-009 — Cross-config transition attack (LL-013 surface)

**Adversary classes:** A4

**Mechanism.** When a USB device is plugged in or AC adapter
connected, the genuine device's trajectory shifts to a new
configuration-specific region of the attractor. The verifier
must distinguish:

- **Legitimate config change.** User plugged in their normal
  USB; trajectory should shift to the registered USB-plugged
  envelope.
- **Spoofing attempt.** Adversary is attempting to drive the
  trajectory to a new region that matches their forgery.

If the verifier accepts any trajectory shift as a config change,
the adversary uses config-change events as cover for spoofing
attempts. If the verifier rejects all transitions, legitimate
configuration changes break verification.

**Defenses.**

- **LL-004 (continuous sensor coupling).** The sensor stream
  itself reports which configuration is active; the verifier
  can use sensor reads as the config signal.
- **LL-013 (cross-config transition handling).** Detection
  protocol uses sensor reads to determine which envelope to
  compare against. Pending design.

**Residual risk.** Sensor reads are themselves attackable
(V-006). If the adversary can spoof "USB-plugged" without
actually plugging in a USB, they can claim "I'm in a new
configuration; here's my new trajectory" without that being
true. V-006 and V-009 compose adversarially.

**Mitigation pending.** LL-013 design. Possibilities:

- Per-configuration registered envelopes (envelope set at
  registration covers expected configurations).
- Transition-pattern fingerprint (the *way* a device transitions
  between configurations — timing, coupling intensity — is
  itself substrate-coupled and hard to spoof).
- Restricted configuration set (system only accepts pre-
  registered configurations; arbitrary configuration claims are
  rejected).

### V-010 — Threshold calibration gaming (LL-014 surface)

**Adversary classes:** A2, A4

**Mechanism.** Whatever threshold the verifier uses for residue
detection has a false-positive / false-negative tradeoff. An
adversary who can probe the threshold (e.g., by submitting
forged trajectories and observing accept/reject responses) can
calibrate their forgery to stay within the false-negative regime.

**Defenses.**

- **LL-006 (multi-scale Lyapunov spectrum).** Threshold isn't a
  single number; it's a vector across multiple spectral features.
  Adversary must satisfy all simultaneously, which raises the
  effort.
- **LL-014 (threshold calibration discipline).** Pending —
  formal calibration procedure that bounds false-positive vs
  false-negative rates against realistic adversary capabilities.

**Residual risk.** Threshold-probing attacks are well-studied in
anomaly detection. The general defense is *not exposing the
threshold's response* (no oracle on accept/reject other than
final verification). LavaLamp's verification protocol must
enforce this — no debug oracle that tells the adversary how close
they were.

**Mitigation pending.** LL-014 design must include:

- Explicit no-oracle requirement in the verification protocol.
- Statistical bounds on false-negative rate at calibrated
  thresholds.
- Optional adaptive thresholding that learns from trajectory
  history and is therefore harder for the adversary to predict.

### V-011 — Reseed Oracle (LL-019 surface)

**Adversary classes:** A2, A4, A5

**Mechanism.** The chaos-guard (LL-007) state machine
{INVALID, WARMUP, VALID} produces observable transitions
when λ̂₁ < τ_λ triggers a reseed. Reseed events correspond to
brief "unavailability" windows on the verifier (the device
returns WARMUP-shaped responses for warmup_steps updates).
Because reseed triggers are sensor-correlated — a thermal
event or sensor-induced parameter drift can push λ̂₁ below
the rejection threshold — an adversary probing verification
readiness or measuring response latency obtains an *event
channel correlated with the device's internal sensor state*.

This is a low-bandwidth oracle: the adversary doesn't read
the trajectory directly, but they can synchronise their spoof
trajectory to the device's reseed cadence, time their attack
to coincide with WARMUP windows, or use reseed timing as a
covert thermal-event detector against the device.

**Defenses.** None yet — pending LL-019 design.

**Residual risk.** Substantial. The chaos-guard's state-
transition logic is currently exposed via natural verifier
output. Any production deployment that emits WARMUP responses
distinguishably from VALID/REJECT responses leaks the timing.

**Mitigation pending.** LL-019 design must specify either:
- Constant-time response (hide WARMUP behind a uniform
  delay matching the slowest legitimate verification path).
- Decorrelation of reseed triggers from observable verifier
  outputs (introduce randomised delay between reseed event
  and any external response that could leak the event).
- Explicit acceptance + documentation that the deployment
  context bounds A4 capability below the timing-precision
  threshold required to exploit this.

**Source.** Surfaced in synthesis-team round 2
(`docs/synthesis_team_round2_companion.md` §1C — Grok
edge-witness response, A1).

### V-012 — Calibration Spectrum Leakage (LL-020 surface)

**Adversary classes:** A5 (registration-time observer)

**Mechanism.** The registration ceremony (LL-011) calibrates
the device's envelope by running n_trials independent SDE
runs and recording per-exponent λ_i mean and σ_i. The current
prototype uses n_trials=10. These ~10 spectrum estimates plus
the calibration statistics are *exposed to anyone who can
observe the registration channel* — even with TPM attestation
preventing envelope substitution, observation of the channel
is not prevented.

An A5 adversary present during registration captures the
registered envelope to machine precision. They can:

1. Reconstruct the SDE family / parameter set by least-
   squares fitting against the captured spectra.
2. Compute the envelope's residue ball geometry exactly
   (mean ± k·σ per exponent at any chosen k).
3. Craft trajectories that lie just inside the rejection
   ball, evading the LL-006 audit by construction.

This directly undermines LL-017 verification-no-oracle:
no-oracle assumes the adversary doesn't know the threshold
geometry, but a registration-channel observer *does*.

**Defenses.** None yet — pending LL-020 design.

**Residual risk.** Substantial. TPM attestation defends
against envelope substitution but not envelope observation;
they are complementary requirements that the current design
treats as a single concern.

**Mitigation pending.** LL-020 design must specify:
- Sealed-storage protocol for the registered envelope
  (verifier-side encryption with key tied to the TPM /
  Secure Enclave), with the envelope never transmitted in
  the clear after registration.
- ε-differentially-private perturbation of any published
  envelope statistics (so observers see a noisy version
  with quantifiable information loss).
- Multi-party threshold scheme on envelope reconstruction
  (no single channel observer reconstructs the envelope
  alone).

**Source.** Surfaced in synthesis-team round 2
(`synthesis_team_round2_companion.md` §1C — Grok edge-witness
response, A2).

### V-013 — Structured α-Direction Attack (LL-021 surface)

**Adversary classes:** A2, A4

**Mechanism.** The synthetic-adversary model in `Audit.jl`
perturbs α isotropically (random unit vector × magnitude).
Real adversaries have *structured* perturbation directions:

- Sensor manipulation (V-006) perturbs only the α components
  coupled to the manipulated sensor — directional.
- Configuration replay (V-009) shifts α toward registered
  configuration directions — directional.
- Slow-drift threshold gaming (V-005) chooses the direction
  that maximally evades the residue test — *adversarially*
  directional.

The empirical detection-probability surface
(`benchmark/results/p3b_detection_lorenz96.txt`) at the
prototype's working point is therefore an *optimistic* lower
bound on detection difficulty; structured adversaries can
align ε with the weakest-coupled directions of the linear
U(s, x; t) and stay inside the residue ball longer than the
isotropic surface predicts.

The under-estimation factor scales with the condition number
of the coupling matrix — visible empirically in the α-sweep
data from 0.0.8 (different α directions produce different
spectrum shifts).

**Defenses.** Partial:

- **LL-006 (Lyapunov-spectrum residue audit).** The vector
  per-exponent test still catches structured adversaries
  who diverge in *any* exponent — they have to suppress
  divergence across the entire spectrum simultaneously.
- **LL-021 (worst-case-adversary-bound, pending).** Re-state
  the LL-006 detection-probability claim against a worst-
  case adversary direction, not isotropic. Empirical
  benchmarks should sweep structured directions in addition
  to isotropic.

**Residual risk.** Moderate. Even with LL-021, a
sufficiently sophisticated adversary aligned with the
weakest-coupled direction can extract more rejection-margin
than the isotropic curve suggests. The honest claim shrinks
from "P(detect) sigmoidal in ε_A" to "P(detect) sigmoidal in
ε_A · cos(θ_min)" where θ_min is the angle between ε and the
worst-case direction.

**Mitigation pending.** LL-021 design + structured-direction
benchmark sweep. Long-term: state-dependent coupling (U
quadratic-or-higher in x) reduces the coupling matrix's
condition-number disparity.

**Source.** Surfaced in synthesis-team round 2
(`synthesis_team_round2_companion.md` §1C — Grok edge-
witness response, A3 + A6).

---

### V-014 — Passive-emanation reconstruction (LL-025 surface)

**Adversary classes:** A4 primary; A1 / A2 limited at higher
adversary tiers.

**Mechanism.** Modern TEMPEST-class research demonstrates
state recovery from acoustic / EM / optical side-channels:
cryptographic key extraction from CPU acoustic emanations
(Genkin et al. 2014); EM leakage at DDR3/DDR4 read rates;
van Eck phreaking on modern displays. The attack on
LavaLamp specifically: the SDE solver runs on a CPU; the
trajectory state lives in registers + memory; integration
steps emanate at the pipeline's clock rate. A passive
adversary with appropriate equipment may extract:

- Full or partial trajectory state via EM / acoustic capture
  of the integration pipeline.
- Per-component state via memory-bus / register-file
  emanations.
- Sensor-coupling parameters via observation of the coupling
  computation.

Reconstruction feasibility scales with adversary tier
(equipment, distance, target specificity); the noise floor
of multi-GHz CPUs makes full trajectory reconstruction at
LavaLamp's chaos-production rate (h_KS · N) hard for all
but state-tier adversaries.

**Defenses.** Partial:

- **LL-025 (A7-passive-emanation-boundary, this version).**
  Tier-bounded scoping declaration: state-actor / mid-tier /
  commodity. Articulates what's defended at each tier and
  what's conceded; commits to honest scope rather than
  universal defense.
- **Hardware-platform choice (deployment-context guidance).**
  TEMPEST-rated enclosure shifts the tier threshold upward;
  not part of LavaLamp itself but available to deployment
  consumers (PharOS scope).
- **Cost-asymmetry framing (LL-008 footer).** Even at state-
  actor tier, attacking LavaLamp via TEMPEST has high
  per-target cost relative to easier targets (cf.
  `threat_landscape_companion.md` §2.7).

**Residual risk.** Bounded by tier:

- **Tier 1 (state actor, sub-meter, lab equipment):** real;
  LL-025 declares scope rather than promising defense.
- **Tier 2 (room-scale SDR, commercial equipment):** signal
  extraction possible; full reconstruction unlikely. LL-025
  scope still applies.
- **Tier 3 (commodity adversary):** negligible capability;
  noise floor + decode complexity bound the threat.

**Mitigation pending.** Hardware-platform-tier guidance for
high-assurance deployments (PharOS scope). LL-025 is a
scoping commitment, not a primitive; deeper mitigation
lives in deployment guidance + hardware-platform choice.

**Source.** Surfaced by Aaron 2026-05-05 ("how does one
stop their machine from leaking radio and other emf that
can be picked up and decoded by passive sensors?") prior to
the round-3 brief; confirmed in synthesis-team round 3 by
both seats (`synthesis_team_round3_companion.md` §1B.Q7 —
Grok synthesis "load-bearing parallel boundary triple"; §1C.A7
— ChatGPT edge-witness "real but tier-bounded").

---

### V-015 — Cross-sector autopoiesis spoofing (paper-derived; LL-006 / LL-007 limitation)

**Adversary classes:** A2, A4

**Mechanism.** The closure_forces_structure paper §11.13
(Self-Reproducing Fixed Point) shows Q_102 = Q_51 ∪ C(Q_51)
is autopoietically closed: 100% of 420 composition products
map back to existing Q_102 vertices, depth-independent at
depths 2-4. The paper's computational autopoiesis test
empirically confirms this with the 0/5202 result at
threshold 0.999 — cross-sector autopoiesis fails
structurally.

But: the *attempted* attack still produces a partial
trajectory before divergence triggers structural failure. An
adversary can craft an early-stage trajectory that:

- Looks genuine for the first T < T_div integration steps.
- Exhibits sensor-coupling that *would* be authentic if
  fully extended.
- Diverges from a genuine trajectory only after the
  structural mismatch accumulates past the divergence
  threshold.

This is the analog of prefix-valid cryptographic forgery —
the early-stage trajectory passes as authentic; only the
sustained-pattern check would catch it.

The attack-mechanism axis (early-stage prefix mimicry before
LL-007 reseed triggers) was originally surfaced as V-021 in
ChatGPT's edge-witness response and merged into V-015 per
round-3 §1D.vi decision 2.

**Defenses.** Partial:

- **LL-006 (Lyapunov-spectrum residue audit).** Per-exponent
  vector audit catches sustained mismatches. But the audit
  needs T ≥ T_div integration steps to accumulate evidence —
  prefix attacks shorter than T_div may evade.
- **LL-007 (chaos-guard).** Triggers on `λ̂₁ < τ_λ` divergence
  collapse — but only after divergence is fully manifest,
  not at the *beginning* of a partial autopoiesis attempt.
- **LL-026 (logic-tier annotation discipline, this
  version).** Forces explicit Possibilistic / Probabilistic
  / Bridge annotation per claim, reducing the surface for
  V-017-style logical-tier confusion attacks that compound
  V-015.

**Residual risk.** Moderate. The structural impossibility
result (paper §11.13) closes the *long-run* attack; the
*short-run* attack window before LL-007 / LL-006 catches
divergence remains. T_div is parameter-dependent; with N=20
and h_KS · N ≈ 5 nats/sec, T_div is on the order of
0.5-1.0 s of integration time — exploitable for short-window
verification protocols.

**Mitigation pending.** Per-request audit with T ≥ T_div
guarantee (LL-019's audit-on-verify pattern partially
addresses this). Open: explicit lower-bound on verification
time as a function of N and chosen-FPR.

**Source.** Paper-derived (closure_forces_structure §11.13).
Confirmed in synthesis-team round 3 by both seats
(`synthesis_team_round3_companion.md` §1B.Q1 — Grok
synthesis "(c) LL-007 reseed instantiation"; §1C.A6 —
ChatGPT edge-witness "real and not fully covered" + V-021
prefix-trajectory mimicry mechanism axis).

---

### V-016 — Numerical-threshold calibration gaming (paper-derived; LL-014 / LL-026 surface)

**Adversary classes:** A2, A4

**Mechanism.** The closure_forces_structure paper §13.6
(Evidence Classification) explicitly notes: at threshold
`0.999`, spurious merges occur for ~5% (Q_48) to ~12%
(Q_102) of Haar-random initial conditions; at threshold
`1 − 10⁻¹²`, 200/200 seeds give the canonical vertex counts.
The threshold is *numerical convenience*, not part of the
mathematical definition.

LavaLamp's LL-014 (adversary-signature threshold calibration)
sets per-exponent `τ_i = 3·σ(λ̂_i | T)` baseline; the
analog: LavaLamp's threshold zone (~10% baseline FPR per
the P3-bound benchmark with k=5, n_trials=10) is *the same
phenomenon as the paper's 5-12% spurious-merge zone*. Quote
from ChatGPT (round 3 §1C.A6): *"The paper's 5–12% spurious
merge region maps almost exactly to LL-014 FPR baseline
(~10%). This is not coincidence — it is the same phenomenon
in different language: threshold ≠ structure."*

The attack: an adversary crafts a trajectory that lies in
LavaLamp's analog of the "spurious merge" zone — within the
audit threshold but not actually a genuine trajectory. The
language axis (LL-014 FPR ≡ paper §13.6 spurious merge) was
originally surfaced as V-022 in ChatGPT's edge-witness
response and merged into V-016 per round-3 §1D.vi decision 2.

**Defenses.** Partial:

- **LL-014 (adversary-signature threshold calibration).**
  Per-exponent calibration discipline. Partial defense; the
  threshold zone exists by construction.
- **LL-014 amendment (Tier 2, pending).** Explicit annotation
  that the 10% FPR baseline is *calibration convenience*,
  not structure — same status as the paper's `0.999` vs
  `1−10⁻¹²` decision. Forces deployment-config attention to
  threshold tightening for high-assurance scope.
- **LL-026 (logic-tier annotation discipline, this version).**
  Reduces surface for compounding V-016 with V-017 logical-
  tier confusion attacks.

**Residual risk.** Moderate. The threshold zone is
parameter-controllable; tighter thresholds reduce the zone
but increase compute cost. PharOS-tier deployments will
likely tighten beyond the prototype's 10% baseline. The
core insight ("threshold ≠ structure") is a permanent
discipline, not a fixable bug.

**Mitigation pending.** LL-014 amendment in Tier 2; per-
deployment threshold-tightening guidance in PharOS scope.

**Source.** Paper-derived (closure_forces_structure §13.6).
Confirmed in synthesis-team round 3 by both seats
(`synthesis_team_round3_companion.md` §1B.Q1 + §1C.A6 —
ChatGPT edge-witness named the LL-014 ≡ paper §13.6
equivalence explicitly).

---

### V-017 — Three-layer logical-tier confusion (LL-026 surface)

**Adversary classes:** A1, A2 (meta-attack on the proof
framing rather than a runtime channel)

**Mechanism.** The closure_forces_structure paper §1.2
articulates a three-layer logical structure: **Possibilistic
Layer** (forced / forbidden / compatible — discrete
combinatorial); **Probabilistic Layer** (Born rule + Gleason
— measurement); **Bridge Layer** (NCG-derived
unconditional). Quote: *"these are not interchangeable;
conflating them produces category errors."*

LavaLamp's spec entries cluster across the three layers
implicitly: LL-001 / LL-006 / LL-008 / LL-018 are
Possibilistic-tier (cost-asymmetry; what's forbidden under
the constraint surface); LL-019 / LL-020 / LL-021 touch
Probabilistic (statistical bounds, ε-DP, FPR); LL-011 /
LL-012 / LL-013 / LL-017 are Bridge-tier (deployment
protocols spanning the layers).

The attack: an adversary deliberately exploits a category
error in LavaLamp's spec — apply a Probabilistic-tier attack
against a claim that's only defended at the Possibilistic
tier. Concrete example from ChatGPT (round 3 §1C.A6):
*"LL-008 claims forbidden region; adversary reframes as low
probability. This breaks security proofs at the reasoning
layer."* The attack doesn't break the runtime; it breaks
the *justification* for the runtime's claims.

**Defenses.** Full (after LL-026):

- **LL-026 (three-layer logic-tier annotation discipline,
  this version).** Every spec entry annotated explicitly:
  Possibilistic / Probabilistic / Bridge per paper §1.2.
  The annotation itself is the defense — eliminates the
  category-error surface by construction. Adversary cannot
  apply Probabilistic reasoning to a claim that's tagged
  Possibilistic.
- **CLAUDE.md governance amendment (pending companion
  doc-standard update).** Future spec amendments must carry
  the layer tag; cross-audits include layer-consistency check.

**Residual risk.** Low post-LL-026 landing. The discipline
is governance, not engineering — once the spec is
annotated, the attack surface closes.

**Mitigation pending.** Per-entry layer annotation pass on
existing LL-001..LL-024 entries (follow-up companion in
Tier 2 or as a small-session pass).

**Source.** Paper-derived (closure_forces_structure §1.2).
Confirmed in synthesis-team round 3 by both seats
(`synthesis_team_round3_companion.md` §1B.Q1 + §1C.A6 —
ChatGPT edge-witness *"very real and dangerous"* meta-attack).

---

### V-018 — Coordinated multi-sensor synthesis (LL-029 future)

**Adversary classes:** A4 (physical proximity required for
coordinated sensor manipulation)

**Mechanism.** LL-016 Strategy 2 (multi-sensor cross-
validation) defends against *naive* spoofing where the
adversary manipulates one sensor in isolation. But a
determined adversary can **physically couple channels** to
satisfy the cross-validation constraints rather than
violate them:

- Heater coupled to thermal sensor produces correlated
  battery-discharge signal → thermal + battery cross-
  validation passes.
- Load injector produces both AC current draw and thermal
  rise → AC + thermal cross-validation passes.
- Vibration motor produces correlated mic + accelerometer
  signal → mic + accelerometer cross-validation passes.

Quote from ChatGPT (round 3 §1C.A2): *"The cross-validation
model assumes independent noise sources, but a determined
adversary can couple channels physically. This is a classic
sensor-fusion-inversion attack: attacker injects signals
that satisfy constraints rather than violate them."*

The attack defeats LL-016 Strategy 2 because the *independence
assumption* is wrong, not because the cross-validation
mechanism is wrong.

**Defenses.** None yet structurally; pending LL-029.

- **LL-016 (sensor-authenticity requirement).** Existing
  spec entry; requires authenticity but does not enumerate
  *physical-mechanism diversity* as part of the requirement.
- **LL-029 (multi-channel entropy independence; pending
  Tier 3).** Will require physical-mechanism diversity —
  different *physical phenomena*, not just different
  sensors. Heater + thermal + battery share one physical
  mechanism (thermal); LL-029 forces enumeration of
  uncorrelated physical mechanisms (thermal + acoustic +
  RF + entropy-source-decay) before cross-validation
  qualifies.

**Residual risk.** High pre-LL-029. Compounds V-006
(sensor-input poisoning) by raising the adversary capability
required to defeat cross-validation: V-006 says "sensor
manipulation possible"; V-018 says "coordinated
manipulation defeats the cross-check, not just one
channel". Together they form the *biggest engineering gap*
post-round-3.

**Mitigation pending.** LL-029 (Tier 3) — physical-mechanism-
diversity requirement. Operational implication: P-RS Level 2
sensor architecture must enumerate the physical-mechanism
families and ensure sensor selection spans uncorrelated
families.

**Source.** Surfaced in synthesis-team round 3
(`synthesis_team_round3_companion.md` §1C.A2 — ChatGPT
edge-witness seat).

---

### V-019 — Runtime conformance bypass (LL-028 future)

**Adversary classes:** A2 (deployer-controlled runtime;
malicious or compromised deployer); occasionally A3 in
deeper bypass.

**Mechanism.** The deployment-stack triple (LL-022 +
LL-023 + LL-024) defines what LavaLamp depends on, what it
exposes, and how it instantiates — but **conformance is
deployment-time configuration, not runtime enforcement**.
A malicious or compromised deployer can satisfy the
LL-023 API contract while violating LL-022 invariants
internally:

- Cached randomness reused while reporting fresh entropy
  (bypasses LL-022(c) host-TRNG requirement).
- Bypassed TRNG with deterministic replay (verifier sees
  expected `getrandom` shape; under the hood, fixed seed).
- Forged sensor-fusion outputs upstream (LL-024 Strategy 2
  cross-validation reports success without actually reading
  hardware).
- TPM attestation stub returns hardcoded "valid" without
  hardware verification.

Quote from ChatGPT (round 3 §1C.A3): *"system satisfies API
but violates invariants internally. This is equivalent to
type-level vs semantic conformance mismatch."*

The attack defeats the deployment-stack triple because the
triple specifies *what* must hold, not *how* to verify it
holds at runtime.

**Defenses.** None yet structurally; pending LL-028.

- **LL-022 / LL-023 / LL-024 (existing).** Specify
  requirements; do not enforce.
- **LL-028 (runtime conformance verification; pending Tier 3).**
  Will require runtime invariant verification: continuous
  attestation that LL-022 mechanisms are actually being
  used; periodic re-checks of LL-024 sensor authenticity;
  LL-023 verifier-side conformance probes.

**Residual risk.** High pre-LL-028. The deployment-stack
triple is *honest about its scope* (configuration trust,
not runtime enforcement) but the attack surface is real for
adversaries who control the deployment context.

**Mitigation pending.** LL-028 (Tier 3) — runtime
conformance verification. Likely requires:

- TPM-attested boot + measured runtime state (where TPM is
  available per LL-022).
- Periodic LL-024 sensor cross-validation with adversarial
  test cases.
- Verifier-side LL-023 API contract probing.

**Source.** Surfaced in synthesis-team round 3
(`synthesis_team_round3_companion.md` §1C.A3 — ChatGPT
edge-witness seat).

---

### V-020 — Stable-manifold stealth injection (LL-021 amendment, Tier 2)

**Adversary classes:** A2, A4

**Mechanism.** At large N (Lyapunov spectrum dimension), the
attractor manifold has both unstable directions (positive
λ_i) and stable directions (negative λ_i). At N=160 (the
0.0.30 N-scaling benchmark's largest case), there are ~52
unstable directions and ~108 stable directions. An adversary
can inject perturbations along strongly-contracting stable
modes:

- **Stable-direction injection.** Perturbations along
  modes with most-negative λ_i decay rapidly under the
  flow → minimal spectral impact on LL-006 audit. Audit
  passes; perturbation persists.
- **Manifold shadowing.** Adversary maintains trajectory
  near the attractor while diverging in unobserved
  subspaces. Standard residue audit compares to envelope
  in observed coordinates; shadowing in unobserved
  subspaces evades.
- **Spectral gap flattening.** High-dimensional attractors
  have many λ_i values close to each other; the
  distinguishability margin (max(λ_i) − τ_λ) is reduced
  per dimension.

Quote from ChatGPT (round 3 §1C.A5): *"LL-021 likely does
not generalize without re-benchmarking."*

The attack matters because LL-021's worst-case bound was
validated empirically only at N=20 (0.0.18 / 0.0.28). At
N=160, the curvature of the attractor manifold, mixing
times, and detectability thresholds all change. The bound
shape `ε_eff = ε_A · proj` may still hold but the
parametric constants differ.

**Defenses.** Pending Tier 2:

- **LL-021 amendment (Tier 2, pending).** Explicit scope-
  limit: bound is stated for **finite-N regime (N ≤ 80)**;
  large-N regime requires re-benchmarking. Plus adaptive-
  adversary amendment (per ChatGPT A4): bound stated
  against *adaptive* linear-model adversary, not static.
- **LL-006 (Lyapunov-spectrum residue audit).** Per-
  exponent vector audit catches divergence in any one mode
  — including stable-mode reversals. Partial defense at
  large N; the per-exponent test still applies.
- **Deployment-tier N selection.** PharOS (high-assurance):
  N=160 with tight thresholds + LL-021 large-N bench.
  Lazarus (consumer): N=80 within validated regime.

**Residual risk.** Moderate. The stable-direction injection
attack class is mathematically real but practically bounded
by the residue audit's per-exponent sensitivity (LL-006 is
not just λ_max). At N ≤ 80 the existing LL-021 benchmarks
apply; at N > 80 honest framing requires the scope-limit.

**Mitigation pending.** LL-021 amendment + large-N
re-benchmark (Tier 2 + future P3 follow-up benchmark at
N=160 with structured-direction adversaries).

**Source.** Surfaced in synthesis-team round 3
(`synthesis_team_round3_companion.md` §1C.A5 — ChatGPT
edge-witness seat).

---

## §4 — Adversary class × attack vector matrix

Coverage at a glance. ● = primary adversary class for this
vector; ○ = secondary / contributing class; blank = not applicable.

| | A1 remote | A2 unpriv | A3 root | A4 side-ch | A5 reg | A6 time-loc |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| V-001 "good enough" | | ● | OOS | ● | | |
| V-002 basin-spoof (closed) | | ● | OOS | ● | | |
| V-003 q-seed → classical | | | OOS | ● | | |
| V-004 Nyquist | | | OOS | ● | | |
| V-005 slow-drift | | ● | OOS | ● | | |
| V-006 sensor poison | | | OOS | ● | | |
| V-007 reg ceremony | | | | ○ | ● | |
| V-008 cold-start | | ● | OOS | ● | | ● |
| V-009 cross-config | | | OOS | ● | | |
| V-010 threshold game | | ● | OOS | ● | | |
| V-011 reseed oracle | | ● | OOS | ● | ● | |
| V-012 calibration leak | | | | ○ | ● | |
| V-013 structured α-attack | | ● | OOS | ● | | |
| V-014 passive emanation | ○ | ○ | OOS | ● | | |
| V-015 cross-sector autopoiesis | | ● | OOS | ● | | |
| V-016 numerical-threshold game | | ● | OOS | ● | | |
| V-017 logical-tier confusion | ● | ● | OOS | | | |
| V-018 coordinated multi-sensor | | | OOS | ● | | |
| V-019 runtime conformance | | ● | OOS | | | |
| V-020 stable-manifold stealth | | ● | OOS | ● | | |

**OOS** = out of scope (A3 root assumed defeated; LavaLamp does
not claim defense against full-kernel adversaries).

A1 (remote software) is broadly defended by the substrate-coupling
itself — they have nothing to model with. A4 (side-channel /
physical proximity) is the *load-bearing adversary class*: if A4
attacks succeed, LavaLamp's claim is much weaker than the pitch
suggests.

---

## §5 — Residual risks not yet defeated

Honest enumeration of attack vectors the current architecture
does *not* yet defeat:

**1. Sensor authenticity (V-006).** Cannot be solved within the
trajectory layer; requires sensor-cross-validation strategy or
hardware-attested sensors. Without this, A4 adversaries with
physical proximity can drive the genuine device to produce
chosen trajectories. **This is the biggest residual gap.**

**2. Registration ceremony (V-007).** Trust root undefined.
Until LL-011 is designed, any deployment is undefended at
registration time.

**3. Cold-start window (V-008).** Authentication during boot is
undefined. Window of unauthenticatable state after every boot
event.

**4. Cross-config transitions (V-009).** Distinguishing
legitimate config changes from adversarial spoofing requires
LL-013, which is pending. The defense partially relies on
sensor authenticity (V-006), so V-009 inherits V-006's residual
risk.

**5. Threshold calibration (V-010).** Calibration discipline
LL-014 pending. Without bounded false-negative rates, slow-drift
attacks (V-005) are not provably detected.

**7. Reseed oracle (V-011).** Chaos-guard state transitions
observable as timing channel; sensor-correlated. LL-019
pending — constant-time response or randomised-delay protocol.

**8. Calibration spectrum leakage (V-012).** Registration-
channel observers capture the registered envelope. LL-020
pending — sealed storage / ε-DP perturbation / multi-party
threshold scheme.

**9. Structured α-direction attack (V-013).** Empirical
detection surface is optimistic vs structured adversaries.
LL-021 pending — worst-case-direction bound and structured-
adversary benchmark.

**10. Passive emanation (V-014).** TEMPEST-class adversary
recovers trajectory state from EM / acoustic / optical
emanations. LL-025 (0.0.45) declares scope by adversary
tier rather than promising universal defense: Tier 1 (state
actor, sub-meter) is honest residual risk; Tier 2 (mid-tier
SDR) is deployment-context guidance; Tier 3 (commodity) is
negligible. Tier-bounded scope, not universal defense.

**11. Coordinated multi-sensor synthesis (V-018).** Adversary
physically couples sensor channels to satisfy LL-016 cross-
validation rather than violate it. LL-029 (Tier 3, pending)
will require physical-mechanism diversity (different physical
phenomena, not just different sensors). Compounds V-006
sensor-input-poisoning. **Largest engineering gap post-
round-3.**

**12. Runtime conformance bypass (V-019).** Deployer
satisfies LL-023 API contract while violating LL-022
invariants internally (cached randomness, deterministic-
replay TRNG, forged sensor-fusion outputs). LL-028 (Tier 3,
pending) will require runtime invariant verification. Real
attack surface for adversaries who control the deployment
context.

**13. Stable-manifold stealth at large N (V-020).** LL-021
worst-case bound was validated only at N=20 (0.0.18 / 0.0.28);
at large N the attractor has many stable directions an
adversary can exploit (52 unstable / 108 stable at N=160).
LL-021 amendment (Tier 2, pending) adds explicit scope-limit
to N ≤ 80 plus adaptive-adversary text; large-N re-benchmark
pending.

**6. A3 (kernel-level adversary) is explicitly out of scope.**
This is honest scoping, not residual risk — but consumers of the
spec must understand that LavaLamp is a defense against bounded
adversary capability, not a defense against arbitrary attackers
with arbitrary code execution on the device.

---

## §6 — Spec-impact recommendations

This enumeration surfaces architectural claims that should be
pinned as additional spec entries. Recommended additions in 0.0.4:

- **LL-015 — adversary-class-A3-out-of-scope.** Explicitly state
  in the spec that defense against A3 (kernel-level adversaries)
  is out of scope. Honest scoping; protects against future
  drift toward overclaiming.
- **LL-016 — sensor-authenticity-requirement.** Sensor reads
  used in the security primitive must satisfy a separate
  authenticity check (cross-sensor correlation, hardware
  attestation, or accepted-residual-risk). Currently the residual
  risk in V-006 is *implicit* in LL-013's open status; making it
  explicit prevents drift.
- **LL-017 — verification-no-oracle.** The verification protocol
  must not expose accept/reject feedback that lets the adversary
  probe the residue threshold. Required for LL-014 to deliver its
  intended security.
- **LL-018 — adversary-resolution-bound-formalisation.** Formal
  statement of the resolution-boundary claim (LL-008) including
  the adversary classes A1–A6 and which capability levels the
  claim covers.

These are recommendations, not commitments — Aaron's call on
which (if any) get added.

---

## §7 — Followups

- **P2 — Architectural design pass.** This enumeration surfaces
  several open architectural questions: per-sensor Nyquist
  analysis, sensor-authenticity strategy, registration-ceremony
  design, cold-start handling, cross-config protocol, threshold
  calibration. P2 must close these or document them as
  intentional `:open` entries with timelines.
- **Round-2 synthesis-team review.** Trigger: after P2 closes
  the open architectural questions. Brief: forward this
  enumeration + P2 outputs and ask Gemini (synthesis) and Grok
  (edge-witness) to validate the threat tree against attacks
  this enumeration may have missed.
- **Spec entries.** Per §6, add LL-015..LL-018 (or refine to
  fewer / different entries) in 0.0.4 if accepted.
- **Eventual paper structure.** This document is the load-bearing
  technical content of the LavaLamp paper. The paper will need:
  Introduction (problem statement + corpus context); Architecture
  (LL-001..LL-014); Threat model and defenses (this document);
  Formalization (Julia prototype + Haskell compositional check +
  Lean theorem); Discussion (residual risks, deployment context,
  honest tier framing); Acknowledgments (codetaur visual seed,
  Brian ORSIΩ engagement, Gemini + Grok synthesis-team).

---

## §8 — Document discipline

This enumeration is **not** a session companion in the engine-
project sense (one doc per substantive working session). It is a
*formal artefact* that captures the architecture's threat model.
It will be updated as the architecture evolves: new attack vectors
get added when discovered; existing vectors get refined as
defenses are formalized; closed vectors stay in the document with
their resolution noted (e.g., V-002 is closed but documented).

The naming distinction (`attack_surface_enumeration.md` vs.
`*_companion.md`) reflects this: companions are historical
records of sessions; this is a maintained technical document.

Updates to this document should land in versioned changelog
entries, with the V-IDs append-only (parallel to LL-IDs in the
spec) and resolutions tracked rather than removed.
