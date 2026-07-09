extends Node3D

# Lightweight arcade body separation for skaters/goalies.
# This is intentionally not full physics. It keeps sprites from ghosting through
# each other and injects a small bounce so checks/crowded crease plays feel solid.

@export var separation_radius: float = 1.08
@export var goalie_separation_radius: float = 1.20
@export var separation_strength: float = 0.42
@export var velocity_impulse: float = 2.8
@export var max_position_push: float = 0.22

var _bodies: Array[Node3D] = []

func setup(bodies: Array[Node3D]) -> void:
	_bodies.clear()
	for body: Node3D in bodies:
		if body != null:
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
	var flat_delta: Vector3 = Vector3(b.global_position.x - a.global_position.x, 0.0, b.global_position.z - a.global_position.z)
	var distance: float = flat_delta.length()
	if distance <= 0.001:
		flat_delta = Vector3.RIGHT
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

func _pair_radius(a: Node3D, b: Node3D) -> float:
	if _is_goalie(a) or _is_goalie(b):
		return goalie_separation_radius
	return separation_radius

func _movement_weight(body: Node3D) -> float:
	# Goalies should block, not get shoved out of the crease.
	return 0.25 if _is_goalie(body) else 1.0

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
