class_name Credits
extends Control
## Credits + links. URLs are intentionally blank named constants for the author to fill in;
## a row whose URL is still blank is disabled so it never opens an empty link.

const GITHUB_URL := ""    # TODO: Amir to fill
const LINKEDIN_URL := ""  # TODO: Amir to fill
const PORTFOLIO_URL := "" # TODO: Amir to fill


func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = ThemeManager.color("bg")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIKit.panel("surface", "hairline", 20.0, 28)
	panel.custom_minimum_size.x = UIKit.clamp_width(460.0)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	v.add_child(UIKit.label("Meridian", "display_bold", 40, "ink"))

	var blurb := UIKit.label(
		"A tic-tac-toe that refused to stay simple. Fill the board, chase the longest line, and make the AI think about its choices.\n\nDesigned and built by Amir, one stubborn pixel at a time.",
		"ui", 15, "ink_2")
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.size_flags_horizontal = Control.SIZE_FILL
	v.add_child(blurb)

	var sep := ColorRect.new()
	sep.color = ThemeManager.color("hairline")
	sep.custom_minimum_size.y = 1
	v.add_child(sep)

	v.add_child(_link_row("GitHub", GITHUB_URL))
	v.add_child(_link_row("LinkedIn", LINKEDIN_URL))
	v.add_child(_link_row("Portfolio", PORTFOLIO_URL))

	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	v.add_child(gap)

	var back := UIKit.button("< Back", "ghost")
	back.pressed.connect(func() -> void: MeridianApp.instance.goto("menu"))
	v.add_child(back)


func _link_row(name_text: String, url: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size.y = ThemeManager.TAP
	var l := UIKit.label(name_text, "ui_semibold", 16, "ink")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var has_url := url.strip_edges() != ""
	var btn := UIKit.button("Open" if has_url else "Soon", "soft")
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = not has_url
	if has_url:
		btn.pressed.connect(func() -> void: _open(url))
	row.add_child(btn)
	return row


func _open(url: String) -> void:
	if url.strip_edges() != "":
		OS.shell_open(url)
