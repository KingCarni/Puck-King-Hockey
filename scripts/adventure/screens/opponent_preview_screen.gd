extends "res://scripts/adventure/adventure_screen.gd"

# Opponent Preview — scouting report before puck drop: opponent identity,
# match modifier, boss rule, plus your perks and player conditions.

var _play_button: Button = null

func _screen_title() -> String:
	var opponent: Dictionary = _opponent()
	return String(opponent.get("label", "NEXT MATCH"))

func _footer_hints() -> String:
	return "A / ENTER — PLAY MATCH      B / ESC — BACK"

func _opponent() -> Dictionary:
	return _flow.call("current_opponent") if _flow != null else {}

func _build_content(parent: Control) -> void:
	var opponent: Dictionary = _opponent()
	var team_color: Color = opponent.get("color", COLOR_BLOOD_RED)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 60)
	parent.add_child(row)

	# --- Opponent panel -----------------------------------------------------
	var opp_panel: PanelContainer = make_panel(team_color)
	opp_panel.custom_minimum_size = Vector2(860.0, 0.0)
	opp_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(opp_panel)
	var opp_box: VBoxContainer = VBoxContainer.new()
	opp_box.add_theme_constant_override("separation", 12)
	opp_panel.add_child(opp_box)

	var identity: HBoxContainer = HBoxContainer.new()
	identity.add_theme_constant_override("separation", 26)
	opp_box.add_child(identity)
	identity.add_child(make_logo_badge(String(opponent.get("monogram", "??")), team_color, 140.0))
	var name_box: VBoxContainer = VBoxContainer.new()
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_child(name_box)
	var name_label: Label = make_display_label(String(opponent.get("name", "UNKNOWN OPPONENT")), 40, COLOR_BONE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(560.0, 0.0)
	name_box.add_child(name_label)

	opp_box.add_child(make_accent_label("MATCH MODIFIER: %s" % String(opponent.get("modifier", "NONE")), 24, COLOR_GOLD))
	if opponent.has("boss_rule"):
		opp_box.add_child(make_accent_label("BOSS RULE: %s" % String(opponent.get("boss_rule", "")), 24, COLOR_BLOOD_RED))

	opp_box.add_child(make_heading("THEIR LINEUP", team_color.lightened(0.3)))
	for skater_name: String in opponent.get("roster", []):
		opp_box.add_child(make_accent_label("— %s" % skater_name, 24, COLOR_BONE))

	# --- Your side panel ----------------------------------------------------
	var squad_panel: PanelContainer = make_panel(COLOR_GOLD)
	squad_panel.custom_minimum_size = Vector2(680.0, 0.0)
	squad_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(squad_panel)
	var squad_box: VBoxContainer = VBoxContainer.new()
	squad_box.add_theme_constant_override("separation", 10)
	squad_panel.add_child(squad_box)

	squad_box.add_child(make_heading("YOUR LINE"))
	var captain: StringName = StringName(_flow.get("captain_id")) if _flow != null else &""
	for definition: Resource in (_flow.call("active_players") if _flow != null else []):
		var player: PlayerDefinitionScript = definition
		var crown: String = "★ " if player.id == captain else ""
		var condition: String = String(_flow.call("condition_of", player.id))
		squad_box.add_child(make_accent_label("%s%s — %s" % [crown, player.display_name.to_upper(), condition], 24, COLOR_BONE))

	squad_box.add_child(make_heading("TOURNAMENT PERKS"))
	var perks: Array = _flow.get("perks") if _flow != null else []
	if perks.is_empty():
		squad_box.add_child(make_accent_label("None yet — win to draft perks.", 22, COLOR_STEEL))
	for perk: Dictionary in perks:
		squad_box.add_child(make_accent_label("★ %s" % String(perk.get("title", "")), 22, COLOR_GOLD))

	_play_button = make_button("PLAY MATCH", true)
	_play_button.custom_minimum_size = Vector2(560.0, 96.0)
	_play_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play_button.pressed.connect(advance)
	squad_box.add_child(_play_button)

func _default_focus() -> Control:
	return _play_button
