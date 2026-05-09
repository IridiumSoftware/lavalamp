# visual/ — Decorative-Only Lava-Lamp Animation

This directory contains the **marketing / landing-page asset**
for the LavaLamp project — a browser-canvas lava-lamp animation.
**Decoupled from the security primitive per LL-002**, the
load-bearing architectural invariant of the LavaLamp project.

> **Note on UX role.** As of v0.0.83, the daily-driver user-
> feedback surface is the **macOS menu bar app**
> (`../src/swift/lavalamp_menubar/`) — a small lavalamp icon
> that turns green when the LavaLamp daemon is running and
> faded when it isn't (see LL-039 in `LAVALAMP_SPEC.md`). This
> directory is positioned as marketing/landing material —
> embed it in the project homepage, screenshot it for the
> README, demo it to a non-technical audience. It does not
> give live status; the menu bar does that.

## What it is

- A pure HTML/JS canvas animation. Open `index.html` in any
  modern browser.
- Bubble simulator: 7 bubbles with random initial positions,
  velocities, sizes, hues; vertical drift with slight wobble;
  bounce off edges; reset on exit-top.
- ~80 lines of JavaScript. No build system, no dependencies, no
  module bundler. Drop-in, self-contained.

## What it isn't

- **Not derived from the security primitive.** The visual does
  *not* read the SDE trajectory, the Lyapunov spectrum, the
  chaos-guard's λ̂₁, or any other state from
  `../src/julia/src/`. Architecturally, the visual lives in a
  different language entirely (JS) and a different process
  (browser); there is no IPC, no shared memory, no shared file
  state.
- **Not security-grade.** All randomness is `Math.random()` —
  the JavaScript standard PRNG, not cryptographically secure.
  This is intentional and matches LL-002's framing: the visual
  is decorative; security comes from the primitive that runs
  independently (see `../src/julia/`).

## Why decoupling is load-bearing

Round-1 synthesis-team review (Gemini + Grok, 2026-04-30) flagged
the visual-richness ↔ security tension as a structural blindspot
in any design that fed the visual *from* the SDE. The decoupling
resolution: visual is decorative; security primitive runs
independently. **If those two layers ever get re-coupled, the
basin-spoofing attack surface (V-002 — multi-basin reaction-
diffusion regimes the visual layer would want to use) returns.**

See:
- `../README.md` "Architectural separation" section — invariant
  statement (LL-002) and the visual ↔ security decoupling
  rationale.

## Decoupling assertions

LL-002 was upgraded from `:argued` to `:tested` in 0.0.33 via
example-tested assertions in
`../src/julia/test/runtests.jl` (the `Visual layer decoupling
(LL-002)` testset). The tests verify:

- **`visual/` contains no references** to security-primitive
  identifiers (`Audit`, `lyapunov_spectrum`, `Envelope`,
  `ChaosGuard`, `synthetic_adversary`, `verify`, etc.).
- **`src/julia/src/` contains no references** to visual-layer
  identifiers (`requestAnimationFrame`, `canvas`, `lava-lamp
  animation`, etc.).
- **`Math.random()` is the visual's randomness source** (no
  imports of crypto-grade RNGs that might suggest security
  intent).

The assertions are *static* (text-search across files), which
is sufficient for the architectural-decoupling claim. Stronger
guarantees (Lean / type-level enforcement that the security-
primitive type-graph cannot reach the visual-layer type-graph)
remain deferred per the LL-002 spec footer.

## Decorative-choice notes

- 7 bubbles is a tasteful default; can be tuned in
  `lavalamp.js` (constant `N_BUBBLES`).
- Color palette is warm-hued (red / orange / pink) by
  convention; decorative choice with no security significance.
  Free to change.
- Wobble effect is `Math.sin(t·ω)·amplitude` — purely a visual
  flourish.
- Frame rate is browser-native via `requestAnimationFrame`. No
  fixed timestep.

## Future extensions

Per the dashboard's P8 priority, the visual layer can grow into:

- A 3D version (threejs) if 2D loses information.
- A Lazarus-shaped product UI wrapping the LavaLamp identity
  primitive.
- A PharOS-side login-screen accent (when PharOS lands).

Any extension must preserve the LL-002 decoupling — do not
import from `../src/julia/`, do not consume security-primitive
state, do not derive visual parameters from the residue audit
or chaos-guard. **Keep the visual decorative.**
