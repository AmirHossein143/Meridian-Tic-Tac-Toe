class_name Scoring
extends RefCounted
## Canonical scoring — a faithful port of refrence/board.js `score()`.
##
## Scan the 4 axes. In each axis, every MAXIMAL run of >= 3 identical marks scores its
## own length (run of L -> L points). A run is maximal when its predecessor in that axis
## is off-board, empty, or a different mark. Per player we return the total, the list of
## runs (cells + length), and 3/4/5+ bucket counts (the 5 bucket means "5 or more").
##
## NOTE: this is board.js's formula, NOT PROTOTYPE.py's (L-1)(L-2)/2 over-count.

## The 4 scan axes in (d_row, d_col). These cover the same lines as board.js DIRS
## [[1,0],[0,1],[1,1],[1,-1]]; the resulting maximal-run set is identical.
const DIRS := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)]


## Returns { Marks.X: rec, Marks.O: rec } where
## rec = { "total": int, "runs": Array[{"cells": Array[Vector2i], "len": int}], "counts": {3,4,5} }.
static func score(board: Board) -> Dictionary:
	var size := board.size
	var out := {
		Marks.X: {"total": 0, "runs": [], "counts": {3: 0, 4: 0, 5: 0}},
		Marks.O: {"total": 0, "runs": [], "counts": {3: 0, 4: 0, 5: 0}},
	}
	for dir in DIRS:
		var dr: int = dir.x
		var dc: int = dir.y
		for r in size:
			for c in size:
				var v := board.get_cell(r, c)
				if v == Marks.EMPTY:
					continue
				# Skip cells that are not the start of a run in this axis.
				var pr := r - dr
				var pc := c - dc
				if pr >= 0 and pc >= 0 and pr < size and pc < size and board.get_cell(pr, pc) == v:
					continue
				# Walk forward collecting the maximal run.
				var run_cells: Array = [Vector2i(r, c)]
				var nr := r + dr
				var nc := c + dc
				while nr >= 0 and nc >= 0 and nr < size and nc < size and board.get_cell(nr, nc) == v:
					run_cells.append(Vector2i(nr, nc))
					nr += dr
					nc += dc
				var length := run_cells.size()
				if length >= 3:
					var rec: Dictionary = out[v]
					rec["runs"].append({"cells": run_cells, "len": length})
					rec["total"] += length
					rec["counts"][mini(length, 5)] += 1
	return out


## Points each run-length bucket contributes, derived from one player's score() record
## (single source of truth). rec = { "total", "runs":[{cells,len}], "counts":{3,4,5} }.
## Returns { 3: c3*3, 4: c4*4, 5: sum of len for runs of len >= 5 }. A run of L always adds L,
## so the 5+ bucket sums actual lengths (a len-6 run = 6, not 5) and the three buckets sum to total.
static func bucket_points(rec: Dictionary) -> Dictionary:
	var p := {3: 0, 4: 0, 5: 0}
	for run: Dictionary in rec["runs"]:
		var length: int = run["len"]
		p[mini(length, 5)] += length
	return p


## Convenience: { Marks.X: total, Marks.O: total }.
static func totals(board: Board) -> Dictionary:
	var s := score(board)
	return {Marks.X: s[Marks.X]["total"], Marks.O: s[Marks.O]["total"]}


## Signed differential from `mark`'s perspective (mark_total - opponent_total).
static func differential(board: Board, mark: int) -> int:
	var t := totals(board)
	return t[mark] - t[Marks.other(mark)]
