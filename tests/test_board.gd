# GdUnit4 suite — Board model (pure, headless).
extends GdUnitTestSuite


func test_new_board_is_empty() -> void:
	var b := Board.new(3)
	assert_int(b.size).is_equal(3)
	assert_int(b.empty_count()).is_equal(9)
	assert_bool(b.is_full()).is_false()


func test_place_and_get() -> void:
	var b := Board.new(3)
	b.place(0, 0, Marks.X)
	b.place(2, 1, Marks.O)
	assert_int(b.get_cell(0, 0)).is_equal(Marks.X)
	assert_int(b.get_cell(2, 1)).is_equal(Marks.O)
	assert_bool(b.is_empty(1, 1)).is_true()
	assert_int(b.empty_count()).is_equal(7)


func test_undo_clears_cell() -> void:
	var b := Board.new(3)
	b.place(1, 1, Marks.X)
	b.undo(1, 1)
	assert_int(b.get_cell(1, 1)).is_equal(Marks.EMPTY)
	assert_int(b.empty_count()).is_equal(9)


func test_in_bounds() -> void:
	var b := Board.new(3)
	assert_bool(b.in_bounds(0, 0)).is_true()
	assert_bool(b.in_bounds(2, 2)).is_true()
	assert_bool(b.in_bounds(-1, 0)).is_false()
	assert_bool(b.in_bounds(3, 0)).is_false()
	assert_bool(b.in_bounds(0, 3)).is_false()


func test_is_full_and_empties() -> void:
	var b := Board.new(2)
	assert_int(b.empties().size()).is_equal(4)
	for r in 2:
		for c in 2:
			b.place(r, c, Marks.X)
	assert_bool(b.is_full()).is_true()
	assert_array(b.empties()).is_empty()


func test_clone_is_independent() -> void:
	var b := Board.new(3)
	b.place(0, 0, Marks.X)
	var c := b.clone()
	assert_int(c.get_cell(0, 0)).is_equal(Marks.X)
	c.place(1, 1, Marks.O)
	# Mutating the clone must not change the original.
	assert_int(b.get_cell(1, 1)).is_equal(Marks.EMPTY)
	assert_int(c.get_cell(1, 1)).is_equal(Marks.O)


func test_from_rows_maps_row_col() -> void:
	var rows := [[Marks.X, Marks.EMPTY], [Marks.O, Marks.X]]
	var b := Board.from_rows(rows)
	assert_int(b.size).is_equal(2)
	assert_int(b.get_cell(0, 0)).is_equal(Marks.X)
	assert_int(b.get_cell(0, 1)).is_equal(Marks.EMPTY)
	assert_int(b.get_cell(1, 0)).is_equal(Marks.O)
	assert_int(b.get_cell(1, 1)).is_equal(Marks.X)


func test_key_changes_with_state() -> void:
	var b := Board.new(3)
	var k0 := b.key()
	b.place(0, 0, Marks.X)
	assert_bool(b.key() != k0).is_true()
