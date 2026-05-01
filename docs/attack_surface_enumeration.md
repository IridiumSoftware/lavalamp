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
