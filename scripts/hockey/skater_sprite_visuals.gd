extends RefCounted

# Shared builder for the top-down sprite visuals that replace the
# placeholder cylinders (see docs/ART_STYLE_GUIDE.md).
#
# Sprites are authored facing image-top. A PlaneMesh maps image-top to
# local -Z, while the controllers' VisualRoot yaw treats +Z as forward,
# so the mesh node is flipped 180° to line the art up with the skating
# direction. State feedback (checking, stun, possession) is done by
# swapping tinted copies of the same textured material.

const SPRITE_SIZE: float = 2.78
const SPRITE_LOCAL_Y: float = -0.52
const STICK_VISUAL_NAME: String = "StickReadabilityOverlay"

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
	_add_stick_readability_overlay(body_mesh, size)
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

static func _add_stick_readability_overlay(body_mesh: MeshInstance3D, size: float) -> void:
	var existing: Node = body_mesh.get_node_or_null(STICK_VISUAL_NAME)
	if existing != null:
		existing.queue_free()

	var stick_root: Node3D = Node3D.new()
	stick_root.name = STICK_VISUAL_NAME
	stick_root.position = Vector3(0.0, 0.012, -size * 0.29)
	stick_root.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	body_mesh.add_child(stick_root)

	var shaft_material: StandardMaterial3D = _make_unshaded_color_material(Color(0.045, 0.037, 0.030, 0.92))
	var blade_material: StandardMaterial3D = _make_unshaded_color_material(Color(0.010, 0.010, 0.012, 0.96))
	var tape_material: StandardMaterial3D = _make_unshaded_color_material(Color(0.86, 0.82, 0.72, 0.82))

	var shaft: MeshInstance3D = _make_box_mesh("StickShaft", Vector3(size * 0.060, 0.010, size * 0.64), Vector3(size * 0.18, 0.0, -size * 0.10), shaft_material)
	shaft.rotation_degrees = Vector3(0.0, -16.0, 0.0)
	stick_root.add_child(shaft)

	var blade: MeshInstance3D = _make_box_mesh("StickBlade", Vector3(size * 0.25, 0.010, size * 0.070), Vector3(size * 0.31, 0.0, -size * 0.43), blade_material)
	blade.rotation_degrees = Vector3(0.0, -16.0, 0.0)
	stick_root.add_child(blade)

	var tape: MeshInstance3D = _make_box_mesh("StickTape", Vector3(size * 0.16, 0.011, size * 0.045), Vector3(size * 0.37, 0.0, -size * 0.45), tape_material)
	tape.rotation_degrees = Vector3(0.0, -16.0, 0.0)
	stick_root.add_child(tape)

static func _make_box_mesh(mesh_name: String, mesh_size: Vector3, mesh_position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var box: BoxMesh = BoxMesh.new()
	box.size = mesh_size
	mesh_instance.mesh = box
	mesh_instance.position = mesh_position
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

static func _make_unshaded_color_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
