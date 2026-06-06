class_name AI
extends RefCounted
## Depth-limited negamax + alpha-beta search for Meridian.
##
## Pure (no nodes). It mutates the Board it is given during the search but always restores
## it, so callers may pass their live board; the threaded AIRunner passes a clone anyway.
##
## Evaluation is INCREMENTAL: placing a mark only changes the 4 lines through that cell, so
## make/unmake rescores just those lines. `running_exact` mirrors Scoring.differential()
## exactly (cross-checked in tests); `running_pot` is a heuristic bonus for extendable lines.
##
## Transposition table is keyed by a Zobrist hash of the position and qualified by remaining
## depth + bound flag (EXACT/LOWER/UPPER) — sound across depths, unlike PROTOTYPE.py's memo.

enum { FLAG_EXACT, FLAG_LOWER, FLAG_UPPER }

const NEG_INF := -(1 << 50)
const POS_INF := (1 << 50)

var cfg: AIConfig
var board: Board
var size: int

var running_exact: int = 0   ## X_total - O_total (exact run score), maintained incrementally
var running_pot: int = 0     ## X_potential - O_potential (heuristic), maintained incrementally
var zkey: int = 0
var ztable: PackedInt64Array
var tt: Dictionary = {}

var rng := RandomNumberGenerator.new()
var on_progress: Callable = Callable()   ## optional: called with the best root move per depth

var nodes: int = 0          ## search statistics (for benchmarks)
var depth_reached: int = 0
var _deadline: int = 0
var _aborted: bool = false


func _init(config: AIConfig = null) -> void:
	cfg = config if config != null else AIConfig.hard()
	if cfg.rng_seed != 0:
		rng.seed = cfg.rng_seed
	else:
		rng.randomize()


## Returns the best move for `to_move` on board `b`. Never blocks longer than the time budget.
func best_move(b: Board, to_move: int) -> Vector2i:
	board = b
	size = b.size
	tt.clear()
	nodes = 0
	depth_reached = 0
	_init_eval()

	if board.empty_count() == size * size:
		return Vector2i(size / 2, size / 2) # center opening

	var cands := _candidates()
	if cands.is_empty():
		return Vector2i(-1, -1)

	# Easy difficulty: occasional random blunder so it is beatable.
	if cfg.blunder_chance > 0.0 and rng.randf() < cfg.blunder_chance:
		return cands[rng.randi() % cands.size()]

	_deadline = Time.get_ticks_msec() + cfg.time_budget_ms
	_aborted = false
	var best: Vector2i = cands[0]
	var max_d: int = mini(cfg.max_depth, board.empty_count())
	var depth := 1
	while depth <= max_d:
		var res := _search_root(to_move, depth)
		if _aborted:
			break # discard the incomplete iteration, keep the previous depth's best
		best = res
		depth_reached = depth
		if on_progress.is_valid():
			on_progress.call(best)
		depth += 1
	return best


func _search_root(to_move: int, depth: int) -> Vector2i:
	var alpha := NEG_INF
	var beta := POS_INF
	var best_val := NEG_INF
	var best_m := Vector2i(-1, -1)
	for m: Vector2i in _ordered_candidates(to_move):
		if _time_up():
			_aborted = true
			break
		var d := _apply(m.x, m.y, to_move)
		var val := -_negamax(depth - 1, -beta, -alpha, Marks.other(to_move))
		_unapply(m.x, m.y, to_move, d)
		if _aborted:
			break
		if val > best_val:
			best_val = val
			best_m = m
			if val > alpha:
				alpha = val
	if best_m == Vector2i(-1, -1):
		var fallback := _candidates()
		if not fallback.is_empty():
			best_m = fallback[0]
	return best_m


func _negamax(depth: int, alpha: int, beta: int, to_move: int) -> int:
	nodes += 1
	if _time_up(): # checked every node — nodes are heavy, the check is cheap
		_aborted = true
		return 0
	if board.is_full():
		return _leaf(to_move, true)
	if depth == 0:
		return _leaf(to_move, false)

	var alpha_orig := alpha
	if tt.has(zkey):
		var e: Dictionary = tt[zkey]
		if e["depth"] >= depth:
			match e["flag"]:
				FLAG_EXACT:
					return e["value"]
				FLAG_LOWER:
					alpha = maxi(alpha, e["value"])
				FLAG_UPPER:
					beta = mini(beta, e["value"])
			if alpha >= beta:
				return e["value"]

	var best_val := NEG_INF
	var best_m := Vector2i(-1, -1)
	for m: Vector2i in _ordered_candidates(to_move):
		var d := _apply(m.x, m.y, to_move)
		var val := -_negamax(depth - 1, -beta, -alpha, Marks.other(to_move))
		_unapply(m.x, m.y, to_move, d)
		if _aborted:
			return 0
		if val > best_val:
			best_val = val
			best_m = m
		if best_val > alpha:
			alpha = best_val
		if alpha >= beta:
			break

	var flag := FLAG_EXACT
	if best_val <= alpha_orig:
		flag = FLAG_UPPER
	elif best_val >= beta:
		flag = FLAG_LOWER
	tt[zkey] = {"depth": depth, "value": best_val, "flag": flag, "move": best_m}
	return best_val


## Leaf value from `to_move`'s perspective. At a full board the exact score is final
## (potential is 0 there anyway).
func _leaf(to_move: int, terminal: bool) -> int:
	var x_view := running_exact * cfg.scale + (0 if terminal else running_pot)
	return x_view if to_move == Marks.X else -x_view


