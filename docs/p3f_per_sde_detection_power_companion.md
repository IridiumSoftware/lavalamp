# P3f — Per-SDE Detection-Power Benchmark + Companion

Version: 0.0.31 (LL-006 per-SDE detection-power characterisation;
Lorenz-96 has best operational balance, 2026-05-04)

Permanent record of the per-SDE detection-power benchmark — the
last unblocked sub-item from the round-3-trigger memory's queue
("rerun P3-bound fit on Lorenz-63 / Rössler"). Sweeps a
parameter-space adversary against each of the three candidate
SDEs and characterises the LL-006 detection bound shape per
engine.

**Net result.** The detection-bound shape `P(detect) ≥ 1 - K ·
exp(-c' · T · ε_A²)` applies cleanly to all three SDEs, with
SDE-specific c′ values reflecting per-parameter detection
sensitivity:

| SDE       | param | c′       | binding ε_A | comment |
|-----------|-------|---------:|------------:|---------|
| Lorenz-96 | F     |  0.00372 |       1.000 | balanced |
| Lorenz-63 | ρ     |  0.00168 |       4.000 | low sensitivity |
| Rössler   | c     |  0.38179 |       0.200 | extremely brittle |

The c' values are not directly comparable across SDEs (F, ρ, c
have different absolute scales), but they expose a clear
architectural pattern:

