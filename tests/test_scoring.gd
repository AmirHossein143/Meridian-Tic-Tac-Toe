# GdUnit4 suite — scoring port pinned to the REAL board.js.
# The golden fixture is produced by `node tools/gen_reference_scores.mjs`.
# This proves Scoring.score() is identical to refrence/board.js across every fixture:
# per-player total, 3/4/5+ bucket counts, and the exact set of maximal-run cells.
extends GdUnitTestSuite

const FIXTURE := "res://tests/fixtures/reference_scores.json"

var _cases: Array = []


func before() -> void:
	var f := FileAccess.open(FIXTURE, FileAccess.READ)
	assert_object(f) \
		.override_failure_message("Missing fixture %s — run: node tools/gen_reference_scores.mjs" % FIXTURE) \
		.is_not_null()
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	assert_that(data).is_not_null()
	_cases = (data as Dictionary).get("cases", [])
	assert_int(_cases.size()).is_greater(0)


func test_scoring_matches_board_js_reference() -> void:
	assert_int(_cases.size()).is_greater(0)
	for tc: Dictionary in _cases:
		_check_case(tc)


func _check_case(tc: Dictionary) -> void:
	var case_name: String = tc.get("name", "?")
	var board := Board.from_rows(tc["grid"])
	var s := Scoring.score(board)
	var golden: Dictionary = tc["score"]
	_check_player(case_name, "X", s[Marks.X], golden["X"])
	_check_player(case_name, "O", s[Marks.O], golden["O"])


func _check_player(case_name: String, label: String, mine: Dictionary, golden: Dictionary) -> void:
	var ctx := "%s/%s" % [case_name, label]
	assert_int(mine["total"]).override_failure_message("%s total" % ctx).is_equal(int(golden["total"]))
	assert_int(mine["counts"][3]).override_failure_message("%s counts[3]" % ctx).is_equal(int(golden["counts"]["3"]))
	assert_int(mine["counts"][4]).override_failure_message("%s counts[4]" % ctx).is_equal(int(golden["counts"]["4"]))
	assert_int(mine["counts"][5]).override_failure_message("%s counts[5+]" % ctx).is_equal(int(golden["counts"]["5"]))
	assert_array(_canon_mine(mine["runs"])).override_failure_message("%s run cells" % ctx).is_equal(_canon_golden(golden["runs"]))


# Normalize my runs (cells are Vector2i) to a sorted list of canonical strings.
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


# Normalize golden runs (cells are [row, col] JSON arrays of floats) the same way.
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
