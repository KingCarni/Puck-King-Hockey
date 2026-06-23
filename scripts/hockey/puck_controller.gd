extends Node3D

const RINK_HALF_LENGTH: float = 16.25
const RINK_HALF_WIDTH: float = 8.25
const PUCK_Y: float = 0.18

@export var pickup_radius: float = 1.05
@export var carry_distance: float = 1.05
@export var carry_lag_speed: float = 14.0
@export var loose_friction: float = 3.2
@export var board_bounce: float = 0.72
@export var shot_speed: float = 18.0
@export var max_loose_speed: float = 22.0

var _velocity: Vector3 = Vector3.ZERO
var _owner: Node3D = null
var _is_possessed: bool = false

@onready var _puck_mesh: MeshInstance3D = $PuckMesh

func _ready() -> void:
	_build_placeholder_visuals()
	global_position.y = PUCK_Y

func _physics_process(delta: float) -> void:
	if _is_possessed:
		return

	global_position += _velocity * delta
	global_position.y = PUCK_Y
	_velocity = _velocity.move_toward(Vector3.ZERO, loose_friction * delta)
	_apply_rink_bounds()

func can_be_picked_up_by(player: Node3D) -> bool:
	if _is_possessed:
		return false

	var flat_delta: Vector3 = _flat_position(global_position) - _flat_position(player.global_position)
	return flat_delta.length() <= pickup_radius

func take_possession(owner: Node3D) -> void:
	_owner = owner
	_is_possessed = true
	_velocity = Vector3.ZERO

func is_possessed_by(owner: Node3D) -> bool:
	return _is_possessed and _owner == owner

func update_possession(target_position: Vector3, owner_velocity: Vector3, delta: float) -> void:
	if not _is_possessed:
		return

	var target: Vector3 = target_position
	target.y = PUCK_Y
	var lerp_weight: float = clamp(carry_lag_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target, lerp_weight)
	global_position.y = PUCK_Y
	_velocity = Vector3(owner_velocity.x, 0.0, owner_velocity.z)

func shoot(direction: Vector3, owner_velocity: Vector3) -> void:
	var shot_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if shot_direction.length_squared() <= 0.001:
		shot_direction = Vector3.FORWARD

	_is_possessed = false
	_owner = null
	_velocity = shot_direction.normalized() * shot_speed + Vector3(owner_velocity.x, 0.0, owner_velocity.z) * 0.28
	_velocity = _velocity.limit_length(max_loose_speed)
	global_position += shot_direction.normalized() * 0.45
	global_position.y = PUCK_Y

func poke_free(direction: Vector3, force: float) -> void:
	var release_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if release_direction.length_squared() <= 0.001:
		release_direction = Vector3.FORWARD

	_is_possessed = false
	_owner = null
	_velocity = release_direction.normalized() * force
	_velocity = _velocity.limit_length(max_loose_speed)

func _apply_rink_bounds() -> void:
	var clamped_x: float = clamp(global_position.x, -RINK_HALF_LENGTH, RINK_HALF_LENGTH)
	var clamped_z: float = clamp(global_position.z, -RINK_HALF_WIDTH, RINK_HALF_WIDTH)
	var hit_horizontal_board: bool = not is_equal_approx(clamped_x, global_position.x)
	var hit_vertical_board: bool = not is_equal_approx(clamped_z, global_position.z)

	if hit_horizontal_board:
		global_position.x = clamped_x
		_velocity.x = -_velocity.x * board_bounce

	if hit_vertical_board:
		global_position.z = clamped_z
		_velocity.z = -_velocity.z * board_bounce

func _flat_position(position: Vector3) -> Vector3:
	return Vector3(position.x, 0.0, position.z)

func _build_placeholder_visuals() -> void:
	var puck_material: StandardMaterial3D = StandardMaterial3D.new()
	puck_material.albedo_color = Color(0.015, 0.015, 0.018, 1.0)
	puck_material.roughness = 0.28
	_puck_mesh.material_override = puck_material
