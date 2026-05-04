# OS-Level Identity-Security Scoping Pass — LavaLamp (P-OS Companion)

Version: 0.0.26 (P-OS scoping pass, 2026-05-03)

Permanent record of the OS-level identity-security scoping pass.
Closes the one architectural seam the project has gestured at
repeatedly without ever consolidating: the **LavaLamp ↔ OS trust
boundary**. Currently OS-level concerns are scattered across LL-011
(TPM in registration), LL-012 (cold-start window — vague footnote
about Secure Boot being "out of scope"), LL-015 (A3 kernel-level
out of scope), LL-016 (TPM-signed sensor reads), and LL-020
(TPM-sealed calibration). What is missing is a single canonical
artefact answering: *what does LavaLamp require from the OS for
its claims to hold, what does it merely recommend, and what's
explicitly out of scope?*

This companion is design work, not implementation. The evidence
type produced is `manual`; spec entry LL-022 (added by this pass)
lands at `:argued` per the CLAUDE.md evidence-taxonomy rule. No
Julia / Lean / Haskell / C code is touched. Real TPM / Secure
Enclave attestation flow and IMA / kernel-lockdown integration are
deferred to P7 hardening.

This pass is **independent of the closure_forces_structure physics
paper update**. It does not surface content that would inform
LL-021 worst-case bounds or the C-conjugate-inheritance argument,
so it can land in parallel with the round-3 trigger gate.

---

## §1 — Computational basis

No code. Pure design synthesis from existing artefacts plus formal
restatement of the trust-stack scoping question.

**Inputs.**

- `LAVALAMP_SPEC.md` v0.0.25 — 21 spec entries; the entries that
  reference OS mechanisms (LL-011, LL-012, LL-015, LL-016, LL-020)
  read directly.
- `docs/attack_surface_enumeration.md` §2 — adversary taxonomy
  (A1..A6, A3 out of scope) is the prior framing for the boundary
  this pass formalises.
- `docs/architecture_design_companion.md` §2.4, §2.5.1, §2.5.2 —
  prior TPM / Secure-Enclave references and the cold-start
  out-of-scope footnote.
- `docs/p_r2b_calibration_confidentiality_companion.md` §2 —
  three-strategy design space for LL-020, of which Strategy 1
  (TPM-sealed) is OS-plumbing-coupled.
- `docs/synthesis_team_round2_companion.md` §1C-A2 — V-012
  registration-channel observation surfaced the calibration-
  confidentiality gap that LL-020 + LL-022 together close.
- `dashboard.md` §Live discipline notes — *asymmetry-trap watch*.
  The trust stack is the load-bearing place where "claim shrinks
  under reading" is most likely to bite: a reader projects an
  unconditional security guarantee onto a system whose claims
  hold only under stated OS assumptions. Articulating those
  assumptions positively (LL-022) and negatively (LL-015) is the
  asymmetry-trap defence.

**No build commands** for this companion. The design pass is prose
+ formal restatements; verification is `manual` per CLAUDE.md
§Evidence types.

---

## §2 — Results

### §2.1 — Trust stack and the LavaLamp boundary

The LavaLamp identity primitive sits at the top of a trust stack
descending through OS userspace, kernel, bootloader, firmware, and
hardware root of trust. Each layer has a distinct relationship to
LavaLamp's claims:

```
                                  in scope          out of scope
                                  (LavaLamp owns)   (LL-015 / LL-022)
┌─────────────────────────────────┐
│ LavaLamp security primitive     │      ●
│  (Engine, Sensors, Audit,       │
│   ChaosGuard)                   │
├─────────────────────────────────┤
│ OS userspace                    │      depends on (sensor APIs,
│  (libc, syscalls, /dev/urandom) │      getrandom, sysfs reads)
├─────────────────────────────────┤
│ Kernel                          │                       ●  (LL-015 A3)
│  (drivers, scheduler, sysfs)    │
├─────────────────────────────────┤
│ Bootloader / measured boot      │      depends on for cold-start
│                                 │      authentication beyond
│                                 │      WARMUP (LL-012, LL-022)
├─────────────────────────────────┤
│ Firmware / UEFI / Secure Boot   │      recommended (defense-in-
│                                 │      depth)
├─────────────────────────────────┤
│ TPM / Secure Enclave            │      required for LL-011 B+D,
│  (hardware root of trust)       │      LL-016 strategy 1, LL-020
│                                 │      strategy 1 (LL-022)
└─────────────────────────────────┘
```

