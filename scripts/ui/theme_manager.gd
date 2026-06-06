extends Node
## Autoload "ThemeManager". Translates refrence/tokens.css into runtime Colors + fonts and
## supports light/dark + optional purple accent. Custom-drawn controls (BoardView) and the
## UIKit read colors here; `changed` fires when the palette is swapped so views can redraw.

signal changed

# Base palettes (everything except the accent group) ------------------------------------------
const _LIGHT := {
	"bg": "#F3EDE3", "surface": "#FCF8F1", "surface_2": "#F6EFE3",
	"board_bg": "#E7DAC1", "grid": "#B6A079",
	"ink": "#2C2823", "ink_2": "#6E6557", "ink_3": "#9C9384",
	"hairline": "#E6DECE", "line": "#D8CDB9",
	"run_white": "#CC7A52", "highlight": "#D8A24A",
}
const _DARK := {
	"bg": "#1A1815", "surface": "#232019", "surface_2": "#2A261F",
	"board_bg": "#2F2A22", "grid": "#4D4636",
	"ink": "#F1ECE0", "ink_2": "#B4AC9C", "ink_3": "#837B6C",
	"hairline": "#322E26", "line": "#3A352B",
	"run_white": "#D98A60", "highlight": "#E0B25C",
}
# Accent group per (accent, theme) ------------------------------------------------------------
const _ACCENT := {
	"jade": {
		"light": {"accent": "#4F8E7C", "accent_2": "#3F7567", "accent_soft": "#DCEAE4", "on_accent": "#FBF7F0"},
		"dark": {"accent": "#5FA48F", "accent_2": "#71B19D", "accent_soft": "#2A352F", "on_accent": "#14110D"},
	},
	"purple": {
		"light": {"accent": "#6E5AC8", "accent_2": "#5B49B0", "accent_soft": "#E6E1F7", "on_accent": "#FBF7F0"},
		"dark": {"accent": "#8B79E0", "accent_2": "#9C8CEA", "accent_soft": "#2E2842", "on_accent": "#14110D"},
	},
}

# Radii / spacing from tokens.css
const R_SM := 10.0
const R_MD := 14.0
const R_LG := 20.0
const R_PILL := 999.0
const TAP := 44.0

var theme_mode := "light"
var accent := "jade"

var font_display: FontFile      ## Sora — wordmark / numbers
var font_display_bold: FontFile
var font_ui: FontFile           ## Hanken Grotesk — UI
var font_ui_semibold: FontFile
var font_mono: FontFile         ## JetBrains Mono — specs

var _c := {}


func _ready() -> void:
	_load_fonts()
	theme_mode = str(Settings.get_value("theme", "light"))
	accent = str(Settings.get_value("accent", "jade"))
	_resolve()


func _load_fonts() -> void:
	font_display = load("res://assets/fonts/Sora/static/Sora-SemiBold.ttf") as FontFile
	font_display_bold = load("res://assets/fonts/Sora/static/Sora-Bold.ttf") as FontFile
	font_ui = load("res://assets/fonts/Hanken_Grotesk/static/HankenGrotesk-Regular.ttf") as FontFile
	font_ui_semibold = load("res://assets/fonts/Hanken_Grotesk/static/HankenGrotesk-SemiBold.ttf") as FontFile
	font_mono = load("res://assets/fonts/JetBrains_Mono/static/JetBrainsMono-Regular.ttf") as FontFile


func _resolve() -> void:
	var theme_s := theme_mode
	var base: Dictionary = _LIGHT if theme_mode == "light" else _DARK
	var acc: Dictionary = _ACCENT[accent][theme_s]
	_c.clear()
	for k: String in base:
		_c[k] = Color(base[k])
	for k: String in acc:
		_c[k] = Color(acc[k])
	_c["x"] = _c["accent"]       # X mark / runs follow the accent
	_c["o"] = _c["run_white"]    # O mark / runs are terracotta
	changed.emit()


func color(name: String) -> Color:
	return _c.get(name, Color.MAGENTA)


func is_dark() -> bool:
	return theme_mode == "dark"


func set_theme_mode(mode: String) -> void:
	if mode == theme_mode:
		return
	theme_mode = mode
	Settings.set_value("theme", mode)
	_resolve()


func set_accent(a: String) -> void:
	if a == accent:
		return
	accent = a
	Settings.set_value("accent", a)
	_resolve()
