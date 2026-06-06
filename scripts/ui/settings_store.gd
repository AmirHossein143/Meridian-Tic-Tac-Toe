extends Node
## Autoload "Settings". Persists user preferences to user:// as a flat ConfigFile.
## Keys: theme (light|dark), accent (jade|purple), sound (bool), music (bool),
##       mode (ai|local), difficulty (easy|medium|hard), board_size (int 3..19).

const PATH := "user://meridian_settings.cfg"
const SECTION := "meridian"

signal changed(key: String, value: Variant)

var _data := {
	"theme": "light",
	"accent": "jade",
	"sound": true,
	"music": true,
	"mode": "ai",
	"difficulty": "hard",
	"board_size": 9,
}


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key: String in _data.keys():
			if cfg.has_section_key(SECTION, key):
				_data[key] = cfg.get_value(SECTION, key)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in _data.keys():
		cfg.set_value(SECTION, key, _data[key])
	cfg.save(PATH)


func get_value(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)


func set_value(key: String, value: Variant) -> void:
	if _data.get(key) == value:
		return
	_data[key] = value
	save_settings()
	changed.emit(key, value)
