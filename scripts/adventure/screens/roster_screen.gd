extends "res://scripts/adventure/adventure_screen.gd"

# Roster screen — ACTIVE vs BENCH columns with select-to-swap.
# Select one player, then another: they trade slots (works across columns
# and within a column). Runs in three modes set by AdventureFlow:
#   select — pre-tournament line selection (CONTINUE -> quests)
#   swap   — between matches (CONTINUE -> opponent preview, back gated)
#   manage — from the hub (view/swap freely, back returns to hub)

var _armed_id: StringName = &""
var _active_box: VBoxContainer = null
var _bench_box: VBoxContainer = null
var _active_buttons: Array[Button] = []
var _bench_buttons: Array[Button] = []
var _continue_button: Button = null
var _focus_id: StringName = &""

func _mode() -> StringName:
	return StringName(_flow.get("roster_mode")) if _flow != null else &"manage"

func _screen_title() -> String:
	match _mode():
		&"select": return "SELECT YOUR LINE"
		&"swap": return "ROSTER SWAP"
	return "TEAM"

func _footer_hints() -> String:
	if _mode() == &"swap":
		return "A / ENTER — PICK, THEN PICK AGAIN TO SWAP      CONTINUE WHEN READY"
	return "A / ENTER — PICK, THEN PICK AGAIN TO SWAP      B / ESC — BACK"

func _build_content(parent: Control) -> void:
	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(outer)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 70)
	outer.add_child(row)

	_active_box = _make_column(row, "ACTIVE LINE", COLOR_BLOOD_RED)
	_bench_box = _make_column(row, "BENCH", COLOR_HOME_BLUE)

	_continue_button = make_button("CONTINUE", true)
	_continue_button.custom_minimum_size = Vector2(600.0, 92.0)
	_continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_button.pressed.connect(advance)
	_continue_button.visible = _mode() != &"manage"
	outer.add_child(_continue_button)

	_rebuild()

func _make_column(parent: HBoxContainer, title: String, border: Color) -> VBoxContainer:
	var panel: PanelContainer = make_panel(border)
	panel.custom_minimum_size = Vector2(700.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(make_heading(title, border.lightened(0.35)))
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	box.add_child(list)
	return list

func _rebuild() -> void:
	for child: Node in _active_box.get_children():
		child.queue_free()
	for child: Node in _bench_box.get_children():
		child.queue_free()
	_active_buttons.clear()
	_bench_buttons.clear()
	if _flow == null:
		return
	for definition: Resource in _flow.call("active_players"):
		_add_player_button(_active_box, _active_buttons, definition)
	for definition: Resource in _flow.call("bench_players"):
		_add_player_button(_bench_box, _bench_buttons, definition)
	wire_vertical(_active_buttons)
	wire_vertical(_bench_buttons)
	wire_columns(_active_buttons, _bench_buttons)
	if _continue_button.visible:
		# Down from the bottom of either column reaches CONTINUE.
		if not _active_buttons.is_empty():
			_active_buttons[-1].focus_neighbor_bottom = _active_buttons[-1].get_path_to(_continue_button)
		if not _bench_buttons.is_empty():
			_bench_buttons[-1].focus_neighbor_bottom = _bench_buttons[-1].get_path_to(_continue_button)
		if not _active_buttons.is_empty():
			_continue_button.focus_neighbor_top = _continue_button.get_path_to(_active_buttons[-1])
	_restore_focus()

func _add_player_button(box: VBoxContainer, list: Array[Button], definition: Resource) -> void:
	var player: PlayerDefinitionScript = definition
	var captain: StringName = StringName(_flow.get("captain_id"))
	var condition: String = String(_flow.call("condition_of", player.id))
	var armed: bool = player.id == _armed_id
	var crown: String = "★ " if player.id == captain else ""
	var marker: String = "» " if armed else ""
	var text: String = "%s%s%s  ·  %s  ·  %s" % [marker, crown, player.display_name.to_upper(), archetype_text(player.archetype), condition]
	var btn: Button = make_button(text, armed)
	btn.custom_minimum_size = Vector2(640.0, 82.0)
	btn.pressed.connect(_on_player_pressed.bind(player.id))
	box.add_child(btn)
	list.append(btn)

func _on_player_pressed(id: StringName) -> void:
	if _armed_id == &"":
		_armed_id = id
	elif _armed_id == id:
		_armed_id = &""
	else:
		_flow.call("swap_players", _armed_id, id)
		_focus_id = _armed_id
		_armed_id = &""
	if _focus_id == &"":
		_focus_id = id
	_rebuild()

func _restore_focus() -> void:
	if _focus_id == &"":
		return
	call_deferred("_focus_player", _focus_id)
	_focus_id = &""

func _focus_player(id: StringName) -> void:
	var index: int = _index_in(_flow.call("active_players"), id)
	if index >= 0 and index < _active_buttons.size():
		_active_buttons[index].grab_focus()
		return
	index = _index_in(_flow.call("bench_players"), id)
	if index >= 0 and index < _bench_buttons.size():
		_bench_buttons[index].grab_focus()

func _index_in(players: Array, id: StringName) -> int:
	for index: int in range(players.size()):
		if StringName(players[index].get("id")) == id:
			return index
	return -1

func _default_focus() -> Control:
	return _active_buttons[0] if not _active_buttons.is_empty() else _continue_button
