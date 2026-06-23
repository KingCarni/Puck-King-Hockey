extends Control

const MATCH_SCENE_PATH: String = "res://scenes/match/TestRink.tscn"
const PRESET_SELECT_KEY: String = "puck_king_hell/selected_preset_id"

var _palette: Node = null
var _title_puck_left: Label = null
var _title_puck_right: Label = null
var _title_puck_king: Label = null
var _title_hell: Label = null
var _subtitle_label: Label = null
var _play_button: Button = null
var _settings_button: Button = null
var _stats_button: Button = null
var _extras_button: Button = null
var _quit_button: Button = null
var _preset_buttons: Array[Button] = []
var _preset_blurb_title: Label = null
var _preset_blurb_label: Label = null
var _settings_panel: Control = null
var _selected_preset_id: String = MatchPreset.ID_STANDARD
var _previewed_preset_id: String = MatchPreset.ID_STANDARD
var _is_settings_open: bool = false

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_select_preset(_selected_preset_id)
	_play_button.grab_focus()

func _build_ui() -> void:
	_build_backdrop()

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.name = "RootLayout"
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_left = 120.0
	root_vbox.offset_right = -120.0
	root_vbox.offset_top = 52.0
	root_vbox.offset_bottom = -56.0
	root_vbox.add_theme_constant_override("separation", 18)
	add_child(root_vbox)

	_build_title(root_vbox)
	_build_body(root_vbox)
	_build_footer()
	_build_settings_panel()

func _build_backdrop() -> void:
	var base: ColorRect = ColorRect.new()
	base.name = "ArenaBackdrop"
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.color = Color(0.018, 0.018, 0.026, 1.0)
	add_child(base)

	var blood_wash: ColorRect = ColorRect.new()
	blood_wash.name = "BloodWash"
	blood_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blood_wash.color = Color(0.22, 0.02, 0.04, 0.62)
	blood_wash.rotation = deg_to_rad(-4.0)
	blood_wash.offset_left = -240.0
	blood_wash.offset_right = 240.0
	blood_wash.offset_top = -90.0
	blood_wash.offset_bottom = 90.0
	add_child(blood_wash)

	var bottom_slab: ColorRect = ColorRect.new()
	bottom_slab.name = "BottomBlackSlash"
	bottom_slab.anchor_left = 0.0
	bottom_slab.anchor_right = 1.0
	bottom_slab.anchor_top = 0.78
	bottom_slab.anchor_bottom = 1.14
	bottom_slab.color = Color(0.01, 0.012, 0.018, 0.92)
	bottom_slab.rotation = deg_to_rad(-4.5)
	add_child(bottom_slab)

	_build_side_banner("LeftArenaBanner", true)
	_build_side_banner("RightArenaBanner", false)
	_build_spark_field()

func _build_side_banner(node_name: String, is_left: bool) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = node_name
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.88
	panel.custom_minimum_size = Vector2(170.0, 0.0)
	if is_left:
		panel.anchor_left = 0.0
		panel.anchor_right = 0.0
		panel.offset_left = 14.0
		panel.offset_right = 184.0
	else:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
		panel.offset_left = -184.0
		panel.offset_right = -14.0
	panel.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.03, 0.03, 0.04, 0.58), Color(0.80, 0.10, 0.14, 0.88), 3))
	add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var top: Label = Label.new()
	top.text = "PUCK" if is_left else "HELL"
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(top)

	var mid: Label = Label.new()
	mid.text = "KING" if is_left else "LEAGUE"
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(mid)

	var puck: Label = Label.new()
	puck.text = "♛\n●"
	puck.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(puck)

	if _palette != null:
		_palette.style_display_label(top, 38, _palette.COLOR_BONE)
		_palette.style_display_label(mid, 34, _palette.COLOR_STEEL)
		_palette.style_display_label(puck, 44, _palette.COLOR_GOLD)

