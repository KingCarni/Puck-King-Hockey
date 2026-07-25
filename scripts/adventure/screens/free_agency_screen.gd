extends "res://scripts/adventure/adventure_screen.gd"

# Free Agency — placeholder list of available skaters. Signing logic
# arrives with the recruitment/economy systems.

const AdventureDataScript = preload("res://scripts/adventure/adventure_data.gd")

var _back_button: Button = null

func _screen_title() -> String:
	return "FREE AGENCY"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	for definition: Resource in AdventureDataScript.recruit_pool():
		var agent: PlayerDefinitionScript = definition
		var panel: PanelContainer = make_panel(COLOR_HOME_BLUE)
		panel.custom_minimum_size = Vector2(900.0, 0.0)
		vbox.add_child(panel)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		panel.add_child(row)
		row.add_child(make_logo_badge(agent.display_name.left(1), COLOR_HOME_BLUE, 90.0))
		var text_box: VBoxContainer = VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(text_box)
		text_box.add_child(make_display_label(agent.display_name.to_upper(), 28, COLOR_BONE))
		text_box.add_child(make_accent_label("%s · %s · \"%s\"" % [agent.position, archetype_text(agent.archetype), agent.nickname], 20, COLOR_STEEL))
		row.add_child(make_accent_label("ASKING: ???", 24, COLOR_GOLD))

	var note: Label = make_accent_label("AGENTS AREN'T TAKING CALLS YET — SIGNING COMING SOON", 24, COLOR_GOLD)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(note)

	_back_button = make_button("BACK", false, 84.0)
	_back_button.custom_minimum_size = Vector2(420.0, 84.0)
	_back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_button.pressed.connect(func() -> void: _on_back())
	vbox.add_child(_back_button)

func _default_focus() -> Control:
	return _back_button
