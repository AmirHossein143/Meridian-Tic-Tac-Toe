# Meridian — Menus, How-to-Play guide, Credits, Quit, and in-game theming

Phase 3 + 4 are committed (board rendering, theme/fonts, screens, components). This task is a UI/navigation
pass — no changes to the pure game/AI core, and the AI must stay off the main thread exactly as it is now.
Keep everything on the existing design system: build controls through `UIKit`, pull every colour from
`ThemeManager.color(...)`, use the project fonts, flat fills only, 44px minimum tap targets.

## Files you'll touch (and the APIs they expose)

- `scripts/ui/app.gd` — `MeridianApp`, the root scene + router. `MeridianApp.instance.goto(name, params)`;
  screens built in `_make()` (`"menu" | "setup" | "game" | "settings"`). On a `ThemeManager.changed` it
  **rebuilds the current screen** via `goto(_current_name, _current_params)` (see the gotcha below).
- `scripts/ui/main_menu.gd` — `MainMenu`. Currently just Play + Settings.
- `scripts/ui/game_setup.gd` — `GameSetup`. Header with `< Back`; mode/difficulty/board-size; `Start`.
- `scripts/ui/game_screen.gd` — `GameScreen`. Top bar (`Menu`, `Undo`, `Restart`), scoreboard, turn pill,
  `BoardView`, game-over overlay (`_show_game_over` is the modal pattern to copy).
- `scripts/ui/settings_screen.gd` — `SettingsScreen`. Sound/Music switches, Light/Dark `Segmented`, purple
  accent switch.
- `scripts/ui/theme_manager.gd` — autoload `ThemeManager`: `color(name)`, `is_dark()`,
  `set_theme_mode("light"|"dark")`, `set_accent("jade"|"purple")`, `theme_mode`, `accent`, fonts,
  `R_SM/R_MD/R_LG/R_PILL/TAP`, signal `changed`.
- `scripts/ui/settings_store.gd` — autoload `Settings`: `get_value(key, default)`, `set_value(key, value)`,
  persists to `user://meridian_settings.cfg`.
- `scripts/ui/ui_kit.gd` — `UIKit.button(text, kind, big)` (`kind`: `primary|ghost|soft|danger`),
  `UIKit.label(text, role, size, color_name)` (`role`: `ui|ui_semibold|display|display_bold|mono`),
  `UIKit.panel(bg, border, radius, pad)`.
- Components: `Segmented.configure(opts, idx)` + `selected(i)`; `ToggleSwitch.configure(on)` + `switched(on)`;
  `ScoreCard`, `MarkGlyph.configure(mark, size)`, `MiniBoard.configure(n, px)`.
- Board/scoring for the guide visuals: `Board.from_rows(rows)` (ints: `0` empty, `1` X, `2` O),
  `BoardView.set_board(b)` / `set_runs([{ "cells": Array[Vector2i], "owner": int }])`,
  `Scoring.score(board)` → `{ Marks.X: {total, runs:[{cells,len}], counts:{3,4,5}}, Marks.O: {...} }`,
  `Marks.X`, `Marks.O`.

---

## ⚠️ READ FIRST — the theme-change gotcha

`MeridianApp._on_theme_changed()` does `call_deferred("goto", _current_name, _current_params)`, which
**frees and rebuilds the whole current screen**. That's correct for stateless screens, but it has two
consequences you must handle, because this task adds an in-game theme toggle:

1. **A theme toggle while playing would wipe the game** — `goto("game", …)` re-runs `init_screen` →
   `_build()` + `_start_game()` → a brand-new `GameState`. The in-progress board would be lost.
2. **A theme toggle mid-setup would reset unsaved selections** — `GameSetup` reads mode/difficulty/size from
   `Settings`, but only writes them on `Start`, so a rebuild snaps back to last-saved values.

### Fix A — preserve the in-progress game across a rebuild (GameScreen)

`GameState` is a `RefCounted`, so it survives the node being freed as long as something still references it.
Use a static hand-off:

