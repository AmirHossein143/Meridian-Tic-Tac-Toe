extends GdUnitTestSuite
## AI search: incremental-eval correctness, candidate generation, tactics, difficulty/blunder
## behaviour, and the off-thread runner.

func _fast(seed: int = 1) -> AIConfig:
	var c := AIConfig.hard(seed)
	c.max_depth = 3
	c.time_budget_ms = 600
	return c


func test_first_move_is_center() -> void:
	var mv := AI.new(_fast()).best_move(Board.new(5), Marks.X)
	assert_int(mv.x).is_equal(2)
	assert_int(mv.y).is_equal(2)


func test_candidates_within_radius_of_marks() -> void:
	var ai := AI.new(AIConfig.hard())
	ai.cfg.candidate_radius = 1
	ai.board = Board.new(7)
	ai.size = 7
	ai.board.set_cell(3, 3, Marks.X)
	var cands := ai._candidates()
	assert_int(cands.size()).is_equal(8) # the 8 neighbours of (3,3)
	for m: Vector2i in cands:
		assert_int(maxi(absi(m.x - 3), absi(m.y - 3))).is_less_equal(1)


func test_takes_the_immediate_three() -> void:
	# X has (0,0),(0,1); (0,2) is the only move that forms a 3-run (+3 dominates).
	var b := Board.new(5)
	b.set_cell(0, 0, Marks.X)
	b.set_cell(0, 1, Marks.X)
	b.set_cell(4, 4, Marks.O)
	b.set_cell(4, 3, Marks.O)
	var mv := AI.new(_fast()).best_move(b, Marks.X)
	assert_int(mv.x).is_equal(0)
	assert_int(mv.y).is_equal(2)


func test_incremental_eval_tracks_scoring_exactly() -> void:
	# Filling the board with pseudo-random alternating moves: the incrementally maintained
	# running_exact must equal a from-scratch Scoring.differential() after EVERY move, and
	# the potential must return to 0 once the board is full.
	var ai := AI.new(_fast())
	var b := Board.new(6)
	ai.board = b
	ai.size = 6
	ai._init_eval()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var mark := Marks.X
	for step in 36:
		var empties := b.empties()
		if empties.is_empty():
			break
		var cell: Vector2i = empties[rng.randi() % empties.size()]
		ai._apply(cell.x, cell.y, mark)
		assert_int(ai.running_exact) \
			.override_failure_message("incremental exact mismatch at step %d" % step) \
			.is_equal(Scoring.differential(b, Marks.X))
		mark = Marks.other(mark)
	assert_int(ai.running_pot).is_equal(0)


func test_returns_legal_move_midgame() -> void:
	var b := Board.from_rows([
		[1, 2, 0, 0, 1],
		[0, 1, 2, 0, 0],
		[0, 0, 1, 2, 0],
		[2, 0, 0, 1, 0],
		[0, 2, 0, 0, 1],
	])
	var mv := AI.new(_fast()).best_move(b, Marks.O)
	assert_bool(b.in_bounds(mv.x, mv.y)).is_true()
	assert_bool(b.is_empty(mv.x, mv.y)).is_true()


func test_easy_blunders_sometimes_not_always() -> void:
	var b := Board.new(5)
	b.set_cell(0, 0, Marks.X)
	b.set_cell(0, 1, Marks.X)
	b.set_cell(4, 4, Marks.O)
	b.set_cell(4, 3, Marks.O)
	var strong := AI.new(_fast()).best_move(b, Marks.X) # (0,2)
	var blunders := 0
	var trials := 60
	for i in trials:
		if AI.new(AIConfig.easy(1000 + i)).best_move(b, Marks.X) != strong:
			blunders += 1
	assert_int(blunders).override_failure_message("easy blundered %d/%d" % [blunders, trials]).is_greater(0)
	assert_int(blunders).is_less(trials)


# NOTE: the off-thread AIRunner is verified end-to-end in tests/headless/bench_ai.gd.
# Driving WorkerThreadPool + signal await *inside* a GdUnit test crashes GdUnit's process
# teardown (the tests pass, but the engine segfaults on exit), so it is kept out of here to
# preserve a clean CI exit code. The synchronous tests above cover the search itself.
