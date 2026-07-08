extends Node3D

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const RINK_HALF_LENGTH: float = 19.25
const RINK_HALF_WIDTH: float = 9.25
const PLAYER_Y: float = 0.72
const PUCK_Y: float = 0.18

@export var puck_path: NodePath = NodePath("../Puck")
@export var player_path: NodePath = NodePath("../Player")
@export var acceleration: float = 13.5
@export var max_speed: float = 6.1
@export var friction: float = 4.6
@export var turn_speed: float = 8.0
@export var board_bounce: float = 0.32
@export var puck_carry_distance: float = 1.0
@export var puck_carry_side_offset: float = 0.18
@export var shooting_x_threshold: float = 10.2
@export var shoot_cooldown_seconds: float = 1.05
@export var shot_power: float = 0.62
@export var support_distance_x: float = 3.0
@export var support_distance_z: float = 2.5
@export var skater_texture_path: String = "res://assets/art/characters/pkh_skater_home_alt.svg"

var _move_velocity: Vector3 = Vector3.ZERO
var _last_facing_direction: Vector3 = Vector3.RIGHT
var _shoot_cooldown_timer: float = 0.0
var _stagger_timer: float = 0.0
var _puck: Node = null
var _player: Node3D = null
var _base_material: StandardMaterial3D = null
var _possession_material: StandardMaterial3D = null

@onready var _visual_root: Node3D = $VisualRoot
@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var _direction_marker: MeshInstance3D = $VisualRoot/DirectionMarker

func _ready() -> void:
	_build_placeholder_visuals()
	add_to_group("checkable")
	_puck = get_node_or_null(puck_path)
	_player = get_node_or_null(player_path) as Node3D

func receive_check(direction: Vector3, force: float, checker_velocity: Vector3) -> void:
	var hit_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if hit_direction.length_squared() <= 0.001:
		hit_direction = Vector3.RIGHT
	_move_velocity = hit_direction.normalized() * force + Vector3(checker_velocity.x, 0.0, checker_velocity.z) * 0.22
	_stagger_timer = 0.5

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_ai(delta)
	_update_movement(delta)
	_update_puck_interaction(delta)
	_update_visuals(delta)

func _update_timers(delta: float) -> void:
	_shoot_cooldown_timer = max(_shoot_cooldown_timer - delta, 0.0)
	_stagger_timer = max(_stagger_timer - delta, 0.0)

func _update_ai(delta: float) -> void:
	if _stagger_timer > 0.0:
		return
	if _puck == null:
		_apply_friction(delta)
		return

	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		_drive_with_puck(delta)
		return

	var target_position: Vector3 = _get_puck_position()
	if _player != null and _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", _player)):
		target_position = _get_support_position()
	elif _player != null:
		# Loose-puck chase: don't stack on the center; shade to open ice.
		var to_player: Vector3 = _player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() < 2.2:
			var separation: Vector3 = -to_player.normalized() * 2.4
			target_position += Vector3(0.0, 0.0, separation.z)

	_skate_toward(target_position, delta)

func _drive_with_puck(delta: float) -> void:
	var attack_target: Vector3 = Vector3(RINK_HALF_LENGTH - 1.0, PLAYER_Y, 0.0)
	_skate_toward(attack_target, delta)

	var close_enough_to_shoot: bool = global_position.x >= shooting_x_threshold
	var roughly_facing_net: bool = _get_facing_direction().dot(Vector3.RIGHT) > 0.45
	if close_enough_to_shoot and roughly_facing_net and _shoot_cooldown_timer <= 0.0:
		_shoot_toward_away_goal()

func _update_movement(delta: float) -> void:
	global_position += _move_velocity * delta
	global_position.y = PLAYER_Y
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, friction * delta)
	_apply_rink_bounds()

func _update_puck_interaction(delta: float) -> void:
	if _puck == null:
		return

	if _puck.has_method("can_be_picked_up_by") and bool(_puck.call("can_be_picked_up_by", self)):
		_puck.call("take_possession", self)

	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		var carry_target: Vector3 = _get_puck_carry_position()
		_puck.call("update_possession", carry_target, _move_velocity, delta)

func _skate_toward(target_position: Vector3, delta: float) -> void:
	var flat_delta: Vector3 = Vector3(target_position.x - global_position.x, 0.0, target_position.z - global_position.z)
	if flat_delta.length_squared() <= 0.08:
		_apply_friction(delta)
		return

	var desired_direction: Vector3 = flat_delta.normalized()
	_move_velocity += desired_direction * acceleration * delta
	_move_velocity = _move_velocity.limit_length(max_speed)
	_last_facing_direction = desired_direction

func _apply_friction(delta: float) -> void:
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, friction * delta)

