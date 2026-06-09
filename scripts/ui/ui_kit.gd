class_name UIKit
extends RefCounted
## Factory helpers that build design-system controls (pill buttons, labels, panels) styled
## from ThemeManager. Controls are styled once at creation; the App rebuilds the current
## screen on a theme change so colours stay in sync.

static func button(text: String, kind := "primary", big := false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = 56.0 if big else ThemeManager.TAP
	b.add_theme_font_override("font", ThemeManager.font_ui_semibold)
	b.add_theme_font_size_override("font_size", 19 if big else 16)
	_style_button(b, kind, big)
	return b


static func _style_button(b: Button, kind: String, big: bool) -> void:
	var bg: Color
	var bg_hover: Color
	var fg: Color
	var border := 0
	var border_col := Color(0, 0, 0, 0)
	match kind:
		"ghost":
			bg = Color(0, 0, 0, 0)
			bg_hover = ThemeManager.color("surface_2")
			fg = ThemeManager.color("ink")
			border = 1
			border_col = ThemeManager.color("line")
		"soft":
			bg = ThemeManager.color("surface_2")
			bg_hover = ThemeManager.color("accent_soft")
			fg = ThemeManager.color("ink")
		"danger":
			bg = Color(0, 0, 0, 0)
			bg_hover = ThemeManager.color("run_white")
			bg_hover.a = 0.14
			fg = ThemeManager.color("run_white")
			border = 1
			border_col = ThemeManager.color("run_white")
			border_col.a = 0.45
		_: # primary
			bg = ThemeManager.color("accent")
			bg_hover = ThemeManager.color("accent_2")
			fg = ThemeManager.color("on_accent")
	var pad := 36 if big else 22
	b.add_theme_stylebox_override("normal", _pill(bg, pad, border, border_col))
	b.add_theme_stylebox_override("hover", _pill(bg_hover, pad, border, border_col))
	b.add_theme_stylebox_override("pressed", _pill(bg_hover, pad, border, border_col))
	b.add_theme_stylebox_override("disabled", _pill(Color(bg, 0.5), pad, border, border_col))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.5))


static func _pill(bg: Color, pad: int, border: int, border_col: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(ThemeManager.R_PILL))
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_col
	return s


static func label(text: String, role := "ui", fsize := 16, color_name := "ink") -> Label:
	var l := Label.new()
	l.text = text
	var f: FontFile = ThemeManager.font_ui
	match role:
		"display": f = ThemeManager.font_display
		"display_bold": f = ThemeManager.font_display_bold
		"ui_semibold": f = ThemeManager.font_ui_semibold
		"mono": f = ThemeManager.font_mono
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", ThemeManager.color(color_name))
	return l


## Clamps a desired panel/column width to the current window so fixed-width layouts never
## overflow (and clip) on narrow / portrait windows.
static func clamp_width(desired: float) -> float:
	var ml := Engine.get_main_loop()
	if ml is SceneTree and (ml as SceneTree).root != null:
		var w := (ml as SceneTree).root.get_visible_rect().size.x
		if w > 0.0:
			return minf(desired, w - 48.0)
	return desired


static func panel(bg_name := "surface", border_name := "hairline", radius := 20.0, pad := 24) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = ThemeManager.color(bg_name)
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(1)
	s.border_color = ThemeManager.color(border_name)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	p.add_theme_stylebox_override("panel", s)
	return p
