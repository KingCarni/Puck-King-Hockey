extends "res://scripts/adventure/adventure_screen.gd"

# Captain Select — pick the tournament captain from the whole squad.
# Selecting a player sets the captain immediately; CONTINUE advances.

var _player_buttons: Array[Button] = []
var _continue_button: Button = null
var _list_box: VBoxContainer = null

func _screen_title() -> String:
	return "SELECT YOUR CAPTAIN"

func _build_content(parent: Control) -> void:
	var center: CenterContainer = CenterContainer.new()
	parent.add_child(center)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	_list_box = VBoxContainer.new()
	_list_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_list_box)

	_continue_button = make_button("CONTINUE", true)
	_continue_button.custom_minimum_size = Vector2(720.0, 92.0)
	_continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_button.pressed.connect(advance)
	vbox.add_child(_continue_button)

	_rebuild_list()

func _rebuild_list() -> void:
	for child: Node in _list_box.get_children():
		child.queue_free()
	_player_buttons.clear()
	if _flow == null:
		return
	var captain: StringName = StringName(_flow.get("captain_id"))
	var players: Array[Resource] = []
	players.append_array(_flow.call("active_players"))
	players.append_array(_flow.call("bench_players"))
	for definition: Resource in players:
		var player: PlayerDefinitionScript = definition
		var is_captain: bool = player.id == captain
		var crown: String = "★ CAPTAIN — " if is_captain else ""
		var btn: Button = make_button("%s%s  ·  %s (%s)" % [crown, player.display_name.to_upper(), archetype_text(player.archetype), player.position], is_captain)
		btn.custom_minimum_size = Vector2(720.0, 84.0)
		btn.pressed.connect(_on_pick.bind(player.id))
		_list_box.add_child(btn)
		_player_buttons.append(btn)
	var all_buttons: Array[Button] = _player_buttons.duplicate()
	all_buttons.append(_continue_button)
	wire_vertical(all_buttons)

func _on_pick(id: StringName) -> void:
	if _flow != null:
		_flow.call("set_captain", id)
	_rebuild_list()
	if not _player_buttons.is_empty():
		_continue_button.grab_focus()

func _default_focus() -> Control:
	return _player_buttons[0] if not _player_buttons.is_empty() else _continue_button