Three categories partition the stack:

1. **In scope (LavaLamp owns).** The security primitive itself —
   the SDE engine, sensor coupling, residue audit, chaos-guard.
   Claims about these layers are LavaLamp's own.
2. **Depended-upon (upward dependency).** Layers LavaLamp needs
   to function but does not implement. The strength of LavaLamp's
   claims depends on these layers behaving correctly. **LL-022**
   pins exactly which mechanisms in this category are *required*
   versus *recommended*.
3. **Explicitly out of scope (downward boundary).** The kernel
   layer is *trusted* by assumption — A3-class adversaries are
   not defended against. **LL-015** is the honest scoping
   declaration that this assumption is load-bearing.

LL-022 (positive) and LL-015 (negative) together close the
trust-stack scoping question. Either alone is incomplete: LL-015
without LL-022 leaves the upward dependencies implicit; LL-022
without LL-015 leaves the kernel-trust assumption fuzzy.

### §2.2 — Required OS mechanisms

The following are *required* for LavaLamp's existing spec claims
to hold. A deployment lacking any of these falls outside the
spec's evidenced regime and the corresponding LL claim is
suspended for that deployment.

#### §2.2.1 — Hardware root of trust (TPM / Secure Enclave)

**Required by:** LL-011 (registration ceremony, default protocol
B + D); LL-016 strategy 1 (sensor authenticity via TPM-signed
reads); LL-020 strategy 1 (TPM-sealed calibration storage).

**What LavaLamp needs from the OS.** A TPM 2.0 / Secure Enclave /
TrustZone API exposing:

- *Attestation primitives*: produce a quote / signed measurement
  over a nonce + a platform PCR set. Defends LL-011 against
  registration-substitution attacks (A5).
- *Sealing primitives*: encrypt-to-platform with PCR-binding so
  the ciphertext is decryptable only by the same boot-state
  machine. Defends LL-020 against registration-channel observers
  (V-012).
- *Identity-key primitives*: device-bound asymmetric keypair with
  the private half non-extractable. Defends LL-011's
  device-derived secret-mixing (D variant).

**If absent.** LL-011 falls back to multi-party registration (A
threshold scheme) without hardware root; LL-016 falls back to
strategy 2 (multi-sensor cross-validation); LL-020 falls back to
strategy 2 (ε-DP perturbation) or strategy 3 (Shamir threshold).
Each fallback weakens the corresponding claim relative to its
TPM-rooted form, with the weakening documented per-strategy in the
respective companion docs.

#### §2.2.2 — OS sensor APIs at LL-005-compliant bandwidths

**Required by:** LL-004 (continuous sensor coupling), LL-005
(sensor Nyquist condition).

**What LavaLamp needs from the OS.** Read access to the hardware
sensors LL-004 enumerates (battery state, AC adapter status, USB
peripheral status, CPU thermal, scheduler timing) at sample rates
satisfying LL-005's `f_sensor > bandwidth` per-sensor condition.
Concrete OS surfaces vary by platform: Linux `/sys/class/power_supply`,
`/proc/stat`, `/sys/class/hwmon`; macOS IOKit / SMC; Windows
WMI / Performance Counters. The prototype's `Sensors.jl` currently
uses synthetic streams; real-sensor FFI is a P3-followup or P7
hardening item.

**If absent.** Specific sensor channels are removed from the
`CouplingParams` configuration. The security primitive degrades
gracefully — fewer channels means lower per-direction coupling
vector dimensionality, which by LL-021's analysis tightens the
worst-case adversary bound on the remaining channels. A deployment
with no usable sensor channels reduces to an unforced SDE; the
chaos-production rate h_KS is preserved (it is the SDE's own
property), but configuration-binding (LL-013 cross-config
transition handling) loses its substrate. LL-001's "function of
(machine, configuration, time)" framing weakens to "function of
(machine, time)".

#### §2.2.3 — Host TRNG (`/dev/urandom`, `getrandom`, RDRAND)

**Required by:** LL-007 chaos-guard (reseed flow uses
TRNG-derived unit-vector × magnitude perturbation).

