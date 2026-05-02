# CLAUDE.md — LavaLamp

## Project identity

A device-bound identity primitive. A laptop continuously solves a
hard but lightweight stochastic differential equation locally; the
trajectory is amplified by hardware/configuration-state coupling
(thermal jitter, CPU governor, scheduler timing, sensor reads from
USB / power-adapter / battery / temperature sensors) into a
substrate-unique signature. Identity = sustained chaotic trajectory
on the device. Verification = trajectory checkpoint comparison
against a registered hardware envelope, with adversary-signature
detection via Lyapunov-spectrum residue audit.

The project is structurally derived from the C-conjugate adversary
construction in *Possibilistic Security* (Green 2026), applied at
the entropy layer. It is **not** quantum key distribution, despite
sharing QKD's unclonability flavor: LavaLamp's security tier is
**resolution-bounded computational unclonability** — secure against
any adversary whose measurement/compute resolution is exceeded by
the device's chaos-production rate (`S_production > S_measurement`).

**Architectural separation** (load-bearing): the **security
primitive** (chaotic SDE + sensor coupling + Lyapunov-spectrum
audit) is decoupled from the **visual skin** (user-facing
lava-lamp animation). The visual is decorative and can be driven by
any RNG; the security is the substance under the hood. Same shape
as Lazarus.

**Status (2026-04-30).** Concept-stage. Architecture has been
synthesized through one round each of synthesis-seat (Gemini) and
edge-witness-seat (Grok) review. Visual/security decoupling
resolution by Aaron closes the round-1 blindspot. No code yet;
attack-surface enumeration is the next deliverable.

**Owner:** Aaron Green.

**Visual seed credit:** codetaur (SDE imagery resembling a lava
lamp; structural application unintended). Patent-offer extended
as good-faith credit for the seed.

## Orientation

Read `dashboard.md` first, every session — status summary, priority
stack, open questions. Start with `git status` to confirm a clean
working directory; if not, commit or stash before starting new
work.

For claim status, see `LAVALAMP_SPEC.md` directly. For history,
`changelog.md` or `git log`. For the file inventory, `git ls-files`.

## Ground truth hierarchy

1. **`LAVALAMP_SPEC.md`** — formal spec. Every named claim
   (security primitive property, architectural invariant, formal
   constraint) gets an LL-ID, a logic tier, an evidence type, and a
   status. If it's not in the spec, it's not established.

2. **`artifact_registry.md`** — maps every spec entry to its
   evidence file (test, proof, benchmark, argument). No registry
   row → no traceable evidence.

3. **Companion docs** — `docs/*_companion.md`. Permanent record of
   each substantive session (concept origin, dialogue rounds,
   architecture, attack-surface).

4. **`dashboard.md`** — current status + priorities + open
   questions. No scorecard copy — that lives in the spec only.

5. **Everything else** — eventual source code (Haskell / Lean /
   visual layer), build scripts. Supporting.

## Evidence types

Every spec entry must declare what kind of justification supports it.

| Type | Meaning | Sufficient for `:proved`? |
|---|---|---|
| **lean-proved** | Machine-verified proof in Lean 4 | Yes |
| **type-checked** | Property enforced by the host language's type system | Yes |
| **algebraic** | Symbolic computation in exact arithmetic that constitutes a proof | Yes |
| **property-tested** | QuickCheck-style property test passes | No → `:verified` |
| **example-tested** | Hand-written test case passes | No → `:tested` |
| **benchmarked** | Performance / signal-detection target met by recorded benchmark | No → `:benchmarked` |
| **manual** | Human inspection or written argument, not machine-checked | **No** → `:argued` only |
| **none** | Claim exists, no verification yet | No → `:open` |

**Rule.** `:proved` only if evidence type is `lean-proved`,
`type-checked`, or `algebraic`. The registry's `evidence_type`
column is the audit trail.

## Load-bearing scope boundaries

LavaLamp inherits two scope boundaries from the broader corpus:

1. **No complex numbers in security-critical math.** The visual
   layer is decorative and can use whatever it wants; the security
   primitive (SDE, sensor coupling, residue audit) stays
   real-valued. This is a corpus-wide discipline boundary, not a
   project preference.

2. **No full simulation in the dynamics regime that could
   instantiate self-reproducing structure.** LavaLamp solves a
   *bounded-time* SDE on a *finite* state — explicitly does not run
   continuum-limit / hypergraph-rewriting / autopoietic dynamics.
   Static analysis of trajectories within bounded windows; no
   open-ended simulation regime.

These are honored as constraints, not as preferences.

## Honest tier framing (load-bearing for any pitch)

LavaLamp delivers **computational unclonability** at the device-
universe scale. It is **not** information-theoretically secure in
the QKD / no-cloning-theorem sense. Quantum no-cloning depends on
the linearity of quantum mechanics; classical chaotic SDEs are
non-linear and the state is observable without collapse. Conflating
the two tiers in pitches will trip careful reviewers.

