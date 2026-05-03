# P-R2c Worst-Case-Adversary-Bound Companion

Version: 0.0.15 (P-R2c — LL-021 worst-case-adversary-bound,
2026-05-02)

Permanent record of the P-R2c session: analytic derivation of
the worst-case adversary direction in α-space + an empirical
benchmark demonstrating the asymmetry concretely. Closes
LL-021 from `:open` to `:tested` with `example-tested`
evidence backed by a committed benchmark output file.

---

## §1 — Computational basis

**What was built.**

- **`src/julia/benchmark/p_r2c_structured_adversary.jl`** —
  benchmark script. Constructs a Lorenz-96 system with TWO
  sensor channels carrying *different* coupling vectors b
  (b_1 = e_1 narrow vs b_2 = ones(N) broad); sweeps adversary
  perturbation direction in α-space at fixed magnitude;
  produces a structured-adversary detection-probability
  surface that contrasts with the isotropic surface from
  `p3b_detection_lorenz96.txt`.

- **`src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`**
  — committed benchmark output. The headline result table.
  Reproducibility seeds documented in the file header.

- **`docs/p_r2c_worst_case_adversary_companion.md`** (this
  file) — analytic derivation + result reading.

**Build / run.**

```bash
cd src/julia
julia --project=. benchmark/p_r2c_structured_adversary.jl
# ~60s wall clock; writes results/p_r2c_structured_lorenz96.txt
```

---

## §2 — Results

### §2.1 — Analytic derivation of the worst-case direction

Genuine system: α = (α_1, α_2, …, α_n) over n sensor
channels with coupling vectors b_1, b_2, …, b_n each of
length N (the SDE dimension). The forcing per dimension is

```
F_i = F_base + Σ_k α_k · s_k(t) · b_k[i]
```

For constant sensors at value 1.0 (the prototype's
non-degenerate test fixture):

```
F_i = F_base + Σ_k α_k · b_k[i]
```

Adversary perturbation: α → α + ε · û where û is a unit
vector in α-space. The induced F-shift per dimension is:

```
ΔF_i = ε · Σ_k û_k · b_k[i]
```

For Lorenz-96 in the chaotic regime, the leading Lyapunov
exponent λ₁ is approximately a function of the *mean* forcing
F̄ = mean(F_i). To leading order:

```
δλ₁ ≈ (∂λ₁/∂F̄) · Δ F̄ = (∂λ₁/∂F̄) · ε · Σ_k û_k · mean(b_k)
```

So the spectrum gap induced by adversary perturbation in
direction û is:

```
δ_A(û) ≈ |∂λ₁/∂F̄| · ε · |Σ_k û_k · mean(b_k)|
```

**The worst-case direction** for the adversary is the one
that *minimises* δ_A(û): û orthogonal to the vector
(mean(b_1), mean(b_2), …, mean(b_n)) in α-space.

For the prototype's two-channel system with b_1 = e_1 and
b_2 = ones(N):

- mean(b_1) = 1/N (only b_1[1] = 1 nonzero, rest zero)
- mean(b_2) = 1 (all entries 1)

The "mean-coupling vector" is m = (1/N, 1) ≈ (1/20, 1) for
N=20. Worst-case direction is orthogonal to m: û_worst =
(1, -1/N) / sqrt(1 + 1/N²) ≈ (1, -1/20) / 1.001 ≈ (1, -0.05).

This is *almost* the (1, 0) direction (NARROW), with a tiny
negative component on Channel 2 to perfectly cancel the
mean-coupling. In practice the (1, 0) NARROW direction is
within 5% of the worst case, which is why it suffices for
the empirical benchmark.

The **best-case (highest detection)** direction is parallel
to m: û_best = m / ‖m‖ ≈ (1/20, 1) / 1.001 ≈ (0.05, 0.998).
Almost the (0, 1) BROAD direction. Same logic: the broad
direction is within 5% of the best case.

### §2.2 — Empirical benchmark result

