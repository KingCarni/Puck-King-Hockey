extends CanvasLayer

# Match HUD: top-center scoreboard (with period timer), top-left UPGRADES panel,
# notification stack, goal banner. Controller/TV friendly.

const NotificationBannerScript: GDScript = preload("res://scripts/ui/notification_banner.gd")
const GoalBannerScript: GDScript = preload("res://scripts/ui/goal_banner.gd")

const SCOREBOARD_WIDTH: float = 1180.0
const SCOREBOARD_HEIGHT: float = 200.0

var _palette: Node = null

# Scoreboard widgets.
var _scoreboard_panel: PanelContainer = null
var _home_score_label: Label = null
var _away_score_label: Label = null
var _home_team_name_label: Label = null
var _away_team_name_label: Label = null
var _home_logo: Label = null
var _away_logo: Label = null
var _timer_label: Label = null
var _period_label: Label = null

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

# Team identities (could be data-driven later).
var _home_name: String = "PUCK KING"
var _away_name: String = "BLOODHAWKS"
var _home_logo_glyph: String = "\u26A1"
var _away_logo_glyph: String = "\u2738"

func _ready() -> void:
	layer = 10
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	set_score(0, 0)
	set_upgrades([])
	set_clock(0.0, "1ST PERIOD")

func _build_ui() -> void:
	var hud_root: Control = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_scoreboard_panel.offset_left = -SCOREBOARD_WIDTH * 0.5
	_scoreboard_panel.offset_right = SCOREBOARD_WIDTH * 0.5
	_scoreboard_panel.offset_top = 28.0
	_scoreboard_panel.offset_bottom = 28.0 + SCOREBOARD_HEIGHT
	_scoreboard_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_scoreboard_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.96)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 14
	_scoreboard_panel.add_theme_stylebox_override("panel", style)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "Layout"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	_scoreboard_panel.add_child(hbox)

	# Home tile.
	var home_tile: Control = _build_team_tile(true)
	home_tile.name = "HomeTile"
	hbox.add_child(home_tile)
	_home_logo = home_tile.get_node("Row/HomeLogoPanel/Glyph") as Label
	_home_team_name_label = home_tile.get_node("Row/Info/Name") as Label
	_home_score_label = home_tile.get_node("Row/Info/Score") as Label

	# Center column: timer + period label.
	var center_tile: PanelContainer = _build_center_tile()
	hbox.add_child(center_tile)

	# Away tile.
	var away_tile: Control = _build_team_tile(false)
	away_tile.name = "AwayTile"
	hbox.add_child(away_tile)
	_away_logo = away_tile.get_node("Row/AwayLogoPanel/Glyph") as Label
	_away_team_name_label = away_tile.get_node("Row/Info/Name") as Label
	_away_score_label = away_tile.get_node("Row/Info/Score") as Label

	if _home_team_name_label != null:
		_home_team_name_label.text = _home_name
	if _away_team_name_label != null:
		_away_team_name_label.text = _away_name
	if _home_logo != null:
		_home_logo.text = _home_logo_glyph
	if _away_logo != null:
		_away_logo.text = _away_logo_glyph

func _build_team_tile(is_home: bool) -> PanelContainer:
	var tile: PanelContainer = PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(440.0, SCOREBOARD_HEIGHT - 24.0)

	var tile_style: StyleBoxFlat = StyleBoxFlat.new()
	tile_style.bg_color = Color(0.05, 0.05, 0.07, 1.0)
	if is_home:
		tile_style.border_color = Color(0.18, 0.55, 1.0, 1.0)
	else:
		tile_style.border_color = Color(1.0, 0.20, 0.22, 1.0)
	tile_style.set_border_width_all(4)
	tile_style.set_corner_radius_all(10)
	tile_style.content_margin_left = 18
	tile_style.content_margin_right = 18
	tile_style.content_margin_top = 8
	tile_style.content_margin_bottom = 8
	tile.add_theme_stylebox_override("panel", tile_style)

	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	tile.add_child(row)

	# Logo + info ordering — home: logo left; away: logo right.
	var logo_panel: PanelContainer = _build_logo_panel(is_home)
	logo_panel.name = "HomeLogoPanel" if is_home else "AwayLogoPanel"
	var info_block: VBoxContainer = VBoxContainer.new()
	info_block.name = "Info"
	info_block.alignment = BoxContainer.ALIGNMENT_CENTER
	info_block.add_theme_constant_override("separation", -4)
	info_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var team_text: Label = Label.new()
	team_text.name = "Side"
	team_text.text = "HOME" if is_home else "AWAY"
	team_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_block.add_child(team_text)

	var name_label: Label = Label.new()
	name_label.name = "Name"
	name_label.text = _home_name if is_home else _away_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_block.add_child(name_label)

	var score_label: Label = Label.new()
	score_label.name = "Score"
	score_label.text = "0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.pivot_offset = Vector2(60.0, 60.0)
	info_block.add_child(score_label)

	if is_home:
		row.add_child(logo_panel)
		row.add_child(info_block)
	else:
		row.add_child(info_block)
		row.add_child(logo_panel)

	if _palette != null:
		_palette.style_accent_label(team_text, 22, _palette.COLOR_GOLD)
		_palette.style_accent_label(name_label, 22, _palette.COLOR_BONE if is_home else _palette.COLOR_AWAY_RED)
		_palette.style_display_label(score_label, 96, _palette.COLOR_BONE)

	return tile

