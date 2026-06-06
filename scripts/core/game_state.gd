class_name GameState
extends RefCounted
## Orchestrates a single match. Pure (no nodes); the UI subscribes to its signals and
## reads its board. X always moves first. There is no early win — the game ends only when
## the board is full, then `final_result()` tallies the canonical score.

signal move_made(r: int, c: int, player: int)
signal turn_changed(player: int)
signal game_over(result: Dictionary)

enum Mode { VS_AI, TWO_PLAYER }

var board: Board
var mode: int = Mode.VS_AI
var ai_player: int = Marks.O ## In vs-AI the AI is O (human is X and moves first), per PROTOTYPE.py.
var current: int = Marks.X
var history: Array = [] ## Array[Vector2i] of moves in play order.
var over: bool = false


func _init(p_size: int = 3, p_mode: int = Mode.VS_AI) -> void:
	board = Board.new(p_size)
	mode = p_mode
	current = Marks.X
	history = []
	over = false


func legal(r: int, c: int) -> bool:
	return not over and board.in_bounds(r, c) and board.is_empty(r, c)


## Applies the current player's move. Returns false if illegal. Emits move_made, then
## either game_over (board full) or turn_changed.
func apply_move(r: int, c: int) -> bool:
	if not legal(r, c):
		return false
	var player := current
	board.place(r, c, player)
	history.append(Vector2i(r, c))
	move_made.emit(r, c, player)
	if board.is_full():
		over = true
		game_over.emit(final_result())
	else:
		current = Marks.other(current)
		turn_changed.emit(current)
	return true


## Undoes the most recent move and restores the turn to its mover. Returns false if empty.
func undo_last() -> bool:
	if history.is_empty():
		return false
	var last: Vector2i = history.pop_back()
	board.undo(last.x, last.y)
	over = false
	# Moves strictly alternate from X, so the next mover is decided by history length.
	current = Marks.X if history.size() % 2 == 0 else Marks.O
	turn_changed.emit(current)
	return true


func last_move() -> Vector2i:
	return history.back() if not history.is_empty() else Vector2i(-1, -1)


## Tallies the finished (or in-progress) board. winner is Marks.X / Marks.O, or Marks.EMPTY for a draw.
func final_result() -> Dictionary:
	var s := Scoring.score(board)
	var x_total: int = s[Marks.X]["total"]
	var o_total: int = s[Marks.O]["total"]
	var winner := Marks.EMPTY
	if x_total > o_total:
		winner = Marks.X
	elif o_total > x_total:
		winner = Marks.O
	return {"score": s, "x_total": x_total, "o_total": o_total, "winner": winner}
