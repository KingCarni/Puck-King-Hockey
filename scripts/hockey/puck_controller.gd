extends Node3D

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const PUCK_TEXTURE_PATH: String = "res://assets/art/puck/pkh_puck_topdown.svg"
const RINK_HALF_LENGTH: float = 22.0
const RINK_HALF_WIDTH: float = 10.8
const PUCK_Y: float = 0.18

@export var pickup_radius: float = 1.05
@export var carry_distance: float = 1.05
@export var carry_lag_speed: float = 14.0
@export var loose_friction: float = 3.2
@export var board_bounce: float = 0.80
@export var board_bounce_jitter_degrees: float = 3.5
@export var wrist_shot_speed: float = 17.0
@export var slap_shot_speed: float = 27.0
@export var owner_velocity_inheritance: float = 0.28
@export var max_loose_speed: float = 36.0
@export var hot_shot_speed_threshold: float = 20.0

var magnet_target: Node3D = null
var magnet_radius: float = 2.8
var magnet_pull: float = 16.0

var _velocity: Vector3 = Vector3.ZERO
var _owner: Node3D = null
var _is_possessed: bool = false
var _last_toucher: Node3D = null
var _previous_position: Vector3 = Vector3.ZERO
var _sprite_material: StandardMaterial3D = null
var _hot_glow: MeshInstance3D = null
var _hot_core: OmniLight3D = null
var _is_hot: bool = false

@onready var _puck_mesh: MeshInstance3D = $PuckMesh

func _ready() -> void:
	_build_placeholder_visuals()
	_build_hot_visuals()
	global_position.y = PUCK_Y
	_previous_position = global_position

func _physics_process(delta: float) -> void:
	_update_hot_glow()
	if _is_possessed:
		return
	_previous_position = global_position
	_apply_magnet(delta)
	global_position += _velocity * delta
	global_position.y = PUCK_Y
	_velocity = _velocity.move_toward(Vector3.ZERO, loose_friction * delta)
	_apply_rink_bounds()

func _apply_magnet(delta: float) -> void:
	if magnet_target == null or not is_instance_valid(magnet_target):
		return
	var speed: float = _velocity.length()
	if speed > 15.0:
		return
	var to_target: Vector3 = _flat_position(magnet_target.global_position) - _flat_position(global_position)
	var distance: float = to_target.length()
	if distance > magnet_radius or distance < 0.05:
		return
	var pull_strength: float = magnet_pull * (1.0 - distance / magnet_radius)
	_velocity += to_target.normalized() * pull_strength * delta

func _update_hot_glow() -> void:
	if _sprite_material == null:
		return
	var hot: bool = not _is_possessed and _velocity.length() > hot_shot_speed_threshold
	if hot == _is_hot:
		return
	_is_hot = hot
	if hot:
		_sprite_material.albedo_color = Color(2.6, 0.25, 0.05, 1.0)
		_sprite_material.emission_enabled = true
		_sprite_material.emission = Color(1.0, 0.04, 0.0, 1.0)
		_sprite_material.emission_energy_multiplier = 1.8
	else:
		_sprite_material.albedo_color = Color.WHITE
		_sprite_material.emission_enabled = false
	if _hot_glow != null:
		_hot_glow.visible = hot
	if _hot_core != null:
		_hot_core.visible = hot

func get_last_toucher() -> Node3D:
	return _last_toucher if _last_toucher != null and is_instance_valid(_last_toucher) else null

func get_previous_position() -> Vector3:
	return _previous_position

func get_velocity() -> Vector3:
	return _velocity

func is_possessed() -> bool:
	return _is_possessed

func can_be_picked_up_by(player: Node3D) -> bool:
	if _is_possessed:
		return false
	var flat_delta: Vector3 = _flat_position(global_position) - _flat_position(player.global_position)
	return flat_delta.length() <= pickup_radius

func take_possession(owner: Node3D) -> void:
	_owner = owner
	_last_toucher = owner
	_is_possessed = true
	_velocity = Vector3.ZERO

func is_possessed_by(owner: Node3D) -> bool:
	return _is_possessed and _owner == owner

func update_possession(target_position: Vector3, owner_velocity: Vector3, delta: float) -> void:
	if not _is_possessed:
		return
	_previous_position = global_position
	var target: Vector3 = target_position
	target.y = PUCK_Y
	var lerp_weight: float = clamp(carry_lag_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target, lerp_weight)
	global_position.y = PUCK_Y
	_velocity = Vector3(owner_velocity.x, 0.0, owner_velocity.z)

