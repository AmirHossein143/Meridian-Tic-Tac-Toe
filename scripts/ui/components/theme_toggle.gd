class_name ThemeToggle
extends Button
## Compact light/dark toggle (sun in dark mode -> tap for light; moon in light mode -> tap for
## dark). Calls `on_toggle.call(target_mode)`; the host decides how to apply it (directly, or
## preserving an in-progress game). 44x44 minimum.

var on_toggle := Callable()


func configure(cb: Callable) -> ThemeToggle:
	on_toggle = cb
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(ThemeManager.TAP, ThemeManager.TAP)
	tooltip_text = "Toggle light / dark"
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.color("surface_2")
	sb.set_corner_radius_all(int(ThemeManager.R_MD))
	sb.set_border_width_all(1)
	sb.border_color = ThemeManager.color("hairline")
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("hover", sb)
	add_theme_stylebox_override("pressed", sb)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_press)
	ThemeManager.changed.connect(queue_redraw)
	return self


func _on_press() -> void:
	if on_toggle.is_valid():
		on_toggle.call("light" if ThemeManager.is_dark() else "dark")


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.24
	var ink := ThemeManager.color("ink")
	if ThemeManager.is_dark():
		# Currently dark -> tapping switches to light: show a sun.
		draw_circle(c, r * 0.62, ink)
		var lw := maxf(r * 0.16, 1.5)
		for i in 8:
			var a := i * PI / 4.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * (r * 0.85), c + d * (r * 1.25), ink, lw, true)
	else:
		# Currently light -> tapping switches to dark: show a crescent moon.
		draw_circle(c, r, ink)
		draw_circle(c + Vector2(r * 0.55, -r * 0.28), r, ThemeManager.color("surface_2"))
