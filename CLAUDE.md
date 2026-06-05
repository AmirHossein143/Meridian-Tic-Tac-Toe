# Meridian — Project Guide (for Claude Code)

## What this is
Meridian is a polished, launch-ready tic-tac-toe game built in **Godot 4** with **GDScript**.
It is **not** classic win-on-3 tic-tac-toe: players fill an N×N board completely, and the
winner is whoever's marks form the most and longest lines. Targets: **Windows now, Android later.**

- Marks: **X** (player one) and **O** (player two), drawn inside grid cells.
- Board size: selectable, **3×3 up to 19×19** (presets + a custom stepper).
- Modes: **vs AI** (Easy / Medium / Hard) and **local 2-player** (pass-and-play).
- No early win — the board fills completely, then scores are tallied.

## Files to ignore
Claude should **not** read or reference:
- `README.md` — GitHub documentation only

## Source of truth
- **Game rules come from `PROTOTYPE.py`** (fill the board completely; no early win; 4 directions).
  **Scoring comes from `board.js`** — use the simpler, cleaner formula (see Scoring section below).
- **`reference/board.js` is the reference for both rendering AND scoring.** Use its `score()`
  function to confirm the scoring formula, and use its `render()` to match how the board, marks,
  grid lines, last-move highlight, run bands, and the "thinking" pulse are drawn.

## Scoring (canonical — match board.js exactly)
After the board is full, find every **maximal** run of 3+ identical marks in each of 4 directions
(horizontal, vertical, both diagonals). A run is maximal if the cell before it in that direction
is empty or a different mark. Each maximal run of length L contributes **L points** to its owner's
total (3-line → 3 pts, 4-line → 4 pts, 5-line → 5 pts, and so on). Higher total wins; equal = draw.
- This matches `board.js`'s `score()` function exactly. Pin GUT/GdUnit4 tests to values confirmed
  against board.js.
- PROTOTYPE.py uses a different double-counting formula — use it only to confirm the rules (fill
  the board, no early win, same 4 directions), not for scoring.

## Design system (in `reference/`)
- `tokens.css` — colors (light + dark + optional purple accent), type, radii, spacing. Translate
  into a Godot `Theme` + color constants.
- `game.css` — component styling (buttons, segmented control, switches, stepper, preset cards,
  scoreboard, turn pill, breakdown, device frames). Rebuild as Godot Control scenes/theme.
- `board.js` — board rendering reference (see above). Key specs: square board; **interior grid
  lines only** (no outer frame); X = two crossing strokes, O = a ring, both centered in cells;
  glyph radius ≈ 0.30 × cell pitch; glyph stroke ≈ max(0.11 × cell, 3); last-move cell highlight;
  run-band overlays at game over; animated "thinking" pulse on the AI's target cell.
- Fonts: **Sora** (display / wordmark / numbers), **Hanken Grotesk** (UI), **JetBrains Mono**
  (specs). All on Google Fonts — download and import as Godot fonts. Numbers use tabular figures.
- Colors map: **X = accent (jade; purple in the purple variant)**, **O = terracotta**, amber =
  last-move marker. Keep everything **flat-fill**.
- Branding in `assets/branding/`: `icon-final.svg`, `icon-final-flat.svg` (small sizes),
  `logo.svg`, `logo-mark.svg`.

## Hard rules
- The AI **must never block the main thread.** Run the search on a worker thread / WorkerThreadPool
  or chunk with `await`, with a per-move time budget and a visible "thinking" state.
- Game **rules + AI live in pure GDScript classes with NO UI / node dependencies**, so they're
  unit-testable headless. The UI reads from them; it never owns rules.
- Scoring is covered by tests pinned to PROTOTYPE.py reference values.
- Flat fills only (no heavy gradients) — matches the design and stays performant on mobile.

## Suggested layout
- `PROTOTYPE.py` — root, reference
- `reference/` — tokens.css, game.css, board.js, design notes
- `assets/` — `branding/`, `fonts/`, `sfx/`, `music/`
- `scripts/core/` — board model, rules, scoring (pure)
- `scripts/ai/` — search + evaluation (pure)
- `scripts/ui/` — scene scripts
- `scenes/` — MainMenu, GameSetup, Game, GameOver, Settings, Board
- `tests/` — GUT / GdUnit4
- `theme/` — theme.tres + fonts

## Conventions
- GDScript: typed where reasonable; `snake_case` files/vars; `PascalCase` classes/nodes; signals
  for cross-node comms; `@export` for tunables. Small, focused scripts.
- Persist settings to `user://`: last mode, difficulty, board size, theme, sound + music toggles.

## Verify
- Use the Godot CLI headless: import (`--headless --import`), run the test suite, and export
  (`--headless --export-release "Windows Desktop" <path>`). You can't see the rendered game — give
  me the command to run it and I'll check visuals and report back.