func _time_up() -> bool:
	return Time.get_ticks_msec() > _deadline


# ----------------------------------------------------------------- make / unmake

func _apply(r: int, c: int, mark: int) -> Array:
	var before := _sum_lines(r, c)
	board.set_cell(r, c, mark)
	var after := _sum_lines(r, c)
	var de: int = after[0] - before[0]
	var dp: int = after[1] - before[1]
	running_exact += de
	running_pot += dp
	zkey ^= ztable[(r * size + c) * 2 + (mark - 1)]
	return [de, dp]


func _unapply(r: int, c: int, mark: int, delta: Array) -> void:
	board.set_cell(r, c, Marks.EMPTY)
	running_exact -= delta[0]
	running_pot -= delta[1]
	zkey ^= ztable[(r * size + c) * 2 + (mark - 1)]


# ----------------------------------------------------------------- evaluation

## Sum of (exact, potential) over the 4 axis lines that pass through (r, c).
func _sum_lines(r: int, c: int) -> Array:
	var e := 0
	var p := 0
	for dir: Vector2i in Scoring.DIRS:
		var res := _score_line(_line_cells(r, c, dir))
		e += res[0]
		p += res[1]
	return [e, p]


## The full axis line through (r, c) in direction `dir`, as a sequence of cell values.
func _line_cells(r: int, c: int, dir: Vector2i) -> PackedByteArray:
	var dr := dir.x
	var dc := dir.y
	var sr := r
	var sc := c
	while board.in_bounds(sr - dr, sc - dc):
		sr -= dr
		sc -= dc
	var cells := PackedByteArray()
	while board.in_bounds(sr, sc):
		cells.append(board.get_cell(sr, sc))
		sr += dr
		sc += dc
	return cells


## Scores one line from X's perspective: maximal runs >= 3 add +/- length (exact); open-ended
## pairs and extendable 3+ runs add +/- a small potential.
func _score_line(line: PackedByteArray) -> Array:
	var n := line.size()
	var exact := 0
	var pot := 0
	var i := 0
	while i < n:
		var v := line[i]
		if v == Marks.EMPTY:
			i += 1
			continue
		var j := i
		while j < n and line[j] == v:
			j += 1
		var run_len := j - i
		var sgn := 1 if v == Marks.X else -1
		if run_len >= 3:
			exact += sgn * run_len
			if (i - 1 >= 0 and line[i - 1] == Marks.EMPTY) or (j < n and line[j] == Marks.EMPTY):
				pot += sgn * cfg.w_ext
		elif run_len == 2:
			if (i - 1 >= 0 and line[i - 1] == Marks.EMPTY) or (j < n and line[j] == Marks.EMPTY):
				pot += sgn * cfg.w_live2
		i = j
	return [exact, pot]


# ----------------------------------------------------------------- candidates

## Empty cells within `candidate_radius` of any existing mark (center if the board is empty).
func _candidates() -> Array:
	var rad := cfg.candidate_radius
	var found := {}
	var any := false
	for r in size:
		for c in size:
			if board.get_cell(r, c) != Marks.EMPTY:
				any = true
				for dr in range(-rad, rad + 1):
					for dc in range(-rad, rad + 1):
						if dr == 0 and dc == 0:
							continue
						var nr := r + dr
						var nc := c + dc
						if board.in_bounds(nr, nc) and board.get_cell(nr, nc) == Marks.EMPTY:
							found[nr * size + nc] = Vector2i(nr, nc)
	if not any:
		return [Vector2i(size / 2, size / 2)]
	return found.values()


## Candidates ordered by a 1-ply heuristic value (best first) and capped to max_candidates,
## which sharpens alpha-beta pruning and bounds the branching factor.
func _ordered_candidates(to_move: int) -> Array:
	var cands := _candidates()
	if cands.size() <= 1:
		return cands
	var scored: Array = []
	for m: Vector2i in cands:
		var d := _apply(m.x, m.y, to_move)
		scored.append({"m": m, "v": _leaf(to_move, board.is_full())})
		_unapply(m.x, m.y, to_move, d)
	scored.sort_custom(func(a, b): return a["v"] > b["v"])
	var out: Array = []
	var limit: int = mini(scored.size(), cfg.max_candidates)
	for i in limit:
		out.append(scored[i]["m"])
	return out


# ----------------------------------------------------------------- init

## Builds the Zobrist table and computes running eval + hash from the current board.
func _init_eval() -> void:
	ztable = PackedInt64Array()
	ztable.resize(size * size * 2)
	var zr := RandomNumberGenerator.new()
	zr.seed = 0x1A2B3C4D5E6F # fixed -> reproducible TT keys
	for i in size * size * 2:
		var hi: int = zr.randi()
		var lo: int = zr.randi()
		ztable[i] = (hi << 32) | lo

	var tot := _full_eval()
	running_exact = tot[0]
	running_pot = tot[1]
	zkey = 0
	for r in size:
		for c in size:
			var v := board.get_cell(r, c)
			if v != Marks.EMPTY:
				zkey ^= ztable[(r * size + c) * 2 + (v - 1)]


## Whole-board (exact, potential) from scratch — scans each axis line once.
func _full_eval() -> Array:
	var e := 0
	var p := 0
	for dir: Vector2i in Scoring.DIRS:
		var dr := dir.x
		var dc := dir.y
		for r in size:
			for c in size:
				if not board.in_bounds(r - dr, c - dc): # start of a line in this axis
					var res := _score_line(_line_cells(r, c, dir))
					e += res[0]
					p += res[1]
	return [e, p]
