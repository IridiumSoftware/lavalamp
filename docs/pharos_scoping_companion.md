# PharOS Scoping Pass — LavaLamp ↔ PharOS Consumer Architecture

Version: 0.0.34 (PharOS scoping pass; LL-023 added :argued, 2026-05-04)

Permanent record of the PharOS scoping pass — parallel-safe
design work landed while waiting for the
`closure_forces_structure` paper update + engine updates. The
2026-05-03 0.0.26 P-OS pass scoped what *LavaLamp depends on
from the OS layer* (LL-022, *upward dependencies*). This pass
scopes the complementary question: **what does LavaLamp expose
to consumers above** — specifically PharOS, the canonical
OS-deployment consumer in the Triad Deployments portfolio.

LL-022 (downward) + LL-023 (upward) together close LavaLamp's
trust-stack scoping question on both ends. The pair is the
asymmetry-trap defence at the consumer-API surface level: a
reader projecting LavaLamp into a deployment context sees
explicitly *what consumes its primitive*, *what surface that
consumption uses*, and *what guarantees the surface provides*.

PharOS itself does not yet exist as a separate repo. This
companion is design-only; when PharOS lands operationally, it
will get its own spec / dashboard / tests that conform to the
LL-023 surface this companion articulates. The Triad Deployments
sequencing per the portfolio reference: Lazarus (existing) →
LavaLamp (prototype-stage at 0.0.34) → PharOS (forthcoming;
this scoping pass is its design-stage entry point).

---

## §1 — Computational basis

### §1.1 — Inputs

- `LAVALAMP_SPEC.md` v0.0.33 — 22 spec entries; the entries that
  the consumer-API surface touches (LL-011 registration
  ceremony, LL-013 cross-config transitions, LL-014 threshold
  calibration, LL-017 verification no-oracle, LL-022
  OS-trust-stack-dependency) read directly.
- `docs/architecture_design_companion.md` §2.5 — protocol layer
  (registration / cold-start / cross-config / no-oracle).
- `docs/os_identity_security_scoping_companion.md` (0.0.26) —
  the shape this pass mirrors. PharOS scoping is the *upward*
  complement to that pass's downward scoping.
- `README.md` Portfolio section — Triad Deployments umbrella +
  the three deployments (Lazarus / LavaLamp / PharOS).
- `~/.claude/projects/.../memory/reference_triad_deployments.md`
  — portfolio branding decision (2026-05-04).
- `dashboard.md` "asymmetry-trap watch" — same discipline note
  that motivated the 0.0.26 P-OS pass.

### §1.2 — No code; design synthesis only

This pass produces no code, no tests, no benchmarks. The
evidence type is `manual`; the new spec entry LL-023 lands at
`:argued` per CLAUDE.md §Evidence types. PharOS's own
implementation lives in PharOS's future repo; LavaLamp's spec
captures the LL-023 commitment to expose a stable API surface.

### §1.3 — Why now (parallel-safe)

The PharOS scoping pass has zero connection to the
round-3-blocked C-conjugate adversary structure, Q₅₁-tier
identity claim, or 0/5202 cross-sector autopoiesis result. It
operates entirely at the consumer-API-surface layer and can
land in parallel with the upstream paper / engine work. Same
parallel-safety justification as the 0.0.26 P-OS pass.

---

## §2 — Results

### §2.1 — PharOS architectural role

**PharOS is the OS-level identity layer that consumes LavaLamp's
verifier API to provide device-bound authentication for
operating-system primitives.** The lighthouse metaphor
(intentional in the name) is operational: PharOS serves as a
*persistent reference point* that downstream OS subsystems
(login window, sudo, SSH agent, biometric replacement, etc.)
query for "is this device the genuine one?" — a fixed beacon
that tells navigators "you've arrived at the right place."

**What PharOS does:**

- **Register** the device's LavaLamp envelope at install time
  (per LL-011 registration ceremony, called from PharOS's
  install / first-boot flow).