```gdscript
# game_screen.gd
static var _resume: GameState = null   # set just before a theme-driven rebuild
var _last_result: Dictionary = {}      # cache the game-over payload for re-display

func init_screen(params: Dictionary) -> void:
    _params = params
    vs_ai = str(params.get("mode", "ai")) == "ai"
    difficulty = str(params.get("difficulty", "hard"))
    board_n = int(params.get("board_size", 9))
    _build()
    if _resume != null:
        _adopt(_resume)
        _resume = null
    else:
        _start_game()

func _adopt(s: GameState) -> void:
    state = s
    state.move_made.connect(_on_move_made)   # old connections died with the freed node
    state.game_over.connect(_on_game_over)
    ai_thinking = false
    board_view.set_board(state.board)
    board_view.set_last_move(state.last_move())
    board_view.interactive = not state.over
    _update_scores()
    _update_turn_pill()
    if state.over:
        _on_game_over(_last_result)   # redraw run bands + the game-over modal
    else:
        _maybe_ai_move()              # re-request if it's the AI's turn (runner was freed)
```

And the in-game toggle just stashes the state before flipping the theme:

```gdscript
func _toggle_theme() -> void:
    _resume = state                  # deferred rebuild reads this in init_screen
    if state != null and state.over:
        pass # _last_result already cached by _on_game_over
    ThemeManager.set_theme_mode("light" if ThemeManager.is_dark() else "dark")
```

Cache the payload in the existing handler: `func _on_game_over(result): _last_result = result; …`.
If the AI was mid-search when the theme flips, the runner is freed and `_adopt` simply re-requests the move —
no lost game. Don't try to preserve any open overlay across the rebuild; landing back on the live board is fine.

### Fix B — make GameSetup selections survive a rebuild

Persist immediately instead of only on Start, so the rebuild restores them. In the mode/difficulty/size
callbacks call `Settings.set_value("mode"/"difficulty"/"board_size", …)` right away (you can then simplify
`_on_start` to just `goto`). This also makes the setup screen remember the last choices generally — a plus.

---

## Feature 1 — Main menu: How to Play, Credits, Quit

Extend `MainMenu` so the button column reads: **Play**, **How to Play**, **Settings**, **Credits**, **Quit**
(Play stays the primary button; the rest `ghost`, same 260px min width). Wire:

- How to Play → `MeridianApp.instance.goto("howto")`
- Credits → `MeridianApp.instance.goto("credits")`
- Quit → open a themed confirm modal (below), not an immediate quit.

### Quit confirm (witty / smart-ass)

Build it as a centred modal overlay using the same pattern as `GameScreen._show_game_over` (full-rect dim
`ColorRect` at ~0.38 alpha + a `UIKit.panel`). Copy you can use (keep one, or rotate a few):

> **Heading:** "Leaving already?"
> **Body:** "The board was just starting to like you. Walk away now and those X's and O's never get closure."
> **Buttons:** `Quit` (danger) · `Stay` (ghost)

`Quit` → `get_tree().quit()`. `Stay` (and tapping the dim) → close the modal. On Android `quit()` is a no-op /
discouraged, but Windows is the current target — leave a `# TODO(android)` note.

---

## Feature 2 — How to Play guide (visual, reusable)

A screen that **shows** the rules with real boards, not just paragraphs. Build the body as a **reusable
`Control`** (e.g. `scripts/ui/how_to_play.gd`, `class_name HowToPlay`) so it can be hosted both full-screen
(from the menu) and inside the in-game pause overlay (Feature 5). Put it in a `ScrollContainer` (the content
is tall) with a max-width column (~560) centred.

Cover these four ideas, each with a small `BoardView` illustration driven by `Board.from_rows(...)`:

1. **The goal — fill the whole board.** "There's no early win. Every cell gets a mark, then we count."
   Show a small board partly then fully filled (two `MiniBoard`/`BoardView` states, or one full board).
