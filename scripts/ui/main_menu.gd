extends Control

# Puck King Hell — main menu title screen.
# Built entirely from native Control nodes: layered arena backdrop, keyed logo
# art, framed MATCH MODES / ACTIONS panels and a footer hint bar. Mouse hover,
# keyboard and gamepad all drive the same focus state, so hover == focus.

const MATCH_SCENE_PATH: String = "res://scenes/match/TestRink.tscn"
const PRESET_SELECT_KEY: String = "puck_king_hell/selected_preset_id"
const LOGO_WEBP_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.webp"
const LOGO_PNG_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.png"
const ICON_DIR_PATH: String = "res://assets/ui/icons"

const COLOR_GOLD: Color = Color(1.0, 0.78, 0.10, 1.0)
const COLOR_HOT_GOLD: Color = Color(1.0, 0.92, 0.30, 1.0)
const COLOR_BONE: Color = Color(0.97, 0.96, 0.92, 1.0)
const COLOR_STEEL: Color = Color(0.55, 0.58, 0.62, 1.0)
const COLOR_BLOOD_RED: Color = Color(0.85, 0.10, 0.13, 1.0)
const COLOR_HOME_BLUE: Color = Color(0.18, 0.55, 1.0, 1.0)
const COLOR_DARK_FILL: Color = Color(0.055, 0.055, 0.07, 0.94)
const COLOR_PANEL_FILL: Color = Color(0.028, 0.028, 0.042, 0.88)

# The approved logo art ships on a solid black plate (no alpha channel).
# This keys the black out so the logo sits on the live backdrop, and adds a
# diagonal light-sweep band; sweep_pos is animated from _start_ambient_motion().
const LOGO_SHADER_CODE: String = """
shader_type canvas_item;
uniform float sweep_pos = -0.5;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = max(c.r, max(c.g, c.b));
	float keyed = smoothstep(0.02, 0.14, lum);
	float band = clamp(1.0 - abs(UV.x + UV.y * 0.22 - sweep_pos) / 0.09, 0.0, 1.0);
	c.rgb += vec3(band * band * 0.32) * keyed;
	COLOR = vec4(c.rgb, c.a * keyed);
}
"""

var _palette: Node = null
var _logo: TextureRect = null
var _logo_material: ShaderMaterial = null
var _snow: CPUParticles2D = null
var _blurb_label: Label = null
var _preset_buttons: Array[Button] = []
var _action_buttons: Array[Button] = []
var _play_button: Button = null
var _adventure_button: Button = null
var _stats_button: Button = null
var _extras_button: Button = null
var _settings_button: Button = null
var _quit_button: Button = null
var _settings_panel: Control = null
var _settings_back_button: Button = null
var _is_settings_open: bool = false
var _selected_preset_id: String = MatchPreset.ID_STANDARD
var _previewed_preset_id: String = MatchPreset.ID_STANDARD

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Restore the mode picked earlier this session (set again in _select_preset).
	var saved_id: String = String(ProjectSettings.get_setting(PRESET_SELECT_KEY, MatchPreset.ID_STANDARD))
	_selected_preset_id = String(MatchPreset.find(saved_id).get("id", MatchPreset.ID_STANDARD))
	_previewed_preset_id = _selected_preset_id

	_build_backdrop()
	_build_layout()
	_build_settings_panel()
	_wire_focus_neighbors()
	_select_preset(_selected_preset_id)
	_start_ambient_motion()

	get_viewport().size_changed.connect(_update_ambient_bounds)
	_update_ambient_bounds()

	if _play_button != null:
		_play_button.grab_focus()

# ---------------------------------------------------------------- backdrop --

