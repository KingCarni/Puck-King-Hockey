extends Node3D

const RINK_LENGTH: float = 34.0
const RINK_WIDTH: float = 18.0
const ICE_THICKNESS: float = 0.12
const BOARD_HEIGHT: float = 0.75
const BOARD_THICKNESS: float = 0.32
const GOAL_WIDTH: float = 3.2
const GOAL_DEPTH: float = 1.2
const LINE_HEIGHT: float = 0.11

@onready var world: Node3D = $World
@onready var camera: Camera3D = $CameraRig/IsometricCamera

func _ready() -> void:
	_configure_camera()
	_build_test_rink()

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 36.0
	camera.global_position = Vector3(0.0, 26.0, 24.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_test_rink() -> void:
	_create_floor_backdrop()
	_create_ice_surface()
	_create_zone_tints()
	_create_rink_lines()
	_create_faceoff_markings()
	_create_boards()
	_create_glass_posts()
	_create_goals()
	_create_spawn_markers()
	_create_placeholder_players()
	_create_placeholder_puck()

func _create_floor_backdrop() -> void:
	var floor := _create_box("DarkArenaFloor", Vector3(RINK_LENGTH + 8.0, 0.08, RINK_WIDTH + 8.0), Vector3.ZERO)
	floor.position.y = -0.08
	floor.material_override = _make_material(Color(0.055, 0.06, 0.065, 1.0), 0.0, 0.75)
	world.add_child(floor)

func _create_ice_surface() -> void:
	var ice := _create_box("IceSurface", Vector3(RINK_LENGTH, ICE_THICKNESS, RINK_WIDTH), Vector3.ZERO)
	ice.material_override = _make_material(Color(0.78, 0.94, 1.0, 1.0), 0.05, 0.18)
	world.add_child(ice)

func _create_zone_tints() -> void:
	var home_crease := _create_box("HomeCrease", Vector3(2.3, 0.02, 4.8), Vector3(-RINK_LENGTH * 0.5 + 1.75, LINE_HEIGHT, 0.0))
	home_crease.material_override = _make_material(Color(0.35, 0.75, 1.0, 0.55), 0.0, 0.35)
	world.add_child(home_crease)

	var away_crease := _create_box("AwayCrease", Vector3(2.3, 0.02, 4.8), Vector3(RINK_LENGTH * 0.5 - 1.75, LINE_HEIGHT, 0.0))
	away_crease.material_override = _make_material(Color(0.35, 0.75, 1.0, 0.55), 0.0, 0.35)
	world.add_child(away_crease)

func _create_rink_lines() -> void:
	_create_flat_line("CenterRedLine", Vector3(0.20, 0.03, RINK_WIDTH), Vector3(0.0, LINE_HEIGHT, 0.0), Color(0.9, 0.08, 0.08, 1.0))
	_create_flat_line("LeftBlueLine", Vector3(0.24, 0.035, RINK_WIDTH), Vector3(-7.2, LINE_HEIGHT + 0.01, 0.0), Color(0.08, 0.22, 0.95, 1.0))
	_create_flat_line("RightBlueLine", Vector3(0.24, 0.035, RINK_WIDTH), Vector3(7.2, LINE_HEIGHT + 0.01, 0.0), Color(0.08, 0.22, 0.95, 1.0))
	_create_flat_line("HomeGoalLine", Vector3(0.12, 0.03, RINK_WIDTH - 1.1), Vector3(-RINK_LENGTH * 0.5 + 1.2, LINE_HEIGHT + 0.02, 0.0), Color(0.86, 0.07, 0.07, 1.0))
	_create_flat_line("AwayGoalLine", Vector3(0.12, 0.03, RINK_WIDTH - 1.1), Vector3(RINK_LENGTH * 0.5 - 1.2, LINE_HEIGHT + 0.02, 0.0), Color(0.86, 0.07, 0.07, 1.0))
	_create_ring("CenterCircle", Vector3(0.0, LINE_HEIGHT + 0.03, 0.0), 3.0, 0.08, Color(0.1, 0.25, 0.85, 1.0), 48)
	_create_ring("HomeCreaseRing", Vector3(-RINK_LENGTH * 0.5 + 1.8, LINE_HEIGHT + 0.03, 0.0), 2.25, 0.06, Color(0.86, 0.07, 0.07, 1.0), 36)
	_create_ring("AwayCreaseRing", Vector3(RINK_LENGTH * 0.5 - 1.8, LINE_HEIGHT + 0.03, 0.0), 2.25, 0.06, Color(0.86, 0.07, 0.07, 1.0), 36)

func _create_faceoff_markings() -> void:
	var positions: Array[Vector3] = [
		Vector3(-10.8, LINE_HEIGHT + 0.04, -4.8),
		Vector3(-10.8, LINE_HEIGHT + 0.04, 4.8),
		Vector3(10.8, LINE_HEIGHT + 0.04, -4.8),
		Vector3(10.8, LINE_HEIGHT + 0.04, 4.8),
		Vector3(-3.6, LINE_HEIGHT + 0.04, -4.8),
		Vector3(-3.6, LINE_HEIGHT + 0.04, 4.8),
		Vector3(3.6, LINE_HEIGHT + 0.04, -4.8),
		Vector3(3.6, LINE_HEIGHT + 0.04, 4.8)
	]

	for index in positions.size():
		var dot := _create_cylinder("FaceoffDot%02d" % index, 0.18, 0.035, positions[index])
		dot.material_override = _make_material(Color(0.84, 0.08, 0.08, 1.0), 0.0, 0.45)
		world.add_child(dot)

	for circle_position in [Vector3(-12.2, LINE_HEIGHT + 0.045, -5.8), Vector3(-12.2, LINE_HEIGHT + 0.045, 5.8), Vector3(12.2, LINE_HEIGHT + 0.045, -5.8), Vector3(12.2, LINE_HEIGHT + 0.045, 5.8)]:
		_create_ring("FaceoffCircle", circle_position, 1.75, 0.055, Color(0.84, 0.08, 0.08, 1.0), 36)

func _create_boards() -> void:
	var board_material := _make_material(Color(0.94, 0.95, 0.90, 1.0), 0.0, 0.28)
	var cap_material := _make_material(Color(0.1, 0.22, 0.9, 1.0), 0.0, 0.35)
	var kick_material := _make_material(Color(0.95, 0.78, 0.08, 1.0), 0.0, 0.45)

	var top_board := _create_box("TopBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, -RINK_WIDTH * 0.5))
	var bottom_board := _create_box("BottomBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, RINK_WIDTH * 0.5))
	var left_board := _create_box("LeftBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(-RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var right_board := _create_box("RightBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))

	for board in [top_board, bottom_board, left_board, right_board]:
		board.material_override = board_material
		world.add_child(board)

	_create_flat_line("TopBlueCap", Vector3(RINK_LENGTH + 0.6, 0.08, 0.14), Vector3(0.0, BOARD_HEIGHT + 0.06, -RINK_WIDTH * 0.5), Color(0.1, 0.22, 0.9, 1.0), cap_material)
	_create_flat_line("BottomBlueCap", Vector3(RINK_LENGTH + 0.6, 0.08, 0.14), Vector3(0.0, BOARD_HEIGHT + 0.06, RINK_WIDTH * 0.5), Color(0.1, 0.22, 0.9, 1.0), cap_material)
	_create_flat_line("TopKickPlate", Vector3(RINK_LENGTH + 0.5, 0.06, 0.08), Vector3(0.0, 0.16, -RINK_WIDTH * 0.5 + 0.22), Color(0.95, 0.78, 0.08, 1.0), kick_material)
	_create_flat_line("BottomKickPlate", Vector3(RINK_LENGTH + 0.5, 0.06, 0.08), Vector3(0.0, 0.16, RINK_WIDTH * 0.5 - 0.22), Color(0.95, 0.78, 0.08, 1.0), kick_material)

func _create_glass_posts() -> void:
	var post_material := _make_material(Color(0.72, 0.86, 1.0, 0.75), 0.0, 0.18)
	var x_min := -RINK_LENGTH * 0.5 + 0.8
	var x_max := RINK_LENGTH * 0.5 - 0.8
	for i in range(18):
		var x := lerp(x_min, x_max, float(i) / 17.0)
		for z in [-RINK_WIDTH * 0.5 - 0.08, RINK_WIDTH * 0.5 + 0.08]:
			var post := _create_cylinder("GlassPost", 0.035, 1.7, Vector3(x, BOARD_HEIGHT + 0.85, z))
			post.material_override = post_material
			world.add_child(post)

func _create_goals() -> void:
	var goal_material := _make_material(Color(0.85, 0.05, 0.05, 1.0), 0.0, 0.3)
	var net_material := _make_material(Color(0.86, 0.88, 0.88, 0.65), 0.0, 0.6)
	for x_position in [-RINK_LENGTH * 0.5 + 0.55, RINK_LENGTH * 0.5 - 0.55]:
		var goal_name := "LeftGoal" if x_position < 0.0 else "RightGoal"
		var goal_direction := 1.0 if x_position < 0.0 else -1.0
		var goal := Node3D.new()
		goal.name = goal_name
		world.add_child(goal)

		var back_bar := _create_box("BackBar", Vector3(0.12, 1.0, GOAL_WIDTH), Vector3(x_position, 0.55, 0.0))
		var top_post := _create_box("TopPost", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.55, -GOAL_WIDTH * 0.5))
		var bottom_post := _create_box("BottomPost", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.55, GOAL_WIDTH * 0.5))
		var cross_bar := _create_box("CrossBar", Vector3(0.12, 0.12, GOAL_WIDTH), Vector3(x_position + goal_direction * GOAL_DEPTH, 1.05, 0.0))
		var net := _create_box("NetPlaceholder", Vector3(GOAL_DEPTH, 0.75, GOAL_WIDTH), Vector3(x_position + goal_direction * GOAL_DEPTH * 0.5, 0.48, 0.0))

		for bar in [back_bar, top_post, bottom_post, cross_bar]:
			bar.material_override = goal_material
			goal.add_child(bar)

		net.material_override = net_material
		goal.add_child(net)

