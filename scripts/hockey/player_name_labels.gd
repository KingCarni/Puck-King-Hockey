extends Node3D

# Lightweight player identity labels for Standard Mode.
# Names are rendered in a dedicated 2D overlay and positioned from each
# skater's projected screen position. This guarantees they stay below the
# player and prevents depth/layer flicker against skater art.

const SCREEN_OFFSET: Vector2 = Vector2(0.0, 31.0)
const SHADOW_OFFSET: Vector2 = Vector2(1.0, 1.0)
const LABEL_SIZE: Vector2 = Vector2(118.0, 24.0)
const NORMAL_FONT_SIZE: int = 14
const CONTROLLED_FONT_SIZE: int = 16
const NORMAL_OUTLINE_SIZE: int = 5
const CONTROLLED_OUTLINE_SIZE: int = 5
const NORMAL_ALPHA: float = 0.72
const CONTROLLED_ALPHA: float = 1.0
const RING_Y: float = -0.43
const RING_INNER_RADIUS: float = 0.70
const RING_OUTER_RADIUS: float = 0.84
const RING_PULSE_MIN: float = 0.95
const RING_PULSE_MAX: float = 1.05
const RING_PULSE_SPEED: float = 7.8539816 # 0.8-second cycle (TAU / 0.8)

var _labels: Dictionary = {}
var _shadows: Dictionary = {}
var _rings: Dictionary = {}
var _players: Dictionary = {}
var _base_names: Dictionary = {}
var _team_colors: Dictionary = {}
var _controlled_player: Node3D = null
var _canvas_layer: CanvasLayer = null
var _overlay: Control = null
var _pulse_time: float = 0.0

func setup(players: Array[Node3D], roster: RefCounted) -> void:
	clear()
	_build_overlay()
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
	set_process(true)

func _process(delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	_pulse_time += delta
	for instance_id: Variant in _labels.keys():
		var player: Node3D = _players.get(instance_id) as Node3D
		var label: Label = _labels.get(instance_id) as Label
		var shadow: Label = _shadows.get(instance_id) as Label
		if player == null or label == null or shadow == null or not is_instance_valid(player) or not is_instance_valid(label) or not is_instance_valid(shadow):
			continue
		var behind_camera: bool = camera.is_position_behind(player.global_position)
		label.visible = not behind_camera
		shadow.visible = not behind_camera
		if behind_camera:
			continue
		var screen_position: Vector2 = camera.unproject_position(player.global_position)
		var base_position: Vector2 = screen_position + SCREEN_OFFSET - LABEL_SIZE * 0.5
		label.position = base_position
		shadow.position = base_position + SHADOW_OFFSET

		var ring: MeshInstance3D = _rings.get(instance_id) as MeshInstance3D
		if ring != null and is_instance_valid(ring) and player == _controlled_player:
			var pulse_t: float = (sin(_pulse_time * RING_PULSE_SPEED) + 1.0) * 0.5
			var pulse_scale: float = lerpf(RING_PULSE_MIN, RING_PULSE_MAX, pulse_t)
			ring.scale = Vector3(pulse_scale, 1.0, pulse_scale)

func set_controlled_player(player: Node3D) -> void:
	_controlled_player = player
	_refresh_styles()

func clear() -> void:
	for ring: Variant in _rings.values():
		if ring is Node and is_instance_valid(ring):
			ring.queue_free()
	if _canvas_layer != null and is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()
	_canvas_layer = null
	_overlay = null
	_labels.clear()
	_shadows.clear()
	_rings.clear()
	_players.clear()
	_base_names.clear()
	_team_colors.clear()
	_controlled_player = null
	_pulse_time = 0.0
	set_process(false)

func _build_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "PlayerNameCanvas"
	_canvas_layer.layer = 8
	add_child(_canvas_layer)

	_overlay = Control.new()
	_overlay.name = "PlayerNameOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_overlay)

func _add_identity(player: Node3D, display_name: String) -> void:
	var instance_id: int = player.get_instance_id()
	var short_name: String = _short_name(display_name)
	var team_color: Color = _team_color(player)
	_players[instance_id] = player
	_base_names[instance_id] = short_name
	_team_colors[instance_id] = team_color

	var shadow := Label.new()
	shadow.name = "PlayerNameShadow"
	shadow.text = short_name
	shadow.size = LABEL_SIZE
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.45))
	shadow.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
	_overlay.add_child(shadow)
	_shadows[instance_id] = shadow

	var label := Label.new()
	label.name = "PlayerNameLabel"
	label.text = short_name
	label.size = LABEL_SIZE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_overlay.add_child(label)
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
	material.albedo_color = Color(team_color.r, team_color.g, team_color.b, 0.82)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = team_color
	material.emission_energy_multiplier = 2.65
	torus.material = material

	player.add_child(ring)
	_rings[instance_id] = ring

func _refresh_styles() -> void:
	for instance_id: Variant in _labels.keys():
		var label: Label = _labels.get(instance_id) as Label
		var shadow: Label = _shadows.get(instance_id) as Label
		var player: Node3D = _players.get(instance_id) as Node3D
		if label == null or shadow == null or player == null or not is_instance_valid(label) or not is_instance_valid(shadow) or not is_instance_valid(player):
			continue
		var is_controlled: bool = player == _controlled_player
		var base_name: String = String(_base_names.get(instance_id, label.text))
		var team_color: Color = _team_colors.get(instance_id, Color.WHITE)

		label.add_theme_font_size_override("font_size", CONTROLLED_FONT_SIZE if is_controlled else NORMAL_FONT_SIZE)
		shadow.add_theme_font_size_override("font_size", CONTROLLED_FONT_SIZE if is_controlled else NORMAL_FONT_SIZE)
		label.add_theme_constant_override("outline_size", CONTROLLED_OUTLINE_SIZE if is_controlled else NORMAL_OUTLINE_SIZE)
		shadow.add_theme_constant_override("outline_size", 0)
		label.add_theme_color_override("font_color", team_color if is_controlled else Color.WHITE)
		label.modulate.a = CONTROLLED_ALPHA if is_controlled else NORMAL_ALPHA
		shadow.modulate.a = 1.0 if is_controlled else NORMAL_ALPHA
		label.text = base_name
		shadow.text = base_name

		var ring: MeshInstance3D = _rings.get(instance_id) as MeshInstance3D
		if ring != null and is_instance_valid(ring):
			ring.visible = is_controlled
			if not is_controlled:
				ring.scale = Vector3.ONE

func _short_name(display_name: String) -> String:
	var cleaned: String = display_name.strip_edges()
	if cleaned.is_empty():
		return "SKATER"
	var words: PackedStringArray = cleaned.split(" ", false)
	if words.is_empty():
		return cleaned.to_upper()
	return String(words[0]).to_upper()

func _fallback_name(player: Node3D) -> String:
	return String(player.name).replace("_", " ").capitalize()

func _team_color(player: Node3D) -> Color:
	var name_lower: String = String(player.name).to_lower()
	if name_lower.contains("away") or name_lower == "player2":
		return Color(1.0, 0.42, 0.34, 1.0)
	return Color(0.34, 0.76, 1.0, 1.0)
