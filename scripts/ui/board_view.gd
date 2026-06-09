class_name BoardView
extends Control
## Custom-drawn board — a faithful port of refrence/board.js render() into Godot _draw().
## Square, interior grid lines only (no outer frame); X = two crossing strokes, O = a ring,
## both centred; amber last-move highlight; run-band overlays at game over; an animated
## "thinking" pulse on the AI's target cell. Geometry matches board.js (VB = 1000) scaled to
## the control's square. Colours come from ThemeManager (X = accent, O = terracotta).

signal cell_pressed(cell: Vector2i)

const VB := 1000.0

var board: Board = null
var last_move := Vector2i(-1, -1)
var thinking_cell := Vector2i(-1, -1)
var runs: Array = [] ## Array of { "cells": Array[Vector2i], "owner": int } for game-over bands
var interactive := true

var _pulse_t := 0.0
var _pop_cell := Vector2i(-1, -1)
var _pop_t := 0.0
const _POP_DUR := 0.16


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	ThemeManager.changed.connect(queue_redraw)
	set_process(false)


func set_board(b: Board) -> void:
	board = b
	_pop_cell = Vector2i(-1, -1)
	_update_anim()
	queue_redraw()


## `pop` triggers the placement animation; pass false for undo / restore (re-highlight only).
func set_last_move(cell: Vector2i, pop := true) -> void:
	last_move = cell
	if pop and cell.x >= 0:
		_pop_cell = cell
		_pop_t = 0.0
		_update_anim()
	queue_redraw()


func set_thinking_cell(cell: Vector2i) -> void:
	thinking_cell = cell
	_update_anim()
	queue_redraw()


func _update_anim() -> void:
	set_process(thinking_cell.x >= 0 or _pop_cell.x >= 0)


func set_runs(r: Array) -> void:
	runs = r
	queue_redraw()


func clear_overlays() -> void:
	last_move = Vector2i(-1, -1)
	thinking_cell = Vector2i(-1, -1)
	runs = []
	_pop_cell = Vector2i(-1, -1)
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_t += delta
	if _pop_cell.x >= 0:
		_pop_t += delta
		if _pop_t >= _POP_DUR:
			_pop_cell = Vector2i(-1, -1)
	queue_redraw()
	if thinking_cell.x < 0 and _pop_cell.x < 0:
		set_process(false)


# ---- geometry (mirrors board.js) -----------------------------------------------------------

func _metrics() -> Dictionary:
	var n := board.size if board != null else 3
	var side: float = minf(size.x, size.y)
	var s := side / VB
	var ox := (size.x - side) * 0.5
	var oy := (size.y - side) * 0.5
	var pad: float = maxf(18.0, 60.0 / n + 14.0) * s
	var cell := (side - 2.0 * pad) / n
	return {
		"n": n, "s": s, "ox": ox, "oy": oy, "pad": pad, "cell": cell,
		"rg": cell * 0.30,
		"sw": maxf(cell * 0.11, 3.0 * s),
	}


func _edge(m: Dictionary, i: int, axis_x: bool) -> float:
	var base: float = m["ox"] if axis_x else m["oy"]
	return base + m["pad"] + i * m["cell"]


func _center(m: Dictionary, cell: Vector2i) -> Vector2:
	# cell = (row, col): screen x follows column, screen y follows row.
	return Vector2(
		m["ox"] + m["pad"] + (cell.y + 0.5) * m["cell"],
		m["oy"] + m["pad"] + (cell.x + 0.5) * m["cell"])


func _draw() -> void:
	if board == null:
		return
	var m := _metrics()
	var n: int = m["n"]
	var cell: float = m["cell"]

	# 1) last-move highlight (under everything)
	if last_move.x >= 0:
		var hp := Vector2(_edge(m, last_move.y, true) + cell * 0.06, _edge(m, last_move.x, false) + cell * 0.06)
		var w := cell * 0.88
		var sb := StyleBoxFlat.new()
		sb.bg_color = ThemeManager.color("highlight")
		sb.bg_color.a = 0.22
		sb.set_border_width_all(int(maxf(3.0 * m["s"], 1.0)))
		sb.border_color = ThemeManager.color("highlight")
		sb.set_corner_radius_all(int(cell * 0.16))
		draw_style_box(sb, Rect2(hp, Vector2(w, w)))

	# 2) interior grid lines only
	var grid := ThemeManager.color("grid")
	var gw: float = maxf(2.4 * m["s"], 1.0)
	for i in range(1, n):
		draw_line(Vector2(_edge(m, i, true), _edge(m, 0, false)), Vector2(_edge(m, i, true), _edge(m, n, false)), grid, gw, true)
		draw_line(Vector2(_edge(m, 0, true), _edge(m, i, false)), Vector2(_edge(m, n, true), _edge(m, i, false)), grid, gw, true)

	# 3) run bands (game over)
	for run: Dictionary in runs:
		var cells: Array = run["cells"]
		if cells.size() < 2:
			continue
		var col: Color = ThemeManager.color("x") if int(run["owner"]) == Marks.X else ThemeManager.color("o")
		col.a = 0.30
		draw_line(_center(m, cells[0]), _center(m, cells[cells.size() - 1]), col, m["rg"] * 1.7, true)

	# 4) thinking pulse (animated, on an empty target cell)
	if thinking_cell.x >= 0:
		var t := sin(_pulse_t * (TAU / 1.5)) * 0.5 + 0.5 # 1.5s period
		var pulse_w := cell * 0.64
		var grow := lerpf(0.78, 1.04, t)
		var cx := _center(m, thinking_cell)
		var pw := pulse_w * grow
		var pb := StyleBoxFlat.new()
		pb.bg_color = ThemeManager.color("accent")
		pb.bg_color.a = lerpf(0.12, 0.40, t)
		pb.set_corner_radius_all(int(cell * 0.14))
		draw_style_box(pb, Rect2(cx - Vector2(pw, pw) * 0.5, Vector2(pw, pw)))

	# 5) marks
	var x_col := ThemeManager.color("x")
	var o_col := ThemeManager.color("o")
	var rg: float = m["rg"]
	var sw: float = m["sw"]
	for r in n:
		for c in n:
			var v := board.get_cell(r, c)
			if v == Marks.EMPTY:
				continue
			var ctr := _center(m, Vector2i(r, c))
			var rg2 := rg
			var sw2 := sw
			if _pop_cell.x == r and _pop_cell.y == c:
				var pt := clampf(_pop_t / _POP_DUR, 0.0, 1.0)
				var ps := lerpf(0.5, 1.0, 1.0 - pow(1.0 - pt, 3.0)) # ease-out
				rg2 = rg * ps
				sw2 = maxf(sw * ps, 1.0)
			if v == Marks.X:
				draw_line(ctr + Vector2(-rg2, -rg2), ctr + Vector2(rg2, rg2), x_col, sw2, true)
				draw_line(ctr + Vector2(rg2, -rg2), ctr + Vector2(-rg2, rg2), x_col, sw2, true)
			else:
				draw_arc(ctr, rg2, 0.0, TAU, 48, o_col, sw2, true)


# ---- input ---------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not interactive or board == null:
		return
	var pos := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	if pos == Vector2.INF:
		return
	var m := _metrics()
	var c := int(floor((pos.x - m["ox"] - m["pad"]) / m["cell"]))
	var r := int(floor((pos.y - m["oy"] - m["pad"]) / m["cell"]))
	if r >= 0 and c >= 0 and r < m["n"] and c < m["n"]:
		cell_pressed.emit(Vector2i(r, c))
		accept_event()