func _build_spark_field() -> void:
	for index: int in range(22):
		var spark: ColorRect = ColorRect.new()
		spark.name = "Spark%02d" % index
		var from_left: bool = index % 2 == 0
		spark.anchor_left = 0.0 if from_left else 1.0
		spark.anchor_right = spark.anchor_left
		spark.anchor_top = 0.18 + float(index % 11) * 0.055
		spark.anchor_bottom = spark.anchor_top
		spark.offset_left = (64.0 + float(index % 5) * 14.0) if from_left else (-128.0 - float(index % 5) * 14.0)
		spark.offset_right = spark.offset_left + 72.0
		spark.offset_top = 0.0
		spark.offset_bottom = 5.0
		spark.rotation = deg_to_rad(18.0 if from_left else -18.0)
		spark.color = Color(1.0, 0.78, 0.10, 0.35) if index % 3 == 0 else Color(0.85, 0.08, 0.12, 0.32)
		add_child(spark)

func _build_title(parent: VBoxContainer) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	parent.add_child(header)

	_title_puck_left = _make_title_puck()
	header.add_child(_title_puck_left)

	var title_block: VBoxContainer = VBoxContainer.new()
	title_block.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_block)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 22)
	title_block.add_child(title_row)

	_title_puck_king = Label.new()
	_title_puck_king.text = "PUCK KING"
	_title_puck_king.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(_title_puck_king)

	_title_hell = Label.new()
	_title_hell.text = "HE⌞⌞!"
	_title_hell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(_title_hell)

	_subtitle_label = Label.new()
	_subtitle_label.text = "AN ARCADE HOCKEY ROGUELITE"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_block.add_child(_subtitle_label)

	_title_puck_right = _make_title_puck()
	header.add_child(_title_puck_right)

	if _palette != null:
		_palette.style_display_label(_title_puck_king, 116, _palette.COLOR_BONE)
		_palette.style_display_label(_title_hell, 116, _palette.COLOR_FIRE_RED)
		_palette.style_accent_label(_subtitle_label, 28, _palette.COLOR_BONE)
		_palette.style_display_label(_title_puck_left, 70, _palette.COLOR_GOLD)
		_palette.style_display_label(_title_puck_right, 70, _palette.COLOR_GOLD)

func _make_title_puck() -> Label:
	var label: Label = Label.new()
	label.text = "♛\n●"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(132.0, 112.0)
	return label

func _build_body(parent: VBoxContainer) -> void:
	var body: HBoxContainer = HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 44)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(body)

	_build_match_panel(body)
	_build_action_panel(body)

func _build_match_panel(parent: HBoxContainer) -> void:
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(880.0, 0.0)
	left_panel.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.04, 0.04, 0.05, 0.96), Color(1.0, 0.78, 0.10, 1.0), 5))
	parent.add_child(left_panel)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 14)
	left_panel.add_child(left_vbox)

	var preset_title: Label = Label.new()
	preset_title.text = "★ SELECT MATCH ★"
	preset_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null:
		_palette.style_accent_label(preset_title, 40, _palette.COLOR_GOLD)
	left_vbox.add_child(preset_title)

	for preset in MatchPreset.catalog():
		var preset_id: String = String(preset.get("id", ""))
		var row_title: String = String(preset.get("title", "?"))
		var row_blurb: String = String(preset.get("blurb", ""))
		var icon: String = _icon_for_preset(preset_id)
		var btn: Button = _make_mode_button(icon, row_title, row_blurb, preset_id)
		left_vbox.add_child(btn)
		_preset_buttons.append(btn)

	var info_panel: PanelContainer = PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.02, 0.02, 0.025, 0.88), Color(1.0, 0.62, 0.05, 1.0), 3))
	left_vbox.add_child(info_panel)

	var info_row: HBoxContainer = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 18)
	info_panel.add_child(info_row)

	var info_icon: Label = Label.new()
	info_icon.text = "ⓘ"
	info_icon.custom_minimum_size = Vector2(76.0, 0.0)
	info_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_row.add_child(info_icon)

	var info_text: VBoxContainer = VBoxContainer.new()
	info_row.add_child(info_text)

	_preset_blurb_title = Label.new()
	_preset_blurb_title.text = "STANDARD MATCH"
	info_text.add_child(_preset_blurb_title)

	_preset_blurb_label = Label.new()
	_preset_blurb_label.text = ""
	_preset_blurb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.add_child(_preset_blurb_label)

	if _palette != null:
		_palette.style_display_label(info_icon, 42, _palette.COLOR_GOLD)
		_palette.style_accent_label(_preset_blurb_title, 24, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_preset_blurb_label, 22, _palette.COLOR_BONE)

