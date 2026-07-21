extends "res://scripts/hockey/player_controller_3v3.gd"

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
