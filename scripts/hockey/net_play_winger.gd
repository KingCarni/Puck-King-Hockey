extends "res://scripts/hockey/team_play_winger.gd"

const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")

func _apply_rink_bounds() -> void:
	var previous: Vector3 = global_position - _move_velocity * get_physics_process_delta_time()
	var constrained: Vector3 = RinkGeometry.clamp_to_rink(global_position, 0.55)
	if constrained != global_position:
		var normal: Vector3 = (constrained - global_position).normalized()
		global_position = constrained
		if _move_velocity.dot(normal) < 0.0:
			_move_velocity = _move_velocity.slide(normal) * 0.78
	var collision: Dictionary = RinkGeometry.resolve_net_body(global_position, previous, RinkGeometry.PLAYER_NET_CLEARANCE)
	if bool(collision.get("hit", false)):
		global_position = collision.get("position", global_position)
		var normal: Vector3 = collision.get("normal", Vector3.ZERO)
		if normal.length_squared() > 0.001:
			_move_velocity = _move_velocity.slide(normal) * 0.72

func _clamp_to_play_area(point: Vector3) -> Vector3:
	point = RinkGeometry.clamp_to_rink(point, 0.75)
	var collision: Dictionary = RinkGeometry.resolve_net_body(point, global_position, RinkGeometry.PLAYER_NET_CLEARANCE)
	point = collision.get("position", point)
	point.y = 0.72
	return point

func _attack(delta: float) -> void:
	if _puck == null:
		super._attack(delta)
		return
	var puck_position: Vector3 = (_puck as Node3D).global_position
	var attack_goal_x: float = attack_direction * RinkGeometry.GOAL_LINE_X
	var near_goal: bool = absf(puck_position.x - attack_goal_x) < 4.2
	if near_goal and absf(puck_position.z) > RinkGeometry.GOAL_HALF_WIDTH + 0.4:
		var wrap: Vector3 = RinkGeometry.wrap_target(attack_direction, puck_position.z)
		_skate_toward(wrap, delta, true)
		if global_position.distance_to(wrap) < 1.2 and _shoot_cooldown_timer <= 0.0:
			var aim: Vector3 = Vector3(attack_goal_x, 0.18, clampf(-global_position.z * 0.35, -1.0, 1.0))
			_puck.call("shoot", (aim - global_position).normalized(), _move_velocity, shot_power)
			_shoot_cooldown_timer = shoot_cooldown_seconds
		return
	super._attack(delta)