2. **Lines score in 4 directions.** Show four tiny 3×3 boards, each with one banded run, captioned
   *Across / Down / Diagonal / Diagonal*:
   - Across `[[1,1,1],[0,0,0],[0,0,0]]`, run `(0,0)→(0,2)`
   - Down `[[1,0,0],[1,0,0],[1,0,0]]`, run `(0,0)→(2,0)`
   - Diagonal `[[1,0,0],[0,1,0],[0,0,1]]`, run `(0,0)→(2,2)`
   - Diagonal `[[0,0,1],[0,1,0],[1,0,0]]`, run `(0,2)→(2,0)`
   Use `set_runs([{ "cells": [...], "owner": Marks.X }])` to draw the band.
3. **Longer lines are worth more.** A run of L in a row scores **L points** (3→3, 4→4, 5→5, …). Show a
   3-wide, a 4-wide, and a 5-wide top-row board (`Board.from_rows` with n = 3/4/5) each labelled "= 3 / 4 / 5".
   Note that only **maximal** runs of **3 or more** count — a lone pair scores nothing.
4. **Most points wins; tie is a draw.** Show one small **full** example board, then **drive the numbers from
   `Scoring.score(board)`** (don't hand-write totals — render whatever canonical scoring returns, and use its
   `runs` to draw the bands). Display "X N – O M → winner". This keeps the guide honest against the real rules.

Header: a `< Back` ghost button (full-screen host → `goto("menu")`; pause host → close overlay). Reuse the
amber `highlight` / accent colours already in `BoardView`. Add `"howto"` to `MeridianApp._make()`.

---

## Feature 3 — Credits screen

Add `"credits"` to `_make()`; `class_name Credits` in `scripts/ui/credits.gd`. Centred `UIKit.panel`, with:

- The Meridian wordmark (`UIKit.label("Meridian", "display_bold", …)`) and a witty line. Suggested copy:

  > "Meridian — a tic-tac-toe that refused to stay simple.
  > Fill the board, chase the longest line, and make the AI think about its choices.
  > Designed and built by **Amir**, one stubborn pixel at a time."

- Three link rows (label + a `soft`/`ghost` button) for **GitHub**, **LinkedIn**, **Portfolio**. **Leave the
  URLs blank** as named constants the user will fill in:

```gdscript
const GITHUB_URL    := ""   # TODO: Amir to fill
const LINKEDIN_URL  := ""   # TODO
const PORTFOLIO_URL := ""   # TODO

func _open(url: String) -> void:
    if url.strip_edges() != "":
        OS.shell_open(url)
```

  Disable (or no-op) a button whose URL is still blank so it never opens an empty link. `< Back` → `goto("menu")`.

---

## Feature 4 — Header dark/light toggle (Game Setup + Game)

Add a compact light/dark toggle to the header row of **GameSetup** (next to `< Back`) and the **GameScreen**
top bar (right side, near Undo/Restart). It calls `ThemeManager.set_theme_mode(...)` (which already persists
and fires `changed`).

- In **GameSetup** the rebuild is harmless once Fix B is in.
- In **GameScreen** route it through `_toggle_theme()` (Fix A) so the game survives.
- Make a tiny shared helper so both headers use the same control, e.g. `UIKit`-styled `soft` button whose
  label reflects the target mode (`"Dark"` when currently light, `"Light"` when dark), or a small custom
  `_draw` sun/moon glyph if you want it iconic. Reflect the current state and keep it ≥44px tall.

---

## Feature 5 — In-game Menu → pause popup (replaces the direct exit)

Right now `Menu` does `goto("menu")` and abandons the game instantly. Replace that with a **pause modal**
(same dim + `UIKit.panel` overlay pattern as `_show_game_over`, added as a child of `GameScreen` so the board
stays mounted underneath). Heading e.g. "Paused". Options, top to bottom:

