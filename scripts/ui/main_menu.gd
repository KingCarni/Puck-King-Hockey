extends Control

const MATCH_SCENE_PATH: String = "res://scenes/match/TestRink.tscn"
const PRESET_SELECT_KEY: String = "puck_king_hell/selected_preset_id"

var _palette: Node = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _play_button: Button = null
var _settings_button: Button = null
var _quit_button: Button = null
var _preset_buttons: Array[Button] = []
var _preset_blurb_label: Label = null
var _settings_panel: Control = null
var _selected_preset_id: String = MatchPreset.ID_STANDARD
var _is_settings_open: bool = false

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_select_preset(_selected_preset_id)
	_play_button.grab_focus()

func _build_ui() -> void:
	var backdrop: ColorRect = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.03, 0.03, 0.05, 1.0)
	add_child(backdrop)

	var diag: ColorRect = ColorRect.new()
	diag.name = "DiagSlash"
	diag.color = Color(0.85, 0.10, 0.13, 0.18)
	diag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	diag.rotation = deg_to_rad(-6.0)
	diag.offset_left = -400.0
	diag.offset_right = 400.0
	add_child(diag)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.name = "RootLayout"
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 120.0
	root_vbox.offset_right = -120.0
	root_vbox.offset_top = 60.0
	root_vbox.offset_bottom = -60.0
	root_vbox.add_theme_constant_override("separation", 32)
	add_child(root_vbox)

	_build_title(root_vbox)
	_build_body(root_vbox)
	_build_settings_panel()

func _build_title(parent: VBoxContainer) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 28)
	parent.add_child(header)

	var bolt_left: Label = Label.new()
	bolt_left.text = "!"
	bolt_left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(bolt_left)

	var title_block: VBoxContainer = VBoxContainer.new()
	title_block.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_block)

	_title_label = Label.new()
	_title_label.text = "PUCK KING HELL"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_block.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "AN ARCADE HOCKEY ROGUELITE"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_block.add_child(_subtitle_label)

	var bolt_right: Label = Label.new()
	bolt_right.text = "!"
	bolt_right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(bolt_right)

	if _palette != null:
		_palette.style_display_label(_title_label, 132, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_subtitle_label, 30, _palette.COLOR_BONE)
		_palette.style_display_label(bolt_left, 124, _palette.COLOR_HOT_GOLD)
		_palette.style_display_label(bolt_right, 124, _palette.COLOR_HOT_GOLD)

func _build_body(parent: VBoxContainer) -> void:
	var body: HBoxContainer = HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 36)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(body)

	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(820.0, 0.0)
	left_panel.add_theme_stylebox_override("panel", _make_panel_style())
	body.add_child(left_panel)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 14)
	left_panel.add_child(left_vbox)

	var preset_title: Label = Label.new()
	preset_title.text = "SELECT MATCH"
	if _palette != null:
		_palette.style_accent_label(preset_title, 30, _palette.COLOR_GOLD)
	left_vbox.add_child(preset_title)

	for preset in MatchPreset.catalog():
		var btn: Button = Button.new()
		btn.text = String(preset.get("title", "?"))
		btn.custom_minimum_size = Vector2(0.0, 76.0)
		btn.focus_mode = Control.FOCUS_ALL
		var preset_id: String = String(preset.get("id", ""))
		btn.set_meta("preset_id", preset_id)
		btn.pressed.connect(_on_preset_button_pressed.bind(preset_id))
		btn.focus_entered.connect(_on_preset_button_focused.bind(preset_id))
		btn.mouse_entered.connect(_on_preset_button_focused.bind(preset_id))
		if _palette != null:
			_palette.style_button(btn, _palette.COLOR_BLACK, _palette.COLOR_GOLD, _palette.COLOR_BONE, 28)
		left_vbox.add_child(btn)
		_preset_buttons.append(btn)

	_preset_blurb_label = Label.new()
	_preset_blurb_label.text = ""
	_preset_blurb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _palette != null:
		_palette.style_accent_label(_preset_blurb_label, 22, _palette.COLOR_STEEL)
	left_vbox.add_child(_preset_blurb_label)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(560.0, 0.0)
	right_panel.add_theme_stylebox_override("panel", _make_panel_style())
	body.add_child(right_panel)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 18)
	right_panel.add_child(right_vbox)

	var actions_title: Label = Label.new()
	actions_title.text = "FACEOFF"
	if _palette != null:
		_palette.style_accent_label(actions_title, 30, _palette.COLOR_GOLD)
	right_vbox.add_child(actions_title)

	_play_button = _make_button("PLAY MATCH", _on_play_pressed, true)
	_settings_button = _make_button("SETTINGS", _on_settings_pressed, false)
	_quit_button = _make_button("QUIT", _on_quit_pressed, false)
	right_vbox.add_child(_play_button)
	right_vbox.add_child(_settings_button)
	right_vbox.add_child(_quit_button)

	var hint: Label = Label.new()
	hint.text = "ENTER / A - CONFIRM    ESC - QUIT"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null:
		_palette.style_accent_label(hint, 18, _palette.COLOR_STEEL)
	right_vbox.add_child(hint)