func _create_spawn_markers() -> void:
	for marker_path in ["../SpawnPoints/HomeSpawn", "../SpawnPoints/AwaySpawn", "../SpawnPoints/PuckSpawn"]:
		var marker := world.get_node_or_null(marker_path)
		if marker == null:
			continue
		var marker_visual := _create_cylinder("SpawnMarkerVisual", 0.22, 0.035, marker.global_position)
		marker_visual.material_override = _make_material(Color(1.0, 0.85, 0.2, 1.0), 0.0, 0.35)
		world.add_child(marker_visual)

func _create_placeholder_players() -> void:
	var home_player := _create_cylinder("HomePlayerPlaceholder", 0.42, 1.1, Vector3(-7.0, 0.65, -1.25))
	home_player.material_override = _make_material(Color(0.12, 0.34, 1.0, 1.0), 0.0, 0.35)
	world.add_child(home_player)

	var away_player := _create_cylinder("AwayPlayerPlaceholder", 0.42, 1.1, Vector3(7.0, 0.65, 1.25))
	away_player.material_override = _make_material(Color(1.0, 0.2, 0.15, 1.0), 0.0, 0.35)
	world.add_child(away_player)

func _create_placeholder_puck() -> void:
	var puck := _create_cylinder("PuckPlaceholder", 0.24, 0.12, Vector3(0.0, 0.18, 0.0))
	puck.material_override = _make_material(Color(0.02, 0.02, 0.025, 1.0), 0.0, 0.15)
	world.add_child(puck)

func _create_flat_line(node_name: String, size: Vector3, position: Vector3, color: Color, material: StandardMaterial3D = null) -> void:
	var line := _create_box(node_name, size, position)
	line.material_override = material if material != null else _make_material(color, 0.0, 0.45)
	world.add_child(line)

func _create_ring(node_name: String, center: Vector3, radius: float, thickness: float, color: Color, segments: int) -> void:
	var material := _make_material(color, 0.0, 0.45)
	var segment_length := TAU * radius / float(segments)
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		var position := Vector3(center.x + cos(angle) * radius, center.y, center.z + sin(angle) * radius)
		var segment := _create_box("%sSegment" % node_name, Vector3(segment_length, 0.025, thickness), position)
		segment.rotation.y = -angle
		segment.material_override = material
		world.add_child(segment)

func _create_box(node_name: String, size: Vector3, position: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	return mesh_instance

func _create_cylinder(node_name: String, radius: float, height: float, position: Vector3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	return mesh_instance

func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
