extends RefCounted

# Shared builder for the top-down sprite visuals that replace the
# placeholder cylinders (see docs/ART_STYLE_GUIDE.md).
#
# Sprites are authored facing image-top. A PlaneMesh maps image-top to
# local -Z, while the controllers' VisualRoot yaw treats +Z as forward,
# so the mesh node is flipped 180° to line the art up with the skating
# direction. State feedback (checking, stun, possession) is done by
# swapping tinted copies of the same textured material.

const SPRITE_SIZE: float = 2.15
const SPRITE_LOCAL_Y: float = -0.52

static func load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func apply_skater_sprite(body_mesh: MeshInstance3D, direction_marker: MeshInstance3D, size: float = SPRITE_SIZE) -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(size, size)
	body_mesh.mesh = plane
	body_mesh.position = Vector3(0.0, SPRITE_LOCAL_Y, 0.0)
	body_mesh.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if direction_marker != null:
		direction_marker.visible = false

static func make_sprite_material(texture: Texture2D, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