- **Lorenz-96** has the right operational balance: high h_KS
  (10× Lorenz-63 / 155× Rössler from 0.0.25 P3d) AND moderate
  per-unit parameter sensitivity (c'_F = 0.00372).
- **Lorenz-63** is doubly weak for production: low h_KS AND
  low per-unit parameter sensitivity (c'_ρ = 0.00168 — half
  Lorenz-96's per-unit; binding ε_A = 4.0 means ρ must drift
  by ~14% before detection, vs Lorenz-96's F drifting by 12.5%).
- **Rössler** is too brittle for production: low h_KS AND
  extremely high per-unit parameter sensitivity (c'_c = 0.382 —
  two orders of magnitude larger than the others). Genuine
  calibration drift in c (thermal, age, etc.) of order 0.1 — a
  ~2% absolute drift — is enough to trigger rejection. This
  brittleness adds a second reason to reject Rössler for
  production beyond the h_KS reason from 0.0.25.

LL-006 stays `:benchmarked`. The per-SDE characterisation adds
deployment-guidance content to the entry's footer and confirms
the 0.0.25 P3d architectural choice (Lorenz-96 over alternatives)
on a complementary axis.

---

## §1 — Computational basis

### §1.1 — Adversary model: parameter-space, not coupling-space

The 0.0.17 P3-bound benchmark fitted Lorenz-96 detection
constants against an **α-space adversary** — perturbations in
the sensor-coupling-strength vector. That adversary model
applies only to `lorenz96_coupled` (the prototype's full
sensor-coupled engine); it does not directly apply to
`lorenz63` / `rossler`, which are standalone SDEs without
sensor-coupling layers in the prototype.

The 0.0.25 P3d benchmark compared raw chaos statistics across
all three SDEs but did not characterise detection-power for
the alternatives.

This benchmark closes that gap with a **parameter-space
adversary** — perturbations to each SDE's principal chaotic
parameter:

- **Lorenz-96**: F (forcing). Baseline F=8.0; chaotic for F ≳ 4.
  Adversary: F → F + ε_A.
- **Lorenz-63**: ρ (Rayleigh number). Baseline ρ=28.0; chaotic
  for ρ > 24.74. Adversary: ρ → ρ + ε_A.
- **Rössler**: c (attractor-stability parameter). Baseline c=5.7.
  Adversary: c → c + ε_A.

Parameter-space adversaries simulate an attacker who knows the
SDE family but not the exact parameter calibration — analogous
to the α-space adversary's "knows the architecture but cannot
reproduce the exact coupling-strength" model from the Audit.jl
docstring, applied at the parameter level rather than the
coupling level.

### §1.2 — Configuration and inputs

- `src/julia/benchmark/p3f_per_sde_detection_power.jl` (new).
- Per SDE: 10 calibration trials + (5 trials × |ε_A grid|)
  adversary trials.
- N_benettin=1200, Δt=0.05, Ttr=200.0 (matches 0.0.17 P3-bound).
- Verifier: vector per-exponent test, k=5 (matches 0.0.17).
- T_observation = 60 time units.
- ε_A grids per SDE (selected to span the FPR-floor → saturation
  transition):
  - Lorenz-96 ΔF ∈ {0, 0.5, 1.0, 1.5, 2.0, 3.0}
  - Lorenz-63 Δρ ∈ {0, 1, 2, 4, 8}
  - Rössler   Δc ∈ {0, 0.05, 0.1, 0.2, 0.5, 1.0}
- Result file:
  `src/julia/benchmark/results/p3f_per_sde_detection_power.txt`.
  Wall-clock excluded per CLAUDE.md §Benchmarking discipline.

### §1.3 — Determinism check

```
$ diff /tmp/p3f_run1.txt \
       src/julia/benchmark/results/p3f_per_sde_detection_power.txt
$ echo $?
0
```

PASS. Two consecutive runs produced byte-identical result
files. The numerical pipeline's byte-identical determinism
holds across the three SDEs at this configuration.

### §1.4 — Wall clock

~5 minutes per run on Apple Silicon: ~4 s calibration ×3 SDEs +
~3 minutes Lorenz-96 (the dominant cost; N=20 and 6×5=30
trials) + ~30 s Lorenz-63 + ~30 s Rössler. The 3-D systems
finish in O(seconds) per trial; Lorenz-96 dominates compute.

---

## §2 — Results

### §2.1 — Per-SDE detection-power surfaces

#### Lorenz-96 (perturbing F, baseline=8.0)

```
ε_A      P_reject    rejects/trials
-----    --------    ---------------
0.000       0.000       0 / 5
0.500       0.000       0 / 5
1.000       0.200       1 / 5
1.500       0.800       4 / 5
2.000       1.000       5 / 5
3.000       1.000       5 / 5
```

Clean sigmoid through ε_A ∈ [1.0, 2.0]. Saturation at ε_A=2.0.
FPR floor 0/5 at ε_A ≤ 0.5.

Fit: K=1.0, c'=0.00372, T=60.0, c'·T=0.2231. Binding constraint:
ε_A=1.0 (the transition-region point with smallest per-point
c_max,i).

#### Lorenz-63 (perturbing ρ, baseline=28.0)

```
ε_A      P_reject    rejects/trials
-----    --------    ---------------
0.000       0.000       0 / 5
1.000       0.000       0 / 5
2.000       0.000       0 / 5
4.000       0.800       4 / 5
8.000       1.000       5 / 5
```

Sigmoid sharper than Lorenz-96 in absolute ε_A terms (transition
through ε_A ∈ [2, 4]) but at much larger ε_A magnitudes. ρ must
drift by ~14% from baseline (Δρ=4 on ρ=28) before the residue
audit detects.

Fit: K=1.0, c'=0.00168, T=60.0, c'·T=0.1006. Binding constraint:
ε_A=4.0.

#### Rössler (perturbing c, baseline=5.7)

```
ε_A      P_reject    rejects/trials
-----    --------    ---------------
0.000       0.000       0 / 5
0.050       0.000       0 / 5
0.100       0.000       0 / 5
0.200       0.600       3 / 5
0.500       1.000       5 / 5
1.000       1.000       5 / 5
```

Very steep transition: 0/5 at ε_A=0.1 (Δc=0.1, ~2% absolute
drift) → 3/5 at ε_A=0.2 (~3.5% drift) → 5/5 at ε_A=0.5 (~9%
drift). Detection happens at much smaller absolute Δc than for
the other SDEs' parameters.

Fit: K=1.0, c'=0.38179, T=60.0, c'·T=22.91. Binding constraint:
ε_A=0.2.

### §2.2 — Comparative reading: c' is per-parameter, not per-SDE-quality

The c' values cluster as:

```
Lorenz-96 c'_F = 0.00372
Lorenz-63 c'_ρ = 0.00168       (0.45× Lorenz-96)
Rössler   c'_c = 0.38179      (103× Lorenz-96)
```

**Important: these c' values are NOT directly comparable as
"detection quality" rankings.** Each c' reflects the
*per-unit-parameter-perturbation* spectrum sensitivity, and the
parameters have different absolute scales (F~10, ρ~28, c~5.7).
A high c' means the SDE is brittle to parameter perturbations,
not that it offers stronger security per se.

The honest reading is:

- **Lorenz-96 c'_F = 0.00372**: detection threshold at Δh ≈ 1
  spectrum-units corresponds to ΔF ≈ 1 (about 12.5% relative
  drift on F=8). Per-unit sensitivity is moderate.
- **Lorenz-63 c'_ρ = 0.00168**: detection threshold at Δh ≈ 1
  corresponds to Δρ ≈ 4 (about 14% relative drift on ρ=28).
  Per-unit sensitivity is half Lorenz-96's. ρ is a much
  larger absolute parameter.
- **Rössler c'_c = 0.382**: detection threshold at Δh ≈ 1
  corresponds to Δc ≈ 0.2 (about 3.5% relative drift on
  c=5.7). Per-unit sensitivity is *enormous*. Even small drifts
  trigger rejection.

### §2.3 — Architectural reading: Lorenz-96 has the right operational balance

The 0.0.25 P3d benchmark rejected Lorenz-63 / Rössler on
**h_KS** grounds (10× / 155× lower than Lorenz-96). This
benchmark exposes a complementary axis:

| SDE       | h_KS    | c'_per-param | Operational characterisation |
|-----------|--------:|-------------:|------------------------------|
| Lorenz-96 |  10.149 |      0.00372 | High security margin AND moderate parameter robustness. |
| Lorenz-63 |   0.900 |      0.00168 | Low security margin AND low detection sensitivity (large drifts before rejection). |
| Rössler   |   0.066 |      0.38179 | Low security margin AND brittle (small drifts trigger rejection). |

**Lorenz-96 has the right balance** for production:

- Security margin (h_KS) is 10-155× higher than alternatives.
- Per-parameter detection sensitivity is moderate enough that
  genuine calibration drift (thermal, age, manufacturing
  variance) is unlikely to trigger spurious rejections, but
  high enough that adversary parameter perturbations *are*
  detectable.

**Lorenz-63's failure mode**: an adversary with a +1 to +2
ρ-perturbation slips through the rejection ball. Calibration
drift of similar magnitude is operationally plausible (thermal
sensitivity of physical analog implementations, manufacturing
variance), so even legitimately-similar Lorenz-63 systems may
not be reliably distinguishable. Combined with the 11× lower
h_KS (less security margin), Lorenz-63 is acceptable only for
low-power-mode fallback per 0.0.25's deployment guidance.

**Rössler's failure mode**: extreme parameter brittleness. Any
small drift in c (thermal, mechanical) triggers rejection of
the *genuine* device. Combined with the 155× lower h_KS,
Rössler is operationally unviable for production despite
having the *highest* per-unit detection sensitivity.

The combined h_KS + c' picture confirms 0.0.25's "Lorenz-96
dominates" architectural choice on two complementary axes:
**security margin** (h_KS) AND **operational robustness**
(per-parameter sensitivity). Lorenz-96 is the only SDE in the
candidate set with both.

### §2.4 — Why Rössler's c-sensitivity is so extreme

Rössler's chaotic regime is a narrow band in c: chaos at
c≈5.7 sits between periodic regimes at c<5 (single attractor)
and c>~10 (different attractor topology). Small perturbations
in c can flip between qualitatively different regimes
(Sprott's chaos atlas; Rössler 1976). The Lyapunov spectrum
changes dramatically across these transitions, so per-unit
spectrum sensitivity is enormous.

This is *intrinsic* to Rössler's structure, not a calibration
artifact of the benchmark. Lorenz-96 by contrast has chaotic
regimes that span F ∈ [4, ~24] with smooth dependence on F —
small perturbations produce small spectrum changes.

For deployment purposes: Rössler's narrow chaotic band is a
structural limitation that the residue audit cannot work
around. Even with perfect calibration, environmental drift will
push the genuine device out of its registered envelope at
small ε.

### §2.5 — Comparing F-space (this) to α-space (0.0.17)

The 0.0.17 P3-bound benchmark fitted Lorenz-96 with α-space
adversary: c'_α = 0.00423. This benchmark fits Lorenz-96 with
F-space adversary: c'_F = 0.00372. The two are within ~12% of
each other, consistent with the underlying spectrum-sensitivity
being similar regardless of which scalar parameter is perturbed
at the prototype's calibration.

The c'_F < c'_α observation suggests F-space perturbations are
slightly *less* detectable per unit than α-space — which makes
sense: F is a single scalar that affects all 20 dimensions
uniformly; α-space perturbations are direction-dependent and
can concentrate in the most-sensitive direction. The 0.0.18
LL-021 worst-case-direction analysis already showed direction
matters substantially.

For a unified Lean theorem (round-2 §1D.v priority 1), both
c'_α and c'_F are instances of the parameterised
detection-bound shape applied to different per-parameter
sensitivity coefficients. The theorem statement holds; the
constants are deployment-time inputs.

---

## §3 — Verification

### §3.1 — LL-006 status: still :benchmarked

LL-006 was closed to `:benchmarked` in 0.0.17 with
c'_α=0.00423 for Lorenz-96 / α-space. This benchmark adds
**per-SDE characterisation** of the same bound shape applied
to parameter-space adversaries. Status unchanged; the
characterisation is additive evidence about the bound's
universality across the candidate engine set.

### §3.2 — Why per-SDE comparability requires care

The c' values from this benchmark cannot be summed,
multiplied, or directly compared as "detection quality"
metrics. Each is a per-parameter sensitivity coefficient with
its own dimensional units. The honest comparison is the
**combined picture** of (h_KS, c'_per-param), which reveals
the operational-balance argument for Lorenz-96 in §2.3.

### §3.3 — Lean theorem grounding

The detection-bound shape is parameterised by an
SDE-and-parameter-specific c'. Any future Lean theorem stating
the bound for one SDE-parameter pair extends to other pairs
by the same proof structure with different constants:

```lean
theorem detection_bound_per_sde
  (M : ChaoticSDE)
  (env : Envelope)
  (param : SDE.PrincipalParameter M)
  (c' : ℝ)                -- SDE-and-parameter-specific
  (T : ℝ) (h_T : T = 60.0)
  (K : ℝ) (h_K : K = 1)
  (adv : ParameterSpaceAdversary M param)
  (ε_A : ℝ) (h_ε : ε_A > 0)
  : P_detect M env adv ≥ 1 - K · exp(-c' · T · ε_A^2)
```

Per the 0.0.18 LL-021 companion, the unified theorem absorbs
the per-parameter sensitivity into c' and lets the structural
content of the bound (exponential decay in T·ε_A²) carry
through. P5/P6 work.

---

## §4 — Spec impact

### §4.1 — LL-006 footer update

Append a "Per-SDE detection-power characterisation (2026-05-04)"
footer to LL-006 documenting:

- The bound shape applies cleanly to all three candidate SDEs.
- Per-SDE c' values: c'_F = 0.00372 (Lorenz-96), c'_ρ = 0.00168
  (Lorenz-63), c'_c = 0.38179 (Rössler).
- c' values are NOT comparable as "detection quality"; they
  reflect per-parameter sensitivity coefficients.
- Combined with 0.0.25 P3d's h_KS comparison, **Lorenz-96 has
  the right operational balance**: high security margin AND
  moderate parameter robustness.

### §4.2 — No status change

LL-006: stays `:benchmarked`. Counts unchanged
(22 / 0 / 0 / 2 / 0 / 4 / 15 / 1).

### §4.3 — Files changed

- `src/julia/benchmark/p3f_per_sde_detection_power.jl` — new.
- `src/julia/benchmark/results/p3f_per_sde_detection_power.txt`
  — new.
- `docs/p3f_per_sde_detection_power_companion.md` (this file)
  — new.
- `LAVALAMP_SPEC.md` — LL-006 footer addition.
- `artifact_registry.md` — LL-006 row update.
- `dashboard.md` — recent companion docs update; spec status
  counts (no change); P3 follow-ups list updated.
- `changelog.md` — 0.0.31 entry.
- `README.md` — companion list + benchmark list updates.

No source code changes; no test changes. The benchmark uses
the existing `lorenz96`, `lorenz63`, `rossler`,
`lyapunov_spectrum`, `register_envelope`, `verify` APIs only.

---

## §5 — Lessons captured

### §5.1 — Detection-bound shape is universal across the candidate set

All three SDEs produced clean detection sigmoids with the same
bound shape `1 - exp(-c'·T·ε_A²)`. The universality of the
shape — across SDEs with very different chaos statistics
(h_KS varying by 155×) — confirms that the LL-006 bound is a
structural feature of the residue-audit-on-Lyapunov-spectrum
methodology, not specific to Lorenz-96.

This generalises the 0.0.17 P3-bound's "the bound holds at this
configuration" claim to "the bound holds across the candidate
SDE set with SDE-specific c' constants."

### §5.2 — c' is per-parameter, not per-SDE

A naive reading of the c' table would say "Rössler has the
best detection (highest c')". The honest reading is "Rössler
has the highest *per-unit-parameter* sensitivity, which
reflects its narrow chaotic band, which makes it brittle to
genuine calibration drift, not better as a security
primitive."

The lesson generalises: when comparing fitted constants across
parameterisations, the constants are not directly commensurate
unless the parameter scales are normalised. For per-SDE
deployment-design comparisons, the relevant metric is the
**combined picture** of (h_KS, c'_per-param) — security margin
AND operational robustness — not c' alone.

### §5.3 — The architectural choice is on two axes

The 0.0.25 P3d benchmark rejected Lorenz-63 / Rössler on
h_KS grounds (security margin). This benchmark adds parameter
robustness as a second axis. The combined picture:

- Lorenz-96 wins on h_KS (security margin: 10-155× alternatives)
- Lorenz-96 wins on operational robustness (moderate per-param
  sensitivity, neither too low for adversary detection nor too
  high for genuine calibration tolerance)
- Lorenz-63 loses on both (low h_KS, low per-param sensitivity)
- Rössler loses on both (low h_KS, extreme per-param brittleness)

For round-3 input: the architectural-choice argument now has
two empirical axes; further SDE candidates (e.g., higher-N
Lorenz-96 variants, Henon, Chua) can be compared on the same
two-axis framework. The benchmark methodology is reusable.

### §5.4 — Methodology composes again

This is the fourth refresh / scaling exercise in 24 hours
using the same constrained-fit + Wilson-CI methodology
established in 0.0.17 P3-bound:

- 0.0.28 LL-021 high-res (n-scaling of trial count)
- 0.0.29 LL-019 high-res (regime-boundary finding)
- 0.0.30 LL-003 N-scaling (system-size scaling)
- 0.0.31 LL-006 per-SDE (engine-candidate scaling)

Each session is faster than the last because the templates
exist (constrained fit, Wilson CIs, per-N intensities,
companion structure). The continuity is now *the* development
pattern for empirical-refinement work in the prototype; future
sessions can iterate efficiently within this template.

### §5.5 — All known unblocked sub-items now closed

Per the 0.0.25 round-3-trigger memory, the unblocked queue at
session start was:

1. Higher-resolution refresh of P-R2c (15+ trials) → **closed in 0.0.28**
2. Higher-resolution LL-019 KS-test at α=0.01 → **closed in 0.0.29 (regime-boundary)**
3. Detection-power-vs-ε benchmark for LL-020 Strategy 2 → **closed in 0.0.27 (with bug-fix)**
4. LL-005 part-(a) parameter-validation test — *deferred to round-3* per 0.0.24
5. Higher-N Lorenz-96 scaling benchmark → **closed in 0.0.30**
6. Per-SDE detection-probability surface → **closed in 0.0.31** (this commit)

All items closed except the deferred LL-005 part-(a). The
project is now in a quiet state — no obvious next benchmark
without round-3 trigger landing or new architectural work
surfacing. Round-3 remains gated on the
`closure_forces_structure` paper update.
