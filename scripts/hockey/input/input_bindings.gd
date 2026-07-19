extends RefCounted

# Runtime local multiplayer bindings.
# Gamepad: left stick move, RT shoot, LT pass/call, LB switch, A sprint, B check.

const CONTROLLER_OWNER_P1: String = "p1"
const CONTROLLER_OWNER_P2: String = "p2"
static var controller_owner: String = CONTROLLER_OWNER_P2

static func set_controller_owner(owner: String) -> void:
	if owner != CONTROLLER_OWNER_P1 and owner != CONTROLLER_OWNER_P2:
		return
	controller_owner = owner
	ensure_player_actions()

static func get_controller_owner() -> String:
	return controller_owner

static func ensure_player_actions() -> void:
	var pads: Array[int] = Input.get_connected_joypads()
	var primary_pad: int = pads[0] if pads.size() >= 1 else -1
	var secondary_pad: int = pads[1] if pads.size() >= 2 else -1
	_setup_player("p1", KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE, KEY_F, KEY_E, KEY_Q, KEY_TAB)
	_add_mouse_button("p1_shoot", MOUSE_BUTTON_LEFT)
	if primary_pad >= 0 and controller_owner == CONTROLLER_OWNER_P1:
		_add_pad_bindings("p1", primary_pad)
	elif secondary_pad >= 0:
		_add_pad_bindings("p1", secondary_pad)
	_setup_player("p2", KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_M, KEY_SLASH, KEY_COMMA, KEY_PERIOD, KEY_SHIFT)
	if primary_pad >= 0 and controller_owner == CONTROLLER_OWNER_P2:
		_add_pad_bindings("p2", primary_pad)

static func _setup_player(prefix: String, up: Key, down: Key, left: Key, right: Key, sprint: Key, shoot: Key, check: Key, pass_key: Key, switch_key: Key) -> void:
	for suffix: String in ["up", "down", "left", "right", "sprint", "shoot", "check", "pass", "switch"]:
		_reset_action(prefix + "_" + suffix)
	_add_key(prefix + "_up", up)
	_add_key(prefix + "_down", down)
	_add_key(prefix + "_left", left)
	_add_key(prefix + "_right", right)
	_add_key(prefix + "_sprint", sprint)
	_add_key(prefix + "_shoot", shoot)
	_add_key(prefix + "_check", check)
	_add_key(prefix + "_pass", pass_key)
	_add_key(prefix + "_switch", switch_key)

static func _add_pad_bindings(prefix: String, device: int) -> void:
	_add_pad_axis(prefix + "_up", device, JOY_AXIS_LEFT_Y, -1.0)
	_add_pad_axis(prefix + "_down", device, JOY_AXIS_LEFT_Y, 1.0)
	_add_pad_axis(prefix + "_left", device, JOY_AXIS_LEFT_X, -1.0)
	_add_pad_axis(prefix + "_right", device, JOY_AXIS_LEFT_X, 1.0)
	_add_pad_axis(prefix + "_shoot", device, JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_pad_axis(prefix + "_pass", device, JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_pad_button(prefix + "_sprint", device, JOY_BUTTON_A)
	_add_pad_button(prefix + "_check", device, JOY_BUTTON_B)
	_add_pad_button(prefix + "_pass", device, JOY_BUTTON_X)
	_add_pad_button(prefix + "_switch", device, JOY_BUTTON_LEFT_SHOULDER)

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
