extends Node3D

const RINK_LENGTH: float = 32.0
const RINK_WIDTH: float = 18.0
const ICE_THICKNESS: float = 0.12
const BOARD_HEIGHT: float = 1.4
const BOARD_THICKNESS: float = 0.35
const GOAL_WIDTH: float = 4.0
const GOAL_DEPTH: float = 1.2

@onready var world: Node3D = $World

func _ready() -> void:
	_build_test_rink()

func _build_test_rink() -> void:
	_create_ice_surface()
	_create_center_line()
	_create_blue_lines()
	_create_boards()
	_create_goals()
	_create_spawn_markers()
	_create_placeholder_players()
	_create_placeholder_puck()

func _create_ice_surface() -> void:
	var ice := _create_box("IceSurface", Vector3(RINK_LENGTH, ICE_THICKNESS, RINK_WIDTH), Vector3.ZERO)
	ice.material_override = _make_material(Color(0.72, 0.92, 1.0, 1.0), 0.25, 0.08)
	world.add_child(ice)

func _create_center_line() -> void:
	var line := _create_box("CenterLine", Vector3(0.18, 0.03, RINK_WIDTH), Vector3(0.0, 0.08, 0.0))
	line.material_override = _make_material(Color(0.9, 0.1, 0.1, 1.0), 0.0, 0.5)
	world.add_child(line)

func _create_blue_lines() -> void:
	for x_position in [-7.5, 7.5]:
		var line := _create_box("BlueLine", Vector3(0.18, 0.035, RINK_WIDTH), Vector3(x_position, 0.09, 0.0))
		line.material_override = _make_material(Color(0.1, 0.25, 0.95, 1.0), 0.0, 0.45)
		world.add_child(line)

func _create_boards() -> void:
	var board_material := _make_material(Color(0.95, 0.95, 0.88, 1.0), 0.0, 0.35)
	var top_board := _create_box("TopBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, -RINK_WIDTH * 0.5))
	var bottom_board := _create_box("BottomBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, RINK_WIDTH * 0.5))
	var left_board := _create_box("LeftBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(-RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var right_board := _create_box("RightBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))

	for board in [top_board, bottom_board, left_board, right_board]:
		board.material_override = board_material
		world.add_child(board)

func _create_goals() -> void:
	var goal_material := _make_material(Color(0.85, 0.05, 0.05, 1.0), 0.0, 0.3)
	for x_position in [-RINK_LENGTH * 0.5 + 0.8, RINK_LENGTH * 0.5 - 0.8]:
		var goal_name := "LeftGoal" if x_position < 0.0 else "RightGoal"
		var goal := Node3D.new()
		goal.name = goal_name
		world.add_child(goal)

		var back_bar := _create_box("BackBar", Vector3(0.12, 1.0, GOAL_WIDTH), Vector3(x_position, 0.5, 0.0))
		var top_bar := _create_box("TopBar", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + sign(x_position) * -GOAL_DEPTH * 0.5, 1.0, -GOAL_WIDTH * 0.5))
		var bottom_bar := _create_box("BottomBar", Vector3(GOAL_DEPTH, 0.12, 0.12), Vector3(x_position + sign(x_position) * -GOAL_DEPTH * 0.5, 1.0, GOAL_WIDTH * 0.5))

		for bar in [back_bar, top_bar, bottom_bar]:
			bar.material_override = goal_material
			goal.add_child(bar)

func _create_spawn_markers() -> void:
	for marker_path in ["../SpawnPoints/HomeSpawn", "../SpawnPoints/AwaySpawn", "../SpawnPoints/PuckSpawn"]:
		var marker := world.get_node_or_null(marker_path)
		if marker == null:
			continue
		var marker_visual := _create_cylinder("MarkerVisual", 0.25, 0.04, marker.global_position)
		marker_visual.material_override = _make_material(Color(1.0, 0.85, 0.2, 1.0), 0.0, 0.35)
		world.add_child(marker_visual)

func _create_placeholder_players() -> void:
	var home_player := _create_cylinder("HomePlayerPlaceholder", 0.45, 1.1, Vector3(-10.0, 0.65, 0.0))
	home_player.material_override = _make_material(Color(0.15, 0.35, 1.0, 1.0), 0.0, 0.35)
	world.add_child(home_player)

	var away_player := _create_cylinder("AwayPlayerPlaceholder", 0.45, 1.1, Vector3(10.0, 0.65, 0.0))
	away_player.material_override = _make_material(Color(1.0, 0.2, 0.15, 1.0), 0.0, 0.35)
	world.add_child(away_player)

func _create_placeholder_puck() -> void:
	var puck := _create_cylinder("PuckPlaceholder", 0.28, 0.14, Vector3(0.0, 0.18, 0.0))
	puck.material_override = _make_material(Color(0.02, 0.02, 0.025, 1.0), 0.0, 0.15)
	world.add_child(puck)

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
	return material
