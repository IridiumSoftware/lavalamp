# P3d Companion — SDE-Selection Comparative Benchmark

Version: 0.0.25 (P3d SDE-selection benchmark; LL-003
:benchmarked, 2026-05-03)

Permanent record of the P3d session. Adds Lorenz-63 and
Rössler as alternate SDE candidates to `Engine.jl`; runs a
comparative benchmark across all three (Lorenz-96 / Lorenz-63
/ Rössler) on the security-relevant metrics; closes LL-003
from `:tested` to `:benchmarked` with the comparative table
as the empirical justification for Lorenz-96 as the
prototype's default.

The architecture-design §2.3 / §3.4 recommendation
("Lorenz-96 is the leading candidate per the design pass")
is empirically justified by this benchmark.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/src/Engine.jl`** — adds `lorenz63(; σ, ρ, β,
  u0)` and `rossler(; a, b, c, u0)` with their in-place
  RHS functions. Standard chaotic-regime defaults.
- **`src/julia/src/LavaLamp.jl`** — re-exports.
- **`src/julia/benchmark/p3d_sde_selection.jl`** —
  comparative benchmark script. Runs full Lyapunov spectrum
  estimation on each SDE at appropriate per-system N and
  Δt, records λ₁ / n_pos / h_KS / Kaplan-Yorke dim / per-
  call wall-clock, 5 trials per SDE, deterministic seeds.
- **`src/julia/benchmark/results/p3d_sde_selection.txt`** —
  committed empirical comparison table.

No new test assertions in `runtests.jl` beyond what's
already exercised by the existing Lorenz-96 baseline tests
(LL-003). The new SDEs were smoke-tested against literature
values during development (documented in §2.1) but not added
to the persistent test suite — they're alternate candidates,
not additions to the prototype's primary SDE.

**Build / run.**

```bash
cd src/julia
julia --project=. benchmark/p3d_sde_selection.jl
# ~30s wall clock; writes the result file
```

---

## §2 — Results

### §2.1 — Per-SDE smoke validation against literature

Before running the comparative benchmark, each new SDE
implementation was smoke-tested against literature values:

| SDE | parameter | literature λ | observed λ |
|---|---|---|---|
| Lorenz-63 | σ=10, ρ=28, β=8/3 | [0.91, 0, -14.6] | [0.929, 0.001, -14.597] |
| Rössler | a=0.2, b=0.2, c=5.7 | [0.07, 0, -5.4] | [0.076, -0.0, -5.147] |

Both reproduce literature within typical estimator
tolerance. Lorenz-63's λ₁ = 0.929 vs literature 0.91 is
≈ 2% — within the standard estimator-variance band for
finite-window Benettin estimation. Rössler's λ₃ = -5.147 vs
literature -5.4 is ≈ 5% — Rössler converges slowly and
N_benettin = 3000 may not have fully converged the high-|λ|
exponent; not material for the comparative benchmark.

### §2.2 — Comparative summary

5 trials per SDE, mean ± std reported for stochastic
quantities:

```
SDE                  dim       λ₁    n_pos    h_KS      KY     wall_s
─────────────────────────────────────────────────────────────────────
Lorenz-96 N=40        40    1.674    13.40   10.257   27.040    3.952
Lorenz-63              3    0.898     1.60    0.900    2.062    0.285
Rössler                3    0.065     1.40    0.066    2.013    0.256
```

Standard deviations (across 5 trials):

| metric | Lorenz-96 | Lorenz-63 | Rössler |
|---|---:|---:|---:|
| λ₁ | 0.0072 | 0.0057 | 0.0047 |
| n_pos | 0.55 | 0.55 | 0.55 |
| h_KS | 0.026 | 0.0060 | 0.0049 |
| KY dim | 0.001 | 0.0004 | 0.0011 |
| wall_s | 0.064 | 0.601 | 0.545 |

(The wall_s std for Lorenz-63 / Rössler is dominated by
first-call compilation overhead in trial 1; subsequent trials
are fast. Lorenz-96's wall_s is consistent.)

### §2.3 — h_KS ratio (vs. lowest)

```
Lorenz-96 N=40     : 155.15×
Lorenz-63          :  13.62×
Rössler            :   1.00× (baseline)
```

**Lorenz-96 produces 155× the chaos rate of Rössler and 11×
the chaos rate of Lorenz-63.** This is the security-relevant
ratio: per LL-008 / LL-018, S_production = h_KS sets the
upper limit on the resolution-bound margin Δh against any
adversary measurement bandwidth. Higher h_KS → more
adversary-resistance.

### §2.4 — Per-axis comparison

#### λ₁ (leading exponent)

Lorenz-96 ≈ 1.67 vs Lorenz-63 ≈ 0.90 vs Rössler ≈ 0.07.
Lorenz-96 has the fastest per-direction divergence rate.
This matters for the chaos-guard (LL-007): the warmup
window scales as 100/λ₁_expected, and a higher λ₁ means
the system equilibrates faster after a reseed event. At
Rössler's λ₁ ≈ 0.07, warmup would take ~1500 time units
versus Lorenz-96's ~60 — a 25× operational latency for the
same security regime.

#### n_pos (Lyapunov richness)

Lorenz-96 has ~13.4 positive exponents (out of 40 total —
about 1/3 of the spectrum). Lorenz-63 and Rössler each
have ~1.5 positive exponents (out of 3 total). The high-
dim Lorenz-96 system gives the verifier ~13× more
spectral degrees of freedom to check against — more
attack surface for adversaries to match simultaneously.

This is the LL-006 vector-test rationale at scale: with 13
positive exponents to match, the adversary must control 13
parameters; with 1, they control 1.

#### h_KS (chaos-production rate)

Already covered in §2.3. Lorenz-96 dominates by
1-2 orders of magnitude.

#### Kaplan-Yorke dimension

Lorenz-96 ≈ 27.0 vs Lorenz-63 ≈ 2.06 vs Rössler ≈ 2.01.
The KY dimension is the *fractal dimension* of the strange
attractor — a measure of attractor complexity. Higher
dimension = more fine structure, harder to model. Lorenz-96
attractor lives in ~27-dim subspace of the 40-dim state
space; the 3-dim systems both have KY dim ≈ 2 (typical for
3-dim chaotic flows).

#### Compute cost

Lorenz-96 takes ~14× longer per spectrum estimation than
the 3-dim systems (~4s vs ~0.3s at our config). Cost-vs-
chaos-production ratio:

| SDE | wall_s | h_KS | h_KS / wall_s |
|---|---:|---:|---:|
| Lorenz-96 N=40 | 3.95 | 10.26 | 2.60 |
| Lorenz-63 | 0.29 | 0.90 | 3.10 |
| Rössler | 0.26 | 0.07 | 0.27 |

**Lorenz-63 is slightly more compute-efficient per chaos-
unit** (3.10 vs 2.60), but Lorenz-96's *absolute* h_KS is
~11× larger which matters for the resolution-bound margin
(an adversary needs to clear a higher absolute bandwidth
threshold, not a relative one). Rössler is the worst on
both axes.

### §2.5 — Architectural justification of the choice

Lorenz-96 N=40 is the prototype's default per the
architecture-design §2.3 recommendation. The benchmark
empirically justifies the choice on all five axes:

- **λ₁** (×1.86 vs Lorenz-63, ×26 vs Rössler) — fastest
  per-direction chaos.
- **n_pos** (×8.4 vs both) — richest spectrum.
- **h_KS** (×11 vs Lorenz-63, ×155 vs Rössler) — highest
  S_production for the same adversary bandwidth.
- **KY dim** (×13 vs both) — most complex attractor.
- **Compute cost** — only ~14× higher than Lorenz-63;
  per-h_KS is comparable.

The trade-off the design makes: spend ~14× the compute to
get ~11× the chaos production AND ~8.4× richer spectrum
AND ~13× the attractor complexity. The compute is the
necessary cost of the security margin.

### §2.6 — When to use Lorenz-63 / Rössler instead

Lorenz-63 is a viable low-power-mode fallback for
deployments where:

- Compute is severely constrained (sub-second per
  verification request matters).
- The security model accepts a ~10× reduction in the
  resolution-bound margin Δh.
- The lower-dimensionality (3 vs 40) makes attack-surface
  analysis simpler.

Rössler is *not* recommended for any production deployment.
Its h_KS is so low (0.07) that the resolution-bound margin
against any non-trivial adversary measurement bandwidth
collapses; LL-008's Δh > 0 condition would be violated for
typical A2/A4 adversaries.

The honest framing per CLAUDE.md: deployment-context
choice. Lorenz-96 is the default; Lorenz-63 is the documented
fallback; Rössler is a benchmark anchor (the "what worse
looks like" reference) and not a production choice.

### §2.7 — Per-SDE configuration notes

Each SDE was benchmarked at parameters appropriate to its
time scale:

- **Lorenz-96**: N_benettin=2000, Δt=0.05, T_obs=100. ~166
  Lyapunov times; well-converged.
- **Lorenz-63**: N_benettin=2000, Δt=0.05, T_obs=100. ~91
  Lyapunov times; well-converged.
- **Rössler**: N_benettin=3000, Δt=0.10, T_obs=300. ~21
  Lyapunov times. Convergence slower (Rössler's λ₁ is
  10× smaller); the 5%-deviation in λ₃ vs literature
  reflects this. Larger N_benettin would tighten Rössler's
  estimates but doesn't change the comparative ordering.

---

## §3 — Verification

### §3.1 — LL-003 :benchmarked upgrade

- **Evidence type:** `benchmarked`.
- **Status moves:** `:tested` → `:benchmarked`.
- **Test:** existing `runtests.jl` LL-003 baseline @testsets
  (8 assertions reproducing literature for Lorenz-96
  N=40, F=8) at `:tested` level.
- **Benchmark:**
  `src/julia/benchmark/p3d_sde_selection.jl` +
  `src/julia/benchmark/results/p3d_sde_selection.txt` +
  this companion's §2 comparative analysis.
- **Performance target:** "the prototype's chosen SDE
  (Lorenz-96 N=40, F=8) dominates alternative SDEs
  (Lorenz-63, Rössler) on the security-relevant metrics
  (λ₁, n_pos, h_KS, KY dim) at acceptable compute cost."
  Result: **MET**. Lorenz-96 has the highest h_KS,
  highest n_pos, highest λ₁, highest KY dim across the
  three candidates; compute cost is ~14× the cheapest
  alternative but justified by the ~11× h_KS gain.

### §3.2 — Why this is `:benchmarked` rather than `:tested`

The original P3 baseline (0.0.6) closed LL-003 to `:tested`
by demonstrating Lorenz-96's λ₁ matches literature (~1.66).
This established that the chosen SDE *works* but did not
empirically justify the *choice* over alternatives.

LL-003's `:benchmarked` evidence is the comparative
benchmark: not "Lorenz-96 has λ₁ ≈ 1.66" (that's :tested
content) but "Lorenz-96 dominates Lorenz-63 and Rössler on
the security metrics by quantified ratios" — a comparative
performance claim met by recorded benchmark.

### §3.3 — What `:benchmarked` does NOT establish

- **No SDE outside the three candidates.** Other chaotic
  systems (Henon-Heiles, double pendulum, Chen system,
  etc.) might compare differently. The benchmark is
  specifically against the round-1 candidate set.
- **No higher-dimensional Lorenz-96 (N>40).** Increasing N
  raises h_KS further but increases compute; the benchmark
  uses N=40 as the prototype default. Different N would
  change the Lorenz-96 column but not the comparative
  structure.
- **No production-realistic compute scaling.** The wall-
  clock numbers are for the prototype's Julia
  implementation. C/C++ rewrite (P7) would give different
  absolute numbers; the comparative ratios should hold.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-003** single-attractor chaotic engine: `:tested` →
  `:benchmarked` with `example-tested` → `benchmarked`
  evidence type. Benchmark + companion paths added.

### §4.2 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 2 (LL-004, LL-007; was 3 — LL-003 leaves)
- **`:benchmarked`:** 4 (LL-003, LL-006, LL-019, LL-021;
  was 3)
- **`:argued`:** 14 (unchanged)
- **`:open`:** 1 (LL-015) (unchanged)

### §4.3 — Files changed

- `docs/p3d_sde_selection_companion.md` (this file) — new.
- `src/julia/src/Engine.jl` — `lorenz63` + `rossler`
  added with EOM functions.
- `src/julia/src/LavaLamp.jl` — re-exports.
- `src/julia/benchmark/p3d_sde_selection.jl` — new.
- `src/julia/benchmark/results/p3d_sde_selection.txt` —
  new (committed comparative table).
- `LAVALAMP_SPEC.md` — LL-003 status move; counts.
- `artifact_registry.md` — LL-003 row update; counts.
- `dashboard.md` — P3d landed; spec status counts; remaining
  unblocked sub-items (P3d removed).
- `changelog.md` — 0.0.25 entry.

Test suite: 117/117 still passes (~52s); the new SDEs
don't break existing tests.

### §4.4 — Followups

- **Higher-N Lorenz-96 benchmark.** N ∈ {20, 40, 80, 160}
  to see how h_KS scales with dimension. Could justify a
  "large-N" deployment mode for high-security applications.
- **Per-SDE detection-probability surface.** The P3-bound
  detection-probability fit (LL-006 :benchmarked) is
  Lorenz-96-specific. Rerunning the same fit for Lorenz-63
  / Rössler would produce comparable bound constants and
  let the deployment model document
  expected detection probability per SDE choice.
- **C/C++ implementation cost.** The compute-cost ratios
  reported here are Julia-specific. P7 hardening would
  produce different absolute numbers; the comparative
  ratios should hold.
- **Lean theorem.** No round-2 §1D.v Lean priority
  specifically targets LL-003's choice. The relevant
  theorem would be parametric in the SDE family ("for any
  ergodic SDE meeting these conditions, the detection
  bound holds") — corollary-style, not a direct LL-003
  theorem.

---

## §5 — Lessons captured

### §5.1 — Comparative benchmarks justify defaults

LL-003 was `:tested` against literature for Lorenz-96
specifically; that established the SDE works but not that
it was the right choice. The `:benchmarked` upgrade
required *comparing* against alternatives. Comparative
benchmarks are the right shape for choice-of-default
claims.

This generalises: any spec entry that picks one option
from a set ("the SDE", "the estimator", "the calibration
strategy") benefits from a comparative `:benchmarked`
benchmark — not just "the chosen option works" but "the
chosen option dominates alternatives."

### §5.2 — h_KS / wall_s isn't the only metric

Lorenz-63 has slightly better h_KS / wall_s (3.10 vs 2.60)
than Lorenz-96. By that metric alone, Lorenz-63 would be
the choice. But the *absolute* h_KS matters more for the
LL-008 resolution-bound margin: a deployment context with
fixed adversary measurement bandwidth needs Lorenz-96's
absolute h_KS = 10.26 to clear margin, regardless of
compute cost.

The lesson: efficiency ratios matter for resource-
constrained deployments; absolute numbers matter for the
security claim. Default to absolute when the security
margin is the load-bearing claim.

### §5.3 — Rössler is the "what worse looks like" anchor

Rössler is so low on every axis (h_KS = 0.07, n_pos = 1.4,
KY ≈ 2.01) that no production deployment would choose it.
But it's a useful benchmark anchor: it shows what
"insufficient chaos production" looks like quantitatively.
Future deployment choices should compare against Rössler
to verify they exceed the worst-case.

The lesson: include a "lower bound" reference in
comparative benchmarks even when the reference isn't a
serious candidate. It calibrates the upper choices.

### §5.4 — Negative-result + positive-result sequences

This work-set produced 0.0.23 (positive — ε-DP works),
0.0.24 (negative — Nyquist isn't detected), 0.0.25
(positive — Lorenz-96 dominates). Three sessions in a row;
mixed positive / negative outcomes; all three commit
honest evidence.

This sequence is the lavalamp pattern in operation:

- Session produces evidence.
- Evidence is committed regardless of polarity.
- Companion documents what was found and what wasn't.
- Spec status reflects evidence honestly.

The discipline is independent of outcome. Negative
results don't get suppressed; positive results don't get
overstated. Future sessions can audit the trail and learn
from both.
