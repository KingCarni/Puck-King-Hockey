extends "res://scripts/hockey/team_play_puck.gd"

const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")

func _physics_process(delta: float) -> void:
	var before: Vector3 = global_position
	super._physics_process(delta)
	if bool(get("_is_possessed")):
		return
	var constrained: Vector3 = RinkGeometry.clamp_to_rink(global_position, 0.10)
	if constrained != global_position:
		var normal: Vector3 = (constrained - global_position).normalized()
		global_position = constrained
		_bounce_from_normal(normal, 0.82)
	var collision: Dictionary = RinkGeometry.resolve_net_body(global_position, before, RinkGeometry.PUCK_NET_CLEARANCE)
	if bool(collision.get("hit", false)):
		global_position = collision.get("position", global_position)
		_bounce_from_normal(collision.get("normal", Vector3.ZERO), 0.88)

func update_possession(target_position: Vector3, owner_velocity: Vector3, delta: float) -> void:
	var previous: Vector3 = global_position
	var safe_target: Vector3 = RinkGeometry.clamp_to_rink(target_position, 0.10)
	var collision: Dictionary = RinkGeometry.resolve_net_body(safe_target, previous, RinkGeometry.PUCK_NET_CLEARANCE)
	if bool(collision.get("hit", false)):
		safe_target = collision.get("position", safe_target)
	super.update_possession(safe_target, owner_velocity, delta)

func _bounce_from_normal(normal: Vector3, restitution: float) -> void:
	if normal.length_squared() < 0.001:
		return
	var raw_velocity: Variant = get("_velocity")
	if not (raw_velocity is Vector3):
		return
	var velocity: Vector3 = raw_velocity
	if velocity.dot(normal) < 0.0:
		velocity = velocity.bounce(normal.normalized()) * restitution
		set("_velocity", velocity)
