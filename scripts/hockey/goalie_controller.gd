extends Node3D

# Crease goalie 2.0: idle → track → slide → save → recover.
#  - difficulty scales reaction time and lateral speed
#  - sliding fast opens the five-hole (smaller effective block radius)
#  - rebound control: hard shots kicked to the corner, soft close pucks
#    are covered, then frozen (whistle → faceoff via the puck_frozen signal)
#  - butterfly squash pulse on every save

signal puck_frozen

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const PLAYER_Y: float = 0.72

@export var puck_path: NodePath = NodePath("../Puck")
## -1.0 guards the left (-X) goal, +1.0 guards the right (+X) goal.
@export var guard_side: float = -1.0
@export var guard_distance_from_center: float = 20.0
@export var crease_half_width: float = 2.30
@export var crease_depth: float = 0.95
@export var lateral_max_speed: float = 6.8
@export var lateral_acceleration: float = 28.0
@export var friction: float = 9.0
@export var block_radius: float = 1.28
@export var crash_poke_radius: float = 1.65
@export var save_deflect_speed: float = 10.8
@export var crash_clear_speed: float = 14.0
@export var save_cooldown_seconds: float = 0.36
@export var save_flash_seconds: float = 0.30
## 0 = beer league, 1 = brick wall. Scales reaction time and lateral speed.
@export var difficulty: float = 0.65
@export var cover_radius: float = 0.95
@export var cover_speed_threshold: float = 8.0
@export var freeze_after_seconds: float = 0.85
@export var goalie_texture_path: String = "res://assets/art/characters/pkh_goalie_home.svg"

var saves_made: int = 0

var _puck: Node = null
var _lateral_velocity: float = 0.0
var _save_cooldown_timer: float = 0.0
var _save_flash_timer: float = 0.0
var _reaction_timer: float = 0.0
var _shot_was_incoming: bool = false
var _cover_timer: float = 0.0
var _is_covering: bool = false
var _base_material: StandardMaterial3D = null
var _save_material: StandardMaterial3D = null

@onready var _visual_root: Node3D = $VisualRoot
@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh

func _ready() -> void:
	_build_visuals()
	_puck = get_node_or_null(puck_path)
	reset_to_center()

func _physics_process(delta: float) -> void:
	_save_cooldown_timer = max(_save_cooldown_timer - delta, 0.0)
	_save_flash_timer = max(_save_flash_timer - delta, 0.0)
	_reaction_timer = max(_reaction_timer - delta, 0.0)
	if _is_covering:
		_update_cover(delta)
		_update_visuals(delta)
		return
	_update_positioning(delta)
	_update_block()
	_update_visuals(delta)

func reset_to_center() -> void:
	global_position = Vector3(_guard_x(), PLAYER_Y, 0.0)
	_lateral_velocity = 0.0
	_save_cooldown_timer = 0.0
	_save_flash_timer = 0.0
	_reaction_timer = 0.0
	_shot_was_incoming = false
	_cover_timer = 0.0
	_is_covering = false

func _guard_x() -> float:
	return guard_side * guard_distance_from_center

func _update_positioning(delta: float) -> void:
	var target_z: float = _pick_target_z()
	var delta_z: float = target_z - global_position.z

	var effective_max_speed: float = lateral_max_speed * lerpf(0.82, 1.12, clampf(difficulty, 0.0, 1.0))
	if abs(delta_z) > 0.06:
		_lateral_velocity += signf(delta_z) * lateral_acceleration * delta
		_lateral_velocity = clampf(_lateral_velocity, -effective_max_speed, effective_max_speed)
	else:
		_lateral_velocity = move_toward(_lateral_velocity, 0.0, friction * delta)

	global_position.z = clampf(global_position.z + _lateral_velocity * delta, -crease_half_width, crease_half_width)
	global_position.x = lerpf(global_position.x, _guard_x(), clampf(6.0 * delta, 0.0, 1.0))
	global_position.x = clampf(global_position.x, _guard_x() - crease_depth, _guard_x() + crease_depth)
	global_position.y = PLAYER_Y

func _pick_target_z() -> float:
	if _puck == null:
		return 0.0
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return 0.0

	var puck_position: Vector3 = puck_node.global_position
	var puck_velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = _puck.get("_velocity")
	if raw_velocity is Vector3:
		puck_velocity = raw_velocity

	var toward_goal: bool = puck_velocity.x * guard_side > 2.0

	# Reaction time: the goalie needs a beat to read a fresh shot. Lower
	# difficulty = longer beat = more goals on quick releases.
	if toward_goal and not _shot_was_incoming:
		_reaction_timer = lerpf(0.30, 0.05, clampf(difficulty, 0.0, 1.0))
	_shot_was_incoming = toward_goal

	if toward_goal and absf(puck_velocity.x) > 0.5 and _reaction_timer <= 0.0:
		var time_to_line: float = (_guard_x() - puck_position.x) / puck_velocity.x
		if time_to_line > 0.0 and time_to_line < 1.4:
			return clampf(puck_position.z + puck_velocity.z * time_to_line, -crease_half_width, crease_half_width)

	return clampf(puck_position.z + puck_velocity.z * 0.10, -crease_half_width, crease_half_width)