The right framing is **Substrate-Bound Identity** with
**Resolution-Bounded Security**: the device's chaos-production rate
exceeds plausible adversary measurement resolution. Strong in
practice; not unconditional.

QKD-flavored language is permitted in marketing register only,
never in formal claims.

## Language tiers and phase discipline

LavaLamp is structured by **stage-appropriate language choice** —
each phase uses the language whose strengths match the *kind of
risk* that phase is reducing. The methodology generalises from the
broader corpus discipline:

| Phase | Language | Risk reduced |
|---|---|---|
| **Explore** | Python (maybe Julia) | Conceptual — does the idea even work? |
| **Verify / obstruct** | Julia (`DifferentialEquations.jl`, `DynamicalSystems.jl`, `ChaosTools.jl`) | Computational (numerical) — do the numbers come out, and where do they refuse to? |
| **Categorical realise** *(when applicable)* | Julia + Catlab.jl / GATlab | Computational (categorical) — does the categorical structure actually close, do the diagrams commute on concrete instances? |
| **Prove (compositional)** | Haskell (types as spec; QuickCheck for universal coverage) | Compositional — did we *miss a corollary or universal* the spec implies? |
| **Prove (formal)** | Lean 4 | Mathematical — is the theorem actually *true*? |
| **Harden (future)** | C / C++, rewriting from the proven spec | Supply-chain / dependency / long-term-stability |

**Three distinct jobs in the formal stack** (load-bearing
distinction; do not collapse):

- **Catlab** — *computational* category theory. Builds the
  categorical model concretely, lets you compute with morphisms,
  verifies diagrams commute on instances. Over exact types this
  produces algebraic / `:catlab` evidence (the Closure v5 corpus
  has 9 of 145 `:proved` entries carrying this evidence type, so
  this is precedent, not speculation).
- **Haskell** — *compositional* coverage. Spec as types +
  QuickCheck enumerating universals example tests miss. Catches
  corollaries you didn't know you implied.
- **Lean 4** — *formal* proof. Machine-verified theorem in
  dependent type theory.

These are not interchangeable. Collapse Haskell into "another way
to write Julia or Lean" and it earns its keep nowhere. Collapse
Lean into "property tests but more rigorous" and you get
pseudo-formality without the actual logical guarantee. Collapse
Catlab into "a slow Haskell" and you lose the productivity
gradient that makes the tier worthwhile.

**Rationale per tier:**

- **Julia is the prototype core.** The SDE solver (`DiffEq.jl`),
  the Lyapunov-spectrum residue audit (`ChaosTools.jl`), the
  chaos-guard (real-time `λ_max` estimation), and the sensor
  coupling all live where the chaos community has done the
  algorithmic work. Reaching for Haskell or Python at this layer
  is rebuilding from scratch what's a one-liner in Julia.
- **Catlab fits between numerical verification and Haskell** when
  the architecture has non-trivial categorical content. Multiple-
  dispatch + concrete computation iterates faster than Haskell
  typeclass plumbing or Lean tactics. By the time you reach
  Haskell, you already know the morphisms compose; by the time
  you reach Lean, you already know the theorem statement is
  right. **Optional per project** — skip when the categorical
  content is shallow (pure SDE / numerical work); use when there
  are functors, natural transformations, universal constructions,
  or multicategory-style composition to verify.
- **Haskell is the compositional-completeness checker, not the
  prototype.** Property tests in Julia cover *example* space; they
  don't formally cover *composition* space. The spec implies
  corollaries and universals that example tests will pass over
  silently. Haskell's type system + QuickCheck force enumeration
  of compositions and structure what "complete coverage" means.
  Catching an unspotted universal at the Haskell stage is cheap;
  catching it after a Lean proof has been written against a flawed
  spec is expensive. (See triadic-coordination-engine S-026: the
  hand-built suite passed; QuickCheck immediately falsified
  symmetry on `"force-force-spec"` vs `"force_c-c-spec"`.)
- **Lean 4 is for formal truth on theorems**, not for compositional
  enumeration. Lean catches "is this true"; Haskell catches "did
  we enumerate everything." Complementary, not redundant.
- **C/C++ is hardening from the proven spec, not from
  exploratory code.** Once Haskell + Lean have closed the spec,
  the rewrite is a translation exercise from a formal
  specification. Reaching for C/C++ before the spec is closed
  collapses to refactoring tangled exploratory code.

**Phase discipline:**

- "Explore → verify → realise (categorical, when applicable) →
  prove → harden" is the canonical order, but feedback loops
  backward are normal. A Lean obstruction can send you back to
  verify; a verify obstruction can send you back to explore.
- "Obstruct" is a first-class result at every stage, not a failure.
  When verification or proof doesn't close, two valid forward
  moves: (a) refine the claim until it does close, or (b) accept
  the obstruction as a structural boundary and document.
