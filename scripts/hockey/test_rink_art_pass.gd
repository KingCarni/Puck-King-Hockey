extends "res://scripts/hockey/test_rink.gd"

const ICE_TEXTURE_WEBP_PATH: String = "res://assets/art/rink/pkh_ice_surface.webp"
const ICE_TEXTURE_PNG_PATH: String = "res://assets/art/rink/pkh_ice_surface.png"
const ICE_TEXTURE_Y: float = 0.082

const ART_RINK_LENGTH: float = 38.5
const ART_RINK_WIDTH: float = 20.5
const ART_HOME_GOAL_X: float = ART_RINK_LENGTH * 0.5 - 1.05
const ART_AWAY_GOAL_X: float = -ART_RINK_LENGTH * 0.5 + 1.05
const HOME_TEAMMATE_START: Vector3 = Vector3(-8.2, PLAYER_Y, 3.7)
const AWAY_TEAMMATE_START: Vector3 = Vector3(8.2, PLAYER_Y, -3.7)

const VISUAL_BOARD_Y: float = 0.42
const VISUAL_GLASS_Y: float = 1.18
const VISUAL_POST_Y: float = 1.08

@onready var _home_teammate: Node3D = get_node_or_null("HomeTeammate") as Node3D
@onready var _away_teammate: Node3D = get_node_or_null("AwayTeammate") as Node3D

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 30.0
	camera.global_position = Vector3(0.0, 28.0, 25.5)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null:
		return
	if _goal_lockout:
		return

	var puck_position: Vector3 = _puck.global_position
	var is_inside_goal_width: bool = abs(puck_position.z) <= GOAL_WIDTH * 0.5 + 0.35
	if not is_inside_goal_width:
		return

	if puck_position.x >= ART_HOME_GOAL_X:
		_register_goal("HOME")
	elif puck_position.x <= ART_AWAY_GOAL_X:
		_register_goal("AWAY")

func _reset_faceoff(clear_puck: bool) -> void:
	super._reset_faceoff(clear_puck)
	_reset_home_teammate()
	_reset_away_teammate()

func _set_match_enabled(is_enabled: bool) -> void:
	super._set_match_enabled(is_enabled)
	if _home_teammate != null:
		_home_teammate.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
	if _away_teammate != null:
		_away_teammate.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED

func _reset_home_teammate() -> void:
	if _home_teammate == null:
		return
	_home_teammate.global_position = HOME_TEAMMATE_START
	_home_teammate.set("_move_velocity", Vector3.ZERO)
	_home_teammate.set("_last_facing_direction", Vector3.RIGHT)
	_home_teammate.set("_shoot_cooldown_timer", 0.0)

func _reset_away_teammate() -> void:
	if _away_teammate == null:
		return
	_away_teammate.global_position = AWAY_TEAMMATE_START
	_away_teammate.set("_move_velocity", Vector3.ZERO)
	_away_teammate.set("_last_facing_direction", Vector3.LEFT)
	_away_teammate.set("_stun_timer", 0.0)
	_away_teammate.set("_shoot_cooldown_timer", 0.0)

func _create_floor_backdrop() -> void:
	var floor: MeshInstance3D = _create_box("DarkArenaFloor", Vector3(ART_RINK_LENGTH + 8.0, 0.08, ART_RINK_WIDTH + 8.0), Vector3.ZERO)
	floor.position.y = -0.08
	floor.material_override = _make_material(Color(0.035, 0.038, 0.042, 1.0), 0.0, 0.78)
	world.add_child(floor)

