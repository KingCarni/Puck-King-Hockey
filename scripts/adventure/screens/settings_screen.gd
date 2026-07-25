extends "res://scripts/adventure/adventure_screen.gd"

# Adventure Settings — placeholder. Full settings live on the title screen;
# adventure-specific options (difficulty, rules) plug in here later.

var _back_button: Button = null

func _screen_title() -> String:
	return "SETTINGS"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var panel: PanelContainer = make_panel(COLOR_GOLD)
	panel.custom_minimum_size = Vector2(860.0, 0.0)
	vbox.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(make_heading("ADVENTURE SETTINGS"))
	for line: String in [
		"Audio and display settings live on the title screen.",
		"Adventure-specific options — difficulty, rulesets,",
		"and run modifiers — will appear here.",
	]:
		box.add_child(make_accent_label(line, 24, COLOR_BONE))

	_back_button = make_button("BACK", false, 84.0)
	_back_button.custom_minimum_size = Vector2(420.0, 84.0)
	_back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_button.pressed.connect(func() -> void: _on_back())
	vbox.add_child(_back_button)

func _default_focus() -> Control:
	return _back_button
