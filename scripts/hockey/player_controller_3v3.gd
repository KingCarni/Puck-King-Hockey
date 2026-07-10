extends "res://scripts/hockey/player_controller.gd"

# Thin match-specific wrapper around the core player controller.
# Gives the user room behind the net and lets Pass double as "call for pass"
# when a teammate already has the puck.

const EXPANDED_RINK_HALF_LENGTH: float = 24.2
const EXPANDED_RINK_HALF_WIDTH: float = 11.6
const CALL_PASS_POWER: float = 0.42
const MIN_CALL_PASS_SPEED_BONUS: float = 2.5

func _apply_rink_bounds() -> void:
	var clamped_x: float = clamp(global_position.x, -EXPANDED_RINK_HALF_LENGTH, EXPANDED_RINK_HALF_LENGTH)
	var clamped_z: float = clamp(global_position.z, -EXPANDED_RINK_HALF_WIDTH, EXPANDED_RINK_HALF_WIDTH)
	var hit_horizontal_board: bool = not is_equal_approx(clamped_x, global_position.x)
	var hit_vertical_board: bool = not is_equal_approx(clamped_z, global_position.z)
	if hit_horizontal_board:
		global_position.x = clamped_x
		_move_velocity.x = -_move_velocity.x * board_bounce
	if hit_vertical_board:
		global_position.z = clamped_z
		_move_velocity.z = -_move_velocity.z * board_bounce

func _update_puck_interaction(delta: float) -> void:
	if _puck == null:
		_update_charge_meter(0.0, false)
		return

	var has_possession: bool = _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self))
	if not has_possession and _input_source.is_pass_just_pressed():
		if _try_call_for_pass():
			return

	if _puck.has_method("can_be_picked_up_by") and _puck.call("can_be_picked_up_by", self):
		_puck.call("take_possession", self)

	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		if _try_pass():
			return
		_update_shot_charge(delta)
		var carry_target: Vector3 = _get_puck_carry_position()
		_puck.call("update_possession", carry_target, _move_velocity, delta)
	else:
		_cancel_shot_charge()

func _try_call_for_pass() -> bool:
	if _puck == null or not _puck.has_method("is_possessed_by"):
		return false
	var carriers: Array[Node3D] = _get_teammate_carriers()
	for carrier: Node3D in carriers:
		if carrier == null or not is_instance_valid(carrier):
			continue
		if bool(_puck.call("is_possessed_by", carrier)):
			_force_pass_from(carrier)
			return true
	return false

func _get_teammate_carriers() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if input_prefix == "p1":
		_append_teammate(result, "../HomeTeammate")
		_append_teammate(result, "../HomeTeammate2")
	else:
		_append_teammate(result, "../AwayTeammate")
		_append_teammate(result, "../AwayTeammate2")
	return result

func _append_teammate(result: Array[Node3D], path: String) -> void:
	var teammate: Node3D = get_node_or_null(path) as Node3D
	if teammate != null:
		result.append(teammate)

func _force_pass_from(carrier: Node3D) -> void:
	var carrier_velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = carrier.get("_move_velocity")
	if raw_velocity is Vector3:
		carrier_velocity = raw_velocity
	var lead_target: Vector3 = global_position + _move_velocity * 0.35
	var pass_direction: Vector3 = Vector3(lead_target.x - carrier.global_position.x, 0.0, lead_target.z - carrier.global_position.z)
	if pass_direction.length_squared() <= 0.001:
		pass_direction = Vector3(global_position.x - carrier.global_position.x, 0.0, global_position.z - carrier.global_position.z)
	if pass_direction.length_squared() <= 0.001:
		return
	var boosted_carrier_velocity: Vector3 = carrier_velocity + pass_direction.normalized() * MIN_CALL_PASS_SPEED_BONUS
	_puck.call("shoot", pass_direction.normalized(), boosted_carrier_velocity, CALL_PASS_POWER)
