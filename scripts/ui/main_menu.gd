extends Control

const MATCH_SCENE_PATH: String = "res://scenes/match/TestRink.tscn"
const PRESET_SELECT_KEY: String = "puck_king_hell/selected_preset_id"
const MENU_WEBP_PATH: String = "res://assets/ui/title_screen/pkh_main_menu.webp"
const MENU_PNG_PATH: String = "res://assets/ui/title_screen/pkh_main_menu.png"
const LOGO_WEBP_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.webp"
const LOGO_PNG_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.png"

var _palette: Node = null
var _using_menu_art: bool = false
var _play_button: Button = null
var _settings_button: Button = null
var _stats_button: Button = null
var _extras_button: Button = null
var _quit_button: Button = null
var _preset_buttons: Array[Button] = []
var _selected_preset_id: String = MatchPreset.ID_STANDARD
var _previewed_preset_id: String = MatchPreset.ID_STANDARD
var _settings_panel: Control = null
var _is_settings_open: bool = false

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_select_preset(_selected_preset_id)
	if _play_button != null:
		_play_button.grab_focus()

func _build_ui() -> void:
	_build_backdrop()
	if _using_menu_art:
		_build_art_hotspots()
	else:
		_build_fallback_menu()
	_build_settings_panel()

func _build_backdrop() -> void:
	var texture: Texture2D = _load_menu_texture()
	if texture != null:
		_using_menu_art = true
		var art: TextureRect = TextureRect.new()
		art.name = "GeneratedMenuArt"
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		return

	_using_menu_art = false
	var base: ColorRect = ColorRect.new()
	base.name = "FallbackBackdrop"
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.018, 0.018, 0.026, 1.0)
	add_child(base)

	var red_wash: ColorRect = ColorRect.new()
	red_wash.name = "RedWash"
	red_wash.anchor_left = 0.0
	red_wash.anchor_right = 0.52
	red_wash.anchor_top = 0.0
	red_wash.anchor_bottom = 1.0
	red_wash.color = Color(0.22, 0.02, 0.04, 0.55)
	add_child(red_wash)

	var blue_wash: ColorRect = ColorRect.new()
	blue_wash.name = "BlueWash"
	blue_wash.anchor_left = 0.48
	blue_wash.anchor_right = 1.0
	blue_wash.anchor_top = 0.0
	blue_wash.anchor_bottom = 1.0
	blue_wash.color = Color(0.02, 0.07, 0.20, 0.50)
	add_child(blue_wash)

func _build_art_hotspots() -> void:
	# The generated menu concept already contains the visible logo/buttons.
	# These invisible/low-alpha controls sit over the art so the screen is actually playable.
	_build_mode_hotspots()
	_build_action_hotspots()
	_build_mode_detail_overlay()

func _build_mode_hotspots() -> void:
	var presets: Array = MatchPreset.catalog()
	var y_start: float = 0.390
	var row_height: float = 0.075
	var row_gap: float = 0.018
	for index in range(presets.size()):
		var preset: Dictionary = presets[index]
		var preset_id: String = String(preset.get("id", ""))
		var btn: Button = _make_hotspot_button(preset_id)
		btn.anchor_left = 0.188
		btn.anchor_right = 0.455
		btn.anchor_top = y_start + float(index) * (row_height + row_gap)
		btn.anchor_bottom = btn.anchor_top + row_height
		btn.set_meta("preset_id", preset_id)
		btn.pressed.connect(_on_preset_button_pressed.bind(preset_id))
		btn.focus_entered.connect(_on_preset_button_focused.bind(preset_id))
		btn.mouse_entered.connect(_on_preset_button_focused.bind(preset_id))
		add_child(btn)
		_preset_buttons.append(btn)

