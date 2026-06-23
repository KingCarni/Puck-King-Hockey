extends "res://scripts/hockey/test_rink.gd"

const ICE_TEXTURE_WEBP_PATH: String = "res://assets/art/rink/pkh_ice_surface.webp"
const ICE_TEXTURE_PNG_PATH: String = "res://assets/art/rink/pkh_ice_surface.png"

func _create_ice_surface() -> void:
	var ice: MeshInstance3D = _create_box("IceSurface", Vector3(RINK_LENGTH, ICE_THICKNESS, RINK_WIDTH), Vector3.ZERO)
	var material: StandardMaterial3D = _make_ice_surface_material()
	ice.material_override = material
	world.add_child(ice)

func _create_ice_surface_details() -> void:
	if _has_ice_texture():
		_create_subtle_ice_edge_glow()
		return

	# Keep the procedural detail pass as a fallback when no external asset exists.
	_create_ice_under_panels()
	_create_center_ice_badge()
	_create_ice_scratch_marks()
	_create_ice_edge_glow()

func _make_ice_surface_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.98, 1.0, 1.0)
	material.metallic = 0.0
	material.roughness = 0.28
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.uv1_scale = Vector3(1.0, 1.0, 1.0)

	var texture: Texture2D = _load_ice_texture()
	if texture != null:
		material.albedo_texture = texture
		material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		material.roughness = 0.20
	return material

func _has_ice_texture() -> bool:
	return ResourceLoader.exists(ICE_TEXTURE_WEBP_PATH) or ResourceLoader.exists(ICE_TEXTURE_PNG_PATH)

func _load_ice_texture() -> Texture2D:
	if ResourceLoader.exists(ICE_TEXTURE_WEBP_PATH):
		return load(ICE_TEXTURE_WEBP_PATH) as Texture2D
	if ResourceLoader.exists(ICE_TEXTURE_PNG_PATH):
		return load(ICE_TEXTURE_PNG_PATH) as Texture2D
	return null

func _create_subtle_ice_edge_glow() -> void:
	var edge_material: StandardMaterial3D = _make_material(Color(0.55, 0.90, 1.0, 0.10), 0.0, 0.36)
	_create_flat_line("TopIceTextureGlow", Vector3(RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, LINE_HEIGHT - 0.012, -RINK_WIDTH * 0.5 + 0.45), Color(0.55, 0.90, 1.0, 0.10), edge_material)
	_create_flat_line("BottomIceTextureGlow", Vector3(RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, LINE_HEIGHT - 0.012, RINK_WIDTH * 0.5 - 0.45), Color(0.55, 0.90, 1.0, 0.10), edge_material)
	_create_flat_line("LeftIceTextureGlow", Vector3(0.16, 0.012, RINK_WIDTH - 1.0), Vector3(-RINK_LENGTH * 0.5 + 0.45, LINE_HEIGHT - 0.012, 0.0), Color(0.55, 0.90, 1.0, 0.10), edge_material)
	_create_flat_line("RightIceTextureGlow", Vector3(0.16, 0.012, RINK_WIDTH - 1.0), Vector3(RINK_LENGTH * 0.5 - 0.45, LINE_HEIGHT - 0.012, 0.0), Color(0.55, 0.90, 1.0, 0.10), edge_material)
