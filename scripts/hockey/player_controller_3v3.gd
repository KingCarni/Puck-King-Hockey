extends "res://scripts/hockey/player_controller.gd"

const EXPANDED_RINK_HALF_LENGTH: float = 24.2
const EXPANDED_RINK_HALF_WIDTH: float = 11.6

var _team_play_manager: Node = null
var _pass_charge: float = 0.0

func set_human_control(source: RefCounted, manager: Node) -> void:
	set_input_source(source)
	_team_play_manager = manager

func set_ai_control() -> void:
	_team_play_manager = null

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

	var owns_puck: bool = _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self))
	if _team_play_manager != null:
		var prefix: String = input_prefix
		if Input.is_action_just_pressed(prefix + "_pass"):
			_pass_charge = 0.0
		if Input.is_action_pressed(prefix + "_pass"):
			_pass_charge = minf(_pass_charge + delta / 0.45, 1.0)
		if Input.is_action_just_released(prefix + "_pass"):
			if owns_puck:
				_team_play_manager.call("execute_pass", self, _get_facing_direction(), _pass_charge)
			else:
				_team_play_manager.call("request_pass", self)
			_pass_charge = 0.0

	if _puck.has_method("can_be_picked_up_by") and _puck.call("can_be_picked_up_by", self):
		_puck.call("take_possession", self)

	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", self)):
		_update_shot_charge(delta)
		var carry_target: Vector3 = _get_puck_carry_position()
		_puck.call("update_possession", carry_target, _move_velocity, delta)
	else:
		_cancel_shot_charge()
