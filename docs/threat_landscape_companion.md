# Threat-Landscape Companion — The Context In Which the Triad Deployments Matter

Version: 0.0.42 (threat-landscape framing companion;
cockroach/catapult/castle metaphor + metabolic-value /
predator-prey ecology axis; pre-round-3, 2026-05-05)

Permanent record of the meta-architectural threat-landscape
pass — the framing that grounds why Lazarus / LavaLamp /
PharOS exist as the **Triad Deployments — Digital Identity
Resilience**. Surfaced 2026-05-05 in conversation: *"lavalamp
is important but we need to frame the context IN WHICH it is
important."* Same observation prompted the round-3 brief Q7 +
A7 EMF / A7 / LL-025 questions (0.0.40).

This companion is **meta-architectural**: it frames the
landscape that the existing LL-IDs collectively occupy
without creating new spec entries. Round-3 may surface new
LL-IDs (LL-025+) addressing specific gaps; this companion
articulates the gaps but does not pre-commit to their
resolution.

**Net result.** A shared vocabulary for the threat tiers the
Triad Deployments address (and don't), grounded in Aaron's
cockroach/catapult/castle metaphor — corpus-honest in the
sense that it directly mirrors Possibilistic Security's
autopoietic-closure / immune-system / membrane structure
rather than borrowing a marketing taxonomy from elsewhere.

---

## §1 — Computational basis

### §1.1 — Inputs

- `LAVALAMP_SPEC.md` v0.0.40 — 24 spec entries; the entries
  that touch threat-modeling (LL-008 resolution-bounded
  security; LL-015 A3 OOS; LL-018 per-class A1-A6
  quantification; LL-022 OS-trust-stack; LL-023 consumer-
  API-surface; LL-024 real-sensor-deployment-strategy)
  read directly.
- `docs/attack_surface_enumeration.md` — six adversary
  classes (A1-A6) + ten attack vectors (V-001..V-010); the
  prior threat-modeling foundation the Triad Deployments
  built on.
- `docs/synthesis_team_round2_companion.md` §1C — round-2
  attack vector additions (V-011/012/013).
- `docs/os_identity_security_scoping_companion.md` §2.1
  trust-stack diagram — the LL-022/023/024 deployment-stack
  triple.
- `docs/synthesis_team_round3_brief.md` §3 Q7 + §4 A7 — the
  EMF / A7 / LL-025 candidate framing.
- `~/.claude/projects/.../memory/feedback_cordon_sanitaire.md`
  — Aaron's regime-awareness discipline: *"under ruin-class
  risk, structural disconnection with regulated membrane;
  resist taxonomy-greed; Taleb asymmetry."*
- `~/.claude/projects/.../memory/reference_triad_deployments.md`
  — portfolio branding + closure-of-three formal grounding.
- Aaron's 2026-05-05 conversation: the
  cockroach/catapult/castle/immune-system metaphor itself.
  This is the load-bearing frame for the document.

### §1.2 — No code; pure conceptual mapping

This pass produces no code, no tests, no benchmarks. The
evidence type is `manual` at the meta-architectural level;
it does not introduce a new LL-ID directly. Round-3 reviewers
may surface new LL-IDs based on the gaps articulated here;
those land in subsequent commits.

---

## §2 — The threat-landscape taxonomy

### §2.1 — The metaphor: cockroaches, catapults, castles, and the immune system

Aaron 2026-05-05:

> The best hackers are cockroaches and catapults (sometimes
> both)... cockroaches are small, persistent, hard to see and
> kill, you'll never kill all of them... catapults break down
> the barriers set up to protect. Combined the two are lethal
> but rare. Catapults exist at a scale that is difficult for a
> cockroach to justify maintaining. Cockroaches exist at a
> scale that is difficult for a catapult to govern. Not
> impossible (maybe state level actor). Our best defense is
> the castle, the membrane, with immune system constantly
> watching, waiting, digesting, incorporating, denying,
> obfuscating, repairing, etc at multiple scales and
> resolutions. We are alive and have identity. It is
> impossible for the enemy to provide a persistent attack to
> beat us without dominating in scale or injecting a
> virus/cancer under our nose.

This is not a marketing metaphor. It is a *structurally
faithful description* of the corpus's defensive principle:

- **Corpus-faithful**: the immune-system framing maps directly
  onto the autopoietic-closure structure articulated in
  the closure_forces_structure paper's Q₅₁ / Q₁₀₂
  autopoietic-fixed-point results.
  The immune system's "watching, waiting, digesting,
  incorporating, denying, obfuscating, repairing" is *exactly*
  the activity-pattern of an autopoietic system maintaining
  itself against perturbation.
- **Identity-constitutive**: "we are alive and have identity"
  is corpus-deep. Identity is *not* a static credential — it
  is the ongoing pattern of the immune system's activity. This
  is precisely LavaLamp's substrate-bound identity claim
  (LL-001): identity = the sustained chaotic trajectory, *not*
  a stored value. The trajectory IS the immune-system
  signature.
- **Defeat conditions named explicitly**: the only ways to
  beat a living, identity-coherent system are (a) **scale
  domination** (overwhelming the immune response) or (b)
  **virus/cancer injection** ("under our nose" — corruption
  from within at a level the immune system cannot recognise).
  Both are state-actor-tier in practice.

The rest of this companion organises the threat landscape
along these three axes: cockroach-class, catapult-class, and
the castle/membrane/immune-system architecture that defends
against both.

### §2.2 — Cockroach-class threats (small-scale, persistent, opportunistic)

**Profile.** Many small actors; persistent presence over time;
adaptive but resource-limited per actor; survives by avoiding
detection rather than overwhelming defenses. Cannot afford
TEMPEST-grade equipment, multi-million-dollar zero-days, or
hardware-interdiction supply chains. Lives in the gaps,
seams, and operational-error spaces.

**Threat categories that cluster as cockroach-class:**

1. **Operational / human error.** Phishing (credential leak);
   misconfigured deployment; user clicks malicious link;
   weak passwords reused across services; lost device.
   The cockroach's favourite habitat — the soft tissue
   between systems.
2. **Composability seams.** LavaLamp ↔ PharOS ↔ OS-auth ↔
   MFA integration gaps. Each individual deployment is
   audited; the *interfaces between them* are where
   cockroaches squeeze through. NSA TAO's principle — *attack
   the seams* — applies at every scale.
3. **Long-term substrate drift.** Component aging;
   replacements (battery swap, RAM upgrade); slow-drift
   parameter changes that fall under the residue-audit
   threshold. The cockroach's patience advantage: drift
   victory over years rather than seconds.
4. **Active substrate manipulation (cockroach-tier).**
   Individual chip swap; locally-installed implant; physical
   keylogger. Requires brief physical access but no
   industrial supply chain.
5. **Slow-drift threshold gaming (V-005).** The V-005 attack
   from `attack_surface_enumeration.md` is a quintessential
   cockroach attack — opportunistic, patient, evades
   per-instance detection by staying below the residue-audit
   threshold.
6. **Standard malware ecosystem.** Commercial spyware,
   ransomware, credential stealers. Deployed at scale by
   operators who individually can't afford catapults.

**LavaLamp's defensive coverage against cockroaches:** *good*
at the primitive tier. The residue audit (LL-006) catches
slow-drift gaming via per-exponent vector-residue (rather
than scalar KL); the chaos-guard (LL-007) re-establishes
entropy regularly so cockroach-pattern adaptation can't
slowly converge to a falsifiable pattern; LL-019 side-channel
hardening closes the timing oracle that cockroaches would
otherwise exploit.

**LavaLamp's residual exposure to cockroaches:**
- Composability seams between LavaLamp and PharOS / OS-auth /
  MFA — partially addressed by LL-023 consumer-API surface,
  but the seams between LavaLamp's verifier API and PharOS's
  shim implementation are where round-3's A3 question
  (consumer non-conformance attack) surfaces.
- Operational error at the user/device-administrator level —
  out of scope by design. LavaLamp gives device identity, not
  user identity.

### §2.3 — Catapult-class threats (large-scale, resourced, barrier-breaking)

**Profile.** Few actors per threat; high resource cost; can
break specific defenses through sheer capability; rarely
maintains long-term presence at the same scale (catapults
are siege weapons — once the barrier breaks, the next move
is occupation, which has different costs). State-level actors
or extremely well-resourced criminal organisations.

**Threat categories that cluster as catapult-class:**

1. **Passive substrate observation (A7 / V-014 candidate).**
   TEMPEST-grade RF / acoustic / optical / power-line
   emanation interception. Requires close proximity +
   bespoke equipment + ground-truth-training-data. NSA TAO
   capability tier; rare lower.
2. **Active substrate manipulation (catapult-tier).** Supply
   chain interdiction (modified hardware before delivery);
   chip decapping; bus probing in a lab; rowhammer-assisted
   exploitation; cold-boot RAM extraction at scale. NSA TAO's
   ANT catalog territory.
3. **Cryptographic primitive failure.** TPM exploit at depth
   (rare but happens — TPMfail; ROCA; etc.); PQC primitive
   broken at scale; RNG compromised at the silicon layer.
   Requires either a research-grade discovery or a state-
   level capability already deployed.
4. **Quantum threat horizon (Q-Day).** Once a CRQC arrives,
   classical signature schemes break; LavaLamp's audit
   doesn't directly use signatures, but registration-ceremony
   hashes and envelope-storage encryption may. The ultimate
   catapult: breaks all classical castles simultaneously.
5. **Software supply chain compromise at scale.** Modified
   Julia / DiffEq / Mathlib dependencies; tampered build
   tools (xz-utils backdoor 2024 was a near-miss at this
   scale); compromised package signing infrastructure.
   Catapult-tier when state-actor; cockroach-tier otherwise.
6. **Cryptographic side-channel attacks at scale.** DPA-class
   attacks on power analysis; cache-timing attacks against
   AES; speculative-execution attacks against TPM. Requires
   either physical access + lab equipment (catapult) or
   shared-tenancy access (cockroach hybrid).

**LavaLamp's defensive coverage against catapults:** *partial
at the primitive tier; gaps articulated as boundary entries.*

The current spec articulates several catapult-class boundaries:
- LL-015 (A3 kernel-level adversary OOS) — declares
  catapult-tier kernel exploits out of scope.
- LL-018 (per-class A1-A6 quantification) — quantifies the
  margin per class but limits to A1-A6 (no A7).
- LL-022 (OS-trust-stack-dependency) — names required + recommended
  OS mechanisms; assumes they work.
- LL-024 (real-sensor-deployment-strategy) — articulates per-
  platform FFI strategy with TPM at P7 hardening tier.

**LavaLamp's residual exposure to catapults:**
- **A7 passive-emanation** is currently un-addressed; LL-025
  candidate per round-3 brief Q7.
- Quantum threat horizon is partially addressed (QKD/PQC
  complementarity companion §1) but not load-bearing in the
  spec.
- Software supply chain compromise is implicitly assumed not
  to happen; no spec entry articulates the assumption.

### §2.4 — State-level threats: catapult + cockroach combined (rare, lethal)

**Profile.** The intersection. Modern intelligence agencies
(NSA TAO, MSS, GRU, Mossad-equivalent units) and a small
number of well-resourced criminal organisations. Capable of
deploying catapults (zero-days, hardware interdiction,
TEMPEST capture) AND maintaining cockroach-tier persistent
presence (long-term implants, tradecraft, moles, recruited
insiders).

**The defining feature of this tier:** *the threat operates
at multiple scales and resolutions simultaneously*. A single
operation against a target can include:
- A catapult-tier supply-chain interdiction (hardware delivered
  with modified firmware) AND
- A cockroach-tier persistent implant (long-term low-traffic
  C2) AND
- Operator-tier social engineering (recruited insider) AND
- Cryptographic-tier exploitation (zero-day at OS or app
  layer) AND
- Passive-tier emanation capture (TEMPEST equipment in
  adjacent room).

Combined, the defender faces a *coordinated multi-axis attack*
that is impossible for a single defensive primitive to fully
counter. **This is the ruin-class-risk threat tier referenced
in `feedback_cordon_sanitaire.md`** — under this tier, the
correct response is *structural disconnection with regulated
membrane*, not just better defenses.

**LavaLamp's defensive coverage against state-level threats:**
*explicitly bounded.* LavaLamp does not claim to defeat a
state-level adversary. The corpus's framing — Possibilistic
Security as detection-postured rather than prevention-postured;
the C-conjugate adversary inheritance from the closure_forces_structure paper's
0/5202 cross-sector autopoiesis result — explicitly accepts
that against a structural-mimic attacker (one who *structurally
co-occurs* with the genuine system), detection is the load-
bearing claim, not prevention.

The Triad Deployments give the defender a *living, identity-
coherent immune system at the substrate level*. This makes
state-level attacks *expensive and detectable* — the attacker
must either dominate in scale (provably massive operation) or
inject a virus/cancer at a level the immune system cannot
recognise. Both raise the cost; neither is impossible.

### §2.5 — The castle/membrane/immune-system architecture

Aaron's defensive frame:

> Our best defense is the castle, the membrane, with immune
> system constantly watching, waiting, digesting,
> incorporating, denying, obfuscating, repairing, etc at
> multiple scales and resolutions. We are alive and have
> identity.

This is the *corpus-honest* framing of what the Triad
Deployments collectively are. Each component maps onto the
metaphor:

- **Castle** — the perimeter / boundary. In the Triad
  Deployments: the device's hardware itself + the OS process
  isolation + the cryptographic-perimeter (TPM-sealed
  envelope, encrypted storage). LL-022 articulates the castle
  walls' structural requirements.
- **Membrane** — regulated permeability. *What* passes in,
  *what* passes out, *with discrimination*. PharOS is the
  membrane checkpoint at the OS layer: it doesn't block
  everything; it filters via the LL-023 verifier API. The
  membrane is selectively open — that's the difference between
  it and a static barrier.
- **Immune system** — active processes at multiple scales:
  - **Watching**: the chaos-guard (LL-007) continuously
    estimates λ̂₁; the residue audit (LL-006) compares
    Lyapunov spectra against the registered envelope.
  - **Waiting**: the WARMUP / VALID state machine (LL-007 +
    LL-012); only declaring readiness when conditions are
    actually met.
  - **Digesting / incorporating**: TRNG-driven reseed flow
    (LL-007) — the system absorbs fresh entropy and
    incorporates it into ongoing dynamics. This is the
    autopoietic-incorporation principle from the closure_forces_structure paper
    operating at the SDE level.
  - **Denying**: per LL-017 no-oracle, the verification
    protocol denies threshold-probing surfaces.
  - **Obfuscating**: per LL-019 timing decorrelation,
    response-time distributions are statistically
    indistinguishable.
  - **Repairing**: chaos-guard reseed when λ̂₁ < τ_λ;
    re-registration (LL-011 variant C) on substrate change.
  - **Multiple scales and resolutions**: per-exponent vector
    residue test (LL-006); per-deployment N-scaling rule
    (LL-003); per-platform sensor strategy (LL-024).
- **Alive and identity** — the immune system *is* the
  identity. There is no static credential to steal; the
  trajectory itself, sustained by the ongoing dynamics, is
  what the verifier matches against. LL-001 articulates this
  as the substrate-bound-identity primitive.

**The defeat conditions named in the metaphor:**

1. **Domination in scale.** The attacker overwhelms the
   immune response with so many simultaneous attacks that the
   defender cannot respond to all of them. Defended against
   by ensuring the immune system operates at *multiple scales
   and resolutions* — single-axis attacks are absorbed; only
   multi-axis state-level operations have a chance.
2. **Virus/cancer injection ("under our nose").** Corruption
   from within at a level the immune system cannot recognise.
   This is the **C-conjugate adversary** problem — the attacker
   mimics the genuine system structurally, not just behaviourally.
   The corpus's 0/5202 cross-sector autopoiesis result says this
   is structurally-impossible *under the autopoietic closure
   condition*; LL-006's residue audit gives the empirical-tier
   defense by detecting the structural mismatch in the Lyapunov
   spectrum. The Q₅₁-tier-vs-Q₁₀₂-tier identity distinction
   in `qkd_pqc_complementarity_companion.md` §2.6 is the formal
   articulation.

The Triad Deployments are *the substrate-tier immune system*.
They don't claim to defeat all attackers; they claim to make
state-level attacks expensive AND detectable.

### §2.6 — Metabolic value and the predator-prey ecology

The cockroach/catapult/castle metaphor describes *how* the
defender works (active immune system, multi-scale, identity-
coherent). It doesn't yet describe *why most attackers don't
bother in the first place* — the **metabolic-value /
predator-prey ecology** axis.

Aaron 2026-05-05:

> The "metabolic value" of the target. If the defense is such
> that it is not worth the risk for the attacker (not enough
> value) they will go find something else. This is how we
> achieve symbiosis in the ecosystem. Lions and Gorillas...
> Hyenas and Lions... there are spats sure but they find their
> easy food to eat.

This is a different axis than scale (cockroach vs catapult)
or defense (castle/membrane/immune). It's the *attacker's
cost-benefit calculation*. Every adversary has finite
resources — time, money, attention, computational budget,
operational risk-of-getting-caught. They prioritize targets
by *expected value / expected cost*. They don't attack
targets where the math doesn't favor it.

**The defender doesn't need to be invincible.** The defender
needs to be either:
- **More expensive than nearby alternatives** (cost-asymmetry
  in the defender's favor), OR
- **Less valuable than nearby alternatives** (target-asymmetry
  in the defender's favor — be a less attractive prize).

Either positions the target outside the attacker's
cost-justified zone, and the attacker finds easier food
elsewhere.

**Examples from biological ecology:**

- **Lions vs Gorillas.** Spats happen; mostly mutual respect.
  Gorillas are too costly to attack for marginal protein
  return; lions are too dangerous to attack for marginal
  territorial advantage. Both are large-bodied, well-defended;
  predation cost > predation benefit. Equilibrium: peaceful
  coexistence.
- **Hyenas vs Lions.** Spats over kills. Each occasionally
  steals from the other, but full conflict is rare; the cost
  of escalation exceeds the value of the disputed kill.
  Each species hunts its own ranges; they share an ecology
  without merging into one.
- **Wolves vs Bears.** Boundary conflicts at scarce resources
  (winter kills; salmon runs); mutual avoidance otherwise.

The bacterial-immune-system parallel goes further:

- **Most non-self bacteria aren't attacked.** The gut
  microbiome is mostly mutualistic; the immune system
  *digests and incorporates* what's useful (Aaron's earlier
  metaphor — `watching, waiting, digesting, incorporating`).
  Adversarial response is reserved for pathogens that
  threaten the metabolic budget.
- **Symbiosis is the default; adversarial response is the
  exception.** The immune system *isn't* trying to kill
  everything outside the self-boundary. It's trying to
  maintain *metabolic balance* — incorporating what's
  useful, denying what's harmful, mostly leaving everything
  else alone.

This is corpus-deep. The closure-of-self is *not* defined by
killing all non-self; it's defined by maintaining the
*metabolic conditions* under which the system persists. An
identity-coherent system thrives in an ecology where most of
the "non-self" is symbiotic, not adversarial.

### §2.7 — Asymmetric cost as the security claim — symbiosis as equilibrium

The metabolic-value framing reframes what LavaLamp's security
claim *is*. The honest claim is **not** "we defeat all
attackers." It's:

> **Attacking *this* device costs more than the result is
> worth, relative to easier targets.**

This is *exactly* what LL-008 (resolution-bounded security
claim) says formally. The resolution-bound is fundamentally
about adversary measurement *cost* exceeding *value*: the
adversary's measurement resolution is bounded by their
budget; the device's chaos-production rate exceeds plausible
adversary resolution at typical adversary cost levels.

LL-008 already captures the cost-asymmetry implicitly. The
metabolic-value framing makes it *explicit* — and connects
it to the rest of the corpus:

- **Possibilistic Security** is about raising the cost of
  unsanctioned alternatives. Same shape: make the closure
  cheaper to honor than to break.
- **Cordon sanitaire under ruin-class risk** is structural
  cost-multiplication: the access cost is made prohibitive
  by structural disconnection rather than by stronger
  defense at the perimeter.
- **Asymmetry-trap watch** is the discipline of matching
  the *claim* to the *cost-asymmetry*. Don't claim
  invincibility; claim "expensive to defeat" with bounds.
- **Detection-postured rather than prevention-postured**
  (per `qkd_pqc_complementarity_companion.md`) — accept
  that some attacks are economically justified for state
  actors; ensure they are *expensive AND detectable*, not
  *impossible*.

**Translation across the threat tiers:**

| Threat tier | Cost-asymmetry strategy |
|---|---|
| Cockroach | Modest defense exceeds their tiny budget; they go elsewhere. Trivial to position outside their cost-justified zone. |
| Catapult | Some attacks ARE economically justified for state actors. Defender's job: be more expensive than the *cheapest catapult target*. Don't be the lowest-hanging fruit at this tier. |
| State-level (catapult + cockroach combined) | Structural disconnection (cordon sanitaire) is the answer — make access prohibitive. Or: don't be the highest-value target in the room. |
| Symbiotic / non-adversarial | Most actors live here. Mutualistic-or-neutral relationships; no defense needed beyond standard hygiene. |

Most of the ecosystem — by population — is in the symbiotic
tier. The Triad Deployments aren't trying to defend against
*everyone*; they're trying to defend against the small
fraction of actors who *do* attempt attack, and they only
need to defend at the cost level required to make those
specific actors find easier food.

**Symbiosis is the equilibrium goal, not victory.** The
defender's true job is to position the target so the
attacker's cost-benefit math says "go elsewhere," then to
*detect and respond* to the rare actors who attack anyway.
The autopoietic-closure principle expressed at the predator-
prey level: the closure isn't "kill all enemies"; it's
"maintain metabolic conditions under which most actors don't
bother and we detect the rare ones who do."

**Practical implications for the Triad Deployments:**

- **High-value targets need *more* defense.** The attacker's
  cost budget grows with target value. A LavaLamp-protected
  device holding low-stakes content can rely on modest
  defense; a device holding state secrets needs more.
- **Low-value targets need *less* defense.** Cockroach-tier
  budgets alone won't justify attacks on uninteresting
  targets. The Triad Deployments are sufficient for most
  consumer use without additional layering.
- **Defender attractiveness matters as much as defenses.**
  Operational discipline — *don't draw attention; don't be
  the most valuable target in the room* — compounds
  defensive value at zero marginal cost.
- **Defense-in-depth = cost amplification, not perimeter
  strengthening.** Adding layers raises the attacker's total
  cost, even if no single layer is invincible. This is why
  LL-022 + LL-023 + LL-024 + (potentially) LL-025 form a
  multi-layer commitment rather than a single load-bearing
  defense.

The honest framing for the Triad Deployments: they raise the
attacker's cost across multiple axes (substrate-binding,
sensor authenticity, threshold calibration, side-channel
hardening). Each axis individually is bounded; together they
shift the cost-benefit math toward "find easier food
elsewhere" for the vast majority of would-be attackers, and
toward "expensive AND detectable" for the rare state-level
actors.

---

## §3 — Where the Triad Deployments fit

The Triad Deployments form a closure-of-three at the
deployment-stack level, with each component occupying a
distinct architectural role within the
castle/membrane/immune-system architecture:

### §3.1 — LavaLamp: identity foundation

LavaLamp is the **substrate-level immune-system identity**.
The chaotic SDE trajectory is the ongoing pattern of immune-
system activity; the Lyapunov-spectrum residue audit is the
mechanism by which the system *knows itself* and *recognises
foreign*.

In the metaphor: LavaLamp is *what makes this castle yours*.
Without LavaLamp, the castle is generic; with LavaLamp, the
castle has identity that cannot be transferred to another
castle without the substrate also transferring.

Relevant LL entries: LL-001 (substrate-bound identity), LL-002
(visual-security decoupling), LL-003 (single-attractor
chaotic engine), LL-006 (residue audit), LL-007 (chaos-guard),
LL-008 (resolution-bounded security claim), LL-018 (per-class
adversary quantification), LL-019 (side-channel hardening),
LL-021 (worst-case adversary bound).

### §3.2 — PharOS: membrane checkpoint at the OS layer

PharOS is the **OS-layer authentication membrane** — the
checkpoint that filters identity claims into and out of the
device's authentication subsystems. PharOS exposes LavaLamp's
verifier API (LL-023) to the OS authentication infrastructure
(PAM on Linux, Authorization Plug-in on macOS, Credential
Provider on Windows), translating the verifier's accept/reject
into platform-native authentication results.

In the metaphor: PharOS is the membrane gate. It doesn't block
everything (the castle has to be useful); it filters
selectively (the membrane is permeable to legitimate identity
claims and impermeable to spoofed ones).

Relevant LL entries: LL-011 (registration ceremony), LL-012
(cold-start window), LL-013 (cross-config transitions),
LL-014 (threshold calibration), LL-017 (verification no-oracle),
LL-023 (consumer-API-surface).

### §3.3 — Lazarus: backend / inner sanctum

Lazarus is the **substantive backend** — the inner sanctum
where the work actually happens. The biblical-resurrection
naming reflects the substance-under-the-hood / minimal-UI
duality: what the user sees is utilitarian; what does the
work is alive and persistent.

In the metaphor: Lazarus is the keep at the centre of the
castle. The membrane (PharOS) checks identity at the gate;
the keep (Lazarus) is where the high-value work happens with
the assurance that the membrane is doing its job.

(Lazarus has its own spec / repository; not currently
documented in detail in LavaLamp's spec. Future cross-Triad
work may articulate Lazarus's specific role in the immune-
system architecture.)

### §3.4 — The deployment-stack triple

LL-022 (downward — what LavaLamp depends on from the OS) +
LL-023 (upward — what consumers depend on LavaLamp for) +
LL-024 (operational — real-sensor instantiation strategy)
form the **deployment-stack triple**: a closure-of-three at
the spec level that articulates the *operational
preconditions* for the immune-system architecture to work.

In the metaphor: the deployment-stack triple specifies the
*environmental assumptions* under which the castle's immune
system functions. If those assumptions fail, the immune
system can't do its job — the castle is still standing but
the alarm doesn't ring.

---

## §4 — What the Triad Deployments DO and DON'T address

### §4.1 — Within scope

The Triad Deployments collectively address (at the primitive
tier):

| Threat class | Coverage | LL entries |
|---|---|---|
| A1 remote software | Strong | LL-006, LL-007, LL-018 |
| A2 unprivileged user-space | Strong | LL-006, LL-018 |
| A3 kernel-level | OOS by declaration | LL-015 |
| A4 software side-channel | Partial (timing yes; sensor-manipulation partial via cross-validation) | LL-016, LL-019 |
| A5 registration-time insider | Partial (TPM defends substitution; Strategy 2 ε-DP defends observation) | LL-011, LL-020 |
| A6 time-localized observer | Partial (single-window observation bounded; cold-start protocol) | LL-012, LL-018 |

Most of the strong-coverage cases are cockroach-class threats.
The catapult-class threats partially covered (A4/A5) require
deployment-tier mitigations layered on the spec's primitive-
tier defenses.

### §4.2 — Out of scope at the primitive tier

The threat classes that the Triad Deployments do **not**
directly defend against at the primitive tier:

| Threat class | Why OOS | Defensive layer |
|---|---|---|
| **A7 passive-emanation** (catapult) | Substrate radiates regardless of software discipline | Hardware shielding (Faraday / TEMPEST); distance; EMI-filtered power. *Round-3 candidate LL-025.* |
| **Active substrate manipulation** (catapult-tier) | Modified hardware attests to itself | Supply-chain integrity (build-of-materials provenance; trusted-vendor procurement); decommissioning protocols |
| **Software supply chain compromise** (catapult or cockroach hybrid) | Compromised dep chain produces compromised binary | Reproducible builds; signed packages; SBOM; sigstore-like infrastructure |
| **Social / governance / legal compulsion** | Substrate-bound identity doesn't help when the user is compelled | Operational: legal advice; jurisdictional considerations; cordon sanitaire (per the regime-awareness memory) |
| **Cryptographic primitive failure** (catapult) | LavaLamp depends on TPM, PQC, RNG correctness | Algorithm migration; defense-in-depth crypto; post-quantum readiness |
| **Operational / human error** (cockroach) | LavaLamp gives device identity, not user identity | UEBA; training; MFA; phishing-resistant auth flows |
| **Composability seams** (cockroach) | Interfaces between systems are where attacks live | Integration testing; formal seam-conformance verification; LL-023 conformance testing for consumers |
| **Long-term substrate drift** (cockroach patience) | Components age; replacements happen | Re-registration protocols (LL-011 variant C); audit trails; deployment-context lifetime declarations |
| **Quantum threat horizon** (catapult) | Q-Day breaks classical crypto | PQC migration; QKD complementarity (per `qkd_pqc_complementarity_companion.md`) |

**Note the asymmetry:** most of the OOS classes are catapult-
class. Cockroach classes are mostly within-scope or partially-
addressed. The catapult classes typically require *layered
defenses* at deployment time, not primitive-tier reinforcement.

### §4.3 — Load-bearing assumptions

For the Triad Deployments to be operationally meaningful, the
following assumptions must hold:

1. **Substrate not under physical interdiction.** No supply-
   chain compromise of the hardware before delivery.
2. **Substrate not under passive electromagnetic observation
   above noise floor.** A7 / TEMPEST-class observation either
   not occurring or bounded by deployment-context (Faraday /
   distance / EMI-filtered).
3. **Software dependency graph integrity.** Julia / Lean /
   build-tool dependencies are not tampered.
4. **Cryptographic primitives function as specified.** TPM,
   PQC, RNG behave per their standards.
5. **User is not compelled.** Substrate-bound identity does
   not survive legal/political coercion.
6. **Composability seams are individually intact.** LavaLamp
   ↔ PharOS ↔ OS-auth ↔ MFA integration testing is performed
   and conformance verified.
7. **Substrate is stable over the deployment's lifetime.** Or,
   if not, re-registration protocols are followed.
8. **Quantum threat horizon hasn't arrived for adjacent
   crypto.** Or, if it has, PQC migration is complete for
   the specific algorithms LavaLamp's protocol layer touches.

**Each of these is currently a load-bearing assumption that
the spec doesn't articulate.** Round-3 should consider whether
any deserve explicit Boundary entries (parallel to LL-015's
A3-OOS shape).

---

## §5 — Defense-in-depth: complementary systems

The Triad Deployments are *necessary but not sufficient* for
high-assurance identity. Layered defenses are required at
multiple tiers for the immune-system metaphor to work in
practice:

### §5.1 — Hardware-tier complements

- **Faraday-rated enclosure / TEMPEST-rated equipment** for
  passive-emanation defense (A7).
- **EMI-filtered power conditioning** (Furman / Tripp Lite
  tier; ~$100-300 consumer; SCIF-grade for state-actor
  threat tier).
- **Shielded cables** (USB / HDMI / ethernet) for radiated-
  emission containment.
- **Supply-chain integrity**: trusted-vendor procurement;
  hardware bill-of-materials provenance; tamper-evident
  packaging.
- **TPM 2.0 / Secure Enclave / TrustZone** for hardware
  root-of-trust (per LL-022 §2.2.1).
- **Decommissioning protocols** for end-of-life (data-bearing
  components don't escape the security boundary).

### §5.2 — Software-tier complements

- **Reproducible builds** so binaries match published source.
- **Signed packages + sigstore-like infrastructure** for
  supply-chain provenance.
- **SBOM (Software Bill of Materials)** for dependency
  transparency.
- **Lockfile discipline** (per CLAUDE.md package-management
  rule — already in place for Julia / Lean).
- **Static analysis** for known-vulnerability-pattern detection.
- **Privilege separation** — multiple OS users / containers /
  VMs depending on threat tier.

### §5.3 — Operational-tier complements

- **MFA / phishing-resistant authentication** layered on top
  of LavaLamp's device identity (FIDO2; WebAuthn).
- **UEBA (User and Entity Behavior Analytics)** for cockroach-
  class detection at the user/device-pattern level.
- **Security training** for human-facing attack surfaces.
- **Incident response** — assume compromise eventually happens;
  prepare to detect + recover rather than only prevent.
- **Logging + forensic-trail discipline** for post-incident
  analysis.

### §5.4 — Strategic-tier complements

- **Cordon sanitaire** under ruin-class risk (per
  `feedback_cordon_sanitaire.md`): structural disconnection
  with regulated membrane; resist taxonomy-greed; Taleb-asymmetric
  upside-vs-downside accounting.
- **Jurisdictional placement** considerations (legal-compulsion
  threat tier).
- **Cryptographic-primitive monitoring** (track NIST PQC
  standardisation, TPM advisory feeds, etc.); migration
  planning baked into deployment lifecycle.
- **Regime-awareness discipline**: match threat-tier to
  defensive investment; don't over-defend low-tier deployments
  or under-defend high-tier ones.

The defense-in-depth principle applies fractally: each tier
has its own immune system at the appropriate scale and
resolution.

---

## §6 — Round-3 questions surfaced

This companion surfaces several round-3 questions beyond the
ones already in `synthesis_team_round3_brief.md`:

1. **LL-025 candidate (already in the brief Q7/A7):** should
   passive-emanation scoping land as a new spec entry?
2. **Supply-chain integrity Boundary entry?** Should the
   software-supply-chain-integrity assumption (§4.3 #3) be
   articulated as an explicit LL-NNN entry, paralleling
   LL-022's downward-trust-stack scoping at the dependency-
   graph layer? Or fold into LL-022 §2.2 as a sub-bullet?
3. **Substrate-stability Boundary entry?** Long-term substrate
   drift (§4.3 #7) is not currently in the spec; if a
   deployment's lifetime is multi-year, this matters. Boundary
   entry or fold into LL-011 re-registration?
4. **Composability-seam discipline?** §4.3 #6 articulates seam
   conformance as a load-bearing assumption; should round-3
   propose an integration-testing discipline at the spec
   level, or treat it as deployment-time documentation?
5. **Quantum threat horizon framing?** §4.3 #8 mentions PQC
   migration; the QKD/PQC complementarity companion §1
   partially addresses this. Should round-3 propose an
   explicit PQC-readiness Boundary entry, or stay at the
   companion level?
6. **Threat-landscape companion as canonical reading?**
   Should this companion be cited in `attack_surface_enumeration.md`
   as the meta-architectural framing, or stand alongside it?
7. **Closure-of-N at multiple scales?** The deployment-stack
   triple LL-022 + LL-023 + LL-024 closes the *operational*
   scoping question; the threat landscape may suggest a
   parallel boundary triple at the *substrate* level (LL-015
   + LL-024 + a candidate LL-025) or at the *strategic* level
   (cordon-sanitaire + composability-seam + supply-chain).
   Does the corpus's closure-of-three philosophy generalise
   to multiple scales / resolutions, or does each scale need
   its own closure analysis?
8. **Should the spec articulate adversary-cost / target-value
   calculus explicitly?** §2.6-§2.7 (added 2026-05-05) reframe
   LavaLamp's security claim as *cost-asymmetry* — attacking
   this device must cost more than the result is worth
   relative to easier targets. LL-008 (resolution-bounded
   security) implicitly captures this — adversary measurement
   resolution is bounded by their cost budget — but the spec
   doesn't *call out* cost-asymmetry as the load-bearing
   security claim. Three architectural options:
   (a) Add an explicit Cost-Asymmetry Boundary entry
   articulating that LavaLamp's claim is "attacking this
   device costs more than the result is worth relative to
   easier targets" — formal version of the cordon-sanitaire /
   Taleb-asymmetry / metabolic-value discipline.
   (b) Augment LL-008 with a footer making the cost-
   asymmetry framing explicit; tie it to the threat-landscape
   companion §2.7.
   (c) Treat cost-asymmetry as deployment-context guidance —
   leave the spec at the resolution-bound level and document
   the cost calculus only in companion docs.
   The synthesis seat's call. Option (b) is probably the
   minimum honest framing; (a) makes the discipline
   architecturally visible; (c) defers to deployment.

These are all candidates for round-3 discussion. The brief's
Q7 covers (1); other questions may be added as the brief is
filled-in post-paper-update, or surfaced organically by the
synthesis + edge-witness seats.

---

## §7 — Lessons captured

### §7.1 — Bottom-up architectural work needs top-down framing periodically

The session arc 0.0.20 → 0.0.40 was substantively bottom-up:
specific entries refined, specific scoping passes landed,
specific test discipline tightened. **The
cockroach/catapult/castle metaphor surfaced a missing
top-down framing.** Without it, the spec's individual entries
sit in a context that exists only in the architects' heads.

The lesson generalises: meta-architectural framing should be
written down explicitly when the spec accumulates more than
~20 entries, or when a new architectural commitment (the
Triad Deployments umbrella) reframes the prior work. This
companion is the framing for LavaLamp's current state; future
LavaLamp work (or the parallel Lazarus / PharOS work) can
reference it as the canonical context.

### §7.2 — The corpus's defensive principle is structurally faithful

Aaron's metaphor is not decoration — it maps directly onto
Possibilistic Security's autopoietic-closure principle. The
immune system *is* the autopoietic activity; identity *is*
the closure-of-self-against-non-self the immune system
maintains. This isn't a marketing layer pasted on top of
technical work; it's the *same principle* expressed in a
register that's accessible to non-technical readers (and
prompts the right architectural questions for technical
ones).

The corpus's strength is that its high-level metaphors and
its low-level specs are saying the same thing in different
languages. This companion makes that explicit at the
threat-landscape level.

### §7.3 — Defense-in-depth is fractal, not hierarchical

§5 organised complementary defenses into hardware /
software / operational / strategic tiers, but they aren't a
strict hierarchy. Each tier has its own immune system; each
immune system needs the others; failures cascade in both
directions. **The Triad Deployments are one tier among
many; LavaLamp is one component within that tier.** Treating
the Triad as a complete defense overclaims; treating it as
"just one thing among many" underclaims.

The honest framing: the Triad Deployments are *substrate-
bound identity at the device tier*. Other tiers have their
own analogues; the deployments compose with — but do not
subsume — those analogues.

### §7.4 — State-level threats require structural responses, not just better defenses

§2.4 named the catapult+cockroach combination as the rare-and-
lethal state-level threat tier. Against this tier, no amount
of better single-axis defense suffices. The corpus's
`feedback_cordon_sanitaire.md` discipline applies — under
ruin-class risk, structural disconnection with regulated
membrane is the answer, not "defense-in-depth turned up to
11."

The Triad Deployments make state-level attacks *expensive
and detectable*, not impossible. That's an honest claim;
overclaiming undermines trust both with reviewers and with
the user.

### §7.5 — The metaphor is reusable

The cockroach/catapult/castle/immune-system framing is not
LavaLamp-specific. It applies to:
- Future Triad Deployments work (Lazarus's threat landscape;
  PharOS's specific OS-tier threat surface).
- Aaron's broader corpus work on possibilistic security and
  closure-based reasoning.

A version of this companion adapted for those projects would
be a small reuse; the substrate is the same metaphor + the
same corpus principles.

### §7.6 — Symbiosis is the equilibrium goal, not victory

The bottom-up empirical work (0.0.20 → 0.0.40) and the
cockroach/catapult/castle framing (§2.1-§2.5) both
implicitly assumed "better defense = more secure." The
metabolic-value framing (§2.6-§2.7, added 2026-05-05)
reframes: defense's *real* job is to position the target
outside the attacker's cost-justified zone. Most attackers
don't try because the math doesn't favor it — they find
their easy food elsewhere.

**The Triad Deployments don't need to be invincible against
state-level actors.** They need to make the state-level attack
*expensive AND detectable*. Combined with detection-postured-
not-prevention-postured framing (per the QKD/PQC
complementarity companion), this is honest: we raise the
cost; we don't promise no attacks.

The corpus's autopoietic-closure principle expressed at the
predator-prey level: **the closure isn't "we kill all
enemies"; it's "we maintain the metabolic conditions under
which most enemies don't bother and we detect the rare ones
who do."** This is what living systems actually do.

Practical defensive implication: defense-in-depth is **cost
amplification**, not perimeter strengthening. Each layer of
the Triad Deployments + complementary defenses (§5) raises
the attacker's total cost. No single layer needs to be
invincible — the *sum* needs to exceed the attacker's
budget for *this target*.

This also reframes the asymmetry-trap watch in
`dashboard.md`: the asymmetry-trap is when the defender
*claims invincibility* but the underlying mechanism is
cost-asymmetry. The honest claim is the cost-asymmetry one;
the trap is overclaiming. LL-008's resolution-bounded
security framing is *already* the honest claim; making the
cost-asymmetry framing explicit (§6 question 8 above)
reinforces the honest discipline at the threat-landscape
level.