func _build_backdrop() -> void:
	var backdrop: Control = Control.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var base: ColorRect = ColorRect.new()
	base.name = "ArenaBlack"
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.016, 0.016, 0.024, 1.0)
	backdrop.add_child(base)

	# Crowd/goal-light glows: red home side, blue away side — echoes the HUD.
	var red_glow: TextureRect = _make_radial_glow(Color(0.72, 0.07, 0.10, 0.34))
	red_glow.name = "RedGlow"
	_set_anchor_rect(red_glow, -0.18, 0.52, -0.30, 0.72)
	backdrop.add_child(red_glow)

	var blue_glow: TextureRect = _make_radial_glow(Color(0.10, 0.30, 0.80, 0.32))
	blue_glow.name = "BlueGlow"
	_set_anchor_rect(blue_glow, 0.48, 1.18, -0.30, 0.72)
	backdrop.add_child(blue_glow)

	# Faint ice sheen rising from the bottom of the rink.
	var sheen: TextureRect = TextureRect.new()
	sheen.name = "IceSheen"
	var sheen_gradient: Gradient = Gradient.new()
	sheen_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	sheen_gradient.colors = PackedColorArray([Color(0.62, 0.78, 1.0, 0.13), Color(0.62, 0.78, 1.0, 0.0)])
	var sheen_texture: GradientTexture2D = GradientTexture2D.new()
	sheen_texture.gradient = sheen_gradient
	sheen_texture.fill_from = Vector2(0.5, 1.0)
	sheen_texture.fill_to = Vector2(0.5, 0.0)
	sheen.texture = sheen_texture
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheen.stretch_mode = TextureRect.STRETCH_SCALE
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_anchor_rect(sheen, 0.0, 1.0, 0.62, 1.0)
	backdrop.add_child(sheen)

	# Drifting ice particles behind the panels.
	_snow = CPUParticles2D.new()
	_snow.name = "IceDrift"
	var dot_gradient: Gradient = Gradient.new()
	dot_gradient.offsets = PackedFloat32Array([0.0, 1.0])
	dot_gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])
	var dot_texture: GradientTexture2D = GradientTexture2D.new()
	dot_texture.gradient = dot_gradient
	dot_texture.fill = GradientTexture2D.FILL_RADIAL
	dot_texture.fill_from = Vector2(0.5, 0.5)
	dot_texture.fill_to = Vector2(0.5, 0.0)
	dot_texture.width = 32
	dot_texture.height = 32
	_snow.texture = dot_texture
	_snow.amount = 40
	_snow.lifetime = 14.0
	_snow.preprocess = 14.0
	_snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_snow.emission_rect_extents = Vector2(1400.0, 30.0)
	_snow.direction = Vector2(0.0, 1.0)
	_snow.spread = 12.0
	_snow.gravity = Vector2(0.0, 4.0)
	_snow.initial_velocity_min = 10.0
	_snow.initial_velocity_max = 30.0
	_snow.scale_amount_min = 0.10
	_snow.scale_amount_max = 0.40
	_snow.color = Color(0.86, 0.92, 1.0, 0.34)
	backdrop.add_child(_snow)

	# Vignette keeps the edges dark so the menu pops.
	var vignette: TextureRect = TextureRect.new()
	vignette.name = "Vignette"
	var vignette_gradient: Gradient = Gradient.new()
	vignette_gradient.offsets = PackedFloat32Array([0.52, 1.0])
	vignette_gradient.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.52)])
	var vignette_texture: GradientTexture2D = GradientTexture2D.new()
	vignette_texture.gradient = vignette_gradient
	vignette_texture.fill = GradientTexture2D.FILL_RADIAL
	vignette_texture.fill_from = Vector2(0.5, 0.5)
	vignette_texture.fill_to = Vector2(0.5, -0.1)
	vignette.texture = vignette_texture
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(vignette)

