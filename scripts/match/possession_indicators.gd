extends Node3D

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")
const RING_TEXTURE_PATH: String = "res://assets/art/effects/pkh_ring_indicator.svg"
const CROWN_TEXTURE_PATH: String = "res://assets/ui/icons/icon_crown.svg"
const RING_Y: float = 0.105
const RING_SIZE: float = 2.55
const CROWN_HEIGHT: float = 2.15
const FLASH_SECONDS: float = 0.26

var _puck: Node = null
var _controlled_player: Node3D = null
var _control_color: Color = Color(0.18, 0.55, 1.0, 0.90)
var _control_ring: MeshInstance3D = null
var _pass_target: Node3D = null
var _pass_ring: MeshInstance3D = null
var _ack_player: Node3D = null
var _ack_timer: float = 0.0
var _ack_ring: MeshInstance3D = null
var _crown: MeshInstance3D = null
var _flash: MeshInstance3D = null
var _flash_material: StandardMaterial3D = null
var _flash_timer: float = 0.0
var _last_owner: Node3D = null
var _time: float = 0.0

func setup(puck: Node, players: Array) -> void:
	_puck = puck
	var ring_texture: Texture2D = SkaterSpriteVisuals.load_texture(RING_TEXTURE_PATH)
	var crown_texture: Texture2D = SkaterSpriteVisuals.load_texture(CROWN_TEXTURE_PATH)
	_control_ring = _make_flat_quad("ControlRing", ring_texture, RING_SIZE, _control_color)
	_control_ring.visible = false
	_pass_ring = _make_flat_quad("PassTargetRing", ring_texture, RING_SIZE * 0.88, Color(1.0, 0.78, 0.10, 0.88))
	_pass_ring.visible = false
	_ack_ring = _make_flat_quad("CallAckRing", ring_texture, RING_SIZE * 0.72, Color(0.35, 1.0, 0.55, 0.90))
	_ack_ring.visible = false
	if not players.is_empty():
		var first: Dictionary = players[0]
		var first_player: Node3D = first.get("node") as Node3D
		if first_player != null:
			set_controlled_player(first_player)
		_control_color = Color(first.get("color", _control_color))
	if crown_texture != null:
		_crown = MeshInstance3D.new()
		_crown.name = "CarrierCrown"
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(0.92, 0.72)
		_crown.mesh = quad
		var crown_material: StandardMaterial3D = SkaterSpriteVisuals.make_sprite_material(crown_texture)
		crown_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_crown.material_override = crown_material
		_crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_crown.visible = false
		add_child(_crown)
	_flash = _make_flat_quad("PossessionFlash", ring_texture, RING_SIZE, Color.WHITE)
	_flash_material = _flash.material_override as StandardMaterial3D
	_flash.visible = false

func set_controlled_player(player: Node3D) -> void:
	_controlled_player = player

func set_pass_target(player: Node3D) -> void:
	_pass_target = player

func acknowledge_call(player: Node3D) -> void:
	_ack_player = player
	_ack_timer = 0.45

func _process(delta: float) -> void:
	_time += delta
	_update_control_ring()
	_update_pass_ring()
	_update_ack_ring(delta)
	_update_crown_and_flash(delta)

func _update_control_ring() -> void:
	if _control_ring == null:
		return
	if _controlled_player == null or not is_instance_valid(_controlled_player):
		_control_ring.visible = false
		return
	_control_ring.visible = true
	_control_ring.global_position = Vector3(_controlled_player.global_position.x, RING_Y, _controlled_player.global_position.z)

func _update_pass_ring() -> void:
	if _pass_ring == null:
		return
	if _pass_target == null or not is_instance_valid(_pass_target):
		_pass_ring.visible = false
		return
	_pass_ring.visible = true
	var pulse: float = 1.0 + sin(_time * 8.0) * 0.08
	_pass_ring.scale = Vector3(pulse, 1.0, pulse)
	_pass_ring.global_position = Vector3(_pass_target.global_position.x, RING_Y + 0.015, _pass_target.global_position.z)

func _update_ack_ring(delta: float) -> void:
	if _ack_ring == null:
		return
	_ack_timer = maxf(_ack_timer - delta, 0.0)
	if _ack_timer <= 0.0 or _ack_player == null or not is_instance_valid(_ack_player):
		_ack_ring.visible = false
		return
	_ack_ring.visible = true
	_ack_ring.global_position = Vector3(_ack_player.global_position.x, RING_Y + 0.025, _ack_player.global_position.z)
	var progress: float = 1.0 - _ack_timer / 0.45
	var size: float = lerpf(0.65, 1.35, progress)
	_ack_ring.scale = Vector3(size, 1.0, size)

func _update_crown_and_flash(delta: float) -> void:
	var owner: Node3D = _get_puck_owner()
	if _crown != null:
		if owner != null:
			_crown.visible = true
			var bob: float = sin(_time * 5.0) * 0.07
			_crown.global_position = Vector3(owner.global_position.x, CROWN_HEIGHT + bob, owner.global_position.z)
		else:
			_crown.visible = false
	if owner != _last_owner and owner != null and _flash != null:
		_flash_timer = FLASH_SECONDS
		_flash.visible = true
		_flash.global_position = Vector3(owner.global_position.x, RING_Y + 0.01, owner.global_position.z)
	_last_owner = owner
	if _flash_timer > 0.0 and _flash != null:
		_flash_timer = maxf(_flash_timer - delta, 0.0)
		var progress: float = 1.0 - _flash_timer / FLASH_SECONDS
		var flash_scale: float = lerpf(0.55, 1.65, progress)
		_flash.scale = Vector3(flash_scale, 1.0, flash_scale)
		if _flash_material != null:
			_flash_material.albedo_color = Color(1.0, 1.0, 1.0, 0.85 * (1.0 - progress))
		if _flash_timer <= 0.0:
			_flash.visible = false

func _get_puck_owner() -> Node3D:
	if _puck == null:
		return null
	var is_possessed: Variant = _puck.get("_is_possessed")
	if not (is_possessed is bool) or not bool(is_possessed):
		return null
	var owner: Variant = _puck.get("_owner")
	if owner is Node3D and is_instance_valid(owner):
		return owner as Node3D
	return null

func _make_flat_quad(node_name: String, texture: Texture2D, size: float, tint: Color) -> MeshInstance3D:
	var quad: MeshInstance3D = MeshInstance3D.new()
	quad.name = node_name
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(size, size)
	quad.mesh = plane
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if texture != null:
		quad.material_override = SkaterSpriteVisuals.make_sprite_material(texture, tint)
	add_child(quad)
	return quad
