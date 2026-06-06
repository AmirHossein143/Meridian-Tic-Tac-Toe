class_name SettingsScreen
extends Control
## Sound / music toggles, light/dark theme, optional purple accent. Persists via Settings;
## theme/accent changes flow through ThemeManager and trigger an App rebuild.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIKit.panel("surface", "hairline", 20.0, 28)
	panel.custom_minimum_size.x = 440
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var back := UIKit.button("< Back", "ghost")
	back.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	header.add_child(back)
	var title := UIKit.label("Settings", "display", 24, "ink")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(title)
	v.add_child(header)
	v.add_child(_gap(10))

	v.add_child(_switch_row("Sound", bool(Settings.get_value("sound", true)),
		func(on: bool) -> void: Settings.set_value("sound", on)))
	v.add_child(_sep())
	v.add_child(_switch_row("Music", bool(Settings.get_value("music", true)),
		func(on: bool) -> void: Settings.set_value("music", on)))
	v.add_child(_sep())

	var seg := Segmented.new().configure(["Light", "Dark"], 1 if ThemeManager.theme_mode == "dark" else 0)
	seg.selected.connect(func(i: int) -> void: ThemeManager.set_theme_mode("dark" if i == 1 else "light"))
	v.add_child(_control_row("Theme", seg))
	v.add_child(_sep())

	v.add_child(_switch_row("Purple accent", ThemeManager.accent == "purple",
		func(on: bool) -> void: ThemeManager.set_accent("purple" if on else "jade")))


func _switch_row(text: String, value: bool, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size.y = ThemeManager.TAP
	var l := UIKit.label(text, "ui_semibold", 16, "ink")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sw := ToggleSwitch.new().configure(value)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.switched.connect(cb)
	row.add_child(l)
	row.add_child(sw)
	return row


func _control_row(text: String, ctrl: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size.y = ThemeManager.TAP
	var l := UIKit.label(text, "ui_semibold", 16, "ink")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	row.add_child(ctrl)
	return row


func _sep() -> Control:
	var r := ColorRect.new()
	r.color = ThemeManager.color("hairline")
	r.custom_minimum_size.y = 1
	return r


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
