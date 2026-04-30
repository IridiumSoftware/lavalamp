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
