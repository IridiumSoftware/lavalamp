# Cross-Audit Findings — 2026-05-04 (Full A0–A6, post-0.0.34)

Version: 0.0.35 (full A0–A6 cross-audit pre-round-3, 2026-05-04)

Per CLAUDE.md §Cross-audit protocol: "Cross-audits catch drift
between spec, registry, code, and dashboard. Run when integrating
substantive new work or preparing a release. Output: a findings
document (`audit_YYYY-MM-DD.md`) listing discrepancies. Findings
are fixed immediately or added to the priority stack."

This audit was triggered by the seven-version session arc 0.0.26
→ 0.0.34 (P-OS scoping; LL-020 fix; LL-021/LL-019/LL-003/LL-006
high-res / scaling refreshes; LL-005 part-(a); LL-002 visual
layer; P-PharOS scoping). The 2026-05-03 audit
(`docs/audit_2026-05-03.md`) was at 0.0.22 and found PASS across
A0-A6; substantial spec-state changes since then warrant a fresh
cross-audit pre-round-3.

The filename `audit_2026-05-04_full.md` distinguishes this audit
from the same-date diagnostic note `audit_2026-05-04.md`
(LL-020 negative-result phase from 0.0.26.5).

**Result: PASS across A1–A6 immediately. A0 found CLAUDE.md
drift; fixed in this commit. Final state PASS across all six
checks.**

---

## §1 — A0 self-audit

**Check.** Every claim that `CLAUDE.md` makes about how the
project operates matches observable practice.

**Method.** Read CLAUDE.md §Status, §Ground truth hierarchy,
§Evidence types, §Workflow rules, §Benchmarking discipline,
§Companion doc standard, §Cross-audit protocol, §Key principles,
§What not to do. Cross-check each operational claim against the
actual project state at 0.0.34.

**Findings before this commit.**

- **§Status section is materially stale.** Claims:
  - Date "2026-05-03" → should be "2026-05-04".
  - "Spec ledger now (21 entries, post-0.0.20)" → 23 entries
    post-0.0.34.
  - `:tested` × 3 listed as "LL-003 baseline; LL-004 sensor
    coupling; LL-007 chaos-guard" → should be "LL-002 visual ↔
    security decoupling; LL-004 sensor coupling; LL-007
    chaos-guard" (LL-003 promoted to :benchmarked at 0.0.25;
    LL-002 promoted to :tested at 0.0.33).
  - `:benchmarked` × 3 → should be × 4 (LL-003 added at
    0.0.25).
  - `:argued` × 14 → should be × 15 (LL-022 added 0.0.26;
    LL-002 left for :tested at 0.0.33; LL-023 added 0.0.34
    — net +1).
  - Trajectory description ends at 0.0.20 closure pass; missing
    14 versions (0.0.21 - 0.0.34).

- **§Benchmarking discipline section** (added 0.0.27 + 0.0.29):
  observable practice matches. Determinism rule + multi-level
  determinism rule are followed across LL-020 Strategy 2,
  LL-021 high-res, LL-019 high-res, LL-003 N-scaling, LL-006
  per-SDE benchmarks. ✓ no drift.

- **§Companion doc standard**: observable practice matches.
  Every substantive session 0.0.26 → 0.0.34 produced a
  companion doc per the standard (`docs/*_companion.md`
  pattern). ✓ no drift.

- **§Cross-audit protocol**: observable practice matches the
  protocol; this audit itself follows it. ✓ no drift.

- **§Key principles + §What not to do**: spot-checks against
  the work landed since 0.0.20 — none of the "what not to do"
  rules were violated; the key principles (substrate-coupling,
  resolution-bounded tier, decoupling, etc.) were preserved
  across all changes. ✓ no drift.

**Findings after this commit.** §Status section refreshed:

- Date "2026-05-04".
- Trajectory description extends through 0.0.26 - 0.0.34 with
  one-line summaries per version.
- Spec ledger shows correct counts (23 / 0 / 3 / 0 / 4 / 15 /
  1) and correct memberships per status.
- Note about test suite (184/184 in ~51 s) added.
- Note about all round-3-trigger queue items closed (except
  LL-005 part-(a) adversary-side sub-claim per 0.0.24
  negative finding).

**A0 verdict: drift fixed in this commit. PASS.**

---

## §2 — A1 coverage

**Check.** Every spec LL-ID has a registry row.

**Method.** Count `^### LL-` in `LAVALAMP_SPEC.md`; count
`^| LL-[0-9]` in `artifact_registry.md`; verify equal. Spot-
check a few LL-IDs to ensure pairwise correspondence.

**Result.** 23 spec entries; 23 registry rows. Pairwise
correspondence verified for LL-001 through LL-023.

**A1 verdict: PASS.**

---

## §3 — A2 logic & status parity

**Check.** Spec keys ↔ registry keys are identical (or
unambiguously compressed per CLAUDE.md). Logic tier and Status
fields match.

**Method.** Compare each spec entry's `### LL-NNN — title-slug`
+ `- Logic tier: ...` + `- Status: ...` against the registry
row's Key / Logic tier / Status columns. Compression is allowed
on Key per CLAUDE.md A2; S-ID is the canonical link.