- **Verify** the device's current trajectory against the
  registered envelope on demand (per LL-017 verification
  no-oracle), exposing a single `is-this-device?` Boolean to
  consumers.
- **Mediate** between OS authentication subsystems and
  LavaLamp's verifier — translates OS-level
  authentication-request semantics into LavaLamp verify calls.
- **Expose** a stable API to OS consumers (PAM module on Linux,
  Authorization Plug-in on macOS, Credential Provider on
  Windows) so login / sudo / SSH agent integration is a small
  shim rather than a rewrite.

**What PharOS does *not* do:**

- It does not reimplement the security primitive — the SDE,
  sensor coupling, residue audit, chaos-guard all run inside
  LavaLamp.
- It does not modify LavaLamp's spec or behaviour. PharOS is
  a consumer; the verifier-side discipline (LL-011 / LL-013 /
  LL-014 / LL-017) is unchanged.
- It does not introduce its own trust-tier above LavaLamp's.
  LavaLamp's resolution-bounded computational unclonability
  (LL-008) is the load-bearing claim; PharOS inherits the tier,
  not exceeds it.
- It does not defend against A3 (kernel-level) adversaries.
  LL-015's downward boundary applies transitively — PharOS,
  running in user-space, cannot defeat A3.

The role analogy: PharOS is to LavaLamp as a database driver is
to a database. The database has the data and the query engine;
the driver translates application calls into database
operations. PharOS translates OS authentication requests into
LavaLamp verify calls.

### §2.2 — LavaLamp ↔ PharOS API surface

The LL-023 surface is the contract LavaLamp commits to expose
for consumers (PharOS, future Lazarus product UIs, future
embedded SDKs). The surface has four operations:

#### §2.2.1 — `register(device, envelope_storage_path) → registration_handle`

Acquires the device's registered envelope per LL-011. Called
once at install / first-boot time; the resulting envelope is
stored at the consumer-supplied path (which may be
TPM-sealed per LL-022 §2.2.1, or DP-protected per LL-020
Strategy 2, or accepted as plaintext for low-assurance
deployments).

**Inputs:**
- `device` — a handle to the LavaLamp engine instance
  (typically created via the LavaLamp library's init flow with
  the configured SDE / sensors / chaos-guard parameters).
- `envelope_storage_path` — where the consumer wants the
  resulting `Envelope` blob stored. PharOS uses a TPM-sealed
  blob on hardware-rooted deployments; ε-DP-perturbed plaintext
  on universal-fallback deployments per LL-020.

**Outputs:**
- `registration_handle` — opaque pointer / file descriptor /
  protobuf the consumer uses to refer to the registration in
  later `verify` calls.

**Errors:**
- Hardware-attestation failure (TPM unavailable when required).
- Envelope storage I/O failure.
- Device-state-not-converged (LL-007 chaos-guard refuses
  registration if `is_valid()` returns false during
  calibration).

Consumers: PharOS calls `register` from its install flow.
Lazarus might call from its onboarding. Future embedded SDKs
might bake registration into manufacturing.

#### §2.2.2 — `verify(registration_handle, current_trajectory) → Bool`

Single-bit accept/reject decision per LL-017. Called every time
an OS authentication request needs to know if the device is
genuine.

**Inputs:**
- `registration_handle` — from `register`.
- `current_trajectory` — a snapshot of the device's current
  SDE state plus enough integration to compute λs at the
  configured T_observation. May be precomputed (LL-007
  chaos-guard maintains the trajectory continuously) or
  computed on demand.

**Outputs:**
- `Bool` only. No distance, no per-exponent residual, no
  time-to-detection. Per LL-017 strict no-oracle.

**Variants:**
- `verify` (plain): cheap; uses pre-computed λs if available.
- `verify_full(ds, env; ...)` (LL-019 audit-on-every-verify):
  forces full Benettin spectrum computation per call; the
  production-grade variant.
- `verify_constant_time(λs, env; target_seconds)` (LL-019
  timing decorrelation): pads response time to a uniform
  target; mandatory for production deployments where timing
  channels matter.