1. **Restart** → call the existing `_on_restart()` and close the modal.
2. **Settings** → open settings **as an overlay on top of the game** (do **not** `goto("settings")` — that
   frees the GameScreen and loses the game). Reuse the settings controls: extract the row builders from
   `SettingsScreen` into a shared `Control`/builder (e.g. `SettingsPanel`) that both the full screen and this
   overlay use, so there's one source of truth. A `Done`/`< Back` returns to the pause modal (or straight to
   the board). Note: toggling theme from here will rebuild via Fix A and land back on the board in the new
   theme — that's acceptable; don't try to reopen the overlay.
3. **How to Play** → show the `HowToPlay` control from Feature 2 in an overlay; back returns to the pause modal.
4. **Back to Main Menu** → `goto("menu")` (intentionally leaves the game). Optional: a light "abandon this
   game?" confirm, since it discards the board — your call, keep it witty if you add it.

Also add a **Resume/Close** affordance (a button and/or tapping the dim) so the modal can be dismissed back
into the game.

---

## Optional polish (cheap, while you're in these files)

- **Animated thinking indicator.** The board-cell pulse is already animated; only the pill text is static.
  Cycle the ellipsis ("Thinking" → "Thinking." → "Thinking..") on a `Timer`, or a tiny animated-dots `Control`.
- **GameSetup max-width column.** It currently fills the full width. Wrap the content column in a centred
  max-width (~520–560) container to match the other panels.

(Audio, SVG logo, and Tween transitions remain Phase 5 — out of scope here.)

---

## Constraints

- No changes to `scripts/core/**` or `scripts/ai/**`. Rules + AI stay pure and node-free; the AI stays on the
  `AIRunner` worker thread with its time budget and visible thinking state.
- Every colour via `ThemeManager.color(...)`; every control via `UIKit` (or matching its styleboxes). Flat
  fills, project fonts, tabular numbers where numbers appear, ≥44px taps.
- New screens follow the existing convention: a `class_name`, built in `_ready()` (or `init_screen(params)` if
  they need params), registered in `MeridianApp._make()`.

## Acceptance criteria

- Main menu shows Play / How to Play / Settings / Credits / Quit, all wired.
- How to Play visibly teaches fill-the-board, the 4 directions, "run of L = L points (3+ only, maximal)", and
  win/draw — reachable from the menu **and** from the in-game pause menu, sharing one `HowToPlay` control.
- Credits shows the witty blurb + GitHub/LinkedIn/Portfolio rows with blank, user-editable URL constants and no
  empty-link opens.
- Quit asks the witty confirm; `Quit` exits, `Stay` cancels.
- A dark/light toggle sits in the GameSetup header and the in-game top bar; **toggling it mid-game does not
  reset the board** and **toggling it mid-setup does not reset selections**.
- The in-game Menu opens the pause modal (Restart / Settings / How to Play / Back to Main Menu + Resume);
  Settings and How to Play open as overlays and the game is intact when you close them; only Back to Main Menu
  leaves the game.

## Verify (headless — you can't see pixels, so report commands for the user)

- `--headless --import` must exit clean.
- Extend the `App --smoke` path: open `howto` and `credits`; open the pause modal in-game and each of its
  overlays; flip the theme **while a game is in progress** and assert the board state is unchanged
  (e.g. same `state.board.cells` / move count before and after) — this is the regression that matters. Print a
  clear `SMOKE_OK`.
- The GdUnit suite must still pass unchanged (UI work shouldn't touch core/AI — confirm 21/21, exit 0):
  `& "C:\Program Files\Godot\Godot_v4.6.3-stable_win64.exe" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests` (use the project's existing test command if different).
- Hand the user the windowed command to eyeball it: `& "C:\Program Files\Godot\Godot_v4.6.3-stable_win64.exe" --path .`
- Manual checklist for the user: menu buttons; guide visuals + bands render and the worked example's numbers
  match the bands; credits links are inert until filled; quit confirm wording; theme toggle recolours
  everything in setup and in-game **without** resetting the game/selections; pause modal options behave;
  Back to Main Menu is the only in-game path that abandons the board.
```

Nothing here commits — leave it staged for the user to review.
