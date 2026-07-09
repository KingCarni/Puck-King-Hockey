extends "res://scripts/hockey/input/input_source.gd"

# Lightweight CPU driver for a center skater body that normally uses
# player_controller.gd. Used when the human switches control to the other side.

var _owner: Node3D = null
var _puck: Node = null
var _attack_direction: float = 1.0
var _shoot_pressed_frames: int = 0
var _shoot_cooldown: int = 0
var _check_cooldown: int = 0
var _sprint_frames: int = 0

func setup(owner: Node3D, puck: Node, attack_direction: float) -> void:
	_owner = owner
	_puck = puck
	_attack_direction = 1.0 if attack_direction >= 0.0 else -1.0

func get_move_vector() -> Vector2:
	_tick_action_timers()
	if _owner == null or _puck == null:
		return Vector2.ZERO

	var target: Vector3 = _get_puck_position()
	_sprint_frames = 0
	if _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", _owner)):
		target = Vector3(17.8 * _attack_direction, _owner.global_position.y, clampf(_owner.global_position.z * 0.25, -2.7, 2.7))
		_prepare_shot_if_ready()
		_sprint_frames = 10 if absf(target.x - _owner.global_position.x) > 7.0 else 0
	else:
		_prepare_check_if_pressuring()
		var puck_distance: float = Vector3(target.x - _owner.global_position.x, 0.0, target.z - _owner.global_position.z).length()
		_sprint_frames = 8 if puck_distance > 8.0 else 0

	var flat_delta: Vector3 = Vector3(target.x - _owner.global_position.x, 0.0, target.z - _owner.global_position.z)
	if flat_delta.length_squared() <= 0.05:
		return Vector2.ZERO
	var direction: Vector3 = flat_delta.normalized()
	return Vector2(direction.x, direction.z) * 0.82

func is_sprint_pressed() -> bool:
	return _sprint_frames > 0

func is_shoot_just_pressed() -> bool:
	return _shoot_pressed_frames == 2

func is_shoot_pressed() -> bool:
	return _shoot_pressed_frames > 0

func is_shoot_just_released() -> bool:
	return _shoot_pressed_frames == 1

func is_check_just_pressed() -> bool:
	if _check_cooldown == 1:
		return true
	return false

func is_pass_just_pressed() -> bool:
	return false

func _tick_action_timers() -> void:
	if _shoot_pressed_frames > 0:
		_shoot_pressed_frames -= 1
	if _shoot_cooldown > 0:
		_shoot_cooldown -= 1
	if _check_cooldown > 0:
		_check_cooldown -= 1
	if _sprint_frames > 0:
		_sprint_frames -= 1

func _prepare_shot_if_ready() -> void:
	if _shoot_cooldown > 0 or _shoot_pressed_frames > 0:
		return
	if absf(_owner.global_position.x) < 10.0:
		return
	var attacking_correct_end: bool = _owner.global_position.x * _attack_direction > 0.0
	if not attacking_correct_end:
		return
	_shoot_pressed_frames = 2
	_shoot_cooldown = 85

func _prepare_check_if_pressuring() -> void:
	if _check_cooldown > 0:
		return
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return
	var distance: float = Vector3(puck_node.global_position.x - _owner.global_position.x, 0.0, puck_node.global_position.z - _owner.global_position.z).length()
	if distance <= 1.65:
		_check_cooldown = 55

func _get_puck_position() -> Vector3:
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return _owner.global_position
	return puck_node.global_position
