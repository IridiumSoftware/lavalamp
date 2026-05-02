# Language Plan — Catlab Tier Insertion (Companion)

Captures the methodology refinement landed in the 2026-05-01
session: insertion of Catlab.jl / GATlab as a fifth tier in the
formal stack, between numerical verification and Haskell
compositional completeness.

---

## §1 — Computational basis

No scripts. Methodology refinement.

**Sources consulted:**

- LavaLamp `CLAUDE.md` — the "Language tiers and phase discipline"
  section as set in 0.0.2 (Julia / Haskell / Lean / C-C++).
- Closure v5 `BUSINESS/CLAUDE.md` — the "Language tooling" section
  documenting the Julia-vs-Python distinction by *arithmetic
  type*, not by language: a Julia `Float64` computation is
  `:computational`; a Julia `Rational{BigInt}` computation is
  `:algebraic`. The proof is in the arithmetic type.
- Closure v5 `BUSINESS/dashboard.md` — current state of 145
  `:proved` entries, 9 of which carry evidence type `:catlab`
  (categorical machine proofs via CatLab.jl).
- Closure v5 changelog through v158 — confirms `:catlab` is an
  active, audited evidence type with `:proved` status, used
  e.g. for S25 (adhesivity), Q₂₄ vertex-count and orbit-closure
  verification.
- Triadic-coordination-engine `src/lean4/TriadicTheorems.lean` —
  S-029 closure-equation proof landed via project-local
  `Category` typeclass, no Catlab precedent in that project; in
  retrospect Catlab would have been a useful pre-Lean step for
  the closure equation `R_γα ∘ R_βγ ∘ R_αβ = id_τα`.

---

## §2 — Results

The 0.0.2 language plan articulated four formal-stack tiers:
explore (Python / Julia) → verify-or-obstruct (Julia) → prove
(compositional) (Haskell) → prove (formal) (Lean 4) → harden
(C / C++).

This refinement inserts **Catlab.jl / GATlab** as a fifth tier
between verify-or-obstruct (numerical) and prove (compositional).
Full revised stack:

1. Explore (Python, maybe Julia)
2. Verify / obstruct (Julia: `DiffEq.jl`, `DynamicalSystems.jl`,
   `ChaosTools.jl`)
3. **Categorical realise (Julia + Catlab.jl / GATlab) — new tier**
4. Prove (compositional) (Haskell: types as spec + QuickCheck)
5. Prove (formal) (Lean 4)
6. Harden (C / C++, rewriting from the proven spec)

### 2.1 Why Catlab earns a tier

Catlab is *computational* category theory. It uses Julia's
multiple-dispatch + algebraic-theory framework (GATlab) to make
categorical constructions concrete and executable. You can:

- Define objects, morphisms, functors, natural transformations.
- Ask "does this diagram commute?" — compute both paths over
  exact types, check equality.
- Verify functoriality, naturality, adjunction triangle
  identities on concrete instances.
- Build coproducts, pushouts, and other limits / colimits and
  check universal properties.
- Run DPO rewriting (the framework Closure v5 uses for ternary
  causal hypergraph dynamics).

Over exact types (`Rational{BigInt}`, exact algebraic
representations) the output is *algebraic evidence* in the corpus
sense — a deductive computation producing a proof, not a numerical
approximation.