func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.06, 0.96)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 18
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

func _make_button(text: String, callback: Callable, accent: bool) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 80.0)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(callback)
	if _palette != null:
		var fill: Color = _palette.COLOR_BLOOD_RED if accent else _palette.COLOR_BLACK
		_palette.style_button(btn, fill, _palette.COLOR_GOLD, _palette.COLOR_BONE, 32)
	return btn

func _build_settings_panel() -> void:
	_settings_panel = Control.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_panel)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.78)
	_settings_panel.add_child(shade)

	var frame: PanelContainer = PanelContainer.new()
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -560.0
	frame.offset_right = 560.0
	frame.offset_top = -380.0
	frame.offset_bottom = 380.0
	frame.add_theme_stylebox_override("panel", _make_panel_style())
	_settings_panel.add_child(frame)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	frame.add_child(vbox)

	var title: Label = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null:
		_palette.style_display_label(title, 64, _palette.COLOR_HOT_GOLD)
	vbox.add_child(title)

	vbox.add_child(_make_slider_row("MASTER VOLUME", -20.0, 0.0, _get_audio_volume("master_volume_db", 0.0), _on_master_changed))
	vbox.add_child(_make_slider_row("SFX VOLUME", -30.0, 6.0, _get_audio_volume("sfx_volume_db", -4.0), _on_sfx_changed))
	vbox.add_child(_make_slider_row("MUSIC VOLUME", -30.0, 6.0, _get_audio_volume("music_volume_db", -8.0), _on_music_changed))

	var rebind_label: Label = Label.new()
	rebind_label.text = "REBIND CONTROLS - COMING SOON"
	rebind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null:
		_palette.style_accent_label(rebind_label, 22, _palette.COLOR_STEEL)
	vbox.add_child(rebind_label)

	var close_btn: Button = Button.new()
	close_btn.text = "BACK"
	close_btn.custom_minimum_size = Vector2(360.0, 64.0)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_on_settings_close)
	if _palette != null:
		_palette.style_button(close_btn, _palette.COLOR_BLOOD_RED, _palette.COLOR_GOLD, _palette.COLOR_BONE, 28)
	vbox.add_child(close_btn)

func _make_slider_row(label_text: String, min_val: float, max_val: float, current: float, on_change: Callable) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(320.0, 0.0)
	if _palette != null:
		_palette.style_accent_label(label, 22, _palette.COLOR_BONE)
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
	_preview_preset(preset_id)
	_refresh_preset_button_styles()

func _preview_preset(preset_id: String) -> void:
	var data: Dictionary = MatchPreset.find(preset_id)
	if _preset_blurb_label != null:
		_preset_blurb_label.text = String(data.get("blurb", ""))

func _refresh_preset_button_styles() -> void:
	for btn in _preset_buttons:
		var pid: String = String(btn.get_meta("preset_id", ""))
		_apply_preset_button_style(btn, pid == _selected_preset_id)

func _apply_preset_button_style(btn: Button, is_selected: bool) -> void:
	if _palette == null:
		return
	var fill: Color = _palette.COLOR_BLOOD_RED if is_selected else _palette.COLOR_BLACK
	var border: Color = _palette.COLOR_HOT_GOLD if is_selected else _palette.COLOR_GOLD
	_palette.style_button(btn, fill, border, _palette.COLOR_BONE, 28)

func _on_preset_button_focused(preset_id: String) -> void:
	_preview_preset(preset_id)
	_refresh_preset_button_styles()
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
	_play_button.grab_focus()

func _on_quit_pressed() -> void:
	_play_sfx("ui_click")
	get_tree().quit()

func _on_master_changed(v: float) -> void:
	_call_sfx_method("set_master_volume", [v])

func _on_sfx_changed(v: float) -> void:
	_call_sfx_method("set_sfx_volume", [v])
	_play_sfx("ui_focus")

func _on_music_changed(v: float) -> void:
	_call_sfx_method("set_music_volume", [v])

func _unhandled_input(event: InputEvent) -> void:
	if _is_settings_open:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu"):
			_on_settings_close()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
		get_viewport().set_input_as_handled()

func _get_audio_volume(property_name: String, default_value: float) -> float:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx == null:
		return default_value
	return float(sfx.get(property_name))

func _play_sfx(sfx_id: String) -> void:
	_call_sfx_method("play", [sfx_id])

func _call_sfx_method(method_name: String, args: Array) -> void:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx == null or not sfx.has_method(method_name):
		return
	sfx.callv(method_name, args)
