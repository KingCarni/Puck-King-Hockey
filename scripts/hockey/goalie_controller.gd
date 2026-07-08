extends Node3D

# Simple crease goalie: idle → track puck → move across crease → save →
# recover → return to center. Never leaves the crease, never crosses center.

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const PLAYER_Y: float = 0.72

@export var puck_path: NodePath = NodePath("../Puck")
## -1.0 guards the left (-X) goal, +1.0 guards the right (+X) goal.
@export var guard_side: float = -1.0
@export var guard_distance_from_center: float = 17.35
@export var crease_half_width: float = 2.05
@export var crease_depth: float = 0.85
@export var lateral_max_speed: float = 6.4
@export var lateral_acceleration: float = 26.0
@export var friction: float = 9.0
@export var block_radius: float = 1.15
@export var save_deflect_speed: float = 9.5
@export var save_cooldown_seconds: float = 0.45
@export var save_flash_seconds: float = 0.30
@export var goalie_texture_path: String = "res://assets/art/characters/pkh_goalie_home.svg"

var _puck: Node = null
var _lateral_velocity: float = 0.0
var _save_cooldown_timer: float = 0.0
var _save_flash_timer: float = 0.0
var _base_material: StandardMaterial3D = null
var _save_material: StandardMaterial3D = null

@onready var _visual_root: Node3D = $VisualRoot
@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh

func _ready() -> void:
	_build_visuals()
	_puck = get_node_or_null(puck_path)
	reset_to_center()

func _physics_process(delta: float) -> void:
	_save_cooldown_timer = max(_save_cooldown_timer - delta, 0.0)
	_save_flash_timer = max(_save_flash_timer - delta, 0.0)
	_update_positioning(delta)
	_update_block()
	_update_visuals(delta)

func reset_to_center() -> void:
	global_position = Vector3(_guard_x(), PLAYER_Y, 0.0)
	_lateral_velocity = 0.0
	_save_cooldown_timer = 0.0
	_save_flash_timer = 0.0

func _guard_x() -> float:
	return guard_side * guard_distance_from_center

func _update_positioning(delta: float) -> void:
	var target_z: float = _pick_target_z()
	var delta_z: float = target_z - global_position.z

	if abs(delta_z) > 0.06:
		_lateral_velocity += signf(delta_z) * lateral_acceleration * delta
		_lateral_velocity = clampf(_lateral_velocity, -lateral_max_speed, lateral_max_speed)
	else:
		_lateral_velocity = move_toward(_lateral_velocity, 0.0, friction * delta)

	global_position.z = clampf(global_position.z + _lateral_velocity * delta, -crease_half_width, crease_half_width)
	# Hug the crease line; a save can nudge the goalie, ease back in.
	global_position.x = lerpf(global_position.x, _guard_x(), clampf(6.0 * delta, 0.0, 1.0))
	global_position.x = clampf(global_position.x, _guard_x() - crease_depth, _guard_x() + crease_depth)
	global_position.y = PLAYER_Y

func _pick_target_z() -> float:
	if _puck == null:
		return 0.0
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return 0.0

	var puck_position: Vector3 = puck_node.global_position
	var puck_velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = _puck.get("_velocity")
	if raw_velocity is Vector3:
		puck_velocity = raw_velocity

	# Shot incoming: slide to where the puck will cross the goal line.
	var toward_goal: bool = puck_velocity.x * guard_side > 2.0
	if toward_goal and absf(puck_velocity.x) > 0.5:
		var time_to_line: float = (_guard_x() - puck_position.x) / puck_velocity.x
		if time_to_line > 0.0 and time_to_line < 1.4:
			return clampf(puck_position.z + puck_velocity.z * time_to_line, -crease_half_width, crease_half_width)

	# Otherwise mirror the puck with a small anticipation lead.
	return clampf(puck_position.z + puck_velocity.z * 0.10, -crease_half_width, crease_half_width)

func _update_block() -> void:
	if _puck == null or _save_cooldown_timer > 0.0:
		return
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return

	var flat_delta: Vector3 = puck_node.global_position - global_position
	flat_delta.y = 0.0
	if flat_delta.length() > block_radius:
		return

	# Kick the puck away from the net toward the near corner.
	var clear_direction: Vector3 = Vector3(-guard_side, 0.0, signf(global_position.z) if absf(global_position.z) > 0.15 else (1.0 if randf() > 0.5 else -1.0))
	if _puck.has_method("poke_free"):
		_puck.call("poke_free", clear_direction.normalized(), save_deflect_speed)
	_save_cooldown_timer = save_cooldown_seconds
	_save_flash_timer = save_flash_seconds
	# Saves push the goalie back slightly for weight.
	global_position.x += guard_side * 0.18

func _update_visuals(delta: float) -> void:
	if _visual_root == null:
		return
	var facing: Vector3 = Vector3(-guard_side, 0.0, 0.0)
	if _puck != null:
		var puck_node: Node3D = _puck as Node3D
		if puck_node != null:
			var to_puck: Vector3 = puck_node.global_position - global_position
			to_puck.y = 0.0
			if to_puck.length_squared() > 0.04:
				# Face the puck, but never turn away from center ice.
				facing = to_puck.normalized().lerp(Vector3(-guard_side, 0.0, 0.0), 0.45).normalized()
	var target_yaw: float = atan2(facing.x, facing.z)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, clampf(7.0 * delta, 0.0, 1.0))

	if _body_mesh == null or _base_material == null:
		return
	_body_mesh.material_override = _save_material if _save_flash_timer > 0.0 else _base_material

func _build_visuals() -> void:
	var texture: Texture2D = SkaterSpriteVisuals.load_texture(goalie_texture_path)
	if texture != null:
		SkaterSpriteVisuals.apply_skater_sprite(_body_mesh, null, SkaterSpriteVisuals.SPRITE_SIZE * 1.12)
		_base_material = SkaterSpriteVisuals.make_sprite_material(texture)
		_save_material = SkaterSpriteVisuals.make_sprite_material(texture, Color(1.55, 1.60, 1.85, 1.0))
		_body_mesh.material_override = _base_material
		return

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.90, 0.92, 0.95, 1.0)
	_save_material = _base_material
	_body_mesh.material_override = _base_material
