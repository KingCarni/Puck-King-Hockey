extends "res://scripts/hockey/winger_controller.gd"

@export_enum("LEFT", "RIGHT") var wing_role: String = "LEFT"
@export var same_team_winger_path: NodePath = NodePath("")

var _human_input: RefCounted = null
var _team_play_manager: Node = null
var _pass_charge: float = 0.0
var _same_team_winger: Node3D = null

func _ready() -> void:
	super._ready()
	_same_team_winger = get_node_or_null(same_team_winger_path) as Node3D

func set_human_control(source: RefCounted, manager: Node) -> void:
	_human_input = source
	_team_play_manager = manager

func set_ai_control() -> void:
	_human_input = null
	_team_play_manager = null
	_pass_charge = 0.0

func _physics_process(delta: float) -> void:
	if _human_input == null:
		super._physics_process(delta)
		return
	_update_timers(delta)
	if _stun_timer > 0.0:
		_apply_friction(delta)
	else:
		_update_human(delta)
	_update_movement(delta)
	_update_puck_interaction(delta)
	_update_visuals(delta)

func _update_human(delta: float) -> void:
	var move: Vector2 = _human_input.get_move_vector()
	if move.length_squared() > 0.01:
		var desired: Vector3 = Vector3(move.x, 0.0, move.y).normalized()
		var sprinting: bool = _human_input.is_sprint_pressed()
		var accel: float = get_runtime_stat(&"sprint_acceleration", sprint_acceleration) if sprinting else get_runtime_stat(&"acceleration", acceleration)
		var top: float = get_runtime_stat(&"sprint_max_speed", sprint_max_speed) if sprinting else get_runtime_stat(&"max_speed", max_speed)
		_move_velocity += desired * accel * delta
		_move_velocity = _move_velocity.limit_length(top)
		_last_facing_direction = desired
	else:
		_apply_friction(delta)

	if _human_input.is_check_just_pressed():
		_try_human_check()

	if _human_input.is_pass_just_pressed():
		_pass_charge = 0.0
	if Input.is_action_pressed(_human_prefix() + "_pass"):
		_pass_charge = minf(_pass_charge + delta / 0.45, 1.0)
	if Input.is_action_just_released(_human_prefix() + "_pass"):
		if _possesses(self) and _team_play_manager != null:
			_team_play_manager.call("execute_pass", self, _get_facing_direction(), _pass_charge)
		elif _team_play_manager != null:
			_team_play_manager.call("request_pass", self)
		_pass_charge = 0.0

	if _possesses(self) and _human_input.is_shoot_just_released():
		_puck.call("shoot", _get_facing_direction(), _move_velocity, 0.55, get_runtime_attribute(&"shot_power_scale", 1.0))

func _human_prefix() -> String:
	return "p1" if attack_direction > 0.0 else "p2"

func _try_human_check() -> void:
	var nearest: Node3D = null
	var nearest_distance: float = 1.75
	for enemy: Node3D in _enemies():
		var distance: float = _flat_distance(global_position, enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest == null:
		return
	var direction: Vector3 = nearest.global_position - global_position
	direction.y = 0.0
	if nearest.has_method("receive_check"):
		nearest.call("receive_check", direction.normalized(), 12.0, _move_velocity, {})

func _offense_support(delta: float) -> void:
	var carrier: Node3D = _ally_center
	if carrier == null:
		_apply_friction(delta)
		return
	var preferred_z: float = -4.4 if wing_role == "LEFT" else 4.4
	var forward_x: float = carrier.global_position.x + attack_direction * 4.0
	var target: Vector3 = Vector3(forward_x, PLAYER_Y, preferred_z)
	if absf(carrier.global_position.x) > 13.0:
		target.x = carrier.global_position.x - attack_direction * 1.5
		target.z = preferred_z * 0.72
	_avoid_same_team_target(target)
	_skate_toward(_clamp_to_play_area(target), delta, false)

func _loose_puck(delta: float) -> void:
	var puck_position: Vector3 = _puck_position()
	var my_distance: float = _flat_distance(global_position, puck_position)
	var center_distance: float = INF
	if _ally_center != null:
		center_distance = _flat_distance(_ally_center.global_position, puck_position)
	var partner_distance: float = INF
	if _same_team_winger != null:
		partner_distance = _flat_distance(_same_team_winger.global_position, puck_position)
	if my_distance <= center_distance and my_distance <= partner_distance:
		_skate_toward(puck_position, delta, my_distance > 5.0)
		return
	var preferred_z: float = -4.0 if wing_role == "LEFT" else 4.0
	var own_net_x: float = -attack_direction * GOAL_MOUTH_X
	var shade: Vector3 = Vector3(lerpf(puck_position.x, own_net_x, 0.30), PLAYER_Y, preferred_z)
	_skate_toward(_clamp_to_play_area(shade), delta, false)

func _avoid_same_team_target(target: Vector3) -> void:
	if _same_team_winger == null:
		return
	if _flat_distance(target, _same_team_winger.global_position) < 2.8:
		target.z += -2.5 if wing_role == "LEFT" else 2.5
