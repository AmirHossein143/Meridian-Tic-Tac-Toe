class_name Stepper
extends HBoxContainer
## Custom board-size stepper (3..19). Emits `value_changed(v)`.

signal value_changed(v: int)

var value := 9
var min_v := 3
var max_v := 19
var _label: Label
var _minus: Button
var _plus: Button


func configure(v: int, lo := 3, hi := 19) -> Stepper:
	min_v = lo
	max_v = hi
	value = clampi(v, lo, hi)
	add_theme_constant_override("separation", 6)
	alignment = BoxContainer.ALIGNMENT_CENTER

	_minus = _round_btn("-")
	_minus.pressed.connect(func() -> void: _step(-1))
	_label = UIKit.label("", "display", 22, "ink")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size.x = 110
	_plus = _round_btn("+")
	_plus.pressed.connect(func() -> void: _step(1))

	add_child(_minus)
	add_child(_label)
	add_child(_plus)
	_refresh()
	return self


func set_value_silent(v: int) -> void:
	value = clampi(v, min_v, max_v)
	_refresh()


func _step(d: int) -> void:
	var nv := clampi(value + d, min_v, max_v)
	if nv == value:
		return
	value = nv
	_refresh()
	value_changed.emit(value)


func _refresh() -> void:
	_label.text = "%d x %d" % [value, value]
	_minus.disabled = value <= min_v
	_plus.disabled = value >= max_v


func _round_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(ThemeManager.TAP, ThemeManager.TAP)
	b.add_theme_font_override("font", ThemeManager.font_display)
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.color("surface")
	sb.set_corner_radius_all(int(ThemeManager.TAP / 2))
	sb.set_border_width_all(1)
	sb.border_color = ThemeManager.color("hairline")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", ThemeManager.color("ink"))
	b.add_theme_color_override("font_disabled_color", ThemeManager.color("ink_3"))
	return b
