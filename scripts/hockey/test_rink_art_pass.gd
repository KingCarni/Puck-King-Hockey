extends "res://scripts/hockey/test_rink.gd"

const ICE_TEXTURE_WEBP_PATH: String = "res://assets/art/rink/pkh_ice_surface.webp"
const ICE_TEXTURE_PNG_PATH: String = "res://assets/art/rink/pkh_ice_surface.png"
const ICE_TEXTURE_Y: float = 0.082

const VISUAL_BOARD_Y: float = 0.42
const VISUAL_GLASS_Y: float = 1.18
const VISUAL_POST_Y: float = 1.08

func _create_ice_surface() -> void:
	var base_ice: MeshInstance3D = _create_box("IceSurfaceBase", Vector3(RINK_LENGTH, ICE_THICKNESS, RINK_WIDTH), Vector3.ZERO)
	base_ice.material_override = _make_material(Color(0.86, 0.97, 1.0, 1.0), 0.0, 0.24)
	world.add_child(base_ice)

	var texture: Texture2D = _load_ice_texture()
	if texture == null:
		return

	var ice_quad: MeshInstance3D = MeshInstance3D.new()
	ice_quad.name = "IceSurfaceTextureQuad"

	# QuadMesh gives us predictable UVs. Rotate it flat onto the rink so the full image
	# maps once across the ice instead of relying on BoxMesh face UVs.
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(RINK_LENGTH, RINK_WIDTH)
	ice_quad.mesh = quad
	ice_quad.position = Vector3(0.0, ICE_TEXTURE_Y, 0.0)
	ice_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	ice_quad.material_override = _make_ice_texture_plane_material(texture)
	world.add_child(ice_quad)

func _create_ice_surface_details() -> void:
	if _has_ice_texture():
		_create_subtle_ice_edge_glow()
		return

	# Keep the procedural detail pass as a fallback when no external asset exists.
	_create_ice_under_panels()
	_create_center_ice_badge()
	_create_ice_scratch_marks()
	_create_ice_edge_glow()

func _create_zone_tints() -> void:
	if _has_ice_texture():
		return
	super._create_zone_tints()

func _create_rink_lines() -> void:
	if _has_ice_texture():
		return
	super._create_rink_lines()

func _create_faceoff_markings() -> void:
	if _has_ice_texture():
		return
	super._create_faceoff_markings()

