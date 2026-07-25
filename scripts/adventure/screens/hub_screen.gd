extends "res://scripts/adventure/adventure_screen.gd"

# Adventure Hub — home base between tournament runs.

var _first_button: Button = null

func _screen_title() -> String:
	return "ADVENTURE HUB"

func _footer_hints() -> String:
	return "A / ENTER — SELECT      B / ESC — TITLE SCREEN"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var options: Array[Dictionary] = [
		{"id": &"tournament", "label": "ENTER TOURNAMENT", "primary": true},
		{"id": &"shop", "label": "SHOP"},
		{"id": &"free_agency", "label": "FREE AGENCY"},
		{"id": &"team", "label": "TEAM"},
		{"id": &"settings", "label": "SETTINGS"},
	]
	var buttons: Array[Button] = []
	for option: Dictionary in options:
		var btn: Button = make_button(String(option["label"]), bool(option.get("primary", false)))
		btn.custom_minimum_size = Vector2(640.0, 92.0)
		btn.pressed.connect(_on_option.bind(StringName(option["id"])))
		vbox.add_child(btn)
		buttons.append(btn)
	var exit_btn: Button = make_button("RETURN TO TITLE")
	exit_btn.custom_minimum_size = Vector2(640.0, 92.0)
	exit_btn.pressed.connect(func() -> void:
		if _flow != null:
			_flow.call("exit_to_title")
	)
	vbox.add_child(exit_btn)
	buttons.append(exit_btn)
	wire_vertical(buttons)
	_first_button = buttons[0]

func _default_focus() -> Control:
	return _first_button

func _on_option(option: StringName) -> void:
	if _flow != null:
		_flow.call("hub_select", option)
