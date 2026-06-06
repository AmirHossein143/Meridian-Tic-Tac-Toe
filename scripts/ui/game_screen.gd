class_name GameScreen
extends Control
## In-game screen: live scoreboard, turn pill, the board, and undo/restart/menu. Drives the
## GameState and (in vs-AI) the off-thread AIRunner, then shows the game-over breakdown.

var state: GameState
var runner: AIRunner
var vs_ai := true
var difficulty := "hard"
var board_n := 9
var ai_thinking := false
var _params: Dictionary = {}

var board_view: BoardView
var x_card: ScoreCard
var o_card: ScoreCard
var turn_glyph: MarkGlyph
var turn_label: Label
var _over_layer: Control


func init_screen(params: Dictionary) -> void:
	_params = params
	vs_ai = str(params.get("mode", "ai")) == "ai"
	difficulty = str(params.get("difficulty", "hard"))
	board_n = int(params.get("board_size", 9))
	_build()
	_start_game()


# ---------------------------------------------------------------- layout

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)

	# Top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var menu_btn := UIKit.button("Menu", "ghost")
	menu_btn.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	top.add_child(menu_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var undo_btn := UIKit.button("Undo", "soft")
	undo_btn.pressed.connect(_on_undo)
	top.add_child(undo_btn)
	var restart_btn := UIKit.button("Restart", "soft")
	restart_btn.pressed.connect(_on_restart)
	top.add_child(restart_btn)
	col.add_child(top)

	# Scoreboard
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 12)
	x_card = ScoreCard.new().configure(Marks.X, "You" if vs_ai else "Player X")
	o_card = ScoreCard.new().configure(Marks.O, "AI" if vs_ai else "Player O")
	scores.add_child(x_card)
	scores.add_child(o_card)
	col.add_child(scores)

	# Turn pill (centered)
	var pill_center := CenterContainer.new()
	var pill := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = ThemeManager.color("surface")
	psb.set_corner_radius_all(int(ThemeManager.R_PILL))
	psb.set_border_width_all(1)
	psb.border_color = ThemeManager.color("hairline")
	psb.content_margin_left = 16
	psb.content_margin_right = 18
	psb.content_margin_top = 8
	psb.content_margin_bottom = 8
	pill.add_theme_stylebox_override("panel", psb)
	var pill_box := HBoxContainer.new()
	pill_box.add_theme_constant_override("separation", 8)
	turn_glyph = MarkGlyph.new().configure(Marks.X, 22)
	turn_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	turn_label = UIKit.label("", "ui_semibold", 15, "ink")
	turn_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill_box.add_child(turn_glyph)
	pill_box.add_child(turn_label)
	pill.add_child(pill_box)
	pill_center.add_child(pill)
	col.add_child(pill_center)

	# Board (square, centered, fills remaining space)
	var board_area := Control.new()
	board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(board_area)
	var ar := AspectRatioContainer.new()
	ar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ar.ratio = 1.0
	ar.stretch_mode = AspectRatioContainer.STRETCH_FIT
	board_area.add_child(ar)
	board_view = BoardView.new()
	board_view.cell_pressed.connect(_on_cell_pressed)
	ar.add_child(board_view)

	# AI runner
	runner = AIRunner.new()
	add_child(runner)
	runner.move_ready.connect(_on_ai_move)
	runner.thinking.connect(_on_ai_thinking)


# ---------------------------------------------------------------- game flow

func _start_game() -> void:
	if is_instance_valid(_over_layer):
		_over_layer.queue_free()
		_over_layer = null
	state = GameState.new(board_n, GameState.Mode.VS_AI if vs_ai else GameState.Mode.TWO_PLAYER)
	state.move_made.connect(_on_move_made)
	state.game_over.connect(_on_game_over)
	ai_thinking = false
	board_view.set_board(state.board)
	board_view.clear_overlays()
	board_view.interactive = true
	_update_scores()
	_update_turn_pill()
	_maybe_ai_move()


func _on_cell_pressed(cell: Vector2i) -> void:
	if state.over or ai_thinking:
		return
	if vs_ai and state.current != Marks.X:
		return
	state.apply_move(cell.x, cell.y)


func _on_move_made(r: int, c: int, _player: int) -> void:
	board_view.set_last_move(Vector2i(r, c))
	board_view.queue_redraw()
	_update_scores()
	_update_turn_pill()
	if not state.over:
		call_deferred("_maybe_ai_move")


func _maybe_ai_move() -> void:
	if state.over or not vs_ai or ai_thinking:
		return
	if state.current != state.ai_player:
		return
	ai_thinking = true
	board_view.interactive = false
	_update_turn_pill()
	runner.request_move(state.board, state.current, _ai_config())


func _on_ai_thinking(cell: Vector2i) -> void:
	if ai_thinking:
		board_view.set_thinking_cell(cell)


