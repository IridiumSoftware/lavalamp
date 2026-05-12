-- LL002Visual.lean — concrete Lean formalisation of LL-002
-- visual-security decoupling at the type-level surface.
--
-- LL-002 (LAVALAMP_SPEC.md) establishes that the user-facing
-- lava-lamp visual animation does NOT derive from the security-
-- critical SDE trajectory. The Julia static-lint at
-- `src/julia/test/runtests.jl` ("Visual layer decoupling
-- (LL-002)" testset, 45 assertions) verifies the operational
-- decoupling — no security-primitive identifiers leak into
-- `visual/`, no visual-layer identifiers leak into `src/julia/`,
-- and the visual layer uses `Math.random()` not crypto-grade RNG.
--
-- This file adds a LAYERED COMPANION at the Lean type level:
-- the visual surface's externally-observable output is a
-- 2-constructor inductive (`locked` / `unlocked`), with NO
-- third constructor that could carry distance, residue, or
-- timing information. The type-system makes "the visual returns
-- a Bool, never a distance" a compile-time guarantee — distinct
-- from (and stronger than) the static-text-search assertions in
-- runtests.jl.
--
-- This module is the canonical concrete formalisation of the
-- LL-002 Bool-only visual surface for cross-repo consumers:
--   - Lazarus's `TriadBackbone.lean` imports `VisualOutput`
--     via Lake git dep on `lavalamp-hermetic` and uses
--     `visual_one_bit_channel` as the LL-002 leg of its
--     `no_oracle_triad_backbone` cross-Triad composition theorem.
--   - LL-002's spec entry notes the Lean layered companion as
--     "option (b) Lean / type-level enforcement" of the
--     decoupling claim, previously deferred to P5/P6.
--
-- Honest framing. The Lean track formalises ONE aspect of
-- LL-002's claim — the type-cardinality of the visual output.
-- The broader decoupling claim (no security-primitive
-- identifiers reach the visual layer; visual cannot read from
-- SDE state) remains covered by the Julia static-lint, which is
-- the source of truth for LL-002's `:tested` status. The Lean
-- module is layered evidence, not a replacement.

namespace LavaLamp.LL002Visual

/-- The LavaLamp visual UI's externally-observable output.
    Two constructors — `locked` (security primitive denies) and
    `unlocked` (security primitive admits) — encode the entire
    user-facing surface. There is no third constructor that
    could carry distance, residue, timing, or any other
    side-channel information.

    The type signature is the load-bearing structural claim:
    a refactor that adds a distance-carrying constructor (e.g.
    `locked_at_distance d`) would change `VisualOutput`'s
    cardinality and fail to type-check at every existing use
    site. -/
inductive VisualOutput
  | locked
  | unlocked
  deriving DecidableEq, Repr

-- ── Theorem 1: every output is in the 2-element finite list ──

/-- The visual output's externally-observable surface is
    bounded by a 2-element finite enumeration. Used by cross-
    repo consumers (Lazarus's `TriadBackbone.lean`) as one leg
    of the joint No-Oracle Backbone composition.

    This is the type-level counterpart of LL-002's
    runtests.jl assertion "no security-primitive identifiers
    leak into the visual layer" — both rule out distance/residue
    information appearing on the visual surface, but at different
    abstraction levels. The Lean theorem is structural (any
    inhabitant of `VisualOutput` is one of these two values);
    the Julia static-lint is source-textual. -/
theorem visual_one_bit_channel (v : VisualOutput) :
    v ∈ ([VisualOutput.locked, VisualOutput.unlocked] : List VisualOutput) := by
  cases v <;> simp

-- ── Theorem 2: the surface has exactly 2 inhabitants ───────

/-- Cardinality witness: the canonical enumeration of all
    `VisualOutput` values has length 2. Stated separately to
    make the "ℝ can't fit here" framing explicit for downstream
    composition (ℝ is uncountable; 2 is countable). -/
theorem visual_output_cardinality :
    ([VisualOutput.locked, VisualOutput.unlocked] : List VisualOutput).length = 2 := by rfl

-- ── Theorem 3: no third inhabitant exists ─────────────────

/-- Exhaustivity. Every `VisualOutput` is either `locked` or
    `unlocked` — there is no third inductive case. Decidable by
    structural pattern matching. Together with `DecidableEq`
    (derived above), this rules out the "smuggle distance through
    a hidden constructor" attack class at the type level. -/
theorem visual_exhaustive (v : VisualOutput) :
    v = VisualOutput.locked ∨ v = VisualOutput.unlocked := by
  cases v
  · exact Or.inl rfl
  · exact Or.inr rfl

end LavaLamp.LL002Visual
