extends CharacterBody3D

const RINK_HALF_LENGTH: float = 16.35
const RINK_HALF_WIDTH: float = 8.35

@export var acceleration: float = 22.0
@export var sprint_acceleration: float = 36.0
@export var max_speed: float = 8.0
@export var sprint_max_speed: float = 13.5
@export var ice_friction: float = 4.5
@export var turn_speed: float = 12.0
@export var board_bounce: float = 0.28
@export var puck_path: NodePath = NodePath("../Puck")
@export var puck_carry_distance: float = 1.05
@export var puck_carry_side_offset: float = 0.18
@export var slap_shot_charge_seconds: float = 0.72
@export var minimum_shot_power: float = 0.08
@export var charge_meter_height: float = 0.10
@export var check_cooldown_seconds: float = 0.62
@export var check_active_seconds: float = 0.18
@export var check_lunge_speed: float = 8.0
@export var check_hit_radius: float = 1.35
@export var check_forward_dot: float = 0.18
@export var check_knockback_force: float = 12.0
@export var check_puck_force: float = 12.0

var _move_velocity: Vector3 = Vector3.ZERO
var _last_facing_direction: Vector3 = Vector3.FORWARD
var _puck: Node = null
var _is_charging_shot: bool = false
var _shot_charge_time: float = 0.0
var _check_cooldown_timer: float = 0.0
var _check_active_timer: float = 0.0
var _has_hit_during_check: bool = false
var _body_material: StandardMaterial3D = null
var _checking_material: StandardMaterial3D = null

@onready var _visual_root: Node3D = $VisualRoot
@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var _direction_marker: MeshInstance3D = $VisualRoot/DirectionMarker
var _charge_meter_back: MeshInstance3D = null
var _charge_meter_fill: MeshInstance3D = null
var _charge_fill_material: StandardMaterial3D = null

func _ready() -> void:
	_build_placeholder_visuals()
	_build_charge_meter()
	_puck = get_node_or_null(puck_path)

func _physics_process(delta: float) -> void:
	_update_check_timers(delta)
	_handle_check_input()

	var input_direction: Vector3 = _get_input_direction()
	var is_sprinting: bool = Input.is_action_pressed("skate_sprint")
	var target_acceleration: float = sprint_acceleration if is_sprinting else acceleration
	var target_max_speed: float = sprint_max_speed if is_sprinting else max_speed

	if input_direction.length_squared() > 0.0:
		_move_velocity += input_direction * target_acceleration * delta
		_move_velocity = _move_velocity.limit_length(target_max_speed)
		_last_facing_direction = input_direction
	else:
		_move_velocity = _move_velocity.move_toward(Vector3.ZERO, ice_friction * delta)

	velocity = Vector3(_move_velocity.x, 0.0, _move_velocity.z)
	move_and_slide()
	_move_velocity = Vector3(velocity.x, 0.0, velocity.z)

	_apply_rink_bounds()
	_rotate_visuals(delta)
	_update_check_collision()
	_update_puck_interaction(delta)
	_update_check_visuals()

func _get_input_direction() -> Vector3:
	var input_vector: Vector2 = Input.get_vector("skate_left", "skate_right", "skate_up", "skate_down")
	if input_vector.length_squared() <= 0.0:
		return Vector3.ZERO

	# Screen-space controls mapped to rink-space movement.
	var direction: Vector3 = Vector3(input_vector.x, 0.0, input_vector.y)
	return direction.normalized()

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

func _rotate_visuals(delta: float) -> void:
	var facing_direction: Vector3 = _get_facing_direction()
	if facing_direction.length_squared() <= 0.0:
		return

	var target_yaw: float = atan2(facing_direction.x, facing_direction.z)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, turn_speed * delta)

func _update_check_timers(delta: float) -> void:
	_check_cooldown_timer = max(_check_cooldown_timer - delta, 0.0)
	_check_active_timer = max(_check_active_timer - delta, 0.0)