**What LavaLamp needs from the OS.** A non-blocking, kernel-
backed entropy source meeting the standards documented in NIST
SP 800-90B (or platform-equivalent). Linux `getrandom(2)` with
`GRND_NONBLOCK`; macOS `SecRandomCopyBytes`; Windows
`BCryptGenRandom`. The chaos-guard reseed is the only place in
the prototype that consumes TRNG output; it does not need
information-theoretic guarantees, only cryptographic-grade
unpredictability sufficient that an A4 observer cannot predict
the reseed direction in advance.

**If absent.** No safe fallback. The chaos-guard cannot reseed
deterministically without exposing a sensor-correlated reseed
oracle (V-011) — that is exactly the side-channel LL-019 is
defending against. A deployment without a host TRNG must instead
disable the chaos-guard and accept that drifted-into-fixed-point
trajectories will cause permanent INVALID state until manual
re-initialisation, which is operationally unacceptable. **The
host TRNG is the only LL-022 requirement with no graceful
fallback.**

#### §2.2.4 — User/kernel process isolation

**Required by:** LL-018 (per-class A1..A6 quantification — the
A2 margin assumes an A2-class adversary is bounded by user-space-
observable resolution, not kernel-level capability).

**What LavaLamp needs from the OS.** Standard process isolation
between user-space processes — virtual memory separation, syscall
boundary enforcement, no shared memory by default, scheduler
quantum bounded. This is implicit in any modern OS (Linux,
macOS, Windows, BSD; not bare-metal embedded firmware), but
LavaLamp's A2 vs A3 separation depends on it being held. Without
it, the entire A2 / A3 distinction collapses: an "unprivileged"
adversary on a single-mode system is effectively kernel-level.

**If absent.** A2-class adversary is upgraded to A3-class for the
deployment in question. LL-015 then applies (A3 out of scope) —
LavaLamp does not claim defense. Single-mode embedded firmware
deployments fall in this category and should not be treated as
within LavaLamp's evidenced scope.

### §2.3 — Recommended OS mechanisms (defense-in-depth)

The following mechanisms are *recommended* — not load-bearing for
LavaLamp's formal claims, but they raise the practical bar against
multiple attack classes. A deployment lacking these does not lose
spec coverage but operates with a smaller margin against
sophisticated adversaries.

#### §2.3.1 — Secure Boot / measured boot / cold-boot RAM hardening

**Recommended for:** LL-012 cold-start window.

LL-012's WARMUP-state authentication is the *only* line of
defence during cold start without measured boot — the device
distinguishes WARMUP from OPERATIONAL via the chaos-guard's λ̂₁
trace, signed by device identity key. Measured boot adds a
second, parallel chain-of-custody: the boot path itself is
attested to a known-good measurement before the SDE engine
starts, so cold-start authentication composes (the WARMUP signal
is signed *and* the boot platform is attested) rather than
relies on a single line.

The 0.0.5 architecture-design companion's footnote ("Early-boot
integrity… is OS-level concern explicitly out of scope") is hereby
revised: it remains *out of LavaLamp's implementation scope*
(LavaLamp does not provide measured boot), but it is *not out of
the trust-stack scoping conversation*. Measured boot's role is
articulated here as a recommended, not required, dependency.

#### §2.3.2 — IMA / kernel-lockdown / mandatory access control

**Recommended for:** raises the cost of A3 without claiming
defence.

A3 (kernel-level) adversaries are out of scope per LL-015 — at
that capability level, identity is irrelevant because the
attacker can simulate any trajectory directly. But A3 is not a
binary capability in practice; it has a *cost*. IMA (Integrity
Measurement Architecture), kernel-lockdown mode, SELinux /
AppArmor mandatory access control, and similar mechanisms raise
the cost of attaining A3-class capability from "any user-mode
exploit chain" to "kernel exploit chain plus integrity-
measurement bypass". Deployments where the A3 attack cost is
operationally relevant should adopt these mechanisms.

This is *not* a defence claim. LL-015 stays `:open` and is
unchanged. LL-022 articulates IMA / kernel-lockdown as a
deployment recommendation, not a load-bearing dependency.

#### §2.3.3 — eBPF-based sensor authentication

**Recommended for:** LL-016 strategy 1.5, between hardware
attestation (strategy 1) and software cross-validation
(strategy 2).

