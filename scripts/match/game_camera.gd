extends Node

# Broadcast-style camera polish. Everything is subtle and additive:
#  - slight positional lead toward the puck (gameplay stays centered)
#  - gentle zoom-in when play enters an attacking zone
#  - punch zoom + shake on goals, small shake on big hits
#  - slightly tighter framing in overtime
#
# Other systems reach it via the "game_camera" group:
#   get_tree().call_group("game_camera", "add_shake", 0.4)

const LEAD_X_FACTOR: float = 0.16
const LEAD_Z_FACTOR: float = 0.11
const LEAD_X_MAX: float = 2.6
const LEAD_Z_MAX: float = 1.1
const FOLLOW_SMOOTHING: float = 3.2
const ZONE_ZOOM_AMOUNT: float = 2.2
const ZONE_START_X: float = 13.0
const SHAKE_DECAY: float = 3.4
const SHAKE_SCALE: float = 0.55

var _camera: Camera3D = null
var _puck: Node3D = null
var _base_position: Vector3 = Vector3.ZERO
var _base_size: float = 34.0
var _lead_offset: Vector3 = Vector3.ZERO
var _shake_strength: float = 0.0
var _punch: float = 0.0

func setup(camera: Camera3D, puck: Node3D) -> void:
	_camera = camera
	_puck = puck
	_base_position = camera.global_position
	_base_size = camera.size
	add_to_group("game_camera")

func add_shake(strength: float) -> void:
	_shake_strength = minf(_shake_strength + strength, 1.4)

func goal_punch() -> void:
	_punch = 1.0
	add_shake(0.8)

func set_overtime(is_overtime: bool) -> void:
	_base_size = 32.2 if is_overtime else 34.0

func _process(delta: float) -> void:
	if _camera == null or _puck == null or not is_instance_valid(_puck):
		return

	# Lead toward the puck.
	var target_lead: Vector3 = Vector3(
		clampf(_puck.global_position.x * LEAD_X_FACTOR, -LEAD_X_MAX, LEAD_X_MAX),
		0.0,
		clampf(_puck.global_position.z * LEAD_Z_FACTOR, -LEAD_Z_MAX, LEAD_Z_MAX))
	_lead_offset = _lead_offset.lerp(target_lead, clampf(FOLLOW_SMOOTHING * delta, 0.0, 1.0))

	# Zone zoom: tighten when the puck is deep in either end.
	var zone_depth: float = clampf((absf(_puck.global_position.x) - ZONE_START_X) / 6.5, 0.0, 1.0)
	var target_size: float = _base_size - zone_depth * ZONE_ZOOM_AMOUNT

	# Goal punch zoom, decaying.
	_punch = maxf(_punch - delta * 1.4, 0.0)
	target_size -= _punch * 4.5

	_camera.size = lerpf(_camera.size, target_size, clampf(4.0 * delta, 0.0, 1.0))

	# Decaying shake.
	_shake_strength = maxf(_shake_strength - SHAKE_DECAY * delta, 0.0)
	var shake_offset: Vector3 = Vector3.ZERO
	if _shake_strength > 0.01:
		shake_offset = Vector3(
			randf_range(-1.0, 1.0) * _shake_strength * SHAKE_SCALE,
			0.0,
			randf_range(-1.0, 1.0) * _shake_strength * SHAKE_SCALE)

	_camera.global_position = _base_position + _lead_offset + shake_offset
