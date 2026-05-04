# LL-005 Part-(a) — Parameter-Validation Test + Companion

Version: 0.0.32 (LL-005 part-(a) parameter-validation test;
entry stays :argued, 2026-05-04)

Brief permanent record of the LL-005 part-(a) parameter-
validation test landing. The round-3-trigger memory and the
LL-005 spec footer both flagged this item with the warning
"consider deferring to avoid misleading partial upgrade." This
companion documents why the test landed despite the warning,
and why LL-005's entry-level status correctly stays `:argued`.

**Net result.** A `nyquist_compliant(f_SDE, f_sensor, bandwidth)`
predicate is added to `src/julia/src/Sensors.jl`, with 16 new
test assertions covering the prototype's defaults, borderline
strict-inequality edges, argument validation, and type
flexibility. Test suite 123/123 → 139/139. **LL-005 stays
`:argued` at the entry level** — the test evidences only the
parameter-compliance sub-claim; the adversary-detection
sub-claim remains open per the 0.0.24 P3-Nyq negative finding.

---

## §1 — Computational basis

### §1.1 — The two-sub-claim structure of LL-005

LL-005 — *sensor-Nyquist-condition* — is structurally a
*conjunction* of two implicit sub-claims:

1. **Parameter compliance**: `f_SDE > 2 · bandwidth ∧ f_sensor
   > bandwidth`. The deployment's chosen sample rates exceed
   the assumed adversary measurement bandwidth.
2. **Adversary detection**: the residue audit (LL-006) detects
   sub-Nyquist sensor reconstruction by an adversary whose
   measurement bandwidth is below `f_sensor` but who attempts
   to reconstruct the genuine stream.

Both sub-claims must hold for LL-005 to be `:tested`. A test
that evidences only one sub-claim is partial coverage, and
upgrading to `:tested` from partial coverage would overclaim
under CLAUDE.md §Honest framing.

The 0.0.24 P3-Nyq benchmark (`docs/p3_nyq_companion.md`)
attempted to evidence sub-claim (2). Result was **NEGATIVE**:
zero-mean Gaussian noise has time-averaged statistics that are
invariant under sub-sampling, so the Lyapunov-spectrum residue
audit cannot detect sub-Nyquist adversaries by construction.
Sub-claim (2) therefore requires either a different audit
mechanism (FFT-based PSD audit, trajectory-checkpoint
comparison) or LL-016 sensor authenticity (multi-sensor
cross-validation, hardware attestation) to address the gap —
both round-3 architectural input.

This companion documents the part-(a) test for sub-claim (1).
The discipline question — "should we add the test even though
it can only evidence one of two sub-claims?" — is the
substantive content here.

### §1.2 — Why the test landed despite the deferral warning

The round-3-trigger memory said: *"~10 min — but consider
deferring to avoid misleading partial upgrade."*

The deferral concern was: if we add a parameter test and move
LL-005 to `:tested`, we'd be implying the *entry-level* claim
is tested when only one of two implicit sub-claims has
evidence. That would be dishonest framing.

The resolution: **add the test, but keep LL-005 `:argued`**.
The CLAUDE.md status-honesty rule does not require partial
test coverage to upgrade status. A test can exist as evidence
on a sub-claim without changing the entry-level status when
the entry's claim is a conjunction and only one conjunct is
tested.

The discipline benefit: future deployments can call
`nyquist_compliant(...)` at configuration time to assert
parameter compliance. Without the predicate, that check has
to be open-coded each time. Having the predicate in the
prototype's API surface — with documentation that explicitly
notes the partial-coverage status — is a small operational
improvement that respects the spec's structural caveats.

### §1.3 — The predicate

```julia
function nyquist_compliant(f_SDE::Real, f_sensor::Real, bandwidth::Real)
    f_SDE > 0 || throw(ArgumentError("f_SDE must be positive"))
    f_sensor > 0 || throw(ArgumentError("f_sensor must be positive"))
    bandwidth > 0 || throw(ArgumentError("bandwidth must be positive"))
    return Float64(f_SDE) > 2 * Float64(bandwidth) &&
           Float64(f_sensor) > Float64(bandwidth)
end
```

The strict inequalities `>` (not `>=`) match LL-005's formal
requirement. The function is exported at the LavaLamp top
level alongside the existing sensor primitives.

---

## §2 — Results

### §2.1 — Test coverage

16 new assertions in `src/julia/test/runtests.jl`:

- **Prototype defaults**: `nyquist_compliant(20.0, 100.0, 5.0)`
  → true (f_SDE=20Hz from Δt=0.05; gaussian_noise_stream
  default sample_rate=100Hz; BW=5Hz is plausible for thermal
  noise at typical deployment regimes).
- **Strict-inequality edges (f_SDE side)**: BW=9.9 passes
  (20 > 19.8); BW=10 fails (20 > 20 is false); BW=15 fails
  (20 < 30).
- **Strict-inequality edges (f_sensor side)**: f_sensor=5,
  BW=5 fails (5 > 5 is false); f_sensor=5.1, BW=5 passes;
  f_sensor=3, BW=5 fails directly.
- **Both fail**: f_SDE=8, f_sensor=3, BW=5 fails both.
- **Argument validation**: zero or negative inputs throw
  `ArgumentError`.
- **Type flexibility**: `Real` arguments accepted (Int,
  Float64, Rational); only Float64 enforced internally.

Test suite count: 123/123 → 139/139.

### §2.2 — What the test does and does not show

**Shows:**

- The deployment's chosen rates pass a per-deployment
  Nyquist-compliance check against an explicit bandwidth.