**Errors:**
- Cold-start / WARMUP (per LL-012 cold-start window) — return
  `WARMUP` instead of `Bool`.
- Cross-config transition (per LL-013) — return `TRANSITIONING`
  instead of `Bool` for the brief equilibration window.
- Unknown configuration — return `UNKNOWN_CONFIGURATION`.
- Rate-limited — return `RATE_LIMITED` per LL-014's per-source
  / per-device rate-limit policy.

The error variants are not oracles — they convey deployment
state, not threshold-distance information.

#### §2.2.3 — `device_state() → GuardState`

Real-time chaos-guard status per LL-007. Returns `INVALID`,
`WARMUP`, or `VALID`. Called by consumers to decide whether
verification is currently meaningful.

**Inputs:** None (queries the running engine's chaos-guard).

**Outputs:** `GuardState` (one of three enum values).

**Use case:** PharOS calls `device_state()` before every
`verify` to filter out responses that would arrive in
INVALID / WARMUP states; presenting "device not ready" to the
OS consumer is more honest than auto-rejecting on a transient
chaos-guard reseed.

#### §2.2.4 — `re_register(registration_handle, new_envelope_storage_path) → new_registration_handle`

Time-bounded re-registration per LL-011 variant C. Called when
the consumer needs to refresh the envelope (e.g., post-
hardware-change, post-OS-upgrade, scheduled rotation).
Atomic: the new envelope replaces the old one only after
calibration succeeds; the old envelope remains valid until
then.

**Inputs:**
- `registration_handle` — from previous `register` /
  `re_register`.
- `new_envelope_storage_path` — typically same path as before;
  consumer may rotate to a different TPM slot.

**Outputs:**
- `new_registration_handle` — replaces the old handle.

**Errors:**
- Same as `register`.
- `RE_REGISTRATION_RATE_LIMITED` if the consumer is calling
  more frequently than LL-014 policy allows.

### §2.3 — PharOS ↔ OS integration points

PharOS exposes the `verify` decision to OS authentication
subsystems via platform-specific shims. The shims are *thin*:
they translate platform authentication-request semantics into
PharOS API calls; they do not reimplement security logic.

**macOS:** Authorization Plug-in (AuthorizationCreate /
AuthorizationCopyRights). PharOS shim registers itself as an
authorization mechanism; the plug-in's `mechanism_invoke`
function calls `verify_full` and translates the Bool result
into AuthorizationResultAllow / AuthorizationResultDeny.

**Linux:** PAM module. PharOS shim ships as
`pam_pharos.so`; consumers (login, sudo, sshd) include
`auth required pam_pharos.so` in the relevant
`/etc/pam.d/*` config files. The module's `pam_sm_authenticate`
function calls `verify_full` and returns PAM_SUCCESS /
PAM_AUTH_ERR.

**Windows:** Credential Provider. PharOS shim ships as a COM
object implementing `ICredentialProvider`; the
`GetCredentialAt` method returns a `pharos_credential` whose
`GetSerialization` method calls `verify_full`.

**SSH agent / SSH key wrapping:** Optional. PharOS can wrap
SSH private keys with a key-derivation function whose input
is the LavaLamp envelope; the keys decrypt only when the
device verifies. This is a more advanced integration; first-
release PharOS focuses on login / sudo only.

**Biometric replacement:** PharOS substitutes for
fingerprint / FaceID-style local biometrics on devices that
have substrate-rich enough sensor inputs (per LL-016 sensor
authenticity). The substitution is an *operational equivalent*,
not a cryptographic one — the device-bound identity is
analogous to a biometric in that it's tied to the physical
device, but the security tier is resolution-bounded
computational (LL-008), not biometric-template-matching.

### §2.4 — PharOS's own threat model

PharOS's threat model is *narrower* than LavaLamp's because
PharOS does not implement the security primitive. PharOS
defends against:

1. **Authentication-request spoofing** — an attacker who can
   send authentication requests but not control the device's
   trajectory cannot cause a false ACCEPT. Defended by LL-017
   no-oracle (PharOS only returns Bool to the OS layer; no
   threshold-probing surface).
2. **Replay attacks** — a captured authentication-allow
   response cannot be replayed. Defended by per-request
   trajectory snapshot (each `verify` requires the device's
   *current* state, not a historical one).
3. **Configuration-transition attacks** — an attacker who can
   trigger configuration changes (USB plug, AC plug) cannot
   cause spurious ACCEPTs during transitions. Defended by
   LL-013 cross-config transition handling (PharOS surfaces
   the TRANSITIONING state honestly).

PharOS does **not** defend against:

1. **A3 (kernel-level) adversaries** — same boundary as LL-015.
   A kernel-mode attacker can simulate the SDE trajectory
   directly and bypass PharOS entirely.
2. **Sensor manipulation (V-006)** — same boundary as LL-016.
   PharOS inherits LavaLamp's sensor-authenticity strategies
   (TPM / multi-sensor cross-validation / anomaly flagging /
   eBPF authentication on Linux per LL-022 §2.3.3).
3. **Registration-time insiders (V-012, A5)** — same boundary
   as LL-011 + LL-020. PharOS inherits the registration-
   ceremony protocol and the calibration-confidentiality
   strategies.
4. **Side-channel timing oracles** — defended only when
   PharOS calls `verify_constant_time` (LL-019). PharOS
   should call `verify_constant_time` by default in
   production deployments.

PharOS's threat model is therefore **transitively** what
LavaLamp defends against minus what PharOS itself excludes.
The exclusions match LavaLamp's existing boundaries; PharOS
adds no new defences and no new boundaries.

### §2.5 — Trust-stack picture: Lazarus / LavaLamp / PharOS

The Triad Deployments form a **closure** at the trust-stack
level, with each project occupying a distinct architectural
role:

```
                                role
                                ────────────────────────────
┌─────────────────────────────────┐
│ Lazarus                         │  Existing project; substance-
│  (substance under the hood,     │  under-hood backend; biblical
│   minimal/utilitarian UI)       │  raised-from-the-dead semantics.
├─────────────────────────────────┤
│ PharOS                          │  Forthcoming; OS-level
│  (consumer of LavaLamp's        │  identity layer; lighthouse
│   verifier API; OS-auth shim)   │  reference / persistent beacon.
├─────────────────────────────────┤
│ LavaLamp                        │  Prototype-stage at 0.0.34;
│  (device-bound identity         │  device-bound identity primitive;
│   primitive)                    │  visible-yet-substantive duality.
└─────────────────────────────────┘
       │                                    The closure: three
       │ ↑ LL-022 (OS-trust-stack)          posts whose mutual
       │ ↓ LL-023 (consumer-API surface)    coordination is the
       ▼                                    unit of identity-
   OS / firmware / hardware-root            security defence.
```

Each project has a distinct dependency relationship with the
other two:

- **LavaLamp ↔ PharOS:** PharOS depends on LavaLamp's verifier
  API (LL-023); LavaLamp's spec exposes this surface as a
  Boundary entry. PharOS's spec (when it exists) will state
  conformance to LL-023.
- **LavaLamp ↔ Lazarus:** Lazarus may consume LavaLamp's
  verifier surface for its own product-shaped identity
  guarantees; same LL-023 contract applies. Lazarus existed
  before LavaLamp was conceived; its consumption of LavaLamp
  is forthcoming-or-optional.
- **PharOS ↔ Lazarus:** No direct dependency. They are sibling
  consumers of LavaLamp; their coordination is via shared
  conformance to LL-023 + their separate threat models.

The "Watchmen" reframing (per the portfolio reference): the
collective is the unit of guard. No single watchman is
sufficient (single-point-of-failure problem — *who watches the
watchmen?*); three watchmen mutually committed to closure is
the answer. Each Triad Deployment is one of the watchmen; the
closure is the security claim.

### §2.6 — Lean / Haskell theorem-shape implications

The PharOS scoping pass introduces a complementary parametric
shape to LL-022's:

```lean
-- LL-022 shape (downward dependency, from 0.0.26 P-OS pass):
Theorem LL_NNN_under_LL022 :
  forall (env : RegisteredEnvelope)
         (os : OSAssumptions)
         (proof_os : LL022.satisfies os),
  LL_NNN_property env os

-- LL-023 shape (upward exposure, this pass):
Theorem consumer_inherits_LL_NNN :
  forall (env : RegisteredEnvelope)
         (consumer : LL023.Consumer)
         (proof_conformance : LL023.conforms consumer)
         (proof_LL_NNN : LL_NNN_property env consumer.os_assumptions),
  ConsumerInheritsProperty consumer LL_NNN_property
```

Read together: a consumer (PharOS) that conforms to LL-023's
API contract inherits LavaLamp's properties parametric in the
consumer's OS assumptions. The closure of LL-022 (downward)
+ LL-023 (upward) is what gives the Triad Deployments
collective security claim its formal grounding.

P5/P6 work to prove. This pass provides the theorem-shape
discipline; the actual proofs await Lean infrastructure
landing.

**Concrete impact on round-2 §1D.v Lean priorities.** The
priorities (linear-coupling worst-case bound, side-channel
timing indistinguishability, calibration ε-DP) are LavaLamp-
internal claims and don't directly touch LL-023. But every
priority's *deployment-time* statement (e.g., "PharOS
deployments inherit the worst-case bound") is parametric in
LL-023 conformance. The pattern: primitive-level theorems are
LL-023-independent; integration-level theorems are
LL-023-parametric. Same pattern as LL-022 in the 0.0.26
companion §2.6.

---

## §3 — Verification

### §3.1 — LL-023 status: :argued

**Verification status:** `:argued`.

**Evidence type:** `manual`.

The §2 design synthesis is the argument: §2.1 articulates
PharOS's role; §2.2 enumerates the consumer-API surface;
§2.3 maps the OS integration points; §2.4 articulates PharOS's
threat model; §2.5 closes the trust-stack picture; §2.6 pins
the Lean theorem-shape discipline.

The argument is *not* machine-checked. Promotion paths:

- **`:tested`** would require a deployment-spec test suite that
  loads a candidate consumer (PharOS or Lazarus) and verifies
  it conforms to the LL-023 surface. This is operational
  tooling that lands when the consumers themselves exist;
  forthcoming for PharOS.
- **`:proved`** would require Lean theorems following the §2.6
  shape. The theorems are *meta-theorems* about consumer
  inheritance from LavaLamp's primitive theorems; they cannot
  be machine-verified without first having Lean proofs of the
  inherited claims. P5/P6 work.

LL-023 will likely stay `:argued` until at least one consumer
(PharOS) lands operationally and exercises the surface in CI.
Same shape as LL-022 (which also stays `:argued` permanently
in the prototype's scope per the 0.0.26 companion §3.1).

### §3.2 — Why this isn't a status change for existing entries

LL-011 (registration ceremony), LL-013 (cross-config),
LL-014 (threshold calibration), LL-017 (verification
no-oracle), LL-022 (OS-trust-stack-dependency) all gain
*cross-references* to LL-023 — but no status change. The
verifier-side discipline articulated by those entries is
unchanged; LL-023 just makes the *consumer-side framing*
explicit.

This parallels the 0.0.26 P-OS pass: LL-011 / LL-012 / LL-015
/ LL-016 / LL-020 gained cross-references to LL-022 without
status changes.

---

## §4 — Spec impact

### §4.1 — New entry

**LL-023 — consumer-API-surface**

- *Logic tier*: Boundary (parallel to LL-009, LL-010, LL-015,
  LL-022).
- *Evidence type*: `manual`.
- *Status*: `:argued`.
- *Source*: this companion §2.

The entry articulates the consumer-API contract LavaLamp
exposes for downstream OS-deployment consumers. PharOS is the
canonical first instantiation; Lazarus and future embedded
SDK consumers also conform.

### §4.2 — Amendments to existing entries

- **LL-011** — append a "PharOS as canonical OS-deployment
  consumer (2026-05-04)" sub-bullet noting the consumer-side
  framing and pointing to LL-023.
- **LL-017** — append cross-reference to LL-023 for the
  consumer-side framing of the no-oracle protocol.
- **LL-022** — append cross-reference noting the LL-022 +
  LL-023 closure pair (downward + upward trust-stack
  scoping).

### §4.3 — Spec-status counts (post-pass, version 0.0.34)

- Total: 23 (was 22; +LL-023)
- `:proved`: 0
- `:tested`: 3 (LL-002, LL-004, LL-007 — unchanged)
- `:verified`: 0
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-021 — unchanged)
- `:argued`: 15 (was 14; +LL-023)
- `:open`: 1 (LL-015 — unchanged)

### §4.4 — Files changed

- `docs/pharos_scoping_companion.md` (this file) — new.
- `LAVALAMP_SPEC.md` — new entry LL-023; amendments to LL-011 /
  LL-017 / LL-022.
- `artifact_registry.md` — new row for LL-023; counts.
- `dashboard.md` — recent companion docs update; spec status
  counts updated; P-PharOS section added to priority stack.
- `changelog.md` — 0.0.34 entry.
- `README.md` — companion list + spec ledger + trajectory
  updated.

No source code changes; no test changes (design-only pass).

---

## §5 — Lessons captured

### §5.1 — The trust-stack scoping question has two ends

The 0.0.26 P-OS pass scoped the *downward* end (LL-022: what
LavaLamp depends on). This pass scopes the *upward* end
(LL-023: what consumers depend on LavaLamp for). Either
without the other leaves the trust-stack scoping incomplete —
LL-022 alone makes LavaLamp's OS dependencies explicit but
leaves the consumer-side implicit; LL-023 alone makes the
consumer-side explicit but leaves the OS dependencies fuzzy.

The pair is the asymmetry-trap defence at the trust-stack
boundary. Generalisable: any architectural boundary likely has
two ends; scoping passes should land in pairs unless one end
is structurally absent.

### §5.2 — Design-only passes compose with the same template

This is the third design-only pass in LavaLamp's history,
following P2 (architectural design pass, 0.0.5) and P-OS
(OS-level scoping, 0.0.26). All three follow the same shape:

- §1 computational basis (no code; inputs from existing spec
  and companion docs).
- §2 results (architectural synthesis, multiple subsections).
- §3 verification (manual evidence; status determined by
  CLAUDE.md §Evidence types).
- §4 spec impact (new entries; cross-references).
- §5 lessons.

The template composes without modification. Future design
passes (e.g., for Lazarus integration with LavaLamp, or for a
hypothetical embedded SDK) can drop into the same shape with
minimal session setup.

### §5.3 — Closure-of-three is the Triad Deployments unit

The Watchmen reframe + portfolio branding establishes that
**no single deployment is the unit of security**; the closure
of three (Lazarus / LavaLamp / PharOS) is. This pass
articulates the upward end of LavaLamp's contribution to that
closure (LL-023); LL-022 articulates the downward end. PharOS
lands as the canonical first consumer; Lazarus is structurally
already in place.

The closure-of-three pattern is corpus-honest — Aaron's
Possibilistic Security / triadic-coordination work is *about*
closures of three. The Triad Deployments name is structurally
faithful to that work, not a marketing veneer.

### §5.4 — PharOS's role is reference, not gate

The "lighthouse" semantics chosen for PharOS (over the
"watchman" alternative) reflects an honest framing: PharOS's
role is **reference-providing**, not active gate-keeping. The
gate-keeping happens *inside* LavaLamp (residue audit,
detection bound, chaos-guard). PharOS just translates "is the
device genuine?" into a Bool the OS can act on.

Naming a project "Watchman" would have over-claimed PharOS's
role. The lighthouse / Pharos metaphor is honest about where
the work actually happens. Captured as discipline note for
future portfolio naming: *match the project's name to its
honest functional role; reject names that overclaim*.
