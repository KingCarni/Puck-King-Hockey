extends "res://scripts/adventure/adventure_screen.gd"

# Tournament Overview — schedule + stakes before committing to the run.

var _enter_button: Button = null

func _screen_title() -> String:
	return "TOURNAMENT OVERVIEW"

func _build_content(parent: Control) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 60)
	parent.add_child(row)

	# Schedule column.
	var schedule_panel: PanelContainer = make_panel(COLOR_HOME_BLUE)
	schedule_panel.custom_minimum_size = Vector2(880.0, 0.0)
	schedule_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(schedule_panel)
	var schedule_box: VBoxContainer = VBoxContainer.new()
	schedule_box.add_theme_constant_override("separation", 12)
	schedule_panel.add_child(schedule_box)
	schedule_box.add_child(make_heading("ROAD TO THE CROWN"))

	var schedule: Array = _flow.get("schedule") if _flow != null else []
	var game_index: int = int(_flow.get("current_game")) if _flow != null else 0
	for index: int in range(schedule.size()):
		var entry: Dictionary = schedule[index]
		var is_boss: bool = bool(entry.get("is_boss", false))
		var marker: String = "★ " if index == game_index else "   "
		var line: String = "%s%s  —  %s" % [marker, String(entry.get("label", "")), String(entry.get("name", ""))]
		var label: Label = make_accent_label(line, 26, COLOR_BLOOD_RED if is_boss else COLOR_BONE)
		schedule_box.add_child(label)

	# Stakes column.
	var stakes_panel: PanelContainer = make_panel(COLOR_GOLD)
	stakes_panel.custom_minimum_size = Vector2(620.0, 0.0)
	stakes_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(stakes_panel)
	var stakes_box: VBoxContainer = VBoxContainer.new()
	stakes_box.add_theme_constant_override("separation", 12)
	stakes_panel.add_child(stakes_box)
	stakes_box.add_child(make_heading("WINNER'S PURSE"))
	for line: String in [
		"500 GOLD",
		"10 PUCKS",
		"1 RARE RECRUIT OFFER",
		"",
		"Lose and you keep your earnings,",
		"but the Crown stays with the King.",
	]:
		stakes_box.add_child(make_accent_label(line, 24, COLOR_BONE))

	_enter_button = make_button("BEGIN TOURNAMENT", true)
	_enter_button.custom_minimum_size = Vector2(560.0, 96.0)
	_enter_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enter_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_enter_button.pressed.connect(advance)
	stakes_box.add_child(_enter_button)

func _default_focus() -> Control:
	return _enter_button
