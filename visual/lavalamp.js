/*
 * LavaLamp decorative visual — bubble simulator.
 *
 * Decoupled from the security primitive per LL-002 (load-bearing
 * architectural invariant). Uses Math.random() exclusively; does
 * NOT consume entropy from the security primitive's RNG, the
 * Lyapunov-spectrum residue audit, the chaos-guard, or any other
 * `src/julia/src/` module.
 *
 * If the visual ever needs to derive from the security primitive
 * (it should not), the basin-spoofing attack surface flagged in
 * round-1 synthesis-team review (V-002) returns. See the
 * top-level README "Architectural separation" section.
 *
 * Convention: all randomness via Math.random(). No imports, no
 * modules, no shared globals with the security primitive.
 */

(function () {
  'use strict';

  const canvas = document.getElementById('lamp-canvas');
  const ctx = canvas.getContext('2d');
  const W = canvas.width;
  const H = canvas.height;

  // Bubble palette — warm hues; decorative choice, no security
  // significance.
  const palette = [
    'rgba(255, 80, 60, 0.85)',
    'rgba(255, 120, 40, 0.85)',
    'rgba(220, 60, 80, 0.85)',
    'rgba(200, 50, 50, 0.85)',
  ];

  // Bubble parameters.
  const N_BUBBLES = 7;
  const bubbles = [];

  function makeBubble() {
    return {
      x: Math.random() * W,
      y: H + Math.random() * H * 0.5,
      r: 18 + Math.random() * 28,
      vy: -(0.3 + Math.random() * 0.6),
      vx: (Math.random() - 0.5) * 0.15,
      hueIdx: Math.floor(Math.random() * palette.length),
      wobblePhase: Math.random() * Math.PI * 2,
      wobbleAmp: 0.2 + Math.random() * 0.5,
    };
  }

  for (let i = 0; i < N_BUBBLES; i++) {
    bubbles.push(makeBubble());
  }

  function step(t) {
    // Background gradient.
    const grad = ctx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, '#1a0a14');
    grad.addColorStop(0.5, '#2a141e');
    grad.addColorStop(1, '#0c0608');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Update + draw each bubble.
    for (let i = 0; i < bubbles.length; i++) {
      const b = bubbles[i];

      // Vertical drift with slight wobble (no SDE — pure
      // Math.random() + sin curve).
      b.y += b.vy;
      b.x += b.vx + Math.sin(t * 0.001 + b.wobblePhase) * b.wobbleAmp * 0.3;

      // Horizontal bounce off edges (purely decorative).
      if (b.x < b.r || b.x > W - b.r) {
        b.vx = -b.vx;
      }

      // Reset when bubble exits top.
      if (b.y < -b.r * 2) {
        Object.assign(b, makeBubble());
        b.y = H + b.r;
      }

      // Soft glow — radial gradient per bubble.
      const bg = ctx.createRadialGradient(b.x, b.y, 0, b.x, b.y, b.r);
      bg.addColorStop(0, palette[b.hueIdx]);
      bg.addColorStop(0.6, palette[b.hueIdx].replace('0.85', '0.4'));
      bg.addColorStop(1, 'rgba(0, 0, 0, 0)');

      ctx.fillStyle = bg;
      ctx.beginPath();
      ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2);
      ctx.fill();
    }

    requestAnimationFrame(step);
  }

  requestAnimationFrame(step);
})();
