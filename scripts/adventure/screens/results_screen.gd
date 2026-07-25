extends "res://scripts/adventure/adventure_screen.gd"

# Match Results — outcome of the match just played plus rewards, quest
# progress, perks, and what's next. Back is gated: the run only moves
# forward from here.

var _continue_button: Button = null

func _screen_title() -> String:
	var last: Dictionary = _last()
	if last.is_empty():
		return "MATCH RESULTS"
	return "VICTORY" if bool(last.get("won", false)) else "DEFEAT"

func _footer_hints() -> String:
	return "A / ENTER — CONTINUE"

func _last() -> Dictionary:
	return _flow.get("last_match") if _flow != null else {}

func _build_content(parent: Control) -> void:
	var last: Dictionary = _last()
	var opponent: Dictionary = last.get("opponent", {})
	var won: bool = bool(last.get("won", false))

	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var score_label: Label = make_display_label(
		"%d — %d  vs  %s" % [int(last.get("home", 0)), int(last.get("away", 0)), String(opponent.get("name", "???"))],
		48, COLOR_HOT_GOLD if won else COLOR_STEEL)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(score_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 50)
	vbox.add_child(row)

	# Rewards panel.
	var rewards_panel: PanelContainer = make_panel(COLOR_GOLD)
	rewards_panel.custom_minimum_size = Vector2(520.0, 0.0)
	rewards_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rewards_panel)
	var rewards_box: VBoxContainer = VBoxContainer.new()
	rewards_box.add_theme_constant_override("separation", 10)
	rewards_panel.add_child(rewards_box)
	rewards_box.add_child(make_heading("REWARDS"))
	rewards_box.add_child(make_accent_label("+%d GOLD" % int(last.get("gold_earned", 0)), 28, COLOR_GOLD))
	rewards_box.add_child(make_accent_label("+%d PUCKS" % int(last.get("pucks_earned", 0)), 28, COLOR_BONE))
	rewards_box.add_child(make_heading("PERKS HELD"))
	var perks: Array = _flow.get("perks") if _flow != null else []
	if perks.is_empty():
		rewards_box.add_child(make_accent_label("None yet.", 22, COLOR_STEEL))
	for perk: Dictionary in perks:
		rewards_box.add_child(make_accent_label("★ %s" % String(perk.get("title", "")), 22, COLOR_GOLD))

	# Quests panel.
	var quest_panel: PanelContainer = make_panel(COLOR_HOME_BLUE)
	quest_panel.custom_minimum_size = Vector2(620.0, 0.0)
	quest_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(quest_panel)
	var quest_box: VBoxContainer = VBoxContainer.new()
	quest_box.add_theme_constant_override("separation", 10)
	quest_panel.add_child(quest_box)
	quest_box.add_child(make_heading("QUEST PROGRESS", COLOR_HOME_BLUE.lightened(0.35)))
	for quest: Dictionary in (_flow.get("quests") if _flow != null else []):
		quest_box.add_child(make_accent_label(
			"%s — %d / %d" % [String(quest.get("title", "")), int(quest.get("progress", 0)), int(quest.get("goal", 1))],
			24, COLOR_BONE))

	# Next up.
	var next_line: String = "TOURNAMENT COMPLETE"
	if _flow != null and not bool(_flow.call("is_tournament_complete")):
		var next_opponent: Dictionary = _flow.call("current_opponent")
		next_line = "NEXT — %s: %s" % [String(next_opponent.get("label", "")), String(next_opponent.get("name", ""))]
	var next_label: Label = make_accent_label(next_line, 26, COLOR_BONE)
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(next_label)

	_continue_button = make_button("CONTINUE", true)
	_continue_button.custom_minimum_size = Vector2(620.0, 96.0)
	_continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(advance)
	vbox.add_child(_continue_button)

func _default_focus() -> Control:
	return _continue_button