- Edge-witness review fits naturally between phases (especially
  explore → verify and verify → prove). The synthesis-seat /
  edge-witness-seat protocol applies.

**For LavaLamp specifically (priority order):**

1. Attack-surface enumeration document (P1 in `dashboard.md`) —
   *landed in 0.0.3*.
2. Architectural design pass (P2): formalise the residue audit,
   the resolution-bounded security claim, the chaos-guard, the
   sensor-coupling potential field.
3. Julia prototype implementing the architecture (P3).
4. Catlab categorical realisation **only if** the verification
   protocol design (P2) surfaces enough categorical structure to
   warrant it. Default: skip; revisit when registration ceremony /
   cross-config transition designs are concrete. The SDE /
   sensor-coupling primitive is dynamical-systems work, not
   categorical; the verification protocol may be different.
5. Haskell spec-as-types + QuickCheck against the Julia
   prototype (compositional completeness check).
6. Lean 4 formal proofs of the structural security claims.
7. (Future) C/C++ hardening rewrite from the proven spec.
8. Decoupled visual skin throughout (per LL-002, low priority,
   any RNG / animation framework).

## Workflow rules

- **One task per conversation.** Don't combine architecture work
  with implementation.
- **Output every substantive session as a companion doc.** No
  version suffixes in filenames; git handles versioning.
- **The spec is ground truth.** Conflicts get resolved toward the
  spec.
- **Honest framing.** "Type-checked" beats "proved" when types are
  the only enforcement. "Resolution-bounded" beats "unconditionally
  secure" when the security depends on adversary capability.
- **Stubs that return data are forbidden.** Unimplemented functions
  must `error` / `sorry` / equivalent — never return placeholder
  values that silently corrupt downstream logic.
- **Test before committing.** A commit must compile and pass its
  component's tests.

## Companion doc standard

Every substantive session produces a companion doc in `docs/`. The
companion is the permanent record — chat history is ephemeral. If a
design decision was made in conversation but not captured in the
companion, it does not exist.

Sections (parallel to triadic-coordination-engine convention):

- **§1 — Computational basis.** What was built or run, with files,
  dependencies, build commands, test data.
- **§2 — Results.** What was found. Precise.
- **§3 — Verification.** For each result destined for the spec:
  type-checked / property-tested / example-tested / benchmarked /
  manually-argued / open. Honest.
- **§4 — Spec impact.** Proposed LL-ID, key, logic tier, evidence
  type, registry status.

## Cross-audit protocol

Cross-audits catch drift between spec, registry, code, and
dashboard. Run when integrating substantive new work or preparing a
release.

| Check | What to verify |
|---|---|
| **A0 — Self-audit** | Every claim *this CLAUDE.md* makes about how the project operates matches observable practice. Drift is fixed here, not in the project. |
| **A1 — Coverage** | Every spec LL-ID has a registry row. |
| **A2 — Key match** | Spec → Registry key mapping is identical. |
| **A3 — Evidence exists** | Every Test/Proof and Source file in the registry exists. |
| **A4 — Status honesty** | No entry has a status its evidence type can't support. |
| **A5 — Stale counts** | Counts cited in dashboard and CLAUDE.md match the spec. |
| **A6 — Test sync** | Every spec entry with a Test/Proof file is exercised by a test that runs in CI. |

## Key principles

- **The visual is not the work.** The lava-lamp animation is a
  decorative skin. The work is the security primitive under the
  hood. Same shape as Lazarus.
- **Decoupling is load-bearing.** Visual layer and security
  primitive must remain architecturally independent. If they ever
  become coupled, the basin-spoofing attack surface from the
  rejected SGL/Gray-Scott path returns.
- **The C-conjugate adversary is the meaningful adversary.** An
  attacker who can structurally co-occur but cannot sustain the
  trajectory is the adversary the residue audit is designed to
  detect. This is structurally inherited from Possibilistic
  Security.
- **Substrate-coupling is the security claim.** Identity is the
  trace, not the value. The trace cannot be detached from the
  hardware that produced it without the residue rising above
  threshold.
- **Resolution-bounded is the honest tier.** Not unconditional, not
  information-theoretic; resolution-bounded against adversary
  capability. State this plainly in every formal claim.

## What not to do

- Don't claim QKD-grade or no-cloning-theorem-inheritance security
  in formal claims. Marketing register only.
- Don't introduce complex numbers into the security-critical math.
  The visual layer can use whatever; the SDE / sensor coupling /
  residue audit stays real-valued.
- Don't couple the visual to the security primitive. Decoupling is
  load-bearing.
- Don't run open-ended simulations in regimes that could instantiate
  self-reproducing structure. Bounded windows, static analysis.
- Don't conflate the *visual* with the *fingerprint*. Two
  independent layers; the visual is decoration.
- Don't add spec entries without registry rows.
- Don't call a result "proved" unless its evidence type is
  `lean-proved`, `type-checked`, or `algebraic`.
- Don't bypass lockfile discipline once language tracks land.