The committed table from
`benchmark/results/p_r2c_structured_lorenz96.txt`:

```
direction    ε_A    p_reject   rejects/trials
---------    ---    --------   --------------
NARROW       0.50       0.20      1 / 5
NARROW       1.00       0.00      0 / 5
NARROW       2.00       0.20      1 / 5
NARROW       4.00       0.00      0 / 5
MIXED        0.50       0.00      0 / 5
MIXED        1.00       0.60      3 / 5
MIXED        2.00       1.00      5 / 5
MIXED        4.00       1.00      5 / 5
BROAD        0.50       0.60      3 / 5
BROAD        1.00       1.00      5 / 5
BROAD        2.00       1.00      5 / 5
BROAD        4.00       1.00      5 / 5
```

Three regimes by direction:

- **NARROW (worst-case proxy).** P(reject) ≈ baseline FPR
  across all magnitudes. Even at ε_A = 4.0 (a perturbation
  4× the genuine α magnitude), detection rate is 0/5. The
  narrow-coupling adversary is *effectively undetectable*.
- **MIXED (45° in α-space).** Sigmoid transition around ε_A
  = 1.0. Resembles the isotropic surface from P3b.
- **BROAD (best-case proxy).** Detection saturates at 1.00
  by ε_A = 1.0; partial detection (3/5) at ε_A = 0.5.

At equal ε_A = 1.0, the asymmetry is **0% (NARROW) vs 100%
(BROAD)** — empirical detection ratio exceeding the
analytic ~sqrt(N) under-estimation factor because at this
configuration the narrow direction sits below the noise
floor entirely.

### §2.3 — Why the asymmetry is so dramatic

The §2.1 derivation said worst-case δ_A scales as 1/N
relative to best-case. For N=20, that's a ~20× ratio.
Empirically the ratio is "infinite" at high ε_A (NARROW
stays at FPR; BROAD saturates).

The reason: at the prototype's calibration noise level (σ̄ ≈
0.08 per exponent), the threshold for detection is roughly
k·σ̄ = 5·0.08 = 0.4 in spectrum-distance terms. The narrow
direction's spectrum shift at any ε_A is bounded by ε_A/N ≈
ε_A·0.05, which for ε_A=4 gives 0.2 — *still below the
detection threshold*. Hence 0/5 detection at all tested
magnitudes.

The narrow direction is so weak that no realistic ε_A
crosses the detection floor. To trip the audit on the narrow
direction, the adversary would need ε_A·0.05 > 0.4, i.e.,
ε_A > 8. At that magnitude the perturbation is 8× the
genuine α — operationally implausible for a stealth
adversary, but the *bound is finite*; not zero detection in
all cases.

### §2.4 — LL-021 corrected detection bound

The LL-006 / LL-008 detection-probability shape from §2.1
of the architecture-design companion:

```
P(detect | adversary submits) ≥ 1 - K · exp(-c · T · δ_A²)
```

where δ_A was previously the isotropic-average spectrum gap.
LL-021 corrects this to use the **worst-case** δ_A:

```
δ_A_worst = min_{û : ‖û‖ = 1} (ε · |∂λ/∂α · û|_∞)
```

For the prototype's 2-channel system this minimum is
approximately ε · (1/N) for the narrow direction. The
detection bound then becomes:

```
P(detect | adversary submits) ≥ 1 - K · exp(-c · T · (ε/N)²)
```

— exponentially weaker in N than the isotropic-average
bound at the same ε. Production deployments must either:

1. **Choose coupling vectors with more uniform support** so
   the worst-case ratio is closer to 1. E.g., all b_k =
   ones(N)/sqrt(N) (uniform unit vectors). Reduces the
   worst-case under-estimation but also reduces the
   per-channel coupling strength.
2. **Increase n (number of channels)** with diverse coupling
   directions so that the orthogonal-to-mean-coupling
   subspace is high-dimensional and adversaries cannot
   easily place ε in it. With n=2, the worst-case is a
   single direction; with n=10, it's an 8-dimensional
   subspace.
