class_name GameSetup
extends Control
## Choose mode (vs AI / 2-player), difficulty (AI only), and board size (presets + 3..19
## stepper), then Start. Selections persist immediately so a theme-driven rebuild restores them.

const PRESETS := [3, 5, 9, 13, 15, 19]

var mode := "ai"
var difficulty := "hard"
var board_size := 9

var _diff_block: VBoxContainer
var _diff_seg: Segmented
var _stepper: Stepper
var _preset_cards := {}


func _ready() -> void:
	mode = str(Settings.get_value("mode", "ai"))
	difficulty = str(Settings.get_value("difficulty", "hard"))
	board_size = int(Settings.get_value("board_size", 9))

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.custom_minimum_size.x = UIKit.clamp_width(540.0)
	center.add_child(col)

	col.add_child(_gap(20))

	# Header: back + theme toggle + title
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var back := UIKit.button("< Back", "ghost", false, "back")
	back.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	header.add_child(back)
	var theme_tog := ThemeToggle.new().configure(func(t: String) -> void: ThemeManager.set_theme_mode(t))
	theme_tog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(theme_tog)
	var title := UIKit.label("New game", "display", 26, "ink")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)
	col.add_child(header)

	# Mode
	col.add_child(UIKit.label("Mode", "ui_semibold", 14, "ink_2"))
	var mode_seg := Segmented.new().configure(["vs AI", "2 Players"], 0 if mode == "ai" else 1)
	mode_seg.selected.connect(_on_mode)
	col.add_child(mode_seg)

	# Difficulty (AI only)
	_diff_block = VBoxContainer.new()
	_diff_block.add_theme_constant_override("separation", 8)
	_diff_block.add_child(UIKit.label("Difficulty", "ui_semibold", 14, "ink_2"))
	var diff_idx := ["easy", "medium", "hard"].find(difficulty)
	_diff_seg = Segmented.new().configure(["Easy", "Medium", "Hard"], maxi(diff_idx, 0))
	_diff_seg.selected.connect(_on_difficulty)
	_diff_block.add_child(_diff_seg)
	col.add_child(_diff_block)
	_diff_block.visible = mode == "ai"

	# Board size
	col.add_child(UIKit.label("Board size", "ui_semibold", 14, "ink_2"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for n: int in PRESETS:
		grid.add_child(_make_preset(n))
	col.add_child(grid)

	_stepper = Stepper.new().configure(board_size, 3, 19)
	_stepper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stepper.value_changed.connect(func(v: int) -> void: _select_size(v, false))
	col.add_child(_stepper)

	col.add_child(_gap(6))
	var start := UIKit.button("Start game", "primary", true, "start")
	start.pressed.connect(_on_start)
	col.add_child(start)
	col.add_child(_gap(16))

	_refresh_presets()


func _on_mode(i: int) -> void:
	mode = "ai" if i == 0 else "local"
	Settings.set_value("mode", mode)
	_diff_block.visible = mode == "ai"


func _on_difficulty(i: int) -> void:
	difficulty = ["easy", "medium", "hard"][i]
	Settings.set_value("difficulty", difficulty)


func _make_preset(n: int) -> Control:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	# Children must not intercept clicks — the whole card is one hit target (card.gui_input).
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mini := MiniBoard.new().configure(n, 64)
	mini.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := UIKit.label("%d x %d" % [n, n], "ui_semibold", 14, "ink")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(mini)
	v.add_child(lbl)
	card.add_child(v)
	card.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
				or (e is InputEventScreenTouch and e.pressed):
			Audio.play("preset")
			_select_size(n, true))
	_preset_cards[n] = card
	return card


func _select_size(n: int, from_preset: bool) -> void:
	board_size = clampi(n, 3, 19)
	Settings.set_value("board_size", board_size)
	if from_preset:
		_stepper.set_value_silent(board_size)
	_refresh_presets()


func _refresh_presets() -> void:
	for n: int in _preset_cards.keys():
		var card: PanelContainer = _preset_cards[n]
		var sel := n == board_size
		var s := StyleBoxFlat.new()
		s.bg_color = ThemeManager.color("accent_soft") if sel else ThemeManager.color("surface")
		s.set_corner_radius_all(int(ThemeManager.R_MD))
		s.set_border_width_all(2 if sel else 1)
		s.border_color = ThemeManager.color("accent") if sel else ThemeManager.color("hairline")
		s.content_margin_left = 14
		s.content_margin_right = 14
		s.content_margin_top = 12
		s.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", s)


func _on_start() -> void:
	MeridianApp.instance.goto("game", {"mode": mode, "difficulty": difficulty, "board_size": board_size})


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
