class_name SettingsPanel
extends VBoxContainer
## The settings rows (sound, music, light/dark, purple accent), shared by the full Settings
## screen and the in-game pause overlay. Sound/music persist directly via Settings; theme and
## accent are applied through host-provided callables so the in-game host can preserve the game.

func configure(apply_theme: Callable, apply_accent: Callable) -> SettingsPanel:
	add_theme_constant_override("separation", 6)

	add_child(_switch_row("Sound", bool(Settings.get_value("sound", true)),
		func(on: bool) -> void: Settings.set_value("sound", on)))
	add_child(_sep())
	add_child(_switch_row("Music", bool(Settings.get_value("music", true)),
		func(on: bool) -> void: Settings.set_value("music", on)))
	add_child(_sep())

	var seg := Segmented.new().configure(["Light", "Dark"], 1 if ThemeManager.is_dark() else 0)
	seg.selected.connect(func(i: int) -> void: apply_theme.call("dark" if i == 1 else "light"))
	add_child(_control_row("Theme", seg))
	add_child(_sep())

	add_child(_switch_row("Purple accent", ThemeManager.accent == "purple",
		func(on: bool) -> void: apply_accent.call("purple" if on else "jade")))
	return self


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
