extends Node3D

# Lightweight in-world identity labels for Standard Mode.
# Names stay small and below each skater. The controlled skater is identified
# by hockey-stick bookends and a glowing ice-level ring without interrupting play.

const LABEL_HEIGHT: float = -0.66
const NORMAL_FONT_SIZE: int = 11
const CONTROLLED_FONT_SIZE: int = 14
const NORMAL_OUTLINE_SIZE: int = 3
const CONTROLLED_OUTLINE_SIZE: int = 4
const NORMAL_ALPHA: float = 0.62
const CONTROLLED_ALPHA: float = 1.0
const RING_Y: float = -0.43
const RING_INNER_RADIUS: float = 0.70
const RING_OUTER_RADIUS: float = 0.84

var _labels: Dictionary = {}
var _rings: Dictionary = {}
var _base_names: Dictionary = {}
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
		_add_identity(player, display_name)
	_refresh_styles()

func set_controlled_player(player: Node3D) -> void:
	_controlled_player = player
	_refresh_styles()

func clear() -> void:
	for label: Variant in _labels.values():
		if label is Node and is_instance_valid(label):
			label.queue_free()
	for ring: Variant in _rings.values():
		if ring is Node and is_instance_valid(ring):
			ring.queue_free()
	_labels.clear()
	_rings.clear()
	_base_names.clear()
	_controlled_player = null

func _add_identity(player: Node3D, display_name: String) -> void:
	var instance_id: int = player.get_instance_id()
	var short_name: String = _short_name(display_name)
	_base_names[instance_id] = short_name

	var label := Label3D.new()
	label.name = "PlayerNameLabel"
	label.text = short_name
	label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	label.modulate = _team_color(player)
	label.outline_modulate = Color(0.015, 0.015, 0.02, 0.94)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player.add_child(label)
	_labels[instance_id] = label

	var ring := MeshInstance3D.new()
	ring.name = "ControlledPlayerRing"
	var torus := TorusMesh.new()
	torus.inner_radius = RING_INNER_RADIUS
	torus.outer_radius = RING_OUTER_RADIUS
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.position = Vector3(0.0, RING_Y, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false

	var material := StandardMaterial3D.new()
	var ring_color: Color = _team_color(player)
	material.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.78)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = ring_color
	material.emission_energy_multiplier = 2.2
	torus.material = material

	player.add_child(ring)
	_rings[instance_id] = ring

func _refresh_styles() -> void:
	for instance_id: Variant in _labels.keys():
		var label: Label3D = _labels[instance_id] as Label3D
		if label == null or not is_instance_valid(label):
			continue
		var player: Node3D = label.get_parent() as Node3D
		var is_controlled: bool = player != null and player == _controlled_player
		var base_name: String = String(_base_names.get(instance_id, label.text))

		label.font_size = CONTROLLED_FONT_SIZE if is_controlled else NORMAL_FONT_SIZE
		label.outline_size = CONTROLLED_OUTLINE_SIZE if is_controlled else NORMAL_OUTLINE_SIZE
		label.modulate.a = CONTROLLED_ALPHA if is_controlled else NORMAL_ALPHA
		label.text = "🏒 %s 🏒" % base_name if is_controlled else base_name

		var ring: MeshInstance3D = _rings.get(instance_id) as MeshInstance3D
		if ring != null and is_instance_valid(ring):
			ring.visible = is_controlled

func _short_name(display_name: String) -> String:
	var cleaned: String = display_name.strip_edges()
	if cleaned.is_empty():
		return "SKATER"
	var words: PackedStringArray = cleaned.split(" ", false)
	if words.is_empty():
		return cleaned.to_upper()
	# In-match labels prioritize immediate recognition. Menus can retain full names.
	return String(words[0]).to_upper()

func _fallback_name(player: Node3D) -> String:
	return String(player.name).replace("_", " ").capitalize()

func _team_color(player: Node3D) -> Color:
	var name_lower: String = String(player.name).to_lower()
	if name_lower.contains("away") or name_lower == "player2":
		return Color(1.0, 0.42, 0.34, 1.0)
	return Color(0.34, 0.76, 1.0, 1.0)
