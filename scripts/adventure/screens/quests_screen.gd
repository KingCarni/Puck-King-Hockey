extends "res://scripts/adventure/adventure_screen.gd"

# Tournament Quests — three run-long objectives. Progress is placeholder
# until the quest system hooks real match events.

var _continue_button: Button = null

func _screen_title() -> String:
	return "TOURNAMENT QUESTS"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var quests: Array = _flow.get("quests") if _flow != null else []
	for quest: Dictionary in quests:
		vbox.add_child(_make_quest_row(quest))
	if quests.is_empty():
		vbox.add_child(make_accent_label("NO QUESTS POSTED", 26, COLOR_STEEL))

	_continue_button = make_button("CONTINUE", true)
	_continue_button.custom_minimum_size = Vector2(720.0, 92.0)
	_continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_button.pressed.connect(advance)
	vbox.add_child(_continue_button)

func _make_quest_row(quest: Dictionary) -> PanelContainer:
	var panel: PanelContainer = make_panel(COLOR_GOLD)
	panel.custom_minimum_size = Vector2(880.0, 0.0)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var progress: int = int(quest.get("progress", 0))
	var goal: int = int(quest.get("goal", 1))
	box.add_child(make_display_label(String(quest.get("title", "QUEST")), 32, COLOR_BONE))
	box.add_child(make_accent_label(String(quest.get("description", "")), 22, COLOR_STEEL))
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = goal
	bar.value = progress
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0.0, 22.0)
	bar.focus_mode = Control.FOCUS_NONE
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.07, 1.0)
	bg_style.set_corner_radius_all(6)
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = COLOR_GOLD
	fill_style.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	box.add_child(bar)
	box.add_child(make_accent_label("%d / %d" % [progress, goal], 22, COLOR_GOLD))
	return panel

func _default_focus() -> Control:
	return _continue_button
