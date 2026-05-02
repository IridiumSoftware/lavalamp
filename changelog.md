# Changelog — LavaLamp

Versioned entries top-down. Each entry mirrors a commit; commit
messages match entry summaries.

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
    prior anchored on Closure v5 catlab_spec.jl
    Thm_Q51_autopoietic / Thm_Q102_structure (cross-sector
    autopoiesis fails 0/5202 across 5 ICs at threshold 0.999;
    cross_sector_autopoiesis_v1.py is the source).
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

The Closure v5 corpus citations used to ground LL-006's
structural-separation prior were verified directly against
`catlab_spec.jl` (lines 1855, 1858, 2415) and
`cross_sector_autopoiesis_v1.py`. The earlier
`qkd_pqc_complementarity_companion.md` named the citations; this
companion ties them to specific corpus loci. The
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
the Closure v5 corpus's `:catlab` evidence-type precedent (9 of
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
  categorical structure). Anchors the tier on Closure v5
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
  and inherits the C-conjugate adversary from the Closure v5
  cross-sector autopoiesis result (0/5202 on primary seed,
  v156). Records the resolution of an earlier misreading by
  Claude of the Possibilistic Security paper's PQC claim. Adds
  a §2.6 noting the implication of the Q₅₁-as-autopoietic
  reframing (Closure v5 v157, S157) for the identity layer:
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
Catlab tier, which has independent corpus precedent (Closure v5
has 9 `:catlab` `:proved` entries via CatLab.jl) and serves a
distinct job: *computational* category theory that fits between
numerical verification and Haskell's compositional-completeness
check.

The three-jobs distinction is load-bearing: collapsing Catlab into
Haskell (or vice versa) loses content. Catlab computes with
categorical objects; Haskell enumerates composition space; Lean
proves theorems formally. Closure v5's evidence taxonomy already
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
LavaLamp identity and the Q₅₁-as-autopoietic Closure v5 result
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
0.0.1 inherited the triadic-coordination-engine's "Haskell core +
Lean 4 formalisation" stack via pattern-matching, without checking
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
role from the engine project: as the **compositional-completeness
checker** at the prove stage, expressing the spec as types and
running QuickCheck-style universal coverage to catch corollaries
the example tests miss. The S-026 `semanticSimilarity` symmetry
bug in the engine is the canonical example of why this stage
matters: hand-built example tests passed; QuickCheck immediately
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
attack-surface enumeration. Mirrors the triadic-coordination-engine
foundation pattern (spec → registry → dashboard → companion docs →
governance).

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
get lost. Mirroring the triadic-coordination-engine foundation
pattern: every named claim gets an LL-ID with status; every
substantive session produces a companion doc; the spec is ground
truth. This commit captures the architecture as currently
synthesized — the result of one full round of synthesis-team
(Gemini) + edge-witness-team (Grok) review, with Aaron's
decoupling-resolution closing the round-1 blindspot.

The decision to scaffold the discipline *before* attack-surface
enumeration mirrors the engine project's spec-first arc and is
consistent with the corpus-wide spec → registry → companion → code
sequence. Code work is gated on attack-surface enumeration, which
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
