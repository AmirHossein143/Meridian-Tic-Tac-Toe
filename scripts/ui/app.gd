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
	var old_name := _current_name
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
	# Fade in on genuine navigation only — NOT on the theme rebuild's same-screen re-entry, which
	# would flash the whole game screen in behind the reopened Settings overlay (protects Fix 4).
	if screen_name != old_name:
		s.modulate.a = 0.0
		create_tween().tween_property(s, "modulate:a", 1.0, 0.12)
	# Music plays in-game only; play_music() is idempotent so the rebuild doesn't restart it.
	if screen_name == "game":
		Audio.play_music()
	else:
		Audio.stop_music()


func _make(screen_name: String) -> Control:
	match screen_name:
		"setup": return GameSetup.new()
		"game": return GameScreen.new()
		"settings": return SettingsScreen.new()
		"howto": return HowToPlay.new()
		"credits": return Credits.new()
		_: return MainMenu.new()


func _on_theme_changed() -> void:
	_bg.color = ThemeManager.color("bg")
	call_deferred("goto", _current_name, _current_params)


## Headless build check: cycles every screen + in-game overlays, then verifies that toggling
## the theme mid-game does NOT reset the board. Run with: godot --headless --path . -- --smoke
func _run_smoke() -> void:
	await get_tree().process_frame
	# Audio: every mapped event must resolve to a real clip (a future rename fails the smoke).
	print("AUDIO_OK %d/%d" % [Audio.resolved_count(), Audio.expected_count()])
	if not Audio.all_resolved():
		push_error("audio: not all clips resolved")
		get_tree().quit(1)
		return
	for name in ["settings", "howto", "credits", "setup"]:
		goto(name)
		await get_tree().process_frame

	# Local game + a couple of moves.
	goto("game", {"mode": "local", "difficulty": "hard", "board_size": 5})
	await get_tree().process_frame
	var gs := _current as GameScreen
	gs.state.apply_move(0, 0)
	gs.state.apply_move(2, 2)
	await get_tree().process_frame

	# In-game pause + each overlay.
	gs._open_pause()
	await get_tree().process_frame
	gs._close_pause()
	gs._open_settings_overlay()
	await get_tree().process_frame
	gs._settings_done()
	await get_tree().process_frame
	gs._close_pause()
	gs._open_howto_overlay()
	await get_tree().process_frame
	gs._howto_done()
	await get_tree().process_frame

	# vs-AI: make a move, let the AI reply on a worker thread.
	goto("game", {"mode": "ai", "difficulty": "easy", "board_size": 5})
	await get_tree().process_frame
	gs = _current as GameScreen
	gs.state.apply_move(1, 1)
	await get_tree().process_frame
	if gs.ai_thinking:
		await gs.runner.move_ready
	await get_tree().process_frame

	# Fix 3 regression: after the AI replies it's the human's turn — the pill must say so.
	var turn_ok := gs.state.current == Marks.X and gs.turn_label.text == "Your turn"
	print("TURN_SYNC: current=%d pill='%s' ok=%s" % [gs.state.current, gs.turn_label.text, str(turn_ok)])
	if not turn_ok:
		push_error("turn indicator out of sync with active player")
		get_tree().quit(1)
		return

	# REGRESSION: toggle theme mid-game; the board must be preserved across the rebuild.
	var before_cells := gs.state.board.cells.duplicate()
	var before_moves := gs.state.history.size()
	gs._set_theme_preserving("dark" if not ThemeManager.is_dark() else "light")
	await get_tree().process_frame
	await get_tree().process_frame
	var gs2 := _current as GameScreen
	var preserved := gs2.state != null and gs2.state.board.cells == before_cells \
		and gs2.state.history.size() == before_moves
	print("THEME_PRESERVE: preserved=%s moves=%d->%d" % [str(preserved), before_moves, gs2.state.history.size()])
	if not preserved:
		push_error("theme toggle reset the in-progress game")
		get_tree().quit(1)
		return

	# Fix 4: toggling theme FROM the in-game Settings overlay must reopen the overlay post-rebuild.
	gs2._open_settings_overlay()
	await get_tree().process_frame
	gs2._settings_set_theme("light" if ThemeManager.is_dark() else "dark")
	await get_tree().process_frame
	await get_tree().process_frame
	var gs3 := _current as GameScreen
	var reopened := is_instance_valid(gs3._overlay) and gs3._overlay is Modal
	print("SETTINGS_REOPEN: ok=%s" % str(reopened))
	if not reopened:
		push_error("settings popup not restored after theme toggle")
		get_tree().quit(1)
		return
	print("SMOKE_OK: menu/settings/howto/credits/setup/game + pause/overlays + theme-preserve")
	get_tree().quit(0)
