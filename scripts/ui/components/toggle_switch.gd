class_name ToggleSwitch
extends Button
## iOS-style on/off switch (settings). Emits `switched(on)`.

signal switched(on: bool)

var on := false


func configure(initial := false) -> ToggleSwitch:
	on = initial
	toggle_mode = true
	button_pressed = on
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(56, 32)
	toggled.connect(func(p: bool) -> void:
		on = p
		_restyle()
		switched.emit(on))
	_restyle()
	return self


func _restyle() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.color("accent") if on else ThemeManager.color("line")
	sb.set_corner_radius_all(16)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	queue_redraw()


func _draw() -> void:
	var d := 26.0
	var x := (size.x - d - 3.0) if on else 3.0
	draw_circle(Vector2(x + d * 0.5, size.y * 0.5), d * 0.5, ThemeManager.color("surface"))
