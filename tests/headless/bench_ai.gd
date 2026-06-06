extends SceneTree
## Worst-case AI move-time benchmark (Hard difficulty) at 15x15 and 19x19, plus an end-to-end
## check that AIRunner searches off the main thread without blocking.
##   godot --headless --path . -s res://tests/headless/bench_ai.gd
##
## After _initialize() returns we do NOT quit: the SceneTree keeps iterating, flushing the
## message queue so the worker's call_deferred result fires move_ready -> _on_move -> quit().

var _runner: AIRunner
var _runner_t0: int
var _runner_dispatch: int
var _runner_board: Board


func _initialize() -> void:
	print("\n=== Meridian AI benchmark — Hard difficulty ===")
	_bench_sync(15)
	_bench_sync(19)

	# Off-thread end-to-end check via the real AIRunner.
	_runner = AIRunner.new()
	_runner.move_ready.connect(_on_runner_move)
	_runner_board = _worst_case_board(15)
	_runner_t0 = Time.get_ticks_msec()
	_runner.request_move(_runner_board, Marks.O, AIConfig.hard(1))
	_runner_dispatch = Time.get_ticks_msec() - _runner_t0
	# Intentionally no quit() here — wait for the threaded result.


func _on_runner_move(mv: Vector2i) -> void:
	var total := Time.get_ticks_msec() - _runner_t0
	var legal := _runner_board.in_bounds(mv.x, mv.y) and _runner_board.is_empty(mv.x, mv.y)
	print("runner 15x15  dispatch_returned=%dms (non-blocking)  move=%s  legal=%s  total=%dms"
		% [_runner_dispatch, str(mv), str(legal), total])
	# Free after the emit unwinds (it is locked mid-emit right now), then quit cleanly.
	_runner.call_deferred("free")
	quit(0)


## Dense, near-balanced scatter — maximises candidate count and run interactions.
func _worst_case_board(n: int) -> Board:
	var b := Board.new(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var target := int(n * n * 0.5)
	var mark := Marks.X
	var placed := 0
	while placed < target:
		var r := rng.randi() % n
		var c := rng.randi() % n
		if b.is_empty(r, c):
			b.set_cell(r, c, mark)
			mark = Marks.other(mark)
			placed += 1
	return b


func _bench_sync(n: int) -> void:
	var b := _worst_case_board(n)
	var cfg := AIConfig.hard(1)
	var ai := AI.new(cfg)
	var t0 := Time.get_ticks_msec()
	var mv := ai.best_move(b, Marks.O)
	var dt := Time.get_ticks_msec() - t0
	var status := "OK" if dt <= cfg.time_budget_ms + 150 else "OVER-BUDGET"
	print("sync   %dx%d  move=%s  depth=%d  nodes=%d  time=%dms  budget=%dms  [%s]"
		% [n, n, str(mv), ai.depth_reached, ai.nodes, dt, cfg.time_budget_ms, status])