func _build_action_hotspots() -> void:
	var y_start: float = 0.390
	var row_height: float = 0.075
	var row_gap: float = 0.018
	_play_button = _make_hotspot_button("play")
	_settings_button = _make_hotspot_button("settings")
	_stats_button = _make_hotspot_button("stats")
	_extras_button = _make_hotspot_button("extras")
	_quit_button = _make_hotspot_button("quit")

	var buttons: Array[Button] = [_play_button, _stats_button, _extras_button, _settings_button, _quit_button]
	var callbacks: Array[Callable] = [_on_play_pressed, _on_stats_pressed, _on_extras_pressed, _on_settings_pressed, _on_quit_pressed]
	for index in range(buttons.size()):
		var btn: Button = buttons[index]
		btn.anchor_left = 0.565
		btn.anchor_right = 0.820
		btn.anchor_top = y_start + float(index) * (row_height + row_gap)
		btn.anchor_bottom = btn.anchor_top + row_height
		btn.pressed.connect(callbacks[index])
		add_child(btn)

func _build_mode_detail_overlay() -> void:
	# Reserved for later. The approved concept image currently has no detail panel.
	# PKH-23 will replace the baked image with separated assets and a live detail card.
	pass

func _build_fallback_menu() -> void:
	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.name = "FallbackRootLayout"
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 160.0
	root_vbox.offset_right = -160.0
	root_vbox.offset_top = 80.0
	root_vbox.offset_bottom = -90.0
	root_vbox.add_theme_constant_override("separation", 24)
	add_child(root_vbox)

	_build_fallback_title(root_vbox)
	var body: HBoxContainer = HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 76)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(body)
	_build_fallback_match_panel(body)
	_build_fallback_action_panel(body)

func _build_fallback_title(parent: VBoxContainer) -> void:
	var logo_texture: Texture2D = _load_logo_texture()
	if logo_texture != null:
		var logo: TextureRect = TextureRect.new()
		logo.texture = logo_texture
		logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.custom_minimum_size = Vector2(0.0, 270.0)
		parent.add_child(logo)
		return

	var title: Label = Label.new()
	title.text = "PUCK KING HELL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 96)
	title.modulate = Color(1.0, 0.95, 0.80, 1.0)
	parent.add_child(title)

func _build_fallback_match_panel(parent: HBoxContainer) -> void:
	var panel: VBoxContainer = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(720.0, 0.0)
	panel.add_theme_constant_override("separation", 14)
	parent.add_child(panel)
	var title: Label = _make_label("MATCH MODES", 44, Color(1.0, 0.78, 0.10, 1.0))
	panel.add_child(title)
	for preset in MatchPreset.catalog():
		var preset_id: String = String(preset.get("id", ""))
		var text: String = "%s\n%s" % [String(preset.get("title", "MATCH")).to_upper(), String(preset.get("blurb", ""))]
		var btn: Button = _make_visible_button(text, true)
		btn.set_meta("preset_id", preset_id)
		btn.pressed.connect(_on_preset_button_pressed.bind(preset_id))
		btn.focus_entered.connect(_on_preset_button_focused.bind(preset_id))
		btn.mouse_entered.connect(_on_preset_button_focused.bind(preset_id))
		panel.add_child(btn)
		_preset_buttons.append(btn)

func _build_fallback_action_panel(parent: HBoxContainer) -> void:
	var panel: VBoxContainer = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 0.0)
	panel.add_theme_constant_override("separation", 16)
	parent.add_child(panel)
	var title: Label = _make_label("ACTIONS", 44, Color(1.0, 0.78, 0.10, 1.0))
	panel.add_child(title)
	_play_button = _make_visible_button("PLAY", false)
	_stats_button = _make_visible_button("STATS", false)
	_extras_button = _make_visible_button("EXTRAS", false)
	_settings_button = _make_visible_button("SETTINGS", false)
	_quit_button = _make_visible_button("QUIT", false)
	_play_button.pressed.connect(_on_play_pressed)
	_stats_button.pressed.connect(_on_stats_pressed)
	_extras_button.pressed.connect(_on_extras_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	panel.add_child(_play_button)
	panel.add_child(_stats_button)
	panel.add_child(_extras_button)
	panel.add_child(_settings_button)
	panel.add_child(_quit_button)

func _make_hotspot_button(node_name: String) -> Button:
	var btn: Button = Button.new()
	btn.name = "Hotspot_%s" % node_name
	btn.text = ""
	btn.focus_mode = Control.FOCUS_ALL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("normal", _make_hotspot_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0))
	btn.add_theme_stylebox_override("hover", _make_hotspot_style(Color(1.0, 0.78, 0.10, 0.08), Color(1.0, 0.78, 0.10, 0.85), 4))
	btn.add_theme_stylebox_override("focus", _make_hotspot_style(Color(1.0, 0.78, 0.10, 0.10), Color(1.0, 0.92, 0.30, 1.0), 5))
	btn.add_theme_stylebox_override("pressed", _make_hotspot_style(Color(1.0, 0.20, 0.22, 0.16), Color(1.0, 0.92, 0.30, 1.0), 5))
	return btn

