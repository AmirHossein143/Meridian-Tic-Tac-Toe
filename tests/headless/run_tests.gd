extends SceneTree
## Zero-dependency headless test runner. Works on any Godot 4.x with no addons, so it
## is immune to GdUnit4/engine version drift and usable in CI without the framework.
##   godot --headless --path . -s res://tests/headless/run_tests.gd
## Exit code 0 = all pass, 1 = at least one failure.
##
## The GdUnit4 suites in tests/*.gd assert the same things and become the primary suite
## once a Godot-4.6-compatible GdUnit4 build is installed.

var _pass := 0
var _fail := 0
var _failures: Array[String] = []


func _initialize() -> void:
	print("\n=== Meridian headless tests (zero-dep) ===")
	_suite_board()
	_suite_game_state()
	_suite_scoring()
	print("\n----------------------------------------")
	print("TOTAL  pass=%d  fail=%d" % [_pass, _fail])
	if _fail > 0:
		print("FAILURES:")
		for m in _failures:
			print("  - ", m)
	else:
		print("ALL GREEN")
	quit(0 if _fail == 0 else 1)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		_failures.append(msg)


func _eq(actual: Variant, expected: Variant, msg: String) -> void:
	_ok(actual == expected, "%s -- expected %s, got %s" % [msg, str(expected), str(actual)])


# ---------------------------------------------------------------- Board
func _suite_board() -> void:
	var b := Board.new(3)
	_eq(b.size, 3, "board.size")
	_eq(b.empty_count(), 9, "empty board count")
	_ok(not b.is_full(), "empty board not full")
	b.place(0, 0, Marks.X)
	b.place(2, 1, Marks.O)
	_eq(b.get_cell(0, 0), Marks.X, "place X")
	_eq(b.get_cell(2, 1), Marks.O, "place O")
	_eq(b.empty_count(), 7, "count after 2 placements")
	b.undo(0, 0)
	_eq(b.get_cell(0, 0), Marks.EMPTY, "undo clears cell")
	_ok(b.in_bounds(2, 2) and not b.in_bounds(3, 0) and not b.in_bounds(0, -1), "in_bounds")
	# clone independence
	var c := b.clone()
	c.place(1, 1, Marks.X)
	_eq(b.get_cell(1, 1), Marks.EMPTY, "clone is independent")
	# from_rows row/col mapping
	var fr := Board.from_rows([[Marks.X, Marks.EMPTY], [Marks.O, Marks.X]])
	_ok(fr.get_cell(0, 0) == Marks.X and fr.get_cell(1, 0) == Marks.O and fr.get_cell(1, 1) == Marks.X, "from_rows maps (row,col)")
	# full board
	var full := Board.new(2)
	for r in 2:
		for col in 2:
			full.place(r, col, Marks.X)
	_ok(full.is_full(), "full board detected")


# ---------------------------------------------------------------- GameState
func _suite_game_state() -> void:
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	_eq(gs.current, Marks.X, "X moves first")
	_ok(gs.apply_move(0, 0), "X plays")
	_eq(gs.current, Marks.O, "O's turn")
	_ok(not gs.apply_move(0, 0), "occupied cell rejected")
	_ok(not gs.apply_move(5, 5), "out-of-bounds rejected")
	_ok(gs.apply_move(0, 1), "O plays")
	_eq(gs.current, Marks.X, "back to X")
	# undo restores turn + cell
	_ok(gs.undo_last(), "undo O")
	_eq(gs.board.get_cell(0, 1), Marks.EMPTY, "undo removed O move")
	_eq(gs.current, Marks.O, "turn restored to O")
	# game over on full board, fired exactly once
	var gs2 := GameState.new(3, GameState.Mode.TWO_PLAYER)
	var over_count := [0]
	gs2.game_over.connect(func(_res: Dictionary) -> void: over_count[0] += 1)
	for r in 3:
		for col in 3:
			gs2.apply_move(r, col)
	_ok(gs2.over, "game over when full")
	_eq(over_count[0], 1, "game_over fired once")
	_ok(not gs2.apply_move(0, 0), "no moves after game over")
	# winner / draw
	var win := GameState.new(3, GameState.Mode.TWO_PLAYER)
	for cell in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 2)]:
		win.board.place(cell.x, cell.y, Marks.X)
	for cell in [Vector2i(1, 0), Vector2i(1, 2), Vector2i(2, 0), Vector2i(2, 1)]:
		win.board.place(cell.x, cell.y, Marks.O)
	var res := win.final_result()
	_eq(res["winner"], Marks.X, "winner is X")
	_eq(res["x_total"], 6, "X total = row + diagonal")
	_eq(res["o_total"], 0, "O total = 0")
	var draw := GameState.new(3, GameState.Mode.TWO_PLAYER)
	for col in 3:
		draw.board.place(0, col, Marks.X)
		draw.board.place(2, col, Marks.O)
	_eq(draw.final_result()["winner"], Marks.EMPTY, "equal totals -> draw")


# ---------------------------------------------------------------- Scoring (pinned to board.js)
func _suite_scoring() -> void:
	var path := "res://tests/fixtures/reference_scores.json"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_ok(false, "open fixture %s (run: node tools/gen_reference_scores.mjs)" % path)
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		_ok(false, "parse fixture json")
		return
	var cases: Array = (data as Dictionary).get("cases", [])
	_ok(cases.size() > 0, "fixture has cases (%d)" % cases.size())
	for tc: Dictionary in cases:
		var board := Board.from_rows(tc["grid"])
		var s := Scoring.score(board)
		var golden: Dictionary = tc["score"]
		_check_player(str(tc["name"]), "X", s[Marks.X], golden["X"])
		_check_player(str(tc["name"]), "O", s[Marks.O], golden["O"])


func _check_player(case_name: String, label: String, mine: Dictionary, golden: Dictionary) -> void:
	var ctx := "%s/%s" % [case_name, label]
	_eq(mine["total"], int(golden["total"]), ctx + " total")
	_eq(mine["counts"][3], int(golden["counts"]["3"]), ctx + " counts[3]")
	_eq(mine["counts"][4], int(golden["counts"]["4"]), ctx + " counts[4]")
	_eq(mine["counts"][5], int(golden["counts"]["5"]), ctx + " counts[5+]")
	_eq(_canon_mine(mine["runs"]), _canon_golden(golden["runs"]), ctx + " run cells")


func _canon_mine(runs: Array) -> Array:
	var out: Array = []
	for run: Dictionary in runs:
		var cs: Array = []
		for cell: Vector2i in run["cells"]:
			cs.append([cell.x, cell.y])
		cs.sort()
		out.append(str(cs))
	out.sort()
	return out


func _canon_golden(runs: Array) -> Array:
	var out: Array = []
	for run: Dictionary in runs:
		var cs: Array = []
		for cell: Array in run["cells"]:
			cs.append([int(cell[0]), int(cell[1])])
		cs.sort()
		out.append(str(cs))
	out.sort()
	return out