func _update_block() -> void:
	if _puck == null or _save_cooldown_timer > 0.0:
		return
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return

	var flat_delta: Vector3 = puck_node.global_position - global_position
	flat_delta.y = 0.0
	var distance: float = flat_delta.length()

	# Five-hole: sliding hard across the crease shrinks coverage.
	var sliding_fast: bool = absf(_lateral_velocity) > lateral_max_speed * 0.72
	var effective_poke_radius: float = crash_poke_radius * (0.62 if sliding_fast else 1.0)
	var effective_block_radius: float = block_radius * (0.62 if sliding_fast else 1.0)
	if distance > effective_poke_radius:
		return

	var puck_speed: float = 0.0
	var raw_velocity: Variant = _puck.get("_velocity")
	if raw_velocity is Vector3:
		puck_speed = Vector3(raw_velocity.x, 0.0, raw_velocity.z).length()
	var puck_loose: bool = not bool(_puck.get("_is_possessed"))

	# Rebound control: soft loose pucks in tight get covered and frozen.
	if puck_loose and puck_speed < cover_speed_threshold and distance <= cover_radius:
		_start_cover()
		return

	var clear_speed: float = save_deflect_speed if distance > effective_block_radius else crash_clear_speed
	var clear_direction: Vector3 = _get_clear_direction(puck_node.global_position)
	if _puck.has_method("poke_free"):
		_puck.call("poke_free", clear_direction, clear_speed)
	_register_save()
	global_position.x += guard_side * 0.12

func _register_save() -> void:
	saves_made += 1
	_save_cooldown_timer = save_cooldown_seconds
	_save_flash_timer = save_flash_seconds
	_butterfly_pulse()
	SfxPlayer.play(SfxPlayer.ID_SAVE_THUMP, randf_range(0.9, 1.1))

# Quick pad-stack squash so saves read as a butterfly drop.
func _butterfly_pulse() -> void:
	if _body_mesh == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_body_mesh, "scale", Vector3(1.30, 1.0, 0.74), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body_mesh, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_cover() -> void:
	_is_covering = true
	_cover_timer = freeze_after_seconds
	_register_save()
	if _puck != null and _puck.has_method("take_possession"):
		_puck.call("take_possession", self)

func _update_cover(delta: float) -> void:
	_cover_timer -= delta
	# Tuck the puck under the body while covered.
	if _puck != null and _puck.has_method("update_possession"):
		_puck.call("update_possession", global_position + Vector3(-guard_side * 0.35, 0.0, 0.0), Vector3.ZERO, delta)
	if _cover_timer <= 0.0:
		_is_covering = false
		puck_frozen.emit()

func _get_clear_direction(puck_position: Vector3) -> Vector3:
	# Always clear away from the net mouth and toward a corner. This prevents
	# players from shoving the goalie/puck straight through the goal line.
	var corner_z: float = signf(puck_position.z) if absf(puck_position.z) > 0.18 else (1.0 if randf() > 0.5 else -1.0)
	return Vector3(-guard_side * 1.35, 0.0, corner_z * 0.80).normalized()

func _update_visuals(delta: float) -> void:
	if _visual_root == null:
		return
	var facing: Vector3 = Vector3(-guard_side, 0.0, 0.0)
	if _puck != null:
		var puck_node: Node3D = _puck as Node3D
		if puck_node != null:
			var to_puck: Vector3 = puck_node.global_position - global_position
			to_puck.y = 0.0
			if to_puck.length_squared() > 0.04:
				facing = to_puck.normalized().lerp(Vector3(-guard_side, 0.0, 0.0), 0.45).normalized()
	var target_yaw: float = atan2(facing.x, facing.z)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, clampf(7.0 * delta, 0.0, 1.0))

	if _body_mesh == null or _base_material == null:
		return
	_body_mesh.material_override = _save_material if _save_flash_timer > 0.0 else _base_material

func _build_visuals() -> void:
	var texture: Texture2D = SkaterSpriteVisuals.load_texture(goalie_texture_path)
	if texture != null:
		SkaterSpriteVisuals.apply_skater_sprite(_body_mesh, null, SkaterSpriteVisuals.SPRITE_SIZE * 1.12)
		_base_material = SkaterSpriteVisuals.make_sprite_material(texture)
		_save_material = SkaterSpriteVisuals.make_sprite_material(texture, Color(1.55, 1.60, 1.85, 1.0))
		_body_mesh.material_override = _base_material
		return

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.90, 0.92, 0.95, 1.0)
	_save_material = _base_material
	_body_mesh.material_override = _base_material
