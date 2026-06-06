class_name Segmented
extends PanelContainer
## Pill segmented control (mode / difficulty toggles). Emits `selected(index)`.

signal selected(index: int)

var current := 0
var _buttons: Array[Button] = []


func configure(options: Array, initial := 0) -> Segmented:
	current = initial
	var bg := StyleBoxFlat.new()
	bg.bg_color = ThemeManager.color("surface_2")
	bg.set_corner_radius_all(int(ThemeManager.R_PILL))
	bg.set_border_width_all(1)
	bg.border_color = ThemeManager.color("hairline")
	bg.content_margin_left = 4
	bg.content_margin_right = 4
	bg.content_margin_top = 4
	bg.content_margin_bottom = 4
	add_theme_stylebox_override("panel", bg)

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	for i in options.size():
		var b := Button.new()
		b.text = str(options[i])
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = ThemeManager.TAP
		b.add_theme_font_override("font", ThemeManager.font_ui_semibold)
		b.add_theme_font_size_override("font_size", 16)
		var idx := i
		b.pressed.connect(func() -> void: _choose(idx))
		_buttons.append(b)
		box.add_child(b)
	_restyle()
	return self


func set_current(i: int) -> void:
	current = i
	_restyle()


func _choose(i: int) -> void:
	if i == current:
		return
	current = i
	_restyle()
	selected.emit(i)


func _restyle() -> void:
	for i in _buttons.size():
		var b := _buttons[i]
		var sel := i == current
		var sb := StyleBoxFlat.new()
		sb.bg_color = ThemeManager.color("surface") if sel else Color(0, 0, 0, 0)
		sb.set_corner_radius_all(int(ThemeManager.R_PILL))
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var fg := ThemeManager.color("ink") if sel else ThemeManager.color("ink_2")
		b.add_theme_color_override("font_color", fg)
		b.add_theme_color_override("font_hover_color", fg)
		b.add_theme_color_override("font_pressed_color", fg)
