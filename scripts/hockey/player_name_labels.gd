extends Node3D

# Lightweight in-world identity labels for Standard Mode.
# Every skater receives a name label. The controlled skater is emphasized
# without pausing or interrupting gameplay.

const LABEL_HEIGHT: float = 0.72
const NORMAL_FONT_SIZE: int = 22
const CONTROLLED_FONT_SIZE: int = 28
const NORMAL_OUTLINE_SIZE: int = 6
const CONTROLLED_OUTLINE_SIZE: int = 9

var _labels: Dictionary = {}
var _controlled_player: Node3D = null

func setup(players: Array[Node3D], roster: RefCounted) -> void:
	clear()
	for player: Node3D in players:
		if player == null:
			continue
		var display_name: String = ""
		if roster != null and roster.has_method("display_name_for"):
			display_name = String(roster.call("display_name_for", player))
		if display_name.strip_edges().is_empty():
			display_name = _fallback_name(player)
		_add_label(player, display_name)
	_refresh_styles()

func set_controlled_player(player: Node3D) -> void:
	_controlled_player = player
	_refresh_styles()

func clear() -> void:
	for label: Variant in _labels.values():
		if label is Node and is_instance_valid(label):
			label.queue_free()
	_labels.clear()
	_controlled_player = null

func _add_label(player: Node3D, display_name: String) -> void:
	var label := Label3D.new()
	label.name = "PlayerNameLabel"
	label.text = display_name.to_upper()
	label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	label.modulate = _team_color(player)
	label.outline_modulate = Color(0.02, 0.02, 0.02, 0.96)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player.add_child(label)
	_labels[player.get_instance_id()] = label

func _refresh_styles() -> void:
	for instance_id: Variant in _labels.keys():
		var label: Label3D = _labels[instance_id] as Label3D
		if label == null or not is_instance_valid(label):
			continue
		var player: Node3D = label.get_parent() as Node3D
		var is_controlled: bool = player != null and player == _controlled_player
		label.font_size = CONTROLLED_FONT_SIZE if is_controlled else NORMAL_FONT_SIZE
		label.outline_size = CONTROLLED_OUTLINE_SIZE if is_controlled else NORMAL_OUTLINE_SIZE
		label.modulate.a = 1.0 if is_controlled else 0.74
		label.position.y = LABEL_HEIGHT + (0.08 if is_controlled else 0.0)
		label.text = ("▼ " if is_controlled else "") + _base_label_text(label)

func _base_label_text(label: Label3D) -> String:
	var current: String = label.text
	if current.begins_with("▼ "):
		return current.substr(2)
	return current

func _fallback_name(player: Node3D) -> String:
	return String(player.name).replace("_", " ").capitalize()

func _team_color(player: Node3D) -> Color:
	var name_lower: String = String(player.name).to_lower()
	if name_lower.contains("away") or name_lower == "player2":
		return Color(1.0, 0.42, 0.34, 1.0)
	return Color(0.34, 0.76, 1.0, 1.0)