A deployment lacking TPM hardware attestation but running on a
Linux kernel with eBPF can implement an OS-level sensor-read
authentication path that is harder to spoof from user-space than
plain syscall-trace cross-validation. Concretely: an eBPF program
attached to the relevant sensor read syscalls can sample the
kernel-side path *with kernel privilege* and cross-validate
against the user-space `Sensors.jl` reads. An A2-class adversary
cannot install eBPF programs, so a divergence between the eBPF
trace and the user-space read flags V-006-class manipulation.
This is weaker than TPM-signed reads (an A3 adversary defeats
both eBPF and the application) but stronger than pure
software cross-validation.

LL-016 strategy 1.5 is added to the strategy taxonomy in the
LL-022 cross-reference (see §2.5). Implementation is P7
hardening, not P3 prototype.

### §2.4 — Out-of-scope OS-level concerns

This section articulates the LL-015 boundary against the trust
stack. **LavaLamp does not:**

- Implement OS hardening of any kind. Secure Boot, IMA, kernel-
  lockdown, MAC, kernel-level sandboxing — none of these are
  LavaLamp's responsibility, even when LavaLamp recommends them.
- Provide kernel-level defences. There is no LavaLamp kernel
  module, driver, or syscall. LavaLamp runs entirely in
  user-space.
- Detect or mitigate A3-class adversaries. A kernel-mode
  attacker can simulate the SDE trajectory directly, evade
  the residue audit, and replay registered envelopes — at this
  capability level, identity is meaningless. LL-015 is the
  honest scoping declaration.
- Defend the boot path. Even with measured boot recommended in
  §2.3.1, LavaLamp does not implement, verify, or attest the
  boot measurement chain. That is the OS / firmware vendor's
  responsibility.
- Manage hardware lifecycle. TPM provisioning, key rotation,
  firmware updates, secure-element manufacturing supply chain
  — out of scope. LavaLamp consumes a TPM that is already
  provisioned and trusted by the platform; chain-of-trust
  inheritance to the platform's hardware vendor is implicit.

**LavaLamp does:**

- Articulate which OS mechanisms it depends on, distinguished by
  required vs recommended (§2.2 / §2.3).
- Document graceful-fallback behaviour where applicable (§2.2.1,
  §2.2.2) and the one no-fallback case (§2.2.3, host TRNG).
- State the A3 boundary positively (LL-022's required-mechanism
  list scopes the upward dependency; LL-015 scopes the downward
  boundary; together they close the trust-stack scoping
  question).

The kernel layer is *trusted* in LavaLamp's threat model **by
assumption**. LL-015 is the load-bearing declaration that this
assumption is load-bearing. LL-022 is the load-bearing
declaration that the upward dependencies (TPM, sensor APIs, host
TRNG, process isolation) are load-bearing.

### §2.5 — Per-existing-entry OS-dependency mapping

Five existing entries gain explicit cross-references to LL-022:

#### LL-011 (registration ceremony)

The default protocol B+D (TPM/Secure-Enclave attestation +
device-derived secret mixing) is *required* per §2.2.1; the
fallback to multi-party registration (A) is the no-TPM path. The
amendment adds an OS-dependency sub-bullet to LL-011 citing
LL-022.

#### LL-012 (cold-start window)

The original §0.0.5 footnote read: *"Early-boot integrity (Secure
Boot, measured boot, cold-boot RAM) is OS-level concern explicitly
out of scope."* This is partly correct (out of *implementation*
scope) and partly misleading (it suggests these mechanisms are
not part of LavaLamp's design conversation, which they are — as
*recommended* dependencies per §2.3.1). The amendment replaces
this footnote with a cross-reference to LL-022's recommended-list
position and to LL-015's broader OS-level boundary.

#### LL-015 (A3 out of scope)

LL-015 is the downward boundary; LL-022 is the upward boundary.
The amendment adds a cross-reference noting that the two together
close the OS-stack scoping question and that LL-015 stays `:open`
(it is a non-defence declaration), while LL-022 is `:argued` (it
is a positive dependency claim).

#### LL-016 (sensor authenticity)

Strategy 1 (TPM-signed reads) is OS-plumbing-coupled and depends
on §2.2.1. The amendment annotates strategy 1 with "depends on
LL-022 §2.2.1" and adds strategy 1.5 (eBPF-based authentication
on Linux) per §2.3.3 to the strategy taxonomy.