func shoot(direction: Vector3, owner_velocity: Vector3, shot_power: float = 0.0, speed_scale: float = 1.0) -> void:
	var shot_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if shot_direction.length_squared() <= 0.001:
		shot_direction = Vector3.FORWARD
	if _owner != null:
		_last_toucher = _owner
	var normalized_direction: Vector3 = shot_direction.normalized()
	var clamped_power: float = clamp(shot_power, 0.0, 1.0)
	var shot_speed: float = lerp(wrist_shot_speed, slap_shot_speed, clamped_power) * maxf(speed_scale, 0.1)
	var owner_influence: Vector3 = Vector3(owner_velocity.x, 0.0, owner_velocity.z) * owner_velocity_inheritance
	_previous_position = global_position
	_is_possessed = false
	_owner = null
	_velocity = normalized_direction * shot_speed + owner_influence
	_velocity = _velocity.limit_length(max_loose_speed)
	global_position += normalized_direction * 0.52
	global_position.y = PUCK_Y

func poke_free(direction: Vector3, force: float) -> void:
	var release_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if release_direction.length_squared() <= 0.001:
		release_direction = Vector3.FORWARD
	_previous_position = global_position
	_is_possessed = false
	_owner = null
	_velocity = release_direction.normalized() * force
	_velocity = _velocity.limit_length(max_loose_speed)

func _apply_rink_bounds() -> void:
	var clamped_x: float = clamp(global_position.x, -RINK_HALF_LENGTH, RINK_HALF_LENGTH)
	var clamped_z: float = clamp(global_position.z, -RINK_HALF_WIDTH, RINK_HALF_WIDTH)
	var hit_horizontal_board: bool = not is_equal_approx(clamped_x, global_position.x)
	var hit_vertical_board: bool = not is_equal_approx(clamped_z, global_position.z)
	if hit_horizontal_board:
		global_position.x = clamped_x
		_velocity.x = -_velocity.x * board_bounce
		_jitter_bounce()
	if hit_vertical_board:
		global_position.z = clamped_z
		_velocity.z = -_velocity.z * board_bounce
		_jitter_bounce()

func _jitter_bounce() -> void:
	if _velocity.length_squared() < 4.0:
		return
	_velocity = _velocity.rotated(Vector3.UP, deg_to_rad(randf_range(-board_bounce_jitter_degrees, board_bounce_jitter_degrees)))

func _flat_position(position: Vector3) -> Vector3:
	return Vector3(position.x, 0.0, position.z)

func _build_placeholder_visuals() -> void:
	var puck_texture: Texture2D = SkaterSpriteVisuals.load_texture(PUCK_TEXTURE_PATH)
	if puck_texture != null:
		var shadow: MeshInstance3D = MeshInstance3D.new()
		shadow.name = "PuckReadabilityShadow"
		var shadow_plane: PlaneMesh = PlaneMesh.new()
		shadow_plane.size = Vector2(1.03, 1.03)
		shadow.mesh = shadow_plane
		shadow.position = Vector3(0.07, -0.018, 0.07)
		shadow.material_override = _make_puck_shadow_material()
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(shadow)
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(1.02, 1.02)
		_puck_mesh.mesh = plane
		_puck_mesh.position = Vector3(0.0, 0.03, 0.0)
		_puck_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_sprite_material = SkaterSpriteVisuals.make_sprite_material(puck_texture)
		_puck_mesh.material_override = _sprite_material
		return
	var puck_material: StandardMaterial3D = StandardMaterial3D.new()
	puck_material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)
	puck_material.roughness = 0.28
	_puck_mesh.material_override = puck_material

func _build_hot_visuals() -> void:
	_hot_glow = MeshInstance3D.new()
	_hot_glow.name = "RocketShotRedGlow"
	var glow_plane: PlaneMesh = PlaneMesh.new()
	glow_plane.size = Vector2(1.75, 1.75)
	_hot_glow.mesh = glow_plane
	_hot_glow.position = Vector3(0.0, 0.018, 0.0)
	_hot_glow.material_override = _make_hot_glow_material()
	_hot_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hot_glow.visible = false
	add_child(_hot_glow)
	_hot_core = OmniLight3D.new()
	_hot_core.name = "RocketShotRedLight"
	_hot_core.light_color = Color(1.0, 0.05, 0.0, 1.0)
	_hot_core.light_energy = 1.2
	_hot_core.omni_range = 3.6
	_hot_core.position = Vector3(0.0, 0.75, 0.0)
	_hot_core.visible = false
	add_child(_hot_core)

func _make_hot_glow_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.02, 0.0, 0.55)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.02, 0.0, 1.0)
	material.emission_energy_multiplier = 2.2
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_puck_shadow_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.0, 0.0, 0.30)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
