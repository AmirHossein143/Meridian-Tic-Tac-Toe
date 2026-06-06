# GdUnit4 suite — GameState match orchestration (pure, headless).
extends GdUnitTestSuite


func test_x_moves_first_and_alternates() -> void:
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	assert_int(gs.current).is_equal(Marks.X)
	assert_bool(gs.apply_move(0, 0)).is_true()
	assert_int(gs.board.get_cell(0, 0)).is_equal(Marks.X)
	assert_int(gs.current).is_equal(Marks.O)
	assert_bool(gs.apply_move(1, 1)).is_true()
	assert_int(gs.board.get_cell(1, 1)).is_equal(Marks.O)
	assert_int(gs.current).is_equal(Marks.X)


func test_illegal_moves_rejected() -> void:
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	assert_bool(gs.apply_move(0, 0)).is_true()
	assert_bool(gs.apply_move(0, 0)).is_false() # occupied
	assert_bool(gs.apply_move(-1, 0)).is_false() # out of bounds
	assert_bool(gs.apply_move(3, 0)).is_false() # out of bounds


func test_undo_restores_turn_and_cell() -> void:
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	gs.apply_move(0, 0) # X
	gs.apply_move(0, 1) # O
	assert_int(gs.current).is_equal(Marks.X)
	assert_bool(gs.undo_last()).is_true() # undo O
	assert_int(gs.board.get_cell(0, 1)).is_equal(Marks.EMPTY)
	assert_int(gs.current).is_equal(Marks.O)
	assert_bool(gs.undo_last()).is_true() # undo X
	assert_int(gs.current).is_equal(Marks.X)
	assert_bool(gs.undo_last()).is_false() # nothing left to undo


func test_full_board_ends_game_and_emits_once() -> void:
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	var over_count := [0]
	gs.game_over.connect(func(_res: Dictionary) -> void: over_count[0] += 1)
	for r in 3:
		for c in 3:
			gs.apply_move(r, c)
	assert_bool(gs.over).is_true()
	assert_int(over_count[0]).is_equal(1)
	# No moves accepted once the game is over.
	assert_bool(gs.apply_move(0, 0)).is_false()


func test_final_result_picks_higher_total() -> void:
	# X = top row + main diagonal (two 3-runs); O has no 3-run.
	#   X X X
	#   O X O
	#   O O X
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	for cell in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 2)]:
		gs.board.place(cell.x, cell.y, Marks.X)
	for cell in [Vector2i(1, 0), Vector2i(1, 2), Vector2i(2, 0), Vector2i(2, 1)]:
		gs.board.place(cell.x, cell.y, Marks.O)
	var res := gs.final_result()
	assert_int(res["winner"]).is_equal(Marks.X)
	assert_int(res["x_total"]).is_equal(6) # 3 (row) + 3 (diagonal)
	assert_int(res["o_total"]).is_equal(0)


func test_final_result_draw_is_empty_winner() -> void:
	# Symmetric: X top row, O bottom row -> 3 each -> draw.
	var gs := GameState.new(3, GameState.Mode.TWO_PLAYER)
	for c in 3:
		gs.board.place(0, c, Marks.X)
		gs.board.place(2, c, Marks.O)
	var res := gs.final_result()
	assert_int(res["x_total"]).is_equal(3)
	assert_int(res["o_total"]).is_equal(3)
	assert_int(res["winner"]).is_equal(Marks.EMPTY)
