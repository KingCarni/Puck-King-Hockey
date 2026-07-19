extends "res://scripts/hockey/puck_controller.gd"

signal possession_changed(owner: Node3D)

@export var release_pickup_lock: float = 0.16
@export var receiver_priority_seconds: float = 0.42
@export var facing_bonus: float = 0.35

var _blocked_player: Node3D = null
var _pickup_lock_timer: float = 0.0
var _priority_receiver: Node3D = null
var _priority_timer: float = 0.0
var _claimed_frame: int = -1

func _physics_process(delta: float) -> void:
	_pickup_lock_timer = maxf(_pickup_lock_timer - delta, 0.0)
	_priority_timer = maxf(_priority_timer - delta, 0.0)
	if _priority_timer <= 0.0:
		_priority_receiver = null
	super._physics_process(delta)

func get_owner() -> Node3D:
	var owner: Variant = get("_owner")
	if owner is Node3D:
		return owner as Node3D
	return null

func set_receiver_priority(receiver: Node3D, passer: Node3D, duration: float = 0.42) -> void:
	_priority_receiver = receiver
	_priority_timer = maxf(duration, receiver_priority_seconds)
	_blocked_player = passer
	_pickup_lock_timer = release_pickup_lock

func can_be_picked_up_by(player: Node3D) -> bool:
	if bool(get("_is_possessed")):
		return false
	if player == null:
		return false
	if _pickup_lock_timer > 0.0 and player == _blocked_player:
		return false
	if _priority_receiver != null and _priority_timer > 0.0:
		return player == _priority_receiver and _within_pickup_radius(player)
	return player == _best_pickup_candidate()

func take_possession(owner: Node3D) -> void:
	var frame: int = Engine.get_physics_frames()
	if _claimed_frame == frame:
		return
	if not can_be_picked_up_by(owner):
		return
	_claimed_frame = frame
	_priority_receiver = null
	_priority_timer = 0.0
	_blocked_player = null
	_pickup_lock_timer = 0.0
	super.take_possession(owner)
	emit_signal("possession_changed", owner)

func shoot(direction: Vector3, owner_velocity: Vector3, shot_power: float = 0.0, speed_scale: float = 1.0) -> void:
	var previous_owner: Node3D = get_owner()
	super.shoot(direction, owner_velocity, shot_power, speed_scale)
	_blocked_player = previous_owner
	_pickup_lock_timer = release_pickup_lock
	emit_signal("possession_changed", null)

func poke_free(direction: Vector3, force: float) -> void:
	var previous_owner: Node3D = get_owner()
	super.poke_free(direction, force)
	_blocked_player = previous_owner
	_pickup_lock_timer = release_pickup_lock * 0.75
	_priority_receiver = null
	_priority_timer = 0.0
	emit_signal("possession_changed", null)

func _best_pickup_candidate() -> Node3D:
	var best: Node3D = null
	var best_score: float = INF
	for node: Node in get_tree().get_nodes_in_group("checkable"):
		var candidate: Node3D = node as Node3D
		if candidate == null or not _within_pickup_radius(candidate):
			continue
		if _pickup_lock_timer > 0.0 and candidate == _blocked_player:
			continue
		var distance: float = Vector3(candidate.global_position.x - global_position.x, 0.0, candidate.global_position.z - global_position.z).length()
		var score: float = distance
		var raw_facing: Variant = candidate.get("_last_facing_direction")
		if raw_facing is Vector3:
			var facing: Vector3 = raw_facing
			var to_puck: Vector3 = Vector3(global_position.x - candidate.global_position.x, 0.0, global_position.z - candidate.global_position.z)
			if to_puck.length_squared() > 0.001:
				score -= maxf(0.0, facing.normalized().dot(to_puck.normalized())) * facing_bonus
		if score < best_score:
			best_score = score
			best = candidate
	return best

func _within_pickup_radius(player: Node3D) -> bool:
	var delta: Vector3 = Vector3(global_position.x - player.global_position.x, 0.0, global_position.z - player.global_position.z)
	return delta.length() <= pickup_radius
