class_name MainMenu
extends Control
## Title screen: wordmark + Play / How to Play / Settings / Credits / Quit.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
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

	v.add_child(_menu_button("Play", "primary", true, func() -> void: MeridianApp.instance.goto("setup")))
	v.add_child(_menu_button("How to Play", "ghost", false, func() -> void: MeridianApp.instance.goto("howto")))
	v.add_child(_menu_button("Settings", "ghost", false, func() -> void: MeridianApp.instance.goto("settings")))
	v.add_child(_menu_button("Credits", "ghost", false, func() -> void: MeridianApp.instance.goto("credits")))
	v.add_child(_menu_button("Quit", "ghost", false, _confirm_quit))


func _menu_button(text: String, kind: String, big: bool, cb: Callable) -> Button:
	var b := UIKit.button(text, kind, big)
	b.custom_minimum_size.x = 260
	b.pressed.connect(cb)
	return b


func _confirm_quit() -> void:
	var m := Modal.new().configure(true, 420.0)
	add_child(m)
	m.dismissed.connect(m.close)

	m.body.add_child(UIKit.label("Leaving already?", "display_bold", 26, "ink"))
	var msg := UIKit.label(
		"The board was just starting to like you. Walk away now and those X's and O's never get closure.",
		"ui", 15, "ink_2")
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size.x = UIKit.clamp_width(360.0)
	m.body.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var quit := UIKit.button("Quit", "danger")
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.pressed.connect(func() -> void: get_tree().quit()) # TODO(android): quit() is a no-op/discouraged on Android
	var stay := UIKit.button("Stay", "ghost")
	stay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stay.pressed.connect(m.close)
	row.add_child(quit)
	row.add_child(stay)
	m.body.add_child(row)
