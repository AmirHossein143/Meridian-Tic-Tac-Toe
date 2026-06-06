class_name MiniBoard
extends Control
## To-scale interior-grid preview of an N x N board (preset cards).

var n := 9


func configure(size_n: int, px: float) -> MiniBoard:
	n = size_n
	custom_minimum_size = Vector2(px, px)
	return self


func _ready() -> void:
	ThemeManager.changed.connect(queue_redraw)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var pad := s * 0.10
	var cell := (s - 2.0 * pad) / n
	var col := ThemeManager.color("grid")
	var w := maxf(s * 0.014, 1.0)
	for i in range(1, n):
		draw_line(Vector2(pad + i * cell, pad), Vector2(pad + i * cell, s - pad), col, w)
		draw_line(Vector2(pad, pad + i * cell), Vector2(s - pad, pad + i * cell), col, w)
