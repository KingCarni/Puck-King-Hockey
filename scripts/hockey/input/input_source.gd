extends RefCounted

# Abstract input source for a skater body.
#
# player_controller.gd polls one of these every physics frame, so the
# body never knows where its commands come from. Implementations:
#   - human_input_source.gd (local keyboard / gamepad via InputMap)
#   - AIInputSource (future: drive a skater body with the AI brain)
#   - NetworkInputSource (future: remote players)

func get_move_vector() -> Vector2:
	return Vector2.ZERO

func is_sprint_pressed() -> bool:
	return false

func is_shoot_just_pressed() -> bool:
	return false

func is_shoot_pressed() -> bool:
	return false

func is_shoot_just_released() -> bool:
	return false

func is_check_just_pressed() -> bool:
	return false

func is_pass_just_pressed() -> bool:
	return false