func _handle_check_input() -> void:
	if not Input.is_action_just_pressed("body_check"):
		return

	if _check_cooldown_timer > 0.0:
		return

	var facing_direction: Vector3 = _get_facing_direction()
	_move_velocity += facing_direction * check_lunge_speed
	_move_velocity = _move_velocity.limit_length(sprint_max_speed + check_lunge_speed * 0.55)
	_check_active_timer = check_active_seconds
	_check_cooldown_timer = check_cooldown_seconds
	_has_hit_during_check = false

func _update_check_collision() -> void:
	if _check_active_timer <= 0.0 or _has_hit_during_check:
		return

	var facing_direction: Vector3 = _get_facing_direction()
	var checkable_nodes: Array[Node] = get_tree().get_nodes_in_group("checkable")

	for checkable_node: Node in checkable_nodes:
		var target: Node3D = checkable_node as Node3D
		if target == null or target == self:
			continue

		var flat_delta: Vector3 = Vector3(target.global_position.x - global_position.x, 0.0, target.global_position.z - global_position.z)
		var distance: float = flat_delta.length()
		if distance > check_hit_radius or distance <= 0.001:
			continue

		var target_direction: Vector3 = flat_delta.normalized()
		var forward_dot: float = facing_direction.dot(target_direction)
		if forward_dot < check_forward_dot:
			continue

		if target.has_method("receive_check"):
			target.call("receive_check", facing_direction, check_knockback_force, _move_velocity)

		if _puck != null and _puck.has_method("poke_free"):
			_puck.call("poke_free", facing_direction + target_direction * 0.35, check_puck_force)

		_has_hit_during_check = true
		_move_velocity = _move_velocity.move_toward(Vector3.ZERO, 2.5)
		return

func _update_check_visuals() -> void:
	if _body_material == null or _checking_material == null:
		return

	if _check_active_timer > 0.0:
		_body_mesh.material_override = _checking_material
	else:
		_body_mesh.material_override = _body_material

func _update_puck_interaction(delta: float) -> void:
	if _puck == null:
		_update_charge_meter(0.0, false)
		return

	if _puck.has_method("can_be_picked_up_by") and _puck.call("can_be_picked_up_by", self):
		_puck.call("take_possession", self)

	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		_update_shot_charge(delta)
		var carry_target: Vector3 = _get_puck_carry_position()
		_puck.call("update_possession", carry_target, _move_velocity, delta)
	else:
		_cancel_shot_charge()

func _update_shot_charge(delta: float) -> void:
	if Input.is_action_just_pressed("puck_shoot"):
		_is_charging_shot = true
		_shot_charge_time = 0.0

	if _is_charging_shot and Input.is_action_pressed("puck_shoot"):
		_shot_charge_time = min(_shot_charge_time + delta, slap_shot_charge_seconds)

	if _is_charging_shot and Input.is_action_just_released("puck_shoot"):
		_release_charged_shot()
		return

	var shot_power: float = _get_shot_power()
	_update_charge_meter(shot_power, _is_charging_shot)

func _release_charged_shot() -> void:
	if _puck == null:
		_cancel_shot_charge()
		return

	var shot_power: float = max(_get_shot_power(), minimum_shot_power)
	_puck.call("shoot", _get_facing_direction(), _move_velocity, shot_power)
	_cancel_shot_charge()

func _cancel_shot_charge() -> void:
	_is_charging_shot = false
	_shot_charge_time = 0.0
	_update_charge_meter(0.0, false)

func _get_shot_power() -> float:
	if slap_shot_charge_seconds <= 0.0:
		return 1.0
	return clamp(_shot_charge_time / slap_shot_charge_seconds, 0.0, 1.0)

