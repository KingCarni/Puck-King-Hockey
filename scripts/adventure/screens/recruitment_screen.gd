extends "res://scripts/adventure/adventure_screen.gd"

# Recruitment — end-of-tournament scene. Shows the recruit offers that the
# real recruitment system will one day make signable. CONTINUE ends the run.

const AdventureDataScript = preload("res://scripts/adventure/adventure_data.gd")

var _continue_button: Button = null

func _screen_title() -> String:
	return "RECRUITMENT"

func _footer_hints() -> String:
	return "A / ENTER — RETURN TO HUB"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var headline: String = "THE SCOUTS TOOK NOTICE"
	if _flow != null and int(_flow.get("losses")) == 0:
		headline = "A PERFECT RUN — THE SCOUTS ARE BUZZING"
	var head_label: Label = make_accent_label(headline, 26, COLOR_GOLD)
	head_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(head_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	vbox.add_child(row)

	for definition: Resource in AdventureDataScript.recruit_pool():
		var recruit: PlayerDefinitionScript = definition
		var panel: PanelContainer = make_panel(COLOR_HOME_BLUE)
		panel.custom_minimum_size = Vector2(480.0, 0.0)
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(panel)
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		panel.add_child(box)
		box.add_child(make_logo_badge(recruit.display_name.left(1), COLOR_HOME_BLUE, 110.0))
		box.add_child(make_display_label(recruit.display_name.to_upper(), 30, COLOR_BONE))
		box.add_child(make_accent_label("\"%s\"" % recruit.nickname, 22, COLOR_STEEL))
		box.add_child(make_accent_label("%s · %s" % [recruit.position, archetype_text(recruit.archetype)], 22, COLOR_BONE))
		box.add_child(make_accent_label("SIGNING OPENS SOON", 20, COLOR_GOLD))

	_continue_button = make_button("RETURN TO HUB", true)
	_continue_button.custom_minimum_size = Vector2(620.0, 96.0)
	_continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(advance)
	vbox.add_child(_continue_button)

func _default_focus() -> Control:
	return _continue_button
