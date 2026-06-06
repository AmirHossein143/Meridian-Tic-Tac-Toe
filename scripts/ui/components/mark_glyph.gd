class_name MarkGlyph
extends Control
## A small X or O glyph for scoreboards / breakdown rows, drawn with the same flat strokes
## as the board (X = accent, O = terracotta).

var mark := Marks.X


func configure(m: int, px := 30.0) -> MarkGlyph:
	mark = m
	custom_minimum_size = Vector2(px, px)
	return self


func _ready() -> void:
	ThemeManager.changed.connect(queue_redraw)


func set_mark(m: int) -> void:
	mark = m
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var ctr := size * 0.5
	var rg := s * 0.32
	var sw := maxf(s * 0.11, 2.4)
	if mark == Marks.X:
		var col := ThemeManager.color("x")
		draw_line(ctr + Vector2(-rg, -rg), ctr + Vector2(rg, rg), col, sw, true)
		draw_line(ctr + Vector2(rg, -rg), ctr + Vector2(-rg, rg), col, sw, true)
	else:
		draw_arc(ctr, rg, 0.0, TAU, 40, ThemeManager.color("o"), sw, true)
