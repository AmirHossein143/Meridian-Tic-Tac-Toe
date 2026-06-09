class_name HowToPlay
extends Control
## Visual rules guide. Reusable: hosted full-screen from the menu (default back -> menu) or as
## an in-game overlay (host sets `on_back` before adding it). Draws real boards via BoardView,
## and the worked example's numbers are driven by Scoring.score() so it can never drift.

var on_back := Callable()


func _ready() -> void:
	if not on_back.is_valid():
		on_back = func() -> void: MeridianApp.instance.goto("menu")

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = ThemeManager.color("bg")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# Fixed header (always visible)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var hm := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		hm.add_theme_constant_override("margin_" + s, 16)
	hm.add_child(header)
	var back := UIKit.button("< Back", "ghost")
	back.pressed.connect(func() -> void: on_back.call())
	header.add_child(back)
	var title := UIKit.label("How to play", "display", 24, "ink")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(title)
	root.add_child(hm)

	# Scrollable body, centred max-width column
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	col.custom_minimum_size.x = UIKit.clamp_width(560.0)
	center.add_child(col)

	col.add_child(_gap(4))
	col.add_child(_section_goal())
	col.add_child(_section_directions())
	col.add_child(_section_longer())
	col.add_child(_section_winning())
	col.add_child(_gap(8))


# ---- sections ------------------------------------------------------------------------------

func _section_goal() -> Control:
	var s := _section("1 — Fill the whole board", "There's no early win. Players take turns until every cell has a mark, and only then do we count the score.")
	s.add_child(_centered(_demo(_full5(), [], 150.0)))
	return s


func _section_directions() -> Control:
	var s := _section("2 — Lines score in 4 directions", "A scoring line can run across, down, or along either diagonal.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.add_child(_demo_caption([[1, 1, 1], [0, 0, 0], [0, 0, 0]], [Vector2i(0, 0), Vector2i(0, 2)], "Across"))
	grid.add_child(_demo_caption([[1, 0, 0], [1, 0, 0], [1, 0, 0]], [Vector2i(0, 0), Vector2i(2, 0)], "Down"))
	grid.add_child(_demo_caption([[1, 0, 0], [0, 1, 0], [0, 0, 1]], [Vector2i(0, 0), Vector2i(2, 2)], "Diagonal"))
	grid.add_child(_demo_caption([[0, 0, 1], [0, 1, 0], [1, 0, 0]], [Vector2i(0, 2), Vector2i(2, 0)], "Diagonal"))
	s.add_child(grid)
	return s


func _section_longer() -> Control:
	var s := _section("3 — Longer lines are worth more", "A run of L in a row scores L points (3 -> 3, 4 -> 4, 5 -> 5, and so on). Only maximal runs of 3 or more count — a lone pair scores nothing.")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_demo_caption([[1, 1, 1], [0, 0, 0], [0, 0, 0]], [Vector2i(0, 0), Vector2i(0, 2)], "= 3"))
	row.add_child(_demo_caption(_top_row(4), [Vector2i(0, 0), Vector2i(0, 3)], "= 4"))
	row.add_child(_demo_caption(_top_row(5), [Vector2i(0, 0), Vector2i(0, 4)], "= 5"))
	s.add_child(row)
	return s


func _section_winning() -> Control:
	var rows := [[1, 1, 1, 2, 1], [2, 2, 1, 2, 1], [1, 2, 2, 2, 1], [2, 1, 1, 2, 2], [1, 1, 2, 1, 2]]
	var board := Board.from_rows(rows)
	var sc := Scoring.score(board)
	var xt: int = sc[Marks.X]["total"]
	var ot: int = sc[Marks.O]["total"]
	var verdict := "it's a draw"
	if xt > ot:
		verdict = "X wins"
	elif ot > xt:
		verdict = "O wins"

	var bands: Array = []
	for owner in [Marks.X, Marks.O]:
		for run: Dictionary in sc[owner]["runs"]:
			bands.append({"cells": run["cells"], "owner": owner})

	var s := _section("4 — Most points wins (tie = draw)", "When the board is full, the higher total wins. Here the bands show every scoring run:")
	s.add_child(_centered(_demo(rows, bands, 170.0)))
	var line := UIKit.label("X %d   -   O %d    ->   %s" % [xt, ot, verdict], "mono", 16, "ink")
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(line)
	return s


# ---- builders ------------------------------------------------------------------------------

func _section(heading: String, desc: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(UIKit.label(heading, "display", 20, "ink"))
	var p := UIKit.label(desc, "ui", 15, "ink_2")
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.size_flags_horizontal = Control.SIZE_FILL
	v.add_child(p)
	return v


func _demo(rows: Array, runs: Array, px: float) -> BoardView:
	var bv := BoardView.new()
	bv.custom_minimum_size = Vector2(px, px)
	bv.set_board(Board.from_rows(rows))
	bv.interactive = false
	if not runs.is_empty():
		bv.set_runs(runs)
	bv.ready.connect(_make_passthrough.bind(bv), CONNECT_ONE_SHOT)
	return bv


func _demo_caption(rows: Array, run_endpoints: Array, caption: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var runs: Array = []
	if not run_endpoints.is_empty():
		runs = [{"cells": run_endpoints, "owner": Marks.X}]
	var bv := _demo(rows, runs, 116.0)
	bv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(bv)
	var cap := UIKit.label(caption, "ui_semibold", 14, "ink_2")
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	return v


func _centered(c: Control) -> Control:
	var box := CenterContainer.new()
	box.add_child(c)
	return box


func _make_passthrough(bv: BoardView) -> void:
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _full5() -> Array:
	return [[1, 2, 1, 2, 1], [2, 1, 2, 1, 2], [1, 1, 2, 2, 1], [2, 2, 1, 1, 2], [1, 2, 2, 1, 1]]


func _top_row(n: int) -> Array:
	var rows: Array = []
	for r in n:
		var row: Array = []
		for c in n:
			row.append(1 if r == 0 else 0)
		rows.append(row)
	return rows


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
