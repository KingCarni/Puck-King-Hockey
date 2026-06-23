extends Node

# Puck King Hell — global arcade UI palette and theme builder.
# Heavy metal / fight night aesthetic. Bold, chunky, controller-friendly.

const FONT_DISPLAY_PATH: String = "res://assets/fonts/Bungee-Regular.ttf"
const FONT_ACCENT_PATH: String = "res://assets/fonts/BungeeInline-Regular.ttf"

const COLOR_BLACK: Color = Color(0.05, 0.05, 0.06, 1.0)
const COLOR_BLACK_TRANSPARENT: Color = Color(0.04, 0.04, 0.05, 0.78)
const COLOR_INK: Color = Color(0.08, 0.08, 0.09, 1.0)
const COLOR_BLOOD_RED: Color = Color(0.85, 0.10, 0.13, 1.0)
const COLOR_FIRE_RED: Color = Color(1.0, 0.22, 0.18, 1.0)
const COLOR_GOLD: Color = Color(1.0, 0.78, 0.10, 1.0)
const COLOR_HOT_GOLD: Color = Color(1.0, 0.92, 0.30, 1.0)
const COLOR_BONE: Color = Color(0.97, 0.96, 0.92, 1.0)
const COLOR_STEEL: Color = Color(0.55, 0.58, 0.62, 1.0)
const COLOR_HOME_BLUE: Color = Color(0.18, 0.55, 1.0, 1.0)
const COLOR_AWAY_RED: Color = Color(1.0, 0.20, 0.22, 1.0)

var font_display: FontFile = null
var font_accent: FontFile = null

func _ready() -> void:
	font_display = _try_load_font(FONT_DISPLAY_PATH)
	font_accent = _try_load_font(FONT_ACCENT_PATH)

func _try_load_font(path: String) -> FontFile:
	var font_file: FontFile = null
	if ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is FontFile:
			font_file = loaded as FontFile
	if font_file == null and FileAccess.file_exists(path):
		var raw_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		if raw_bytes.size() > 0:
			font_file = FontFile.new()
			font_file.data = raw_bytes
	return font_file

func get_display_font() -> FontFile:
	return font_display

func get_accent_font() -> FontFile:
	return font_accent

# Build a chunky, bordered panel: black fill, gold outline, optional accent stripe.
func make_panel_box(fill: Color = COLOR_BLACK, border: Color = COLOR_GOLD, border_width: int = 4, corner_radius: int = 10) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

# Build a chunky button background.
func make_button_box(fill: Color, border: Color = COLOR_GOLD, border_width: int = 3, corner_radius: int = 8) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

# Apply the arcade display font to a Label with optional drop shadow.
func style_display_label(label: Label, size: int, color: Color = COLOR_BONE, shadow: bool = true) -> void:
	if font_display != null:
		label.add_theme_font_override("font", font_display)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if shadow:
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		label.add_theme_constant_override("shadow_offset_x", 3)
		label.add_theme_constant_override("shadow_offset_y", 4)
		label.add_theme_constant_override("shadow_outline_size", 0)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 6)

func style_accent_label(label: Label, size: int, color: Color = COLOR_GOLD) -> void:
	if font_accent != null:
		label.add_theme_font_override("font", font_accent)
	elif font_display != null:
		label.add_theme_font_override("font", font_display)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 5)

func style_button(button: Button, fill: Color = COLOR_BLOOD_RED, border: Color = COLOR_GOLD, text_color: Color = COLOR_BONE, size: int = 28) -> void:
	if font_display != null:
		button.add_theme_font_override("font", font_display)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_focus_color", COLOR_HOT_GOLD)
	button.add_theme_color_override("font_hover_color", COLOR_HOT_GOLD)
	button.add_theme_color_override("font_pressed_color", COLOR_BONE)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	button.add_theme_constant_override("outline_size", 5)

	var normal: StyleBoxFlat = make_button_box(fill, border, 3, 8)
	var hover: StyleBoxFlat = make_button_box(fill.lightened(0.12), COLOR_HOT_GOLD, 4, 8)
	var pressed: StyleBoxFlat = make_button_box(fill.darkened(0.18), COLOR_GOLD, 3, 8)
	var focus: StyleBoxFlat = make_button_box(fill, COLOR_HOT_GOLD, 5, 8)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