func _shoot_toward_away_goal() -> void:
	if _puck == null or not _puck.has_method("shoot"):
		return

	var target_z: float = clamp(global_position.z * 0.25, -2.6, 2.6)
	var goal_target: Vector3 = Vector3(RINK_HALF_LENGTH + 1.0, PUCK_Y, target_z)
	var shot_direction: Vector3 = Vector3(goal_target.x - global_position.x, 0.0, goal_target.z - global_position.z).normalized()
	_puck.call("shoot", shot_direction, _move_velocity, shot_power)
	_shoot_cooldown_timer = shoot_cooldown_seconds

func _get_support_position() -> Vector3:
	if _player == null:
		return global_position

	# Stay ahead of the carrier toward the attack (+X), on the opposite
	# lateral side of the puck, so a pass lane is always open.
	var puck_z: float = _get_puck_position().z
	var side: float = -1.0 if puck_z > 0.0 else 1.0
	var lead_x: float = support_distance_x
	if _player.global_position.x > RINK_HALF_LENGTH - 6.0:
		lead_x = 1.0  # deep in the zone: pull level for a one-timer instead of overskating
	var support: Vector3 = _player.global_position + Vector3(lead_x, 0.0, support_distance_z * side)
	support.x = clamp(support.x, -RINK_HALF_LENGTH + 1.5, RINK_HALF_LENGTH - 3.0)
	support.z = clamp(support.z, -RINK_HALF_WIDTH + 1.2, RINK_HALF_WIDTH - 1.2)
	support.y = PLAYER_Y
	return support

func _get_puck_position() -> Vector3:
	if _puck == null:
		return global_position

	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return global_position

	return puck_node.global_position

func _get_puck_carry_position() -> Vector3:
	var facing_direction: Vector3 = _get_facing_direction()
	var side_direction: Vector3 = Vector3(facing_direction.z, 0.0, -facing_direction.x).normalized()
	var target_position: Vector3 = global_position + facing_direction * puck_carry_distance + side_direction * puck_carry_side_offset
	target_position.y = PUCK_Y
	return target_position

func _get_facing_direction() -> Vector3:
	var facing_direction: Vector3 = _move_velocity.normalized() if _move_velocity.length_squared() > 0.05 else _last_facing_direction
	if facing_direction.length_squared() <= 0.0:
		return Vector3.RIGHT
	return facing_direction.normalized()

func _apply_rink_bounds() -> void:
	var clamped_x: float = clamp(global_position.x, -RINK_HALF_LENGTH, RINK_HALF_LENGTH)
	var clamped_z: float = clamp(global_position.z, -RINK_HALF_WIDTH, RINK_HALF_WIDTH)
	var hit_horizontal_board: bool = not is_equal_approx(clamped_x, global_position.x)
	var hit_vertical_board: bool = not is_equal_approx(clamped_z, global_position.z)

	if hit_horizontal_board:
		global_position.x = clamped_x
		_move_velocity.x = -_move_velocity.x * board_bounce

	if hit_vertical_board:
		global_position.z = clamped_z
		_move_velocity.z = -_move_velocity.z * board_bounce

func _update_visuals(delta: float) -> void:
	var facing_direction: Vector3 = _get_facing_direction()
	var target_yaw: float = atan2(facing_direction.x, facing_direction.z)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, turn_speed * delta)

	if _body_mesh == null:
		return

	if _puck != null and _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		_body_mesh.material_override = _possession_material
	else:
		_body_mesh.material_override = _base_material

func _build_placeholder_visuals() -> void:
	var skater_texture: Texture2D = SkaterSpriteVisuals.load_texture(skater_texture_path)
	if skater_texture != null:
		SkaterSpriteVisuals.apply_skater_sprite(_body_mesh, _direction_marker)
		_base_material = SkaterSpriteVisuals.make_sprite_material(skater_texture)
		_possession_material = SkaterSpriteVisuals.make_sprite_material(skater_texture, Color(1.25, 1.30, 1.50, 1.0))
		_body_mesh.material_override = _base_material
		return

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.08, 0.45, 1.0, 1.0)
	_base_material.roughness = 0.35

	_possession_material = StandardMaterial3D.new()
	_possession_material.albedo_color = Color(0.20, 0.75, 1.0, 1.0)
	_possession_material.emission_enabled = true
	_possession_material.emission = Color(0.10, 0.45, 1.0, 1.0)
	_possession_material.emission_energy_multiplier = 0.35

	var direction_material: StandardMaterial3D = StandardMaterial3D.new()
	direction_material.albedo_color = Color(0.02, 0.025, 0.03, 1.0)
	direction_material.roughness = 0.45

	_body_mesh.material_override = _base_material
	_direction_marker.material_override = direction_material