func _make_radial_glow(glow_color: Color) -> TextureRect:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([glow_color, Color(glow_color.r, glow_color.g, glow_color.b, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 512
	texture.height = 512
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _set_anchor_rect(node: Control, left: float, right: float, top: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_right = right
	node.anchor_top = top
	node.anchor_bottom = bottom
	node.offset_left = 0.0
	node.offset_right = 0.0
	node.offset_top = 0.0
	node.offset_bottom = 0.0

# ------------------------------------------------------------------ layout --

func _build_layout() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Layout"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 20)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	_build_logo_slot(column)
	_build_menu_row(column)
	_build_footer(column)

func _build_logo_slot(parent: VBoxContainer) -> void:
	var slot: Control = Control.new()
	slot.name = "LogoSlot"
	slot.custom_minimum_size = Vector2(0.0, 300.0)
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(slot)

	var texture: Texture2D = _load_logo_texture()
	if texture != null:
		_logo = TextureRect.new()
		_logo.name = "Logo"
		_logo.texture = texture
		_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader: Shader = Shader.new()
		shader.code = LOGO_SHADER_CODE
		_logo_material = ShaderMaterial.new()
		_logo_material.shader = shader
		_logo_material.set_shader_parameter("sweep_pos", -0.5)
		_logo.material = _logo_material
		_logo.resized.connect(func() -> void:
			_logo.pivot_offset = _logo.size * 0.5
		)
		slot.add_child(_logo)
		return

	# Fallback if the logo art is missing: typographic lockup in project fonts.
	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(title_box)
	var line_one: Label = _make_display_label("PUCK KING", 120, COLOR_BONE)
	var line_two: Label = _make_display_label("HELL", 88, COLOR_BLOOD_RED)
	title_box.add_child(line_one)
	title_box.add_child(line_two)

func _build_menu_row(parent: VBoxContainer) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "MenuRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 90)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	_build_mode_panel(row)
	_build_action_panel(row)

func _build_mode_panel(parent: HBoxContainer) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ModePanel"
	panel.custom_minimum_size = Vector2(700.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_box(COLOR_PANEL_FILL, COLOR_BLOOD_RED, 4, 14, 26, 22))
	parent.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	vbox.add_child(_make_header_ribbon("MATCH MODES", COLOR_BLOOD_RED))

	for preset in MatchPreset.catalog():
		var preset_id: String = String(preset.get("id", ""))
		var btn: Button = _make_menu_button(String(preset.get("title", "MATCH")), COLOR_DARK_FILL, "", 30, 88)
		btn.set_meta("preset_id", preset_id)
		btn.pressed.connect(_on_preset_button_pressed.bind(preset_id))
		btn.focus_entered.connect(_on_preset_button_focused.bind(preset_id))
		vbox.add_child(btn)
		_preset_buttons.append(btn)

	_blurb_label = Label.new()
	_blurb_label.name = "PresetBlurb"
	_blurb_label.custom_minimum_size = Vector2(0.0, 58.0)
	_blurb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_blurb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_blurb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_accent_label(_blurb_label, 24, COLOR_STEEL)
	vbox.add_child(_blurb_label)

func _build_action_panel(parent: HBoxContainer) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ActionPanel"
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", _make_box(COLOR_PANEL_FILL, COLOR_HOME_BLUE, 4, 14, 26, 22))
	parent.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	vbox.add_child(_make_header_ribbon("ACTIONS", Color(0.10, 0.22, 0.46, 1.0)))

	_play_button = _make_menu_button("PLAY", COLOR_BLOOD_RED, "icon_play", 38, 104)
	_adventure_button = _make_menu_button("ADVENTURE", Color(0.30, 0.20, 0.02, 0.96), "icon_crown", 32, 88)
	_stats_button = _make_menu_button("STATS", COLOR_DARK_FILL, "icon_trophy", 32, 88)
	_extras_button = _make_menu_button("EXTRAS", COLOR_DARK_FILL, "icon_crown", 32, 88)
	_settings_button = _make_menu_button("SETTINGS", COLOR_DARK_FILL, "icon_settings", 32, 88)
	_quit_button = _make_menu_button("QUIT", COLOR_DARK_FILL, "icon_quit", 32, 88)

	_play_button.pressed.connect(_on_play_pressed)
	_adventure_button.pressed.connect(_on_adventure_pressed)
	_stats_button.pressed.connect(_on_stats_pressed)
	_extras_button.pressed.connect(_on_extras_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	if OS.has_feature("web"):
		_quit_button.visible = false

	var actions: Array[Button] = [_play_button, _adventure_button, _stats_button, _extras_button, _settings_button, _quit_button]
	for btn in actions:
		vbox.add_child(btn)
		if btn.visible:
			_action_buttons.append(btn)

func _build_footer(parent: VBoxContainer) -> void:
	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 24)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(footer)

	var hints: Label = Label.new()
	hints.text = "ARROWS / D-PAD — MOVE      ENTER / A — SELECT      ESC / START — BACK"
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_accent_label(hints, 22, COLOR_STEEL)
	footer.add_child(hints)

	var version: Label = Label.new()
	var version_text: String = String(ProjectSettings.get_setting("application/config/version", ""))
	version.text = version_text if version_text != "" else "DEV BUILD"
	_style_accent_label(version, 20, Color(0.40, 0.42, 0.46, 1.0))
	footer.add_child(version)

# ------------------------------------------------------------ widget makers --

func _make_header_ribbon(text: String, fill: Color) -> PanelContainer:
	var ribbon: PanelContainer = PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", _make_box(fill, COLOR_GOLD, 4, 8, 20, 10))
	var label: Label = _make_display_label(text, 40, COLOR_BONE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_child(label)
	return ribbon

func _make_menu_button(text: String, fill: Color, icon_name: String, font_size: int, height: float) -> Button:
	var btn: Button = Button.new()
	btn.name = "Button_%s" % text.to_pascal_case()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0.0, height)
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_constant_override("icon_max_width", 48)
	btn.add_theme_constant_override("h_separation", 20)
	if icon_name != "":
		var icon: Texture2D = _load_icon(icon_name)
		if icon != null:
			btn.icon = icon
	_style_button(btn, fill, font_size)
	# Hovering steals focus so mouse, keyboard and gamepad share one highlight.
	btn.mouse_entered.connect(_on_button_hovered.bind(btn))
	btn.focus_entered.connect(_on_button_focus_sfx)
	return btn

func _style_button(btn: Button, fill: Color, font_size: int) -> void:
	if _palette != null and _palette.has_method("style_button"):
		_palette.call("style_button", btn, fill, COLOR_GOLD, COLOR_BONE, font_size)
		return
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COLOR_BONE)
	btn.add_theme_stylebox_override("normal", _make_box(fill, COLOR_GOLD, 3, 8, 28, 16))
	btn.add_theme_stylebox_override("hover", _make_box(fill.lightened(0.12), COLOR_HOT_GOLD, 4, 8, 28, 16))
	btn.add_theme_stylebox_override("pressed", _make_box(fill.darkened(0.18), COLOR_GOLD, 3, 8, 28, 16))
	btn.add_theme_stylebox_override("focus", _make_box(fill, COLOR_HOT_GOLD, 5, 8, 28, 16))

func _make_display_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null and _palette.has_method("style_display_label"):
		_palette.call("style_display_label", label, font_size, color)
	else:
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
	return label

func _style_accent_label(label: Label, font_size: int, color: Color) -> void:
	if _palette != null and _palette.has_method("style_accent_label"):
		_palette.call("style_accent_label", label, font_size, color)
	else:
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)

func _make_box(fill: Color, border: Color, border_width: int, radius: int, margin_h: int, margin_v: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 8
	style.content_margin_left = margin_h
	style.content_margin_right = margin_h
	style.content_margin_top = margin_v
	style.content_margin_bottom = margin_v
	return style

func _load_icon(icon_name: String) -> Texture2D:
	var path: String = "%s/%s.svg" % [ICON_DIR_PATH, icon_name]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _load_logo_texture() -> Texture2D:
	if ResourceLoader.exists(LOGO_WEBP_PATH):
		return load(LOGO_WEBP_PATH) as Texture2D
	if ResourceLoader.exists(LOGO_PNG_PATH):
		return load(LOGO_PNG_PATH) as Texture2D
	return null

# ------------------------------------------------------------------- focus --

func _wire_focus_neighbors() -> void:
	_wire_column(_preset_buttons)
	_wire_column(_action_buttons)
	for index in range(_preset_buttons.size()):
		var mode_btn: Button = _preset_buttons[index]
		var pair_index: int = mini(index, _action_buttons.size() - 1)
		if pair_index >= 0:
			mode_btn.focus_neighbor_right = mode_btn.get_path_to(_action_buttons[pair_index])
	for index in range(_action_buttons.size()):
		var action_btn: Button = _action_buttons[index]
		var pair_index: int = mini(index, _preset_buttons.size() - 1)
		if pair_index >= 0:
			action_btn.focus_neighbor_left = action_btn.get_path_to(_preset_buttons[pair_index])

func _wire_column(buttons: Array[Button]) -> void:
	var count: int = buttons.size()
	for index in range(count):
		var btn: Button = buttons[index]
		var above: Button = buttons[(index - 1 + count) % count]
		var below: Button = buttons[(index + 1) % count]
		btn.focus_neighbor_top = btn.get_path_to(above)
		btn.focus_neighbor_bottom = btn.get_path_to(below)
		btn.focus_previous = btn.get_path_to(above)
		btn.focus_next = btn.get_path_to(below)

func _set_menu_focus_enabled(enabled: bool) -> void:
	var mode: int = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	for btn in _preset_buttons:
		btn.focus_mode = mode
	for btn in _action_buttons:
		btn.focus_mode = mode

func _on_button_hovered(btn: Button) -> void:
	if btn.focus_mode != Control.FOCUS_NONE:
		btn.grab_focus()

func _on_button_focus_sfx() -> void:
	_play_sfx("ui_focus")

# ----------------------------------------------------------------- presets --

func _select_preset(preset_id: String) -> void:
	_selected_preset_id = preset_id
	_previewed_preset_id = preset_id
	_refresh_preset_buttons()
	ProjectSettings.set_setting(PRESET_SELECT_KEY, preset_id)

func _preview_preset(preset_id: String) -> void:
	_previewed_preset_id = preset_id
	_refresh_preset_buttons()

func _refresh_preset_buttons() -> void:
	var crown: Texture2D = _load_icon("icon_crown")
	for btn in _preset_buttons:
		var pid: String = String(btn.get_meta("preset_id", ""))
		var is_selected: bool = pid == _selected_preset_id
		_style_button(btn, COLOR_BLOOD_RED if is_selected else COLOR_DARK_FILL, 30)
		btn.icon = crown if is_selected else null
	if _blurb_label != null:
		var preset: Dictionary = MatchPreset.find(_previewed_preset_id)
		_blurb_label.text = String(preset.get("blurb", ""))

func _on_preset_button_focused(preset_id: String) -> void:
	_preview_preset(preset_id)

func _on_preset_button_pressed(preset_id: String) -> void:
	_select_preset(preset_id)
	_play_sfx("ui_click")

# ----------------------------------------------------------------- actions --

func _on_play_pressed() -> void:
	_play_sfx("ui_click")
	var preset: Dictionary = MatchPreset.find(_selected_preset_id)
	if _selected_preset_id == MatchPreset.ID_ADVENTURE:
		preset = MatchPreset.roll_adventure()
	var match_session: Node = get_node_or_null("/root/MatchSession")
	if match_session != null and match_session.has_method("set_preset"):
		match_session.call("set_preset", preset)
	get_tree().change_scene_to_file(MATCH_SCENE_PATH)

func _on_adventure_pressed() -> void:
	_play_sfx("ui_click")
	var flow: Node = get_node_or_null("/root/AdventureFlow")
	if flow != null and flow.has_method("open_hub"):
		flow.call("open_hub")
	else:
		_show_small_toast("ADVENTURE MODE UNAVAILABLE")

func _on_stats_pressed() -> void:
	_play_sfx("ui_click")
	_show_small_toast("STATS COMING SOON")

func _on_extras_pressed() -> void:
	_play_sfx("ui_click")
	_show_small_toast("EXTRAS COMING SOON")

func _on_settings_pressed() -> void:
	_play_sfx("ui_click")
	_is_settings_open = true
	_settings_panel.visible = true
	_set_menu_focus_enabled(false)
	if _settings_back_button != null:
		_settings_back_button.grab_focus()

func _on_settings_close() -> void:
	_play_sfx("ui_click")
	_is_settings_open = false
	_settings_panel.visible = false
	_set_menu_focus_enabled(true)
	if _play_button != null:
		_play_button.grab_focus()

func _on_quit_pressed() -> void:
	_play_sfx("ui_click")
	if OS.has_feature("web"):
		_show_small_toast("QUIT IS DISABLED IN BROWSER")
		return
	get_tree().quit()

func _show_small_toast(message: String) -> void:
	var toast: Label = Label.new()
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.anchor_left = 0.0
	toast.anchor_right = 1.0
	toast.anchor_top = 1.0
	toast.anchor_bottom = 1.0
	toast.offset_top = -190.0
	toast.offset_bottom = -140.0
	_style_accent_label(toast, 34, COLOR_GOLD)
	add_child(toast)
	var tween: Tween = create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.55).set_delay(1.0)
	tween.tween_callback(toast.queue_free)

func _input(event: InputEvent) -> void:
	if not _is_settings_open:
		return
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("ui_cancel"):
		_on_settings_close()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- settings --

func _build_settings_panel() -> void:
	_settings_panel = Control.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_panel)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.80)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.add_child(shade)

	var frame: PanelContainer = PanelContainer.new()
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -520.0
	frame.offset_right = 520.0
	frame.offset_top = -340.0
	frame.offset_bottom = 340.0
	frame.add_theme_stylebox_override("panel", _make_box(Color(0.04, 0.04, 0.05, 0.98), COLOR_GOLD, 5, 14, 40, 30))
	_settings_panel.add_child(frame)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(vbox)

	vbox.add_child(_make_display_label("SETTINGS", 56, COLOR_GOLD))
	vbox.add_child(_make_slider_row("MASTER VOLUME", -20.0, 0.0, _get_audio_volume("master_volume_db", 0.0), _on_master_changed))
	vbox.add_child(_make_slider_row("SFX VOLUME", -30.0, 6.0, _get_audio_volume("sfx_volume_db", -4.0), _on_sfx_changed))
	vbox.add_child(_make_slider_row("MUSIC VOLUME", -30.0, 6.0, _get_audio_volume("music_volume_db", -8.0), _on_music_changed))

	_settings_back_button = _make_menu_button("BACK", COLOR_DARK_FILL, "", 30, 76)
	_settings_back_button.custom_minimum_size = Vector2(360.0, 76.0)
	_settings_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_settings_back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_back_button.pressed.connect(_on_settings_close)
	vbox.add_child(_settings_back_button)