This is not theoretical. The Closure v5 corpus has 9 of 145
`:proved` scorecard entries carrying evidence type `:catlab`
(e.g. S25 adhesivity verification, finite-object cardinality
checks, DPO pushout-complement existence). The evidence-type
taxonomy treats `:catlab` as proved-tier alongside `:lean-proved`,
`:type-checked`, and `:algebraic`. Audit rule A4 ("status
honesty") admits `:catlab` for `:proved`. So the precedent is
established and audited.

### 2.2 Three distinct jobs in the formal stack

The Catlab insertion makes a previously-collapsed distinction
explicit. The formal stack does *three* different jobs:

| Tier | Risk reduced | What it answers |
|---|---|---|
| **Catlab** | Computational (categorical) | Does the categorical structure actually close? Do the diagrams commute on instances? |
| **Haskell** | Compositional | Did the spec imply a corollary / universal we missed? |
| **Lean** | Formal | Is the theorem actually *true* in dependent type theory? |

Collapsing any of these three into the others loses load-bearing
content:

- **Catlab → Haskell:** loses the ability to compute *with*
  categorical objects. Haskell can express categorical structure
  as types (and there's a long tradition of doing so), but
  doesn't iterate as fast on concrete instances. The Closure v5
  decision to use Catlab over Haskell for categorical proofs was
  made on this productivity basis.
- **Haskell → Lean:** loses universal-coverage testing. Lean
  theorems are statements about objects; QuickCheck enumerates
  the *space* the statement ranges over and falsifies on
  inputs the human author would not have considered. A theorem
  with a wrong premise is a wasted proof; QuickCheck against a
  type-encoded spec catches premise errors before Lean does.
- **Catlab → Lean:** skips the productivity gradient. Catlab
  iterates faster than Lean for "does the model close at all"
  questions. Once it closes, Lean formalises. Going Catlab → Lean
  directly is a valid path; going Lean-first is just slower.

### 2.3 Why the productivity ordering matters

A reasonable observation in the session: Julia + Catlab is *easier
to map* than Haskell or Lean for category-theory work. Multiple-
dispatch + concrete computation iterates faster than Haskell
typeclass plumbing or Lean tactic mode. The benefit of putting
Catlab first:

- By the time you reach Haskell, you already know the morphisms
  compose — you're encoding a known-good structure as types, not
  discovering whether it works.
- By the time you reach Lean, you already know the theorem
  statement is right — you're proving a verified-in-Catlab fact
  formally, not wrestling with a misstatement under a tactic
  prompt.

This is the same productivity argument as "explore in Python
before committing to Julia exact types": the cheaper iteration
buys correctness gradient before the more expensive tier sees the
work.

### 2.4 When Catlab earns its keep on a project

Catlab is *optional* per project. Decision rule:

- **Skip Catlab** if the architecture's categorical content is
  shallow — e.g., a numerical SDE solver with sensor coupling and
  no functor / commutative-diagram structure. The Julia tier's
  iteration speed already covers verification.
- **Use Catlab** if the architecture has non-trivial categorical
  content — functors between non-trivial categories, natural
  transformations, universal constructions, adhesive-category
  rewriting (DPO), spectral-triple structure, multicategory
  composition. The Closure v5 corpus is the canonical example;
  the triadic-coordination-engine's closure equation
  `R_γα ∘ R_βγ ∘ R_αβ = id_τα` is a smaller but real example.

### 2.5 LavaLamp-specific applicability

LavaLamp's **security primitive** (chaotic SDE + sensor coupling +
Lyapunov-spectrum residue audit) is dynamical-systems and
real-analysis. There are no obvious commutative diagrams to verify,
no functorial constructions, no universal properties to check.
Catlab probably under-pulls its weight there — the Julia tier
already covers numerical verification efficiently.

LavaLamp's **verification protocol** (LL-011 registration ceremony,
LL-013 cross-config transitions, LL-012 cold-start window state,
LL-017 no-oracle response design) does have categorical content —
it's morphisms in a category of device-states with admissible
transitions. If the P2 architectural design pass surfaces enough
of that structure to warrant computational verification, Catlab
fits there.

**Default for LavaLamp:** skip Catlab unless P2 designs surface
categorical structure that warrants it. Revisit at the
registration / cross-config transition design step. The
dashboard's priority stack reflects this: Catlab is its own
priority slot (P4) gated on P2.

---

## §3 — Verification

This section is methodology, not a security or architectural
claim. It does not become a spec entry.

The argument that Catlab earns a tier slot rests on three
already-verified facts:

1. **Closure v5 `:catlab` evidence type is established and
   audited.** 9 entries currently carry `:catlab` evidence type
   with `:proved` status. Audit rule A4 admits this combination.
   The corpus's evidence-type taxonomy is the precedent.
2. **Three-jobs distinction is load-bearing.** Documented in §2.2
   above; demonstrated by the triadic-coordination-engine S-026
   catch (Haskell QuickCheck discovered a universal that example
   tests missed; this is different from "is this theorem true,"
   which is Lean's job; and different from "does this categorical
   structure close on instances," which is Catlab's job).
3. **Productivity gradient is empirical.** Catlab + Julia
   iteration speed is observably faster than Haskell + GHC or
   Lean + tactic mode for "does the model close at all" questions
   in the Closure v5 sessions. This is reported, not measured;
   the productivity argument is anchored in corpus practice, not
   benchmark numbers.

**Verification status:** manually argued (manual evidence type;
not lean-proved / type-checked / algebraic). This is a methodology
note, not a formal claim. It does not change the spec.

---

## §4 — Spec impact

**No new LL-IDs.** Methodology refinements do not add spec
entries. Spec entries are reserved for security-primitive claims,
architectural invariants, and formal constraints; none of those
changed.

**Files changed:**

- `CLAUDE.md` — "Language tiers and phase discipline" section
  revised. Catlab inserted between verify / obstruct and
  prove (compositional). The three-jobs distinction (Catlab /
  Haskell / Lean) made explicit. LavaLamp-specific priority
  list updated to mark Catlab as optional with a clear decision
  rule.
- `dashboard.md` — recent companion docs section updated;
  priority stack renumbered to add Catlab as P4 (gated on P2);
  Haskell / Lean / C-C++ / visual moved from P4–P7 to P5–P8.
- `changelog.md` — 0.0.4 entry at top.