- The function is callable, validates arguments, and returns
  Bool only (no oracle leak; matches LL-017 discipline by
  default).

**Does not show:**

- That the prototype's actual deployment defaults
  (f_SDE=20Hz, f_sensor=100Hz) are correct for any *specific*
  threat model. The bandwidth parameter is supplied by the
  caller; the test verifies the predicate's logic, not the
  prototype's threat-model bandwidth choice.
- That the residue audit detects sub-Nyquist adversaries
  (the 0.0.24 P3-Nyq negative finding stands).
- That LL-005's entry-level claim is true. The conjunction
  of the two sub-claims still has one open conjunct.

The test is **necessary but not sufficient** for `:tested`
status — sufficient for the parameter sub-claim, insufficient
for the entry-level claim.

---

## §3 — Verification

### §3.1 — LL-005 status stays :argued

LL-005 entry-level evidence type remains `manual` and status
remains `:argued`. The test exists; the upgrade does not. This
is honest framing per CLAUDE.md §Status honesty.

A `:tested` upgrade requires both sub-claims to have direct
evidence. The current state:

- Parameter sub-claim: 16 example-tested assertions (this
  commit). `example-tested` evidence type for *this sub-claim*.
- Adversary sub-claim: NEGATIVE empirical evidence from 0.0.24
  P3-Nyq. The residue audit cannot evidence detection of
  sub-Nyquist adversaries. Sub-claim is *open at the
  architecture-level*; round-3 must redesign the detection
  mechanism (FFT/PSD or LL-016 cross-validation) before
  positive evidence can accumulate.

When round-3 lands and the adversary sub-claim is addressed,
LL-005 can move to `:tested` (or skip directly to
`:benchmarked` if the new mechanism comes with an empirical
detection-power surface). Until then, `:argued` is the honest
status.

### §3.2 — Counts unchanged

- Total: 22 (unchanged)
- `:proved`: 0
- `:tested`: 2 (LL-004, LL-007 — unchanged)
- `:verified`: 0
- `:benchmarked`: 4 (LL-003, LL-006, LL-019, LL-021 — unchanged)
- `:argued`: 15 (LL-005 stays here — unchanged)
- `:open`: 1 (LL-015 — unchanged)

---

## §4 — Spec impact

### §4.1 — LL-005 footer addition

Append a "Parameter-validation test (2026-05-04, part-(a)
only)" footer to LL-005 documenting:

- The `nyquist_compliant` predicate added to Sensors.jl.
- 16 new test assertions; suite 123 → 139.
- Status unchanged at `:argued` because the adversary-side is
  still open (round-3 input).
- Cross-reference to this companion for the discipline
  rationale.

### §4.2 — Files changed

- `src/julia/src/Sensors.jl` — `nyquist_compliant` predicate +
  docstring + export.
- `src/julia/src/LavaLamp.jl` — re-export.
- `src/julia/test/runtests.jl` — new `Nyquist compliance
  predicate (LL-005 part-(a))` testset (16 assertions).
- `docs/ll005_part_a_companion.md` (this file) — new.
- `LAVALAMP_SPEC.md` — LL-005 footer addition.
- `artifact_registry.md` — LL-005 row update (Test/Proof
  column adds `runtests.jl` reference + this companion).
- `dashboard.md` — minor: updated test suite count.
- `changelog.md` — 0.0.32 entry.
- `README.md` — companion list update; test count updated.

---

## §5 — Lessons captured

### §5.1 — Sub-claim evidence ≠ entry-level upgrade

A spec entry whose claim is a conjunction of N sub-claims
needs evidence on all N to upgrade to `:tested`. Adding a test
that evidences fewer than N is *legitimate engineering work*
— it lowers operational friction for the evidenced sub-claims
— but it is not sufficient for status-upgrade.

The CLAUDE.md §Honest framing rule covers this implicitly via
"No entry has a status its evidence type can't support" but
the explicit conjunctive case is worth surfacing: a `manual`
argument plus a partial `example-tested` test is still
`:argued` at the entry level.

### §5.2 — The deferral warning was right; the implementation was wrong

The original deferral concern in the round-3-trigger memory
read: *"~10 min — but consider deferring to avoid misleading
partial upgrade."* The concern was correct in spirit (don't
overclaim) but wrong in implementation (the right move is to
add the test without upgrading, not to skip the test).

This is generalizable: when a deferral warning is structured
as "add X but don't claim Y," the right move is usually to add
X with explicit guard against Y, not to skip X. Skipping X
loses operational value that's independent of the Y question.

### §5.3 — All known unblocked items are now closed

With 0.0.32, the round-3-trigger memory's queue at session
start is fully exhausted. Per the 0.0.31 companion §5.5:

1. ✓ Higher-resolution refresh of P-R2c → 0.0.28
2. ✓ Higher-resolution LL-019 KS-test at α=0.01 → 0.0.29
3. ✓ Detection-power-vs-ε for LL-020 Strategy 2 → 0.0.27
4. ✓ LL-005 part-(a) parameter-validation test → 0.0.32
   (this commit; partial coverage)
5. ✓ Higher-N Lorenz-96 scaling benchmark → 0.0.30
6. ✓ Per-SDE detection-probability surface → 0.0.31

The prototype is now in a fully-quiet state. No further
unblocked sub-items remain. Round-3 (gated on
`closure_forces_structure` paper update) is the only outstanding
work-trigger.

The session arc 0.0.26 → 0.0.32 (seven versions in ~24 hours)
demonstrated the maturity of the prototype's
empirical-refinement methodology: the constrained-fit + Wilson
CI + companion-doc + spec-footer pattern composed across six
distinct benchmark / scoping / refresh exercises.