func _create_boards() -> void:
	# Keep invisible-ish physical board blocks in the same position as the base rink so puck collisions remain unchanged.
	var collision_board_material: StandardMaterial3D = _make_material(Color(0.18, 0.20, 0.20, 0.18), 0.0, 0.80)
	var top_collision: MeshInstance3D = _create_box("TopBoardsCollisionVisual", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, -RINK_WIDTH * 0.5))
	var bottom_collision: MeshInstance3D = _create_box("BottomBoardsCollisionVisual", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, RINK_WIDTH * 0.5))
	var left_collision: MeshInstance3D = _create_box("LeftBoardsCollisionVisual", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(-RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var right_collision: MeshInstance3D = _create_box("RightBoardsCollisionVisual", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var collision_boards: Array[MeshInstance3D] = [top_collision, bottom_collision, left_collision, right_collision]
	for board: MeshInstance3D in collision_boards:
		board.material_override = collision_board_material
		world.add_child(board)

	_create_arcade_board_run("TopVisualBoards", true, -RINK_WIDTH * 0.5 - 0.30, false)
	_create_arcade_board_run("BottomVisualBoards", true, RINK_WIDTH * 0.5 + 0.30, true)
	_create_arcade_board_run("LeftVisualBoards", false, -RINK_LENGTH * 0.5 - 0.30, false)
	_create_arcade_board_run("RightVisualBoards", false, RINK_LENGTH * 0.5 + 0.30, true)
	_create_board_corner_caps()

func _create_glass_posts() -> void:
	_create_arcade_glass_run("TopGlass", true, -RINK_WIDTH * 0.5 - 0.42, false)
	_create_arcade_glass_run("BottomGlass", true, RINK_WIDTH * 0.5 + 0.42, true)
	_create_arcade_glass_run("LeftGlass", false, -RINK_LENGTH * 0.5 - 0.42, false)
	_create_arcade_glass_run("RightGlass", false, RINK_LENGTH * 0.5 + 0.42, true)

func _create_arcade_board_run(node_prefix: String, is_horizontal: bool, fixed_position: float, flip_trim: bool) -> void:
	var white_material: StandardMaterial3D = _make_material(Color(0.94, 0.96, 0.96, 1.0), 0.0, 0.28)
	var black_material: StandardMaterial3D = _make_material(Color(0.02, 0.025, 0.03, 1.0), 0.0, 0.55)
	var red_material: StandardMaterial3D = _make_material(Color(0.95, 0.06, 0.08, 1.0), 0.0, 0.34)
	var blue_material: StandardMaterial3D = _make_material(Color(0.08, 0.28, 0.95, 1.0), 0.0, 0.34)
	var shadow_material: StandardMaterial3D = _make_material(Color(0.0, 0.0, 0.0, 0.36), 0.0, 0.70)

	var length: float = RINK_LENGTH + 0.80 if is_horizontal else RINK_WIDTH + 0.80
	var panel_count: int = 8 if is_horizontal else 4
	var panel_length: float = length / float(panel_count)
	var start: float = -length * 0.5 + panel_length * 0.5

	for index: int in range(panel_count):
		var along: float = start + float(index) * panel_length
		var is_red_side: bool = index < panel_count / 2
		var accent_material: StandardMaterial3D = red_material if is_red_side != flip_trim else blue_material
		var base_name: String = "%sPanel%02d" % [node_prefix, index]

		var white_size: Vector3 = Vector3(panel_length - 0.10, 0.42, 0.20) if is_horizontal else Vector3(0.20, 0.42, panel_length - 0.10)
		var kick_size: Vector3 = Vector3(panel_length - 0.06, 0.13, 0.24) if is_horizontal else Vector3(0.24, 0.13, panel_length - 0.06)
		var trim_size: Vector3 = Vector3(panel_length - 0.08, 0.08, 0.25) if is_horizontal else Vector3(0.25, 0.08, panel_length - 0.08)
		var shadow_size: Vector3 = Vector3(panel_length - 0.04, 0.06, 0.30) if is_horizontal else Vector3(0.30, 0.06, panel_length - 0.04)

		var white_position: Vector3 = Vector3(along, VISUAL_BOARD_Y + 0.14, fixed_position) if is_horizontal else Vector3(fixed_position, VISUAL_BOARD_Y + 0.14, along)
		var kick_position: Vector3 = Vector3(along, 0.16, fixed_position) if is_horizontal else Vector3(fixed_position, 0.16, along)
		var trim_position: Vector3 = Vector3(along, 0.72, fixed_position) if is_horizontal else Vector3(fixed_position, 0.72, along)
		var shadow_position: Vector3 = Vector3(along, 0.02, fixed_position) if is_horizontal else Vector3(fixed_position, 0.02, along)

		var shadow: MeshInstance3D = _create_box("%sShadow" % base_name, shadow_size, shadow_position)
		shadow.material_override = shadow_material
		world.add_child(shadow)

		var white_panel: MeshInstance3D = _create_box("%sWhite" % base_name, white_size, white_position)
		white_panel.material_override = white_material
		world.add_child(white_panel)

		var kick: MeshInstance3D = _create_box("%sKickplate" % base_name, kick_size, kick_position)
		kick.material_override = black_material
		world.add_child(kick)

		var trim: MeshInstance3D = _create_box("%sAccentTrim" % base_name, trim_size, trim_position)
		trim.material_override = accent_material
		world.add_child(trim)

	_create_major_stanchions(node_prefix, is_horizontal, fixed_position, length)

func _create_arcade_glass_run(node_prefix: String, is_horizontal: bool, fixed_position: float, _flip_side: bool) -> void:
	var glass_material: StandardMaterial3D = _make_glass_material()
	var shine_material: StandardMaterial3D = _make_material(Color(0.85, 0.96, 1.0, 0.22), 0.0, 0.16)
	var length: float = RINK_LENGTH + 0.45 if is_horizontal else RINK_WIDTH + 0.45
	var panel_count: int = 8 if is_horizontal else 4
	var panel_length: float = length / float(panel_count)
	var start: float = -length * 0.5 + panel_length * 0.5

	for index: int in range(panel_count):
		var along: float = start + float(index) * panel_length
		var panel_size: Vector3 = Vector3(panel_length - 0.16, 0.74, 0.045) if is_horizontal else Vector3(0.045, 0.74, panel_length - 0.16)
		var panel_position: Vector3 = Vector3(along, VISUAL_GLASS_Y, fixed_position) if is_horizontal else Vector3(fixed_position, VISUAL_GLASS_Y, along)
		var panel: MeshInstance3D = _create_box("%sPanel%02d" % [node_prefix, index], panel_size, panel_position)
		panel.material_override = glass_material
		world.add_child(panel)

		var shine_size: Vector3 = Vector3(panel_length * 0.42, 0.04, 0.052) if is_horizontal else Vector3(0.052, 0.04, panel_length * 0.42)
		var shine_offset: float = -0.16 if index % 2 == 0 else 0.16
		var shine_position: Vector3 = Vector3(along + shine_offset, VISUAL_GLASS_Y + 0.22, fixed_position) if is_horizontal else Vector3(fixed_position, VISUAL_GLASS_Y + 0.22, along + shine_offset)
		var shine: MeshInstance3D = _create_box("%sShine%02d" % [node_prefix, index], shine_size, shine_position)
		shine.rotation.y = deg_to_rad(-18.0 if index % 2 == 0 else 18.0)
		shine.material_override = shine_material
		world.add_child(shine)

	_create_major_stanchions("%sPosts" % node_prefix, is_horizontal, fixed_position, length)

func _create_major_stanchions(node_prefix: String, is_horizontal: bool, fixed_position: float, length: float) -> void:
	var post_material: StandardMaterial3D = _make_material(Color(0.08, 0.10, 0.13, 1.0), 0.0, 0.32)
	var cap_material: StandardMaterial3D = _make_material(Color(0.38, 0.44, 0.52, 1.0), 0.0, 0.22)
	var count: int = 9 if is_horizontal else 5
	for index: int in range(count):
		var t: float = float(index) / float(count - 1)
		var along: float = lerp(-length * 0.5, length * 0.5, t)
		var post_size: Vector3 = Vector3(0.08, 1.18, 0.16) if is_horizontal else Vector3(0.16, 1.18, 0.08)
		var post_position: Vector3 = Vector3(along, VISUAL_POST_Y, fixed_position) if is_horizontal else Vector3(fixed_position, VISUAL_POST_Y, along)
		var post: MeshInstance3D = _create_box("%sPost%02d" % [node_prefix, index], post_size, post_position)
		post.material_override = post_material
		world.add_child(post)

		var cap_size: Vector3 = Vector3(0.12, 0.10, 0.20) if is_horizontal else Vector3(0.20, 0.10, 0.12)
		var cap_position: Vector3 = Vector3(along, VISUAL_POST_Y + 0.62, fixed_position) if is_horizontal else Vector3(fixed_position, VISUAL_POST_Y + 0.62, along)
		var cap: MeshInstance3D = _create_box("%sPostCap%02d" % [node_prefix, index], cap_size, cap_position)
		cap.material_override = cap_material
		world.add_child(cap)

func _create_board_corner_caps() -> void:
	var post_material: StandardMaterial3D = _make_material(Color(0.04, 0.05, 0.065, 1.0), 0.0, 0.30)
	var corner_positions: Array[Vector3] = [
		Vector3(-RINK_LENGTH * 0.5 - 0.30, VISUAL_POST_Y, -RINK_WIDTH * 0.5 - 0.30),
		Vector3(RINK_LENGTH * 0.5 + 0.30, VISUAL_POST_Y, -RINK_WIDTH * 0.5 - 0.30),
		Vector3(-RINK_LENGTH * 0.5 - 0.30, VISUAL_POST_Y, RINK_WIDTH * 0.5 + 0.30),
		Vector3(RINK_LENGTH * 0.5 + 0.30, VISUAL_POST_Y, RINK_WIDTH * 0.5 + 0.30)
	]
	for index: int in range(corner_positions.size()):
		var corner: MeshInstance3D = _create_box("BoardCornerPost%02d" % index, Vector3(0.34, 1.30, 0.34), corner_positions[index])
		corner.material_override = post_material
		world.add_child(corner)

func _make_glass_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.70, 0.88, 1.0, 0.30)
	material.metallic = 0.0
	material.roughness = 0.08
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_ice_texture_plane_material(texture: Texture2D) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	material.metallic = 0.0
	material.roughness = 0.38
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	var edge_material: StandardMaterial3D = _make_material(Color(0.55, 0.90, 1.0, 0.08), 0.0, 0.36)
	_create_flat_line("TopIceTextureGlow", Vector3(RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, ICE_TEXTURE_Y + 0.006, -RINK_WIDTH * 0.5 + 0.45), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("BottomIceTextureGlow", Vector3(RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, ICE_TEXTURE_Y + 0.006, RINK_WIDTH * 0.5 - 0.45), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("LeftIceTextureGlow", Vector3(0.16, 0.012, RINK_WIDTH - 1.0), Vector3(-RINK_LENGTH * 0.5 + 0.45, ICE_TEXTURE_Y + 0.006, 0.0), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("RightIceTextureGlow", Vector3(0.16, 0.012, RINK_WIDTH - 1.0), Vector3(RINK_LENGTH * 0.5 - 0.45, ICE_TEXTURE_Y + 0.006, 0.0), Color(0.55, 0.90, 1.0, 0.08), edge_material)