func _make_visible_button(text: String, is_mode: bool) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0.0, 92.0 if is_mode else 86.0)
	btn.focus_mode = Control.FOCUS_ALL
	btn.add_theme_font_size_override("font_size", 30 if is_mode else 38)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))
	btn.add_theme_stylebox_override("normal", _make_hotspot_style(Color(0.02, 0.02, 0.025, 0.90), Color(0.30, 0.32, 0.36, 1.0), 3))
	btn.add_theme_stylebox_override("hover", _make_hotspot_style(Color(0.55, 0.04, 0.06, 0.95), Color(1.0, 0.78, 0.10, 1.0), 4))
	btn.add_theme_stylebox_override("focus", _make_hotspot_style(Color(0.65, 0.05, 0.07, 0.95), Color(1.0, 0.92, 0.30, 1.0), 5))
	btn.add_theme_stylebox_override("pressed", _make_hotspot_style(Color(0.75, 0.06, 0.08, 1.0), Color(1.0, 0.92, 0.30, 1.0), 5))
	return btn

func _make_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_hotspot_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

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
	frame.add_theme_stylebox_override("panel", _make_hotspot_style(Color(0.04, 0.04, 0.05, 0.98), Color(1.0, 0.78, 0.10, 1.0), 5))
	_settings_panel.add_child(frame)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	frame.add_child(vbox)
	vbox.add_child(_make_label("SETTINGS", 64, Color(1.0, 0.78, 0.10, 1.0)))
	vbox.add_child(_make_slider_row("MASTER VOLUME", -20.0, 0.0, _get_audio_volume("master_volume_db", 0.0), _on_master_changed))
	vbox.add_child(_make_slider_row("SFX VOLUME", -30.0, 6.0, _get_audio_volume("sfx_volume_db", -4.0), _on_sfx_changed))
	vbox.add_child(_make_slider_row("MUSIC VOLUME", -30.0, 6.0, _get_audio_volume("music_volume_db", -8.0), _on_music_changed))

	var close_btn: Button = _make_visible_button("BACK", false)
	close_btn.custom_minimum_size = Vector2(360.0, 76.0)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_on_settings_close)
	vbox.add_child(close_btn)

func _make_slider_row(label_text: String, min_val: float, max_val: float, current: float, on_change: Callable) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(320.0, 0.0)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.5
	slider.value = current
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(360.0, 36.0)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row

func _select_preset(preset_id: String) -> void:
	_selected_preset_id = preset_id
	_previewed_preset_id = preset_id
	_refresh_preset_button_styles()
	ProjectSettings.set_setting(PRESET_SELECT_KEY, preset_id)

func _preview_preset(preset_id: String) -> void:
	_previewed_preset_id = preset_id
	_refresh_preset_button_styles()

func _refresh_preset_button_styles() -> void:
	for btn in _preset_buttons:
		var pid: String = String(btn.get_meta("preset_id", ""))
		var is_selected: bool = pid == _selected_preset_id
		var is_previewed: bool = pid == _previewed_preset_id
		if _using_menu_art:
			_apply_art_button_style(btn, is_selected, is_previewed)
		else:
			_apply_visible_preset_style(btn, is_selected, is_previewed)

