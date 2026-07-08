extends Node3D

# Readability layer: who do I control, who has the puck, when did it change hands.
#  - team-colored ring under each human-controlled skater (always on)
#  - gold crown floating over the current puck carrier
#  - quick white ring flash wherever possession is gained

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const RING_TEXTURE_PATH: String = "res://assets/art/effects/pkh_ring_indicator.svg"
const CROWN_TEXTURE_PATH: String = "res://assets/ui/icons/icon_crown.svg"

const RING_Y: float = 0.105
const RING_SIZE: float = 2.55
const CROWN_HEIGHT: float = 2.15
const FLASH_SECONDS: float = 0.26

var _puck: Node = null
var _tracked_players: Array[Node3D] = []
var _rings: Array[MeshInstance3D] = []
var _crown: MeshInstance3D = null
var _flash: MeshInstance3D = null
var _flash_material: StandardMaterial3D = null
var _flash_timer: float = 0.0
var _last_owner: Node3D = null
var _time: float = 0.0

## players: Array of { "node": Node3D, "color": Color }
func setup(puck: Node, players: Array) -> void:
	_puck = puck
	var ring_texture: Texture2D = SkaterSpriteVisuals.load_texture(RING_TEXTURE_PATH)
	var crown_texture: Texture2D = SkaterSpriteVisuals.load_texture(CROWN_TEXTURE_PATH)

	for entry: Dictionary in players:
		var player: Node3D = entry.get("node") as Node3D
		if player == null:
			continue
		_tracked_players.append(player)
		_rings.append(_make_flat_quad("ControlRing", ring_texture, RING_SIZE, Color(entry.get("color", Color.WHITE))))

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

func _process(delta: float) -> void:
	_time += delta
	_update_rings()
	_update_crown_and_flash(delta)

func _update_rings() -> void:
	for index: int in range(_tracked_players.size()):
		var player: Node3D = _tracked_players[index]
		var ring: MeshInstance3D = _rings[index]
		if player == null or not is_instance_valid(player):
			ring.visible = false
			continue
		ring.visible = true
		ring.global_position = Vector3(player.global_position.x, RING_Y, player.global_position.z)

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
		_flash_timer = max(_flash_timer - delta, 0.0)
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
	if not (is_possessed is bool) or not is_possessed:
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