func _build_action_panel(parent: HBoxContainer) -> void:
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(600.0, 0.0)
	right_panel.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.04, 0.04, 0.05, 0.96), Color(0.18, 0.55, 1.0, 1.0), 5))
	parent.add_child(right_panel)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 16)
	right_panel.add_child(right_vbox)

	var actions_title: Label = Label.new()
	actions_title.text = "★ FACEOFF ★"
	actions_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _palette != null:
		_palette.style_accent_label(actions_title, 40, _palette.COLOR_GOLD)
	right_vbox.add_child(actions_title)

	_play_button = _make_action_button("●  PLAY MATCH     »", _on_play_pressed, true)
	_settings_button = _make_action_button("⚙  SETTINGS", _on_settings_pressed, false)
	_stats_button = _make_action_button("▰  STATS", _on_stats_pressed, false)
	_extras_button = _make_action_button("▣  EXTRAS", _on_extras_pressed, false)
	_quit_button = _make_action_button("▸  QUIT", _on_quit_pressed, false)
	right_vbox.add_child(_play_button)
	right_vbox.add_child(_settings_button)
	right_vbox.add_child(_stats_button)
	right_vbox.add_child(_extras_button)
	right_vbox.add_child(_quit_button)

	var pit_panel: PanelContainer = PanelContainer.new()
	pit_panel.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.02, 0.02, 0.025, 0.86), Color(1.0, 0.62, 0.05, 1.0), 3))
	right_vbox.add_child(pit_panel)

	var pit_row: HBoxContainer = HBoxContainer.new()
	pit_row.add_theme_constant_override("separation", 16)
	pit_panel.add_child(pit_row)

	var pit_icon: Label = Label.new()
	pit_icon.text = "♛\n●"
	pit_icon.custom_minimum_size = Vector2(90.0, 0.0)
	pit_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pit_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pit_row.add_child(pit_icon)

	var pit_text: VBoxContainer = VBoxContainer.new()
	pit_row.add_child(pit_text)

	var pit_title: Label = Label.new()
	pit_title.text = "GET IN THE PIT"
	pit_text.add_child(pit_title)

	var pit_body: Label = Label.new()
	pit_body.text = "Score goals, draft upgrades, and become the Puck King of Hell."
	pit_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pit_text.add_child(pit_body)

	if _palette != null:
		_palette.style_display_label(pit_icon, 42, _palette.COLOR_GOLD)
		_palette.style_accent_label(pit_title, 24, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(pit_body, 20, _palette.COLOR_BONE)

func _build_footer() -> void:
	var footer: PanelContainer = PanelContainer.new()
	footer.name = "ControllerFooter"
	footer.anchor_left = 0.0
	footer.anchor_right = 1.0
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = 0.0
	footer.offset_right = 0.0
	footer.offset_top = -72.0
	footer.offset_bottom = 0.0
	footer.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.015, 0.015, 0.018, 0.92), Color(1.0, 0.78, 0.10, 0.70), 2))
	add_child(footer)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 150)
	footer.add_child(row)

	var nav: Label = _make_footer_label("⚡ NAVIGATE")
	var select: Label = _make_footer_label("Ⓐ SELECT")
	var back: Label = _make_footer_label("Ⓑ BACK")
	var glory: Label = _make_footer_label("♛ GLORY AWAITS")
	row.add_child(nav)
	row.add_child(select)
	row.add_child(back)
	row.add_child(glory)

func _make_footer_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	if _palette != null:
		_palette.style_accent_label(label, 26, _palette.COLOR_BONE)
	return label