func _apply_art_button_style(btn: Button, is_selected: bool, is_previewed: bool) -> void:
	if is_selected:
		btn.add_theme_stylebox_override("normal", _make_hotspot_style(Color(1.0, 0.08, 0.10, 0.18), Color(1.0, 0.78, 0.10, 0.90), 4))
	elif is_previewed:
		btn.add_theme_stylebox_override("normal", _make_hotspot_style(Color(1.0, 0.78, 0.10, 0.09), Color(1.0, 0.78, 0.10, 0.60), 3))
	else:
		btn.add_theme_stylebox_override("normal", _make_hotspot_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 0))

func _apply_visible_preset_style(btn: Button, is_selected: bool, is_previewed: bool) -> void:
	var fill: Color = Color(0.65, 0.04, 0.06, 0.95) if is_selected else Color(0.02, 0.02, 0.025, 0.90)
	if is_previewed and not is_selected:
		fill = Color(0.12, 0.08, 0.04, 0.95)
	var border: Color = Color(1.0, 0.78, 0.10, 1.0) if is_selected else Color(0.30, 0.32, 0.36, 1.0)
	btn.add_theme_stylebox_override("normal", _make_hotspot_style(fill, border, 4))

func _on_preset_button_focused(preset_id: String) -> void:
	_preview_preset(preset_id)
	_play_sfx("ui_focus")

func _on_preset_button_pressed(preset_id: String) -> void:
	_select_preset(preset_id)
	_play_sfx("ui_click")

func _on_play_pressed() -> void:
	_play_sfx("ui_click")
	var preset: Dictionary = MatchPreset.find(_selected_preset_id)
	if _selected_preset_id == MatchPreset.ID_ADVENTURE:
		preset = MatchPreset.roll_adventure()
	var match_session: Node = get_node_or_null("/root/MatchSession")
	if match_session != null and match_session.has_method("set_preset"):
		match_session.call("set_preset", preset)
	get_tree().change_scene_to_file(MATCH_SCENE_PATH)

func _on_settings_pressed() -> void:
	_play_sfx("ui_click")
	_is_settings_open = true
	_settings_panel.visible = true

func _on_settings_close() -> void:
	_play_sfx("ui_click")
	_is_settings_open = false
	_settings_panel.visible = false
	if _play_button != null:
		_play_button.grab_focus()

func _on_stats_pressed() -> void:
	_play_sfx("ui_click")
	_show_small_toast("STATS COMING SOON")

func _on_extras_pressed() -> void:
	_play_sfx("ui_click")
	_show_small_toast("EXTRAS COMING SOON")

func _on_quit_pressed() -> void:
	_play_sfx("ui_click")
	get_tree().quit()

func _show_small_toast(message: String) -> void:
	var toast: Label = Label.new()
	toast.text = message
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.anchor_left = 0.0
	toast.anchor_right = 1.0
	toast.anchor_top = 1.0
	toast.anchor_bottom = 1.0
	toast.offset_top = -170.0
	toast.offset_bottom = -120.0
	toast.add_theme_font_size_override("font_size", 34)
	toast.add_theme_color_override("font_color", Color(1.0, 0.78, 0.10, 1.0))
	add_child(toast)
	var tween: Tween = create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, 0.55).set_delay(1.0)
	tween.tween_callback(toast.queue_free)

func _input(event: InputEvent) -> void:
	if _is_settings_open and event.is_action_pressed("pause_menu"):
		_on_settings_close()
		get_viewport().set_input_as_handled()

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

func _load_menu_texture() -> Texture2D:
	if ResourceLoader.exists(MENU_WEBP_PATH):
		return load(MENU_WEBP_PATH) as Texture2D
	if ResourceLoader.exists(MENU_PNG_PATH):
		return load(MENU_PNG_PATH) as Texture2D
	return null

func _load_logo_texture() -> Texture2D:
	if ResourceLoader.exists(LOGO_WEBP_PATH):
		return load(LOGO_WEBP_PATH) as Texture2D
	if ResourceLoader.exists(LOGO_PNG_PATH):
		return load(LOGO_PNG_PATH) as Texture2D
	return null
