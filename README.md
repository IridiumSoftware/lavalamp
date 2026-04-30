# LavaLamp

A device-bound identity primitive. Concept-stage; private repo.

## What it is

A laptop continuously solves a hard but lightweight stochastic
differential equation locally. The trajectory is amplified by
hardware/configuration-state coupling (thermal jitter, CPU
governor, scheduler timing, sensor reads from USB / power-adapter /
battery / temperature sensors) into a substrate-unique signature.

**Identity = the sustained chaotic trajectory on the device.**
Verification = trajectory checkpoint comparison against a
registered hardware envelope, with adversary-signature detection
via Lyapunov-spectrum residue audit.

The project is structurally derived from the C-conjugate adversary
construction in *Possibilistic Security* (Green 2026), applied at
the entropy layer.

## What it isn't

- **Not QKD.** No quantum hardware. The unclonability claim is
  *computational*, resolution-bounded against adversary
  measurement capability — not information-theoretically secure
  via no-cloning theorem. Quantum no-cloning depends on
  quantum-mechanical linearity; a classical chaotic SDE is
  non-linear and the state is observable without collapse.
  Conflating the two tiers in pitches will trip careful
  reviewers.
- **Not a key-distribution protocol.** QKD distributes keys
  between two parties over an open channel. LavaLamp generates
  device-bound entropy locally; with a registration ceremony it
  supports device authentication.

## Architectural separation (load-bearing)

**Visual ↔ security decoupling.** The user-facing lava-lamp
animation is *decorative only* and runs on whatever RNG is
convenient. The security primitive (chaotic SDE + sensor coupling
+ Lyapunov-spectrum residue audit) runs as an independent
background process. Same shape as Lazarus: substance under the
hood; minimal/utilitarian UI on top.

If those two layers ever get re-coupled, the basin-spoofing
attack surface (multi-basin reaction-diffusion regimes the visual
layer would want to use) returns.

## Status

Concept-stage. No code yet. Architecture has been synthesized
through one round of synthesis-seat (Gemini) + edge-witness-seat
(Grok) review on 2026-04-30. Next deliverable is the attack-surface
enumeration document, then architectural design pass, then language
tracks (Haskell + Lean 4 mirroring the triadic-coordination-engine
pattern).

See:
- `LAVALAMP_SPEC.md` — authoritative claim ledger (14 entries, all
  `:open`)
- `dashboard.md` — current status + priority stack + open
  questions
- `CLAUDE.md` — project governance + scope boundaries
- `docs/` — per-session companion records

## Layout

```
lavalamp/
├── README.md                       ← you are here
├── LAVALAMP_SPEC.md                ← claim ledger
├── artifact_registry.md            ← spec-to-evidence map
├── dashboard.md                    ← status + priorities
├── changelog.md                    ← versioned entries
├── CLAUDE.md                       ← project governance
├── docs/                           ← per-session companion docs
│   ├── concept_origin_companion.md
│   └── synthesis_team_round1_companion.md
└── .gitignore

# src/ (haskell, lean4, etc.) created when code lands — pending P3
# in the dashboard's priority stack. Concept-stage repo; no code
# until attack-surface enumeration + architectural design pass
# complete.

```

## License

Triadic Closure License (TCL) v1.3. Canonical text and original
discussion in `github.com/IridiumSoftware/possibilistic-security`.

## Provenance

Visual seed credit: codetaur (SDE imagery resembling a lava lamp;
structural application unintended). Patent-offer extended as
good-faith credit for the seed.

Concept and security application: Aaron Green, derived from the
C-conjugate adversary structure introduced in *Possibilistic
Security*.

Discussion / framing engagement: Brian Crabtree (ORSIΩ-vocabulary
discussions).

Synthesis-team review: Gemini (synthesis seat) + Grok (edge-witness
seat), 2026-04-30.