func _create_ice_surface() -> void:
	var base_ice: MeshInstance3D = _create_box("IceSurfaceBase", Vector3(ART_RINK_LENGTH, ICE_THICKNESS, ART_RINK_WIDTH), Vector3.ZERO)
	base_ice.material_override = _make_material(Color(0.86, 0.97, 1.0, 1.0), 0.0, 0.24)
	world.add_child(base_ice)

	var texture: Texture2D = _load_ice_texture()
	if texture == null:
		return

	var ice_quad: MeshInstance3D = MeshInstance3D.new()
	ice_quad.name = "IceSurfaceTextureQuad"

	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(ART_RINK_LENGTH, ART_RINK_WIDTH)
	ice_quad.mesh = quad
	ice_quad.position = Vector3(0.0, ICE_TEXTURE_Y, 0.0)
	ice_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	ice_quad.material_override = _make_ice_texture_plane_material(texture)
	world.add_child(ice_quad)

func _create_ice_surface_details() -> void:
	if _has_ice_texture():
		_create_subtle_ice_edge_glow()
		return

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
	var collision_board_material: StandardMaterial3D = _make_material(Color(0.18, 0.20, 0.20, 0.18), 0.0, 0.80)
	var top_collision: MeshInstance3D = _create_box("TopBoardsCollisionVisual", Vector3(ART_RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, -ART_RINK_WIDTH * 0.5))
	var bottom_collision: MeshInstance3D = _create_box("BottomBoardsCollisionVisual", Vector3(ART_RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, ART_RINK_WIDTH * 0.5))
	var left_collision: MeshInstance3D = _create_box("LeftBoardsCollisionVisual", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, ART_RINK_WIDTH + BOARD_THICKNESS), Vector3(-ART_RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var right_collision: MeshInstance3D = _create_box("RightBoardsCollisionVisual", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, ART_RINK_WIDTH + BOARD_THICKNESS), Vector3(ART_RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var collision_boards: Array[MeshInstance3D] = [top_collision, bottom_collision, left_collision, right_collision]
	for board: MeshInstance3D in collision_boards:
		board.material_override = collision_board_material
		world.add_child(board)

	_create_arcade_board_run("TopVisualBoards", true, -ART_RINK_WIDTH * 0.5 - 0.30, false)
	_create_arcade_board_run("BottomVisualBoards", true, ART_RINK_WIDTH * 0.5 + 0.30, true)
	_create_arcade_board_run("LeftVisualBoards", false, -ART_RINK_LENGTH * 0.5 - 0.30, false)
	_create_arcade_board_run("RightVisualBoards", false, ART_RINK_LENGTH * 0.5 + 0.30, true)
	_create_board_corner_caps()

func _create_glass_posts() -> void:
	_create_arcade_glass_run("TopGlass", true, -ART_RINK_WIDTH * 0.5 - 0.42, false)
	_create_arcade_glass_run("BottomGlass", true, ART_RINK_WIDTH * 0.5 + 0.42, true)
	_create_arcade_glass_run("LeftGlass", false, -ART_RINK_LENGTH * 0.5 - 0.42, false)
	_create_arcade_glass_run("RightGlass", false, ART_RINK_LENGTH * 0.5 + 0.42, true)

func _create_goals() -> void:
	var goal_material: StandardMaterial3D = _make_material(Color(0.85, 0.05, 0.05, 1.0), 0.0, 0.3)
	var net_material: StandardMaterial3D = _make_material(Color(0.86, 0.88, 0.88, 0.65), 0.0, 0.6)
	var goal_positions: Array[float] = [-ART_RINK_LENGTH * 0.5 + 0.55, ART_RINK_LENGTH * 0.5 - 0.55]

	for x_position: float in goal_positions:
		var goal_name: String = "LeftGoal" if x_position < 0.0 else "RightGoal"
		var goal_direction: float = 1.0 if x_position < 0.0 else -1.0
		var goal: Node3D = Node3D.new()
		goal.name = goal_name
		world.add_child(goal)

		var back_bar: MeshInstance3D = _create_box("BackBar", Vector3(0.12, 1.0, GOAL_WIDTH), Vector3(x_position, 0.55, 0.0))
		var top_post: MeshInstance3D = _create_box("TopPost", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.55, -GOAL_WIDTH * 0.5))
		var bottom_post: MeshInstance3D = _create_box("BottomPost", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.55, GOAL_WIDTH * 0.5))
		var cross_bar: MeshInstance3D = _create_box("CrossBar", Vector3(0.12, 0.12, GOAL_WIDTH), Vector3(x_position + goal_direction * GOAL_DEPTH, 1.05, 0.0))
		var net: MeshInstance3D = _create_box("NetPlaceholder", Vector3(GOAL_DEPTH, 0.75, GOAL_WIDTH), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.48, 0.0))
		var bars: Array[MeshInstance3D] = [back_bar, top_post, bottom_post, cross_bar]

		for bar: MeshInstance3D in bars:
			bar.material_override = goal_material
			goal.add_child(bar)

		net.material_override = net_material
		goal.add_child(net)

