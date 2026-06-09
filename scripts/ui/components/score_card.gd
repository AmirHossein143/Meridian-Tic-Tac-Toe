class_name ScoreCard
extends PanelContainer
## A player's live score card (mark glyph + name + big number). Highlights when it's that
## player's turn.

var mark: int
var _num: Label
var _shown := 0
var _tween: Tween


func configure(m: int, name_text: String) -> ScoreCard:
	mark = m
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN

	var glyph := MarkGlyph.new().configure(m, 30.0)

	var meta := VBoxContainer.new()
	meta.add_theme_constant_override("separation", 0)
	meta.add_child(UIKit.label(name_text, "ui_semibold", 13, "ink_2"))
	_num = UIKit.label("0", "display_bold", 38, "ink")
	meta.add_child(_num)

	row.add_child(glyph)
	row.add_child(meta)
	add_child(row)
	set_active(false)
	return self


func set_value(v: int) -> void:
	if not is_inside_tree() or v == _shown:
		_num.text = str(v)
		_shown = v
		return
	if is_instance_valid(_tween):
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_display, float(_shown), float(v), 0.3)
	_shown = v


func _set_display(f: float) -> void:
	_num.text = str(int(round(f)))


func set_active(a: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = ThemeManager.color("accent_soft") if a else ThemeManager.color("surface_2")
	s.set_corner_radius_all(int(ThemeManager.R_MD))
	s.set_border_width_all(1)
	s.border_color = ThemeManager.color("accent") if a else ThemeManager.color("hairline")
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	add_theme_stylebox_override("panel", s)
