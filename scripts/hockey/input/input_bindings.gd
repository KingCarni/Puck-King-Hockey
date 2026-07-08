extends RefCounted

# Registers per-player InputMap actions at runtime so local multiplayer
# needs no project.godot edits and stays configurable later.
#
# Player 1: WASD, Space sprint, F / left mouse shoot, Q pass, E check.
#           Gets the second gamepad if two are connected.
# Player 2: first connected gamepad; keyboard fallback is always bound:
#           arrows, M sprint, / shoot, . pass, , check.
#
# Gamepad layout (both players): left stick move, RT shoot, A sprint,
# B check, X pass.

static func ensure_player_actions() -> void:
	var pads: Array[int] = Input.get_connected_joypads()

	# --- Player 1: keyboard (+ pad #2 when present) ---
	_reset_action("p1_up")
	_reset_action("p1_down")
	_reset_action("p1_left")
	_reset_action("p1_right")
	_reset_action("p1_sprint")
	_reset_action("p1_shoot")
	_reset_action("p1_check")
	_reset_action("p1_pass")
	_add_key("p1_up", KEY_W)
	_add_key("p1_down", KEY_S)
	_add_key("p1_left", KEY_A)
	_add_key("p1_right", KEY_D)
	_add_key("p1_sprint", KEY_SPACE)
	_add_key("p1_shoot", KEY_F)
	_add_mouse_button("p1_shoot", MOUSE_BUTTON_LEFT)
	_add_key("p1_check", KEY_E)
	_add_key("p1_pass", KEY_Q)
	if pads.size() >= 2:
		_add_pad_bindings("p1", pads[1])

	# --- Player 2: first gamepad, keyboard arrows as fallback ---
	_reset_action("p2_up")
	_reset_action("p2_down")
	_reset_action("p2_left")
	_reset_action("p2_right")
	_reset_action("p2_sprint")
	_reset_action("p2_shoot")
	_reset_action("p2_check")
	_reset_action("p2_pass")
	_add_key("p2_up", KEY_UP)
	_add_key("p2_down", KEY_DOWN)
	_add_key("p2_left", KEY_LEFT)
	_add_key("p2_right", KEY_RIGHT)
	_add_key("p2_sprint", KEY_M)
	_add_key("p2_shoot", KEY_SLASH)
	_add_key("p2_pass", KEY_PERIOD)
	_add_key("p2_check", KEY_COMMA)
	if pads.size() >= 1:
		_add_pad_bindings("p2", pads[0])

static func _add_pad_bindings(prefix: String, device: int) -> void:
	_add_pad_axis(prefix + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
	_add_pad_axis(prefix + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
	_add_pad_axis(prefix + "_left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_pad_axis(prefix + "_right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_pad_axis(prefix + "_shoot", device, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_pad_button(prefix + "_sprint", device, JOY_BUTTON_A)
	_add_pad_button(prefix + "_check", device, JOY_BUTTON_B)
	_add_pad_button(prefix + "_pass", device, JOY_BUTTON_X)

static func _reset_action(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.32)

static func _add_key(action: String, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	InputMap.action_add_event(action, event)

static func _add_mouse_button(action: String, button_index: MouseButton) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)

static func _add_pad_button(action: String, device: int, button_index: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = device
	event.button_index = button_index
	InputMap.action_add_event(action, event)

static func _add_pad_axis(action: String, device: int, axis: JoyAxis, axis_value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
