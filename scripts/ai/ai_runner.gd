class_name AIRunner
extends Node
## Runs AI.best_move on a WorkerThreadPool task so the main thread never blocks.
## The search operates on a clone of the board (no shared mutable state); results and
## progress are marshalled back to the main thread via call_deferred + signals.

signal move_ready(move: Vector2i)   ## emitted on the main thread when the search finishes
signal thinking(cell: Vector2i)     ## emitted as the AI's current best root move updates

var _task_id: int = -1
var _busy: bool = false
var last_move: Vector2i = Vector2i(-1, -1) ## most recent completed result (main thread)


func is_busy() -> bool:
	return _busy


## Dispatches a search. Returns immediately. Ignored if a search is already running.
func request_move(board: Board, to_move: int, config: AIConfig) -> void:
	if _busy:
		return
	_busy = true
	# Only stream progress when someone is listening (avoids cross-thread deferred churn).
	var report := thinking.get_connections().size() > 0
	var snapshot := board.clone()
	_task_id = WorkerThreadPool.add_task(_run.bind(snapshot, to_move, config, report), true, "meridian_ai")


func _run(board: Board, to_move: int, config: AIConfig, report: bool) -> void:
	var ai := AI.new(config)
	if report:
		ai.on_progress = func(cell: Vector2i) -> void:
			call_deferred("_emit_thinking", cell)
	var mv := ai.best_move(board, to_move)
	call_deferred("_emit_done", mv)


func _emit_thinking(cell: Vector2i) -> void:
	thinking.emit(cell)


func _emit_done(mv: Vector2i) -> void:
	# The task has already finished (it deferred this call as its last act); collect it so the
	# pool releases the handle. Without this the engine can hang/crash on shutdown.
	if _task_id != -1:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	_busy = false
	last_move = mv
	move_ready.emit(mv)