func _on_ai_move(mv: Vector2i) -> void:
	ai_thinking = false
	board_view.set_thinking_cell(Vector2i(-1, -1))
	board_view.interactive = true
	if state.over:
		return
	if not state.apply_move(mv.x, mv.y):
		# Defensive: if the AI ever returns an unusable cell, take any legal one.
		var empties := state.board.empties()
		if not empties.is_empty():
			state.apply_move(empties[0].x, empties[0].y)


func _ai_config() -> AIConfig:
	match difficulty:
		"easy": return AIConfig.easy()
		"medium": return AIConfig.medium()
		_: return AIConfig.hard()


func _on_undo() -> void:
	if ai_thinking:
		return
	if is_instance_valid(_over_layer):
		_over_layer.queue_free()
		_over_layer = null
	if state.history.is_empty():
		return
	state.undo_last()
	if vs_ai and not state.history.is_empty() and state.current == state.ai_player:
		state.undo_last() # step back past the AI reply so it's the human's turn again
	board_view.set_board(state.board)
	board_view.set_runs([])
	board_view.set_last_move(state.last_move())
	board_view.interactive = true
	_update_scores()
	_update_turn_pill()


func _on_restart() -> void:
	_start_game()


# ---------------------------------------------------------------- views

func _update_scores() -> void:
	var s := Scoring.score(state.board)
	x_card.set_value(s[Marks.X]["total"])
	o_card.set_value(s[Marks.O]["total"])
	x_card.set_active(not state.over and state.current == Marks.X)
	o_card.set_active(not state.over and state.current == Marks.O)


func _update_turn_pill() -> void:
	if state.over:
		turn_glyph.visible = false
		turn_label.text = "Game over"
		return
	turn_glyph.visible = true
	turn_glyph.set_mark(state.current)
	if ai_thinking:
		turn_label.text = "Thinking..."
	elif vs_ai:
		turn_label.text = "Your turn" if state.current == Marks.X else "AI is playing"
	else:
		turn_label.text = ("X" if state.current == Marks.X else "O") + " to move"


# ---------------------------------------------------------------- game over

func _on_game_over(result: Dictionary) -> void:
	board_view.interactive = false
	var s: Dictionary = result["score"]
	var bands: Array = []
	for owner in [Marks.X, Marks.O]:
		for run: Dictionary in s[owner]["runs"]:
			bands.append({"cells": run["cells"], "owner": owner})
	board_view.set_runs(bands)
	_update_scores()
	_update_turn_pill()
	_show_game_over(result)


func _show_game_over(result: Dictionary) -> void:
	_over_layer = Control.new()
	_over_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_over_layer)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.38)
	_over_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_over_layer.add_child(center)

	var panel := UIKit.panel("surface", "hairline", 20.0, 28)
	panel.custom_minimum_size.x = 460
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var winner: int = result["winner"]
	var wtext := "Draw"
	if winner == Marks.X:
		wtext = "You win" if vs_ai else "X wins"
	elif winner == Marks.O:
		wtext = "AI wins" if vs_ai else "O wins"
	var wlabel := UIKit.label(wtext, "display_bold", 32, "ink")
	wlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(wlabel)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	cols.add_child(_breakdown_col(Marks.X, result["score"][Marks.X], winner == Marks.X, "You" if vs_ai else "X"))
	var divider := ColorRect.new()
	divider.color = ThemeManager.color("hairline")
	divider.custom_minimum_size.x = 1
	cols.add_child(divider)
	cols.add_child(_breakdown_col(Marks.O, result["score"][Marks.O], winner == Marks.O, "AI" if vs_ai else "O"))
	v.add_child(cols)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var again := UIKit.button("Play again", "primary")
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(_on_restart)
	var menu := UIKit.button("Menu", "ghost")
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	row.add_child(again)
	row.add_child(menu)
	v.add_child(row)


func _breakdown_col(owner: int, rec: Dictionary, is_winner: bool, name_text: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(MarkGlyph.new().configure(owner, 22))
	head.add_child(UIKit.label(name_text, "ui_semibold", 14, "ink_2"))
	if is_winner:
		head.add_child(_winner_tag())
	col.add_child(head)

	col.add_child(UIKit.label(str(rec["total"]), "display_bold", 30, "ink"))
	col.add_child(_bd_row("3-lines", rec["counts"][3]))
	col.add_child(_bd_row("4-lines", rec["counts"][4]))
	col.add_child(_bd_row("5+ lines", rec["counts"][5]))
	return col


func _bd_row(text: String, count: int) -> Control:
	var row := HBoxContainer.new()
	var l := UIKit.label(text, "ui", 14, "ink_2")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(UIKit.label("x %d" % count, "mono", 14, "ink"))
	return row


func _winner_tag() -> Control:
	var tag := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = ThemeManager.color("accent")
	s.set_corner_radius_all(int(ThemeManager.R_PILL))
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	tag.add_theme_stylebox_override("panel", s)
	tag.add_child(UIKit.label("WINS", "ui_semibold", 11, "on_accent"))
	return tag
