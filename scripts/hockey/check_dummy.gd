extends Node3D

const RINK_HALF_LENGTH: float = 16.25
const RINK_HALF_WIDTH: float = 8.25

@export var friction: float = 7.5
@export var board_bounce: float = 0.35
@export var stun_seconds: float = 0.55

var _velocity: Vector3 = Vector3.ZERO
var _stun_timer: float = 0.0
var _base_material: StandardMaterial3D = null
var _stun_material: StandardMaterial3D = null

@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var _direction_marker: MeshInstance3D = $VisualRoot/DirectionMarker

func _ready() -> void:
	_build_placeholder_visuals()
	add_to_group("checkable")

func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer = max(_stun_timer - delta, 0.0)
		_body_mesh.material_override = _stun_material
	else:
		_body_mesh.material_override = _base_material

	global_position += _velocity * delta
	global_position.y = 0.72
	_velocity = _velocity.move_toward(Vector3.ZERO, friction * delta)
	_apply_rink_bounds()
	_rotate_toward_velocity(delta)

func receive_check(direction: Vector3, force: float, checker_velocity: Vector3) -> void:
	var hit_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if hit_direction.length_squared() <= 0.001:
		hit_direction = Vector3.FORWARD

	var inherited_velocity: Vector3 = Vector3(checker_velocity.x, 0.0, checker_velocity.z) * 0.22
	_velocity = hit_direction.normalized() * force + inherited_velocity
	_stun_timer = stun_seconds

func is_stunned() -> bool:
	return _stun_timer > 0.0

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

func _rotate_toward_velocity(delta: float) -> void:
	if _velocity.length_squared() <= 0.05:
		return

	var direction: Vector3 = _velocity.normalized()
	var target_yaw: float = atan2(direction.x, direction.z)
	$VisualRoot.rotation.y = lerp_angle($VisualRoot.rotation.y, target_yaw, 10.0 * delta)

func _build_placeholder_visuals() -> void:
	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(1.0, 0.18, 0.12, 1.0)
	_base_material.roughness = 0.35

	_stun_material = StandardMaterial3D.new()
	_stun_material.albedo_color = Color(1.0, 0.78, 0.08, 1.0)
	_stun_material.emission_enabled = true
	_stun_material.emission = Color(1.0, 0.35, 0.05, 1.0)
	_stun_material.emission_energy_multiplier = 0.55

	var direction_material: StandardMaterial3D = StandardMaterial3D.new()
	direction_material.albedo_color = Color(0.02, 0.025, 0.03, 1.0)
	direction_material.roughness = 0.45

	_body_mesh.material_override = _base_material
	_direction_marker.material_override = direction_material
