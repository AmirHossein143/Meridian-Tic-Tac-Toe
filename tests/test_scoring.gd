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


# Fix 5: per-bucket POINTS (not just counts). 3->c3*3, 4->c4*4, 5+ -> SUM of actual run lengths.
func test_bucket_points_explicit() -> void:
	# Only run is six X across the top of a 6x6 -> the 5+ bucket sums lengths: a len-6 run = 6,
	# NOT count*5 = 5. (board.js scores a 6-run as 6 — see the x_row6_7 fixture.)
	var six := Board.new(6)
	for c in 6:
		six.set_cell(0, c, Marks.X)
	var sx: Dictionary = Scoring.score(six)[Marks.X]
	assert_int(sx["counts"][3]).is_equal(0)
	assert_int(sx["counts"][4]).is_equal(0)
	assert_int(sx["counts"][5]).is_equal(1)
	var p6 := Scoring.bucket_points(sx)
	assert_int(p6[3]).is_equal(0)
	assert_int(p6[4]).is_equal(0)
	assert_int(p6[5]).is_equal(6)
	assert_int(p6[3] + p6[4] + p6[5]).is_equal(int(sx["total"]))

	# Full 5x5 all-X exercises all three buckets (rows/cols give 12 len-5 runs; the two diagonal
	# axes add 2 len-4 and 2 len-3 runs each).
	var five := Board.new(5)
	for r in 5:
		for c in 5:
			five.set_cell(r, c, Marks.X)
	var fx: Dictionary = Scoring.score(five)[Marks.X]
	assert_int(fx["counts"][3]).is_equal(4)
	assert_int(fx["counts"][4]).is_equal(4)
	assert_int(fx["counts"][5]).is_equal(12)
	var pf := Scoring.bucket_points(fx)
	assert_int(pf[3]).is_equal(12)
	assert_int(pf[4]).is_equal(16)
	assert_int(pf[5]).is_equal(60)
	assert_int(pf[3] + pf[4] + pf[5]).is_equal(88)
	assert_int(int(fx["total"])).is_equal(88)


# bucket_points stays consistent with the board.js-pinned score() across every fixture.
func test_bucket_points_consistent_with_score() -> void:
	assert_int(_cases.size()).is_greater(0)
	for tc: Dictionary in _cases:
		var board := Board.from_rows(tc["grid"])
		var s := Scoring.score(board)
		for mark in [Marks.X, Marks.O]:
			var rec: Dictionary = s[mark]
			var p := Scoring.bucket_points(rec)
			var ctx := "%s/%s" % [tc.get("name", "?"), "X" if mark == Marks.X else "O"]
			assert_int(p[3]).override_failure_message("%s p3" % ctx).is_equal(int(rec["counts"][3]) * 3)
			assert_int(p[4]).override_failure_message("%s p4" % ctx).is_equal(int(rec["counts"][4]) * 4)
			assert_int(p[3] + p[4] + p[5]).override_failure_message("%s sum=total" % ctx).is_equal(int(rec["total"]))


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
