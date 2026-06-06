class_name MeridianApp
extends Control
## Root scene + screen router. Holds the background and swaps full-screen screens. On a theme
## change it rebuilds the current screen (deferred, so we never free a control mid-callback) so
## every styled control picks up the new palette.

static var instance: MeridianApp

var _bg: ColorRect
var _current: Control
var _current_name := "menu"
var _current_params: Dictionary = {}


func _ready() -> void:
	instance = self
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = ThemeManager.color("bg")
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	ThemeManager.changed.connect(_on_theme_changed)
	goto("menu")
	if OS.get_cmdline_user_args().has("--smoke"):
		_run_smoke.call_deferred()


func goto(screen_name: String, params: Dictionary = {}) -> void:
	_current_name = screen_name
	_current_params = params
	if is_instance_valid(_current):
		_current.queue_free()
	var s := _make(screen_name)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_current = s
	add_child(s)
	if s.has_method("init_screen"):
		s.init_screen(params)


func _make(screen_name: String) -> Control:
	match screen_name:
		"setup": return GameSetup.new()
		"game": return GameScreen.new()
		"settings": return SettingsScreen.new()
		_: return MainMenu.new()


func _on_theme_changed() -> void:
	_bg.color = ThemeManager.color("bg")
	call_deferred("goto", _current_name, _current_params)


## Headless build check: cycles every screen (incl. a full vs-AI move) then quits.
## Run with:  godot --headless --path . -- --smoke
func _run_smoke() -> void:
	await get_tree().process_frame
	goto("settings")
	await get_tree().process_frame
	goto("setup")
	await get_tree().process_frame
	goto("game", {"mode": "local", "difficulty": "hard", "board_size": 5})
	await get_tree().process_frame
	var gs := _current as GameScreen
	gs.state.apply_move(0, 0)
	gs.state.apply_move(2, 2)
	await get_tree().process_frame
	goto("game", {"mode": "ai", "difficulty": "easy", "board_size": 5})
	await get_tree().process_frame
	gs = _current as GameScreen
	gs.state.apply_move(0, 0) # human move -> AI replies on a worker thread
	await get_tree().process_frame
	if gs.ai_thinking:
		await gs.runner.move_ready
	await get_tree().process_frame
	print("SMOKE_OK: menu/settings/setup/game(local)/game(ai)+AImove all built")
	get_tree().quit(0)
