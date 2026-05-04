/-
  LavaLamp — Lean 4 formal-verification root module.

  This is the scaffold-tier root; `Theorems.lean` is its only
  current import. When round-3 lands and proof work begins, the
  Theorems module will split into per-priority files
  (`LavaLamp.LL006DetectionBound`, `LavaLamp.LL019TimingIndistinguishability`,
  `LavaLamp.LL020CalibrationDP`, `LavaLamp.LL021WorstCaseBound`,
  `LavaLamp.LL022OSStackDependency`, `LavaLamp.LL023ConsumerAPI`)
  and this root will collect them.

  Per LavaLamp's CLAUDE.md §Lean 4 priority list (post-0.0.36
  refresh):

      Round-2 §1D.v Lean priorities target:
        - linear-coupling worst-case bound (LL-021)
        - side-channel timing indistinguishability (LL-019)
        - calibration ε-DP (LL-020)
        - the original §2.1 detection-probability bound for
          LL-006 / LL-008 / LL-018

      Plus the LL-022 / LL-023 theorem-shape implications added
      by the 0.0.26 P-OS and 0.0.34 P-PharOS scoping passes.

  Conventions in force (from CLAUDE.md §Honest framing):
    - `:proved` requires `lean-proved`, `type-checked`, or
      `algebraic` evidence. The scaffold itself produces no
      `:proved` evidence — `sorry`-stubs are not proofs.
    - When a theorem is genuinely proved (no `sorry`, package
      builds clean), the corresponding LL entry's evidence type
      moves to `lean-proved` and status to `:proved`.
    - Until then, `:argued` / `:tested` / `:benchmarked` are the
      honest statuses for the corresponding entries.
-/

import LavaLamp.Theorems

/-- Smoke definition — confirms the package builds. Removed
    when actual proofs land. -/
def hello : String := "LavaLamp Lean 4 scaffold; round-3 trigger pending"