func _make_mode_button(icon: String, title: String, blurb: String, preset_id: String) -> Button:
	var btn: Button = Button.new()
	btn.text = "%s   %s\n%s" % [icon, title.to_upper(), blurb]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0.0, 86.0)
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_meta("preset_id", preset_id)
	btn.pressed.connect(_on_preset_button_pressed.bind(preset_id))
	btn.focus_entered.connect(_on_preset_button_focused.bind(preset_id))
	btn.mouse_entered.connect(_on_preset_button_focused.bind(preset_id))
	if _palette != null:
		_palette.style_button(btn, _palette.COLOR_BLACK, _palette.COLOR_GOLD, _palette.COLOR_BONE, 25)
	return btn

func _make_action_button(text: String, callback: Callable, accent: bool) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0.0, 86.0)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(callback)
	if _palette != null:
		var fill: Color = _palette.COLOR_BLOOD_RED if accent else _palette.COLOR_BLACK
		var border: Color = _palette.COLOR_HOT_GOLD if accent else _palette.COLOR_STEEL.darkened(0.30)
		_palette.style_button(btn, fill, border, _palette.COLOR_BONE, 32)
	return btn

func _make_brush_panel_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.70)
	style.shadow_size = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
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
	frame.add_theme_stylebox_override("panel", _make_brush_panel_style(Color(0.04, 0.04, 0.05, 0.98), Color(1.0, 0.78, 0.10, 1.0), 5))
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

	var close_btn: Button = _make_action_button("BACK", _on_settings_close, true)
	close_btn.custom_minimum_size = Vector2(360.0, 70.0)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	_previewed_preset_id = preset_id
	_preview_preset(preset_id)
	_refresh_preset_button_styles()

func _preview_preset(preset_id: String) -> void:
	_previewed_preset_id = preset_id
	var data: Dictionary = MatchPreset.find(preset_id)
	if _preset_blurb_title != null:
		_preset_blurb_title.text = String(data.get("title", "MATCH")).to_upper()
	if _preset_blurb_label != null:
		_preset_blurb_label.text = String(data.get("blurb", ""))
	_refresh_preset_button_styles()

func _refresh_preset_button_styles() -> void:
	for btn in _preset_buttons:
		var pid: String = String(btn.get_meta("preset_id", ""))
		var is_selected: bool = pid == _selected_preset_id
		var is_previewed: bool = pid == _previewed_preset_id
		_apply_preset_button_style(btn, is_selected, is_previewed)

func _apply_preset_button_style(btn: Button, is_selected: bool, is_previewed: bool) -> void:
	if _palette == null:
		return
	var fill: Color = _palette.COLOR_BLOOD_RED if is_selected else _palette.COLOR_BLACK
	if is_previewed and not is_selected:
		fill = Color(0.12, 0.08, 0.04, 1.0)
	var border: Color = _palette.COLOR_HOT_GOLD if is_selected else (_palette.COLOR_GOLD if is_previewed else _palette.COLOR_STEEL.darkened(0.35))
	_palette.style_button(btn, fill, border, _palette.COLOR_BONE, 25)

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

func _on_stats_pressed() -> void:
	_play_sfx("ui_click")
	if _preset_blurb_title != null:
		_preset_blurb_title.text = "STATS"
	if _preset_blurb_label != null:
		_preset_blurb_label.text = "Stats screen is coming soon. For now, settle it on the ice."

func _on_extras_pressed() -> void:
	_play_sfx("ui_click")
	if _preset_blurb_title != null:
		_preset_blurb_title.text = "EXTRAS"
	if _preset_blurb_label != null:
		_preset_blurb_label.text = "Future home of packs, team lore, arena toys, and ridiculous unlocks."

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

func _icon_for_preset(preset_id: String) -> String:
	match preset_id:
		MatchPreset.ID_QUICK_HIT:
			return "⚡"
		MatchPreset.ID_STANDARD:
			return "⚔"
		MatchPreset.ID_MARATHON:
			return "⌛"
		MatchPreset.ID_SUDDEN_DEATH:
			return "☠"
		MatchPreset.ID_ADVENTURE:
			return "♛"
		_:
			return "●"
