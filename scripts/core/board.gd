class_name Board
extends RefCounted
## Pure N x N board model. No node / UI dependencies so it is headless-testable.
## Cells are stored in a flat PackedByteArray in (row, col) order: index = row * size + col.

var size: int
var cells: PackedByteArray


func _init(p_size: int = 3) -> void:
	size = p_size
	cells = PackedByteArray()
	cells.resize(size * size) # PackedByteArray.resize zero-fills (EMPTY)


func _index(r: int, c: int) -> int:
	return r * size + c


func in_bounds(r: int, c: int) -> bool:
	return r >= 0 and c >= 0 and r < size and c < size


func get_cell(r: int, c: int) -> int:
	return cells[r * size + c]


func set_cell(r: int, c: int, v: int) -> void:
	cells[r * size + c] = v


func is_empty(r: int, c: int) -> bool:
	return cells[r * size + c] == Marks.EMPTY


## Places a mark. Caller is responsible for legality (used by search/undo too).
func place(r: int, c: int, v: int) -> void:
	cells[r * size + c] = v


## Clears a cell back to EMPTY (search undo).
func undo(r: int, c: int) -> void:
	cells[r * size + c] = Marks.EMPTY


func is_full() -> bool:
	return not cells.has(Marks.EMPTY)


func empty_count() -> int:
	var n := 0
	for b in cells:
		if b == Marks.EMPTY:
			n += 1
	return n


## All empty cells as Array[Vector2i] in (row, col).
func empties() -> Array:
	var out: Array = []
	for r in size:
		var base := r * size
		for c in size:
			if cells[base + c] == Marks.EMPTY:
				out.append(Vector2i(r, c))
	return out


func clone() -> Board:
	var b := Board.new(size)
	b.cells = cells.duplicate()
	return b


## Stable state key (size + hex of cells). Good enough for tests and simple memoization;
## the AI (Phase 2) uses a faster Zobrist hash for its transposition table.
func key() -> String:
	return str(size) + ":" + cells.hex_encode()


## Builds a Board from a 2D Array of ints indexed rows[row][col] (matches board.js grids).
static func from_rows(rows: Array) -> Board:
	var n := rows.size()
	var b := Board.new(n)
	for r in n:
		var row: Array = rows[r]
		for c in n:
			b.set_cell(r, c, int(row[c]))
	return b
