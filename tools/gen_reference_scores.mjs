// Generates golden scoring fixtures by running the REAL refrence/board.js (no fallback).
//
//   node tools/gen_reference_scores.mjs
//
// Output: tests/fixtures/reference_scores.json — a set of boards plus board.js's score()
// output, used by the GDScript scoring tests to prove the port is identical.
//
// board.js grids are indexed g[y][x] (row, then col) with values 0=EMPTY, 1=X, 2=O.
// board.js run cells are [x, y]; we convert them to [row, col] to match the Godot port.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

// board.js is a browser IIFE that assigns to a `window` global. Provide one, then eval
// the file in global scope so `globalThis.Meridian` becomes available.
globalThis.window = globalThis;
const src = readFileSync(path.join(root, "refrence", "board.js"), "utf8");
(0, eval)(src);

const M = globalThis.Meridian;
if (!M || typeof M.score !== "function" || typeof M.generate !== "function") {
  throw new Error("Failed to load Meridian from refrence/board.js");
}

const E = 0, X = 1, O = 2;

function serializeScore(s) {
  const conv = (rec) => ({
    total: rec.total,
    counts: { "3": rec.counts[3], "4": rec.counts[4], "5": rec.counts[5] },
    // board.js cells are [x, y]; emit [row, col].
    runs: rec.runs.map((r) => ({ len: r.len, cells: r.cells.map(([x, y]) => [y, x]) })),
  });
  return { X: conv(s[X]), O: conv(s[O]) };
}

const cases = [];
function addCase(name, grid) {
  cases.push({ name, size: grid.length, grid, score: serializeScore(M.score(grid)) });
}

function blank(n) {
  return Array.from({ length: n }, () => new Array(n).fill(E));
}

// ---- Hand-built edge cases (board.js is the oracle; we only assert our port matches) ----
addCase("empty_3", blank(3));
{ const g = blank(3); g[0] = [X, X, X]; addCase("x_row3_3", g); }
{ const g = blank(3); g[0] = [X, X, X]; g[1] = [O, O, O]; addCase("x_row3_o_row3_3", g); }
{ const g = blank(3); for (let i = 0; i < 3; i++) g[i][i] = X; addCase("x_diag_3", g); }
{ const g = blank(3); for (let i = 0; i < 3; i++) g[i][2 - i] = X; addCase("x_antidiag_3", g); }
{ const g = blank(4); g[0] = [X, X, X, X]; addCase("x_row4_4", g); }
{ const g = blank(5); g[0] = [X, X, X, X, X]; addCase("x_row5_5", g); }
{ const g = blank(7); g[0] = [X, X, X, X, X, X, E]; addCase("x_row6_7", g); }
{ const g = blank(7); g[0] = [X, X, X, E, X, X, X]; addCase("x_two_runs_7", g); }
{ const g = blank(6); g[0] = [X, X, X, O, X, X, ]; g[0].length = 6; addCase("x_broken_by_o_6", g); }
{ const g = blank(4); g[1][1] = X; addCase("single_mark_no_run_4", g); }
{ const g = blank(5); for (let r = 0; r < 5; r++) for (let c = 0; c < 5; c++) g[r][c] = X; addCase("all_x_5", g); }
{ const g = blank(5); for (let r = 0; r < 5; r++) for (let c = 0; c < 5; c++) g[r][c] = (r + c) % 2 === 0 ? X : O; addCase("checker_5", g); }
{ // runs hugging all four borders on a 9x9
  const g = blank(9);
  for (let c = 0; c < 9; c++) { g[0][c] = X; g[8][c] = O; }
  for (let r = 0; r < 9; r++) { g[r][0] = X; g[r][8] = O; }
  addCase("border_runs_9", g);
}

// ---- Reproducible generated boards across sizes & fill levels ----
const sizes = [3, 4, 5, 7, 9, 11, 13, 15, 19];
const fills = [0.5, 0.75, 1.0];
let seed = 1;
for (const size of sizes) {
  for (const fill of fills) {
    addCase(`gen_${size}_${Math.round(fill * 100)}_s${seed}`, M.generate(size, fill, seed));
    seed += 7;
  }
}

const out = {
  generator: "tools/gen_reference_scores.mjs",
  source: "refrence/board.js",
  generated: new Date().toISOString(),
  count: cases.length,
  cases,
};

const outDir = path.join(root, "tests", "fixtures");
mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, "reference_scores.json");
writeFileSync(outPath, JSON.stringify(out, null, 2));
console.log(`Wrote ${cases.length} cases -> ${path.relative(root, outPath)}`);