#### LL-020 (calibration confidentiality)

Strategy 1 (TPM-sealed storage) is OS-plumbing-coupled and depends
on §2.2.1. The amendment annotates strategy 1 with "depends on
LL-022 §2.2.1". Strategies 2 (ε-DP perturbation) and 3 (Shamir
threshold) are not OS-plumbing-coupled — they are
cryptographic-library-coupled — so they need no LL-022
annotation.

### §2.6 — Lean / Haskell theorem-shape implications

The OS-trust-stack dependency is **parametric** in any future
formal proof of LavaLamp's security claims. Theorems must be
stated *given* the LL-022 OS assumptions, not unconditionally.

**Pinned theorem-statement shape (P5/P6 discipline).**

For each spec claim that depends on an LL-022 mechanism, the
formal theorem statement should be:

```
Theorem LL_<NNN>_under_LL022 :
  forall (env : RegisteredEnvelope)
         (os : OSAssumptions)
         (proof_os : LL022.satisfies os),
  LL_<NNN>_property env os
```

where `LL022.satisfies` is a Lean / Haskell predicate enumerating
the §2.2 required mechanisms (TPM availability, OS sensor API
availability, host TRNG availability, user/kernel isolation). The
theorem holds *only* for OS configurations satisfying the
predicate; it makes no claim about configurations that don't.

This discipline prevents the asymmetry-trap failure where a
reader projects an unconditional bound onto a system whose proof
assumes a specific OS configuration. The trust-stack scoping is
explicit in the theorem statement, not implicit in surrounding
text.

**Concrete impact on round-2 §1D.v Lean priorities.**

- *Priority 1* (linear-coupling worst-case bound, LL-021): no LL-022
  dependency at theorem level. The bound is on the SDE +
  coupling math, independent of OS.
- *Priority 2* (side-channel timing indistinguishability, LL-019):
  no direct LL-022 dependency; depends on user/kernel scheduling
  guarantees (LL-022 §2.2.4) only inasmuch as the constant-time
  primitive is observable to user-space adversaries.
- *Priority 3* (calibration ε-DP, LL-020): the ε-DP theorem
  itself is OS-independent (it's a cryptographic property of the
  Gaussian mechanism), but if Strategy 1 (TPM-sealed) is the
  deployment's chosen strategy, the *integration* theorem
  needs LL-022 §2.2.1.

The pattern: the *primitive-level* theorems are OS-independent
(SDE math, cryptographic mechanisms); the *integration-level*
theorems (LL-001 substrate-bound identity, LL-011 registration
ceremony, LL-016 sensor authenticity, LL-020 strategy-1
deployment) are OS-parametric. P5/P6 work should distinguish the
two levels in the theorem catalogue.

---

## §3 — Verification

For LL-022 (added by this pass):

**Verification status:** `:argued`. **Evidence type:** `manual`.

The argument is the §2 design synthesis: §2.2 enumerates the
required mechanisms with rationale; §2.3 enumerates the
recommended mechanisms with cost-benefit framing; §2.4
articulates the boundary; §2.5 wires the new entry into the
existing entries; §2.6 pins the formal-proof discipline.

The argument is *not* machine-checked. Promotion paths:

- **`:tested`** would require a deployment-spec test suite that
  loads the CouplingParams from a candidate OS environment,
  checks each §2.2 required mechanism is present (TPM API
  reachable, sensor API reachable, host TRNG reachable, process
  isolation in force), and emits a clean verdict. This is
  operational tooling rather than the kind of test that closes
  spec entries; defer to P7 unless a concrete deployment
  motivates it earlier.
- **`:proved`** would require Lean theorems following the §2.6
  shape. The theorems are *meta-theorems* about other LL claims,
  not primitive theorems; they cannot be machine-verified
  without first having Lean proofs of the LL claims they
  parameterise (LL-006, LL-008, LL-018, LL-019, LL-021).

LL-022 stays `:argued` permanently in the prototype's scope.

---

## §4 — Spec impact

### New entry

**LL-022 — OS-trust-stack-dependency**

- *Logic tier*: Boundary (parallel to LL-009, LL-010, LL-015).
- *Evidence type*: `manual`.
- *Status*: `:argued`.
- *Source*: this companion §2.

