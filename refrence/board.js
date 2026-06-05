/* ============================================================
   MERIDIAN — board engine
   Tic-tac-toe on an N x N grid. Marks (X / O) sit INSIDE cells.
   Scoring counts maximal runs of 3+ same marks in all 4
   directions; a player's score is the sum of those run lengths.
   Pure, flat SVG — no stones, no vignette.
   ============================================================ */
(function (global) {
  "use strict";

  const EMPTY = 0, X = 1, O = 2;
  const DIRS = [[1, 0], [0, 1], [1, 1], [1, -1]];

  function mulberry32(seed) {
    let a = seed >>> 0;
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // Generate a plausible position. fill = fraction of cells filled.
  // bias gently clusters marks so runs naturally appear.
  function generate(size, fill, seed) {
    const rnd = mulberry32(seed || 1);
    const g = Array.from({ length: size }, () => new Array(size).fill(EMPTY));
    const target = Math.floor(size * size * fill);
    let placed = 0, turn = X, guard = 0;
    while (placed < target && guard < size * size * 40) {
      guard++;
      const cx = Math.floor(rnd() * size);
      const cy = Math.floor(rnd() * size);
      if (g[cy][cx] !== EMPTY) continue;
      let same = 0, other = 0;
      for (const [dx, dy] of [[1,0],[-1,0],[0,1],[0,-1],[1,1],[-1,-1],[1,-1],[-1,1]]) {
        const nx = cx + dx, ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= size || ny >= size) continue;
        if (g[ny][nx] === turn) same++; else if (g[ny][nx] !== EMPTY) other++;
      }
      const p = 0.5 + 0.16 * same - 0.10 * other;
      g[cy][cx] = rnd() < p ? turn : (turn === X ? O : X);
      placed++;
      turn = turn === X ? O : X;
    }
    return g;
  }

  // Find all maximal runs (length >= 3) for both marks.
  function score(g) {
    const size = g.length;
    const out = {
      1: { total: 0, runs: [], counts: { 3: 0, 4: 0, 5: 0 } },
      2: { total: 0, runs: [], counts: { 3: 0, 4: 0, 5: 0 } }
    };
    for (const [dx, dy] of DIRS) {
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          const c = g[y][x];
          if (c === EMPTY) continue;
          const px = x - dx, py = y - dy;
          const prevSame = px >= 0 && py >= 0 && px < size && py < size && g[py][px] === c;
          if (prevSame) continue; // not the start of a run
          const cells = [[x, y]];
          let nx = x + dx, ny = y + dy;
          while (nx >= 0 && ny >= 0 && nx < size && ny < size && g[ny][nx] === c) {
            cells.push([nx, ny]); nx += dx; ny += dy;
          }
          if (cells.length >= 3) {
            const rec = out[c];
            rec.runs.push({ cells, len: cells.length });
            rec.total += cells.length;
            rec.counts[Math.min(cells.length, 5)]++;
          }
        }
      }
    }
    return out;
  }

  // Build an SVG board string.
  // opts: { size, grid (2d), last:[x,y], thinking:[x,y], runs:[{cells,color}] }
  function render(opts) {
    const size = opts.size;
    const g = opts.grid;
    const VB = 1000;
    const pad = Math.max(18, 60 / size + 14);
    const cell = (VB - 2 * pad) / size;
    const C = i => +(pad + (i + 0.5) * cell).toFixed(2);   // cell centre
    const E = i => +(pad + i * cell).toFixed(2);            // cell edge
    const rg = cell * 0.30;                                  // glyph radius
    const sw = +(Math.max(cell * 0.11, 3)).toFixed(2);       // glyph stroke

    let s = `<svg class="rs-board-svg" viewBox="0 0 ${VB} ${VB}" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">`;

    // last-move cell highlight (under marks)
    if (opts.last) {
      const lx = E(opts.last[0]) + cell * 0.06, ly = E(opts.last[1]) + cell * 0.06;
      const w = cell * 0.88;
      s += `<rect class="cell-last" x="${lx.toFixed(2)}" y="${ly.toFixed(2)}" width="${w.toFixed(2)}" height="${w.toFixed(2)}" rx="${(cell*0.16).toFixed(2)}"/>`;
    }

    // interior grid lines (tic-tac-toe hash — no outer frame)
    s += `<g class="g-lines">`;
    for (let i = 1; i < size; i++) {
      s += `<line class="g-line" x1="${E(i)}" y1="${E(0)}" x2="${E(i)}" y2="${E(size)}"/>`;
      s += `<line class="g-line" x1="${E(0)}" y1="${E(i)}" x2="${E(size)}" y2="${E(i)}"/>`;
    }
    s += `</g>`;

    // run highlight bands (under marks)
    if (opts.runs && opts.runs.length) {
      s += `<g class="g-runs">`;
      for (const run of opts.runs) {
        const a = run.cells[0], b = run.cells[run.cells.length - 1];
        const cls = run.color === O ? "run-white" : "run-black";
        s += `<line class="run-band ${cls}" x1="${C(a[0])}" y1="${C(a[1])}" x2="${C(b[0])}" y2="${C(b[1])}" stroke-width="${(rg*1.7).toFixed(2)}"/>`;
      }
      s += `</g>`;
    }

    // AI thinking pulse (empty cell)
    if (opts.thinking) {
      const tx = E(opts.thinking[0]) + cell * 0.18, ty = E(opts.thinking[1]) + cell * 0.18;
      const w = cell * 0.64;
      s += `<rect class="think-pulse" x="${tx.toFixed(2)}" y="${ty.toFixed(2)}" width="${w.toFixed(2)}" height="${w.toFixed(2)}" rx="${(cell*0.14).toFixed(2)}"/>`;
    }

    // marks
    if (g) {
      s += `<g class="g-marks">`;
      for (let y = 0; y < size; y++) {
        for (let x = 0; x < size; x++) {
          const c = g[y][x];
          if (c === EMPTY) continue;
          const cx = C(x), cy = C(y);
          if (c === X) {
            const a = (cx - rg).toFixed(2), b = (cx + rg).toFixed(2);
            const u = (cy - rg).toFixed(2), d = (cy + rg).toFixed(2);
            s += `<g class="mark mark-x"><line x1="${a}" y1="${u}" x2="${b}" y2="${d}" stroke-width="${sw}"/><line x1="${b}" y1="${u}" x2="${a}" y2="${d}" stroke-width="${sw}"/></g>`;
          } else {
            s += `<g class="mark mark-o"><circle cx="${cx}" cy="${cy}" r="${rg.toFixed(2)}" stroke-width="${sw}"/></g>`;
          }
        }
      }
      s += `</g>`;
    }

    s += `</svg>`;
    return s;
  }

  // Back-compat aliases (board values: 1 = X, 2 = O)
  global.Runstone = { EMPTY, BLACK: X, WHITE: O, X, O, generate, score, render };
  global.Meridian = global.Runstone;
})(window);