func _build_logo_panel(is_home: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(108.0, 108.0)

	var s: StyleBoxFlat = StyleBoxFlat.new()
	if is_home:
		s.bg_color = Color(0.04, 0.16, 0.32, 1.0)
		s.border_color = Color(0.18, 0.55, 1.0, 1.0)
	else:
		s.bg_color = Color(0.30, 0.04, 0.05, 1.0)
		s.border_color = Color(1.0, 0.20, 0.22, 1.0)
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", s)

	var glyph: Label = Label.new()
	glyph.name = "Glyph"
	glyph.text = "?"
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(glyph)

	if _palette != null:
		_palette.style_display_label(glyph, 70, _palette.COLOR_HOT_GOLD)

	return panel

func _build_center_tile() -> PanelContainer:
	var tile: PanelContainer = PanelContainer.new()
	tile.name = "CenterTile"
	tile.custom_minimum_size = Vector2(220.0, SCOREBOARD_HEIGHT - 24.0)

	var tile_style: StyleBoxFlat = StyleBoxFlat.new()
	tile_style.bg_color = Color(0.05, 0.05, 0.07, 1.0)
	tile_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	tile_style.set_border_width_all(4)
	tile_style.set_corner_radius_all(10)
	tile_style.content_margin_left = 8
	tile_style.content_margin_right = 8
	tile_style.content_margin_top = 6
	tile_style.content_margin_bottom = 6
	tile.add_theme_stylebox_override("panel", tile_style)

	var col: VBoxContainer = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	tile.add_child(col)

	_timer_label = Label.new()
	_timer_label.name = "Timer"
	_timer_label.text = "00:00"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_timer_label)

	_period_label = Label.new()
	_period_label.name = "Period"
	_period_label.text = "1ST PERIOD"
	_period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_period_label)

	if _palette != null:
		_palette.style_display_label(_timer_label, 78, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_period_label, 22, _palette.COLOR_GOLD)

	return tile

func _build_upgrade_display(parent: Control) -> void:
	_upgrades_panel = PanelContainer.new()
	_upgrades_panel.name = "UpgradeDisplay"
	_upgrades_panel.anchor_left = 0.0
	_upgrades_panel.anchor_right = 0.0
	_upgrades_panel.anchor_top = 0.0
	_upgrades_panel.anchor_bottom = 0.0
	_upgrades_panel.offset_left = 36.0
	_upgrades_panel.offset_right = 380.0
	_upgrades_panel.offset_top = 36.0
	_upgrades_panel.offset_bottom = 260.0
	_upgrades_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_upgrades_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.94)
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
	_upgrades_title_label.text = "UPGRADES"
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

func set_team_identities(home_name: String, home_glyph: String, away_name: String, away_glyph: String) -> void:
	_home_name = home_name
	_away_name = away_name
	_home_logo_glyph = home_glyph
	_away_logo_glyph = away_glyph
	if _home_team_name_label != null:
		_home_team_name_label.text = home_name
	if _away_team_name_label != null:
		_away_team_name_label.text = away_name
	if _home_logo != null:
		_home_logo.text = home_glyph
	if _away_logo != null:
		_away_logo.text = away_glyph

func set_score(home_score: int, away_score: int) -> void:
	if _home_score_label != null:
		_home_score_label.text = str(home_score)
	if _away_score_label != null:
		_away_score_label.text = str(away_score)

func set_clock(seconds_left: float, period_text: String) -> void:
	if _timer_label != null:
		_timer_label.text = MatchPreset.format_clock(seconds_left)
	if _period_label != null:
		_period_label.text = period_text

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
		var glyph: String = "\u26A1"
		var icon_path: String = ""
		if entry is Dictionary:
			label_text = String(entry.get("title", "UPGRADE"))
			glyph = String(entry.get("glyph", "\u26A1"))
			icon_path = String(entry.get("icon", ""))
		else:
			label_text = String(entry)
		_upgrades_list.add_child(_make_upgrade_pill(label_text, glyph, icon_path))

func _make_upgrade_pill(text: String, glyph: String, icon_path: String = "") -> Control:
	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 10)
	pill.add_child(row)

	var icon_texture: Texture2D = null
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_texture = load(icon_path) as Texture2D

	var icon: Label = null
	if icon_texture != null:
		var icon_rect: TextureRect = TextureRect.new()
		icon_rect.texture = icon_texture
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(34.0, 34.0)
		row.add_child(icon_rect)
	else:
		icon = Label.new()
		icon.text = glyph
		row.add_child(icon)

	var label: Label = Label.new()
	label.text = text.to_upper()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	if _palette != null:
		if icon != null:
			_palette.style_accent_label(icon, 22, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(label, 20, _palette.COLOR_BONE)

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
