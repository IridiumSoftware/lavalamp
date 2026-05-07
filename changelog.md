# Changelog — LavaLamp

Versioned entries top-down. Each entry mirrors a commit; commit
messages match entry summaries.

---

## 0.0.56 — 2026-05-06 — `THEOREMS.md` at repo root + README trim

Lands two readability-tier improvements for the public repo:

**1. `THEOREMS.md` at repo root.** Auto-citable summary of
every theorem proved in LavaLamp's Lean 4 track. Each of
the five theorems gets:

- Full Lean statement (verbatim from
  `src/lean4/LavaLamp/Theorems.lean`).
- Proof structure / one-liner with named Mathlib lemmas.
- Hypothesis explanation (which hypotheses are needed
  where, and why).
- Spec connection (which LL-NNN entries the theorem touches
  + status implications).

Plus an index table, build-verification instructions, two
summary sections ("What this collectively proves" / "What
this does NOT prove"), and an honest-framing reminder
(`sorry` would surface as a linter warning; current build
returns zero warnings).

**Why this matters for the article.** The X article + any
future paper-tier artefact can cite "see `THEOREMS.md` for
the formal claims" as a single-file pointer. A reader
without Lean installed can read the theorem statements +
proof structure directly. Previously the formal-verification
content lived inside `LavaLamp/Theorems.lean`'s comment
blocks + `src/lean4/README.md` — visible only to readers
willing to navigate the Lean 4 source tree.

**2. README trim.** Removed two blocks that aren't
necessary for a public repo:

- The version-by-version "Trajectory" string (~150 lines)
  — every version from 0.0.1 through 0.0.55 listed in a
  single dense paragraph. The `changelog.md` has the
  durable per-version record; the README's job is the
  *current state* + how to use the project, not the entire
  development history.
- The "Round 3 ran 2026-05-06" narrative paragraph — full
  process detail of the synthesis-team round (seat
  rotation, verdicts, decision rendering). Useful to
  internal readers but irrelevant to a clone-and-evaluate
  reader. The `docs/synthesis_team_round3_companion.md`
  has the canonical record.

`CLAUDE.md` removed from the README's "See:" list and from
the Layout block — it's been untracked since 0.0.53 and
the references were stale.

**Net effect.** README drops from ~340 lines to ~160; the
"Try it" + spec-ledger + layout sections are intact and
front-and-center; `THEOREMS.md` is one click away from the
top-level table-of-contents.

Counts unchanged at 29/1/3/0/4/20/1. No Lean / Julia /
spec changes — readability-only pass.

**Files touched this version:**

- `THEOREMS.md` — **new file, repo root**; ~250 lines;
  full formal-verification summary.
- `README.md` — Trajectory section (lines 108-289 in
  pre-trim) removed; "See:" list updated (added
  `THEOREMS.md`, removed `CLAUDE.md`); Layout block
  updated (added `THEOREMS.md` row, removed `CLAUDE.md`
  row).
- `artifact_registry.md` — version line bump.
- `dashboard.md` — last-updated stamp; Recent companion
  docs section gets new top entry.
- `changelog.md` — this entry.

---

## 0.0.55 — 2026-05-06 — LL-006 detection-bound range theorems (bound ∈ [0,1])

Lands two short theorems establishing the bound *value*
`1 - K · exp(-(c · T) · δ²)` itself sits in the unit
interval. Without this, the LL-006 statement
`P(detect) ≥ <bound value>` is structurally incomplete:
if the bound exits `[0, 1]`, the inequality is either
vacuous (`bound < 0`) or structurally meaningless
(`bound > 1`). These theorems make the bound *well-typed*
as a lower-bound-on-probability.

**The theorems.**

```lean
theorem LL006_bound_le_one
    {δ K c T : ℝ}
    (h_K_nn : 0 ≤ K) :
    1 - K * Real.exp (-(c * T) * δ ^ 2) ≤ 1

theorem LL006_bound_nonneg
    {δ K c T : ℝ}
    (h_K_nn : 0 ≤ K)
    (h_K_le_one : K ≤ 1)
    (h_cT_nn : 0 ≤ c * T) :
    0 ≤ 1 - K * Real.exp (-(c * T) * δ ^ 2)
```

**Proofs.** `bound_le_one` is one line of work:
`Real.exp_pos` gives `0 < exp(...)`; `mul_nonneg`
lifts to `0 ≤ K · exp(...)` under `0 ≤ K`; `linarith`
discharges. `bound_nonneg` is four steps:

1. `mul_nonneg h_cT_nn (sq_nonneg δ)` gives
   `0 ≤ (c · T) · δ²`.
2. Negate: `-(c · T) · δ² ≤ 0` via `linarith`.
3. `Real.exp_le_exp.mpr` lifts the inequality through
   `exp`; `Real.exp_zero` rewrite gives
   `Real.exp (-(c · T) · δ²) ≤ 1`.
4. `mul_le_mul_of_nonneg_left` applies `0 ≤ K`;
   `linarith` closes the goal via the `K ≤ 1` hypothesis.

**The `K ≤ 1` hypothesis.** Required only for the lower
bound. Matches LL-006's fitted `K = 1` constant from the
0.0.17 P3-bound benchmark (the bound saturates at K=1).
The formalisation accepts any `K ∈ [0, 1]` for generality.

**Why two theorems, not one conjunctive theorem.** The
upper bound `bound ≤ 1` only needs `0 ≤ K`; the lower
bound `0 ≤ bound` needs additionally `K ≤ 1` and
`0 ≤ c · T`. Separate theorems with minimal hypotheses
are cleaner for downstream use — call sites can invoke
just the bound they need with just the hypotheses they
have.

**Bug fix bundled in.** The `### LL-007 — chaos-guard`
header in `LAVALAMP_SPEC.md` was accidentally dropped
during the 0.0.54 LL-006 footer addition (the Edit's
`old_string` included the header without including it in
`new_string`). 0.0.55 restores the header. LL-007 entry
content is unchanged; only the missing markdown header is
restored.

**Build verification.**

```
$ cd src/lean4 && lake build
✔ [1899/1901] Built LavaLamp.Theorems (5.1s)
✔ [1900/1901] Built LavaLamp (1.1s)
Build completed successfully (1901 jobs).
```

1901 jobs green; zero warnings. Build time identical to
0.0.54 (Mathlib analysis content already loaded; the new
theorems use lemmas already in scope: `Real.exp_pos`,
`Real.exp_le_exp`, `Real.exp_zero`, `mul_nonneg`,
`sq_nonneg`, `mul_le_mul_of_nonneg_left`).

**Composition foothold inventory after 0.0.55:**

1. `LL021_worst_case_bound` — 0.0.48 :proved.
2. `LL021_eff_squared_bound` — 0.0.49 corollary.
3. `LL006_worst_case_lower_than_isotropic` — 0.0.54
   bound-shape monotonicity.
4. `LL006_bound_le_one` — 0.0.55 upper-range.
5. `LL006_bound_nonneg` — 0.0.55 lower-range.

Five Lean theorems on the LL-006 / LL-021 track now,
collectively proving: the worst-case-projected adversary
magnitude is bounded by the unprojected magnitude (1);
the squared form of that bound (2); the bound *value* is
monotone-decreasing in the squared adversary magnitude (3);
and the bound itself is in `[0, 1]` (4 + 5).

**What this still doesn't prove.** `P(detect) ≥ ...`
itself. That's a probability-space claim requiring full
formalization. LL-006 stays `:benchmarked`. The Lean
content built so far is *all* of the algebraic /
real-analysis structure that the eventual `:proved` proof
will compose with — the missing piece is the probability
side (sample space, random variables, detection event
predicate, the probabilistic concentration argument).

**Counts.** Unchanged at 29/1/3/0/4/20/1.

**Files touched this version:**

- `src/lean4/LavaLamp/Theorems.lean` — added
  `LL006_bound_le_one` and `LL006_bound_nonneg` after
  `LL006_worst_case_lower_than_isotropic`; `scaffold_tier`
  string bumped to "0.0.55 — LL-006 detection-bound range
  theorems landed (bound ∈ [0,1])".
- `LAVALAMP_SPEC.md` — LL-006 entry gains a new "LL-006
  detection-bound range theorems (0.0.55)" footer
  documenting the well-typedness result. The
  `### LL-007 — chaos-guard` header (accidentally dropped
  in 0.0.54) is restored.
- `artifact_registry.md` — version line bump; LL-006 row
  Test/Proof column updated to mention the range theorems;
  A1-A6 self-check refreshed for 0.0.55.
- `dashboard.md` — last-updated stamp; Recent companion
  docs section gets new top entry covering the range
  theorems + LL-007 header restoration + composition-
  foothold-inventory.
- `changelog.md` — this entry.
- `README.md` — trajectory entry for 0.0.55.

---

## 0.0.54 — 2026-05-06 — LL-021/LL-006 composition theorem (`LL006_worst_case_lower_than_isotropic`)

Lands the second composition foothold on the LL-006
detection-bound track. Theorem 2 in the round-3 §1D.v
priority sequence (after the 0.0.48 LL-021 worst-case bound
and the 0.0.49 squared-effective-magnitude corollary).

**The theorem.**

```lean
theorem LL006_worst_case_lower_than_isotropic
    {ε_A proj K c T : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_nn : 0 ≤ proj)
    (h_proj_le_one : proj ≤ 1)
    (h_K_nn : 0 ≤ K)
    (h_cT_nn : 0 ≤ c * T) :
    1 - K * Real.exp (-(c * T) * (ε_A * proj) ^ 2)
      ≤ 1 - K * Real.exp (-(c * T) * ε_A ^ 2) := by
  have h_sq : (ε_A * proj) ^ 2 ≤ ε_A ^ 2 :=
    LL021_eff_squared_bound h_ε h_proj_nn h_proj_le_one
  have h_neg_cT : -(c * T) ≤ 0 := neg_nonpos.mpr h_cT_nn
  have h_neg : -(c * T) * ε_A ^ 2 ≤ -(c * T) * (ε_A * proj) ^ 2 :=
    mul_le_mul_of_nonpos_left h_sq h_neg_cT
  have h_exp : Real.exp (-(c * T) * ε_A ^ 2)
                 ≤ Real.exp (-(c * T) * (ε_A * proj) ^ 2) :=
    Real.exp_le_exp.mpr h_neg
  have h_mul : K * Real.exp (-(c * T) * ε_A ^ 2)
                 ≤ K * Real.exp (-(c * T) * (ε_A * proj) ^ 2) :=
    mul_le_mul_of_nonneg_left h_exp h_K_nn
  linarith
```

Five-step composition: (1) squared-magnitude bound from
LL-021's corollary; (2) multiply by non-positive scalar
`-(c·T)` flips direction; (3) `Real.exp` monotonicity lifts
the inequality through the exponential; (4) multiplying by
`K ≥ 0` preserves direction; (5) subtraction from `1` flips
once and `linarith` discharges. Every hypothesis is used
load-bearing in at least one step.

**What this proves.** The worst-case detection-probability
bound *value* is less than or equal to the isotropic
detection-probability bound *value*: the LL-021 asymmetry
claim against LL-006 is mathematically derivable from the
bound shape, not just empirically observed.

**What this does NOT prove.** The bound itself
(`P(detect) ≥ 1 - K · exp(-c · T · δ²)`) is a probability-
space claim. Formalizing it requires:

- A probability space modeling trajectory sampling.
- Random variables for the spectrum estimator output.
- The detection-event predicate (when do we say a trajectory
  was "detected as adversarial"?).
- The lower-bound proof itself (probabilistic concentration
  inequality on the spectrum residue).

Each of these is a multi-session research investment. The
0.0.54 theorem proves a *property* of the bound shape —
specifically that the bound is monotone-decreasing in the
squared adversary magnitude — independent of whether the
shape itself bounds `P(detect)`.

**LL-006 status implication: unchanged at `:benchmarked`.**
Promoting to `:proved` requires the full probability
formalization above. The `:benchmarked` content (`K=1,
c′=0.00423, T=60` from the 0.0.17 P3-bound benchmark)
remains the operational evidence; the 0.0.54 theorem is
composition-tier infrastructure that the eventual `:proved`
proof will compose with.

**Imports added.** `Mathlib.Analysis.SpecialFunctions.Exp`
joins the existing `Mathlib.Data.Real.Basic` in
`src/lean4/LavaLamp/Theorems.lean`. This pulls in Mathlib's
real-analysis content for `Real.exp` + `Real.exp_le_exp`
monotonicity. The full Mathlib environment (round-3 §1D.v
Decision 1 Option A) handles this without additional
configuration.

**Build verification.**

```
$ cd src/lean4 && lake build
✔ [1899/1901] Built LavaLamp.Theorems (6.9s)
✔ [1900/1901] Built LavaLamp (1000ms)
Build completed successfully (1901 jobs).
```

1901 jobs green; **zero warnings**. Job count jumped 767 →
1901 with the `Real.exp` import — that's the cost of
pulling Mathlib's analysis module graph. CI workflow at
`.github/workflows/lean.yml` has a 60-minute timeout from
0.0.47 which absorbs the larger build comfortably.

**Composition foothold inventory after 0.0.54:**

1. `LL021_worst_case_bound` — 0.0.48 :proved; the
   foundational `ε_A · proj ≤ ε_A` algebraic bound via
   `mul_le_of_le_one_right`.
2. `LL021_eff_squared_bound` — 0.0.49 corollary;
   `(ε_A · proj)² ≤ ε_A²` via `pow_le_pow_left₀`.
3. `LL006_worst_case_lower_than_isotropic` — 0.0.54 (this
   version); composes (1) + (2) with `Real.exp`
   monotonicity to derive the asymmetry implication.

Each composition step is a real algebraic statement, kernel-
verified at compile time. The chain demonstrates the
:proved → :proved-via-composition pattern: future Lean theorems
land *atop* established :proved content rather than from
scratch.

**Counts.** Unchanged at 29/1/3/0/4/20/1.

**Files touched this version:**

- `src/lean4/LavaLamp/Theorems.lean` — added
  `LL006_worst_case_lower_than_isotropic` theorem after
  `LL021_eff_squared_bound`; added
  `import Mathlib.Analysis.SpecialFunctions.Exp`;
  `scaffold_tier` string bumped to "0.0.54 — LL-006
  worst-case-detection-bound monotonicity composed with
  LL-021".
- `LAVALAMP_SPEC.md` — LL-006 entry gains a new "LL-021/
  LL-006 composition theorem (0.0.54)" footer; LL-021
  entry's 0.0.49 footer gains a forward-reference to the
  cashed composition theorem at 0.0.54.
- `artifact_registry.md` — version line bump; LL-006 row's
  Test/Proof column gets the Lean theorem-file pointer; A1-A6
  self-check refreshed for 0.0.54.
- `dashboard.md` — last-updated stamp; Recent companion docs
  section gets new top entry covering the composition
  theorem + composition-foothold-inventory.
- `changelog.md` — this entry.
- `README.md` — trajectory entry for 0.0.54.
- `src/lean4/README.md` — first-priority row in the
  theorem-plan table updated to mention the LL-006
  composition theorem.

---

## 0.0.51 — 2026-05-06 — Clone-and-run demo for publication-day shipability

Lands a self-contained end-to-end walkthrough at
`src/julia/demo/lavalamp_demo.jl` so the new corpus X article
(publishing 2026-05-06) can credibly reference LavaLamp as a
*shippable* Triad Deployment, not just source code with a
spec ledger.

**Why this exists.** The publication-day plan adds LavaLamp to
the Triad Deployments list alongside Lazarus and OpenQMS. A
deployment claim should be backed by a runnable artifact a
reader can execute from a fresh clone — not just by a source
tree and a 1500-line spec. The demo is the bridge: it stands
the LavaLamp pipeline up end-to-end, drives it with the same
APIs the test suite uses, and prints observable evidence at
each stage so a reader can verify the spec claims behave as
the spec says they do.

**What the demo exercises.** Six spec layers, sequenced as a
single ~4-second wall-clock script on a 2024-vintage laptop:

1. **LL-003** — Lorenz-96 SDE engine; F=8 baseline (the
   `:benchmarked` SDE choice from the 0.0.25 P3d
   selection benchmark).
2. **LL-004** — Sensor-coupling layer; linear-in-x with a
   constant synthetic stream (real hardware = LL-024
   scaffold tier; demo runs anywhere Julia + the lockfile
   installs).
3. **LL-011 / LL-006** — Registration ceremony calibrating
   an envelope over 5 trajectories at N=20, N_steps=1000;
   produces mean λ₁ ≈ +1.89 and per-exponent σ.
4. **LL-019** — `verify_full` API forces full Benettin
   spectrum at the call boundary (audit-on-every-verify).
5. **LL-021** — Strong adversary at ε_A=3σ via
   `synthetic_adversary`; the demo numerically exhibits the
   bound-shape asymmetry the Lean theorem proves
   algebraically.
6. **LL-007** — Chaos-guard state machine; WARMUP → VALID
   over three honest λ̂₁ samples; INVALID after one
   sub-threshold collapse sample.

**Output anchors.** The demo prints residue/σ ratios at each
verify stage and wall-clock timings:

- Honest verify: `max residue / σ` ≈ **2.97** (under k=10).
- Adversary verify: `max residue / σ` ≈ **14.47** (over k=5).
- Wall-clock: registration ~3.8 s; each verify ~0.2 s.

If all three pillars — honest ACCEPT, adversary REJECT,
chaos-guard collapse — behave as expected, the demo prints
`✅ All three pillars of the LavaLamp pipeline behave as
specified.` and exits 0. If any pillar diverges, the demo
prints `❌` and exits 1; CI / reader can use the exit code
as a smoke check.

**Build verification.** Demo executed cleanly during this
version pass — full transcript captured in this commit's
session log; reproducible across Julia versions modulo the
`Manifest.toml` lockfile.

**README quickstart.** The top-level README gains a "Try it"
section with the run command, expected output summary, and a
pointer to `src/lean4/` for the formal-verification side. The
layout block is updated to surface `demo/lavalamp_demo.jl`
in the Julia subtree.

**Why this isn't a spec change.** The demo uses the same APIs
the test suite already exercises (`register_envelope`,
`verify_full`, `synthetic_adversary`, `Guard / update! /
is_valid`); it provides no new evidence beyond what the
:tested entries already carry. The demo is a *packaging
artifact* for shippability, not a verification artifact.
Counts unchanged at 29/1/3/0/4/20/1.

**What's deliberately out of scope.**

- **Real hardware sensors.** RealSensors.jl is scaffold-tier
  (LL-024); calling those functions errors with a deferred-
  implementation message. P-RS Level 2 prototype track
  per round-3 §1D.viii.
- **Calibration confidentiality (LL-020 ε-DP envelope).**
  Separate API; out of scope for the smoke-walkthrough.
- **The Lean track.** `src/lean4/` has its own README and
  build instructions; the demo points there but doesn't
  invoke `lake build`.

**Files touched this version:**

- `src/julia/demo/lavalamp_demo.jl` — **new file**; ~190
  lines including header documentation; runnable with
  `julia --project=src/julia src/julia/demo/lavalamp_demo.jl`.
- `README.md` — new "Try it" section between "Architectural
  separation" and "Status"; layout block gains
  `demo/lavalamp_demo.jl` row in the Julia subtree.
- `artifact_registry.md` — version line bump (counts
  unchanged).
- `dashboard.md` — last-updated stamp; Recent companion
  docs section gets new top entry.
- `changelog.md` — this entry.

---

## 0.0.50 — 2026-05-06 — Synthesis-team round 3 Tier 3 spec landing (LL-028 + LL-029 + LL-019 deployment-context expansion)

Lands the three Tier 3 spec changes per round-3 §1D.iii and
§1D.iv. **Spec-only this version** — engineering
implementation is separately sequenced by P-RS Level 2
prototype availability per round-3 §1D.viii. The
architecture-design content for the gaps round-3 surfaced
lands now; the engineering pass (conformance-check module,
sensor architecture with physical-mechanism family
enumeration, P-RS Level 2 prototype hardware availability)
comes later, in multiple separate version bumps as the
engineering completes.

This version closes the round-3 spec-side trajectory
end-to-end: Tier 1 (0.0.45) → Tier 2 (0.0.46) → Lean L1
(0.0.47) → Lean L2 (0.0.48) → LL-006 composition foothold
(0.0.49) → Tier 3 (this version). The round-3 §1D.viii
"Round 4 trigger" condition ("after Tier 1 + Tier 2 land
*and* the first Lean theorem is type-checked") is now
satisfied; Round 4 may be initiated when ready.

**Tier 3 spec changes (this version):**

### LL-028 — runtime-conformance-verification (added)

- **Logic tier:** Boundary.
- **Evidence type:** manual.
- **Status:** `:argued`.
- **Defends:** V-019 (runtime conformance bypass — deployer
  satisfies API while violating invariants internally).
- **Round-3 origin:** ChatGPT §1C.A3 (edge-witness round-3
  seat): *"system satisfies API but violates invariants
  internally. This is equivalent to type-level vs semantic
  conformance mismatch."*

The deployment-stack triple (LL-022 + LL-023 + LL-024)
specifies *what* must hold — required OS-trust-stack
mechanisms, exposed consumer-API surface, real-sensor
deployment strategies. None of the three specifies *how to
verify it holds at runtime*. A malicious or compromised
deployer can satisfy the LL-023 API contract while violating
LL-022 invariants internally: TRNG-replacement (seeded once
at boot, replayed); sensor-fusion forgery (cached / scripted
sensor reads); TPM-attestation stubs returning hardcoded
`valid`; cached-randomness reuse with API contract preserved.

LL-028 closes this gap with four runtime-verification
requirements:

1. **Attestation continuity.** TPM-attested boot PLUS
   measured runtime state — periodic re-attestation that the
   running binary matches the boot-time-attested measurement.
2. **Sensor cross-validation with adversarial probes.**
   Periodic LL-024 cross-validation runs include adversarial
   test inputs (challenge-response patterns) to detect cached
   / scripted sensor responses.
3. **Verifier-side LL-023 API probing.** Verifier issues
   API queries with embedded conformance probes — queries
   whose results would diverge if the deployer were stubbing
   the underlying mechanisms (statistical fingerprints of
   TRNG output; cross-call entropy decorrelation tests).
4. **Continuous TRNG attestation.** Where the platform
   supports it (e.g. Intel `RDRAND` health-check return-code),
   verifier reads the health-check status alongside random
   output.

These requirements are operational-tier — satisfied by the
deployment, not by LavaLamp's internal logic. LL-028 is the
spec-level statement that runtime conformance is a Boundary
requirement: LL-008 (resolution-bounded security) holds *only*
in deployments where runtime conformance is verified.

`:tested` upgrade path: P-RS Level 2 prototype's
conformance-check module exercises the four requirements on
the prototype's reference deployment (Linux + TPM-equipped
host).

### LL-029 — multi-channel-entropy-independence (added)

- **Logic tier:** Operational.
- **Evidence type:** manual.
- **Status:** `:argued`.
- **Defends:** V-018 (coordinated multi-sensor synthesis —
  sensor-fusion-inversion attack class).
- **Round-3 origin:** ChatGPT §1C.A2: *"the cross-validation
  model assumes independent noise sources, but a determined
  adversary can couple channels physically. This is a classic
  sensor-fusion-inversion attack: attacker injects signals
  that satisfy constraints rather than violate them."*

LL-016 Strategy 2 (multi-sensor cross-validation) defends
against *naive* spoofing where the adversary manipulates one
sensor in isolation. The defence rests on the implicit
assumption that distinct sensors carry *independent* entropy.
The assumption fails when sensors share an underlying
*physical mechanism*: a heater couples thermal sensor +
battery-discharge sensor (one mechanism, two sensors); a
load injector couples AC current + thermal rise (one
mechanism, two sensors); a vibration motor couples microphone
+ accelerometer (one mechanism, two sensors). The
cross-validation algorithm sees correlated readings — exactly
the signal it's looking for — and passes.

LL-029 requires *physical-mechanism* diversity, not just
sensor diversity. Sensor selection must span *uncorrelated*
physical mechanisms. The initial taxonomy (deployment-
expandable):

1. **Thermal.** Temperature; battery-discharge curves; CPU
   thermal-throttle telemetry; cooler-fan PWM.
2. **Acoustic / vibrational.** Microphones; accelerometers;
   gyroscopes; mechanical-resonance sensors.
3. **Electromagnetic / RF.** EMI; antenna noise floor;
   magnetic-field sensors.
4. **Electrical.** Voltage rails; AC current; ground-plane
   impedance; PSU noise.
5. **Optical.** Ambient-light; camera sensor noise; IR
   proximity; OLED display refresh patterns.
6. **Entropy-source-decay.** Hardware TRNG drift; CPU
   jitter accumulation; clock-skew envelope.
7. **Quantum-flavoured.** Radioactive-decay sensors;
   quantum-tunneling diodes (PharOS-tier deployments).

Cross-validation across families: at least two *uncorrelated*
families contribute, with correlation measured empirically
during registration over a 60-second calibration window.
Pairs with correlation magnitude `|ρ| > 0.3` are flagged
same-family and counted as one entropy source.

**Within-family multi-sensor is NOT a defence.** Adding more
sensors of the same family (four thermal sensors instead of
one) does not satisfy LL-029 — the V-018 coupling attack
defeats correlated readings regardless of count.

`:tested` upgrade path: P-RS Level 2 sensor architecture
enumerates physical-mechanism families per platform +
implements the calibration-window correlation test in the
registration flow.

### LL-019 — deployment-context expansion (amendment)

- **Status unchanged at `:benchmarked`.**
- **Round-3 origin:** ChatGPT §1C.A1 (LL-019 is BOTH
  methodological artifact AND real adversary channel).
- **Disposition note:** Grok proposed collapsing LL-019 into
  an LL-022 sub-claim ("no new LL-ID required"); ChatGPT
  countered that LL-019 stays as a standalone entry because
  the timing-channel structural claim is independent of the
  OS-trust-stack scoping declaration. Aaron's resolution
  decision 3 confirmed standalone framing.

LL-019's scope is expanded to cover both deployment regimes:

**Regime 1 — Dev-host artifact (the 0.0.19 benchmark
regime).** Sub-microsecond timing channel below OS scheduling
jitter; KS-test verdicts statistically indistinguishable
with margin. The 0.0.19 + 0.0.29 high-res evidence
characterises this regime and is the basis for the
`:benchmarked` status.

**Regime 2 — Multi-tenant shared environment (real channel).**
Cloud VMs, container orchestrators with neighbouring
workloads, co-tenant CPUs. Timing channel *not* below the
jitter floor — observable by co-tenant adversary. The
dev-host benchmark does not characterise this regime.
LL-019's `:benchmarked` status applies to regime 2 only with
the shared-environment deployment constraint:

1. **Dedicated core / pinned scheduling.** Verify path runs
   on a CPU core not shared with adversary-accessible
   workloads (`taskset`, CPU-affinity, dedicated container).
2. **Constant-time padding above shared-host noise floor.**
   Padded response duration calibrated to dominate observable
   shared-host jitter (operationally `pad_target ≥ 10 ms`).
3. **Jitter randomisation.** Uniform offset on
   `[0, jitter_window]` with `jitter_window ≥ 1 ms`
   decorrelates systematic timing leakage from verify result.

Deployments that don't meet these constraints fall outside
LL-019's `:benchmarked` claim space. The amendment is a
scope-honesty refinement, not a status change — the regime-1
evidence is unchanged.

### Round-3 closure status

All round-3 spec-side deliverables landed end-to-end:

- ✓ Tier 1 (0.0.45) — LL-025 + LL-026; V-014..V-020 enumerated.
- ✓ Tier 2 spec (0.0.46) — LL-027 + LL-021 amendment + LL-014
  amendment.
- ✓ Lean L1 (0.0.47) — Mathlib v4.29.1; LL-021 sorry-stubbed.
- ✓ Lean L2 (0.0.48) — LL-021 proved (`:proved`).
- ✓ LL-006 composition foothold (0.0.49) —
  `LL021_eff_squared_bound` lemma.
- ✓ Tier 3 spec (this version) — LL-028 + LL-029 + LL-019
  expansion.

Round-3 §1D.viii "Round 4 trigger" satisfied: Tier 1 + Tier 2
landed; first Lean theorem type-checked. Round 4 may be
initiated when ready.

Tier 3 *engineering* implementation (LL-028 conformance-check
module, LL-029 physical-mechanism-family enumeration in P-RS
Level 2 sensor architecture, P-RS Level 2 prototype
availability) is sequenced separately as engineering work,
per-entry version bumps as engineering completes.

### Counts

27/1/3/0/4/18/1 → 29/1/3/0/4/20/1.

- Total: 27 → 29 (+LL-028 +LL-029).
- `:argued`: 18 → 20 (+LL-028 +LL-029).
- All other counts unchanged.
- LL-019 amendment is notes-amendment to existing entry; no
  count change.

### Files touched this version

- `LAVALAMP_SPEC.md` — LL-028 + LL-029 entries added under
  the round-3 surfaced-section; LL-019 entry gains the
  round-3 deployment-context expansion footer; Counts
  section updated to 29/1/3/0/4/20/1.
- `artifact_registry.md` — version line bump; LL-028 +
  LL-029 rows added under round-3 section; counts updated;
  A1-A6 self-check refreshed for 0.0.50.
- `dashboard.md` — last-updated stamp; spec-status section
  count flips; Recent companion docs section gets new top
  entry covering all three Tier 3 changes + round-3 closure
  check.
- `changelog.md` — this entry.
- `README.md` — count breakdown table (`:argued` 18 → 20);
  trajectory entry for 0.0.50.

---

## 0.0.49 — 2026-05-06 — LL-021 squared-effective-magnitude composition foothold (`LL021_eff_squared_bound`)

Lands a corollary lemma in
`src/lean4/LavaLamp/Theorems.lean` that sets up the
round-3 §1D.v priority-4 LL-006 detection-bound theorem —
the algebraic step that bridges LL-021 (worst-case bound on
`ε_eff = ε_A · proj`) and LL-006 (detection-probability
bound shape `P(detect) ≥ 1 - K · exp(-c · T · ε_eff²)`).

**The lemma.**

```lean
theorem LL021_eff_squared_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_nn : 0 ≤ proj)
    (h_proj_le_one : proj ≤ 1) :
    (ε_A * proj) ^ 2 ≤ ε_A ^ 2 :=
  pow_le_pow_left₀
    (mul_nonneg h_ε h_proj_nn)
    (LL021_worst_case_bound h_ε h_proj_le_one)
    2
```

Term-mode proof; one-line discharge against Mathlib's
`pow_le_pow_left₀` (the GroupWithZero-form monotone-pow
lemma; the unsubscripted `pow_le_pow_left` from older
Mathlib versions was renamed during the v4.x reorganisation
and the `₀` form is what `ℝ` hits in v4.29.1).

**Why it matters — composition with LL-006.**
`LL021_worst_case_bound` gives `ε_A * proj ≤ ε_A` (worst-case
projection cannot increase magnitude). LL-006's
detection-probability bound shape is
`P(detect) ≥ 1 - K · exp(-c · T · ε_eff²)`. To compose them,
we need `ε_eff² ≤ ε_A²` — and since `t ↦ exp(-c · T · t)` is
decreasing in `t` for `c · T > 0`, this monotonicity flips
to `exp(-c · T · ε_eff²) ≥ exp(-c · T · ε_A²)`, so
`1 - K · exp(-c · T · ε_eff²) ≤ 1 - K · exp(-c · T · ε_A²)`,
meaning **the worst-case detection probability is lower than
the isotropic detection probability** — which is exactly the
structural asymmetry claim LL-021 is making against LL-006.

This lemma encodes the squared-magnitude step. When LL-006
lands as a Lean theorem (round-3 §1D.v priority 4), it will
import this corollary and chain it through Mathlib's
`Real.exp_le_exp` and `mul_le_mul_of_nonneg_left` to derive
the composed bound.

**Hypothesis-set difference vs `LL021_worst_case_bound`.**
The worst-case bound itself does *not* need `0 ≤ proj` (the
bound `ε_A * proj ≤ ε_A` holds for negative `proj` too); we
explicitly dropped that hypothesis at L2 (0.0.48). The
squared-bound corollary *does* need `0 ≤ proj` because the
monotone-squaring step `0 ≤ a ≤ b → a² ≤ b²` requires the
lower bound to be non-negative. Without `0 ≤ ε_A * proj`
(which mul_nonneg gives us from `0 ≤ ε_A` and `0 ≤ proj`),
`pow_le_pow_left₀` does not apply. The hypothesis is
reintroduced in the signature; downstream call sites already
have it from the geometric construction `proj = |û · m_unit|
≥ 0`.

**Build verification.**

```
$ cd src/lean4 && lake build
✔ [765/767] Built LavaLamp.Theorems (755ms)
✔ [766/767] Built LavaLamp (719ms)
Build completed successfully (767 jobs).
```

767 jobs green, **zero warnings**.

**Counts.** Unchanged at 27/1/3/0/4/18/1. The corollary is
additional `lean-proved` content supporting the existing
LL-021 `:proved` entry, not a new entry. Future LL-006
detection-bound theorem (which uses this corollary) will be
the next status flip — `:benchmarked` → `:proved` for
LL-006 — but that's a separate version pass.

**A naming detail (recorded for future Mathlib bumps).** In
v4.29.1, the lemma `pow_le_pow_left` was a "not found" error;
the working name is `pow_le_pow_left₀`. The unsubscripted
form was renamed during Mathlib's v4.x algebraic-hierarchy
reorganisation. If a future Mathlib bump renames again, the
`pow_le_pow_left₀` reference here is the place to look.

**Files touched this version:**

- `src/lean4/LavaLamp/Theorems.lean` — `LL021_eff_squared_bound`
  added below `LL021_worst_case_bound`; doc-comment expanded
  to document the LL-006 composition role and the hypothesis-
  set difference vs the worst-case bound; `scaffold_tier`
  string bumped from "0.0.48 proved" to "0.0.49 squared bound
  landed".
- `LAVALAMP_SPEC.md` — LL-021 entry gains a new "Squared-
  effective-magnitude composition foothold (0.0.49)" footer
  documenting the corollary and its LL-006 composition role.
  Counts section unchanged.
- `artifact_registry.md` — version line bump; LL-021 row's
  Test/Proof column gets the corollary mention; A1-A6
  self-check refreshed for 0.0.49 (counts unchanged).
- `dashboard.md` — last-updated stamp; Recent companion docs
  section gets new top entry.
- `changelog.md` — this entry.
- `README.md` — trajectory entry for 0.0.49.
- `src/lean4/README.md` — first-priority row in the theorem-
  plan table updated to mention the corollary.

---

## 0.0.48 — 2026-05-06 — Synthesis-team round 3 Lean L2 (LL-021 worst-case bound proved; first-ever LavaLamp `:proved` entry)

Lands Lean L2 — the `sorry` body in
`LavaLamp.LL021_worst_case_bound` is replaced with a real
Lean 4 proof. Closes Aaron's round-3 §1D.v Decision 1 path
end-to-end (Option A — full Mathlib; theorem 1 = LL-021
worst-case bound).

**The proof.** A direct application of Mathlib's
`mul_le_of_le_one_right : 0 ≤ a → b ≤ 1 → a * b ≤ a`:

```lean
theorem LL021_worst_case_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_le_one : proj ≤ 1) :
    ε_A * proj ≤ ε_A :=
  mul_le_of_le_one_right h_ε h_proj_le_one
```

Term-mode (no `by ...`); one-line discharge against the
Mathlib lemma. The Lean 4 kernel verifies the proof at
compile time — `lake build` is now a real correctness check,
not just an infrastructure smoke test.

**Signature change vs L1.** The L1 statement carried three
hypotheses: `0 ≤ ε_A`, `0 ≤ proj`, `proj ≤ 1`. L2 drops
`0 ≤ proj` because the bound `ε_A * proj ≤ ε_A` holds
without it: when `proj < 0`, the product `ε_A * proj` is
non-positive (since `0 ≤ ε_A`) and trivially `≤ ε_A`. The
Mathlib lemma `mul_le_of_le_one_right` is stated this way
for the same reason. The geometric construction
`proj = |û · m_unit|` from the spec already guarantees
`0 ≤ proj` at the call sites where it matters; downstream
theorems composing with this one (e.g. LL-006 detection-bound
via `ε_eff²`) will introduce the non-negativity hypothesis
where they need it. Removing it from the L1 statement keeps
the lemma as general as the pure algebraic fact requires —
and as a side benefit, removes the `unused variable
h_proj_nn` linter warning that L1's signature would have
triggered if the proof did not use the hypothesis.

**Build verification.**

```
$ cd src/lean4 && lake build
✔ [765/767] Built LavaLamp.Theorems (741ms)
✔ [766/767] Built LavaLamp (710ms)
Build completed successfully (767 jobs).
```

767 jobs green; **zero warnings** — the L1 `declaration uses
sorry` warning is gone, no `unused variable` warning, no
deprecation warning. CI on `.github/workflows/lean.yml` will
catch any future regression.

**Status flip.**

- LL-021 evidence-type: `benchmarked` → `lean-proved`.
- LL-021 status: `:benchmarked` → `:proved`.
- LL-021 is **the first-ever LavaLamp `:proved` entry.**

**Counts.** 27/0/3/0/5/18/1 → 27/1/3/0/4/18/1 (+1 :proved /
−1 :benchmarked; total + others unchanged).

**`:benchmarked` content preserved.** The empirical fit
constants (`K=1, c′=0.0288, T=60` at N=20, n=15 trials per
point per `docs/ll021_high_res_companion.md`) and the
structured-adversary benchmark surface remain in the spec
entry's notes. The Lean theorem captures the bound *shape*
— `ε_eff = ε_A · proj` cannot exceed `ε_A` — which is the
algebraic content the empirical fit is a *fit to*. The
operational deployment-fit detail (precise constants for
real Lorenz-96 prototype configurations) is `:benchmarked`
content; the underlying bound shape is now `:proved`. The
two work together: the proof is the structural backbone, the
benchmark calibrates the per-deployment numerical content.

**Round-3 amendments preserved.** The LL-021 spec entry's
round-3 amendments (finite-N scope-limit at N ≤ 80;
adaptive-adversary statement) remain text-amendments to the
empirical regime; the Lean theorem captures the bound shape
which holds in both regimes — the regime distinction is
about which empirical fit constants apply, not about whether
the bound shape itself holds.

**Next Lean priority.** Theorem 2 — LL-019 side-channel
timing indistinguishability per round-3 §1D.v priority 2.
Builds atop the Mathlib environment integrated at L1 (uses
`Mathlib.Probability` content). Sequenced in a future version
pass; not gated on this commit.

**Files touched this version:**

- `src/lean4/LavaLamp/Theorems.lean` — L1 `sorry` removed;
  proof body lands; `0 ≤ proj` hypothesis dropped from
  signature; comment block updated to document the proof
  approach + the hypothesis-drop rationale; `scaffold_tier`
  string bumped from "0.0.47 sorry-stubbed" to "0.0.48
  proved".
- `LAVALAMP_SPEC.md` — LL-021 evidence type `benchmarked` →
  `lean-proved`; status `:benchmarked` → `:proved`; new "Lean
  theorem proved" footer; Counts section updated to
  27/1/3/0/4/18/1.
- `artifact_registry.md` — version line bump; LL-021 row
  evidence-type column `benchmarked` → `lean-proved` and
  status column `:benchmarked` → `:proved`; Lean theorem-file
  pointer rendered as the primary Test/Proof entry; counts
  section updated; A1-A6 self-check refreshed for 0.0.48.
- `dashboard.md` — last-updated stamp; spec-status section
  count flip; Recent companion docs section gets new top
  entry.
- `changelog.md` — this entry.
- `README.md` — count breakdown table flip; trajectory entry
  for 0.0.48.
- `src/lean4/README.md` — first-theorem status updated from
  "sorry-stubbed at 0.0.47" → "proved at 0.0.48".

---

## 0.0.47 — 2026-05-06 — Synthesis-team round 3 Lean L1 (Mathlib v4.29.1 integration + LL-021 theorem-statement landed sorry-stubbed)

Lands Lean L1 per round-3 §1D.v Decision 1 (Aaron rendered
2026-05-06: Option A — full Mathlib, theorem 1 = LL-021
worst-case bound). The pass integrates Mathlib v4.29.1 into
the previously-scaffold-only Lean track at `src/lean4/` and
ports the comment-block placeholder in `LavaLamp/Theorems.lean`
to a real (sorry-stubbed) theorem statement.

**L1 vs L2 split (intentional):** L1 is "Mathlib integration
+ theorem-statement landed (sorry-stubbed)"; L2 is "proof
body fills the sorry; status promotes to `:proved`." The
split keeps each commit's diff focused — L1's commit is
infrastructure (toolchain, lockfile, lakefile, theorem
statement), L2's commit is purely a proof-body edit. Per
CLAUDE.md §Honest framing, a sorry-stubbed theorem is **not**
a proof; LL-021 stays at `:benchmarked` until L2 lands.

**Toolchain bump (`src/lean4/lean-toolchain`):**
`leanprover/lean4:v4.18.0` → `leanprover/lean4:v4.29.1`.

- **Why:** Darwin 25 (macOS 25+) hit a dyld linker error on
  the v4.18.0 prebuilt cache binary:
  `__DATA_CONST segment missing SG_READ_ONLY flag`. The
  v4.29.1 release ships with the macOS-25-compatible binary
  and matches the system Lean install (`/opt/homebrew/bin/lake
  --version` → `Lake version 5.0.0-src+f72c35b (Lean version
  4.29.1)`).
- **Mathlib alignment:** Mathlib v4.29.1 (the Mathlib release
  tagged for Lean 4.29.1) ships with the same toolchain — no
  version conflict. The toolchain bump and the Mathlib pin
  are co-versioned.

**Mathlib integration (`src/lean4/lakefile.lean` +
`src/lean4/lake-manifest.json`):**

- **`lakefile.lean`** gains `require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @
  "v4.29.1"`. Header comment block updated to document the
  Mathlib integration round-3 round-3 §1D.v Decision 1 path
  + the `lake update` / `lake exe cache get` / `lake build`
  bootstrap recipe.
- **`lake-manifest.json`** regenerated via `lake update`
  (was 5 lines; now ~95 lines). Mathlib v4.29.1 pinned plus
  8 transitive deps: `plausible`, `LeanSearchClient`,
  `importGraph`, `proofwidgets`, `aesop`, `Qq`, `batteries`,
  `Cli`. Per CLAUDE.md package-management discipline, every
  dependency carries a pinned commit hash.
- **Cache populated:** `lake exe cache get` downloaded 8232
  prebuilt Mathlib `.olean` files into
  `.lake/packages/mathlib/.lake/build/`. Subsequent `lake
  build` is fast (just builds the LavaLamp module on top of
  cached Mathlib oleans).

**Theorem statement landed (`src/lean4/LavaLamp/Theorems.lean`):**

The placeholder comment block is replaced with a real Lean 4
theorem statement (sorry-stubbed body):

```lean
theorem LL021_worst_case_bound
    {ε_A : ℝ} {proj : ℝ}
    (h_ε : 0 ≤ ε_A)
    (h_proj_nn : 0 ≤ proj)
    (h_proj_le_one : proj ≤ 1) :
    ε_A * proj ≤ ε_A := by
  sorry
```

The theorem captures the bound *shape*: the effective
adversary magnitude after projection onto the worst-case
direction (`ε_eff = ε_A · proj`) cannot exceed the
unprojected magnitude `ε_A`. The detection-probability bound
`P(detect) ≥ 1 - K · exp(-c · T · ε_eff²)` from LL-006 then
composes with this — as `proj → 1` the adversary aligns with
the worst-case direction parallel to the mean-coupling
vector, and detection probability rises. The empirical fit
constants (`K=1, c′=0.0288, T=60` at N=20, n=15 trials per
point) live at the `:benchmarked` tier and are not part of
the Lean theorem at L1; subsequent theorems (LL-006 detection
bound; LL-019 timing-indistinguishability; LL-020 ε-DP) build
atop this Mathlib-integrated environment.

**Round-3 amendment alignment:** the theorem comment block
documents the LL-021 round-3 amendments (finite-N scope-limit
+ adaptive-adversary bound) — this theorem applies in the
finite-N regime; large-N (N ≥ 160) and adaptive-adversary
(post-observation direction choice) are spec-text scope-notes
that the Lean theorem captures by stating the bound *shape*
and leaving the regime-specific empirical content to the
`:benchmarked` tier.

**Build verification:**

```
$ cd src/lean4 && lake build
⚠ [765/767] Built LavaLamp.Theorems (4.5s)
warning: LavaLamp/Theorems.lean:90:8: declaration uses `sorry`
✔ [766/767] Built LavaLamp (731ms)
Build completed successfully (767 jobs).
```

767 jobs green; single expected `sorry` warning on
`LL021_worst_case_bound`. The build hits Mathlib's prebuilt
cache for the dependency graph; only the LavaLamp module
itself recompiles.

**CI workflow (`.github/workflows/lean.yml`):**
`timeout-minutes` bumped 15 → 60. `lean-action` invokes
`lake exe cache get` automatically before `lake build`, but
on a fresh ubuntu runner the Mathlib cache download (~8k
oleans, ~hundreds of MB) takes meaningfully longer than the
pre-Mathlib scaffold build. 60 minutes absorbs the worst-case
download + first-build window. Header comment block updated
to document the Mathlib integration timeline.

**Counts:** **unchanged** at 27/0/3/0/5/18/1. The L1 landing
does not promote LL-021 — sorry-stub ≠ proof. L2 (next
version, 0.0.48) flips the count: 27/0/3/0/5/18/1 →
27/1/3/0/4/18/1 (LL-021 :benchmarked → :proved; +1 :proved /
−1 :benchmarked).

**Files touched this version:**

- `src/lean4/lean-toolchain` — toolchain bump v4.18.0 → v4.29.1.
- `src/lean4/lakefile.lean` — Mathlib `require` line added;
  header comment block expanded with Mathlib bootstrap notes.
- `src/lean4/lake-manifest.json` — regenerated with Mathlib
  v4.29.1 + 8 transitive deps pinned (was empty at scaffold
  tier).
- `src/lean4/LavaLamp/Theorems.lean` — comment-block
  placeholder replaced with real `LL021_worst_case_bound`
  theorem statement + `import Mathlib.Data.Real.Basic` +
  expanded round-3 amendment / theorem-priority commentary.
- `.github/workflows/lean.yml` — `timeout-minutes` 15 → 60;
  header comment block updated.
- `LAVALAMP_SPEC.md` — LL-021 entry footer added documenting
  the L1 landing.
- `artifact_registry.md` — version bump; LL-021 row gains a
  Lean theorem-file pointer in Test/Proof column; A1-A6
  self-check refreshed for 0.0.47.
- `dashboard.md` — last-updated stamp; Recent companion docs
  section gets new top entry.
- `changelog.md` — this entry.
- `README.md` — count breakdown unchanged; trajectory entry
  for 0.0.47.
- `src/lean4/README.md` — §Mathlib integration moved from
  "open round-3 architectural decision" to "Mathlib
  integrated at 0.0.47"; toolchain pin updated; round-3
  trigger conditions met.

**Next:** L2 fills the `sorry`. The proof body is expected to
be a one-liner — e.g. `exact mul_le_one_of_le_one_right h_ε
h_proj_le_one` (via Mathlib's `Mathlib.Algebra.Order.Ring`)
or `nlinarith [h_ε, h_proj_nn, h_proj_le_one]`. After L2,
LL-021 evidence-type promotes from `benchmarked` to
`lean-proved` and status from `:benchmarked` to `:proved`;
that's the first-ever LavaLamp `:proved` entry.

---

## 0.0.46 — 2026-05-06 — Synthesis-team round 3 Tier 2 spec changes (LL-027 + LL-021/LL-014 amendments)

Lands round-3 Tier 2 spec changes per the rendered Aaron-
resolution decisions in
`docs/synthesis_team_round3_companion.md` §1D.vii. Tier 2
spec-only this version; first Lean theorem (LL-021 worst-
case bound + Mathlib full per Aaron's Decision 1 — Option A)
deferred to a separate pass to give the Lean work its own
session focus (adding Mathlib + writing measure-theoretic
proofs is multi-hour work; the spec changes alone are
substantial).

**Tier 2 spec changes (this version):**

- **LL-027 — asymptotic-Lyapunov-density-invariant**
  added (Core, `benchmarked` evidence, `:benchmarked`
  status). Promotes the 0.0.30 P3e N-scaling result from a
  deployment-design rule (in the P3e companion) to a spec-
  level invariant claim. The Lorenz-96 SDE at F=8 exhibits
  linear extensive-chaos scaling: `h_KS(N) = s · N` with
  `s ≈ 0.255` per dimension across N ∈ {20, 40, 80, 160}.
  Deployment-design rule: `N* ≈ Δh* / s`; PharOS Δh*=8.0
  → N*≈32; Lazarus Δh*=4.0 → N*≈16. The 0.0.30 benchmark
  *is* the empirical evidence; no new benchmarking required
  to land the entry. Depends on LL-003 (single-attractor
  chaotic engine).
- **LL-021 round-3 amendment** (status unchanged at
  `:benchmarked`). Two-pronged scope/framing amendment:
  (a) explicit scope-limit to finite-N regime
  (operationally N ≤ 80; large-N at N ≥ 160 requires
  re-benchmarking per V-020); (b) adaptive-adversary bound
  stated explicitly — the 0.0.31 per-SDE universality result
  means one successful linear-model fit applies to all
  candidate SDEs at the same configuration. Per ChatGPT
  §1C.A4 critique that LL-021 is a containment bound, not
  closure of A6.
- **LL-014 round-3 amendment** (status unchanged at
  `:argued`). Numerical-threshold non-fundamentality tie:
  the 10% FPR baseline at k=5 / n_trials=10 maps almost
  exactly to the closure_forces_structure paper §13.6's
  5-12% spurious-merge zone — same phenomenon, different
  vocabulary ("threshold ≠ structure"). The threshold is
  calibration convenience, not part of the spec's structural
  claim. Defends V-016 by making non-fundamentality
  explicit. Per ChatGPT §1C.A6.

**Counts:** 26/0/3/0/4/18/1 → 27/0/3/0/5/18/1 (+LL-027
:benchmarked).

**Spec-section heading update:** "Surfaced by synthesis-
team round 3 (0.0.45)" → "(0.0.45+)" to acknowledge multi-
version round-3 series.

**First Lean theorem path (next version, expected 0.0.47):**
Lake `require` for Mathlib added to `src/lean4/lakefile.lean`;
`lake update` regenerates `lake-manifest.json` with Mathlib
pinning; `LavaLamp/Theorems.lean` placeholder replaced with
real theorem statement for LL-021 worst-case bound. Per Grok
§1B.Q5 + Aaron's Decision 1 — Option A: full Mathlib;
theorem 1 is the LL-021 worst-case bound; theorem 2 (Closure
Detection Soundness over LL-007 + LL-014 + LL-021 interplay)
will be added atop theorem 1's environment, with custom DS-
machinery introduced as needed. CI workflow at
`.github/workflows/lean.yml` will pull Mathlib on first
build.

**Tier 3 unchanged from 0.0.45 plan:** LL-028 (runtime
conformance) + LL-029 (multi-channel entropy independence)
+ LL-019 deployment-context expansion. Sequenced by P-RS
Level 2 prototype availability.

**Files touched this version:**

- `LAVALAMP_SPEC.md` — LL-027 entry added; LL-021 + LL-014
  notes amendments appended; section heading updated to
  "(0.0.45+)"; Counts section updated.
- `artifact_registry.md` — version bump; LL-027 row added;
  counts updated; A1-A6 self-check refreshed for 0.0.46.
- `dashboard.md` — last-updated stamp; spec-status section
  updated; Recent companion docs section gets new top entry.
- `changelog.md` — this entry.
- `README.md` — count refresh; trajectory entry for 0.0.46.

Test suite unchanged at 202/202 (Tier 2 spec changes are
governance only; no new code). Cross-audit A1-A6 passes
post-edit.

---

## 0.0.45 — 2026-05-06 — Synthesis-team round 3 Tier 1 (LL-025 + LL-026; V-014..V-020 enumerated)

Lands round-3 Tier 1 spec changes per the rendered Aaron-
resolution decisions in `docs/synthesis_team_round3_companion.md`
§1D.vi. Round 3 ran a seat rotation: Gemini (round-2
synthesis) was struggling on the round-3 task and stepped
out; Grok rotated edge-witness → synthesis; ChatGPT joined
as new edge-witness entrant. Both seats responded
substantively. Verdicts: Grok (synthesis) `engage-and-
formalise-after-fixes`; ChatGPT (edge-witness)
`pass-after-fixes` — complementary lenses, neither says fail.

**Aaron's three resolution decisions (rendered 2026-05-06):**

1. **V-021 / V-022 disposition: MERGE.** V-021 (Prefix-
   Trajectory Mimicry) absorbs into V-015 as the attack-
   mechanism axis; V-022 (Threshold Equivalence Exploit)
   absorbs into V-016 as the language axis. Net new V-IDs
   after merge: 7 (V-014 through V-020).
2. **Tier sequencing: confirm default.** Tier 1 (this
   version) → Tier 2 (paired with first Lean theorem) → Tier
   3 (engineering availability).
3. **Lean first theorem + Mathlib: Option A.** LL-021 worst-
   case bound; Mathlib full. Theorem 2 will be Closure
   Detection Soundness atop theorem 1's environment.
   ChatGPT's adaptive-adversary critique handled in spec text
   via Tier 2 LL-021 amendment, not Lean.

**Tier 1 changes (this version):**

- **LL-025 — A7-passive-emanation-boundary.** New Boundary
  entry (`:argued`). Tier-bounded scoping declaration:
  state-actor / mid-tier / commodity. Forms a parallel
  boundary triple with LL-015 (downward — A3 OOS) and
  LL-024 (operational — sensor instantiation). Three closure-
  of-three groupings now in spec: deployment-stack triple
  (LL-022 / LL-023 / LL-024) + adversary-scoping triple
  (LL-015 / LL-024 / LL-025). Defends V-014 by tier-bounded
  scoping rather than universal defense.
- **LL-026 — three-layer-logic-tier-annotation-discipline.**
  New Core (governance) entry (`:argued`). Spec-level
  governance: every LL entry tagged Possibilistic /
  Probabilistic / Bridge per closure_forces_structure paper
  §1.2. Defends V-017 logical-tier-confusion attacks by
  construction. Per-entry annotation pass on existing
  LL-001..LL-024 deferred to follow-up small-session.
- **V-014..V-020 enumerated** in
  `docs/attack_surface_enumeration.md`. Seven new attack
  vectors:
  - V-014 — Passive-emanation reconstruction (LL-025
    surface).
  - V-015 — Cross-sector autopoiesis spoofing (paper-derived;
    LL-006 / LL-007 limitation; absorbs the V-021 prefix-
    trajectory mimicry mechanism axis).
  - V-016 — Numerical-threshold calibration gaming (paper-
    derived; LL-014 / LL-026 surface; absorbs the V-022
    threshold-equivalence-exploit language axis).
  - V-017 — Three-layer logical-tier confusion (LL-026
    surface).
  - V-018 — Coordinated multi-sensor synthesis (LL-029
    future, Tier 3).
  - V-019 — Runtime conformance bypass (LL-028 future,
    Tier 3).
  - V-020 — Stable-manifold stealth injection (LL-021
    amendment, Tier 2).
- **§4 adversary × vector matrix** updated with V-014..V-020
  rows.
- **§5 residual risks** extended with entries 10-13 covering
  V-014 (LL-025 tier-bounded), V-018 (LL-029 pending —
  largest engineering gap post-round-3), V-019 (LL-028
  pending), V-020 (LL-021 amendment pending).

**LL-008 cost-asymmetry footer** already landed in 0.0.42 —
no additional change needed. Grok §1B.Q1 ratified the
existing footer as the load-bearing framing.

**Counts:**

- Total: 24 → 26 (+LL-025 +LL-026)
- `:argued`: 16 → 18 (+LL-025 +LL-026)
- Other counts unchanged: `:proved` 0; `:tested` 3 (LL-002,
  LL-004, LL-007); `:verified` 0; `:benchmarked` 4 (LL-003,
  LL-006, LL-019, LL-021); `:open` 1 (LL-015 permanent).
- Attack vectors: V-001..V-013 + V-014..V-020 = 20 enumerated
  total (V-021 absorbed into V-015; V-022 absorbed into V-016).

**Spec growth path next:**

- **Tier 2 (next version, paired with first Lean theorem):**
  LL-027 (asymptotic Lyapunov density invariant `s ≈ 0.255`
  per dimension; promotes 0.0.30 N-scaling result to spec-
  level invariant) + LL-021 scope-limit (finite-N regime,
  N ≤ 80) + adaptive-adversary amendment + LL-014 numerical-
  threshold non-fundamentality tie. First Lean theorem:
  `theorem ll021_worst_case_bound : ε_eff ≤ ε_A * proj`
  with full Mathlib measure-theoretic environment.
- **Tier 3 (engineering availability):** LL-028 (runtime
  conformance verification — defends V-019) + LL-029 (multi-
  channel entropy independence — defends V-018) + LL-019
  deployment-context expansion (shared-env constant-time
  padding requirement). Sequenced by P-RS Level 2 prototype
  scope.

**Files touched this version:**

- `LAVALAMP_SPEC.md` — new L2 section "Surfaced by synthesis-
  team round 3 (0.0.45)"; LL-025 + LL-026 entries added;
  Counts section updated.
- `artifact_registry.md` — version bump; new section + rows
  for LL-025 / LL-026; counts updated; A1-A6 self-check
  refreshed.
- `dashboard.md` — last-updated stamp; spec-status section
  updated; Recent companion docs section gets new top entry.
- `changelog.md` — this entry.
- `docs/attack_surface_enumeration.md` — V-014..V-020
  entries inserted before §4; §4 matrix extended; §5
  residual risks extended.
- `README.md` — count refresh.

Test suite unchanged at 202/202 (round-3 Tier 1 is spec /
governance only; no new code). Cross-audit A1-A6 passes
post-edit.

---

## 0.0.44 — 2026-05-05 — Round-3 brief engine-side blanks filled (forward-ready)

Fills the engine-side `[FILL: ...]` blanks in the round-3
forward-brief with project-private context (substance of the
fill is redacted from the public record; the synthesis is
captured in `synthesis_team_round3_companion.md`).

Round-3 ready-state achieved: with both paper-side (0.0.43)
and engine-side (0.0.44) blanks filled, the brief is forward-
ready for synthesis-team review.

**V-NNN tag collision rationalized.** The skeleton's §4 A7
added V-014 (passive-emanation EMF) at 0.0.40; the §4 A6
paper-side fill at 0.0.43 also tagged its first candidate
V-014 (cross-sector autopoiesis spoofing). Collision
resolved at 0.0.44:

- V-014: passive-emanation EMF (came first; keeps the tag).
- V-015: cross-sector autopoiesis spoofing (was V-014).
- V-016: numerical-threshold calibration gaming (was V-015).
- V-017: three-layer logical-tier confusion (was V-016).

V-NNN allocation post-rationalization:
- V-001..V-010: original (`attack_surface_enumeration.md`).
- V-011/012/013: round-2 additions.
- V-014..V-017: round-3 candidates (V-014 EMF; V-015..V-017
  paper-derived).

Counts unchanged at 24 / 0 / 3 / 0 / 4 / 16 / 1. Test suite
202/202 unchanged.

### Changed

- Round-3 forward-brief — engine-side §1 paragraph filled;
  §2 reading-list item 8 filled; §4 A6 V-NNN renumbering
  applied (V-014→V-015, V-015→V-016, V-016→V-017; §4 A7
  V-014 unchanged); top-of-doc and internal-note updates.
- **`LAVALAMP_SPEC.md`** — version 0.0.43 → 0.0.44.
- **`artifact_registry.md`** — version 0.0.43 → 0.0.44.
- **`dashboard.md`** — version 0.0.43 → 0.0.44; Recent
  companion docs section refreshed with the V-NNN
  rationalization note.
- **`README.md`** — version trajectory extended.

### Why

1. **Round-3 trigger now zero-friction.** With both paper-
   side and engine-side blanks filled, Aaron forwards the
   brief to the synthesis-team seats at his discretion. No
   further pre-trigger work needed.
2. **V-NNN tag discipline.** Two V-014 candidates emerging
   from independent fills was a real collision; resolved by
   first-come-first-served with paper-derived candidates
   renumbered. The integration commit makes the V-NNN
   allocation internally consistent.

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.43 — 2026-05-05 — Round-3 brief paper-side blanks filled (closure_forces_structure v1.0 paper-grounded)

Fills the paper-side `[FILL: ...]` blanks in the round-3 brief
landed at 0.0.39 (skeleton) + 0.0.40 (Q7/A7 EMF). Aaron
2026-05-05: *"paper done. almost done with engine."*

The `closure_forces_structure` paper is at **v1.0 2026-04-01**
(public release tag; *"Closure Forces Structure: The Standard
Model from Rosen Closure on Ternary Causal Hypergraphs"*).
What's new for round-3 is **stability-of-corpus**, not paper
revisions — LavaLamp inherits structural priors from a *settled*
canonical paper rather than a moving target. This is *better*
news than the skeleton's "post-paper-update" framing assumed.

**Three load-bearing paper section clusters** captured in the
fill:

1. **§10.5 The C-Closure and Q_48** — formal definition:
   `Q_C = Q ∪ C(Q)` where `C(Q)` is the charge-conjugate
   copy. `Q_48 = Q_24 ∪ C(Q_24)` has 48 vertices, **zero
   overlap between original and conjugate sectors**, perfect
   fixed-point-free real structure J. This is the formal
   mathematical operation behind LavaLamp's "C-conjugate
   adversary inheritance" claim.
2. **§11.13 The Self-Reproducing Fixed Point** — `Q_102 =
   Q_51 ∪ C(Q_51)` is autopoietic in the strong sense: all
   420 composition products map back to existing Q_102
   vertices (100%); 5/5 ICs; depth-independent at depths
   2-4. Quote: *"The daughter IS the parent. Q_102 does not
   produce offspring that inherit its properties; it
   produces itself."* This is the structural anchor for
   LavaLamp's substrate-bound identity claim.
3. **§13.6 Evidence Classification and Honest Framing** —
   five evidence types (proof / algebraic / standard /
   catlab / computational) directly parallel to LavaLamp's
   CLAUDE.md §Evidence types. Quote: *"A Julia computation
   using `Rational{BigInt}` is a proof; the same computation
   using `Float64` is evidence."* — same discipline as
   LavaLamp's "Float64 is computational evidence" rule.

Plus §1.2 three-layer logic structure (Possibilistic /
Probabilistic / Bridge) for LavaLamp claim-tier review, and
§13.6 numerical-threshold remark (5%-12% spurious merges at
0.999 vs 200/200 canonical at 1-10⁻¹²) mapping onto LL-014
threshold calibration discipline.

**Three V-NNN candidates surfaced from the paper's framing:**

(a) V-014 — Cross-sector autopoiesis spoofing. Edge-witness
    A6 question.
(b) V-015 — Numerical-threshold calibration gaming
    (LL-014 analog of paper's 5%-12% spurious merges).
(c) V-016 — Three-layer logical-tier confusion attack
    (paper's §1.2 *"category errors"* warning applied to
    LavaLamp's claim-tier mix).

Synthesis seat Q1 reframed post-paper-read into three sub-
questions on structural-transfer-vs-vocabulary, "daughter
IS the parent" mapping, threshold robustness. Edge-witness
A6 reframed with paper-derived attack-vector candidates.

**Engine-side blanks remain pending engine completion.**
When engine lands, ~15-30 min fills §1 engine paragraph + §2
reading-list item 8 + rationalizes V-NNN tags (the §4 A7
V-014 EMF candidate collides with the §4 A6 V-014 cross-
sector candidate; integration commit reassigns).

Counts unchanged at 24 / 0 / 3 / 0 / 4 / 16 / 1. Test suite
202/202 unchanged.

### Changed

- Round-3 forward-brief — paper-side fill:
  - §1 paper-side paragraph (~1500 words; three section
    clusters + three-layer logic + numerical-threshold remark).
  - §2 reading-list item 1 (file paths + section pointers).
  - §3 Q1 reframed (sub-questions a/b/c).
  - §4 A6 reframed (three V-NNN candidates).
  - Top-of-doc 2026-05-05 update note documenting the 0.0.43
    fill.
  - Internal note at bottom reflecting paper-side substantively
    complete; engine-side pending.
- **`LAVALAMP_SPEC.md`** — version 0.0.42 → 0.0.43 (no entry
  changes).
- **`artifact_registry.md`** — version 0.0.42 → 0.0.43.
- **`dashboard.md`** — version 0.0.42 → 0.0.43. Recent
  companion docs prepended with substantive description of
  the fill.
- **`README.md`** — version trajectory extended.

### Why

1. **Paper is at v1.0 (settled).** The skeleton's framing
   assumed a paper update was pending; in fact the paper has
   been canonically published since April. The fill captures
   the published-corpus content, not anticipated revisions.
   Better news than expected.
2. **Honest-framing discipline confirmed corpus-faithful.**
   The paper's §13.6 evidence taxonomy directly mirrors
   LavaLamp's CLAUDE.md §Evidence types. The "Float64 is
   evidence; Rational{BigInt} is a proof" principle
   transfers to LavaLamp's own discipline (manual / property-
   tested / example-tested / benchmarked / lean-proved /
   type-checked / algebraic / none).
3. **V-NNN candidates surfaced.** Three new attack-vector
   candidates emerged from the paper's framing (V-014/015/016)
   that V-001..V-013 didn't capture. The edge-witness seat
   weighs which are real vs theoretical.
4. **Round-3 readiness improved.** With paper-side filled,
   the brief is now ~85% complete; only engine-side blanks
   remain. Round-3 trigger response time drops further from
   "30-60 min of paper + engine work" to "~15-30 min of
   engine-only work."

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.42 — 2026-05-05 — Threat-landscape companion §2.6/§2.7 (metabolic-value / predator-prey ecology axis)

Adds the **metabolic-value / predator-prey ecology axis** to
the threat-landscape companion landed in 0.0.41. Aaron 2026-05-05
(post-§2.5): *"the metabolic value of the target. If the defense
is such that it is not worth the risk for the attacker (not
enough value) they will go find something else. This is how we
achieve symbiosis in the ecosystem. Lions and Gorillas...
Hyenas and Lions... there are spats sure but they find their
easy food to eat."*

This is a third axis orthogonal to (a) scale (cockroach vs
catapult) and (b) defensive architecture (castle/membrane/
immune system). The new axis is the *attacker's cost-benefit
calculation* — most attackers don't bother because the math
doesn't favor it; symbiosis is the default; adversarial
response is the exception even at the bacterial-immune-
system level (the immune system *digests and incorporates*
most non-self; only attacks pathogens that threaten the
metabolic budget).

§2.7 reframes LavaLamp's security claim explicitly as
**cost-asymmetry** — "attacking this device costs more than
the result is worth, relative to easier targets." This is
*exactly* what LL-008 (resolution-bounded security) says
implicitly; the threat-landscape framing makes it explicit
and connects to the rest of the corpus (Possibilistic
Security raising costs of unsanctioned alternatives;
cordon-sanitaire structural cost-multiplication; asymmetry-
trap watch as cost-vs-claim discipline; detection-postured
QKD/PQC framing).

Translations across the threat tiers:
- Cockroach: modest defense exceeds tiny budget; trivially
  repelled.
- Catapult: some attacks ARE economically justified for
  state actors; defender's job is to *not be the cheapest
  catapult target*.
- State-level: structural disconnection (cordon sanitaire)
  is the answer; or don't be the highest-value target in
  the room.
- Symbiotic: default for most actors; mutualistic-or-neutral.

Counts unchanged at 24 / 0 / 3 / 0 / 4 / 16 / 1. Test suite
202/202 unchanged.

### Added

- **`docs/threat_landscape_companion.md`**:
  - §2.6 — Metabolic value and the predator-prey ecology
    (~700 words). Lions/Gorillas; Hyenas/Lions; Wolves/Bears
    examples + bacterial-immune-system parallel (gut
    microbiome; symbiosis as default; adversarial response
    as exception).
  - §2.7 — Asymmetric cost as the security claim — symbiosis
    as equilibrium (~900 words). Reframes LavaLamp's claim
    as cost-asymmetry; translations across threat tiers;
    practical implications for the Triad Deployments
    (high-value targets need more; low-value need less;
    defender attractiveness matters; defense-in-depth =
    cost amplification).
  - §6 Q8 — Should the spec articulate adversary-cost /
    target-value calculus explicitly? Three options: (a)
    explicit Cost-Asymmetry Boundary entry, (b) LL-008
    footer (taken in this commit as minimum honest framing),
    (c) deployment-context-only.
  - §7.6 lesson — Symbiosis is the equilibrium goal, not
    victory. The corpus's autopoietic-closure principle at
    predator-prey level: maintain metabolic conditions
    under which most enemies don't bother + detect the rare
    ones who do.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.41 → 0.0.42. LL-008
  gains a "Cost-asymmetry framing (2026-05-05, 0.0.42)"
  footer cross-referencing the new §2.7. The
  resolution-bounded-security claim IS a cost-asymmetry claim
  formalised; the footer makes this explicit. No status
  changes.
- **`docs/threat_landscape_companion.md`** — version stamp
  bumped to 0.0.42 with §2.6/§2.7 inclusion noted in the
  cross-ref'ing internal description.
- **`artifact_registry.md`** — version 0.0.41 → 0.0.42
  (companion-update bump; no row changes).
- **`dashboard.md`** — version 0.0.41 → 0.0.42. Recent
  companion docs prepended with substantive description of
  the §2.6/§2.7 update.
- **`README.md`** — version trajectory extended.

### Why

1. **The metaphor was incomplete.** The cockroach/catapult/
   castle/immune framing described *how the defender works*
   but not *why most attackers don't bother*. The metabolic-
   value axis fills that gap.
2. **It's corpus-deep.** Predator-prey symbiosis maps
   directly onto Possibilistic Security's cost-asymmetry
   discipline + the autopoietic-closure principle expressed
   at the ecological level. Same shape; different register.
3. **It reframes the security claim honestly.** LavaLamp's
   claim isn't "we beat all attackers" — it's "attacking
   this device is more expensive than the result is worth."
   This is what LL-008 already says; making it explicit is
   honest framing discipline.
4. **It changes the practical conclusion about defense-in-
   depth.** Defense layers aren't about perimeter
   strengthening; they're about *cost amplification*. No
   single layer needs to be invincible — the sum needs to
   exceed the attacker's budget.

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.41 — 2026-05-05 — Threat-landscape companion (cockroach/catapult/castle framing)

Lands `docs/threat_landscape_companion.md` as the
**meta-architectural framing for the Triad Deployments —
the context within which Lazarus / LavaLamp / PharOS exist
as defenders.** Surfaced 2026-05-05 in conversation: *"lavalamp
is important but we need to frame the context IN WHICH it is
important... the triadic watchmen totally miss [EMF]."*

The companion uses Aaron's cockroach/catapult/castle/immune-
system metaphor as the load-bearing frame:

- **Cockroach-class threats** — small-scale, persistent,
  opportunistic. Phishing, composability seams, slow-drift
  threshold gaming, long-term substrate drift, standard
  malware. Cannot afford catapult-tier capability; lives in
  the gaps and seams.
- **Catapult-class threats** — large-scale, resourced,
  barrier-breaking. TEMPEST/passive-emanation (A7), supply-
  chain interdiction, cryptographic primitive failure,
  Q-Day. State-level capability tier; rare lower.
- **Combined catapult+cockroach** — the rare-and-lethal
  intersection. State-level actors (NSA TAO, MSS, GRU) who
  can deploy catapults AND maintain cockroach-tier
  persistence. Ruin-class-risk threat tier per
  `feedback_cordon_sanitaire.md`.
- **Castle/membrane/immune system** — the defensive
  architecture. Identity is constituted by the immune
  system's ongoing activity, not by a static credential.
  Maps directly onto Possibilistic Security's autopoietic-
  closure principle. Defeat conditions: scale domination
  or virus/cancer injection (the C-conjugate adversary
  problem).

§3 maps the Triad Deployments onto the metaphor:
- LavaLamp = identity foundation (what makes the castle yours)
- PharOS = membrane checkpoint at the OS layer
- Lazarus = inner sanctum / substantive backend

§4 honestly catalogs:
- Within scope: A1-A6 software-stack adversaries (mostly
  cockroach-class; catapult-class A4/A5 partially)
- Out of scope at primitive tier: A7 passive-emanation,
  active substrate manipulation, software supply-chain,
  social/governance/legal compulsion, cryptographic primitive
  failure, operational/user error, composability seams,
  long-term substrate drift, quantum threat horizon
- 8 load-bearing assumptions named explicitly (§4.3)

§5 complementary defenses across four tiers (hardware /
software / operational / strategic — including the
cordon-sanitaire discipline for ruin-class-risk).

§6 surfaces 7 round-3 questions beyond the existing Q7/A7:
- Supply-chain integrity boundary entry?
- Substrate-stability boundary entry?
- Composability-seam discipline at the spec level?
- Quantum-threat horizon framing?
- Closure-of-N at multiple scales (does the corpus's
  closure-of-three philosophy generalise)?

§7 captures five lessons including "the corpus's defensive
principle is structurally faithful" (the metaphor maps onto
autopoietic-closure rather than borrowing from elsewhere)
and "state-level threats require structural responses, not
just better defenses."

**No new spec entries.** The companion is meta-architectural;
round-3 may surface LL-025+ from the §6 questions. Counts
unchanged.

### Added

- **`docs/threat_landscape_companion.md`** (~25 KB).
  Substantive design companion mirroring the P-OS / P-PharOS
  / P-RS scoping-pass shapes but at the meta-architectural
  layer — frames the threat landscape that the existing
  LL-IDs collectively occupy.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.40 → 0.0.41. LL-015,
  LL-018, LL-022 each gain a "Threat-landscape framing
  (2026-05-05, 0.0.41)" footer cross-referencing the
  companion. No status changes; counts unchanged.
- **round-3 forward-brief** — §2 reading list
  gains a new entry (3a) pointing to the threat-landscape
  companion as required reading for the synthesis seat.
- **`artifact_registry.md`** — version 0.0.40 → 0.0.41
  (companion bump; no row changes).
- **`dashboard.md`** — version 0.0.40 → 0.0.41. Recent
  companion docs prepended with substantive description.
- **`README.md`** — version trajectory extended.

### Why

1. **The framing was load-bearing and missing.** The session
   arc 0.0.20 → 0.0.40 was substantively bottom-up — specific
   entries refined, scoping passes landed, test discipline
   tightened. Aaron's 2026-05-05 observation surfaced that
   the *context* (what threat landscape the work occupies)
   was implicit; without it, the spec's individual entries
   sit in a context that exists only in the architects' heads.
2. **The metaphor is corpus-honest.** Cockroach/catapult/
   castle/immune-system maps directly onto Possibilistic
   Security's autopoietic-closure principle and the C-conjugate
   adversary structure from the closure_forces_structure paper. This isn't a marketing
   layer pasted onto technical work — it's the same principle
   in a register accessible to non-technical readers.
3. **Round-3 readiness improved.** The synthesis-team seats
   now have a top-down framing to engage with, not just the
   LL-ID-by-LL-ID detail. The brief's Q1-Q7 / A1-A7 questions
   are sharper when reviewed against the threat-landscape
   context.
4. **Honest threat-tier discipline.** §4 explicitly lists
   what the Triad Deployments *don't* defend against. This
   matches the spec's existing bounded-claim discipline
   (LL-005, LL-008, LL-018) at the threat-landscape level.

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.40 — 2026-05-05 — Round-3 brief Q7 + A7 (EMF / A7 / LL-025 gap surfaced post-skeleton)

Adds Q7 (synthesis seat) + A7 (edge-witness seat) to the
round-3 brief skeleton landed in 0.0.39, covering the
**EMF / passive-emanation-adversary gap** surfaced in
conversation 2026-05-05. Aaron's observation: *"the triadic
watchmen totally miss that concept."*

The gap, articulated:

- The Triadic Watchmen (Lazarus / LavaLamp / PharOS) cover
  the software stack — Lazarus is the existing backend with
  utilitarian UI; LavaLamp is the substrate-bound primitive;
  PharOS is the OS-level consumer.
- All three live above the OS abstraction layer.
- LL-022 covers OS-level dependencies (TPM, sensor APIs,
  TRNG, isolation); LL-023 covers consumer-API surfaces;
  LL-024 covers real-sensor instantiation strategy.
- **None of them touch the physical substrate's
  electromagnetic emanations.** A passive-emanation
  adversary (call it A7) in physical proximity could in
  principle reconstruct the SDE trajectory directly from CPU
  / memory bus / USB / HDMI radiated emissions, bypassing the
  entire residue audit / TPM / sensor authenticity / verifier
  stack at the physical layer.

Q7 (synthesis seat) lays out three architectural options:
(a) new Boundary entry **LL-025** —
physical-emanation-adversary-boundary, parallel to LL-015
A3-OOS, articulating required deployment context (Faraday /
TEMPEST / distance / EMI-filtered power / shielded cables)
for LavaLamp's primitive-tier claim to hold; A7 OOS outside
those bounds;
(b) sub-claim of LL-022 + sub-class of A4 — fold into
existing entries;
(c) defer to deployment-time documentation — leave spec
untouched.

Q7 also asks whether the deployment-stack triple LL-022 +
LL-023 + LL-024 needs to extend to a quartet (+ LL-025), and
whether the closure-of-three philosophy survives — or whether
LL-025 forms a parallel boundary triple with LL-015 + LL-024
covering the substrate at the physical layer.

A7 (edge-witness seat) asks whether passive-emanation
reconstruction is realistic at modern multi-GHz CPU speeds
and what capability tier (close-proximity-state-actor /
mid-tier-SDR / wide-spread) bounds A7. Real research has
demonstrated cryptographic key extraction from acoustic
emanations (Genkin et al. 2014), memory state recovery from
EM (RowHammer-via-EMF), and CPU register state under specific
conditions. The question is whether full or partial
trajectory reconstruction is feasible at LavaLamp's
deployment scales.

**Round-3 deliverable:** synthesis + edge-witness seats
weigh in on whether A7 is a load-bearing addition to the
spec; if yes, what's the right LL-NNN structure; if no,
what's the deployment-context recommendation.

### Added

- **round-3 forward-brief** — Q7 (synthesis
  seat) + A7 (edge-witness seat). Top-of-doc 2026-05-05
  update note documenting the addition. §5 word cap raised
  2500 → 2800. §5 "six-point evaluation" → "seven-point
  evaluation". Internal note at bottom updated to 0.0.40
  status (Q1-Q7 / A1-A7).

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.39 → 0.0.40 (brief
  update bump; no entry changes).
- **`artifact_registry.md`** — version 0.0.39 → 0.0.40 (brief
  update bump; no row changes).
- **`dashboard.md`** — version 0.0.39 → 0.0.40. Recent
  companion docs prepended with the Q7+A7 update note.
- **`README.md`** — version trajectory extended.

### Why

1. **Real architectural gap.** The Triad Deployments
   collectively cover the software identity stack but the
   physical-emanation layer is genuinely outside the current
   spec. An A7-class adversary doesn't need root, doesn't
   need to defeat the residue audit, doesn't need to spoof
   sensors — they just listen to the substrate. This is
   structurally distinct from A4 (software side-channels)
   and warrants explicit treatment.
2. **Round-3 is the right venue.** Pre-committing to a
   specific LL-025 design before round-3 risks the
   synthesis + edge-witness seats arriving at a different
   architecture. Surfacing the question in the brief lets
   round-3 produce the resolution.
3. **No spec changes pre-trigger.** The brief update is a
   question, not a commitment. Counts unchanged; LL-024
   stays as the most-recent spec entry; LL-025 lands (or
   doesn't) as a round-3 deliverable.

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.39 — 2026-05-04 — Round-3 brief skeleton (pre-trigger preparation)

Lands round-3 forward-brief as **parallel-safe
pre-trigger preparation** for the imminent round-3 synthesis-
team review. The brief skeleton is substantively complete on
the LavaLamp side; paper-specific and engine-specific blanks
(marked `[FILL: ...]`) get filled when the
`closure_forces_structure` paper update lands and round-3
actually triggers.

**Net result.** Round-3 trigger response time drops from
"several hours of brief composition" to "fill paper-side
blanks (~30-60 min) and forward." The brief mirrors the
round-2 brief's shape (`docs/synthesis_team_round2_brief.md`)
with content drawn from the nine accumulated architectural
inputs documented in `docs/audit_2026-05-04_full.md` §9.

No spec entry changes; counts unchanged at 24 / 0 / 3 / 0 /
4 / 16 / 1. Test suite 202/202 unchanged.

### Added

- **round-3 forward-brief** (~14 KB).
  - **§1 What changed since round 2.** Two work modes:
    empirical refinement of round-2 :benchmarked cohort
    (0.0.23-0.0.32; LL-020 fix; LL-021/LL-019 high-res;
    LL-003 N-scaling; LL-006 per-SDE; LL-005 part-(a)) +
    parallel-safe scaffolding (0.0.26 P-OS; 0.0.33 visual
    layer; 0.0.34 P-PharOS; 0.0.35 cross-audit; 0.0.36 Lean
    scaffold; 0.0.37 Lean CI; 0.0.38 P-RS). Paper / engine
    paragraphs marked `[FILL: ...]`.
  - **§2 Reading list (9 items).** LavaLamp companions cited
    (audit + deployment-stack triple + :benchmarked cohort
    + empirical refinements + diagnostic notes). Paper +
    engine entries marked `[FILL: ...]`.
  - **§3 Synthesis-seat brief (Q1-Q6).** Drawn from the nine
    architectural inputs: Q1 paper revisions to C-conjugate
    inheritance; Q2 deployment-stack triple match to paper
    closure-of-three framing; Q3 LL-019 host-isolation regime-
    boundary as new spec entry vs LL-022 sub-claim; Q4 LL-005
    adversary-side mechanism choice (LL-016 sensor authenticity
    vs FFT/PSD audit vs trajectory-checkpoint); Q5 first Lean
    theorem priority + Mathlib-or-not call; Q6 N-scaling
    deployment target per Triad Deployment.
  - **§4 Edge-witness brief (A1-A6).** A1 LL-019 host-isolation
    real or methodological; A2 LL-024 cross-validation
    sufficiency against coordinated V-006; A3 deployment-stack
    triple non-conformance attack; A4 linear-coupling
    linearisability post-LL-021; A5 large-N attractor topology
    attack vectors; A6 paper-revisions blank.
  - **§5 Response format.** Mirrors round-2 (six-point
    evaluation; verdicts; net new vectors; Lean suggestions;
    paper-update integration). Word cap raised 2000 → 2500
    (broader surface).
  - **§6 Followups.** Round-3 companion (post-dialogue);
    spec impact discipline; decision point; Phase 1 real-
    sensor implementation gating; first Lean theorem
    implementation gating.
  - **Internal note** on skeleton-tier status: substantively
    complete; paper-specific blanks remain.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.38 → 0.0.39 (skeleton
  bump; no entry changes).
- **`artifact_registry.md`** — version 0.0.38 → 0.0.39
  (skeleton bump; no row changes — brief skeleton is
  pre-trigger prep, not spec evidence).
- **`dashboard.md`** — version 0.0.38 → 0.0.39. Recent
  companion docs prepended with the brief skeleton
  description.
- **`README.md`** — version trajectory extended.

### Why

1. **Round-3 trigger imminent.** Per the user note 2026-05-04:
   "physics paper is genuinely advanced and the current status
   is synced to origin." The trigger window is narrowing;
   pre-trigger work that survives the round-3-blocked content
   gate is the highest-leverage parallel-safe option in the
   current window.
2. **No round-3 commitment.** The skeleton's LavaLamp-side
   content is paper-independent (drawn from the audit §9
   architectural inputs that are LavaLamp-internal). The
   `[FILL: ...]` blanks isolate the paper-dependent content
   from the rest, so the skeleton doesn't pre-commit to
   anything round-3-blocked.
3. **Round-3 response time minimised.** When the paper update
   lands, the round-3 brief composition reduces from
   "several hours of fresh writing" to "30-60 min of blank-
   filling." The skeleton is a force multiplier on the
   round-3 trigger event.
4. **The §3 Q1-Q6 + §4 A1-A6 framing already captures the
   nine accumulated architectural inputs.** Each Q/A maps to
   one or two of the inputs from the audit §9 list; round-3
   reviewers see the LavaLamp side's questions clearly,
   regardless of what the paper update revises.

### Counts

- Total: 24 (unchanged)
- All status counts unchanged.
- Test suite: 202/202 (unchanged).

---

## 0.0.38 — 2026-05-04 — P-RS real-sensor scoping pass (LL-024 added :argued; Linux-first roadmap)

Lands the P-RS real-sensor scoping pass + scaffold module as
**parallel-safe Level-2 prototype prep work**. The current
prototype (Level 1, `src/julia/src/Sensors.jl`) uses synthetic
sensor streams; Level 2 reads actual hardware sensors via
platform-specific FFI. This pass scopes the per-platform
strategy without committing to FFI code yet (the scaffold
module errors meaningfully at every entry point pointing to
the scoping companion).

**Net result.** New entry LL-024 (real-sensor-deployment-
strategy, Operational tier, manual evidence, `:argued`) +
scaffold `src/julia/src/RealSensors.jl` with six API stubs.
LL-022 (downward) + LL-023 (upward) + LL-024 (operational
instantiation) form the **deployment-stack triple** — three-
layer architectural commitment closing the scoping question
on all three ends.

Counts: total 23 → 24; `:argued` 15 → 16. Test suite
184/184 → 202/202 (+18 scaffold-discipline assertions).

### Added

- **`docs/p_real_sensor_scoping_companion.md`** (~9 KB)
  — substantive design companion. §1 inputs (LL-004 / LL-005
  / LL-016 / LL-022). §2.1 per-platform sensor surface
  (Linux sysfs/procfs simplest first platform; macOS
  IOKit/SMC; Windows WMI). §2.2 maps surfaces to LL-004's
  six sensor categories. §2.3 sample-rate constraints with
  LL-005 nyquist_compliant compatibility table. §2.4
  authenticity strategies in real-hardware context (strategy
  2 cross-validation as prototype default; strategy 1.5
  eBPF for hardened Linux; strategy 1 TPM at P7). §2.5
  Linux-first implementation roadmap (Phase 1 ~1 week
  post-round-3; Phase 2 macOS ~2-4 weeks; Phase 3 Windows
  ~4-6 weeks; Phase 4 P7 TPM). §2.6 test strategy. §2.7
  connection to LL-022 / LL-023 (the deployment-stack
  triple). §5 four lessons.
- **`src/julia/src/RealSensors.jl`** — scaffold module
  (~150 lines). Six sensor constructors:
  `real_thermal_stream`, `real_battery_stream`,
  `real_ac_stream`, `real_usb_stream`,
  `real_cpu_governor_stream`, `real_loadavg_stream`. Each
  errors at scaffold tier with a meaningful message
  pointing to the scoping companion + suggesting a
  synthetic substitute via `gaussian_noise_stream`. Per
  CLAUDE.md "stubs that return data are forbidden" rule:
  scaffold stubs error rather than silently returning
  garbage SensorStream values. Mirrors the 0.0.36 Lean
  scaffold pattern (infrastructure-prep, not evidence).
- **Test additions in `src/julia/test/runtests.jl`** — new
  `Real-sensor scaffold (LL-024)` testset with 18
  assertions: 6 callability checks (each constructor is a
  Function), 6 error-throws checks (each errors at
  scaffold tier), 1 message-content check (error message
  references the scoping companion + LL-024); plus the
  testset header comment-block documenting the
  scaffold-discipline framing. Suite 184 → 202.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.37 → 0.0.38. New
  entry LL-024 in a new "Surfaced by P-RS real-sensor
  scoping pass (0.0.38)" section. Counts: total 23 → 24;
  `:argued` 15 → 16. Section header at bottom updated to
  reflect the deployment-stack triple framing.
- **`src/julia/src/LavaLamp.jl`** — adds `include(
  "RealSensors.jl")` after ChaosGuard; imports + re-exports
  the six new sensor constructors at the package top level.
- **`artifact_registry.md`** — version 0.0.37 → 0.0.38.
  New "Surfaced by P-RS real-sensor scoping pass (0.0.38)"
  section with LL-024 row. Counts updated. Cross-audit
  A1-A6 self-check refreshed for 0.0.38.
- **`dashboard.md`** — version 0.0.37 → 0.0.38. P-RS added
  to priority stack as a closed item (parallel to P-OS /
  P-PharOS shape). Recent companion docs prepended with
  the new companion + scaffold module description. Status
  summary captures the deployment-stack triple framing.
- **`README.md`** — spec ledger updated (24 entries; 16
  `:argued`); trajectory extended; layout section adds
  `src/julia/src/RealSensors.jl`.

### Why

1. **User asked.** "When can we prototype the lavalamp?"
   prompted an honest articulation of the Level 1 → Level 4
   prototype spectrum. Level 1 (algorithmic, synthetic
   streams) is done; Level 2 (real-sensor) is the next step.
   The scoping pass de-risks the eventual implementation.
2. **Parallel-safe with no round-3 risk.** Same
   justification as 0.0.26 P-OS, 0.0.34 P-PharOS, 0.0.36
   Lean scaffold, 0.0.37 Lean CI: zero connection to
   C-conjugate / Q₅₁ / 0/5202 round-3-blocked territory.
   Pure architectural-scoping + infrastructure-prep work.
3. **Deployment-stack triple completes scoping.** LL-022
   (downward) + LL-023 (upward) + LL-024 (operational
   instantiation) form a three-layer architectural
   commitment that closes the deployment-stack scoping
   question on all three ends. The triple-of-three pattern
   is corpus-honest (Aaron's closure work targets three-
   element relational closures).
4. **Phase 1 is post-round-3 work but ready to start.** When
   round-3 lands and the LavaLamp project resumes, the
   real-sensor work has its scoping done, its API surface
   declared, its tests scaffolded, and its roadmap pinned —
   ready for ~1 week of focused Linux-first implementation.

### Counts

- Total: 23 → 24 (+LL-024)
- `:proved`: 0 (unchanged)
- `:tested`: 3 (unchanged)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (unchanged)
- `:argued`: 15 → 16 (+LL-024)
- `:open`: 1 (unchanged)

Test suite: 184/184 → 202/202 (+18 RealSensors scaffold-
discipline assertions).

---

## 0.0.37 — 2026-05-04 — Lean 4 CI workflow (.github/workflows/lean.yml; lake build on every push)

Adds a Lean 4 CI workflow as **parallel-safe infrastructure
follow-up** to the 0.0.36 scaffold. Mirrors the Julia CI's
structure (`.github/workflows/test.yml`); uses
`leanprover/lean-action@v1` to install elan + read the pinned
toolchain (`src/lean4/lean-toolchain` → `leanprover/lean4:v4.18.0`)
+ run `lake build` on every push to master and on PRs.

**Net result.** Lean track now has CI baseline at the scaffold
tier. The build is trivial today (no theorems; smoke def +
`LavaLamp/Theorems.lean` comment-block placeholder), but the
workflow becomes operationally meaningful when proofs land in
round-3+: `sorry`-stubs still build clean, but real proof
attempts without `sorry` will fail CI if they have errors.
Same workflow, deeper meaning over time.

Counts unchanged (23 / 0 / 3 / 0 / 4 / 15 / 1). Test suite
184/184 unchanged (Julia track). No spec entry changes — CI
infrastructure is not evidence at the spec level.

### Added

- **`.github/workflows/lean.yml`** — Lean CI workflow.
  - Trigger: push to `master` + pull_request.
  - Runner: `ubuntu-latest`.
  - Timeout: 15 minutes (generous; scaffold-tier build runs
    in seconds).
  - Action: `leanprover/lean-action@v1` with
    `lake-package-directory: src/lean4`.
  - Permissions: read-only (`contents: read`).
  - Comments document the lockfile discipline (toolchain pin
    + lake-manifest.json empty-at-scaffold-tier) and the
    workflow's evolution from scaffold-tier baseline to
    proof-correctness checker as round-3 work lands.

### Changed

- **`CLAUDE.md`** — §Language tiers + phase discipline §6
  ("Lean 4 formal proofs"): scaffold-landed line gains a
  "*CI live at 0.0.37*" parenthetical with workflow path +
  action reference + structural mirror note.
- **`LAVALAMP_SPEC.md`** — version 0.0.36 → 0.0.37 (CI bump;
  no entry changes).
- **`artifact_registry.md`** — version 0.0.36 → 0.0.37 (CI
  bump; no row changes).
- **`dashboard.md`** — version 0.0.36 → 0.0.37. Recent
  companion docs prepended with the workflow file description.

### Why

1. **Scaffold + CI are sibling investments.** Landing the
   scaffold (0.0.36) without CI would mean future Lean drift
   could go undetected (e.g., a toolchain bump that breaks the
   build). CI catches it on the first push after the bug.
2. **No round-3 commitment.** Adding CI doesn't change spec
   entries, evidence types, or theorem statements. The
   workflow is purely operational hygiene.
3. **Symmetry with Julia track.** Julia CI runs `Pkg.test()`;
   Lean CI runs `lake build`. Both are necessary and
   complementary; both run on the same trigger conditions.
4. **Discipline scales with the project.** When proofs land
   in round-3+, the same workflow becomes a proof-
   correctness checker without modification. The investment
   pays off across all future Lean work.

### Counts

- Total: 23 (unchanged)
- All status counts unchanged.
- Test suite: 184/184 (Julia, unchanged).
- Lean: `lake build` clean (no theorems at scaffold tier;
  workflow verifies the buildable infrastructure).

---

## 0.0.36 — 2026-05-04 — Lean 4 scaffold landed at src/lean4/ (lake build clean)

Lands the Lean 4 formal-verification scaffold as **parallel-safe
infrastructure prep** for round-3 work. The scaffold is
buildable infrastructure (Lake project + toolchain pin + root
module + theorem-statement placeholder + README) but contains
**no theorem statements at this tier** — those await round-3
architectural decisions on Mathlib integration and any paper-
update revisions to the C-conjugate adversary structure.

Per CLAUDE.md package-management discipline ("verify a clean
checkout + lockfile install builds before committing"), the
scaffold's build was verified before commit:

```
$ cd src/lean4
$ lake update    # generates lake-manifest.json
$ lake build
✔ [2/4] Built LavaLamp.Theorems
✔ [3/4] Built LavaLamp
Build completed successfully.
```

Counts unchanged (23 / 0 / 3 / 0 / 4 / 15 / 1). Test suite 184/184
unchanged. **No spec entry status moves** — the scaffold is
infrastructure, not evidence. When proofs land, the corresponding
LL entries' evidence types upgrade to `lean-proved` and statuses
upgrade to `:proved`; until then, current `:argued` /
`:tested` / `:benchmarked` statuses are honest.

### Added

- **`src/lean4/lean-toolchain`** — Lean 4 version pin
  (`leanprover/lean4:v4.18.0`). Toolchain auto-installed by
  elan on first `lake` invocation.
- **`src/lean4/lakefile.lean`** — Lake build config; no
  external dependencies at scaffold tier; production-grade
  options (`pp.unicode.fun`, `autoImplicit false`).
- **`src/lean4/LavaLamp.lean`** — root module; imports
  `LavaLamp.Theorems`; smoke `def hello` confirms the package
  builds.
- **`src/lean4/LavaLamp/Theorems.lean`** — round-3 theorem-
  statement placeholder. Contains a comment-block listing the
  six priority theorems (LL-021 worst-case bound, LL-019
  timing indistinguishability, LL-020 calibration ε-DP,
  LL-006/008/018 isotropic detection bound, LL-022 + LL-023
  parametric theorem-shape disciplines) with their intended
  Lean syntactic forms. No `theorem` declarations at scaffold
  tier; uncommenting + filling in `sorry` proofs is round-3
  work.
- **`src/lean4/LavaLamp/`** subdirectory — per-priority
  proof files (LL006DetectionBound, LL019, LL020, LL021,
  LL022, LL023, Spec) will land here when proof work begins.
  Currently contains only Theorems.lean.
- **`src/lean4/lake-manifest.json`** — Lake's lockfile
  (auto-generated by `lake update`). Empty `packages` list at
  scaffold tier; gains entries when Mathlib or other deps are
  added per the round-3 Mathlib-or-not decision.
- **`src/lean4/README.md`** (~7 KB) — substantive discipline
  doc. Sections: what this is / isn't; build verification
  instructions; theorem-statement plan (six priorities with
  Mathlib-dependency notes); Mathlib integration architectural
  decision (three options laid out, round-3-driven); package-
  management discipline notes; round-3 trigger conditions; file
  inventory + future-state file map.

### Changed

- **`CLAUDE.md`** — §Language tiers + phase discipline §6 ("Lean
  4 formal proofs"): "*not yet started*" → "*scaffold landed at
  0.0.36*" with parenthetical noting the lakefile + toolchain
  + root + Theorems placeholder + README contents and the
  no-Mathlib-at-scaffold-tier discipline.
- **`LAVALAMP_SPEC.md`** — version 0.0.35 → 0.0.36 (scaffold
  bump; no entry changes).
- **`artifact_registry.md`** — version 0.0.35 → 0.0.36
  (scaffold bump; no row changes — scaffold is infrastructure,
  not evidence).
- **`dashboard.md`** — version 0.0.35 → 0.0.36. Recent companion
  docs prepended with `src/lean4/` description + theorem plan
  summary.
- **`README.md`** — version trajectory extended; layout section
  adds `src/lean4/`.

### Why

1. **Parallel-safe round-3 prep.** The Lean track is mentioned
   throughout the spec (LL-021 §2.7, LL-022 §2.6, LL-023 §2.6,
   round-2 §1D.v) but had no on-disk infrastructure. Landing
   the scaffold now means round-3 proof work begins from a
   buildable starting point rather than a `mkdir src/lean4/`
   commit.
2. **No round-3 commitment.** The scaffold is infrastructure-
   only; theorem statements are in *comment blocks*, not
   `theorem` declarations. The Mathlib-or-not decision and any
   theorem-shape revisions from the paper update remain open;
   the scaffold doesn't pre-commit to either.
3. **Build discipline established.** The first `lake build`
   ran clean post-commit; future Lean work inherits this
   baseline. Subsequent commits verify against the same
   discipline.
4. **Future file structure documented.** The README's File
   inventory section maps the current scaffold to the future-
   state per-priority file layout; round-3's first proof
   session starts with `mv Theorems.lean Spec.lean +
   create LL021WorstCaseBound.lean` rather than reinventing
   the structure.

### Counts

- Total: 23 (unchanged)
- `:proved`: 0 (unchanged — scaffold produces no `:proved`
  evidence; theorems are in comment blocks)
- `:tested`: 3 (unchanged)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (unchanged)
- `:argued`: 15 (unchanged)
- `:open`: 1 (unchanged)

Test suite: 184/184 unchanged (Lean scaffold is not in CI yet;
Julia tests handle CI).

---

## 0.0.35 — 2026-05-04 — Full A0–A6 cross-audit pre-round-3 (PASS post-fix)

Full A0–A6 cross-audit triggered by the seven-version session
arc 0.0.26 → 0.0.34. Per CLAUDE.md §Cross-audit protocol: "Run
when integrating substantive new work or preparing a release."
The prototype is now in a parallel-safe paused state pending
upstream (`closure_forces_structure` paper update + engine
updates); a fresh audit pre-round-3 confirms the spec / registry
/ dashboard / README / CLAUDE.md are all in sync.

**Result.** PASS across all six checks post-fix. One drift item
found and fixed: CLAUDE.md §Status section was frozen at
0.0.20 / 21 entries — 14 versions stale. Refreshed to 0.0.34 /
23 entries with correct trajectory and ledger.

| Check | Result |
|---|---|
| A0 self-audit | PASS (post-fix) |
| A1 coverage | PASS (23 spec = 23 registry) |
| A2 logic & status parity | PASS |
| A3 evidence exists | PASS (22 src + 17 docs + 4 visual files all present) |
| A4 status honesty | PASS (incl. conjunctive-claim discipline for LL-005, LL-020) |
| A5 stale counts | PASS (post-fix; all 5 sources show 23/0/3/0/4/15/1) |
| A6 test sync | PASS (CI runs Pkg.test() per commit; 184/184) |

Per the CLAUDE.md cross-audit protocol's "Findings are fixed
immediately or added to the priority stack": the CLAUDE.md
drift was fixed in this commit (immediate fix); no items
deferred to the priority stack.

### Added

- **`docs/audit_2026-05-04_full.md`** — full audit findings
  document (~9 KB). §1 A0 (CLAUDE.md drift identified +
  fixed). §2 A1 coverage. §3 A2 key match (registry uses
  spaced-form compressions of spec title-slugs; all
  unambiguous). §4 A3 evidence file existence (22 src + 17
  docs + 4 visual files all verified). §5 A4 status honesty
  (incl. conjunctive-claim discipline applied to LL-005 +
  LL-020). §6 A5 count parity table across 5 sources. §7
  A6 test sync (CI workflow + 184/184 suite). §8 summary
  table. §9 round-3 readiness checklist (7 architectural
  inputs accumulated; prototype side ready when the paper
  lands). Filename `audit_2026-05-04_full.md` distinguishes
  from the same-date `audit_2026-05-04.md` LL-020 diagnostic.

### Changed

- **`CLAUDE.md`** — §Status section refreshed. Date 2026-05-03
  → 2026-05-04. Trajectory description extended through the
  0.0.21 - 0.0.34 work (one-line summaries per substantive
  pass). Spec ledger counts corrected to 23 / 0 / 3 / 0 / 4 /
  15 / 1 with correct memberships. Test suite note added
  (184/184 in ~51 s). Note about all round-3-trigger queue
  items closed (modulo LL-005 part-(a) adversary-side
  sub-claim).
- **`LAVALAMP_SPEC.md`** — version 0.0.34 → 0.0.35 (audit
  bump; no spec content changes).
- **`artifact_registry.md`** — version 0.0.34 → 0.0.35 (audit
  bump).
- **`dashboard.md`** — version 0.0.34 → 0.0.35 (audit bump).
  Recent companion docs prepended with the audit findings
  document.
- **`changelog.md`** — 0.0.35 entry (this).

No spec content changes; no code changes; no test changes.
Counts unchanged at 23 / 0 / 3 / 0 / 4 / 15 / 1.

### Why

1. **Pre-round-3 hygiene.** Per CLAUDE.md, cross-audits are
   run "when integrating substantive new work or preparing a
   release." The seven-version session arc 0.0.26 → 0.0.34
   is substantive; round-3 readiness benefits from a fresh
   audit confirming clean state.
2. **Caught real drift.** CLAUDE.md staleness would have
   propagated into round-3 brief composition (the brief
   typically reads CLAUDE.md to ground its discipline
   description). Fixing now removes a future-session hazard.
3. **Round-3 readiness documented.** §9 of the audit
   findings articulates the seven architectural inputs
   accumulated since the last round-2 review; round-3's
   brief composition draws from this list.

---

## 0.0.34 — 2026-05-04 — PharOS scoping pass (LL-023 added :argued — upward trust-stack scoping)

Lands the PharOS scoping pass as **parallel-safe upward
trust-stack scoping work** while waiting for upstream
(closure_forces_structure paper update + engine updates).
Mirrors the 0.0.26 P-OS pass shape but oriented from the
consumer side. The 0.0.26 pass scoped what *LavaLamp depends
on from the OS layer below* (LL-022); this pass scopes what
*consumers depend on LavaLamp for from above* (LL-023).

**Net result.** New entry LL-023 (consumer-API-surface,
Boundary tier, manual evidence, `:argued`) articulates the
API contract LavaLamp commits to expose for downstream
OS-deployment consumers — four operations: `register`,
`verify` (with `verify_full` and `verify_constant_time`
variants), `device_state`, `re_register`. PharOS is the
canonical first instantiation (forthcoming OS-level identity
layer in the Triad Deployments portfolio); Lazarus and future
embedded SDK consumers also conform to the same surface.

**LL-022 (downward) + LL-023 (upward) close the trust-stack
scoping question on both ends.** Either alone is incomplete;
together they are the asymmetry-trap defence at the trust-
stack boundary. Three in-place amendments (LL-011, LL-017,
LL-022) cross-reference LL-023 for the consumer-side framing.

Counts: total 22 → 23; `:argued` 14 → 15; other counts
unchanged. Test suite 184/184 unchanged (this version adds no
new code or tests — design-only pass).

### Added

- **`docs/pharos_scoping_companion.md`** — substantive design
  companion (~7 KB). §1 inputs (no code; design synthesis
  only). §2.1 PharOS architectural role (lighthouse /
  persistent reference for OS authentication; consumer of
  LavaLamp's verifier API, not a re-implementation of the
  security primitive). §2.2 enumerates the four LL-023 API
  operations with inputs / outputs / errors / use cases. §2.3
  maps OS integration points (PAM on Linux, Authorization
  Plug-in on macOS, Credential Provider on Windows; SSH key
  wrapping + biometric replacement as advanced integrations).
  §2.4 articulates PharOS's narrower threat model. §2.5
  closes the Triad Deployments trust-stack picture (Lazarus
  / LavaLamp / PharOS as a closure-of-three). §2.6 pins
  parametric Lean theorem-shape for consumer inheritance.
  §5 captures four lessons including "the trust-stack scoping
  question has two ends" and "PharOS's role is reference, not
  gate."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.33 → 0.0.34. New entry
  LL-023 in a new "Surfaced by P-PharOS scoping pass (0.0.34)"
  section. Three in-place amendments:
  - LL-011 — appends consumer-framing sub-bullet noting
    PharOS as canonical OS-deployment consumer; cites
    LL-023's `register` operation.
  - LL-017 — appends consumer-framing sub-bullet noting the
    no-oracle protocol enforced at the LL-023 surface;
    cites platform shims (PAM / Auth Plug-in / Credential
    Provider).
  - LL-022 — appends "Closure with LL-023" note articulating
    the downward + upward pair.
  New entry LL-023 lands in its own section with the standard
  Boundary-entry shape (manual / `:argued`). Counts: total
  22 → 23; `:argued` 14 → 15.
- **`artifact_registry.md`** — version 0.0.33 → 0.0.34. New
  "Surfaced by P-PharOS scoping pass (0.0.34)" section with
  LL-023 row. Counts updated. Cross-audit A1-A6 self-check
  refreshed for 0.0.34.
- **`dashboard.md`** — version 0.0.33 → 0.0.34. Status
  summary updated. Spec status counts updated. P-PharOS
  added to priority stack as a closed item (parallel to
  P-OS shape). Recent companion docs prepended with the new
  companion.
- **`README.md`** — spec ledger counts updated; trajectory
  extended.

### Why

1. **Symmetric scoping.** LL-022 (downward) was paired with
   LL-015 (kernel OOS) at the 0.0.26 P-OS pass. LL-023
   (upward) was the missing pair member — without it, the
   trust-stack scoping was incomplete on the consumer side.
   This pass closes that asymmetry.
2. **Triad Deployments portfolio.** With LL-023 landed,
   LavaLamp's spec articulates *what consumers can rely on*
   — the contract PharOS / Lazarus / future SDKs conform to.
   The portfolio's closure-of-three structure (per the
   2026-05-04 branding decision; see
   `~/.claude/projects/.../memory/reference_triad_deployments.md`)
   has its formal grounding in this pair of Boundary entries.
3. **Parallel-safe with no round-3 risk.** Same justification
   as 0.0.26 P-OS / 0.0.33 visual layer: zero connection to
   C-conjugate / Q₅₁ / 0/5202 round-3-blocked territory.
   Pure architectural-scoping work.
4. **Pre-PharOS design discipline.** When PharOS lands
   operationally (forthcoming repo), it inherits the LL-023
   contract as the consumer-side conformance target. This
   pass therefore *de-risks* PharOS's eventual implementation
   by pinning the API surface in advance.

### Counts

- Total: 22 → 23 (+LL-023)
- `:proved`: 0 (unchanged)
- `:tested`: 3 (unchanged)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (unchanged)
- `:argued`: 14 → 15 (+LL-023)
- `:open`: 1 (unchanged)

Test suite: 184/184 unchanged (design-only pass adds no tests).

---

## 0.0.33 — 2026-05-04 — LL-002 :tested via decoupled visual layer + decoupling-assertion testset

Lands the long-deferred P8 visual-skin item from the dashboard
priority stack as **parallel-safe work while waiting for upstream
(closure_forces_structure paper update + engine updates)**. The
visual layer evidences LL-002 (`visual ↔ security decoupling`
load-bearing invariant) at `:tested`-tier — option (a) from the
prior `:argued` footer ("a visual layer with assertions about
decoupling").

**Net result.** LL-002 status moves `:argued` → `:tested`.
Counts shift: `:tested` 2 → 3; `:argued` 15 → 14; total 22
unchanged. Test suite 139 → 184 (+45 assertions for the
`Visual layer decoupling (LL-002)` testset).

The visual is decorative-only by construction: ~80 lines of
JavaScript using Math.random() exclusively, with no references
to any security-primitive identifier, no imports, no
requires, no external script tags. The decoupling invariant is
now **executable on every commit** — any future re-coupling
would fail CI.

### Added

- **`visual/`** directory at repo root.
  - **`visual/index.html`** — entry point (single `<script
    src="lavalamp.js">`).
  - **`visual/lavalamp.js`** — bubble simulator (~80 lines).
    7 bubbles with random initial positions, velocities,
    sizes, hues; vertical drift with sin-curve wobble; bounce
    off edges; reset on exit-top. Pure
    `requestAnimationFrame` render loop.
  - **`visual/style.css`** — minimal lamp-frame styling
    (gradient body, rounded edges, glow shadow). Decorative
    choice; no security significance.
  - **`visual/README.md`** — decoupling discipline
    documentation. Explains what the visual is, what it
    isn't, why decoupling is load-bearing (V-002 basin-
    spoofing returns if ever re-coupled), and what the
    decoupling assertions verify.
- **`src/julia/test/runtests.jl`** — new `Visual layer
  decoupling (LL-002)` testset with 45 assertions:
  - Existence: `visual/` directory + 4 expected files.
  - Randomness source: `Math.random()` present;
    `crypto.getRandomValues` / `crypto.subtle` absent.
  - 14 security-primitive identifiers (`lyapunov_spectrum`,
    `register_envelope`, `synthetic_adversary`,
    `verify_full`, `verify_constant_time`,
    `differentially_private_envelope`, `lorenz96_coupled`,
    `lorenz63`, `rossler`, `ChaosGuard`, `Envelope(`,
    `nyquist_compliant`, `CouplingParams`, `SensorStream`)
    NOT present in `visual/lavalamp.js`.
  - No external imports / requires / script tags in
    `visual/lavalamp.js`.
  - 4 visual-layer identifiers (`requestAnimationFrame`,
    `getContext(`, `createRadialGradient`, `lavalamp.js`)
    NOT present in any `src/julia/src/*.jl`.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.32 → 0.0.33. LL-002
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`. Source / Test fields updated to cite
  `visual/lavalamp.js` and the decoupling testset. Counts:
  `:tested` 2 → 3; `:argued` 15 → 14.
- **`artifact_registry.md`** — version 0.0.32 → 0.0.33.
  LL-002 row updated. Cross-audit A1-A6 self-check
  refreshed for 0.0.33.
- **`dashboard.md`** — version 0.0.32 → 0.0.33. Status
  summary updated. Spec status counts updated. Recent
  companions prepended with `visual/` entry.
- **`README.md`** — test count 139 → 184; trajectory
  extended; visual/ added to file-tree section.

### Why

1. **LL-002 was the most accessible :argued → :tested
   upgrade.** Per the spec footer, the upgrade required
   either (a) a visual layer with assertions about
   decoupling, or (b) Lean / type-level enforcement. Option
   (a) was buildable now without round-3 dependencies;
   option (b) is P5/P6 and contingent on the round-3 paper
   update.
2. **Parallel-safe with no round-3 risk.** The visual layer
   has zero connection to the C-conjugate adversary, Q₅₁-tier
   identity, or 0/5202 cross-sector autopoiesis result. Pure
   architectural-decoupling work that round-3 cannot revise.
3. **The decoupling invariant becomes executable.** Prior
   `:argued` evidence was "invariant preserved by
   construction" (manual). The `:tested` evidence is
   automatic: every commit runs CI; any reference between
   the visual and security layers fails the test. This is
   the asymmetry-trap defence at the test-surface level.
4. **PharOS / Lazarus visual extensibility** — the visual
   layer can grow into product-shaped UIs for the other
   Triad Deployments without changing its decoupling
   discipline. Documented in `visual/README.md`.

### Counts

- Total: 22 (unchanged)
- `:proved`: 0 (unchanged)
- `:tested`: 3 (+1: LL-002)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (unchanged)
- `:argued`: 14 (-1: LL-002)
- `:open`: 1 (unchanged)

Test suite: 139/139 → 184/184.

---

## 0.0.32 — 2026-05-04 — LL-005 part-(a) parameter-validation test (entry stays :argued)

Adds the LL-005 part-(a) parameter-validation test promised in
the round-3-trigger memory's queue ("trivial test asserting
f_SDE > 2·BW"). Adds a `nyquist_compliant(f_SDE, f_sensor,
bandwidth)` predicate to `src/julia/src/Sensors.jl` plus 16
test assertions in runtests.jl. Test suite 123/123 → 139/139.

**Status discipline.** LL-005's entry-level claim is
structurally a *conjunction* of two sub-claims: (1) parameter
compliance and (2) adversary detection. The 0.0.24 P3-Nyq
benchmark answered (2) NEGATIVE: zero-mean Gaussian noise has
time-averaged statistics invariant under sub-sampling, so the
Lyapunov-spectrum residue audit cannot detect sub-Nyquist
adversaries. With (2) open per the negative finding, evidencing
only (1) does not warrant a `:tested` upgrade.

**LL-005 entry-level status remains `:argued`.** The test
exists; the upgrade does not. The discipline rationale —
"sub-claim evidence ≠ entry-level upgrade for conjunctive
claims" — is documented in `docs/ll005_part_a_companion.md` §5.1.

The original deferral concern in the round-3-trigger memory
was *"consider deferring to avoid misleading partial upgrade."*
The right resolution is **add the test without upgrading**,
not skip the test entirely. Future deployments call
`nyquist_compliant(...)` at configuration time; the operational
benefit is independent of the entry-level status question.

### Added

- **`src/julia/src/Sensors.jl`** — `nyquist_compliant(f_SDE,
  f_sensor, bandwidth) -> Bool` predicate. Strict-inequality
  formal requirement: `f_SDE > 2·BW ∧ f_sensor > BW`. Throws
  `ArgumentError` on non-positive inputs. Documented as
  "parameter-side LL-005 evidence only; does not certify
  adversary detection (see 0.0.24 P3-Nyq)."
- **`src/julia/src/LavaLamp.jl`** — re-export of
  `nyquist_compliant`.
- **`src/julia/test/runtests.jl`** — new "Nyquist compliance
  predicate (LL-005 part-(a))" testset with 16 assertions:
  prototype defaults compliant for plausible BW; borderline
  cases at `f_SDE = 2·BW` and `f_sensor = BW` strict edges;
  argument validation (zero / negative); type flexibility
  (`Real` arguments).
- **`docs/ll005_part_a_companion.md`** — brief companion
  documenting the discipline rationale: why the test landed
  despite the deferral warning, what it shows and does not
  show, and why LL-005 stays `:argued`.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.31 → 0.0.32. LL-005
  gains a "Parameter-validation test (2026-05-04, part-(a)
  only)" footer documenting the test, the suite-count
  increase, and the explicit "status unchanged at `:argued`"
  framing. Counts unchanged.
- **`artifact_registry.md`** — version 0.0.31 → 0.0.32.
  LL-005 row's Test/Proof column extended to cite
  runtests.jl + the companion; Source column adds
  `src/julia/src/Sensors.jl (`nyquist_compliant`)`.
  Cross-audit A1-A6 self-check refreshed for 0.0.32.
- **`dashboard.md`** — version 0.0.31 → 0.0.32. P3 follow-ups
  list adds 0.0.32 entry; LL-005 part-(a) removed from
  remaining-unblocked. Recent companion docs prepended with
  `ll005_part_a_companion.md`. Note: "All round-3-trigger
  memory queue items now closed."

### Why

1. **Operational benefit independent of status question.**
   `nyquist_compliant(...)` is a deployment-time check that
   would be open-coded by every consumer otherwise. Adding it
   to the prototype's API surface lowers operational friction
   without overclaiming.
2. **Conjunctive-claim discipline made explicit.** LL-005's
   structure (P_compliance ∧ Q_detection) is now articulated
   in the spec footer and the companion. Future readers see
   why partial coverage doesn't upgrade. This generalises to
   any spec entry with conjunctive claims; the §5.1 lesson is
   reusable.
3. **Round-3-trigger memory queue closure.** Per the 0.0.31
   companion §5.5, this was the last unblocked item. With
   0.0.32 landed, the prototype is in a fully-quiet state
   pending round-3.

### Counts

- Total: 22 (unchanged)
- `:proved`: 0 (unchanged)
- `:tested`: 2 (LL-004, LL-007 — unchanged)
- `:verified`: 0 (unchanged)
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-021 — unchanged)
- `:argued`: 15 (unchanged; LL-005 stays here)
- `:open`: 1 (LL-015 — unchanged)

Test suite: 123/123 → 139/139.

---

## 0.0.31 — 2026-05-04 — LL-006 per-SDE detection-power (Lorenz-96 has best operational balance)

Adds the per-SDE detection-power benchmark — the last unblocked
sub-item from the round-3-trigger memory's queue. Sweeps
parameter-space adversaries against each of the three candidate
SDEs (Lorenz-96 perturbing F, Lorenz-63 perturbing ρ, Rössler
perturbing c) and characterises the LL-006 detection bound shape
per engine.

**Net result.** The detection-bound shape `P(detect) ≥ 1 - K ·
exp(-c' · T · ε_A²)` is universal across the candidate SDE set.
Per-SDE c′ values:

| SDE       | param | c′       | binding ε_A |
|-----------|-------|---------:|------------:|
| Lorenz-96 | F     |  0.00372 |       1.000 |
| Lorenz-63 | ρ     |  0.00168 |       4.000 |
| Rössler   | c     |  0.38179 |       0.200 |

c′ values are NOT directly comparable as detection-quality
rankings (parameter scales differ). Combined with the 0.0.25 P3d
h_KS comparison, **Lorenz-96 has the right operational balance**:
high security margin (h_KS = 10× / 155× the alternatives) AND
moderate per-param sensitivity (neither too low for adversary
detection nor too high for genuine calibration tolerance).
Lorenz-63 fails on both axes (low h_KS AND low per-param
sensitivity → adversaries with ~14% drift slip through).
Rössler fails on both axes (low h_KS AND extreme brittleness
— narrow chaotic band makes ~3% genuine drift trigger
spurious rejection).

The architectural choice from 0.0.25 is confirmed on this
complementary axis. LL-006 stays `:benchmarked`. Counts unchanged
(22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).

### Added

- **`src/julia/benchmark/p3f_per_sde_detection_power.jl`** —
  per-SDE benchmark with inline parameter-space adversary
  helpers per SDE (no new public APIs). Wall-clock excluded
  from result file. ~5 minutes wall clock on Apple Silicon.
- **`src/julia/benchmark/results/p3f_per_sde_detection_power.txt`**
  — committed result file. Determinism check PASS
  (byte-identical across two runs).
- **`docs/p3f_per_sde_detection_power_companion.md`** —
  companion. §1.1 establishes the parameter-space adversary
  model (vs the 0.0.17 P3-bound's α-space adversary). §2.1
  reports per-SDE detection sigmoids. §2.2 cautions on
  comparability of c′ across parameters. §2.3 articulates the
  two-axis operational-balance argument (h_KS + per-param
  sensitivity). §2.4 explains Rössler's intrinsic brittleness
  (narrow chaotic band). §2.5 compares F-space (this) to
  α-space (0.0.17) for Lorenz-96. §5 captures five lessons
  including the universal bound shape and "all known
  unblocked sub-items now closed."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.30 → 0.0.31. LL-006
  gains a "Per-SDE detection-power characterisation
  (2026-05-04)" footer documenting the bound shape's
  universality across the candidate SDE set, the per-SDE
  c′ values, and the two-axis operational-balance argument.
  Status unchanged. Counts unchanged.
- **`artifact_registry.md`** — version 0.0.30 → 0.0.31.
  LL-006 row's Test/Proof column extended to cite the new
  benchmark + result + companion. Cross-audit A1-A6
  self-check refreshed for 0.0.31.
- **`dashboard.md`** — version 0.0.30 → 0.0.31. Status
  summary updated. P3 follow-ups list adds 0.0.31 entry;
  per-SDE detection-probability surface removed from
  remaining-unblocked. Recent companion docs prepended with
  the new companion. Notes "all known unblocked sub-items
  now closed" except LL-005 part-(a) deferred to round-3.

### Why

1. **Last unblocked queue item.** Per the round-3-trigger
   memory's queue at session start, this was item 5 of 6
   (LL-005 part-(a) is item 6, deferred to round-3). Closing
   this item brings the prototype to a quiet state — no
   further obvious benchmarks without round-3 trigger or new
   architectural work.
2. **Architectural-choice confirmation on a second axis.**
   The 0.0.25 P3d benchmark rejected Lorenz-63 / Rössler on
   h_KS alone (security margin). This benchmark adds parameter
   robustness as a second axis. The combined picture
   (security margin AND operational robustness) gives a
   stronger architectural argument for Lorenz-96 than either
   axis alone.
3. **Bound shape universality.** The 0.0.17 P3-bound fitted
   the bound for Lorenz-96 only, leaving open whether the
   shape is Lorenz-96-specific or universal. This benchmark
   confirms universality — the bound shape applies cleanly
   to all three SDEs with SDE-specific c′ values reflecting
   per-parameter sensitivity. Generalises the 0.0.17 claim.

---

## 0.0.30 — 2026-05-04 — LL-003 N-scaling characterisation (Lyapunov density ≈ 0.255)

Adds the Lorenz-96 N-scaling benchmark — the unblocked sub-item
promised in `dashboard.md` P3 follow-ups. Sweeps N ∈ {20, 40,
80, 160} at F=8, 5 trials per N, and characterises how the
Lyapunov-spectrum statistics scale with system size for the
chosen SDE.

**Net result.** Spatially-extended-chaos prediction confirmed
empirically. Linear h_KS scaling within sampling-variance
bounds:

```
h_KS  ≈ 0.2165 · N^1.0370       (β=1.04 vs theoretical β=1.0)
n_pos ≈ 0.3019 · N^1.0220       (β=1.02)
KY    ≈ 0.6623 · N^1.0048       (β=1.00)
```

Per-N Lyapunov density h_KS/N converges from 0.2383 (N=20) to
0.2591 (N=160) — finite-N corrections decay as N grows; density
saturates by N≥80. Asymptotic Lyapunov density s ≈ 0.255 per
dimension at F=8 is a deployment-design constant. Compute
scales as O(N³) per integration step (per-trial wall clock
0.1 → 1.8 → 5.9 → 25 s as N goes 20 → 40 → 80 → 160).

LL-003 stays `:benchmarked`. The N-scaling adds deployment-
guidance content to the entry's footer — concretely, the
deployment-design rule:

```
For target chaos-production margin Δh*:
  N* ≈ Δh* / s        with s ≈ 0.255
  Compute cost: O(N*³) per integration step.
```

### Added

- **`src/julia/benchmark/p3e_n_scaling.jl`** — N-scaling
  benchmark. Sweeps N ∈ {20, 40, 80, 160} at fixed F=8,
  N_benettin=1200, 5 trials per N. Wall-clock excluded from
  result file (printed to stdout) per the §Benchmarking
  discipline byte-identical convention. Total wall clock
  ~3 minutes on Apple Silicon.
- **`src/julia/benchmark/results/p3e_n_scaling_lorenz96.txt`**
  — committed result file. Per-N spectrum statistics +
  fitted scaling laws + per-N intensities. Determinism check
  PASS (byte-identical across two runs).
- **`docs/p3e_n_scaling_companion.md`** — companion. §1
  configuration + determinism. §2.1-§2.2 per-N statistics
  and fitted laws. §2.3 per-N Lyapunov density convergence
  (finite-N correction analysis). §2.4 O(N³) compute scaling
  validation. §2.5 deployment-design rule with worked
  examples. §3.2 grounds LL-008's Lean theorem in
  N-dependent form. §5 captures five lessons including
  "extensive-chaos prediction empirically validated" and
  the methodology continuity across the three high-res
  refreshes 0.0.28-0.0.30.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.29 → 0.0.30. LL-003
  gains a "N-scaling characterisation (2026-05-04)" footer
  documenting the linear scaling, asymptotic density,
  compute cost, and deployment-design rule. Status unchanged.
  Counts unchanged (22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).
- **`artifact_registry.md`** — version 0.0.29 → 0.0.30.
  LL-003 row's Test/Proof column extended to cite the new
  benchmark + result + companion. Cross-audit A1-A6
  self-check refreshed for 0.0.30.
- **`dashboard.md`** — version 0.0.29 → 0.0.30. Status
  summary updated. P3 follow-ups list adds 0.0.30 entry;
  Higher-N Lorenz-96 benchmark removed from
  remaining-unblocked. Recent companion docs prepended with
  the new companion.

### Why

1. **Most fundamental of the remaining queue.** Per the
   in-conversation analysis: the N-scaling benchmark connects
   directly to LL-008's load-bearing security claim
   (`S_production > S_measurement` margin scales with h_KS),
   gives a deployment-design knob (N) with predictable
   consequences, and answers a question that's structurally
   unknown at the prototype's parameters (literature gives
   N=40 values; we hadn't measured N=80 or N=160 ourselves).
2. **Empirical validation of theoretical prediction.** The
   spatially-extended-chaos literature predicts linear h_KS
   scaling for systems like Lorenz-96 at fixed F. This
   benchmark validates that prediction at the prototype's
   parameters within sampling-variance bounds.
3. **LL-008 grounding refinement.** Prior to this benchmark,
   `S_production` was characterised at single N values (N=20
   in P3-bound, N=40 in P3d). The N-dependent characterisation
   `S_production ≈ s · N` makes LL-008's theorem statement
   parametrically clearer for P5/P6 Lean work.
4. **Compute-cost characterisation at high N.** The O(N³) per
   integration step scaling is now concrete (25 s per
   spectrum at N=160). High-assurance deployments now have
   the cost knob alongside the margin knob.

---

## 0.0.29 — 2026-05-04 — LL-019 high-res refresh (regime-boundary at α=0.01/n=2000)

Higher-resolution refresh of the LL-019 timing-distribution
benchmark, promised in `docs/ll019_benchmarked_companion.md` §4
followups. The refresh tested `verify_constant_time` at 5×
sample size (1000 per source vs 200) and α=0.01 (vs 0.05).

**Net result.** The high-res regime exposes a *methodological
boundary* of LL-019's :benchmarked claim, not a tightening or
refutation. At α=0.01 / n=2000 on the prototype's dev host, the
KS_stat for `verify_constant_time` fluctuates ~0.04 across
consecutive runs from system-jitter alone, and the verdict can
flip INDISTINGUISHABLE → DISTINGUISHABLE between runs (Run 1:
KS_stat=0.073, INDIST; Run 2: KS_stat=0.116, DIST;
critical_α=0.01 = 0.093).

This is a real methodological finding, not an implementation
bug. The mean / median timing differences across accept/reject
buckets remain ~10 μs on 100 ms padded operations (ratio 1e-4)
— *operational-significance is unchanged*. The KS test at this
regime is detecting jitter-induced empirical-CDF noise, not
algorithm-level data dependence.

LL-019 stays `:benchmarked` at the 0.0.19 evidence regime
(α=0.05 / n=400, margin 0.061 between KS_stat 0.109 and
critical 0.170 — well above any plausible jitter range; verdict
stable). The high-res refresh produces *regime-boundary
documentation* for what the :benchmarked claim does and does
not extend to.

### Added

- **`src/julia/benchmark/ll019_timing_distribution_high_res.jl`**
  — copy of `ll019_timing_distribution.jl` with N_DISTINCT_λS
  bumped 20→50, N_CALLS_PER_λS bumped 10→20 (1000 samples per
  source vs 200), α=0.01 (c=1.628 vs 1.358 at α=0.05). Same
  system / coupling / verifier / RNG-seed convention; trials
  1-10 reproduce the original by construction; trials 11-20 +
  λs 21-50 are new evidence.
- **`src/julia/benchmark/results/ll019_timing_distribution_high_res.txt`**
  — Run 2 output committed. The result file represents one
  observation, not a deterministic ground truth (per the
  verdict-level determinism convention added to CLAUDE.md
  this commit).
- **`docs/ll019_high_res_companion.md`** — companion. §1.2
  establishes the verdict-level determinism convention for
  timing-based benchmarks (byte-level determinism is
  structurally inapplicable). §2.1-§2.2 report the verdict
  instability across two runs. §2.3 contrasts with the stable
  0.0.19 fit at α=0.05 / n=400. §2.4 explains why critical
  value shrinks faster than KS_stat in the jitter-dominated
  regime (`c(α) · sqrt((n+m)/(n·m))` → 1/sqrt(n)). §2.5
  distinguishes statistical from operational distinguishability
  (the latter is unaffected). §3 documents why this is not a
  status downgrade. §5 captures five lessons: determinism has
  multiple levels; critical shrinks faster than KS_stat;
  operational vs statistical distinguishability; some
  refreshes find boundaries not tightenings; host-isolation
  as round-3 input.

### Changed

- **`CLAUDE.md`** — §Benchmarking discipline gains an inline
  paragraph generalising the determinism rule from byte-
  identical to *multiple levels*: numerical benchmarks (RNG-
  seeded; byte-identical) vs timing-based (jitter-limited;
  verdict-level). The LL-019 high-res refresh is cited as
  the worked example.
- **`LAVALAMP_SPEC.md`** — version 0.0.28 → 0.0.29. LL-019
  gains a "High-resolution refresh (2026-05-04, regime-boundary
  finding)" footer documenting the verdict instability at
  high-res, the operational-significance assessment, and that
  the status stays `:benchmarked` at the 0.0.19 regime.
  Counts unchanged (22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).
- **`artifact_registry.md`** — version 0.0.28 → 0.0.29.
  LL-019 row's Test/Proof column extended to cite the new
  high-res benchmark + result + companion. Cross-audit A1-A6
  self-check refreshed for 0.0.29.
- **`dashboard.md`** — version 0.0.28 → 0.0.29. Status
  summary updated. P3 follow-ups list adds 0.0.29 entry;
  LL-019 high-res refresh removed from remaining-unblocked.
  Recent companion docs prepended with the new companion.

### Why

1. **Promised follow-up.** The 0.0.19 companion explicitly
   deferred the high-res refresh; landing it now closes that
   loop.
2. **Methodological discipline.** A refresh that exposes a
   regime-boundary is a first-class :benchmarked-tier output
   per CLAUDE.md §Benchmarking discipline (negative results
   are first-class artefacts). The 0.0.28 LL-021 refresh
   confirmed; this 0.0.29 LL-019 refresh found a boundary —
   both are honest framing applied to high-res testing.
3. **Round-3 input.** Timing-distribution benchmarks have a
   host-isolation threshold below which statistical power is
   jitter-limited. This is concrete content for the §Host-OS
   invariants discipline note (added 0.0.26.5) and may
   surface in round-3 as a candidate sub-claim of LL-022 or
   as a separate spec entry on operational regimes for
   timing-based decorrelation guarantees.
4. **Determinism rule generalisation.** The §Benchmarking
   discipline rule from 0.0.27 covered byte-identical
   determinism only. This commit generalises it to verdict-
   level determinism for timing-based benchmarks, with the
   LL-019 finding as the canonical example.

---

## 0.0.28 — 2026-05-04 — LL-021 high-resolution refresh (c′=0.0288 at n=15)

Higher-resolution refresh of the P-R2c structured-adversary
benchmark, promised in `docs/ll021_benchmarked_companion.md`
§2.5 / §4.4 as a follow-up to tighten the n=5 sampling-variance
caveat that was the binding limitation on the 0.0.18 fit.

**Net result.** The n=5 fit is *confirmed* at higher statistical
confidence: c′ shifts from 0.02777 to 0.0288 (3.8 %, well within
sampling-variance bounds). The binding constraint migrates from
MIXED ε_A=1.0 (transition-region, P≈0.6 at n=5) to NARROW
ε_A=4.0 (FPR-floor regime, P≈0.07 at n=15). Negative-margin
points reduce from 3 of 12 (n=5) to 1 of 12 (n=15); the
remaining one is FPR-floor and Wilson-95%-CI-consistent.

LL-021 status unchanged at `:benchmarked`. The refresh is a
*refinement of the constants*, not a status promotion or
demotion — but the n=5 caveat documented in 0.0.18 §2.5 closes.

### Added

- **`src/julia/benchmark/p_r2c_structured_adversary_high_res.jl`**
  — copy of `p_r2c_structured_adversary.jl` with
  `N_TRIALS_PER_POINT=15` (was 5) and a separate result-file
  path. Same RNG-seed convention extended deterministically to
  trial 15; trials 1-5 reproduce the original by construction;
  trials 6-15 are new evidence.
- **`src/julia/benchmark/results/p_r2c_structured_high_res_lorenz96.txt`**
  — committed n=15 surface. Wall-clock timing excluded from
  the result file (printed to stdout) so the determinism
  check succeeds byte-identically per CLAUDE.md
  §Benchmarking discipline.
- **`docs/ll021_high_res_companion.md`** — companion. §1.2
  documents the determinism check (PASS after stripping
  wall_s from result file). §2.1-§2.6 report the n=15
  surface, sample-frequency comparison vs n=5, refit, Wilson
  CI tightening, and bound-margin verification at all 12
  points. §3.2 explains why c′ shifts only 3.8 % despite two
  large per-point sample-frequency moves. §4 documents the
  spec-impact (footer addition; status unchanged). §5
  captures four lessons including "confirmation is a
  positive result" and the regime migration of the binding
  constraint.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.27 → 0.0.28. LL-021
  gains a "High-resolution refresh (2026-05-04, n=5 → n=15)"
  footer documenting the refined c′=0.0288, the binding-
  constraint migration, the 11/12 pointwise hold, and the
  Wilson-CI tightening. Status unchanged. Counts unchanged
  (22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).
- **`artifact_registry.md`** — version 0.0.27 → 0.0.28.
  LL-021 row's Test/Proof column extended to cite the high-
  res benchmark + result + companion. Cross-audit A1-A6
  self-check refreshed for 0.0.28.
- **`dashboard.md`** — version 0.0.27 → 0.0.28. Status
  summary updated. P3 follow-ups list adds 0.0.28 entry;
  P-R2c high-res refresh removed from remaining-unblocked.
  Recent companion docs prepended with the new companion.

### Empirical summary

```
direction    ε_A    P_n5    P_n15
---------    ---    -----   -----
NARROW       0.50   0.20    0.27
NARROW       1.00   0.00    0.00
NARROW       2.00   0.20    0.07
NARROW       4.00   0.00    0.07  ← newly inclusive (binding at n=15)
MIXED        0.50   0.00    0.33  ← n=5 missed the transition
MIXED        1.00   0.60    0.87  ← n=5 binding; under-counted
MIXED        2.00   1.00    1.00
MIXED        4.00   1.00    1.00
BROAD        0.50   0.60    0.60  ← unchanged sample frequency
BROAD        1.00   1.00    1.00
BROAD        2.00   1.00    1.00
BROAD        4.00   1.00    1.00
```

| Quantity | n=5 (0.0.18) | n=15 (this) | shift |
|---|---|---|---|
| K | 1 | 1 | unchanged |
| c′ | 0.02777 | 0.0288 | +3.8 % |
| Binding point | MIXED ε_A=1.0 (P=0.6) | NARROW ε_A=4.0 (P=0.07) | regime shift |
| Negative-margin points | 3 of 12 | 1 of 12 | better |
| All Wilson CIs cover bound | yes | yes | maintained |
| Wilson CI width at 0/n | 0.434 | 0.218 | 0.50× tighter |

### Why

1. **Promised follow-up.** The 0.0.18 companion explicitly
   deferred the n=15 refresh as "follow-up benchmark, not a
   fundamental result" — landing it now closes that loop.
2. **Tighter Lean grounding.** Round-2 §1D.v priority 1 (Lean
   theorem on linear-coupling worst-case bound) takes c′ as
   a numerical constant. Refining c′ to 0.0288 at n=15
   confidence makes the eventual Lean theorem statement
   anchor on stronger empirical witness.
3. **Discipline rule applied.** The first determinism check
   on this benchmark failed on wall-clock-timing only
   (numerical results identical). Stripping wall_s from the
   result file made the check pass byte-identically — a
   small refinement to the result-file convention that
   matches the §Benchmarking discipline rule established in
   0.0.27. The original `p_r2c_structured_adversary.jl`
   n=5 result file predates this convention and retains its
   wall_s column for historical continuity.

---

## 0.0.27 — 2026-05-04 — LL-020 Strategy 2 :benchmarked-tier (entry stays :argued)

Closes Strategy 2 of LL-020 (ε-DP envelope perturbation) to
`:benchmarked`-tier evidence with empirically-validated
privacy/detection trade-off constants. Entry-level LL-020
stays `:argued` because the multi-strategy approach
(Strategies 1+2+3) is the entry's claim and only Strategy 2
has been exercised at `:benchmarked` evidence quality.

The session ran in two phases. **Phase 1 (commit `8574670`,
landed prior to this changelog entry):** the initial
benchmark produced a pathological 100% FPR across every
(ε_DP, ε_A) cell. A determinism re-check (`diff` exit 0)
attributed the result cleanly to a bug in
`differentially_private_envelope` rather than host-state
contamination; CLAUDE.md gained a §Benchmarking discipline
section codifying the determinism-check rule going forward.

**Phase 2 (this version, 0.0.27):** the bug fix landed and
the re-benchmark produced the expected trade-off curve.

### Changed

- **`src/julia/src/Audit.jl`** — `differentially_private_envelope`
  refined: spectrum stays Gaussian-mechanism (ε,δ)-DP;
  σ replaced with variance-convolution form
  `σ_pub = sqrt(env.σ² + σ_DP²)`. Deterministic in
  `env.σ`+`σ_DP`; strictly inflates each component; matches
  the docstring's "wider tolerances" intent. Trade-off:
  σ leaks `env.σ ≤ σ_pub` (not DP-protected); only spectrum
  is DP. Operationally σ is calibration *confidence*, less
  sensitive than the spectrum itself; deployments needing
  DP on σ substitute Strategy 1 (TPM-sealed) or Strategy 3
  (Shamir threshold). Docstring updated to reflect the
  refinement and reference `docs/audit_2026-05-04.md` /
  `docs/ll020_strategy_2_benchmarked_companion.md`.
- **`src/julia/test/runtests.jl`** — added 6 new test
  assertions for the variance-convolution σ guarantees:
  σ_pub deterministic in env.σ + σ_DP (different RNG seeds
  give identical σ_pub); σ_pub formula
  `σ_pub_i = sqrt(env.σ_i² + σ_DP²)`; σ_pub strictly inflates
  env.σ; σ_pub ≥ σ_DP per component; end-to-end operational
  correctness via verify against the perturbed envelope.
  Total: 117/117 → 123/123.

### Added

- **`docs/ll020_strategy_2_benchmarked_companion.md`** —
  companion. §1.1 documents the variance-convolution σ
  refinement and the privacy implications of the σ choice.
  §2.1 reports the empirical detection-power surface across
  the (ε_DP, ε_A) plane. §2.2 tabulates σ_DP per privacy
  budget. §2.3 fits bound constants per ε_DP per the LL-006
  P3-bound shape. §2.4 articulates the operational design
  rule: σ_DP ≤ X/3 (where X is the smallest adversary
  magnitude that must be detected) translates the (ε,δ)
  privacy budget into an adversary-magnitude bound. §3
  documents Strategy 2 :benchmarked-tier evidence and why
  LL-020 entry-level stays :argued. §5 captures five
  lessons including end-to-end correctness lives in
  benchmarks not unit tests; σ_DP/σ_true_min ratio as the
  meaningful predictor; DP at moderate ε_DP gives FPR
  elimination as a side benefit.
- **`src/julia/benchmark/results/ll020_strategy_2_detection_power_lorenz96.txt`** —
  post-fix result file. The pre-fix (negative) result is
  preserved in commit `8574670` and described in
  `docs/audit_2026-05-04.md`.

### Empirical summary

Detection-power surface at the prototype's calibration
config (Lorenz-96 N=20, F=8, k=5, n_trials=10,
N_benettin=1200, T=60):

| ε_DP   | σ_DP    | n_fit | K     | c'        | P_genuine_FPR |
|--------|---------|-------|-------|-----------|---------------|
| no DP  | 0.0000  | 3     | 0.798 | 0.00418   | 0.100         |
| 10.00  | 0.0530  | 3     | 3.106 | 0.01325   | 0.000         |
| 3.00   | 0.1766  | 1     | (insufficient transition-region points) | 0.000 |
| 1.00   | 0.5299  | 0     | (saturated at FPR floor) | 0.000 |
| 0.30   | 1.7663  | 0     | (saturated at FPR floor) | 0.000 |

DP at ε_DP=10 brings baseline FPR from 0.100 to 0.000
across all adversary magnitudes — a clean side-benefit
alongside the privacy guarantee (eliminates the round-2
§1C-A5 DoS vector at scale). Detection saturation moves
from ε_A=2 (no DP) to ε_A=3 (ε_DP=10).

### Spec impact

- **`LAVALAMP_SPEC.md`** — version 0.0.26 → 0.0.27. LL-020
  gains a "Round-2 follow-up (2026-05-04, Strategy 2
  :benchmarked-tier)" footer documenting the variance-
  convolution refinement, the benchmark result, and the
  σ_DP/σ_true_min ≈ 3 operational threshold.
  Counts unchanged (22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).
- **`artifact_registry.md`** — version 0.0.26 → 0.0.27.
  LL-020 row's Test/Proof column updated to cite the new
  benchmark + companion + diagnostic note. Cross-audit
  A1-A6 self-check refreshed for 0.0.27.
- **`dashboard.md`** — version 0.0.26 → 0.0.27. Status
  summary updated. P3 follow-ups list adds 0.0.27 entry;
  LL-020 detection-power benchmark removed from
  remaining-unblocked. Recent companion docs prepended
  with the post-fix companion + diagnostic note. Test
  suite count updated 117 → 123.

### Why

1. **Honest evidence quality.** The original LL-020 Strategy
   2 implementation (0.0.23) had unit tests passing but the
   end-to-end operational correctness (genuine device
   verification under DP) was untested. The benchmark caught
   it; the fix landed; the benchmark re-ran successfully.
   This pattern — function-level tests insufficient,
   benchmark catches operational bug — is now codified in
   CLAUDE.md §Benchmarking discipline.
2. **Privacy/detection trade-off operationalised.** The
   benchmark's σ_DP/σ_true_min predictor converts the
   abstract (ε,δ)-DP budget into a deployment design rule
   (`σ_DP ≤ X/3` for adversary magnitude X). Useful for
   threat-model reasoning that's directly comparable across
   deployment configs.
3. **Independent of round-3 trigger.** Same as the 0.0.23
   ε-DP envelope work: this is empirical refinement of an
   already-:argued strategy, not a structural claim that
   would need to wait for the closure_forces_structure paper
   update.

---

## 0.0.26 — 2026-05-03 — P-OS OS-level scoping pass (LL-022 added :argued)

Adds the OS-level identity-security scoping pass — a P2-style
architectural design pass on the one architectural seam the
project had gestured at repeatedly without ever consolidating:
the **LavaLamp ↔ OS trust boundary**. Prior entries (LL-011 TPM
in registration, LL-012 cold-start window's "out of scope"
footnote, LL-015 A3 kernel-level OOS, LL-016 TPM-signed sensor
reads, LL-020 TPM-sealed calibration) each gestured at OS-stack
dependencies without articulating them as a unified scope. This
pass consolidates them.

New entry **LL-022** (OS-trust-stack-dependency, Boundary tier,
manual evidence, `:argued`) pins the *upward* dependencies that
LavaLamp's claims rest on. **Required:** (a) hardware root of
trust (TPM 2.0 / Secure Enclave / TrustZone) for LL-011 protocol
B+D, LL-016 strategy 1, LL-020 strategy 1; (b) OS sensor APIs at
LL-005-compliant bandwidths; (c) host TRNG (`getrandom(2)` /
`SecRandomCopyBytes` / `BCryptGenRandom`) for LL-007 chaos-guard
reseed — the only required mechanism with no graceful fallback;
(d) user/kernel process isolation for LL-018 A2-margin assumption.
**Recommended (defense-in-depth):** Secure Boot / measured boot
(LL-012 cold-start composes parallel chain-of-custody); IMA /
kernel-lockdown / mandatory access control (raises A3 capability
cost without claiming defence — LL-015 unchanged); eBPF-based
sensor authentication on Linux (LL-016 strategy 1.5, between
hardware attestation and pure software cross-validation).

LL-015 (downward boundary, A3 OOS) + LL-022 (upward boundary,
trust-stack) together close the trust-stack scoping question.
Per the asymmetry-trap watch in `dashboard.md`, this is the
load-bearing place where "claim shrinks under reading" was most
likely to bite — articulating the upward dependencies positively
prevents the failure mode where a reader projects an
unconditional bound onto a system whose claims are OS-parametric.

LL-023 (early-boot-integrity-inherited) was considered as a
separate entry per the plan's optional-second-entry decision
point. **Decision: fold into LL-022 §2.3.1** (recommended-list
position). Rationale: not load-bearing-distinct from the
OS-trust-stack umbrella; mirrors how LL-015 covers all A3-class
concerns in a single entry.

### Added

- **`docs/os_identity_security_scoping_companion.md`** —
  companion. §1 computational basis (inputs, no code, no build).
  §2 results (six subsections — trust stack, required, recommended,
  out-of-scope, per-entry mapping, theorem-shape implications).
  §3 verification framing (manual → `:argued`; promotion paths
  documented). §4 spec impact. §5 five lessons (boundary entries
  close pairs not singletons; required-vs-recommended is
  load-bearing; the host TRNG is the only no-fallback dependency;
  scattered dependencies cluster into one entry; scoping
  artefacts are cheap and prevent claim drift).

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.25 → 0.0.26. New entry
  LL-022 in a new "Surfaced by P-OS OS-level scoping pass
  (0.0.26)" section. Five in-place amendments:
  - LL-011 — appends OS-dependency sub-bullet citing LL-022
    §2.2.1.
  - LL-012 — replaces the "Early-boot integrity… out of scope"
    footnote with a cross-reference to LL-022 §2.3.1 (recommended,
    not required) + LL-015 (broader OS-level boundary).
  - LL-015 — appends OS-stack pairing note (LL-015 downward +
    LL-022 upward = trust-stack scoping closure).
  - LL-016 — annotates strategy 1 with "depends on LL-022 §2.2.1";
    adds strategy 1.5 (eBPF on Linux) per LL-022 §2.3.3.
  - LL-020 — annotates strategy 1 (TPM-sealed) with "depends on
    LL-022 §2.2.1"; explicit no-LL-022-dependency note for
    strategies 2 and 3.
  Counts: total 21 → 22; `:argued` 14 → 15.
- **`artifact_registry.md`** — version 0.0.25 → 0.0.26. New
  "Surfaced by P-OS OS-level scoping pass (0.0.26)" section
  with LL-022 row. Counts updated. Cross-audit A1-A6 self-check
  refreshed for 0.0.26.
- **`dashboard.md`** — version 0.0.25 → 0.0.26. Status summary
  rewritten to capture P-OS landing. Spec-status counts updated.
  P-OS added to priority stack as a closed item between P-R2
  and P-R3. Recent companion docs list prepended with the new
  companion.
- **`README.md`** — status block counts corrected (pre-existing
  drift: README showed `:tested` 3 / `:benchmarked` 3 since
  0.0.25 instead of the spec's 2 / 4) and updated to 0.0.26
  (22 total, `:argued` 15).

Test suite: 117/117 still passes (~52s); the P-OS pass is
design-only and adds no code or tests.

### Why

1. **Asymmetry-trap defence.** Five spec entries had gestured at
   OS-stack dependencies; none had named them. A reader scanning
   any one entry could miss that the same OS-trust-stack
   assumption was load-bearing across the spec. The
   asymmetry-trap watch in `dashboard.md` flagged exactly this
   "claim shrinks under reading" failure mode. LL-022's cost
   (one design-pass session, no code) is small relative to the
   risk it mitigates.
2. **Independent of the round-3 trigger.** This pass does not
   surface content that would inform LL-021 worst-case bounds
   or the C-conjugate-inheritance argument; it could land in
   parallel without round-3 gating. Used the slack while
   waiting for the closure_forces_structure paper update.
3. **Pre-Lean discipline.** §2.6 pins the theorem-statement
   shape for any future Lean proof of an LL claim that depends
   on an LL-022 mechanism: `forall (os : OSAssumptions)
   (proof_os : LL022.satisfies os), <LL_property>`. This makes
   the OS dependency explicit in the theorem statement rather
   than implicit in surrounding text — the asymmetry-trap
   defence at the formal level.

---

## 0.0.25 — 2026-05-03 — P3d SDE-selection benchmark (LL-003 :benchmarked)

Closes LL-003 from `:tested` to `:benchmarked` via a
comparative SDE-selection bench across Lorenz-96 / Lorenz-63
/ Rössler. The architecture-design §2.3 recommendation
("Lorenz-96 is the leading candidate") is empirically
justified by the comparative table.

Adds Lorenz-63 and Rössler implementations to Engine.jl as
alternate SDE candidates, validated against literature
values during smoke-testing (Lorenz-63 λ ≈ [0.929, 0.001,
-14.597] vs lit [0.91, 0, -14.6]; Rössler λ ≈ [0.076, 0,
-5.147] vs lit [0.07, 0, -5.4]).

Comparative result (5 trials per SDE):

| SDE | dim | λ₁ | n_pos | h_KS | KY | wall_s |
|---|---:|---:|---:|---:|---:|---:|
| Lorenz-96 N=40 | 40 | 1.674 | 13.4 | 10.257 | 27.0 | 3.95 |
| Lorenz-63 | 3 | 0.898 | 1.6 | 0.900 | 2.06 | 0.29 |
| Rössler | 3 | 0.065 | 1.4 | 0.066 | 2.01 | 0.26 |

Lorenz-96 dominates on every security-relevant axis: 155×
the h_KS of Rössler, 11× of Lorenz-63; 8.4× more positive
exponents; 13× the Kaplan-Yorke dimension. Compute cost
is ~14× the cheapest but per-h_KS efficiency is comparable;
absolute h_KS matters for the LL-008 / LL-018 resolution-
bound margin.

### Added

- **`src/julia/src/Engine.jl`** —
  - `lorenz63_eom!(du, u, p, t)` + `lorenz63(; σ=10, ρ=28,
    β=8/3, u0=nothing)`
  - `rossler_eom!(du, u, p, t)` + `rossler(; a=0.2, b=0.2,
    c=5.7, u0=nothing)`
  Both with standard chaotic-regime defaults; both
  smoke-validated against literature.
- **`src/julia/src/LavaLamp.jl`** — re-exports.
- **`src/julia/benchmark/p3d_sde_selection.jl`** —
  comparative benchmark script. 5 trials per SDE;
  per-system N_benettin / Δt / Ttr appropriate to each
  system's time scale.
- **`src/julia/benchmark/results/p3d_sde_selection.txt`** —
  committed comparative table + h_KS ratios.
- **`docs/p3d_sde_selection_companion.md`** — companion.
  §2 per-axis comparison; §2.5 architectural justification
  of the choice; §2.6 deployment guidance (Lorenz-63
  fallback for resource-constrained; Rössler not
  recommended); §3 verification framing; §4 spec impact;
  §5 four lessons including "comparative benchmarks
  justify defaults" and "negative-result + positive-result
  sequences."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.24 → 0.0.25. LL-003
  evidence type `example-tested` → `benchmarked`; status
  `:tested` → `:benchmarked`; description amended with
  comparative-bench results + dominance ratios. Counts:
  `:tested` 3 → 2; `:benchmarked` 3 → 4. Total 21
  unchanged.
- **`artifact_registry.md`** — version 0.0.24 → 0.0.25.
  LL-003 row updated.
- **`dashboard.md`** — version 0.0.24 → 0.0.25. P3 sub-
  items list adds 0.0.25 entry; P3d removed from
  remaining-unblocked. Spec status counts.

Test suite: 117/117 still passes (~52s); the new SDE
constructors are not in the persistent test suite (they're
benchmark-only candidates).

### Why

P3d was the third and final sub-task in the work-set
unfastened by user direction 2026-05-03. With LL-003
:benchmarked, the prototype's headline architectural choice
("the SDE is Lorenz-96") now has comparative-benchmark
justification, not just literature-match testing.

The benchmark also surfaces useful deployment guidance:
Lorenz-63 is a viable low-power fallback (~10× cost
reduction; ~10× h_KS reduction; documented margin trade-
off); Rössler is the "what insufficient chaos production
looks like" anchor.

This commit + 0.0.23 (positive — ε-DP) + 0.0.24 (negative
— Nyquist) form a three-session sequence with mixed
positive / negative outcomes; all three commit honest
evidence per the lavalamp pattern.

### Spec impact

- Counts: total 21 unchanged; `:tested` 3 → 2 (LL-003
  leaves); `:benchmarked` 3 → 4 (LL-003 enters);
  others unchanged.
- Status moves: LL-003 → `:benchmarked`.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 2 (LL-004, LL-007)
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-021)
- `:argued`: 14
- `:open`: 1 (LL-015)

### Trajectory of :benchmarked count

| commit | :benchmarked | event |
|---|---:|---|
| 0.0.16 | 0 | round-2 cohort not yet started |
| 0.0.17 | 1 | LL-006 (P3-bound) |
| 0.0.18 | 2 | LL-021 (worst-case) |
| 0.0.19 | 3 | LL-019 (timing) |
| 0.0.25 | 4 | **LL-003 (SDE choice)** |

Four `:benchmarked` entries — substantial empirical
evidence backing the architectural choices.

### Known gaps

- **Per-SDE detection-probability surface.** The
  P3-bound + LL-021 :benchmarked work was Lorenz-96-
  specific. Rerunning the same fits for Lorenz-63 /
  Rössler would let deployments document expected
  detection probability per SDE choice.
- **Higher-N Lorenz-96 scaling.** N ∈ {20, 40, 80, 160}
  scaling could justify a "large-N" deployment mode.
- **C/C++ implementation cost.** Wall-clock numbers are
  Julia-specific; comparative ratios should hold under
  P7 hardening but absolute costs differ.

### Followup recommendations

- **Higher-resolution P-R2c refresh** to tighten LL-021's
  c′ binding constraint.
- **Detection-power-vs-ε benchmark** for LL-020 Strategy 2.
- **Higher-resolution LL-019 KS-test** at α=0.01.
- **LL-005 round-3 input.** The 0.0.24 negative finding
  + this benchmark's reaffirmation of Lorenz-96 don't
  resolve the Nyquist-detection gap; round-3 architectural
  review.
- **Round-3 trigger** unchanged (after closure_forces_structure
  paper update).

---

## 0.0.24 — 2026-05-03 — P3-Nyq negative result on Nyquist detection

P3-Nyq adversary-rate benchmark attempted to demonstrate
that the residue audit (LL-006) detects sub-Nyquist sensor
adversaries per LL-005's architecture-design claim. Result:
**negative**. The residue audit does NOT detect sub-Nyquist
sensor reconstruction at the prototype's configuration.

This is honest architectural feedback, not a failure.
LL-005 stays `:argued` (no spec status change). The
benchmark output is committed as audit-trail evidence that
the testing was attempted and produced a structural-gap
finding.

### Added

- **`src/julia/benchmark/p3_nyq_adversary_rate.jl`** —
  benchmark script. Genuine system uses
  `gaussian_noise_stream(σ=1.0, sample_rate=100 Hz)`.
  Adversary observes the genuine stream at sub-Nyquist
  sample rate `f_adv` and reconstructs via linear
  interpolation. Sweep `f_adv ∈ {1, 2, 5, 10, 20, 50, 100}
  Hz` × 20 trials per point.
- **`src/julia/benchmark/results/p3_nyq_adversary_rate.txt`**
  — committed empirical surface. Across all `f_adv` values
  the rejection rate scatters between 0% and 20% with no
  monotonic trend. Wilson 95% CIs for n=20 samples are all
  overlapping; no point is statistically distinguishable
  from the genuine FPR baseline (1/20 = 0.05).
- **`docs/p3_nyq_companion.md`** — companion doc.
  - §2.1 the empirical sweep with no monotonic detection
    trend.
  - §2.2 architectural reason for the negative result:
    zero-mean Gaussian noise → time-averaged sensor
    statistics invariant under sub-sampling → spectrum
    (a time-averaged invariant) doesn't shift.
  - §2.3 architectural implication: the residue audit
    catches parameter-perturbation attacks (V-001, V-013,
    V-005) but not sensor-bandwidth attacks (V-004 Nyquist
    failure). LL-005 is a parameter-level hygiene
    requirement (correctly configured), not an actively-
    defended attack surface.
  - §2.4 mechanisms that *would* detect sub-Nyquist
    adversaries (trajectory-checkpoint comparison,
    FFT-based audit, LL-016 sensor authenticity);
    none currently in the prototype.
  - §2.5 honest tier framing: LL-005 has implicit sub-
    claims (parameter compliance + adversary detection);
    only the parameter side is evidenced; entry-level
    stays `:argued`.
  - §3 verification.
  - §4 spec impact (notes amendment, no status moves).
  - §5 four lessons including "negative results are
    valuable evidence" and "when in doubt, document the
    negative."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.23 → 0.0.24. LL-005
  notes amendment recording the benchmark and the negative
  finding's architectural implication. No entry-level
  status change.
- **`artifact_registry.md`** — version 0.0.23 → 0.0.24.
  Cross-audit A5 reference updated.
- **`dashboard.md`** — version 0.0.23 → 0.0.24. P3 sub-
  items list adds 0.0.24 entry; P3-Nyq removed from
  remaining-unblocked list (now landed with negative
  result). LL-005 part-(a) parameter-validation test added
  as a small trivial-cost follow-up.

### Why

The Nyquist condition (LL-005) is necessary for the
*physical security claim* (substrate-noise can't be
reconstructed at sub-Nyquist) but the residue audit doesn't
*enforce* it as an attack vector. The benchmark surfaces
this gap empirically.

The structural reason: spectrum-based detection averages
over time, and time-averaged statistics of a zero-mean noise
sensor are invariant under sub-sampling. The audit is the
right tool for parameter-perturbation attacks (already
:benchmarked via LL-006 / LL-021) but the wrong tool for
bandwidth-violation attacks.

This is a real architectural finding worth pinning. Round-3
reviewers should evaluate whether the prototype's residue-
audit-only defence is sufficient given LL-016 covers the
gap (already :argued for sensor authenticity) or whether an
additional mechanism is needed.

Don't fudge the negative result. The committed benchmark
output is honest-discipline evidence.

### Spec impact

- Counts: total 21 unchanged; status counts unchanged
  (3 :tested / 3 :benchmarked / 14 :argued / 1 :open).
- Status moves: none.
- Notes amendment on LL-005 recording the negative
  finding + architectural implication.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 14
- `:open`: 1 (LL-015)

### Followup recommendations

- **Round-3 architectural input.** This finding is a real
  candidate for the next round-3 brief: does the prototype
  need an FFT-based audit or a trajectory-checkpoint
  audit to close the Nyquist-detection gap? Or is LL-016
  sensor authenticity sufficient?
- **LL-016 implementation** is the load-bearing defence
  per this benchmark's finding. P7 / P5 work via TPM
  attestation / multi-sensor cross-validation.
- **P3d SDE-selection benchmark** is the next sub-task in
  the work-set (closes LL-003 to :benchmarked).
- **Parameter-validation test for LL-005** (trivial; would
  move part-(a) to :tested) deferred until the
  adversary-side gap is addressed (otherwise the partial
  upgrade misleads).

---

## 0.0.23 — 2026-05-03 — LL-020 Strategy 2 ε-DP envelope stub

Implements Strategy 2 of LL-020 (ε-differentially-private
envelope perturbation) per the P-R2b design. Pure-Julia
implementation of the Dwork-Roth Gaussian mechanism with
the canonical σ_DP = sensitivity · sqrt(2·log(1.25/δ))/ε
formula. 23 new test assertions covering the mechanism +
DP metadata + argument validation + reproducibility.

LL-020 entry-level status remains `:argued`. The entry's
claim is the three-strategy approach (TPM-sealed + ε-DP +
Shamir-threshold) as a whole; Strategy 2's example-tested
implementation is recorded as a notes amendment. Strategies
1 and 3 remain implementation-deferred per the P-R2b
design (P7 / P5 respectively).

This is the first commit since the architectural-debt
closure (0.0.20 / 0.0.22) to add new code; pre-paused
constraint relaxed by user direction. Slower without engine
upstream; may need rework when paper / engine updates land,
but progress now over indefinite wait.

### Added

- **`src/julia/src/Audit.jl`** —
  `differentially_private_envelope(env; ε, δ=1e-6,
  sensitivity=0.1, rng=default_rng())`. Returns a new
  `Envelope` with each component of `spectrum` and `σ`
  perturbed by `Gaussian(0, σ_DP²)`; σ floored at 1e-10
  (DP-safe via post-processing immunity); DP parameters
  recorded in metadata for downstream audit.
- **`src/julia/src/LavaLamp.jl`** — re-exports.
- **`src/julia/test/runtests.jl`** — 23 new assertions in
  the LL-020 `@testset`: type checks; length / n_trials /
  metadata preservation; σ_DP formula verified to 1e-10
  precision; σ floor enforced; tight-ε produces large σ_DP
  + substantial perturbation; loose-ε produces near-
  identity perturbation; argument validation
  (ε ≤ 0, δ ≤ 0, δ ≥ 1, sensitivity ≤ 0 all throw);
  reproducibility (same seed → same result).
- **`docs/ll020_strategy_2_epsilon_dp_companion.md`** —
  session companion. §1 build / run. §2 results: §2.1
  Gaussian mechanism review; §2.2 sensitivity bound
  argument with prototype default of 0.1; §2.3
  privacy-vs-detection-power trade-off documented in
  concept (benchmark deferred); §2.4 σ-floor DP-safety via
  post-processing immunity; §2.5 empirical σ_DP scaling
  table; §2.6 reproducibility note. §3 verification:
  why entry-level stays :argued; what Strategy-2-:tested
  establishes vs what it doesn't. §4 spec impact (notes
  amendment, no status moves; counts unchanged). §5 four
  lessons including "strategy-of-strategies entries land
  in chunks" and "honest entry-level status protects
  against partial-claim drift."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.20 → 0.0.23. LL-020
  notes amendment recording Strategy 2 implementation +
  example-tested status. No entry-level status change.
- **`artifact_registry.md`** — version 0.0.20 → 0.0.23.
  LL-020 row Test/Proof file updated to reference both
  P-R2b design companion AND new Strategy 2 companion;
  Source file points at `Audit.jl` (Strategy 2 only).
  Cross-audit A5 reference updated.
- **`dashboard.md`** — version 0.0.22 → 0.0.23. P3 sub-items
  list adds 0.0.23 entry; "ε-DP envelope stub" removed
  from remaining-unblocked list (now landed). Detection-
  power-vs-ε benchmark added as new follow-up for
  Strategy 2 :benchmarked upgrade.
- **`changelog.md`** — this entry.

Test suite: 94 → 117 assertions; passes in ~52s via
`Pkg.test()`.

### Why

User direction 2026-05-03: "we can do those" (referring to
P3d / P3-Nyq / ε-DP stub previously excluded as adding
new code). Constraint relaxation; "may need to revisit"
acknowledged but progress over wait.

The ε-DP stub was chosen first because it's smallest
(single function + tests; no new SDEs or new benchmark
infrastructure) and most isolated (LL-020 alone; no
upstream / downstream coupling).

Honest entry-level status (LL-020 stays :argued) per the
"strategy-of-strategies" lesson captured in companion §5.1:
multi-strategy entries land in chunks, and entry-level
status reflects the weakest sub-claim's evidence. Notes
record per-strategy progress.

### Spec impact

- Counts: total 21 unchanged; status counts unchanged
  (3 :tested / 3 :benchmarked / 14 :argued / 1 :open).
- Status moves: none.
- Notes amendment on LL-020 recording Strategy 2's
  example-tested evidence.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 14
- `:open`: 1 (LL-015)

### Followup recommendations

- **Detection-power-vs-ε benchmark** for Strategy 2 — the
  natural :benchmarked upgrade. Run the P3-bound detection-
  probability sweep against `differentially_private_envelope`
  output at varying ε; trace the trade-off curve.
- **P3-Nyq adversary-rate Nyquist benchmark** — next sub-
  task in this work-set (closes LL-005 to :tested).
- **P3d SDE-selection benchmark** — third sub-task in the
  work-set (closes LL-003 to :benchmarked).
- **Lean theorem.** Gaussian mechanism (ε, δ)-DP textbook
  proof; round-2 §1D.v priority 3 target. P5/P6 work.
- **Strategy 1 (TPM-sealed) implementation** — P7 hardening
  via platform FFI.
- **Strategy 3 (Shamir threshold) implementation** — P5
  Haskell or finite-field cryptography library. Closes
  the LL-020 entry-level claim when combined with
  Strategies 1 and 2.

---

## 0.0.22 — 2026-05-03 — A0-A6 cross-audit pass (PASS across all six checks)

Full cross-audit per CLAUDE.md §Cross-audit protocol,
triggered by the closure-pass (0.0.20) + drift-fix (0.0.21).
First explicit full A0-A6 pass since the prototype began
(individual checks have been run inline at every commit).

**Result: PASS across all six checks.** No drift requiring
remediation. The CLAUDE.md drift surfaced by A0 was fixed in
0.0.21 before this audit ran.

### Added

- **`docs/audit_2026-05-03.md`** — findings document.
  §1 A0 self-audit (PASS post-0.0.21); §2 A1 coverage
  (21/21 LL-IDs have registry rows); §3 A2 key match
  (spec keys ↔ registry abbreviated labels — intentional
  for table formatting); §4 A3 evidence-file existence
  (all 12 cited paths resolve via git ls-files); §5 A4
  status-evidence honesty (all 21 entries pass the rule
  table); §6 A5 stale counts (spec / registry / dashboard
  / CLAUDE.md all show 3/3/14/1 of 21); §7 A6 test sync
  (all :tested / :benchmarked entries have committed
  evidence; CI runs Pkg.test() on every push). §8
  summary table. §9 process notes including future
  cross-audit cadence + inline-discipline observation +
  what the audit does NOT establish (consistency, not
  substance).

### Changed

- **`dashboard.md`** — version 0.0.20 → 0.0.22 (skipping
  0.0.21 which only touched CLAUDE.md / README.md).
- **`changelog.md`** — this entry.

### Why

Per the lavalamp CLAUDE.md §Cross-audit protocol guidance:
"Run when integrating substantial new work, preparing a
release, or after the spec is materially changed." The
closure pass (0.0.20) + drift fix (0.0.21) constituted
substantial spec-state and documentation changes. Running
the full cross-audit pass formalises what the inline
discipline has done piecewise across all P3 / P-R2 /
benchmarked-cohort sessions; the PASS result confirms that
the discipline held.

This is the cleanest cross-audit result possible — every
check passes, no findings to remediate.

### Spec impact

None. Counts unchanged from 0.0.20: 21 / 0 / 0 / 3 / 3 / 14
/ 1.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 14
- `:open`: 1 (LL-015)

### Followup recommendations

- Future cross-audit triggers: after round-3 (when the
  physics-paper update lands), before P5 / P6 substantial
  work, after any session that adds more than two new spec
  entries.
- The inline A1/A4/A5 discipline (cross-audit clean
  "X + Y + Z = 21" assertion in commit messages) should
  continue.

---

## 0.0.21 — 2026-05-03 — CLAUDE.md + README.md drift fix

Status section + priority list update across CLAUDE.md and
README.md. No spec moves; no code changes. A0 self-audit
per the cross-audit protocol: drift fixed here, not papered
over in the project. The CLAUDE.md was written at concept-
stage (2026-04-30) and required updating to reflect the
prototype-stage reality after the round-2 :benchmarked
cohort + closure pass landed.

### Changed

- **`CLAUDE.md`**:
  - §Status: "Concept-stage" → "Prototype-stage" with the
    actual trajectory across 0.0.3 - 0.0.20; spec ledger
    snapshot inline; round-3 trigger noted.
  - "For LavaLamp specifically (priority order)" subsection:
    P1/P2 marked landed with version numbers; P3
    substantively done with sub-item version mapping; P5/P6
    targets refreshed to reflect Lean priorities from
    round-2 §1D.v + the :benchmarked-cohort grounding.
- **`README.md`**:
  - "Concept-stage" → "Prototype-stage" header.
  - §Status: spec ledger table inline; trajectory bullet;
    expanded companion-doc list (17 docs).
  - §Layout: tree view shows actual src/julia/ structure
    instead of the "no code until P1+P2 complete" framing.

### Spec impact

None. Counts unchanged from 0.0.20: 21 / 0 / 0 / 3 / 3 / 14
/ 1.

---

## 0.0.20 — 2026-05-03 — Closure pass; only LL-015 remains :open

Closure-pass session: four `:open` spec entries elevated to
`:argued` based on evidence already accumulated across
earlier sessions. No new specs; no new code; no new tests.
Pure spec-state finishing.

After this commit, **only LL-015 (A3-OOS scoping declaration)
remains `:open`** — permanently, by design (it is a scoping
boundary, not a verifiable claim). Every other spec entry has
at least `:argued` evidence; six entries have empirical
:tested or :benchmarked evidence.

### Added

- **`docs/spec_closure_pass_companion.md`** — closure-pass
  companion. §1 LL-001 (composed claim argued via component
  evidence: LL-003 :tested, LL-004 :tested, LL-006
  :benchmarked, LL-007 :tested). §2 LL-002 (visual ↔
  security decoupling preserved by construction across the
  Julia prototype: no visual layer exists, security
  primitive has no visual-layer imports). §3 LL-009 (no
  complex numbers; Float64 throughout the security path).
  §4 LL-010 (bounded N, Δt; finite-dim Lorenz-96; no
  autopoietic dynamics). §5 why LL-015 stays `:open`
  permanently. §6 considered-and-dropped: LL-017 verify-
  level no-oracle is :tested-grade evidence but the entry
  also covers protocol-level which isn't implemented;
  honest tier stays :argued without subdividing the entry
  (which would add a new spec). §7 spec impact + counts.
  §8 process notes including closure-pass discipline as a
  reusable pattern for future sessions.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.19 → 0.0.20.
  Status moves :open → :argued with evidence type none →
  manual on LL-001, LL-002, LL-009, LL-010. Source paths
  point at the closure-pass companion. Counts: `:argued`
  10 → 14; `:open` 5 → 1.
- **`artifact_registry.md`** — version 0.0.19 → 0.0.20.
  Four row updates. Counts.
- **`dashboard.md`** — version 0.0.19 → 0.0.20. Status
  summary updated to reflect "spec essentially fully
  argued." Spec status counts. The closure pass is noted
  as the elevation source.
- **`changelog.md`** — this entry.

### Why

The user's constraint for this session: "close out without
adding anything new from a feature/spec perspective. updating
spec states would be within scope. No new specs though
unless discovered via a proving path." All four moves are
status upgrades on existing entries; the considered-but-
dropped LL-017 upgrade was excluded specifically because
subdivision counts as adding new specs.

The pattern is closure-pass discipline: periodically audit
the spec for entries whose evidence is implicit in
already-completed work but whose spec status has lagged.
Elevate to match the evidence. The lavalamp CLAUDE.md
"honest framing" rule is the discipline boundary — only
elevate when evidence actually meets the taxonomy's
requirements; don't force scoping declarations into argued
status.

### Spec impact

- Counts: total 21 unchanged; `:argued` 10 → 14 (+ LL-001,
  LL-002, LL-009, LL-010); `:open` 5 → 1 (− those four);
  `:tested` / `:benchmarked` unchanged.
- Status moves to `:argued`: LL-001, LL-002, LL-009, LL-010.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 14
- `:open`: 1 (LL-015)

### Trajectory

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

### Known gaps

- **LL-015 stays `:open` permanently.** Scoping declaration
  with no verification path. Future sessions should not
  attempt to upgrade.
- **No new evidence.** This commit elevates spec states
  based on existing evidence; no new tests, benchmarks, or
  proofs.
- **Round-3 trigger unchanged.** Still gated on the
  closure_forces_structure paper update.

### Followup recommendations

The closure-pass discipline can be reapplied periodically.
Currently no new evidence is available to elevate other
entries; further elevations would require either (a) the
P3d / P3-Nyq / ε-DP-stub work that remains queued, or (b)
P5/P6 Lean / Haskell formal verification. Both wait for
the next session.

---

## 0.0.19 — 2026-05-03 — LL-019 :benchmarked (timing-distribution KS test); round-2 cohort complete

Closes LL-019 from `:tested` to `:benchmarked` via a two-
sample Kolmogorov-Smirnov test on response-time
distributions for `verify_constant_time` and plain `verify`,
bucketed by verify result (accept vs reject).

LL-019 :benchmarked claim met: `verify_constant_time`
produces a response-time distribution where accept-bucket
and reject-bucket are statistically indistinguishable per
KS test at α = 0.05 (KS_stat = 0.109 < critical = 0.170).

This closes the round-2 :benchmarked cohort: LL-006
(P3-bound), LL-021 (worst-case), LL-019 (timing-
indistinguishability) — three sequential same-day sessions
across 0.0.17/0.0.18/0.0.19, each with appropriate test
methodology (constrained-fit on bound-shape claims for
LL-006 and LL-021; KS-test on distributional-equality
claim for LL-019).

### Added

- **`src/julia/benchmark/ll019_timing_distribution.jl`** —
  timing-distribution benchmark with manual two-sample KS
  test. 20 distinct genuine λs + 20 distinct adversary λs
  (BROAD direction, ε_A = 2.0); 10 timed calls each = 400
  total samples per benchmark function (`verify` and
  `verify_constant_time`). Buckets samples by verify
  result, not input source — corrects the design flaw of
  the first iteration where input-source bucketing
  conflated input-type with verify-result and produced a
  misleading DISTINGUISHABLE verdict on the genuine bucket
  with mixed accept/reject paths.
- **`src/julia/benchmark/results/ll019_timing_distribution.txt`**
  — committed benchmark output with summary statistics
  (median, mean, std), KS statistics, critical value, and
  verdicts for both `verify` and `verify_constant_time`.
- **`docs/ll019_benchmarked_companion.md`** — companion
  with §2.1 hypothesis test setup, §2.2 bucketing-by-
  result design, §2.3 results (KS_stat=0.041 for `verify`;
  0.109 for `verify_constant_time`; both INDISTINGUISHABLE
  at α=0.05), §2.4 honest interpretation (prototype-scale
  `verify` passes empirically because data-dependent
  timing is below OS jitter; production-scale would
  emerge channel that constant-time wrapper defeats),
  §2.5 performance target met, §2.6 sample-size
  considerations, §2.7 comparison to LL-006 and LL-021
  :benchmarked methodologies, §3.3 Lean theorem grounding
  per round-2 §1D.v priority 2, §5 four lessons including
  "bucket by result, not input" and "different test
  shapes for different performance-target shapes."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.18 → 0.0.19. LL-019
  evidence type `example-tested` → `benchmarked`; status
  `:tested` → `:benchmarked`; description amended with
  KS-test results + production-scale honest framing.
  Counts: `:tested` 4 → 3; `:benchmarked` 2 → 3. Total 21
  unchanged.
- **`artifact_registry.md`** — version 0.0.18 → 0.0.19.
  LL-019 row updated with benchmark + companion paths.
- **`dashboard.md`** — version 0.0.18 → 0.0.19. LL-019
  marked ✓ landed at :benchmarked. Spec status counts.
  Round-2 :benchmarked cohort marked complete.
- **`changelog.md`** — this entry.

### Why

LL-019 :benchmarked uses a different test shape than
LL-006 and LL-021. The latter two have bound-shape claims
(P(detect) ≥ 1 - K·exp(-c·T·ε²)); the constrained-fit
methodology validates them. LL-019's claim is
distributional equality (F_accept = F_reject), which the
two-sample Kolmogorov-Smirnov test validates via empirical
CDF comparison.

This session also surfaced a benchmark-design lesson worth
recording: timing-channel benchmarks must bucket by the
*channel's putative cause* (verify result), not by proxy
categories (input source). The first iteration bucketed by
input source and reported false-positive DISTINGUISHABLE on
verify_constant_time; the bucketing-by-result fix produced
the correct INDISTINGUISHABLE result.

The "plain verify also passes KS test" finding is honest
and not surprising at the prototype's scale: 20-component
spectrum comparison runs in microseconds, with sub-µs
data-dependent path differences hidden by OS scheduling
jitter. The constant-time wrapper is the
production-grade defence; the prototype's verify happens
to be too fast for the channel to manifest at this scale.

### Spec impact

- Counts: total 21 unchanged; `:tested` 4 → 3 (LL-019
  leaves); `:benchmarked` 2 → 3 (LL-019 enters); others
  unchanged.
- Status moves: LL-019 → `:benchmarked`.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-007)
- `:benchmarked`: 3 (LL-006, LL-019, LL-021)
- `:argued`: 10
- `:open`: 5

### Round-2 :benchmarked cohort summary

| spec | session | landed | constants / test |
|---|---|---|---|
| LL-006 detection bound | P3-bound | 0.0.17 | K=1, c′=0.00423, T=60 |
| LL-021 worst-case bound | LL-021 :benchmarked | 0.0.18 | K=1, c′=0.02777, T=60 (parameterised on ε_eff) |
| LL-019 timing-indistinguishability | LL-019 :benchmarked | 0.0.19 | KS_stat=0.109 < 0.170 at α=0.05 |

Three sessions across 0.0.17 → 0.0.19. Each test
methodology matches its claim shape.

### Known gaps

- **α=0.05 only.** Tighter α (0.01, 0.001) would require
  more samples per bucket. Deferred.
- **Prototype-scale only.** Plain `verify` passes KS at
  µs scale because OS jitter masks sub-µs data-dependent
  timing. Production-scale (ms data-dependent paths)
  would need a different benchmark to confirm channel
  emergence and constant-time defeat.
- **No formal proof.** Statistical validation at α=0.05
  is not a formal proof. Round-2 §1D.v Lean priority 2 is
  the formal target; this benchmark grounds the theorem
  statement (§3.3 of the companion).

### Followup recommendations

- **Higher-resolution KS test at α=0.01.** Same shape;
  more samples.
- **Production-scale wrapper KS test.** Wrap `verify_full`
  (full Benettin spectrum, ms-scale data-dependent
  timing) and run the KS test; confirm constant-time
  defeats the channel that emerges.
- **P3d SDE-selection benchmark** (LL-003 :benchmarked).
- **P3-Nyq adversary-rate benchmark** (LL-005 :tested).
- **ε-DP envelope stub** (LL-020 Strategy 2 :tested).
- **Lean side-channel theorem** per §3.3 of the
  companion. P5/P6 work.

---

## 0.0.18 — 2026-05-03 — LL-021 :benchmarked (worst-case bound constants fitted)

Closes LL-021 from `:tested` to `:benchmarked` by applying
the P3-bound constrained-fit methodology (introduced in
0.0.17) to the existing P-R2c worst-case detection surface
(0.0.15 commit). No new code; pure analysis on the
already-committed `p_r2c_structured_lorenz96.txt`.

Fitted worst-case constants: **K=1, c′=0.02777, T=60** for
the prototype's two-channel coupling (b_1=e_1 narrow vs
b_2=ones(N) broad). `c′_worst = 0.02777` is **6.6× larger
than `c′_isotropic = 0.00423`** from P3-bound (LL-006) —
the two bounds describe the same shape under different
parameterisations: LL-006 absorbs ∂λ/∂α into c′ at the
isotropic-equivalent direction; LL-021 separates direction
effects via `ε_eff = ε_A · proj(û onto m_unit)`.

Bound holds at 9 of 12 data points pointwise; the 3
negative-margin points (NARROW ε_A=1.00, NARROW ε_A=4.00,
MIXED ε_A=0.50, all 0/5 sample frequency) have Wilson 95%
CIs covering the bound's prediction. Sampling variance at
n=5 accounts for apparent margin failures.

### Added

- **`docs/ll021_benchmarked_companion.md`** — analysis
  companion. §2.1 reframes the bound under direction
  projection (`ε_eff = ε_A · proj(û onto m_unit)`).
  §2.2 derivation: per-point c_max under K=1 constraint,
  binding at MIXED ε_A=1.0 with c_max ≈ 0.0278. §2.3 bound
  predictions vs empirical at all 12 points (9 hold).
  §2.4 Wilson CI analysis for the 3 negative-margin points
  (all CIs cover bound prediction). §2.5 n=5 sampling-
  variance caveat with deferred higher-resolution refresh.
  §2.6 comparison to LL-006 constants explaining the 6.6×
  ratio. §2.7 Lean theorem grounding per round-2 §1D.v
  priority 1. §5 captures four lessons including
  "direction projection collapses a multi-direction surface
  into a single bound" and "methodology continuity across
  sessions is the lavalamp pattern."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.17 → 0.0.18.
  LL-021 evidence type `example-tested` → `benchmarked`;
  status `:tested` → `:benchmarked`; description amended
  with fitted constants + 6.6× ratio context. Counts:
  `:tested` 5 → 4; `:benchmarked` 1 → 2. Total 21
  unchanged.
- **`artifact_registry.md`** — version 0.0.17 → 0.0.18.
  LL-021 row updated with companion path.
- **`dashboard.md`** — version 0.0.17 → 0.0.18. LL-021
  marked ✓ landed at :benchmarked. Spec status counts.
  Remaining unblocked sub-items refined.

### Why

LL-021 :benchmarked was the natural follow-up to P3-bound
0.0.17: same constrained-fit methodology, applied to an
already-committed benchmark surface, with the analytic
direction-projection framing from
`docs/p_r2c_worst_case_adversary_companion.md` §2.1
providing the parameterisation that collapses the
12-point P-R2c surface onto a single bound curve.

The 6.6× ratio between the two bounds' c′ constants is
informative: it quantifies how much the direction-aware
worst-case framing tightens the bound vs the isotropic
parameterisation. The two bounds describe the same shape
under different inputs; the ratio is the cost the
adversary pays for misalignment with m_unit.

The Wilson CI framing for the 3 negative-margin points
preserves the lavalamp CLAUDE.md "honest framing" rule:
sampling variance accounts for the apparent margin
failures; the bound holds in expectation. Higher-resolution
refresh (15+ trials per point) is documented as a
follow-up that would tighten the validation.

### Spec impact

- Counts: total 21 unchanged; `:tested` 5 → 4 (LL-021
  leaves); `:benchmarked` 1 → 2 (LL-021 enters); others
  unchanged.
- Status moves: LL-021 → `:benchmarked`.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 4 (LL-003, LL-004, LL-007, LL-019)
- `:benchmarked`: 2 (LL-006, LL-021)
- `:argued`: 10
- `:open`: 5

### Known gaps

- **n=5 sampling at P-R2c.** Higher-resolution refresh
  (15+ trials per point) would tighten the c′ binding
  constraint. Deferred — current fit is honest at n=5
  with Wilson CI framing.
- **Configuration-specific.** K=1, c′=0.02777, T=60 are
  for the prototype's 2-channel coupling. Other channel
  configurations would have different c′; the bound's
  shape is universal.
- **No analytic ∂λ/∂F̄ derivation.** The proportionality
  constant is empirical; a Lean derivation would derive
  it from the SDE structure.

### Followup recommendations

- **LL-019 :benchmarked upgrade** — different shape
  (response-time distribution KS-test); requires a new
  benchmark.
- **Higher-resolution P-R2c refresh** — 15+ trials per
  (direction, magnitude) point; tightens LL-021 c′.
- **P3d SDE-selection benchmark** — LL-003 :benchmarked.
- **P3-Nyq Nyquist adversary-rate** — LL-005 :tested.
- **ε-DP envelope stub for LL-020 Strategy 2** — would
  upgrade Strategy 2 specifically to :tested.
- **Lean target.** Both LL-006 and LL-021 now have
  concrete K, c′, T constants; the unified Lean theorem
  in `ll021_benchmarked_companion.md` §2.7 is the P5/P6
  target.

---

## 0.0.17 — 2026-05-03 — P3-bound LL-006 :benchmarked (first benchmarked entry)

Closes the P3-bound followup: high-resolution detection-
probability sweep + constrained constant fit empirically
validates the architecture-design §2.1 detection-probability
bound shape with concrete constants for the prototype's
configuration. LL-006 closes from `:tested` to `:benchmarked`
— the project's first `:benchmarked`-tier entry.

Fitted constants: **K = 1, c′ = 0.00423, T = 60** for
Lorenz-96 N=20, F=8, single uniform-coupling channel, k=5,
n_calibration=10. Bound holds at all 10 transition +
saturation data points; one FPR-floor point (ε_A=0.50,
empirical 0/15) is below bound by 0.062 but consistent with
sampling variance (Wilson 95% CI [0, 0.215] covers bound
prediction 0.061). Constrained-fit methodology (max c′ such
that bound holds at every transition point) used rather than
least-squares — least-squares would have produced an
over-tight bound that fails at two transition points.

### Added

- **`src/julia/benchmark/p3_bound_high_res.jl`** — high-
  resolution sweep at finer ε_A grid + more trials per
  point than the original P3b benchmark. ε_A ∈ {0, 0.25,
  0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0}; 15
  trials per point; uses `verify_full` per LL-019 audit-
  on-every-verify. Records per-trial residue (max abs Δλᵢ)
  for δ_A estimation alongside P_reject.
- **`src/julia/benchmark/results/p3_bound_high_res_lorenz96.txt`**
  — committed benchmark output. 11 data points; mean δ_A
  per point reported.
- **`docs/p3_bound_companion.md`** — P3-bound session
  companion. §2 derives the constrained fit. §2.1 puts
  the bound in fittable form (`log(1-P) = log(K) - c'·T·ε²`).
  §2.2 shows the binding constraint (max c per point; min
  across points = c_validated). §2.3 computes c_validated
  = 0.00423 with binding at ε_A=0.75. §2.4 reports bound
  predictions vs empirical at all 11 points (10/11 hold).
  §2.5 honest framing on what the fit does and does not
  establish (configuration-specific; no sharper-bound
  test; FPR-floor regime is sampling-variance bounded).
  §2.6 deferred tightening (more low-signal trials would
  loosen binding constraint and produce sharper c′).
  §2.7 Lean theorem grounding with concrete K, c′, T.
  §5 captures three lessons including "constrained fit >
  least-squares for lower bounds".

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.16 → 0.0.17. LL-006
  evidence type `example-tested` → `benchmarked`; status
  `:tested` → `:benchmarked`; description amended with
  fitted constants + bound-holds caveat. Counts: `:tested`
  6 → 5; `:benchmarked` 0 → 1. Total 21 unchanged.
- **`artifact_registry.md`** — version 0.0.16 → 0.0.17.
  LL-006 row updated with benchmark + companion paths.
- **`dashboard.md`** — version 0.0.16 → 0.0.17. P3-bound
  marked ✓ landed. Spec status counts updated. Remaining
  unblocked sub-items list refined.

### Why

P3-bound is the highest-leverage of the available
:benchmarked-upgrade follow-ups: it converts the headline
LL-006 detection-probability bound (the architecture's
load-bearing security claim per §2.1) from "shape fits
qualitatively" to "fitted constants validated at the
prototype's configuration." The Lean target for LL-006
(round-2 §1D.v supplementary priority alongside the
worst-case bound) now has concrete numbers to aim at.

The constrained-fit methodology is honest at the
:benchmarked tier: a least-squares fit produces tighter
constants but fails as a *lower* bound at two transition
points. The constrained fit produces a looser bound that
*always* holds within the prototype's configuration. For
lower-bound claims, constrained-fit is the right tool;
least-squares characterizes data, not bounds.

The single FPR-floor margin failure is documented honestly
rather than papered over. Wilson 95% CI computation shows
sampling variance accounts for the apparent violation;
future tightening (more trials at low-signal points) would
either confirm the violation as a real bound limitation
(triggering refinement of the bound's shape to include FPR
explicitly) or absorb it into expectation-level validity.

### Spec impact

- Counts: total 21 unchanged; `:tested` 6 → 5 (LL-006
  leaves); `:benchmarked` 0 → 1 (LL-006 enters); others
  unchanged.
- Status moves: LL-006 → `:benchmarked`.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 5 (LL-003, LL-004, LL-007, LL-019, LL-021)
- `:benchmarked`: 1 (LL-006)
- `:argued`: 10
- `:open`: 5

### Known gaps

- **Configuration-specific constants.** K=1, c′=0.00423,
  T=60 are for the prototype's chosen Lorenz-96 N=20, F=8,
  single uniform-coupling configuration. Other coupling
  configurations (especially structured per LL-021)
  produce different c′ values; the bound's *shape* is the
  universal claim, the constants are not.
- **No sharper-bound test.** Alternative bound shapes
  (logistic; Chernoff with explicit moment-generating-
  function terms) might fit the transition regime more
  tightly. Not tested here.
- **No analytic ε_A → δ_A mapping.** c′ absorbs ∂λ/∂α
  into the effective slope; the underlying constant in
  raw δ_A units is not separately reported.
- **Tightening deferred.** §2.6 noted that 50+ trials at
  ε_A ∈ {0.5, 0.75} would loosen the binding constraint
  and produce a sharper c′. Small follow-up benchmark.

### Followup recommendations

- **LL-021 `:benchmarked` upgrade.** Same constrained-fit
  methodology applied to the P-R2c worst-case surface.
  The data is already committed in
  `benchmark/results/p_r2c_structured_lorenz96.txt`; the
  fit needs running.
- **LL-019 `:benchmarked` upgrade.** Different shape —
  response-time distribution KS-test against constant-time
  target. Requires a new benchmark.
- **P3d SDE-selection benchmark.** Comparative bench
  (Lorenz-96 / Lorenz-63 / Rössler). Closes LL-003 to
  `:benchmarked`.
- **P3-Nyq adversary-rate Nyquist benchmark.** Closes
  LL-005 to `:tested`.
- **ε-DP envelope stub for LL-020 Strategy 2.** Pure-Julia
  Gaussian perturbation with sensitivity calibration.
- **Tightening session.** 50+ trials at low-signal ε_A
  to loosen the binding constraint at ε_A=0.75.

---

## 0.0.16 — 2026-05-02 — P-R2b calibration confidentiality (LL-020 :argued); P-R2 trio complete

Implements the round-2 LL-020 architectural response.
Design-only session; no Julia code changes. LL-020 closes
:open → :argued with manual evidence. The P-R2
design-response trio (P-R2a + P-R2c + P-R2b) is now
complete; round-2 architectural debt fully addressed.

### Added

- **`docs/p_r2b_calibration_confidentiality_companion.md`** —
  P-R2b session companion. §1 problem statement (V-012 +
  LL-011's TPM defends substitution but not observation).
  §2 three design strategies analysed:
  - Strategy 1: TPM-sealed envelope storage. Primary for
    hardware-rooted (consumer / enterprise PC) deployments.
    Strongest cryptographic guarantee; requires TPM 2.0 /
    Secure Enclave / TrustZone hardware.
  - Strategy 2: ε-differentially-private envelope. Universal
    fallback when hardware support absent or envelope
    publication required. Quantifiable information bound;
    privacy-vs-detection-power trade-off.
  - Strategy 3: Shamir-style multi-party threshold scheme.
    Primary for federated / multi-trust-root deployments.
    Information-theoretically secure below threshold;
    operational coordination cost.
  §2.3 deployment-context layering matrix documents which
  primary + fallback applies per deployment shape. §2.4
  composition with LL-011 (substitution) + LL-017
  (probing). §2.6 Lean theorem shapes per round-2 §1D.v
  priority 3 (ε-DP definition specialised to envelope;
  TPM indistinguishability; Shamir threshold security).
  §5 captures four lessons including "design-only work is
  honest at :argued" and "P-R2 design-response trio is now
  complete."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.15 → 0.0.16. LL-020
  evidence type `none` → `manual`; status `:open` →
  `:argued`; description expanded with the three-strategy
  design + recommended default layering. Counts: `:argued`
  9 → 10; `:open` 6 → 5.
- **`artifact_registry.md`** — version 0.0.15 → 0.0.16.
  LL-020 row updated with companion-doc path. Counts.
- **`dashboard.md`** — version 0.0.15 → 0.0.16. P-R2b
  marked ✓ landed; P-R2 trio fully closed. Project state
  summary updated to "round-2 architectural debt closed."
  Previously-deferred P3 sub-tasks (P3d / P3-bound /
  P3-Nyq) marked unblocked. Spec status counts updated.

### Why

P-R2b is the design-only sub-task of the P-R2 trio per the
round-2 §6.1 framing ("most novel design work of the three
sub-tasks; mostly cryptographic-protocol thinking"). The
session lands the design space + recommended defaults +
Lean theorem shapes; the implementations are platform-
coupled or cryptographic-library-coupled and properly
belong in P3 hardening / P5 Haskell / P6 Lean / P7
production tracks rather than the Julia-prototype layer
per the language-tier discipline.

The honest tier classification per the lavalamp CLAUDE.md
"honest framing" rule is `:argued`: the design closes; no
implementation lands. A pure-Julia ε-DP envelope stub is a
plausible follow-up that would upgrade Strategy 2
specifically to `:tested`, but the prototype's broader
LL-020 claim spans all three strategies and an ε-DP-only
upgrade would be partial.

P-R2 trio across 0.0.14 / 0.0.15 / 0.0.16 collectively
addresses round-2's three new attack vectors. Round-2
§6.1 estimated "1-2 sessions of design work" for the trio;
in practice the trio closed in three sequential commits
within a single afternoon. The fast turn-around reflects
the round-2 findings being tractable (named attack vectors
with clear mitigation paths) vs the round-1 finding (the
visual ↔ security architectural restructuring).

### Spec impact

- Counts: total 21 unchanged; `:argued` 9 → 10 (+ LL-020);
  `:open` 6 → 5 (- LL-020); `:tested` / others unchanged.
- Status moves to `:argued`: LL-020.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 6 (LL-003, LL-004, LL-006, LL-007, LL-019, LL-021)
- `:benchmarked`: 0
- `:argued`: 10 (LL-005, LL-008, LL-011, LL-012, LL-013,
  LL-014, LL-016, LL-017, LL-018, LL-020)
- `:open`: 5 (LL-001, LL-002, LL-009, LL-010, LL-015)

### P-R2 trio summary

The full round-2 architectural-response set:

| sub-task | spec entry | landed | status |
|---|---|---|---|
| P-R2a | LL-019 side-channel hardening | 0.0.14 | :tested |
| P-R2c | LL-021 worst-case-adversary-bound | 0.0.15 | :tested |
| P-R2b | LL-020 calibration confidentiality | 0.0.16 | :argued |

V-011 / V-012 / V-013 (round-2 attack vectors) all have
explicit defences / responses landed in spec.

### Followup recommendations

- **P3 follow-ups unblocked.** P3d (SDE-selection bench →
  LL-003 :benchmarked); P3-Nyq (Nyquist adversary-rate →
  LL-005 :tested); P3-bound (LL-006 :benchmarked upgrade).
- **LL-019 / LL-021 :benchmarked upgrades.** Statistical
  timing indistinguishability for LL-019; K, c, δ_A_worst
  constant fitting for LL-021. Both are analytical follow-
  ups using existing benchmark infrastructure.
- **ε-DP envelope stub for LL-020 Strategy 2.** Plausible
  small Julia session; would upgrade LL-020 to `:tested`
  for Strategy 2 specifically.
- **Round-3 trigger** unchanged — after closure_forces_structure
  paper update lands. P-R2 trio's completion does not
  itself trigger round 3.

---

## 0.0.15 — 2026-05-02 — P-R2c worst-case-adversary-bound (LL-021 :tested)

Implements the round-2 LL-021 architectural response.
Empirically demonstrates that the P3b detection-probability
surface (isotropic adversary, single coupling channel) is an
*optimistic* lower bound vs structured adversaries.

A new benchmark introduces a Lorenz-96 system with TWO
sensor channels carrying *different* coupling vectors b
(b_1 = e_1 NARROW vs b_2 = ones(N) BROAD), then sweeps
adversary perturbation direction in α-space at fixed
magnitude. The committed empirical surface shows dramatic
asymmetry: at ε_A = 1.0 the NARROW direction has 0/5
detection while the BROAD direction has 5/5 detection. Even
at ε_A = 4.0 (perturbation 4× the genuine α magnitude), the
NARROW direction stays at 0/5 — the structured worst-case
adversary is essentially undetectable at the prototype's
configuration.

LL-021 closes :open → :tested with example-tested evidence
backed by the committed benchmark output. Counts: :tested
5 → 6; :open 7 → 6; total 21 unchanged.

### Added

- **`src/julia/benchmark/p_r2c_structured_adversary.jl`** —
  benchmark script. Constructs a 2-channel coupling
  configuration with NARROW (b_1 = e_1) and BROAD (b_2 =
  ones(N)) coupling vectors; sweeps adversary direction
  ∈ {NARROW (1,0), MIXED (1,1)/√2, BROAD (0,1)} at
  magnitudes ε_A ∈ {0.5, 1.0, 2.0, 4.0}; 5 trials per point;
  uses verify_full from 0.0.14 (audit-on-every-verify) for
  every call. Total ~50s wall clock.
- **`src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`**
  — committed empirical surface.
- **`docs/p_r2c_worst_case_adversary_companion.md`** —
  P-R2c session companion. §2.1 analytic derivation
  (worst-case direction = orthogonal to mean-coupling
  vector m = (mean(b_1), …, mean(b_n)); under-estimation
  factor = condition number of the coupling matrix). §2.2
  empirical result table. §2.3 explanation of why the
  asymmetry is "all FPR" empirically (narrow direction sits
  below the calibration noise floor at any tested
  magnitude). §2.4 corrected detection bound + production
  deployment options. §2.5 refined Lean theorem shape per
  round-2 §1D.v priority 1. §5 captures four lessons
  including "single-channel benchmarks understate adversary
  capability" and "P-R2a → P-R2c order was right (build
  audit-on-every-verify discipline first, exercise it in
  higher-content benchmark second)."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.14 → 0.0.15. LL-021
  evidence type `none` → `example-tested`; status `:open`
  → `:tested`; description expanded with empirical numbers.
  LL-006 notes amendment pointing at the worst-case
  benchmark file. Counts: `:tested` 5 → 6; `:open` 7 → 6.
- **`artifact_registry.md`** — version 0.0.14 → 0.0.15.
  LL-021 row updated with benchmark + source paths. Counts.
- **`dashboard.md`** — version 0.0.14 → 0.0.15. P-R2c
  marked ✓ landed. Spec status counts updated.

### Why

P-R2c was the most numerically interesting of the three
P-R2 sub-tasks per round-2 §1D and the dashboard's outline-
of-next-steps. The benchmark not only validates LL-021's
concern (V-013 / round-2 §1C-A3 + A6) — it produces a
*sharper* finding than expected: the NARROW direction is
essentially undetectable at the prototype's configuration,
not just under-detected.

The session order P-R2a → P-R2c (skipping P-R2b for now) was
chosen because P-R2c uses `verify_full` from P-R2a in every
benchmark call (LL-019 audit-on-every-verify discipline).
P-R2b (LL-020 calibration confidentiality) is mostly
cryptographic-protocol design and can land independently.

The empirical asymmetry has a *practical* implication for
production: deployments must either choose coupling vectors
with uniform support (reduces condition number), increase
the channel count (raises the dimensionality of the
orthogonal-to-mean-coupling subspace), or document the
deployment-context-bounded worst-case weakness. The
prototype lands option 3 honestly with the benchmark as
evidence.

### Spec impact

- Counts: total 21 unchanged; `:tested` 5 → 6 (+ LL-021);
  `:open` 7 → 6 (- LL-021); others unchanged.
- Status moves to `:tested`: LL-021.
- Notes amendments: LL-006 (worst-case companion benchmark
  pointer added).

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 6 (LL-003, LL-004, LL-006, LL-007, LL-019, LL-021)
- `:benchmarked`: 0
- `:argued`: 9
- `:open`: 6

### Known gaps

- **LL-021 :benchmarked upgrade outstanding.** Calibrating K,
  c, δ_A_worst constants against the empirical surface is
  the next analytical step.
- **Lean theorem.** Round-2 §1D.v priority 1 (linear-coupling
  worst-case bound) is now grounded in the §2.5 theorem
  shape. P5/P6 work.
- **LL-020 calibration confidentiality still :open.** P-R2b
  remaining; mostly design (cryptographic-protocol
  thinking).
- **Production coupling-matrix design guidance.** The
  three options in §2.4 are sketches; not benchmarked.

### Followup recommendations

- **P-R2b — LL-020 calibration confidentiality.** Final
  P-R2 sub-task. Companion doc + spec refinement;
  cryptographic-protocol design (TPM-sealed storage / ε-DP /
  multi-party threshold). Mostly design, no benchmarks.
- **Round-3 trigger** unchanged — after closure_forces_structure
  paper update lands.

---

## 0.0.14 — 2026-05-02 — P-R2a side-channel hardening (LL-019 :tested)

Implements the round-2 LL-019 architectural response.
`Audit.jl` gains `verify_full(ds, env; ...)` (forces full
Benettin spectrum at the API level — audit-on-every-verify
per round-2 §1C-A4) and `verify_constant_time(λs, env;
target_seconds)` (pads response time to uniform target —
timing decorrelation per round-2 §1C-A1 / V-011).

12 new test assertions across two `@testset`s. Test suite
grows 82 → 94 assertions, all passing in ~50s. LL-019 closes
:open → :tested with example-tested evidence.

### Added

- **`src/julia/src/Audit.jl`** — `verify_full` (Benettin-
  enforcing wrapper) and `verify_constant_time` (timing-
  padding wrapper).
- **`src/julia/src/LavaLamp.jl`** — re-exports.
- **`src/julia/test/runtests.jl`** — 12 new LL-019
  assertions:
  - "verify_full forces full-spectrum audit": Bool return,
    result agreement with manual lyapunov_spectrum +
    verify, genuine-accept, strong-adversary-reject.
  - "verify_constant_time pads to target": elapsed ≥
    target_seconds for both genuine and adversary paths,
    result equality with plain verify, Bool-only return,
    argument validation.
- **`docs/p_r2a_side_channel_hardening_companion.md`** —
  P-R2a session companion. §2.1 documents the two LL-019
  sub-requirements (audit-on-every-verify, timing
  decorrelation); §2.2 / §2.3 document the API-level vs
  runtime-check design and the constant-time-via-sleep
  prototype trade-off; §2.4 explicitly defers the
  statistical-indistinguishability benchmark; §3 honest
  status framing. §5 captures three lessons including
  "API-level enforcement > runtime sanity-check for
  security-discipline requirements that have to hold under
  code review."

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.12 → 0.0.14. LL-019
  evidence type `none` → `example-tested`; status `:open` →
  `:tested`; description expanded with implementation
  specifics. Counts: `:tested` 4 → 5; `:open` 8 → 7.
- **`artifact_registry.md`** — version 0.0.12 → 0.0.14.
  LL-019 row updated with test/source paths. Counts.
- **`dashboard.md`** — version 0.0.13 → 0.0.14. P-R2a marked
  ✓ landed in the priority block. Spec status counts.
- **`src/julia/Project.toml`** — version 0.0.10 → 0.0.14.
- **`src/julia/Manifest.toml`** — version sync.

### Why

P-R2a was the smallest of the three round-2 architectural
responses by design (round-2 companion §6.1 noted "P-R2a is
probably the smallest design lift"). Verified empirically:
a single companion doc + two API-level wrappers + 12 test
assertions, ~3s additional test wall-clock.

The implementation is intentionally minimal — `verify_full`
is a wrapper that controls which estimator runs, not a new
estimator; `verify_constant_time` is a `sleep`-based padding
wrapper, not a new scheduler. The lavalamp CLAUDE.md
"no half-finished implementations" rule is honoured by
documenting what's deferred (statistical
indistinguishability benchmark, async deadline scheduler)
rather than pretending the prototype implementation is
production-grade.

### Spec impact

- Counts: total 21 unchanged; `:tested` 4 → 5 (+ LL-019);
  `:open` 8 → 7 (- LL-019); others unchanged.
- Status moves to `:tested`: LL-019.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 5 (LL-003, LL-004, LL-006, LL-007, LL-019)
- `:benchmarked`: 0
- `:argued`: 9
- `:open`: 7

### Known gaps

- **Statistical indistinguishability deferred.** The
  `verify_constant_time` test asserts elapsed ≥ target on
  single calls; the *distributional* property (response-time
  distributions across many calls are statistically
  indistinguishable across accept/reject inputs) is a
  benchmark follow-up.
- **`sleep` blocks worker thread.** Production deployments
  need an async deadline scheduler; the prototype's `sleep`
  demonstrates the property but is not the production
  implementation.
- **LL-020 and LL-021 still :open.** P-R2b and P-R2c
  remaining.

### Followup recommendations

- **P-R2c — LL-021 worst-case-adversary-bound** is the
  natural next sub-task — analytical + benchmark work; the
  benchmark can re-use `verify_full` from this session.
- **P-R2b — LL-020 calibration confidentiality** is mostly
  cryptographic-protocol design (companion doc + spec
  refinement); can land in any order with P-R2c.
- **Side-channel statistical benchmark** — KS-test or
  Anderson-Darling distributional equality across many
  verify calls. Closes the `:benchmarked` upgrade for
  LL-019.
- **Lean side-channel theorem** (round-2 §1D.v priority 2)
  — now grounded in this companion's `verify_constant_time`
  design.

---

## 0.0.13 — 2026-05-02 — Round-2 §7 instantiator resolutions

Records Aaron's resolutions of the four outstanding decisions
the AI integrator flagged in `synthesis_team_round2_companion.md`
§7. No spec moves; no code changes. Small follow-up commit to
the 0.0.12 round-2 integration.

### Changed

- **`docs/synthesis_team_round2_companion.md`** — §7
  rewritten from "outstanding" to "resolved 2026-05-02":
  (1a) Gemini-framing accepted as fair; (1b) three new
  spec entries kept as three; (1c) P3d/P3-bound/P3-Nyq
  deferral confirmed; (2) Grok's Lean priorities adopted
  provisionally ("then we'll discuss"); (3) round-3 trigger
  shifted from "after LL-019/020/021 designs" to "after
  closure_forces_structure physics-paper update lands".
  §6.2 and §1D.v updated to reflect the resolutions.
- **`dashboard.md`** — P-R2 priority block notes Aaron's
  §1D resolution accepted; new P-R3 priority block added
  noting the corpus-event trigger.

### Why

The §7 decisions were genuinely open after 0.0.12 lands
because they involved Aaron's instantiator authority (which
parts of the AI integrator's resolution to accept; how to
weight Lean priorities; round-3 timing). Recording the
resolutions inline keeps the workflow audit trail honest
rather than relying on chat-history recall.

The round-3 timing shift is the most consequential change.
"After LL-019/020/021 designs" was a near-term local trigger;
"after closure_forces_structure paper update" is a corpus-
event trigger that depends on parallel physics work. The
two are complementary — local design work proceeds
independently — but the round-3 brief composition has to
wait for the paper.

### Spec impact

None. Counts unchanged: 21 total; 4 :tested; 9 :argued;
8 :open.

### Followup recommendations

- **P-R2a / P-R2b / P-R2c can land in any order** between now
  and the round-3 trigger.
- **Watch closure_forces_structure paper repos** for the
  update event; round-3 brief composition follows.

---

## 0.0.12 — 2026-05-02 — Synthesis-team round 2 (3 new attack vectors, 3 new spec entries)

Captures the second round of synthesis-seat (Gemini) +
edge-witness-seat (Grok) review on LavaLamp, triggered by P2
closure (0.0.5) and the substantive P3 prototype landing
(0.0.6 - 0.0.10). Brief was forwarded in 0.0.11; responses
arrived together; 0.0.12 is the integration commit.

The two seats produced asymmetric content this round. Grok's
edge-witness review surfaced three real new attack vectors
(V-011 Reseed Oracle, V-012 Calibration Spectrum Leakage,
V-013 Structured α-Direction Attack) plus a structural
concern (A6 linearisability of the linear-in-x coupling).
Gemini's synthesis review affirmed the architecture without
substantively deepening it; the Lean theorem stubs offered
were placeholder-level.

Combined verdict: `engage-and-formalise-after-fixes`. Three
new spec entries land at `:open` (LL-019 side-channel
hardening, LL-020 calibration confidentiality, LL-021
worst-case-adversary-bound). Notes amendments on LL-004 /
LL-006 / LL-007 / LL-011 / LL-014 reflect the round-2
findings. P3 prototype-extension follow-ups (P3d, P3-Nyq,
P3-bound) are *deferred* in favor of P-R2 architectural
responses to LL-019/020/021.

### Added

- **`docs/synthesis_team_round2_companion.md`** — round-2
  dialogue + AI-integrator resolution per the round-1
  pattern. §1A brief summary; §1B faithful summary of
  Gemini response (with honest assessment of its
  limitations); §1C faithful summary of Grok response (three
  new attack vectors + linearisability concern + sharper
  Lean priorities); §1D proposed resolution; §2 round-2
  architectural state; §3 verification (manual evidence);
  §4 spec impact; §5 process notes (round-2 contribution
  asymmetry; brief structure worked unevenly across seats;
  Lean priorities expanded); §6 followups; §7 outstanding
  instantiator decisions for Aaron's confirmation.
- **`docs/attack_surface_enumeration.md`** — three new attack
  vectors:
  - **V-011 — Reseed Oracle.** Chaos-guard state transitions
    observable as timing channel; sensor-correlated; gives
    A4/A5 a thermal-event oracle. Defense: LL-019 (pending).
  - **V-012 — Calibration Spectrum Leakage.** Registration
    ceremony exposes the registered envelope to channel
    observers; TPM defends substitution but not observation.
    Defense: LL-020 (pending).
  - **V-013 — Structured α-Direction Attack.** Real
    adversaries are non-isotropic in α-space; existing
    detection-probability surface is an optimistic lower
    bound. Defense: LL-021 (pending).
  Adversary-class × attack-vector matrix updated; residual-
  risks section extended with three new entries.
- **`LAVALAMP_SPEC.md`** — three new spec entries:
  - **LL-019 — side-channel-hardening** (Core, `:open`).
    Constant-time / randomised-delay response on chaos-guard
    state transitions; "audit on every verification request"
    cadence requirement (full Benettin spectrum, not just
    Wolf-method guard).
  - **LL-020 — calibration-confidentiality** (Core, `:open`).
    Registered envelope sealed against registration-channel
    observers via TPM-sealed storage / ε-DP perturbation /
    multi-party threshold scheme. Complementary to LL-011's
    TPM attestation (which defends substitution, not
    observation).
  - **LL-021 — worst-case-adversary-bound** (Core, `:open`).
    Detection-probability claim (LL-006 / LL-008) re-stated
    against worst-case adversary direction (minimum δ_A over
    admissible perturbation directions), not isotropic.
    Empirical benchmarks must include structured directions.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.10 → 0.0.12. Notes
  amendments (no status changes) on:
  - LL-004 (linearisability limitation; state-dependent
    coupling deferred).
  - LL-006 (empirical detection surface is optimistic;
    worst-case is LL-021's deliverable).
  - LL-007 (reseed-timing decorrelation requirement; LL-019
    pre-condition).
  - LL-011 (calibration confidentiality requirement; LL-020
    complementary).
  - LL-014 (adaptive-thresholding promoted from optional to
    load-bearing for multi-tenant deployments).
  Counts: total 18 → 21; `:open` 5 → 8.
- **`artifact_registry.md`** — version 0.0.10 → 0.0.12.
  Three new rows for LL-019/020/021 (`:open`, evidence
  none). Counts. A1 coverage 21/21; A5 stale-counts updated.
- **`dashboard.md`** — version 0.0.11 → 0.0.12. Project state
  notes round-2 architectural debt; workflow shift from P3
  prototype-extension to P-R2 architectural-response
  sessions; P3 follow-ups marked deferred. New P-R2 priority
  block listing P-R2a/b/c sub-tasks. Recent companion docs
  gains the round-2 brief + companion entries.

### Why

Round 2 was triggered by P2 closing in 0.0.5 plus P3
substantively closing in 0.0.10 (4 of 18 entries `:tested`).
The round-1 plan was for round 2 to validate
"engage-and-formalise" or send work back to architecture.
Both happened simultaneously: the architecture is
fundamentally sound (Gemini's affirmation; Grok's
constructive criticism rather than fundamental obstruction)
*and* the prototype implementation has surfaced attack
surface that the design pass didn't enumerate.

The asymmetric contribution profile (Grok > Gemini this
round) is itself informative. Round 1 had Gemini-first
because synthesis was load-bearing for the in-flux
architecture; round 2 had Grok carrying the substantive load
because the architecture was settled and the implementation
was the new attack surface. For round 3 (after LL-019/020/021
designs land), the brief should weight edge-witness questions
accordingly.

The decision to defer P3 prototype-extension work (P3d,
P3-bound, P3-Nyq) in favor of P-R2 architectural responses
follows the same logic as P3 being gated on P2 in 0.0.5:
running comparative benchmarks against an architecture marked
as having known soft spots produces results that need re-
running. Architecture first; benchmarks once the architecture
is solid.

### Spec impact

- Counts: total 18 → 21 (+3 — LL-019, LL-020, LL-021);
  `:open` 5 → 8; `:argued` / `:tested` / others unchanged.
- Status moves: none. New entries land at `:open`.
- Notes amendments: LL-004, LL-006, LL-007, LL-011, LL-014.

### Counts

- Total: 21 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 4 (LL-003, LL-004, LL-006, LL-007)
- `:benchmarked`: 0
- `:argued`: 9 (LL-005, LL-008, LL-011, LL-012, LL-013,
  LL-014, LL-016, LL-017, LL-018)
- `:open`: 8 (LL-001, LL-002, LL-009, LL-010, LL-015,
  LL-019, LL-020, LL-021)

### Known gaps

- **§7 outstanding instantiator decisions.** The companion
  doc lists items where Aaron's call should override the AI
  integrator's proposed resolution before subsequent work
  proceeds. The most consequential: whether the AI
  integrator's framing of Gemini's response as "less
  substantive than the brief asked for" is fair, and whether
  three new spec entries is the right number (versus
  consolidating to fewer).
- **No implementation responses yet.** LL-019/020/021 land
  with `:open` status; their defenses are pending P-R2
  design work. The prototype's V-011/V-012/V-013 attack
  surface is currently *exposed*.
- **Lean target updated but not Lean work landed.** Round-2's
  sharper theorem priorities (linear-coupling worst-case
  bound; side-channel indistinguishability; calibration
  ε-DP) replace Gemini's placeholder stubs but are still
  P5/P6 work.

### Followup recommendations

- **P-R2a — LL-019 design.** Constant-time response /
  decorrelation protocol for chaos-guard state transitions;
  "audit on every verification request" cadence
  specification. Companion doc + minor `Audit.jl` /
  `ChaosGuard.jl` refinement.
- **P-R2b — LL-020 design.** Calibration-data sealing
  protocol (TPM-sealed storage / ε-DP / multi-party
  threshold). Companion doc.
- **P-R2c — LL-021 design.** Worst-case adversary direction
  derivation; structured-adversary benchmark sweep. Companion
  doc + benchmark script + spec refinement.
- **Round 3 trigger** after P-R2a/b/c land. Brief should
  weight edge-witness questions per round-2 §5.1.

---

## 0.0.11 — 2026-05-02 — GitHub Actions CI workflow

Lands the CI workflow flagged as a follow-up since 0.0.7. With
the test suite at 82 assertions and ~47s local wall clock,
manual reruns after every change had become a discipline gap;
CI closes that gap by running `Pkg.test()` on every push to
master and on every PR.

### Added

- **`.github/workflows/test.yml`** — single-job workflow:
  Julia 1.12 on ubuntu-latest, 20-minute job timeout. Steps:
  `actions/checkout@v4` → `julia-actions/setup-julia@v2` (with
  `version: 1.12`) → `julia-actions/cache@v2` (caches the
  Julia depot across runs) → `julia-actions/julia-buildpkg@v1`
  with `project: src/julia` (runs `Pkg.instantiate()`,
  respecting the committed Manifest.toml — lockfile discipline
  preserved) → `julia-actions/julia-runtest@v1` with
  `project: src/julia` (runs `Pkg.test()`). Triggered on
  `push` to master and on `pull_request`. Permissions block
  `contents: read` (least privilege).

### Why

The lavalamp CLAUDE.md package-management rule requires
"verify a clean checkout + lockfile install builds before
committing"; CI mechanically enforces this on every commit
rather than relying on local discipline. For the 82-assertion
test suite, manual rerun on every edit had become slow enough
to be a real friction; CI removes that.

The workflow uses a single Julia version (1.12 to match dev)
on a single OS (ubuntu-latest) — minimal matrix to start.
Project.toml [compat] declares `julia = "1.10"` so the matrix
can expand later without forcing a recheck-everything
session.

The workflow file is the smallest YAML that exercises
`Pkg.test()` against the committed lockfile. No bells, no
benchmarks, no codecov yet — those are follow-ups if the
prototype's wall clock or cost-tracking discipline ever
warrants them.

### Spec impact

None. Workflow is project tooling, not a security claim.
Counts unchanged: 18 total; 4 `:tested`; 9 `:argued`; 5
`:open`.

### Known gaps

- Workflow has not yet been observed to pass on a remote
  runner — this commit triggers its first run. Expected
  outcome: 82/82 assertions pass; wall clock 5-8 minutes
  including precompile (vs ~47s local) on the GitHub-hosted
  ubuntu-latest runner.

---

## 0.0.10 — 2026-05-02 — P3c chaos-guard (LL-007 :tested)

Implements the periodic-window safety signal per architecture-
design §2.3. New `src/julia/src/ChaosGuard.jl` module: state
machine {INVALID, WARMUP, VALID}, GuardConfig with τ_λ /
recovery_threshold / warmup_steps thresholds, default_config
helper, update! transition logic, is_valid Bool predicate
(LL-017 no-oracle compliance), current_lambda diagnostic
field, and reseed! TRNG-derived unit-vector × magnitude state
perturbation.

Test suite grows 47 → 82 assertions, all passing in ~47s — the
runtime is *faster* than 0.0.9 because the chaos-guard tests
use Wolf-method `DynamicalSystems.lyapunov` (single-trajectory,
~1.3 ms per call at N=40) rather than full Benettin
`lyapunovspectrum` (~507 ms per call). 400× speedup confirms
the architecture-design §2.3 cost analysis.

LL-007 closes from `:argued` to `:tested` with `example-tested`
evidence. Counts: `:tested` 3 → 4; `:argued` 10 → 9; total 18
unchanged.

### Added

- **`src/julia/src/ChaosGuard.jl`** — guard module.
  - `GuardState` (`@enum`): INVALID, WARMUP, VALID.
  - `GuardConfig(τ_λ, recovery_threshold, warmup_steps)` with
    construction-time validation (τ_λ > 0; recovery > τ_λ;
    warmup_steps ≥ 1).
  - `default_config(λ₁_expected; warmup_steps=10)` —
    architecture-design §2.3 ratios: `τ_λ = 0.1·λ₁_expected`,
    `recovery_threshold = 5·τ_λ`.
  - `Guard(config)` — mutable state machine; constructor
    initialises in WARMUP (not VALID — security primitive
    must not assume entropy is good before observation).
  - `update!(guard, λ̂₁)` — applies one observation; returns
    post-update state.
  - `is_valid(guard)` → Bool — public predicate.
  - `current_lambda(guard)` → Float64 — diagnostic.
  - `reseed!(ds, guard; rng, magnitude=1.0)` — TRNG unit-
    vector × magnitude perturbation; resets state to WARMUP;
    increments reseed_count.
- **`src/julia/test/runtests.jl`** — 35 new chaos-guard
  assertions across 3 `@testset`s:
  - **State machine** (~17): config validation, initial
    WARMUP, sustained-high → VALID, gray-band dip stability,
    collapse → INVALID, recovery flow.
  - **Lorenz-96 chaotic vs sub-chaotic** (~6): F=8 chaotic →
    VALID; F=2 sub-chaotic (trivial fixed point) → INVALID.
  - **Reseed flow** (~12): VALID → reseed → WARMUP →
    recovery; deterministic-magnitude verification.
- **`docs/p3c_chaos_guard_companion.md`** — session companion.
  Documents the state machine logic, the Lorenz-96 sub-chaotic
  detection scenario, the reseed-with-deterministic-magnitude
  semantic, the cost analysis (cheap Wolf vs full Benettin),
  the LL-002 visual decoupling preservation, the
  module-name/type-name conflict gotcha (Julia docstring
  attachment fails when `module Foo` contains `struct Foo`),
  and four lessons (mod/struct naming, Wolf-vs-Benettin
  always-on monitoring choice, reseed magnitude vs direction,
  conservative-by-construction initial WARMUP).

### Changed

- **`src/julia/src/LavaLamp.jl`** — `include("ChaosGuard.jl")`
  + ChaosGuard re-exports.
- **`src/julia/Project.toml`** — version 0.0.9 → 0.0.10.
- **`LAVALAMP_SPEC.md`** — version 0.0.9 → 0.0.10. LL-007
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; description expanded with implementation
  specifics (Wolf method, exact thresholds, conservative
  initial WARMUP, no-oracle Bool return). Counts: `:tested`
  3 → 4; `:argued` 10 → 9.
- **`artifact_registry.md`** — version 0.0.9 → 0.0.10. LL-007
  row updated. A6 records 82/82 assertions in ~47s wall clock.
- **`dashboard.md`** — version 0.0.9 → 0.0.10. Project state
  summary updated with 0.0.10 numbers. P3 priority block adds
  0.0.10 sub-status; P3c is removed from the remaining list.
  Recent companion docs gains the P3c entry.

### Why

P3c is the operational complement to P3b's residue audit. The
audit is *on-demand* — it runs when verification is requested
and pays its O(N²) full-spectrum cost per request. The chaos-
guard is *always-on* — it runs continuously in the security
primitive's background to catch the periodic-window failure
mode, where the SDE has stalled into a non-chaotic orbit and
the entropy is silently broken. Without the chaos-guard, a
silent drift into a periodic regime would emit consumable
entropy that has no actual chaos behind it.

The cost asymmetry is large enough to matter: ~400× per call
at N=40. That ratio compounds when the guard runs on a
seconds-cadence schedule. The architecture-design §2.3 choice
to use single-exponent Wolf for the guard and reserve full-
spectrum Benettin for the audit is the right cost tradeoff.

The session also surfaced a Julia gotcha worth recording:
`module Foo` containing `struct Foo` breaks the docstring
system with an opaque `MethodError on doc!`. LavaLamp's
convention is now to keep module names and exported type
names distinct (Sensors → SensorStream / CouplingParams;
Audit → Envelope; ChaosGuard → Guard).

### Spec impact

- Counts: total 18 unchanged; `:tested` 3 → 4 (+ LL-007);
  `:argued` 10 → 9 (- LL-007); `:open` 5 unchanged.
- Status moves to `:tested`: LL-007.
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 4 (LL-003, LL-004, LL-006, LL-007)
- `:benchmarked`: 0
- `:argued`: 9
- `:open`: 5

### Known gaps

- **No CI integration yet.** Wall clock dropped to ~47s with
  the cheap-estimator approach, so manual reruns are tolerable
  again, but CI is still recommended before more substantive
  bench work.
- **LL-005 still :argued.** Adversary-rate Nyquist benchmark
  pending. Folds into the existing benchmark framework.
- **LL-006 :benchmarked upgrade outstanding.** Bound-constant
  fitting (K, c, δ_A(ε_A)) against the existing 0.0.9
  detection-probability surface.
- **LL-003 :benchmarked upgrade outstanding.** SDE-selection
  comparative bench (Lorenz-96 vs Lorenz-63 vs Rössler).
- **No real-time integration test.** The chaos-guard is
  exercised by feeding pre-computed λ̂₁ values; a true
  background-thread integration with concurrent SDE
  integration is a production-hardening concern, not a
  prototype-validation requirement.

### Followup recommendations

- **P3d SDE-selection benchmark** — natural next slice. Sweep
  Lorenz-96 / Lorenz-63 / Rössler through the existing
  spectrum + chaos-guard infrastructure. Closes LL-003
  `:benchmarked`.
- **P3-bound LL-006 :benchmarked** — analytic follow-up using
  the existing 0.0.9 detection surface as input. No new
  numerics needed.
- **P3-Nyq adversary-rate Nyquist benchmark** — closes
  LL-005. Requires extending the synthetic-adversary
  framework to perturb sensor sample rate, not just α.
- **CI workflow** — recommended before any of the above.

---

## 0.0.9 — 2026-05-02 — P3b residue audit + detection-probability benchmark

Implements the Lyapunov-spectrum residue audit per
architecture-design §2.1. New `Audit.jl` module: Envelope
(spectrum + per-exponent estimator σ + n_trials calibration),
register_envelope, residue, verify (vector per-exponent test,
Bool-only return per LL-017 no-oracle), synthetic_adversary
(unit-vector L2-magnitude perturbation in α-space). New
benchmark script `benchmark/p3b_detection_probability.jl` and
its committed result file
`benchmark/results/p3b_detection_lorenz96.txt`.

LL-006 closes from `:argued` to `:tested` with `example-tested`
evidence — 18 new test assertions exercising the audit
mechanism, plus the empirical detection-probability surface as
supporting data. Test suite grows 29 → 47 assertions, all
passing in ~78s via `Pkg.test()`.

### Added

- **`src/julia/src/Audit.jl`** — verifier module.
  - `Envelope(spectrum, σ, n_trials, metadata)` immutable
    struct.
  - `register_envelope(ds_factory; n_trials=3, N=1500, Δt=0.05,
    Ttr=300.0, lyapunov_fn=lyapunov_spectrum)` — calibrates
    envelope from independent runs of the genuine system.
    Per-exponent σ is the Bessel-corrected sample standard
    deviation across calibration trials.
  - `residue(λs, env)` — per-exponent absolute differences.
  - `verify(λs, env; k=4.0)` — vector per-exponent test;
    returns `Bool` only (LL-017 no-oracle compliance).
  - `synthetic_adversary(p, ε_A; rng, direction=nothing)` —
    unit-vector + L2-magnitude perturbation in α-space.
- **`src/julia/test/runtests.jl`** — 18 new audit assertions
  across 2 `@testset`s: Audit module mechanism (residue
  correctness, verify Bool semantics, synthetic_adversary
  L2-magnitude preservation, error handling); end-to-end
  exercise (envelope structure, self-acceptance at k=10
  conservative, strong-adversary rejection at k=5 with ε_A=3.0,
  residue-magnitude sanity check).
- **`src/julia/benchmark/p3b_detection_probability.jl`** —
  detection-probability sweep script. Sweeps ε_A ∈ {0.0, 0.1,
  0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0} with 10 trials per
  point; deterministic seeds; writes plain-text result to
  benchmark/results/.
- **`src/julia/benchmark/results/p3b_detection_lorenz96.txt`**
  — committed benchmark output. Empirical detection-probability
  curve at the prototype's working point (Lorenz-96 N=20, F=8,
  k=5, n_trials=10): flat ≈ 10% FPR baseline for ε_A ≤ 0.75;
  sigmoid transition through ε_A ∈ [0.75, 2.0]; saturated
  1.00 detection for ε_A ≥ 2.0. Shape matches the §2.1 bound
  P(detect) ≥ 1 - K·exp(-c·T·δ²); constants not yet derived
  (followup for `:benchmarked` upgrade).
- **`docs/p3b_residue_audit_companion.md`** — session companion.
  §2.1 documents the verifier mechanism. §2.2 records the
  unit-vector + L2 perturbation semantic (vs the noisier
  ε_A·randn alternative). §2.3 records a zero-sensor degeneracy
  bug found during smoke tests (a useful non-degeneracy
  violation example for future sessions). §2.4 reports the
  empirical detection-probability surface. §2.5 explains why
  this lands as `:tested`, not `:benchmarked`. §2.6 documents
  the Sensors-to-top-level module restructure. §5 captures
  three lessons.

### Changed

- **`src/julia/src/LavaLamp.jl`** — submodule load order
  restructured. `Sensors` is now a top-level submodule of
  `LavaLamp` (was nested inside `Engine`); `Engine` and
  `Audit` both reference Sensors via `..Sensors`. New audit
  re-exports.
- **`src/julia/src/Engine.jl`** — `using ..Sensors` instead of
  including Sensors locally.
- **`LAVALAMP_SPEC.md`** — version 0.0.8 → 0.0.9. LL-006
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; description expanded with the vector
  per-exponent test definition and the empirical detection-
  probability surface summary; Source/Test paths added; notes
  reference the bound-constant calibration follow-up. Counts:
  `:tested` 2 → 3; `:argued` 11 → 10. Total still 18.
- **`artifact_registry.md`** — version 0.0.8 → 0.0.9. LL-006
  row updated with `src/julia/test/runtests.jl` +
  `src/julia/benchmark/results/p3b_detection_lorenz96.txt` test
  paths and `src/julia/src/Audit.jl` source. Cross-audit A6
  records 47/47 assertions passing in ~78s wall clock; CI
  recommendation reiterated.
- **`dashboard.md`** — version 0.0.8 → 0.0.9. Project state
  summary updated with P3b numbers. P3 priority block adds
  0.0.9 sub-status; P3-bound (LL-006 `:benchmarked` upgrade)
  added as a new sub-item. Spec status counts updated. Recent
  companion docs gains the P3b entry.

### Why

P3b is the natural next slice after P3a's sensor-coupling
layer. The residue audit is the *security-decision* layer: it
takes the spectrum produced by the coupled SDE and produces
ACCEPT/REJECT decisions. Without it, the substrate-coupled
trajectory has nothing to compare against; with it, the device
identity has structural meaning.

The session validated three claims empirically:

1. **Mechanism correctness.** Envelope, residue, verify, and
   synthetic_adversary all behave as specified (residue is
   per-component abs differences; verify is Bool-only;
   synthetic_adversary preserves L2 magnitude exactly). 18
   new assertions cover this.
2. **Self-acceptance.** At conservative k=10, fresh genuine
   runs against the registered envelope deterministically
   accept. (At working k=5, FPR ≈ 0.10 — characterized in
   the benchmark output.)
3. **Adversary detection.** Strong adversaries (ε_A=3.0)
   deterministically reject at k=5. Weaker adversaries
   transition smoothly: ε_A=1.0 detects 50%; ε_A=0.5
   detects ≈ FPR. Curve shape matches §2.1 bound.

The transition from `:argued` to `:tested` is honest: the
audit *mechanism* is exercised; the *bound's constants* (K, c,
δ_A as a function of ε_A) are not yet derived from the
empirical curve. A future session can fit those constants and
verify the empirical curve is above the bound prediction;
that closes LL-006 to `:benchmarked`.

### Spec impact

- Counts: total 18 unchanged; `:tested` 2 → 3 (+ LL-006);
  `:argued` 11 → 10 (- LL-006); `:open` 5 unchanged.
- Status moves to `:tested`: LL-006.
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 3 (LL-003, LL-004, LL-006)
- `:benchmarked`: 0
- `:argued`: 10
- `:open`: 5

### Known gaps

- **LL-006 `:benchmarked` upgrade outstanding.** Requires
  fitting the §2.1 bound's constants K, c, δ_A(ε_A) from the
  empirical curve and demonstrating the empirical P(detect)
  is above the bound prediction. The committed benchmark
  output has the empirical curve; the fit is the missing
  step.
- **No CI integration yet.** Test wall clock now ~78s; manual
  reruns starting to feel slow. Recommended before P3c.
- **LL-005 (sensor Nyquist) still `:argued`.** Adversary-rate
  benchmark folds into the existing benchmark framework but
  hasn't been run.
- **LL-007 chaos-guard untouched.** Cheaper than P3b
  (single-exponent vs full spectrum); should be next.
- **Stub-stream layer only.** Real-sensor FFI deferred per
  the 0.0.8 followups.

### Followup recommendations

- **P3c chaos-guard** is the natural next slice. Cheapest
  remaining sub-task per the 0.0.7 §2.4 cost analysis (single
  exponent vs full spectrum; O(N) vs O(N²)). Closes LL-007 to
  `:tested`.
- **CI workflow** before P3c. With test wall-clock at ~78s,
  manual reruns are getting expensive. GitHub Actions
  `Pkg.test()` on push closes the gap; small lift.
- **P3-bound LL-006 `:benchmarked` upgrade.** Can land in
  parallel with P3c; uses the existing benchmark output as
  input. Modest analytical work to fit (K, c) and predict
  δ_A(ε_A); compare empirical to fitted prediction.

---

## 0.0.8 — 2026-05-02 — P3a sensor-coupling layer

Implements the smooth sensor-to-SDE coupling layer per
architecture-design §2.4. LL-004 (continuous sensor coupling)
closes from `:argued` to `:tested` with example-tested evidence:
a sensor-stream module + a coupled Lorenz-96 variant + 21 new
test assertions exercising sensor primitives, the no-coupling
sanity reduction, stepped-sensor smoothness, and α-sweep
non-degeneracy. Test suite total grows 8 → 29 assertions, all
passing in ~40s via `Pkg.test()`.

### Added

- **`src/julia/src/Sensors.jl`** — sensor stream module.
  - `SensorStream` struct (immutable, validated at construction).
  - `evaluate(stream, t)` — linear interpolation, clamped at
    endpoints, O(log n) lookup via `searchsortedlast`.
  - `constant_stream(value; t_max)` — fixed-baseline fixture.
  - `binary_step_stream(t_step, before, after; ramp_τ, t_max,
    n_samples)` — sigmoid-smoothed binary state transition;
    models AC plug-in / USB plug events.
  - `gaussian_noise_stream(σ; sample_rate, t_max, rng)` —
    pre-sampled white-Gaussian stream; models thermal /
    scheduler-jitter sensors.
  - `CouplingParams(F_base, streams, alphas, coupling_vectors)` —
    parameter bundle threaded through `CoupledODEs`. Validates
    equal stream/alpha/coupling-vector lengths and uniform N
    across coupling vectors.
  - `no_coupling(F_base)` — empty `CouplingParams` reducing the
    coupled SDE to uncoupled Lorenz-96.
- **`src/julia/test/runtests.jl`** — 4 new `@testset` blocks
  (21 assertions) covering: sensor-stream primitives;
  no-coupling sanity (`lorenz96_coupled` with `no_coupling()`
  reproduces uncoupled `lorenz96` to within 0.05 spectrum
  tolerance); stepped-sensor smoothness (binary 0→1 step
  smoothed by sigmoid τ=0.5; trajectory bounded throughout, no
  step-time anomaly, time-windowed mean ⟨x⟩ shifts in predicted
  direction); α-sweep non-degeneracy (constant sensor, sweep
  α ∈ {0, 1, 2}, Δλ₁ measurable per step and cumulatively).
- **`docs/p3a_sensor_coupling_companion.md`** — session
  companion. §2.1 defines the linear-in-x potential
  U(s, x; t) = Σ_k α_k · s_k(t) · ⟨b_k, x⟩; §2.2/§2.3
  document sanity and smoothness results; §2.4 records the
  corrected ⟨x⟩(F) prediction (chaotic-regime mean ≈ 2.34, not
  fixed-point F=8) and its implication that trajectory-mean
  detection is ~10× weaker than spectrum-based detection,
  empirically validating round-1's architectural choice for
  Lyapunov-spectrum residue audit; §2.5 reports non-degeneracy
  measurements (Δλ₁ ≈ +0.30 at α=1, +0.59 at α=2). §5 captures
  three lessons: spectrum vs trajectory-mean SNR, fixed-point
  ⟨x⟩ ≠ chaotic-regime ⟨x⟩, and lockfile `[deps]` vs `[extras]`.

### Changed

- **`src/julia/src/Engine.jl`** — adds:
  - `lorenz96_coupled_eom!(du, u, p::CouplingParams, t)` —
    sensor-perturbed forcing per architecture-design §2.4. Per-
    component perturbation `F_i = F_base + Σ_k α_k · s_k(t) ·
    b_k[i]`. Sensor evaluations hoisted out of the per-component
    loop.
  - `lorenz96_coupled(N; F, coupling, u0)` — public constructor
    of the coupled `CoupledODEs`.
  - Re-exports new symbols.
- **`src/julia/src/LavaLamp.jl`** — re-exports the coupled
  variant + sensor primitives.
- **`src/julia/Project.toml`** — `Random` moves from `[extras]`
  (test-only) to `[deps]` (regular). `gaussian_noise_stream`
  uses `Random.AbstractRNG` and `randn` at module level, so
  Random must be a regular dep. The Manifest does not require
  re-resolution because Random is a stdlib (already
  transitively pinned).
- **`LAVALAMP_SPEC.md`** — version 0.0.6 → 0.0.8. LL-004
  evidence type `manual` → `example-tested`; status `:argued`
  → `:tested`; Source/Test paths added; description expanded
  with the linear-in-x prototype form. Counts: `:tested` 1 →
  2; `:argued` 12 → 11. Total still 18.
- **`artifact_registry.md`** — version 0.0.6 → 0.0.8. LL-004
  row updated. Cross-audit A6 records 29/29 assertions passing
  ~40s wall clock. CI integration explicitly recommended
  before P3b.
- **`dashboard.md`** — version 0.0.6 → 0.0.8. Project state
  summary updated with P3a numbers. P3 priority block adds
  0.0.8 sub-status; P3a marked landed; P3e (non-degeneracy
  benchmark) folded into P3a's test suite (closed in 0.0.8).
  P3-Nyq sub-task added explicitly. CI workflow listed as a
  P3-level deliverable. Spec status counts updated. Recent
  companion docs gains the P3a entry.

### Why

P3a is the next slice after the 0.0.6 baseline. The substrate-
coupling layer is the *substantive* security mechanism: without
it, Lorenz-96 is just a chaotic SDE; with it, the SDE is bound
to the substrate's sensor reads in a way that makes the
device's identity inseparable from its hardware envelope.

The session validated three structural claims empirically:

1. **Smoothness (LL-004 core content).** A discrete sensor
   transition smoothed by a sigmoid ramp does not produce
   numerical artefacts in the SDE integration. The §2.3 stepped-
   sensor `@testset` confirms this directly.
2. **Tracking.** Trajectory-mean ⟨x⟩ shifts in the predicted
   direction with measurable magnitude. The shift is small
   (~0.2 for α=1) — much smaller than the spectrum shift
   (~0.30). This empirically validates round-1's architectural
   choice to detect via the spectrum, not the trajectory.
3. **Non-degeneracy (LL-006 prerequisite).** ∂λ₁/∂α ≠ 0 across
   the α-sweep. For any non-zero adversary deviation in the
   coupling parameter, the spectrum gap δ_A is non-zero, and
   the §2.1 detection bound P(detect) ≥ 1 - K·exp(-c·T·δ²) has
   positive content.

Each of these is `manual` evidence at the design-pass level
(P2, 0.0.5), now upgraded to `example-tested` for LL-004 by
the prototype.

### Spec impact

- Counts: total 18 unchanged; `:tested` 1 → 2 (+ LL-004);
  `:argued` 12 → 11 (- LL-004); `:open` 5 unchanged.
- Status moves to `:tested`: LL-004.
- Partial evidence contributed (no status move): LL-005
  (Nyquist condition — code-level parameter support);
  LL-006 (residue audit — non-degeneracy prerequisite
  empirically demonstrated; detection bound itself remains
  argued).
- No new spec entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 2 (LL-003, LL-004)
- `:benchmarked`: 0
- `:argued`: 11
- `:open`: 5

### Known gaps

- **LL-005 not yet `:tested`.** Adversary-rate Nyquist benchmark
  requires the residue-audit framework from P3b; folds in there.
- **LL-006 detection bound not yet `:tested` / `:benchmarked`.**
  Non-degeneracy prerequisite empirically demonstrated; the
  P(detect) ≥ 1 - K·exp(-c·T·δ²) bound itself is the P3b
  deliverable.
- **LL-016 sensor authenticity unchanged.** Synthetic stub
  layer cannot address authenticity (TPM attestation /
  cross-validation / anomaly-flagging are deployment-time
  questions). Real-sensor FFI deferred.
- **No CI integration yet.** Recommended before P3b; manual
  rerun after every change becomes burdensome once detection
  benchmarks land.
- **Linear-in-x coupling only.** State-dependent coupling
  (U quadratic-or-higher in x) is a future enhancement.
  Architecture §2.1 detection bound's structural-separation
  prior does not require state-dependent coupling, so this is
  not a blocker.

### Followup recommendations

- **P3b — Residue audit + detection-probability benchmark** is
  the natural next slice. Synthetic adversary trajectories by
  parameter perturbation (ε_A); sweep ε_A and observation
  window T; populate the detection-probability surface.
  Closes LL-006 to `:tested`/`:benchmarked` and folds in
  LL-005's adversary-rate Nyquist content. Inner-loop N likely
  10–20 to manage compute (per 0.0.7 §2.4 budget analysis);
  headline assertions at N=40.
- **CI workflow** before P3b. GitHub Actions running
  `Pkg.test()` on push.
- **P3c chaos-guard** can land in parallel with P3b — different
  files, different test scenarios. Cheaper than P3b
  (single-exponent estimator vs full spectrum).

---

## 0.0.7 — 2026-05-02 — P3 baseline companion + dev-host field observations

Late-landing companion for the 0.0.6 P3 baseline session, plus
three empirical observations from the development host that
surfaced during the canonical baseline test run. The 0.0.6
commit was a "large session" per CLAUDE.md workflow rules and
should have included its companion in the same commit; 0.0.7
corrects the omission. The empirical observations are field
signal worth pinning before they get lost between sessions.

### Added

- **`docs/p3_baseline_companion.md`** — P3 baseline companion.
  - **§1 Computational basis.** Files, build commands, dev-host
    wall-clock metrics (~200s first instantiate, ~20s test).
  - **§2.1 Lorenz-96 baseline reproduces literature.** Numbers
    table: λ₁ = 1.6577 (literature ≈ 1.66, 0.2% match);
    n_pos = 14 (literature 13–14); h_KS = 10.27 (literature
    ≈ 10.5); λ_min = -4.90; Kaplan-Yorke dim = 27.11
    (literature ≈ 27).
  - **§2.2 Empirical robustness against host non-stationarity.**
    Documents that a real configuration event occurred during
    the canonical seed=42 baseline run on the dev M5 Max Pro:
    thermal climb to fan-on threshold + AC adapter plug-in
    (battery had dropped below 15%) + battery state-of-charge
    shift. All 8 test assertions still passed. The bounds
    calibrated for finite-window estimator variance + IC
    randomness also absorbed real-world non-stationarity. This
    is stronger evidence for LL-003 than a clean-machine pass.
  - **§2.3 Substrate-coupling self-demonstration.** The §2.2
    events match the architecture-design §2.4 sensor categories
    one-for-one (high-bandwidth thermal noise; discrete-state
    AC-adapter binary; slow-drift battery SOC). Lorenz-96 in
    0.0.6 ignored them because sensor coupling is P3a; once
    P3a lands, repeating with these triggers would propagate
    the events into the trajectory via U(s, x; t) and would
    require LL-013 cross-config classification to distinguish
    legitimate config change from spoofing. The unintended
    self-demo previews the canonical P3a test scenario shape.
  - **§2.4 Compute load and h_KS are structurally linked.**
    Reframes the dev-host fan-spin event from a "compute cost
    concern" to a *structural indicator*: S_production = h_KS
    sets the resolution-boundary margin Δh per LL-008/LL-018,
    and producing h_KS at a meaningful rate requires sustained
    integration cost. A "warm box" is the security primitive
    operating in the chaos-production regime its claim depends
    on; not a tax on security but a signature of it. Three
    sub-implications: (i) hardware deployment is not free, and
    that is correct; (ii) chaos-guard (P3c) is much cheaper
    than residue audit (P3b) — single exponent vs full
    spectrum, O(N) vs O(N²); (iii) P3b benchmarking budget
    will multiply per-trajectory cost across many synthetic
    adversaries, so inner loops likely use smaller N (10 or
    20) with N=40 reserved for headline assertions.
  - **§3 Verification.** LL-003 already :tested in 0.0.6; the
    §2.2/§2.3/§2.4 observations are `manual` evidence and do
    not move other entries on their own.
  - **§4 Spec impact.** No new entries; no further status
    moves. Positioning language captured for future paper /
    pitch use.
  - **§5 Followups.** P3a/b/c/d test-design and budgeting
    lessons distilled from the observations.

### Changed

- **`dashboard.md`** — version bumped to 0.0.7.
  - Recent companion docs section gains
    `p3_baseline_companion.md` entry.
  - **New section: "Live empirical observations".** Three
    bullets capturing the structural h_KS↔compute link, the
    dev host as a free P3a test-scenario source, and the test
    bounds' demonstrated real-world non-stationarity
    robustness.

### Why

Two independent reasons drove this commit:

1. **Workflow discipline.** The 0.0.6 commit introduced the
   Julia track substantively — a "large session" by CLAUDE.md
   criteria — and should have landed with a companion doc in
   the same commit. 0.0.6 missed step 6 of the large-session
   checklist; 0.0.7 closes that gap. Future sessions: keep the
   companion inside the substantive commit.

2. **Field observations worth pinning.** Three observations
   from the dev host during the 0.0.6 baseline test run are
   not faults but useful signal:
   - The test passed under documented host non-stationarity,
     strengthening LL-003's evidence (§2.2).
   - The host events match the design-§2.4 sensor categories
     one-for-one and preview P3a test design (§2.3).
   - Compute cost and h_KS are structurally linked: a warm
     box indicates the security primitive is producing entropy
     at a rate commensurate with its security margin claim
     (§2.4).
   The third observation is the most consequential: it
   reframes pitch language ("LavaLamp runs cheaply in the
   background" would mis-describe the primitive) and informs
   the P3b benchmarking budget directly.

### Spec impact

None. No new spec entries; no status moves. LL-003 was already
:tested in 0.0.6. The §2.2/§2.3/§2.4 observations are `manual`
evidence supporting LL-003 / LL-004 / LL-016 but do not move
those entries — LL-004 / LL-016 close to :tested only when P3a
implements sensor coupling.

### Counts

Unchanged from 0.0.6: 18 entries total; 1 :tested (LL-003);
12 :argued; 5 :open; 0 :proved / :verified / :benchmarked.

### Followup recommendations

- **Companion doc inside the same commit as the substantive
  work.** The 0.0.6 → 0.0.7 split is honest but slightly out
  of sync; future large-session commits include the companion.
- **CI integration before P3a.** Recommended in the §5.5
  followup; currently the only thing protecting LL-003 is a
  manual `Pkg.test()` on the dev host. GitHub Actions running
  tests on push gives the test suite a real chance to catch
  regressions.
- **P3a sensor coupling slice scoping.** §5.1 distills the
  test-design lessons; the natural minimal P3a slice is a
  synthetic sensor stream coupling to U(s, x; t), exercised by
  a test that injects a sensor event mid-run and asserts the
  trajectory tracks it. Real-sensor IOKit / SMC FFI work
  defers to a later sub-task (or P6 hardening).

---

## 0.0.6 — 2026-05-02 — P3 prototype core (bootstrap + Lorenz-96 baseline)

First substantive Julia prototype work. Establishes the
`src/julia/` track with pinned dependencies (lockfile discipline)
and exercises Lorenz-96 (the leading single-attractor candidate
per the design pass) end-to-end against literature reference
values. LL-003 (single-attractor chaotic engine) moves from
`:open` to `:tested` with `example-tested` evidence; project
state moves from design-stage to prototype-stage.

### Added

- **`src/julia/Project.toml`** — package manifest. Name
  `LavaLamp`, UUID `706f996e-…-8ce7c656a42c`, version 0.0.6.
  Pinned direct dependencies (semver compat in `[compat]`):
  - DifferentialEquations 7
  - DynamicalSystems 3
  - StaticArrays 1
  - Statistics (stdlib)
  Test extras: Random, Test (stdlib).
- **`src/julia/Manifest.toml`** — full transitive lockfile,
  resolved against the local registry. Pins 481 transitive
  packages including DifferentialEquations 7.17.0,
  DynamicalSystems 3.6.7, StaticArrays 1.9.18. Committed
  per the lavalamp CLAUDE.md package-management discipline:
  the Manifest IS the reproducibility lockfile in Julia.
- **`src/julia/src/LavaLamp.jl`** — top-level package module.
  Re-exports `lorenz96` and `lyapunov_spectrum` from `Engine`.
  Documents the conventions in force (real-valued math per
  LL-009; bounded-window analysis per LL-010; security-only,
  visual-decoupled per LL-002).
- **`src/julia/src/Engine.jl`** — Lorenz-96 implementation +
  Benettin spectrum estimator.
  - `lorenz96(N=40; F=8.0, u0=nothing)` constructs a
    `CoupledODEs` from `DynamicalSystems.jl` with the in-place
    Lorenz (1996) right-hand side, periodic boundary by 1-based
    modular index arithmetic.
  - `lyapunov_spectrum(ds; N=5000, Δt=0.05, Ttr=1000.0)`
    estimates the full Lyapunov spectrum via QR
    re-orthonormalization. Defaults calibrated for Lorenz-96
    at N=40, F=8.
  - File-level docstring documents the convention set, the
    "why this primitive" rationale (Lorenz-96's high λ₁,
    parameter sensitivity, and rich spectrum vs Lorenz-63 /
    Rössler), the literature reference values, and the
    performance assumption (memory-fits-in-RAM at N ≤ ~10⁴).
- **`src/julia/test/runtests.jl`** — test suite, 8 assertions
  across three `@testset`s:
  - Lorenz-96 construction smoke.
  - Spectrum length = 40, sorted decreasing.
  - λ₁ ∈ [1.4, 1.9] (literature ≈ 1.66; Lorenz, 1996 +
    Karimi-Paul 2010).
  - Number of positive exponents ∈ [11, 16] (literature 13–14).
  - h_KS = Σ max(λᵢ, 0) ∈ [8.0, 12.5] (literature ≈ 10.5).
  - λ_min < -3.0 (strange attractor has contraction).
  - IC-invariance: |λ₁(seed=7) - λ₁(seed=13)| < 0.2 (Oseledec).
  Run via `Pkg.test()` from `src/julia/`. Wall clock ~20s on
  Apple Silicon (M-class). All 8 assertions pass.

### Changed

- **`LAVALAMP_SPEC.md`** — version 0.0.5 → 0.0.6. LL-003
  evidence type `none` → `example-tested`; status `:open` →
  `:tested`; Source/Test paths added; description expanded with
  Lorenz-96 reference values (λ₁ ≈ 1.66, ~14 positive exponents,
  h_KS ≈ 10.5, Kaplan-Yorke dim ≈ 27). Counts: `:tested` 0 → 1;
  `:open` 6 → 5. Total still 18.
- **`artifact_registry.md`** — version 0.0.5 → 0.0.6. LL-003
  row updated (evidence type, Test/Proof file, Source file,
  status). Counts updated. Cross-audit A6 (test sync)
  meaningful for the first time: LL-003 has a runnable test
  exercising it. A1 coverage 18/18 unchanged.
- **`dashboard.md`** — version 0.0.5 → 0.0.6. Project state
  moves from "design-stage" to "prototype-stage." P3 marked
  ◐ in progress with sub-items P3a..P3e enumerated. Spec
  status counts updated. Open structural questions reduced
  (LL-003 leaves the list). Recent companion docs / formal
  artefacts gains a `src/julia/` entry.
- **`.gitignore`** — Julia build/coverage artefact patterns
  added with comment that Project.toml + Manifest.toml ARE
  committed (lockfile discipline).

### Why

P3 is gated on P2 (closed in 0.0.5). The first slice of P3 is
the lockfile + the smallest substantive numerical result that
exercises the toolchain — Lorenz-96 with literature-comparison
test bounds. The bootstrap and the baseline land in one commit
because the bootstrap is the *first* lockfile (no diff to slip
past); the lavalamp CLAUDE.md "lockfiles in their own commit"
rule is about *subsequent* updates, where lockfile changes
without rationale are the failure mode being prevented.

The Lorenz-96 baseline produces concrete numbers cited
elsewhere in the spec:
- **LL-003** is `:tested` against λ₁ ≈ 1.66.
- **LL-007** chaos-guard's λ₁_expected baseline (and τ_λ ≈
  0.1·λ₁_expected ≈ 0.17 reseed threshold) flows from this
  number.
- **LL-008 / LL-018** S_production = h_KS ≈ 10.5 is the
  device's chaos-production rate, which feeds the
  resolution-boundary margin computation per adversary class.
- **LL-006** detection bound P(detect) ≥ 1 - K·exp(-c·T·δ²)
  has c implicitly bounded by the Lyapunov spectrum's
  estimator-variance; concrete c calibration is a P3b
  follow-up.

Honest framing: LL-003 is `:tested`, not `:verified` or
`:proved`. The test exercises one set of parameters with
deterministic seeds and asserts against literature ranges.
QuickCheck-style property tests over the parameter space
(`:verified`) and Lean proofs of structural claims (`:proved`)
remain follow-ups in P4 / P6.

### Spec impact

- Counts: total 18 unchanged; `:tested` 0 → 1; `:open` 6 → 5;
  `:argued` 12 unchanged; `:proved` / `:verified` /
  `:benchmarked` all 0.
- Status moves to `:tested`: LL-003.
- No new spec entries; no removed entries.

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 1 (LL-003)
- `:benchmarked`: 0
- `:argued`: 12
- `:open`: 5

### Known gaps

- **No CI integration yet.** Tests run via `Pkg.test()` from a
  local checkout. GitHub Actions workflow is a follow-up.
- **No sensor coupling yet.** LL-004 / LL-005 / LL-016 still
  `:argued` only. P3a is the next slice.
- **No residue audit yet.** LL-006 still `:argued` only.
  Detection-probability benchmark (P3b) is the next big
  numerical result after sensor coupling lands.
- **No chaos-guard yet.** LL-007 still `:argued` only.
- **SDE-selection benchmark not yet run.** Lorenz-96 is
  committed as the prototype default; comparative bench (P3d)
  upgrades LL-003 to `:benchmarked` once it lands.

### Followup recommendations

- **P3a — sensor coupling implementation** is the natural next
  step. Touches LL-004 / LL-005 / LL-016. Concrete deliverables:
  potential-field U(s, x; t) functional form (Gaussian-ramp for
  discrete inputs, multiplicative for broadband-noise inputs);
  per-sensor coupling vector calibration; Nyquist analysis for
  the chosen coupling under realistic sensor bandwidths.
- **P3d — SDE selection benchmark** could land in parallel with
  P3a since they touch different files. Lorenz-63 and Rössler
  baselines for comparison.
- **CI workflow** (GitHub Actions running `Pkg.test()` on
  push) is small lift; recommend adding before P3a so the
  test suite is the regression discipline from now on.

---

## 0.0.5 — 2026-05-02 — P2 architectural design pass

P2 closure: the architectural design pass formalising the
Lyapunov-spectrum residue audit, the resolution-bounded security
claim, the chaos-guard, the sensor-coupling potential field, and
the protocol layer (registration / cold-start / cross-config /
no-oracle). Twelve spec entries move from `:open` to `:argued`
with `manual` evidence; one new entry (LL-018) added for
per-adversary-class quantification of the resolution-boundary
margin. P3 (Julia prototype core) unblocked.

### Added

- **`docs/architecture_design_companion.md`** — P2 companion.
  Five §2 sub-sections corresponding to dashboard P2 sub-items:
  - **§2.1 Lyapunov-spectrum residue audit (LL-006).** Vector
    per-exponent threshold τᵢ, not scalar. Detection-probability
    bound P(detect) ≥ 1 - K·exp(-c·T·δ_A²) on observation
    window T and adversary spectrum gap δ_A; structural-separation
    prior anchored on the closure_forces_structure paper's
    Q₅₁ / Q₁₀₂ autopoietic-fixed-point results (cross-sector
    autopoiesis fails 0/5202 across 5 ICs at threshold 0.999).
  - **§2.2 Resolution-Bounded Security claim (LL-008) +
    LL-018.** S_production = h_KS = Σ max(λᵢ, 0) (Pesin); bound
    S_production > S_measurement + log(1/η)/Δt; per-class A1..A6
    quantification split into new LL-018 to prevent the "claim
    shrinks under reading" failure mode. Lean theorem shape
    pinned for P6.
  - **§2.3 Chaos-Guard specifics (LL-007).** Benettin
    estimator over W ≈ 100/λ₁_expected; rejection threshold
    τ_λ ≈ 0.1·λ₁_expected; reseed via host TRNG (`/dev/urandom`
    / `getrandom(2)` / `RDRAND`) at ~1× attractor diameter
    magnitude; 2W warmup before re-marking VALID. Decoupling
    from visual layer (LL-002) preserved — reseeds do not signal
    to the visual.
  - **§2.4 Sensor-coupling potential field (LL-004 / LL-005 /
    LL-016).** Per-sensor catalogue (high-bandwidth noise vs
    discrete-state configuration); SDE form
    dx = f(x) dt + σ dW + ∇U(s, x; t) dt with smoothed ramps
    in U for discrete-sensor inputs and broadband-noise terms
    for high-bandwidth sensors; per-sensor Nyquist analysis;
    f_SDE ≈ 10 kHz baseline. LL-016 sensor authenticity
    strategies in decreasing strength: TPM attestation /
    multi-sensor cross-validation / anomaly-flagging /
    accepted-residual-deployment-context. Default for prototype:
    cross-validation + anomaly-flagging.
  - **§2.5 Protocol layer (LL-011 / LL-012 / LL-013 / LL-014 /
    LL-017).** Registration: TPM + device-derived secret mixing
    default; multi-party threshold scheme as no-TPM fallback;
    time-bounded re-registration as defense-in-depth.
    Cold-start: device-reported WARMUP / OPERATIONAL /
    DEGRADED; single-envelope default with WARMUP "retry in T"
    response. Cross-config: per-config registered envelopes
    (PRE) selected by sensor-authentic configuration claim;
    UNKNOWN_CONFIGURATION rejection. No-oracle:
    {ACCEPT, REJECT, WARMUP, TRANSITIONING,
    UNKNOWN_CONFIGURATION, RATE_LIMITED} response set; rate
    limit 10/min/source + 100/hour/device.
  Companion §3 (verification) marks each result `manual`
  evidence with the explicit argument; §4 (spec impact)
  enumerates the status moves and the new LL-018.

### Changed

- **`LAVALAMP_SPEC.md`** — version bumped to 0.0.5. Eleven
  entries (LL-004, LL-005, LL-006, LL-007, LL-008, LL-011,
  LL-012, LL-013, LL-014, LL-016, LL-017) move from `:open`
  /`none` to `:argued`/`manual` with citation to the design
  companion. New entry **LL-018** added (Core / `:argued` /
  `manual`) for per-class A1..A6 resolution-bound quantification.
  Counts: 17 → 18 total; 0 → 12 `:argued`; 17 → 6 `:open`.
  No `:proved` / `:verified` / `:tested` / `:benchmarked`
  changes.
- **`artifact_registry.md`** — version bumped to 0.0.5. Twelve
  registry rows updated with `manual` evidence type, design-
  companion path, and `:argued` status. New row for LL-018.
  Cross-audit A1 coverage now 18/18; A4 status-honesty preserved.
- **`dashboard.md`** — version bumped to 0.0.5. Project state
  changes from "concept-stage" to "design-stage." P2 marked
  ✓ landed with sub-item summary. P3 marked unblocked. Spec
  status counts updated. Open structural questions reclassified
  into "awaiting P3 / P5–P6 verification" (LL-001/002/003) and
  "corpus-policy boundaries" (LL-009/010/015). Live discipline
  notes consolidated into the structural-questions section
  rather than a separate block (the asymmetry-trap watch and
  the no-complex-numbers / no-open-ended boundaries remain in
  force; their wording is preserved in-place).

### Why

P2 is the gate for P3. The attack-surface enumeration (P1,
0.0.3) listed ten attack vectors with "mitigation pending"
sections naming the design work each vector required. P2
discharges that design work for every vector except the
fundamental sensor-authenticity gap (V-006), which is mitigated
by LL-016's strategy menu but not eliminated — and that
limitation is now honestly stated in the spec rather than
implicit.

The design pass produces `manual` evidence — the weakest
upgrade-tier under the CLAUDE.md taxonomy. This is honest tier
framing: a written argument is not a Lean proof, a Haskell
type-check, or a benchmark. Each `:argued` entry has a clear
upgrade path: P3 prototype produces `:tested` /
`:verified` / `:benchmarked` evidence; P5 Haskell QuickCheck
extends compositional coverage; P6 Lean machine-verifies the
core structural theorems (LL-006 detection bound, LL-008
resolution-boundary, LL-018 per-class quantification).

The closure_forces_structure corpus citations used to ground LL-006's
structural-separation prior were verified directly against the
paper's autopoietic-fixed-point machinery (Q₅₁ / Q₁₀₂; cross-
sector autopoiesis result). The earlier
`qkd_pqc_complementarity_companion.md` named the citations; this
companion ties them to specific paper loci. The
0/5202-on-primary-seed result is `:catlab` evidence — algebraic
/ computational categorical proof at the source — which makes
LavaLamp's structural-separation prior load-bearing rather than
hand-waved.

### Spec impact

- Counts: total 17 → 18; `:argued` 0 → 12; `:open` 17 → 6.
- Status moves to `:argued`: LL-004, LL-005, LL-006, LL-007,
  LL-008, LL-011, LL-012, LL-013, LL-014, LL-016, LL-017.
- New entry: LL-018 (Core, `:argued`).
- Stays `:open`: LL-001, LL-002, LL-003 (await Lean / type / P3
  benchmarks), LL-009, LL-010, LL-015 (corpus-boundary
  declarations).

### Counts

- Total: 18 entries
- `:proved`: 0
- `:verified`: 0
- `:tested`: 0
- `:benchmarked`: 0
- `:argued`: 12
- `:open`: 6

### Known gaps

- **No code yet.** P3 (Julia prototype core) unblocked but not
  yet started. Lockfile discipline (`Manifest.toml`) from day 1
  per CLAUDE.md rule.
- **Sensor-authenticity residual (V-006 / LL-016)** is the
  largest residual risk even after 0.0.5. The design pass
  surfaces four mitigation strategies and recommends a default;
  no strategy fully eliminates V-006. High-assurance deployments
  must specify their A4 capability assumption.
- **Lean theorems remain at sketch level.** §2.2 of the
  companion pins the theorem shape for `detection_complete`;
  the proof is P6 work. None of the `:argued` entries become
  `:proved` until Lean verifies them.
- **Round-2 synthesis-team review** trigger is now met (P2
  closed); not yet invoked. Plan: forward this companion +
  attack-surface enumeration to Gemini (synthesis seat) and
  Grok (edge-witness seat) before P3 prototype work begins.

### Followup recommendations

- **P3 entry points** are listed in dashboard `Priority stack`
  P3 paragraph: SDE selection benchmark, Benettin /
  Rosenstein / Wolf estimator implementation, U(s, x; t)
  concrete form, ∂λ/∂s non-degeneracy benchmark, baseline τᵢ
  threshold calibration.
- **Catlab tier decision (P4)** revisited with concrete
  protocol-layer designs in hand. The protocols (registration /
  cold-start / cross-config) are state-machine + cryptographic
  protocol shape, not categorical structure that obviously
  benefits from Catlab over Haskell. **Recommendation
  unchanged: skip Catlab for LavaLamp.** Document in a
  follow-up to `language_plan_catlab_tier_companion.md`.
- **LL-009 / LL-010** boundary entries should close to
  `:argued` under a small-session companion that articulates
  each boundary in the LavaLamp-specific context. Candidates
  for a future small task; not a P3 dependency.

---

## 0.0.4 — 2026-05-01 — Methodology + positioning refinements

Two related refinements landed in the same session: (1) Catlab.jl
inserted as a fifth tier in the formal stack between numerical
verification and Haskell compositional completeness, motivated by
the closure_forces_structure corpus's `:catlab` evidence-type precedent (9 of
145 `:proved` entries); (2) a positioning companion capturing the
QKD / PQC / possibilistic-identity complementarity worked through
earlier in the session.

### Added

- **`docs/language_plan_catlab_tier_companion.md`** — captures the
  Catlab tier insertion. Establishes the three-jobs distinction
  (Catlab computational-categorical / Haskell compositional /
  Lean formal), the productivity ordering rationale (Catlab
  iterates faster than Haskell or Lean for "does the model close
  at all"), and the LavaLamp-specific decision rule (skip Catlab
  by default; revisit if P2 verification-protocol design surfaces
  categorical structure). Anchors the tier on the closure_forces_structure paper
  corpus precedent — `:catlab` is an audited evidence type with
  9 `:proved` entries currently in the corpus.

- **`docs/qkd_pqc_complementarity_companion.md`** — captures the
  positioning analysis: LavaLamp is not QKD (different problem,
  different security tier — resolution-bounded computational,
  not information-theoretic); is defensive-postured (detect via
  Lyapunov-spectrum residue, not prevent observation); composes
  with PQC rather than replacing it (PQC defends transit
  confidentiality; possibilistic identity defends authentication
  — different layers); replaces MFA under identity-as-closure;
  and inherits the C-conjugate adversary from the closure_forces_structure paper
  cross-sector autopoiesis result (0/5202 on primary seed).
  Records the resolution of an earlier misreading by
  Claude of the Possibilistic Security paper's PQC claim. Adds
  a §2.6 noting the implication of the Q₅₁-as-autopoietic
  reframing (the closure_forces_structure paper) for the identity layer:
  identity is Q₅₁-tier, and the residue audit is a spectrum
  check, not a checkpoint trace match.

### Changed

- **`CLAUDE.md`** — "Language tiers and phase discipline" section
  revised. Catlab.jl / GATlab inserted between verify / obstruct
  and prove (compositional). The three-jobs distinction (Catlab /
  Haskell / Lean) made explicit with explicit "do not collapse"
  warnings for each pairwise collapse. LavaLamp-specific priority
  list updated: P4 is now Catlab (gated on P2), P5–P8 are the
  former P4–P7 (Haskell, Lean, C / C++, visual skin) renumbered.

- **`dashboard.md`** — recent companion docs section updated with
  the two new companions; priority stack renumbered to match
  CLAUDE.md (P1–P8 instead of P1–P7); Catlab decision rule noted
  in P4.

### Why

The 0.0.2 language plan correction (Haskell + Lean → Julia /
Haskell / Lean) covered the prototype-core mistake. It missed the
Catlab tier, which has independent corpus precedent (the closure_forces_structure paper
has 9 `:catlab` `:proved` entries via CatLab.jl) and serves a
distinct job: *computational* category theory that fits between
numerical verification and Haskell's compositional-completeness
check.

The three-jobs distinction is load-bearing: collapsing Catlab into
Haskell (or vice versa) loses content. Catlab computes with
categorical objects; Haskell enumerates composition space; Lean
proves theorems formally. the closure_forces_structure paper's evidence taxonomy already
treats `:catlab` as a distinct evidence type capable of
proved-tier status, so this is precedent, not speculation.

The productivity ordering — Catlab iterates faster than Haskell
or Lean for "does the model close at all" questions — means by
the time a result reaches Haskell the morphisms are known to
compose, and by the time it reaches Lean the theorem statement is
known to be right. Cheaper iteration buys correctness gradient
before more expensive tiers see the work.

The positioning companion is independent of the methodology
refinement but lands in the same session because the conversation
covered both. It captures conclusions about LavaLamp's security
tier, defensive posture, and complementarity with QKD / PQC /
identity-as-closure that were settled earlier in the session and
risked being lost to chat history. The §2.6 connection between
LavaLamp identity and the Q₅₁-as-autopoietic the closure_forces_structure paper result
is new — it grounds the residue audit's spectrum-vs-trace
distinction in a corpus reframing, which strengthens the
conceptual argument behind LL-006.

### Spec impact

None. Both refinements are methodology / positioning, not
security-primitive claims. Spec entry counts unchanged (still 17
entries, all `:open`). No new LL-IDs; no `LAVALAMP_SPEC.md`
change; no `artifact_registry.md` change. The
`artifact_registry.md` cross-audit A1 coverage check still passes
at 17/17.

### Counts

Unchanged: 17 entries, all `:open`. The revisions land in
governance and companion-doc files only.

---

## 0.0.3 — 2026-05-01 — Attack-surface enumeration (P1)

The load-bearing technical artefact: formal threat tree against
LavaLamp's architecture as currently specified (LL-001..LL-014).

### Added

- **`docs/attack_surface_enumeration.md`** — formal threat tree
  document. Six adversary classes taxonomised (A1 remote
  software, A2 unprivileged user-space, A3 root [out of scope],
  A4 side-channel / physical proximity, A5 registration-time,
  A6 time-localized). Ten attack vectors enumerated:
  - **V-001** "good enough" trajectory (defended by LL-006
    Lyapunov-spectrum + LL-003 single-attractor + LL-002 visual
    decoupling)
  - **V-002** basin-spoofing (closed by LL-002 decoupling;
    documented as historical attack with discipline-watch)
  - **V-003** quantum-seed → classical software boundary
    (defended by LL-005 Nyquist + LL-004 continuous coupling)
  - **V-004** sensor Nyquist failure (defended by LL-005)
  - **V-005** slow-drift threshold gaming (defended by LL-006
    multi-scale spectrum + LL-007 chaos-guard)
  - **V-006** sensor-input poisoning (largest residual risk;
    surfaces LL-016 sensor-authenticity-requirement as new
    spec entry)
  - **V-007** registration ceremony (trust-root attack; LL-011
    pending design)
  - **V-008** cold-start window exploitation (LL-012 pending
    design)
  - **V-009** cross-config transition spoofing (LL-013 pending
    design; inherits V-006 risk)
  - **V-010** threshold calibration gaming (surfaces LL-017
    no-oracle requirement; defended partially by LL-006)
  Document also includes adversary-class × attack-vector matrix
  (§4), residual-risks-not-yet-defeated enumeration (§5),
  spec-impact recommendations (§6), followups (§7), and document
  discipline (§8). Maintained artefact, not session companion —
  will be updated as architecture evolves.

### Changed

- **`LAVALAMP_SPEC.md`** — three new spec entries surfaced by
  the enumeration:
  - **LL-015 — adversary-class-A3-out-of-scope** (Boundary).
    Honest scoping: LavaLamp does not claim defense against
    kernel-level adversaries. Parallel to LL-009 / LL-010 in
    pinning a corpus boundary explicitly.
  - **LL-016 — sensor-authenticity-requirement** (Core). Sensor
    reads used in security primitive require independent
    authenticity check. Largest residual risk in current
    architecture; mitigation strategies pending (multi-sensor
    cross-validation / hardware attestation /
    accepted-deployment-context risk).
  - **LL-017 — verification-no-oracle** (Core). Verification
    protocol must not expose accept/reject feedback usable for
    threshold probing. Required for LL-014 calibration to
    deliver intended security.
  Counts: 14 → 17 entries; all `:open`.
- **`artifact_registry.md`** — three new rows for LL-015..LL-017.
  Counts updated. A1 coverage check updated to 17/17.
- **`dashboard.md`** — P1 marked ✓ landed. Spec status updated
  (17 entries). Open structural questions section expanded to
  include the three new entries surfaced by enumeration. Recent
  companion docs / formal artefacts section now distinguishes
  session companions from maintained artefacts.

### Why

P1 is the load-bearing technical content of LavaLamp. Without a
formal threat model, the architectural claims in
`LAVALAMP_SPEC.md` are defensible only against the attacks that
happen to come to mind during informal discussion. The
enumeration produces:

1. **Defensible claims.** Each LL-ID's defensive coverage is
   traced to specific attack vectors. The architecture's
   security posture is now stateable in concrete terms.
2. **Honest residual risks.** Five risks the current
   architecture does *not* defeat are named explicitly: sensor
   authenticity (V-006); registration ceremony (V-007);
   cold-start window (V-008); cross-config transitions (V-009);
   threshold calibration (V-010). Each is mapped to its `:open`
   spec entry. No covert overclaiming.
3. **Spec growth.** Three architectural claims that were
   *implicit* in 0.0.1–0.0.2 are now *explicit*: A3 boundary
   (LL-015), sensor authenticity (LL-016), no-oracle requirement
   (LL-017). Pinning prevents drift.
4. **Foundation for P2 (architectural design pass).** Each
   attack vector's "mitigation pending" section lists the design
   work needed. P2 closes those.

### Spec impact

Spec entries 14 → 17. All `:open`. Counts in
`LAVALAMP_SPEC.md`, `artifact_registry.md`, and `dashboard.md`
synchronized.

### Known gaps

- **Sensor authenticity (V-006 / LL-016) is the biggest residual
  risk** in the current architecture. Mitigation strategies are
  named but not yet selected.
- **Registration ceremony (V-007 / LL-011)** is the trust root;
  any deployment is undefended at registration time until
  designed.
- **Cold-start window, cross-config transitions, threshold
  calibration (V-008..V-010)** all pending P2 design work.
- **No code yet.** P3 (Julia prototype core) gated on P2 closure.
- **Round-2 synthesis-team review** of the attack-surface
  enumeration not yet triggered. Plan: forward this document +
  P2 outputs (when ready) to Gemini and Grok and ask them to
  validate the threat tree against attacks the enumeration may
  have missed.

---

## 0.0.2 — 2026-05-01 — Language-plan correction

Pattern-match correction on the priority-stack language assignments.
0.0.1 inherited a "Haskell core + Lean 4 formalisation" stack from
prior in-house projects via pattern-matching, without checking
whether it fit LavaLamp's actual technical needs. Aaron flagged
the mismatch: LavaLamp is continuous-numerical / real-time /
sensor-coupled, which is Julia's natural register, not Haskell's.

### Changed

- **`CLAUDE.md`** — new "Language tiers and phase discipline"
  section between "Honest tier framing" and "Workflow rules".
  Codifies the explore / verify-or-obstruct / prove-compositional
  / prove-formal / harden methodology, with stage-appropriate
  language choices and the rationale for each tier.
- **`dashboard.md`** — priority stack restated. P3 was previously
  "Language-track infrastructure (Haskell + Lean)"; now split
  into P3 (Julia prototype core), P4 (Haskell compositional-
  completeness via spec-as-types + QuickCheck), P5 (Lean 4 formal
  verification of structural security claims), P6 (C/C++ future
  hardening from proven spec), P7 (decoupled visual skin).
- **`README.md`** — layout-comment updated to reflect the language
  plan; placeholder src-subdirectory map shows
  `src/{julia, haskell, lean4, cpp}` rather than just
  `src/{haskell, lean4}`, with which-language-for-which-priority
  explicit.
- **`docs/synthesis_team_round1_companion.md`** — new §7
  capturing the language-plan revision, including Aaron's
  articulated stage-tiered methodology and the rationale for the
  Julia / Haskell / Lean split.

### Why

LavaLamp's prototype core needs to live where the chaos / SDE /
real-time-numerical community has done the algorithmic work, which
is Julia's `DifferentialEquations.jl` + `DynamicalSystems.jl` +
`ChaosTools.jl` stack. Haskell still has a role — but a *different*
role from where it sits in some other in-house projects: as the
**compositional-completeness checker** at the prove stage,
expressing the spec as types and running QuickCheck-style
universal coverage to catch corollaries the example tests miss.
A canonical in-house example: a `semanticSimilarity` symmetry
bug — hand-built example tests passed; QuickCheck immediately
falsified symmetry. Without that stage, an unspotted universal
sails into Lean and any C/C++ rewrite. Lean stays at "prove
(formal) — is the theorem true," which is a different job from
"prove (compositional) — did we enumerate everything."

C/C++ stays as future hardening from the proven spec, not from the
exploratory code.

### Spec impact

None. LL-001 through LL-014 are unchanged. The correction is
about *which language implements each stage of the methodology*,
not about the architectural claims themselves. All entries remain
`:open` at this commit.

### Counts

Unchanged: 14 entries, all `:open`. The revision is about how
those entries get implemented and verified, not what they assert.

---

## 0.0.1 — 2026-04-30 — Concept-stage foundation

Bootstrap the project's discipline scaffolding before any code or
attack-surface enumeration. Mirrors the in-house foundation pattern
(spec → registry → dashboard → companion docs → governance).

### Added

- **`CLAUDE.md`** — project governance. Identity, orientation,
  ground-truth hierarchy, evidence types, load-bearing scope
  boundaries (no complex numbers in security-critical math; no
  open-ended simulation), honest tier framing
  (resolution-bounded computational unclonability, NOT QKD-grade),
  workflow rules, companion-doc standard, cross-audit protocol,
  key principles, what-not-to-do.
- **`LAVALAMP_SPEC.md` v0.0.1** — 14 named claims with LL-IDs,
  logic tiers, evidence types, statuses. All `:open`. Covers:
  - Core architecture (LL-001..LL-005): substrate-bound identity,
    visual/security decoupling, single-attractor SDE engine,
    continuous sensor coupling, sensor Nyquist condition.
  - Detection / verification (LL-006..LL-008): Lyapunov-spectrum
    residue audit, chaos-guard, resolution-bounded security claim.
  - Boundary constraints (LL-009..LL-010): no complex numbers, no
    open-ended simulation.
  - Open protocol questions (LL-011..LL-014): registration
    ceremony, cold-start window, cross-config transitions,
    threshold calibration.
- **`artifact_registry.md` v0.0.1** — registry rows for every
  LL-ID, with self-check against cross-audit A1–A6.
- **`dashboard.md`** — status summary, priority stack, spec
  status, open structural questions, live discipline notes.
- **`changelog.md`** — this file.
- **`docs/concept_origin_companion.md`** — provenance graph
  (codetaur visual seed, Aaron concept derived from Possibilistic
  Security, Brian ORSIΩ-vocabulary engagement,
  patent-offer-to-codetaur).
- **`docs/synthesis_team_round1_companion.md`** — full dialogue
  arc: Gemini synthesis 1, Grok edge-witness 1, Gemini rebuttal +
  premature skeleton, Grok edge-witness 2 on visual-richness
  blindspot, Aaron's decoupling resolution.
- **`README.md`** — project overview (private repo register).
- **`.gitignore`** — Haskell + Lean + macOS standard.

### Why

Concept-stage projects accumulate decisions in chat history that
get lost. Mirroring the in-house foundation pattern: every named
claim gets an LL-ID with status; every substantive session
produces a companion doc; the spec is ground truth. This commit captures the architecture as currently
synthesized — the result of one full round of synthesis-team
(Gemini) + edge-witness-team (Grok) review, with Aaron's
decoupling-resolution closing the round-1 blindspot.

The decision to scaffold the discipline *before* attack-surface
enumeration mirrors the in-house spec-first arc and is consistent
with the corpus-wide spec → registry → companion → code sequence. Code work is gated on attack-surface enumeration, which
is gated on this scaffold.

### Known gaps

- **No code.** Concept-stage. Language tracks (Haskell + Lean 4)
  pending after attack-surface enumeration.
- **Attack-surface enumeration not yet drafted.** P1 priority.
- **Architectural details still informal** in places: the
  Lyapunov-spectrum residue audit's probabilistic detection
  bound, the chaos-guard implementation specifics, the
  sensor-coupling potential field definition (which sensors, how
  mapped, sampling rate calibration). All marked `:open` in the
  spec.
- **The four protocol-level open questions** (registration
  ceremony, cold-start window, cross-config transitions, threshold
  calibration) block any production deployment.
- **Visual-skin scaffolding** not yet drafted. Decorative-only
  per LL-002; low priority.

### Provenance note

Visual seed credit: codetaur (SDE imagery resembling a lava lamp;
structural application unintended). Patent offer extended as
good-faith credit. Concept and security application: Aaron Green,
derived from the C-conjugate adversary structure introduced in
*Possibilistic Security*. Discussion / framing engagement: Brian
Crabtree (ORSIΩ vocabulary). Synthesis-team review: Gemini
(synthesis seat) + Grok (edge-witness seat), 2026-04-30.

---

## Pre-changelog history

None. This commit is the project's foundation.