func _create_arcade_board_run(node_prefix: String, is_horizontal: bool, fixed_position: float, flip_trim: bool) -> void:
	var white_material: StandardMaterial3D = _make_material(Color(0.94, 0.96, 0.96, 1.0), 0.0, 0.28)
	var black_material: StandardMaterial3D = _make_material(Color(0.02, 0.025, 0.03, 1.0), 0.0, 0.55)
	var red_material: StandardMaterial3D = _make_material(Color(0.95, 0.06, 0.08, 1.0), 0.0, 0.34)
	var blue_material: StandardMaterial3D = _make_material(Color(0.08, 0.28, 0.95, 1.0), 0.0, 0.34)
	var shadow_material: StandardMaterial3D = _make_material(Color(0.0, 0.0, 0.0, 0.36), 0.0, 0.70)

	var length: float = ART_RINK_LENGTH + 0.80 if is_horizontal else ART_RINK_WIDTH + 0.80
	var panel_count: int = 9 if is_horizontal else 5
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
	var length: float = ART_RINK_LENGTH + 0.45 if is_horizontal else ART_RINK_WIDTH + 0.45
	var panel_count: int = 9 if is_horizontal else 5
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
	var count: int = 10 if is_horizontal else 6
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
		Vector3(-ART_RINK_LENGTH * 0.5 - 0.30, VISUAL_POST_Y, -ART_RINK_WIDTH * 0.5 - 0.30),
		Vector3(ART_RINK_LENGTH * 0.5 + 0.30, VISUAL_POST_Y, -ART_RINK_WIDTH * 0.5 - 0.30),
		Vector3(-ART_RINK_LENGTH * 0.5 - 0.30, VISUAL_POST_Y, ART_RINK_WIDTH * 0.5 + 0.30),
		Vector3(ART_RINK_LENGTH * 0.5 + 0.30, VISUAL_POST_Y, ART_RINK_WIDTH * 0.5 + 0.30)
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
	_create_flat_line("TopIceTextureGlow", Vector3(ART_RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, ICE_TEXTURE_Y + 0.006, -ART_RINK_WIDTH * 0.5 + 0.45), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("BottomIceTextureGlow", Vector3(ART_RINK_LENGTH - 1.0, 0.012, 0.16), Vector3(0.0, ICE_TEXTURE_Y + 0.006, ART_RINK_WIDTH * 0.5 - 0.45), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("LeftIceTextureGlow", Vector3(0.16, 0.012, ART_RINK_WIDTH - 1.0), Vector3(-ART_RINK_LENGTH * 0.5 + 0.45, ICE_TEXTURE_Y + 0.006, 0.0), Color(0.55, 0.90, 1.0, 0.08), edge_material)
	_create_flat_line("RightIceTextureGlow", Vector3(0.16, 0.012, ART_RINK_WIDTH - 1.0), Vector3(ART_RINK_LENGTH * 0.5 - 0.45, ICE_TEXTURE_Y + 0.006, 0.0), Color(0.55, 0.90, 1.0, 0.08), edge_material)
