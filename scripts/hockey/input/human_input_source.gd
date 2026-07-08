extends "res://scripts/hockey/input/input_source.gd"

# Local-device input source. Reads per-player InputMap actions registered
# by input_bindings.gd ("p1_up", "p2_shoot", ...).

var _prefix: String = "p1"

func _init(prefix: String) -> void:
	_prefix = prefix

func get_move_vector() -> Vector2:
	return Input.get_vector(_prefix + "_left", _prefix + "_right", _prefix + "_up", _prefix + "_down")

func is_sprint_pressed() -> bool:
	return Input.is_action_pressed(_prefix + "_sprint")

func is_shoot_just_pressed() -> bool:
	return Input.is_action_just_pressed(_prefix + "_shoot")

func is_shoot_pressed() -> bool:
	return Input.is_action_pressed(_prefix + "_shoot")

func is_shoot_just_released() -> bool:
	return Input.is_action_just_released(_prefix + "_shoot")

func is_check_just_pressed() -> bool:
	return Input.is_action_just_pressed(_prefix + "_check")

func is_pass_just_pressed() -> bool:
	return Input.is_action_just_pressed(_prefix + "_pass")
