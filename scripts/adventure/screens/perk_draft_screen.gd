extends "res://scripts/adventure/adventure_screen.gd"

# Tournament Perk Draft — pick one of three run-long perks after a match.
# Perk effects are placeholder until the perk system hooks runtime stats.

const AdventureDataScript = preload("res://scripts/adventure/adventure_data.gd")

var _perk_buttons: Array[Button] = []

func _screen_title() -> String:
	return "PERK DRAFT"

func _footer_hints() -> String:
	return "A / ENTER — DRAFT PERK"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)

	var prompt: Label = make_accent_label("CHOOSE ONE PERK FOR THE REST OF THE TOURNAMENT", 26, COLOR_GOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(prompt)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	vbox.add_child(row)

	for perk: Dictionary in AdventureDataScript.draft_perks(3):
		var panel: PanelContainer = make_panel(COLOR_GOLD)
		panel.custom_minimum_size = Vector2(500.0, 0.0)
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(panel)
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 12)
		panel.add_child(box)
		var description: Label = make_accent_label(String(perk.get("description", "")), 22, COLOR_BONE)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size = Vector2(0.0, 90.0)
		var btn: Button = make_button(String(perk.get("title", "PERK")), true, 92.0)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(_on_perk_picked.bind(perk))
		box.add_child(btn)
		box.add_child(description)
		_perk_buttons.append(btn)

	# Left/right between the three perk cards.
	for index: int in range(_perk_buttons.size()):
		var btn: Button = _perk_buttons[index]
		var left: Button = _perk_buttons[(index - 1 + _perk_buttons.size()) % _perk_buttons.size()]
		var right: Button = _perk_buttons[(index + 1) % _perk_buttons.size()]
		btn.focus_neighbor_left = btn.get_path_to(left)
		btn.focus_neighbor_right = btn.get_path_to(right)

func _on_perk_picked(perk: Dictionary) -> void:
	if _flow != null:
		_flow.call("add_perk", perk)

func _default_focus() -> Control:
	return _perk_buttons[0] if not _perk_buttons.is_empty() else null