func _make_slider_row(label_text: String, min_val: float, max_val: float, current: float, on_change: Callable) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(320.0, 0.0)
	_style_accent_label(label, 24, COLOR_BONE)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.5
	slider.value = current
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(360.0, 36.0)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row

func _get_audio_volume(setting_name: String, fallback: float) -> float:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx == null:
		return fallback
	return float(sfx.get(setting_name))

func _on_master_changed(value: float) -> void:
	_set_audio_setting("master_volume_db", value)

func _on_sfx_changed(value: float) -> void:
	_set_audio_setting("sfx_volume_db", value)

func _on_music_changed(value: float) -> void:
	_set_audio_setting("music_volume_db", value)

func _set_audio_setting(setting_name: String, value: float) -> void:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx != null:
		sfx.set(setting_name, value)
		if sfx.has_method("apply_saved_settings"):
			sfx.call("apply_saved_settings")

func _play_sfx(sound_id: String) -> void:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", sound_id)

# ----------------------------------------------------------------- ambient --

func _start_ambient_motion() -> void:
	if _logo != null:
		var breathe: Tween = create_tween().set_loops()
		breathe.tween_property(_logo, "scale", Vector2(1.014, 1.014), 2.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		breathe.tween_property(_logo, "scale", Vector2(1.0, 1.0), 2.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _logo_material != null:
		var sweep: Tween = create_tween().set_loops()
		sweep.tween_interval(4.2)
		sweep.tween_method(func(value: float) -> void:
			_logo_material.set_shader_parameter("sweep_pos", value)
		, -0.4, 1.6, 1.15)

func _update_ambient_bounds() -> void:
	if _snow == null:
		return
	var view_size: Vector2 = get_viewport_rect().size
	_snow.position = Vector2(view_size.x * 0.5, -60.0)
	_snow.emission_rect_extents = Vector2(view_size.x * 0.55, 30.0)
