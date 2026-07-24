extends Node3D

# Lightweight arcade body separation for skaters/goalies.
# This is intentionally not full physics. It keeps sprites from ghosting through
# each other and injects a small bounce so checks/crowded crease plays feel solid.

@export var separation_radius: float = 1.34
@export var goalie_separation_radius: float = 1.42
@export var separation_strength: float = 0.82
@export var velocity_impulse: float = 4.8
@export var max_position_push: float = 0.46
@export var hard_overlap_threshold: float = 0.42
@export var hard_overlap_hit_force: float = 9.0
@export var behind_net_clearance: float = 0.32

var _bodies: Array[Node3D] = []

func setup(bodies: Array) -> void:
	_bodies.clear()
	for body in bodies:
		if body is Node3D:
			_bodies.append(body)

func _physics_process(delta: float) -> void:
	if _bodies.size() < 2:
		return
	for i: int in range(_bodies.size()):
		var a: Node3D = _bodies[i]
		if a == null or not is_instance_valid(a):
			continue
		for j: int in range(i + 1, _bodies.size()):
			var b: Node3D = _bodies[j]
			if b == null or not is_instance_valid(b):
				continue
			_separate_pair(a, b, delta)

func _separate_pair(a: Node3D, b: Node3D, delta: float) -> void:
	if _is_behind_goalie(a, b) or _is_behind_goalie(b, a):
		return
	var flat_delta: Vector3 = Vector3(b.global_position.x - a.global_position.x, 0.0, b.global_position.z - a.global_position.z)
	var distance: float = flat_delta.length()
	if distance <= 0.001:
		flat_delta = _fallback_normal(a, b)
		distance = 1.0

	var target_radius: float = _pair_radius(a, b)
	if distance >= target_radius:
		return

	var normal: Vector3 = flat_delta / distance
	var overlap: float = target_radius - distance
	var push_amount: float = min(overlap * separation_strength, max_position_push)

	var a_weight: float = _movement_weight(a)
	var b_weight: float = _movement_weight(b)
	var total_weight: float = max(a_weight + b_weight, 0.001)
	var a_push: float = push_amount * (b_weight / total_weight)
	var b_push: float = push_amount * (a_weight / total_weight)

	if a_weight > 0.0:
		a.global_position -= normal * a_push
	if b_weight > 0.0:
		b.global_position += normal * b_push

	_apply_velocity_bump(a, -normal, overlap)
	_apply_velocity_bump(b, normal, overlap)
	if overlap >= hard_overlap_threshold and not (_is_goalie(a) or _is_goalie(b)):
		_apply_soft_check(a, -normal, overlap)
		_apply_soft_check(b, normal, overlap)

func _is_behind_goalie(skater: Node3D, goalie: Node3D) -> bool:
	if _is_goalie(skater) or not _is_goalie(goalie):
		return false
	var goalie_side: float = signf(goalie.global_position.x)
	if goalie_side == 0.0:
		return false
	return skater.global_position.x * goalie_side > goalie.global_position.x * goalie_side + behind_net_clearance

func _fallback_normal(a: Node3D, b: Node3D) -> Vector3:
	var seed: float = float(a.get_instance_id() % 17 - b.get_instance_id() % 13)
	var angle: float = seed * 0.63
	return Vector3(cos(angle), 0.0, sin(angle)).normalized()

func _pair_radius(a: Node3D, b: Node3D) -> float:
	if _is_goalie(a) or _is_goalie(b):
		return goalie_separation_radius
	return separation_radius

func _movement_weight(body: Node3D) -> float:
	return 0.18 if _is_goalie(body) else 1.0

func _is_goalie(body: Node3D) -> bool:
	return body.name.to_lower().contains("goalie")

func _apply_velocity_bump(body: Node3D, direction: Vector3, overlap: float) -> void:
	var raw_velocity: Variant = body.get("_move_velocity")
	if raw_velocity is Vector3:
		var velocity: Vector3 = raw_velocity
		velocity += direction * min(overlap * velocity_impulse, velocity_impulse)
		body.set("_move_velocity", velocity)
		return
	var raw_lateral: Variant = body.get("_lateral_velocity")
	if raw_lateral is float:
		var lateral: float = float(raw_lateral)
		lateral += direction.z * min(overlap * velocity_impulse, velocity_impulse)
		body.set("_lateral_velocity", lateral)

func _apply_soft_check(body: Node3D, direction: Vector3, overlap: float) -> void:
	if not body.has_method("receive_check"):
		return
	var force: float = min(hard_overlap_hit_force + overlap * 5.0, 13.0)
	body.call("receive_check", direction.normalized(), force, direction * force * 0.18, {})
