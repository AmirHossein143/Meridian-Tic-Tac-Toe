class_name SettingsScreen
extends Control
## Full-screen settings: wraps the shared SettingsPanel with a header. Theme/accent are applied
## directly here (no in-progress game to preserve); the App rebuilds this screen on the change.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIKit.panel("surface", "hairline", 20.0, 28)
	panel.custom_minimum_size.x = UIKit.clamp_width(440.0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var back := UIKit.button("< Back", "ghost", false, "back")
	back.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	header.add_child(back)
	var title := UIKit.label("Settings", "display", 24, "ink")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(title)
	v.add_child(header)

	var gap := Control.new()
	gap.custom_minimum_size.y = 10
	v.add_child(gap)

	v.add_child(SettingsPanel.new().configure(
		func(mode: String) -> void: ThemeManager.set_theme_mode(mode),
		func(a: String) -> void: ThemeManager.set_accent(a)))