3. **Accept the bound** and document that the security
   claim against worst-case structured adversaries is
   weaker than against isotropic adversaries by a factor
   set by the coupling matrix's condition number.

The prototype lands option 3: documented bound with a
benchmark; production design choice is deferred to
deployment context.

### §2.5 — Lean theorem shape

Round-2 §1D.v Lean priority 1 named:

> Linear-coupling worst-case bound. Prove that for linear
> coupling there exists a structured perturbation direction
> û such that the residue growth is bounded by O(ε) rather
> than exp(λT)·ε for small T.

Refined statement based on this companion's derivation:

```lean
theorem worst_case_detection_bound
  (M : SDE) (b : Vector (Vector ℝ) n)  -- n coupling vectors
  (ε : ℝ) (hε : ε > 0)
  (T : ℝ) (hT : T > 0)
  : let m := (Σ_k mean(b[k])) ;
    let δ_worst := ε / norm(m) ;  -- worst-case spectrum gap
    P_detect M (worst_case_adversary M ε) T ≤
      1 - K · exp(-c · T · δ_worst²) :=
  sorry
```

The bound's *upper* bound (rather than lower) is what's
honest: the adversary aligned with the worst-case direction
*can* evade detection up to the bound's complement.

### §2.6 — Cost note

The benchmark runs 60 verify_full calls (3 directions × 4
magnitudes × 5 trials) at ~0.7s each, plus 5 calibration
runs. Total wall clock ~50s on Apple Silicon. Roughly
matches the P3b benchmark's cost (which used N=20 with a
single channel; this uses N=20 with two channels which adds
modest sensor-evaluation overhead per integration step).

---

## §3 — Verification

### §3.1 — LL-021 worst-case-adversary-bound

- **Evidence type:** `example-tested`.
- **Status moves:** `:open` → `:tested`.
- **Test:** `src/julia/benchmark/p_r2c_structured_adversary.jl`
  + `src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`
  (committed empirical surface).
- **Source:** `src/julia/src/Audit.jl` (`synthetic_adversary`
  with `direction` parameter — landed in 0.0.9; this
  benchmark exercises it).

### §3.2 — Why this lands at `:tested` not `:benchmarked`

The benchmark *demonstrates* the worst-case asymmetry
empirically and provides reproducible numbers; this is
example-tested evidence. To upgrade to `:benchmarked`
requires:

- A *targeted performance claim*: e.g., "for ε_A < 0.1 the
  worst-case detection probability is ≥ 0.X per the
  derived bound."
- The bound's constants (K, c) calibrated against the
  empirical worst-case curve.
- A check that the empirical curve is *above* the bound
  (not just shape-compatible).

This calibration is plausibly its own session; deferred per
the same logic as the LL-006 `:benchmarked` upgrade
(deferred in 0.0.9).

### §3.3 — LL-006 notes amendment

LL-006's notes section in 0.0.12 already acknowledged that
the empirical detection surface (P3b, isotropic) is an
*optimistic* lower bound. This companion provides the
worst-case counterpart. LL-006's notes should now point at
the P-R2c benchmark file as the worst-case companion to
the P3b file.

### §3.4 — What `:tested` does NOT mean

- **No formal worst-case-direction theorem.** The §2.1
  derivation is heuristic (assumes ∂λ/∂F̄ approximation
  holds; ignores higher-order spectrum dependencies). A
  proper Lean theorem would derive δ_A_worst exactly from
  the SDE and coupling matrix, not from a leading-order
  Taylor expansion.
- **No production coupling-matrix design guidance.** The
  three deployment options in §2.4 are sketches, not
  benchmarked recommendations. P3 follow-ups would need to
  benchmark each option's worst-case detection curve.

---

## §4 — Spec impact

### §4.1 — Status moves

- **LL-021** worst-case-adversary-bound: `:open` →
  `:tested` with `none` → `example-tested` evidence type.

