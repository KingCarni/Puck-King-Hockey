extends CanvasLayer

# Match HUD: top-center scoreboard, top-left upgrade display, notification stack,
# and goal banner. All controller/TV friendly and resolution-independent.

const NotificationBannerScript: GDScript = preload("res://scripts/ui/notification_banner.gd")
const GoalBannerScript: GDScript = preload("res://scripts/ui/goal_banner.gd")

var _palette: Node = null

# Scoreboard widgets.
var _scoreboard_panel: PanelContainer = null
var _home_score_label: Label = null
var _away_score_label: Label = null
var _home_team_label: Label = null
var _away_team_label: Label = null
var _vs_label: Label = null

# Upgrade display widgets.
var _upgrades_panel: PanelContainer = null
var _upgrades_title_label: Label = null
var _upgrades_list: VBoxContainer = null
var _upgrades_empty_label: Label = null

# Hint widget for pause.
var _pause_hint_label: Label = null

# Banner instances.
var _notification: Control = null
var _goal_banner: Control = null

# Score pulse tween cache.
var _home_pulse_tween: Tween = null
var _away_pulse_tween: Tween = null

func _ready() -> void:
	layer = 10
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	set_score(0, 0)
	set_upgrades([])

func _build_ui() -> void:
	var hud_root: Control = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_root)

	_build_scoreboard(hud_root)
	_build_upgrade_display(hud_root)
	_build_pause_hint(hud_root)
	_build_banners(hud_root)

func _build_scoreboard(parent: Control) -> void:
	_scoreboard_panel = PanelContainer.new()
	_scoreboard_panel.name = "Scoreboard"
	_scoreboard_panel.anchor_left = 0.5
	_scoreboard_panel.anchor_right = 0.5
	_scoreboard_panel.anchor_top = 0.0
	_scoreboard_panel.anchor_bottom = 0.0
	_scoreboard_panel.offset_left = -420.0
	_scoreboard_panel.offset_right = 420.0
	_scoreboard_panel.offset_top = 24.0
	_scoreboard_panel.offset_bottom = 196.0
	_scoreboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_scoreboard_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.94)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 16
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 16
	_scoreboard_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "Layout"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	_scoreboard_panel.add_child(hbox)

	# Home side.
	var home_block: VBoxContainer = _build_team_block("HOME", Color(0.18, 0.55, 1.0, 1.0))
	home_block.name = "HomeBlock"
	hbox.add_child(home_block)
	_home_team_label = home_block.get_node("TeamPill/TeamLabel") as Label
	_home_score_label = home_block.get_node("ScoreLabel") as Label

	# Center separator with VS.
	var center: VBoxContainer = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(120.0, 0.0)
	hbox.add_child(center)

	_vs_label = Label.new()
	_vs_label.name = "VsLabel"
	_vs_label.text = "VS"
	_vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_child(_vs_label)

	var label_text: Label = Label.new()
	label_text.text = "PUCK KING"
	label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(label_text)

	var label_text2: Label = Label.new()
	label_text2.text = "HELL"
	label_text2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(label_text2)

	# Away side.
	var away_block: VBoxContainer = _build_team_block("AWAY", Color(1.0, 0.20, 0.22, 1.0))
	away_block.name = "AwayBlock"
	hbox.add_child(away_block)
	_away_team_label = away_block.get_node("TeamPill/TeamLabel") as Label
	_away_score_label = away_block.get_node("ScoreLabel") as Label

	if _palette != null:
		_palette.style_display_label(_vs_label, 56, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(label_text, 18, _palette.COLOR_GOLD)
		_palette.style_accent_label(label_text2, 18, _palette.COLOR_GOLD)

func _build_team_block(team_text: String, team_color: Color) -> VBoxContainer:
	var block: VBoxContainer = VBoxContainer.new()
	block.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_theme_constant_override("separation", 4)
	block.custom_minimum_size = Vector2(280.0, 0.0)

	var team_pill: PanelContainer = PanelContainer.new()
	team_pill.name = "TeamPill"
	team_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = team_color
	pill_style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	pill_style.set_border_width_all(2)
	pill_style.set_corner_radius_all(6)
	pill_style.content_margin_left = 18
	pill_style.content_margin_right = 18
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	team_pill.add_theme_stylebox_override("panel", pill_style)
	block.add_child(team_pill)

	var team_label: Label = Label.new()
	team_label.name = "TeamLabel"
	team_label.text = team_text
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_pill.add_child(team_label)

	var score_label: Label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.pivot_offset = Vector2(140.0, 60.0)
	block.add_child(score_label)

	if _palette != null:
		_palette.style_accent_label(team_label, 26, _palette.COLOR_BONE)
		_palette.style_display_label(score_label, 110, _palette.COLOR_HOT_GOLD)

	return block

func _build_upgrade_display(parent: Control) -> void:
	_upgrades_panel = PanelContainer.new()
	_upgrades_panel.name = "UpgradeDisplay"
	_upgrades_panel.anchor_left = 0.0
	_upgrades_panel.anchor_right = 0.0
	_upgrades_panel.anchor_top = 0.0
	_upgrades_panel.anchor_bottom = 0.0
	_upgrades_panel.offset_left = 36.0
	_upgrades_panel.offset_right = 360.0
	_upgrades_panel.offset_top = 36.0
	_upgrades_panel.offset_bottom = 240.0
	_upgrades_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_upgrades_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.92)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 10
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	_upgrades_panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_upgrades_panel.add_child(vbox)

	# Header pill with "PERKS".
	var header_pill: PanelContainer = PanelContainer.new()
	header_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	pill_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	pill_style.set_border_width_all(2)
	pill_style.set_corner_radius_all(6)
	pill_style.content_margin_left = 14
	pill_style.content_margin_right = 14
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	header_pill.add_theme_stylebox_override("panel", pill_style)
	vbox.add_child(header_pill)

	_upgrades_title_label = Label.new()
	_upgrades_title_label.text = "PERKS"
	header_pill.add_child(_upgrades_title_label)

	_upgrades_list = VBoxContainer.new()
	_upgrades_list.name = "List"
	_upgrades_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_upgrades_list)

	_upgrades_empty_label = Label.new()
	_upgrades_empty_label.name = "EmptyState"
	_upgrades_empty_label.text = "NO PERKS YET"
	vbox.add_child(_upgrades_empty_label)

	if _palette != null:
		_palette.style_accent_label(_upgrades_title_label, 22, _palette.COLOR_BONE)
		_palette.style_accent_label(_upgrades_empty_label, 18, _palette.COLOR_STEEL)