LL-023 (early-boot-integrity-inherited) was considered as a
separate entry per the plan's optional-second-entry decision
point. **Decision: fold into LL-022 §2.3.1** (recommended-list
position). Rationale: early-boot integrity is *not load-bearing-
distinct* from the OS-trust-stack umbrella — it is one
mechanism in the recommended-list family and gains no clarity
from a separate entry. Keeping the trust-stack scoping in a
single entry mirrors how LL-015 covers all A3-class concerns in
a single entry rather than splintering into per-mechanism
claims.

### Amendments to existing entries

- **LL-011** — append OS-dependency sub-bullet citing LL-022.
- **LL-012** — replace the "Early-boot integrity… out of scope"
  footnote with a cross-reference to LL-022 §2.3.1 and LL-015.
- **LL-015** — append cross-reference to LL-022 noting the two
  together close the OS-stack scoping question.
- **LL-016** — annotate strategy 1 with "depends on LL-022
  §2.2.1"; add strategy 1.5 (eBPF) per §2.3.3.
- **LL-020** — annotate strategy 1 (TPM-sealed) with "depends
  on LL-022 §2.2.1".

### Spec-status counts (post-pass, version 0.0.26)

- Total: 22 (was 21)
- `:proved`: 0
- `:tested`: 2 (unchanged: LL-004, LL-007)
- `:verified`: 0
- `:benchmarked`: 4 (unchanged: LL-003, LL-006, LL-019, LL-021)
- `:argued`: 15 (was 14; adds LL-022)
- `:open`: 1 (unchanged: LL-015)

### Registry impact

New row for LL-022 in `artifact_registry.md`:

| LL-ID | Key | Logic tier | Evidence type | Test/Proof file | Source file | Status |
|---|---|---|---|---|---|---|
| LL-022 | OS-trust-stack-dependency | Boundary | manual | docs/os_identity_security_scoping_companion.md §2 | — | :argued |

---

## §5 — Lessons

1. **Scattered OS-level dependencies cluster into one entry.**
   Five existing entries each gestured at TPM / Secure-Enclave /
   sensor-API / host-TRNG dependencies without ever
   consolidating them. A reader scanning any one entry could
   miss that the same OS-trust-stack assumption was load-bearing
   across the spec. LL-022 is the consolidation; the cost is one
   new entry plus five small in-place amendments. Generalisable
   discipline: *any architectural assumption shared across ≥3
   spec entries warrants its own entry.*
2. **Scoping artefacts are cheap and prevent claim drift.** The
   asymmetry-trap watch in `dashboard.md` flagged this exact
   failure mode: "claim shrinks under reading." LL-022's cost
   (one design-pass session, no code) is small relative to the
   risk it mitigates (a reader projecting an unconditional bound
   onto a system whose claims are OS-parametric).
3. **Required vs recommended distinction is load-bearing.**
   §2.2 lists four required mechanisms (TPM, sensor APIs, host
   TRNG, user/kernel isolation); §2.3 lists three recommended
   (Secure Boot, IMA / kernel-lockdown, eBPF). Conflating the
   two would either weaken the spec (treating all dependencies
   as "nice to have") or overscope it (treating all as
   load-bearing). The required/recommended split mirrors
   the §2.4 in-scope/out-of-scope split — both are
   asymmetry-trap defences.
4. **Boundary entries close pairs, not singletons.** LL-015
   (downward, A3 OOS) was incomplete without LL-022 (upward,
   trust-stack); LL-022 is incomplete without LL-015. Future
   boundary work should look for the matching pair: every
   "X is out of scope" likely has a hidden "Y is depended on"
   somewhere in the spec.
5. **The host TRNG is the only no-fallback dependency.** Three
   of the four required mechanisms have graceful-degradation
   fallbacks (TPM → multi-party registration; sensor APIs →
   reduced channel set; user/kernel isolation → A2 collapses
   to A3 and LL-015 applies). The host TRNG (§2.2.3) does not
   — without it, the chaos-guard's reseed flow exposes a
   sensor-correlated oracle that LL-019 cannot mitigate. This
   is worth flagging operationally: an embedded deployment
   targeting LavaLamp must verify host TRNG availability
   *before* anything else, and treat its absence as a
   deployment blocker rather than a degraded mode.