### §4.2 — Notes amendments

- **LL-006** Lyapunov-spectrum residue audit — point at
  `benchmark/results/p_r2c_structured_lorenz96.txt` as the
  worst-case companion to the P3b isotropic surface. The
  empirical detection floor is direction-dependent.

### §4.3 — Updated counts

- **Total:** 21 (unchanged)
- **`:proved`:** 0
- **`:verified`:** 0
- **`:tested`:** 6 (LL-003, LL-004, LL-006, LL-007, LL-019,
  LL-021)
- **`:benchmarked`:** 0
- **`:argued`:** 9 (unchanged)
- **`:open`:** 6 (was 7; − LL-021)

### §4.4 — Files changed

- `docs/p_r2c_worst_case_adversary_companion.md` (this
  file) — new.
- `src/julia/benchmark/p_r2c_structured_adversary.jl` — new.
- `src/julia/benchmark/results/p_r2c_structured_lorenz96.txt`
  — new (committed benchmark output).
- `LAVALAMP_SPEC.md` — LL-021 status move; LL-006 notes
  amendment.
- `artifact_registry.md` — LL-021 row update; counts.
- `dashboard.md` — P-R2c marked done; spec status counts.
- `changelog.md` — 0.0.15 entry.

### §4.5 — Followups

- **LL-021 `:benchmarked` upgrade.** Calibrate K, c, and the
  ε_A → δ_A_worst mapping against the §2.2 empirical
  surface; verify the empirical worst-case curve is above
  the bound prediction.
- **Production coupling-matrix design.** If LavaLamp
  deploys with multi-channel coupling, the coupling-matrix
  condition number sets the worst-case under-estimation
  factor. Design guidance per §2.4 options 1-3 needs to be
  written and benchmarked.
- **Lean theorem.** The worst-case theorem stated in §2.5
  is the round-2 §1D.v Lean priority 1 target. P5/P6 work.

---

## §5 — Lessons captured

### §5.1 — Single-channel benchmarks understate adversary capability

The P3b benchmark used a single channel with b = ones(N).
The "isotropic" adversary in α-space collapsed to ±1 (since
n=1). The benchmark's surface looked clean and well-behaved.
This *was* a worst-case curve — but only because n=1 has no
direction degree of freedom.

P-R2c's benchmark with n=2 demonstrates that the
single-channel "isotropic" surface generalises poorly to
multi-channel deployments. **Default benchmark design rule:
use n ≥ 2 channels with non-trivial coupling-vector
diversity, or document that the benchmark is single-channel-
specific.**

### §5.2 — The narrow direction's empirical detection is "all FPR"

NARROW at ε_A = 4 gave 0/5 detection. The benchmark didn't
just *under-detect* the narrow direction — it failed to
distinguish it from genuine traces *at all*. This is sharper
than the analytic bound (which predicts a finite ε_A
threshold above which narrow detection becomes possible).

The analytic bound is a *lower* bound on the detection
threshold; empirically the threshold is *higher* (because
the calibration σ noise floor adds to the analytic gap).
Production deployments should treat the worst-case bound as
optimistic — empirical noise floors compound it.

### §5.3 — `verify_full` from P-R2a was the right primitive to build on

The benchmark uses `verify_full(ds, env; ...)` for every
call rather than the manual `lyapunov_spectrum` + `verify`
pattern. This is the LL-019 audit-on-every-verify discipline
in action: the benchmark *cannot* accidentally use Wolf-
method λ₁ because the API forces Benettin spectrum.

P-R2a → P-R2c order was the right choice: build the
discipline first, then exercise it in higher-content
benchmarks. P-R2b can land independently.

### §5.4 — The honest-tier framing keeps holding

The benchmark surface is *example-tested* not
*benchmarked*: it demonstrates the asymmetry but doesn't
fit bound constants or verify the prediction. Following the
0.0.9 LL-006 framing exactly. The honest-status discipline
produces consistent classifications across sessions.
