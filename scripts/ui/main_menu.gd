class_name MainMenu
extends Control
## Title screen: wordmark + Play / Settings.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var title := UIKit.label("Meridian", "display_bold", 60, "ink")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sub := UIKit.label("Fill the board — most & longest lines win.", "ui", 16, "ink_2")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	v.add_child(gap)

	var play := UIKit.button("Play", "primary", true)
	play.custom_minimum_size.x = 260
	play.pressed.connect(func() -> void: MeridianApp.instance.goto("setup"))
	v.add_child(play)

	var settings := UIKit.button("Settings", "ghost")
	settings.custom_minimum_size.x = 260
	settings.pressed.connect(func() -> void: MeridianApp.instance.goto("settings"))
	v.add_child(settings)