func _get_puck_carry_position() -> Vector3:
	var facing_direction: Vector3 = _get_facing_direction()
	var side_direction: Vector3 = Vector3(facing_direction.z, 0.0, -facing_direction.x).normalized()
	var target_position: Vector3 = global_position + facing_direction * puck_carry_distance + side_direction * puck_carry_side_offset
	target_position.y = 0.18
	return target_position

func _get_facing_direction() -> Vector3:
	var facing_direction: Vector3 = _move_velocity.normalized() if _move_velocity.length_squared() > 0.05 else _last_facing_direction
	if facing_direction.length_squared() <= 0.0:
		return Vector3.FORWARD
	return facing_direction.normalized()

func _build_placeholder_visuals() -> void:
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = Color(0.08, 0.34, 1.0, 1.0)
	_body_material.roughness = 0.35
	_body_mesh.material_override = _body_material

	_checking_material = StandardMaterial3D.new()
	_checking_material.albedo_color = Color(0.25, 0.75, 1.0, 1.0)
	_checking_material.emission_enabled = true
	_checking_material.emission = Color(0.1, 0.45, 1.0, 1.0)
	_checking_material.emission_energy_multiplier = 0.45

	var direction_material: StandardMaterial3D = StandardMaterial3D.new()
	direction_material.albedo_color = Color(0.02, 0.025, 0.03, 1.0)
	direction_material.roughness = 0.45
	_direction_marker.material_override = direction_material

func _build_charge_meter() -> void:
	_charge_meter_back = MeshInstance3D.new()
	_charge_meter_back.name = "ShotChargeBack"
	var back_mesh: BoxMesh = BoxMesh.new()
	back_mesh.size = Vector3(1.2, charge_meter_height, 0.10)
	_charge_meter_back.mesh = back_mesh
	_charge_meter_back.position = Vector3(0.0, 1.45, 0.0)
	var back_material: StandardMaterial3D = StandardMaterial3D.new()
	back_material.albedo_color = Color(0.03, 0.03, 0.035, 0.65)
	back_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_charge_meter_back.material_override = back_material
	_visual_root.add_child(_charge_meter_back)

	_charge_meter_fill = MeshInstance3D.new()
	_charge_meter_fill.name = "ShotChargeFill"
	var fill_mesh: BoxMesh = BoxMesh.new()
	fill_mesh.size = Vector3(1.0, charge_meter_height * 1.1, 0.12)
	_charge_meter_fill.mesh = fill_mesh
	_charge_meter_fill.position = Vector3(0.0, 1.45, -0.01)
	_charge_fill_material = StandardMaterial3D.new()
	_charge_fill_material.albedo_color = Color(1.0, 0.85, 0.15, 0.95)
	_charge_fill_material.emission_enabled = true
	_charge_fill_material.emission = Color(1.0, 0.55, 0.05, 1.0)
	_charge_fill_material.emission_energy_multiplier = 0.8
	_charge_fill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_charge_meter_fill.material_override = _charge_fill_material
	_visual_root.add_child(_charge_meter_fill)

	_update_charge_meter(0.0, false)

func _update_charge_meter(power: float, is_visible: bool) -> void:
	if _charge_meter_back == null or _charge_meter_fill == null:
		return

	_charge_meter_back.visible = is_visible
	_charge_meter_fill.visible = is_visible
	if not is_visible:
		return

	var clamped_power: float = clamp(power, 0.0, 1.0)
	_charge_meter_fill.scale.x = max(clamped_power, 0.04)
	_charge_meter_fill.position.x = -0.5 + clamped_power * 0.5

	if _charge_fill_material != null:
		var red_value: float = lerp(1.0, 1.0, clamped_power)
		var green_value: float = lerp(0.85, 0.18, clamped_power)
		var blue_value: float = lerp(0.15, 0.05, clamped_power)
		_charge_fill_material.albedo_color = Color(red_value, green_value, blue_value, 0.95)
		_charge_fill_material.emission = Color(red_value, green_value * 0.75, blue_value, 1.0)
