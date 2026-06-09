extends Node
## Autoload "Audio". SFX + Music on dedicated buses, driven by the Sound/Music toggles in Settings.
## Clips are resolved by scanning assets/sfx (+ the music file) so a rename is a visible warning,
## not a silent no-op — and resolution is export-safe (handles .import/.remap sidecars).

# event -> source basename (no extension); the actual file may differ in case/extension.
const _SFX_BASENAMES := {
	"place_x": "PLACE_X", "place_o": "Place_O", "invalid": "Invalid,occupied_cell",
	"button": "Button_press", "tap": "Soft_Tap", "toggle": "Toggle_switch",
	"stepper": "stepper_tick", "preset": "Preset_Select", "start": "Start_game,forward",
	"back": "Back,close", "undo": "Undo", "win": "win", "draw": "Draw,tie",
	"sweep": "Run_highlight_sweep",
}
const _MUSIC_BASENAME := "gameplay_music"
const _SFX_DIR := "res://assets/sfx"
const _MUSIC_DIR := "res://assets/music"
const _POOL := 8

var _sfx_bus := 0
var _music_bus := 0
var _streams := {}            # event -> AudioStream
var _music_stream: AudioStream = null
var _missing: Array[String] = []

var _sfx_pool: Array[AudioStreamPlayer] = []
var _rr := 0
var _music_player: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	_sfx_bus = _ensure_bus("SFX")
	_music_bus = _ensure_bus("Music")
	AudioServer.set_bus_volume_db(_music_bus, -10.0)

	for i in _POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	_resolve_clips()
	_apply_mutes()
	Settings.changed.connect(_on_settings_changed)


# ---- resolution -----------------------------------------------------------------------------

func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		return idx
	idx = AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	return idx


## Maps lowercased "basename-without-extension" -> the res:// path to load (always the source
## file path, so the import remap resolves in exported builds).
func _scan_dir(dir_path: String) -> Dictionary:
	var out := {}
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		var fname := f
		if fname.ends_with(".import"):
			fname = fname.trim_suffix(".import")
		elif fname.ends_with(".remap"):
			fname = fname.trim_suffix(".remap")
		var base := fname.get_basename()        # strips the audio extension
		out[base.to_lower()] = dir_path.path_join(fname)
	return out


func _resolve_clips() -> void:
	var sfx_index := _scan_dir(_SFX_DIR)
	for ev: String in _SFX_BASENAMES:
		var key := String(_SFX_BASENAMES[ev]).to_lower()
		if sfx_index.has(key):
			var stream: AudioStream = load(sfx_index[key])
			if stream != null:
				_streams[ev] = stream
				continue
		_missing.append(ev)
		push_warning("Audio: no clip for event '%s' (expected '%s' in %s)" % [ev, _SFX_BASENAMES[ev], _SFX_DIR])

	var music_index := _scan_dir(_MUSIC_DIR)
	if music_index.has(_MUSIC_BASENAME.to_lower()):
		_music_stream = load(music_index[_MUSIC_BASENAME.to_lower()])
		if _music_stream is AudioStreamMP3:
			(_music_stream as AudioStreamMP3).loop = true
		elif _music_stream is AudioStreamOggVorbis:
			(_music_stream as AudioStreamOggVorbis).loop = true
	if _music_stream == null:
		_missing.append("music")
		push_warning("Audio: no music clip '%s' in %s" % [_MUSIC_BASENAME, _MUSIC_DIR])


func expected_count() -> int:
	return _SFX_BASENAMES.size() + 1


func resolved_count() -> int:
	return _streams.size() + (1 if _music_stream != null else 0)


func all_resolved() -> bool:
	return _missing.is_empty()


# ---- playback -------------------------------------------------------------------------------

func play(event: String) -> void:
	if not _streams.has(event):
		return
	var p := _next_player()
	p.stream = _streams[event]
	p.play()


func _next_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	var p := _sfx_pool[_rr]
	_rr = (_rr + 1) % _sfx_pool.size()
	return p


## Starts the looping track. Idempotent — a no-op if already playing (so the theme rebuild's
## goto("game") doesn't restart it).
func play_music() -> void:
	if _music_stream == null or _music_player.playing:
		return
	_music_player.stream = _music_stream
	_music_player.volume_db = -40.0
	_music_player.play()
	_fade_music(0.0, 0.4)


func stop_music(fade := 0.3) -> void:
	if not _music_player.playing:
		return
	_fade_music(-40.0, fade)
	if is_instance_valid(_music_tween):
		_music_tween.finished.connect(func() -> void:
			if _music_player.volume_db <= -39.0:
				_music_player.stop())


func _fade_music(target_db: float, dur: float) -> void:
	if is_instance_valid(_music_tween):
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", target_db, dur)


# ---- mutes ----------------------------------------------------------------------------------

func _apply_mutes() -> void:
	AudioServer.set_bus_mute(_sfx_bus, not bool(Settings.get_value("sound", true)))
	AudioServer.set_bus_mute(_music_bus, not bool(Settings.get_value("music", true)))


func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "sound":
		AudioServer.set_bus_mute(_sfx_bus, not bool(value))
	elif key == "music":
		AudioServer.set_bus_mute(_music_bus, not bool(value))