**Result.** All 23 entries match. The registry uses spaced
forms of the spec's hyphenated title-slugs (e.g., spec
`substrate-bound-identity-primitive` → registry
`substrate-bound identity primitive`); some registry rows add
parenthetical clarifications (e.g., LL-014 spec
`adversary-signature-threshold-calibration` → registry
`adversary-signature threshold calibration`; LL-018 spec
`adversary-resolution-bound-formalisation` → registry
`adversary-resolution-bound formalisation (per-class A1..A6)`).
All compressions are unambiguous per the CLAUDE.md A2 rule
("a reader should be able to see at a glance that registry Key
and spec Key are restating the same claim"). ✓

Logic tiers match spec → registry across all 23 entries.
Status fields match across all 23 entries (3 :tested, 4
:benchmarked, 15 :argued, 1 :open).

**A2 verdict: PASS.**

---

## §4 — A3 evidence file existence

**Check.** Every Test/Proof and Source file in the registry
exists in `git ls-files`.

**Method.** Extract all file-path references from the registry
(via grep on path patterns: `src/julia/.../*.{jl,txt}`,
`docs/*.md`, `visual/*`); verify each exists on disk.

**Result.**

- **22 src/julia/ files cited** — all exist. Includes
  `src/julia/test/runtests.jl`; `src/julia/src/{Audit,
  ChaosGuard, Engine, Sensors}.jl`; 7 benchmark scripts
  (p3_bound_high_res, p3d_sde_selection, p3e_n_scaling,
  p3f_per_sde_detection_power, p_r2c_structured_adversary,
  p_r2c_structured_adversary_high_res,
  ll019_timing_distribution_high_res); 9 result files (p3b
  through p3f, p_r2c, p_r2c high-res, ll019, ll019 high-res,
  ll020 Strategy 2).

- **17 docs/ companions cited** — all exist. Spans
  `architecture_design_companion`, `spec_closure_pass`,
  `p3_bound`, `p3d_sde_selection`, `p3e_n_scaling`,
  `p3f_per_sde_detection_power`, `ll019_benchmarked`,
  `ll019_high_res`, `ll020_strategy_2_epsilon_dp`,
  `ll020_strategy_2_benchmarked`, `ll021_benchmarked`,
  `ll021_high_res`, `ll005_part_a`, `audit_2026-05-04`,
  `os_identity_security_scoping`, `pharos_scoping`,
  `p_r2b_calibration_confidentiality`.

- **4 visual/ files cited** — all exist
  (`visual/{README.md, lavalamp.js, index.html, style.css}`).

**A3 verdict: PASS.**

---

## §5 — A4 status honesty

**Check.** No entry has a status its evidence type cannot
support per CLAUDE.md §Evidence types.

**Method.** Verify per-status-class:

- `:proved` (0 entries): N/A.
- `:verified` (0 entries): N/A.
- `:tested` (3 entries): all should have `example-tested`.
- `:benchmarked` (4 entries): all should have `benchmarked`.
- `:argued` (15 entries): all should have `manual`.
- `:open` (1 entry): should have `none`.

**Result.**

- LL-002: example-tested → :tested ✓ (added 0.0.33 — visual
  decoupling testset)
- LL-004: example-tested → :tested ✓
- LL-007: example-tested → :tested ✓
- LL-003: benchmarked → :benchmarked ✓
- LL-006: benchmarked → :benchmarked ✓
- LL-019: benchmarked → :benchmarked ✓ (high-res refresh
  produced regime-boundary finding but did not change status —
  LL-019 stays at the 0.0.19 :benchmarked-tier evidence)
- LL-021: benchmarked → :benchmarked ✓
- LL-001, LL-005, LL-008, LL-009, LL-010, LL-011, LL-012,
  LL-013, LL-014, LL-016, LL-017, LL-018, LL-020, LL-022,
  LL-023: all manual → :argued ✓
- LL-015: none → :open ✓

**Honest framing of the conjunctive-claim cases:**

- LL-005 has the LL-005 part-(a) parameter-validation test
  (example-tested for the parameter sub-claim only). Entry-
  level status correctly stays `:argued` because the
  adversary-detection sub-claim is open per 0.0.24 P3-Nyq
  negative. A `:tested` upgrade would require both sub-claims
  to have direct evidence. The conjunctive-claim discipline
  (sub-claim ≠ entry-level upgrade) is documented in the
  spec footer, the companion (`docs/ll005_part_a_companion.md`),
  and a feedback memory
  (`feedback_conjunctive_claim_evidence.md`). ✓

- LL-020 has Strategy 2 :benchmarked-tier evidence (component-
  level) but entry-level stays `:argued` because the multi-
  strategy approach is the entry-level claim and only Strategy
  2 has been exercised. Same conjunctive-claim discipline. ✓

**A4 verdict: PASS.**

---

## §6 — A5 stale counts

**Check.** Counts cited in dashboard, registry, README, and
CLAUDE.md match the spec.

**Method.** Read count summaries from each of the four
documents; verify pairwise equality.

**Result.**

| Source | Total | proved | tested | verified | benchmarked | argued | open |
|---|---:|---:|---:|---:|---:|---:|---:|
| LAVALAMP_SPEC.md | 23 | 0 | 3 | 0 | 4 | 15 | 1 |
| artifact_registry.md | 23 | 0 | 3 | 0 | 4 | 15 | 1 |
| dashboard.md | 23 | 0 | 3 | 0 | 4 | 15 | 1 |
| README.md | 23 | 0 | 3 | 0 | 4 | 15 | 1 |
| CLAUDE.md | 23 | 0 | 3 | 0 | 4 | 15 | 1 |

After CLAUDE.md fix in this commit, all five sources match.

**A5 verdict: PASS (post-fix).**

---

## §7 — A6 test sync

**Check.** Every spec entry with a Test/Proof file is exercised
by a test that runs in CI.

**Method.** Identify entries with cited test files; verify each
is in `src/julia/test/runtests.jl`; verify `runtests.jl` is
exercised by `.github/workflows/test.yml`.

**Result.**

Entries with test/proof citations in the registry:

- LL-002 — `src/julia/test/runtests.jl` (Visual layer
  decoupling testset; 45 assertions; 0.0.33). ✓
- LL-003 — `src/julia/test/runtests.jl` (Lorenz-96 baseline
  testsets) + `p3d_sde_selection` benchmark + `p3e_n_scaling`
  benchmark. ✓
- LL-004 — `src/julia/test/runtests.jl` (Sensor stream
  primitives + LL-004 testsets). ✓
- LL-005 — `src/julia/test/runtests.jl` (Nyquist compliance
  predicate testset; 16 assertions; 0.0.32 — part-(a) only). ✓
- LL-006 — `src/julia/test/runtests.jl` (Audit module
  testsets) + `p3_bound_high_res` benchmark + `p3f_per_sde`
  benchmark. ✓
- LL-007 — `src/julia/test/runtests.jl` (ChaosGuard
  testsets). ✓
- LL-019 — `src/julia/test/runtests.jl` (verify_full +
  verify_constant_time testsets) + `ll019_timing_distribution`
  benchmark + `ll019_timing_distribution_high_res` benchmark. ✓
- LL-020 — `src/julia/test/runtests.jl`
  (`differentially_private_envelope` testset; 23 + 6 new
  assertions for variance-convolution σ; 0.0.27) +
  `ll020_strategy_2_detection_power` benchmark. ✓
- LL-021 — `p_r2c_structured_adversary` benchmark +
  `p_r2c_structured_adversary_high_res` benchmark (no
  runtests.jl entry — benchmark-only evidence). ✓

CI workflow `.github/workflows/test.yml` runs `Pkg.test()` on
push to master + on PRs (Julia 1.12, ubuntu-latest, 20-min
timeout). Suite passes 184/184 in ~51 s.

**A6 verdict: PASS.**

---

## §8 — Summary

| Check | Result |
|---|---|
| A0 self-audit | PASS (post-fix; CLAUDE.md §Status refreshed) |
| A1 coverage | PASS |
| A2 logic & status parity | PASS |
| A3 evidence exists | PASS |
| A4 status honesty | PASS |
| A5 stale counts | PASS (post-fix) |
| A6 test sync | PASS |

**One drift item found and fixed**: CLAUDE.md §Status section
was 14 versions stale (frozen at 0.0.20 / 21 entries; current
state is 0.0.34 / 23 entries). Fixed in this commit.

The pre-round-3 cross-audit is clean. The prototype's spec /
registry / dashboard / README / CLAUDE.md are all in sync at
0.0.34. Round-3 (gated on `closure_forces_structure` paper
update) can proceed without state-drift hazards.

---

## §9 — Round-3 readiness

This audit also confirms round-3 readiness:

- Spec is internally consistent at 23 entries.
- All round-3-trigger memory queue items closed except the
  LL-005 part-(a) adversary-side sub-claim (deferred per the
  0.0.24 P3-Nyq negative finding; round-3 architectural input).
- Round-3 architectural inputs accumulated this session are
  documented in `~/.claude/projects/.../memory/project_lavalamp_round3_trigger.md`:
  1. LL-005 negative finding (P3-Nyq).
  2. LL-022 OS-trust-stack-dependency added (P-OS).
  3. LL-019 host-isolation regime-boundary (high-res KS).
  4. LL-003 deployment-design rule (N-scaling).
  5. LL-006 two-axis architectural argument (per-SDE).
  6. **(new this audit)** LL-023 consumer-API-surface added
     (P-PharOS); pairs with LL-022 to close trust-stack
     scoping on both ends.
  7. **(new this audit)** LL-002 visual decoupling testable
     on every commit (visual layer + decoupling-assertion
     testset).

When the `closure_forces_structure` paper update lands,
round-3's brief composition incorporates these inputs alongside
whatever the paper revises (C-conjugate / Q₅₁-tier / 0/5202
territory). The prototype side is ready.