func _build_pause_hint(parent: Control) -> void:
	_pause_hint_label = Label.new()
	_pause_hint_label.name = "PauseHint"
	_pause_hint_label.text = "ESC / START — PAUSE"
	_pause_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pause_hint_label.anchor_left = 1.0
	_pause_hint_label.anchor_right = 1.0
	_pause_hint_label.anchor_top = 0.0
	_pause_hint_label.anchor_bottom = 0.0
	_pause_hint_label.offset_left = -360.0
	_pause_hint_label.offset_right = -32.0
	_pause_hint_label.offset_top = 40.0
	_pause_hint_label.offset_bottom = 80.0
	parent.add_child(_pause_hint_label)

	if _palette != null:
		_palette.style_accent_label(_pause_hint_label, 20, _palette.COLOR_GOLD)

func _build_banners(parent: Control) -> void:
	_notification = Control.new()
	_notification.set_script(NotificationBannerScript)
	parent.add_child(_notification)

	_goal_banner = Control.new()
	_goal_banner.set_script(GoalBannerScript)
	parent.add_child(_goal_banner)

# ----- Public API -----

func set_score(home_score: int, away_score: int) -> void:
	if _home_score_label != null:
		_home_score_label.text = str(home_score)
	if _away_score_label != null:
		_away_score_label.text = str(away_score)

func pulse_home_score() -> void:
	_pulse_label(_home_score_label, "home")

func pulse_away_score() -> void:
	_pulse_label(_away_score_label, "away")

func _pulse_label(label: Label, key: String) -> void:
	if label == null:
		return
	label.pivot_offset = label.size * 0.5
	if key == "home":
		if _home_pulse_tween != null and _home_pulse_tween.is_valid():
			_home_pulse_tween.kill()
		_home_pulse_tween = create_tween()
		_home_pulse_tween.tween_property(label, "scale", Vector2(1.45, 1.45), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_home_pulse_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	else:
		if _away_pulse_tween != null and _away_pulse_tween.is_valid():
			_away_pulse_tween.kill()
		_away_pulse_tween = create_tween()
		_away_pulse_tween.tween_property(label, "scale", Vector2(1.45, 1.45), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_away_pulse_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func set_upgrades(upgrade_entries: Array) -> void:
	if _upgrades_list == null:
		return

	# Wipe current entries.
	for child in _upgrades_list.get_children():
		child.queue_free()

	if upgrade_entries.is_empty():
		if _upgrades_empty_label != null:
			_upgrades_empty_label.visible = true
		return

	if _upgrades_empty_label != null:
		_upgrades_empty_label.visible = false

	for entry in upgrade_entries:
		var label_text: String = ""
		if entry is Dictionary:
			label_text = String(entry.get("title", "UPGRADE"))
		else:
			label_text = String(entry)
		_upgrades_list.add_child(_make_upgrade_pill(label_text))

func _make_upgrade_pill(text: String) -> Control:
	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", style)

	var label: Label = Label.new()
	label.text = text.to_upper()
	pill.add_child(label)

	if _palette != null:
		_palette.style_accent_label(label, 20, _palette.COLOR_HOT_GOLD)

	# Pop-in animation when added.
	pill.modulate.a = 0.0
	pill.scale = Vector2(0.85, 0.85)
	pill.pivot_offset = Vector2(140.0, 22.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(pill, "modulate:a", 1.0, 0.22)
	tween.tween_property(pill, "scale", Vector2(1.0, 1.0), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	return pill

func show_notification(text: String, accent_color: Color = Color(1.0, 0.78, 0.10, 1.0), hold_time: float = 1.6) -> void:
	if _notification != null and _notification.has_method("show_message"):
		_notification.call("show_message", text, accent_color, hold_time)

func celebrate_goal(team: String) -> void:
	if _goal_banner == null:
		return
	_goal_banner.call("celebrate", team)
	if team.to_upper() == "HOME":
		pulse_home_score()
	else:
		pulse_away_score()

func get_goal_banner() -> Node:
	return _goal_banner
