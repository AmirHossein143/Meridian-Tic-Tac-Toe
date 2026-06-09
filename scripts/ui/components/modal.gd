class_name Modal
extends Control
## Reusable centred modal: full-rect dim + a centred UIKit panel. Add content to `body`.
## Emits `dismissed` when the dim is tapped (if dismissable). Same visual pattern as the
## game-over overlay. Host adds it as a child and calls close() (or connects dismissed).

signal dismissed

var body: VBoxContainer
var _dismissable := true
var _animate := true
var _panel: Control


func configure(dismissable := true, panel_min_x := 420.0, animate := true) -> Modal:
	_dismissable = dismissable
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.38)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE # clicks fall through to the dim except on the panel
	add_child(center)

	var panel := UIKit.panel("surface", "hairline", 20.0, 28)
	panel.custom_minimum_size.x = UIKit.clamp_width(panel_min_x)
	center.add_child(panel)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	panel.add_child(body)
	_panel = panel
	_animate = animate
	return self


func _ready() -> void:
	# Run the entrance here (not in configure) — the modal is in the tree by now, so the
	# tween/get_tree() calls in pop_in are valid.
	if _animate:
		UIKit.pop_in(self, _panel)


func close() -> void:
	queue_free()


func _on_dim_input(e: InputEvent) -> void:
	if not _dismissable:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		dismissed.emit()
