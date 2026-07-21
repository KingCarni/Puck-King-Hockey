extends "res://scripts/hockey/test_rink_3v3_pass.gd"

const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")

var _last_probe_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	world.scale = Vector3.ONE
	_build_geometry_overlay()
	_last_probe_position = _puck.global_position if _puck != null else Vector3.ZERO

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 39.5
	camera.global_position = Vector3(0.0, 34.0, 31.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null or _goal_lockout:
		return
	var current: Vector3 = _puck.global_position
	var previous: Vector3 = current
	if _puck.has_method("get_previous_position"):
		previous = _puck.call("get_previous_position")
	var velocity: Vector3 = Vector3.ZERO
	if _puck.has_method("get_velocity"):
		velocity = _puck.call("get_velocity")
	var possessed: bool = _puck.has_method("is_possessed") and bool(_puck.call("is_possessed"))
	if possessed:
		_last_probe_position = current
		return
	var scoring_team: String = RinkGeometry.legal_goal_crossing(previous, current, velocity)
	if scoring_team != "":
		_register_goal(scoring_team)
	_last_probe_position = current

func _build_geometry_overlay() -> void:
	var overlay: Node3D = Node3D.new()
	overlay.name = "NetPlayGeometry"
	add_child(overlay)
	var board_material: StandardMaterial3D = _make_overlay_material(Color(0.12, 0.18, 0.24, 0.78))
	var post_material: StandardMaterial3D = _make_overlay_material(Color(0.95, 0.08, 0.08, 1.0))
	_create_rounded_outline(overlay, board_material)
	for side: float in [-1.0, 1.0]:
		_create_net_frame(overlay, side, post_material)

func _create_rounded_outline(parent: Node3D, material: StandardMaterial3D) -> void:
	var straight_length: float = RinkGeometry.STRAIGHT_HALF_LENGTH * 2.0
	var straight_width: float = RinkGeometry.STRAIGHT_HALF_WIDTH * 2.0
	_add_bar(parent, "TopBoard", Vector3(straight_length, 0.28, 0.22), Vector3(0.0, 0.14, -RinkGeometry.HALF_WIDTH), material)
	_add_bar(parent, "BottomBoard", Vector3(straight_length, 0.28, 0.22), Vector3(0.0, 0.14, RinkGeometry.HALF_WIDTH), material)
	_add_bar(parent, "LeftBoard", Vector3(0.22, 0.28, straight_width), Vector3(-RinkGeometry.HALF_LENGTH, 0.14, 0.0), material)
	_add_bar(parent, "RightBoard", Vector3(0.22, 0.28, straight_width), Vector3(RinkGeometry.HALF_LENGTH, 0.14, 0.0), material)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for index: int in range(5):
				var angle_a: float = deg_to_rad(float(index) * 18.0)
				var angle_b: float = deg_to_rad(float(index + 1) * 18.0)
				var a: Vector3 = Vector3(sx * (RinkGeometry.STRAIGHT_HALF_LENGTH + cos(angle_a) * RinkGeometry.CORNER_RADIUS), 0.14, sz * (RinkGeometry.STRAIGHT_HALF_WIDTH + sin(angle_a) * RinkGeometry.CORNER_RADIUS))
				var b: Vector3 = Vector3(sx * (RinkGeometry.STRAIGHT_HALF_LENGTH + cos(angle_b) * RinkGeometry.CORNER_RADIUS), 0.14, sz * (RinkGeometry.STRAIGHT_HALF_WIDTH + sin(angle_b) * RinkGeometry.CORNER_RADIUS))
				_add_segment(parent, a, b, material)

func _create_net_frame(parent: Node3D, side: float, material: StandardMaterial3D) -> void:
	var mouth_x: float = side * RinkGeometry.GOAL_LINE_X
	var back_x: float = side * (RinkGeometry.GOAL_LINE_X + RinkGeometry.GOAL_DEPTH)
	for z: float in [-RinkGeometry.GOAL_HALF_WIDTH, RinkGeometry.GOAL_HALF_WIDTH]:
		_add_segment(parent, Vector3(mouth_x, 0.20, z), Vector3(back_x, 0.20, z), material, 0.16)
	_add_segment(parent, Vector3(back_x, 0.20, -RinkGeometry.GOAL_HALF_WIDTH), Vector3(back_x, 0.20, RinkGeometry.GOAL_HALF_WIDTH), material, 0.16)
	for z: float in [-RinkGeometry.GOAL_HALF_WIDTH, RinkGeometry.GOAL_HALF_WIDTH]:
		var post: MeshInstance3D = MeshInstance3D.new()
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.12
		mesh.bottom_radius = 0.12
		mesh.height = 0.75
		post.mesh = mesh
		post.position = Vector3(mouth_x, 0.38, z)
		post.material_override = material
		parent.add_child(post)

func _add_segment(parent: Node3D, a: Vector3, b: Vector3, material: StandardMaterial3D, thickness: float = 0.22) -> void:
	var delta: Vector3 = b - a
	var length: float = delta.length()
	var bar: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(length, 0.28, thickness)
	bar.mesh = mesh
	bar.position = (a + b) * 0.5
	bar.rotation.y = -atan2(delta.z, delta.x)
	bar.material_override = material
	parent.add_child(bar)

func _add_bar(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: StandardMaterial3D) -> void:
	var bar: MeshInstance3D = MeshInstance3D.new()
	bar.name = node_name
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	bar.mesh = mesh
	bar.position = position
	bar.material_override = material
	parent.add_child(bar)

func _make_overlay_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	return material
