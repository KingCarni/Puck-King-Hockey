extends Node3D

const RINK_LENGTH: float = 34.0
const RINK_WIDTH: float = 18.0
const ICE_THICKNESS: float = 0.12
const BOARD_HEIGHT: float = 0.75
const BOARD_THICKNESS: float = 0.32
const GOAL_WIDTH: float = 3.2
const GOAL_DEPTH: float = 1.2
const LINE_HEIGHT: float = 0.11
const PLAYER_Y: float = 0.72
const PUCK_Y: float = 0.18
const HOME_GOAL_X: float = RINK_LENGTH * 0.5 - 1.05
const AWAY_GOAL_X: float = -RINK_LENGTH * 0.5 + 1.05

var _home_score: int = 0
var _away_score: int = 0
var _reward_visible: bool = false
var _selected_upgrades: Array[String] = []
var _reward_options: Array[Dictionary] = [
	{
		"id": "rocket_skates",
		"title": "Rocket Skates",
		"description": "+Speed, +boost speed, +acceleration."
	},
	{
		"id": "sticky_tape",
		"title": "Sticky Tape",
		"description": "+Puck pickup radius and smoother puck control."
	},
	{
		"id": "titanium_pads",
		"title": "Titanium Pads",
		"description": "+Checking power, +hit range, +puck pop force."
	}
]
var _reward_buttons: Array[Button] = []
var _score_label: Label = null
var _status_label: Label = null
var _upgrade_label: Label = null
var _reward_root: Control = null

@onready var world: Node3D = $World
@onready var camera: Camera3D = $CameraRig/IsometricCamera
@onready var _player: Node3D = $Player
@onready var _away_ai: Node3D = $AwayAI
@onready var _puck: Node3D = $Puck
@onready var _home_spawn: Marker3D = $SpawnPoints/HomeSpawn
@onready var _away_spawn: Marker3D = $SpawnPoints/AwaySpawn
@onready var _puck_spawn: Marker3D = $SpawnPoints/PuckSpawn

func _ready() -> void:
	_configure_camera()
	_build_test_rink()
	_build_match_ui()
	_update_scoreboard()
	_reset_faceoff(false)

func _process(_delta: float) -> void:
	if _reward_visible:
		return
	_check_goal_state()

func _unhandled_input(event: InputEvent) -> void:
	if not _reward_visible:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_1:
			_select_reward(0)
		elif key_event.keycode == KEY_2:
			_select_reward(1)
		elif key_event.keycode == KEY_3:
			_select_reward(2)

	if event is InputEventJoypadButton:
		var button_event: InputEventJoypadButton = event as InputEventJoypadButton
		if not button_event.pressed:
			return
		if button_event.button_index == JOY_BUTTON_A:
			_select_reward(0)
		elif button_event.button_index == JOY_BUTTON_X:
			_select_reward(1)
		elif button_event.button_index == JOY_BUTTON_Y:
			_select_reward(2)

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27.0
	camera.global_position = Vector3(0.0, 26.0, 24.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null:
		return

	var puck_position: Vector3 = _puck.global_position
	var is_inside_goal_width: bool = abs(puck_position.z) <= GOAL_WIDTH * 0.5 + 0.35
	if not is_inside_goal_width:
		return

	if puck_position.x >= HOME_GOAL_X:
		_home_score += 1
		_update_scoreboard()
		_show_reward_draft()
	elif puck_position.x <= AWAY_GOAL_X:
		_away_score += 1
		_update_scoreboard()
		_show_status("AWAY GOAL! PUCK DROP AT CENTER.")
		_reset_faceoff(true)

func _show_reward_draft() -> void:
	_reward_visible = true
	_set_match_enabled(false)
	_show_status("GOAL! CHOOSE YOUR REWARD.")
	_reset_faceoff(false)

	if _reward_root != null:
		_reward_root.visible = true

	for index: int in range(_reward_buttons.size()):
		var option: Dictionary = _reward_options[index]
		var button: Button = _reward_buttons[index]
		button.text = "%d. %s\n%s" % [index + 1, String(option["title"]), String(option["description"])]

func _select_reward(index: int) -> void:
	if index < 0 or index >= _reward_options.size():
		return

	var option: Dictionary = _reward_options[index]
	var upgrade_id: String = String(option["id"])
	_selected_upgrades.append(upgrade_id)
	_apply_upgrade(upgrade_id)
	_update_upgrade_label()

	_reward_visible = false
	if _reward_root != null:
		_reward_root.visible = false

	_show_status("SELECTED: %s" % String(option["title"]))
	_set_match_enabled(true)
	_reset_faceoff(true)

func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"rocket_skates":
			_player.set("acceleration", float(_player.get("acceleration")) * 1.08)
			_player.set("sprint_acceleration", float(_player.get("sprint_acceleration")) * 1.10)
			_player.set("max_speed", float(_player.get("max_speed")) * 1.12)
			_player.set("sprint_max_speed", float(_player.get("sprint_max_speed")) * 1.15)
		"sticky_tape":
			_player.set("puck_carry_distance", float(_player.get("puck_carry_distance")) + 0.18)
			_puck.set("pickup_radius", float(_puck.get("pickup_radius")) * 1.25)
			_puck.set("carry_lag_speed", float(_puck.get("carry_lag_speed")) * 1.18)
		"titanium_pads":
			_player.set("check_knockback_force", float(_player.get("check_knockback_force")) * 1.35)
			_player.set("check_puck_force", float(_player.get("check_puck_force")) * 1.25)
			_player.set("check_hit_radius", float(_player.get("check_hit_radius")) + 0.16)
		_:
			return

func _reset_faceoff(clear_puck: bool) -> void:
	_player.global_position = _home_spawn.global_position
	_player.global_position.y = PLAYER_Y
	_player.set("velocity", Vector3.ZERO)
	_player.set("_move_velocity", Vector3.ZERO)
	_player.set("_last_facing_direction", Vector3.FORWARD)
	_player.set("_check_active_timer", 0.0)
	_player.set("_check_cooldown_timer", 0.0)

	_away_ai.global_position = _away_spawn.global_position
	_away_ai.global_position.y = PLAYER_Y
	_away_ai.set("_move_velocity", Vector3.ZERO)
	_away_ai.set("_last_facing_direction", Vector3.LEFT)
	_away_ai.set("_stun_timer", 0.0)
	_away_ai.set("_shoot_cooldown_timer", 0.0)

	if clear_puck:
		_reset_puck_to_center()

func _reset_puck_to_center() -> void:
	_puck.global_position = _puck_spawn.global_position
	_puck.global_position.y = PUCK_Y
	_puck.set("_velocity", Vector3.ZERO)
	_puck.set("_owner", null)
	_puck.set("_is_possessed", false)

func _set_match_enabled(is_enabled: bool) -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
	_away_ai.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
	_puck.process_mode = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED

func _show_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message

func _update_scoreboard() -> void:
	if _score_label != null:
		_score_label.text = "HOME %d  -  %d AWAY" % [_home_score, _away_score]

func _update_upgrade_label() -> void:
	if _upgrade_label == null:
		return

	if _selected_upgrades.is_empty():
		_upgrade_label.text = "Upgrades: none"
		return

	var display_names: Array[String] = []
	for upgrade_id: String in _selected_upgrades:
		display_names.append(_get_upgrade_title(upgrade_id))
	_upgrade_label.text = "Upgrades: %s" % ", ".join(display_names)

func _get_upgrade_title(upgrade_id: String) -> String:
	for option: Dictionary in _reward_options:
		if String(option["id"]) == upgrade_id:
			return String(option["title"])
	return upgrade_id

func _build_match_ui() -> void:
	var hud_layer: CanvasLayer = CanvasLayer.new()
	hud_layer.name = "MatchHUD"
	add_child(hud_layer)

	var hud_root: Control = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(hud_root)

	_score_label = Label.new()
	_score_label.position = Vector2(32.0, 24.0)
	_score_label.add_theme_font_size_override("font_size", 32)
	hud_root.add_child(_score_label)

	_status_label = Label.new()
	_status_label.position = Vector2(32.0, 66.0)
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.text = "FIRST HOME GOAL TRIGGERS REWARD DRAFT"
	hud_root.add_child(_status_label)

	_upgrade_label = Label.new()
	_upgrade_label.position = Vector2(32.0, 100.0)
	_upgrade_label.add_theme_font_size_override("font_size", 18)
	hud_root.add_child(_upgrade_label)
	_update_upgrade_label()

	var reward_layer: CanvasLayer = CanvasLayer.new()
	reward_layer.name = "RewardDraftLayer"
	add_child(reward_layer)

	_reward_root = Control.new()
	_reward_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward_root.visible = false
	reward_layer.add_child(_reward_root)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.62)
	_reward_root.add_child(shade)

	var panel: PanelContainer = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -430.0
	panel.offset_top = -260.0
	panel.offset_right = 430.0
	panel.offset_bottom = 260.0
	_reward_root.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = "POST-MATCH REWARD DRAFT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "Pick one upgrade. Keys: 1/2/3. Controller: A/X/Y."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	vbox.add_child(subtitle)

	_reward_buttons.clear()
	for index: int in range(_reward_options.size()):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(780.0, 92.0)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(Callable(self, "_select_reward").bind(index))
		vbox.add_child(button)
		_reward_buttons.append(button)

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

func _create_floor_backdrop() -> void:
	var floor: MeshInstance3D = _create_box("DarkArenaFloor", Vector3(RINK_LENGTH + 8.0, 0.08, RINK_WIDTH + 8.0), Vector3.ZERO)
	floor.position.y = -0.08
	floor.material_override = _make_material(Color(0.055, 0.06, 0.065, 1.0), 0.0, 0.75)
	world.add_child(floor)

func _create_ice_surface() -> void:
	var ice: MeshInstance3D = _create_box("IceSurface", Vector3(RINK_LENGTH, ICE_THICKNESS, RINK_WIDTH), Vector3.ZERO)
	ice.material_override = _make_material(Color(0.78, 0.94, 1.0, 1.0), 0.05, 0.18)
	world.add_child(ice)

func _create_zone_tints() -> void:
	var home_crease: MeshInstance3D = _create_box("HomeCrease", Vector3(2.3, 0.02, 4.8), Vector3(-RINK_LENGTH * 0.5 + 1.75, LINE_HEIGHT, 0.0))
	home_crease.material_override = _make_material(Color(0.35, 0.75, 1.0, 0.55), 0.0, 0.35)
	world.add_child(home_crease)

	var away_crease: MeshInstance3D = _create_box("AwayCrease", Vector3(2.3, 0.02, 4.8), Vector3(RINK_LENGTH * 0.5 - 1.75, LINE_HEIGHT, 0.0))
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
	var dot_positions: Array[Vector3] = [
		Vector3(-10.8, LINE_HEIGHT + 0.04, -4.8),
		Vector3(-10.8, LINE_HEIGHT + 0.04, 4.8),
		Vector3(10.8, LINE_HEIGHT + 0.04, -4.8),
		Vector3(10.8, LINE_HEIGHT + 0.04, 4.8),
		Vector3(-3.6, LINE_HEIGHT + 0.04, -4.8),
		Vector3(-3.6, LINE_HEIGHT + 0.04, 4.8),
		Vector3(3.6, LINE_HEIGHT + 0.04, -4.8),
		Vector3(3.6, LINE_HEIGHT + 0.04, 4.8)
	]

	for index: int in range(dot_positions.size()):
		var dot: MeshInstance3D = _create_cylinder("FaceoffDot%02d" % index, 0.18, 0.035, dot_positions[index])
		dot.material_override = _make_material(Color(0.84, 0.08, 0.08, 1.0), 0.0, 0.45)
		world.add_child(dot)

	var circle_positions: Array[Vector3] = [
		Vector3(-12.2, LINE_HEIGHT + 0.045, -5.8),
		Vector3(-12.2, LINE_HEIGHT + 0.045, 5.8),
		Vector3(12.2, LINE_HEIGHT + 0.045, -5.8),
		Vector3(12.2, LINE_HEIGHT + 0.045, 5.8)
	]

	for circle_position: Vector3 in circle_positions:
		_create_ring("FaceoffCircle", circle_position, 1.75, 0.055, Color(0.84, 0.08, 0.08, 1.0), 36)

func _create_boards() -> void:
	var board_material: StandardMaterial3D = _make_material(Color(0.94, 0.95, 0.90, 1.0), 0.0, 0.28)
	var cap_material: StandardMaterial3D = _make_material(Color(0.1, 0.22, 0.9, 1.0), 0.0, 0.35)
	var kick_material: StandardMaterial3D = _make_material(Color(0.95, 0.78, 0.08, 1.0), 0.0, 0.45)

	var top_board: MeshInstance3D = _create_box("TopBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, -RINK_WIDTH * 0.5))
	var bottom_board: MeshInstance3D = _create_box("BottomBoards", Vector3(RINK_LENGTH + BOARD_THICKNESS, BOARD_HEIGHT, BOARD_THICKNESS), Vector3(0.0, BOARD_HEIGHT * 0.5, RINK_WIDTH * 0.5))
	var left_board: MeshInstance3D = _create_box("LeftBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(-RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var right_board: MeshInstance3D = _create_box("RightBoards", Vector3(BOARD_THICKNESS, BOARD_HEIGHT, RINK_WIDTH + BOARD_THICKNESS), Vector3(RINK_LENGTH * 0.5, BOARD_HEIGHT * 0.5, 0.0))
	var boards: Array[MeshInstance3D] = [top_board, bottom_board, left_board, right_board]

	for board: MeshInstance3D in boards:
		board.material_override = board_material
		world.add_child(board)

	_create_flat_line("TopBlueCap", Vector3(RINK_LENGTH + 0.6, 0.08, 0.14), Vector3(0.0, BOARD_HEIGHT + 0.06, -RINK_WIDTH * 0.5), Color(0.1, 0.22, 0.9, 1.0), cap_material)
	_create_flat_line("BottomBlueCap", Vector3(RINK_LENGTH + 0.6, 0.08, 0.14), Vector3(0.0, BOARD_HEIGHT + 0.06, RINK_WIDTH * 0.5), Color(0.1, 0.22, 0.9, 1.0), cap_material)
	_create_flat_line("TopKickPlate", Vector3(RINK_LENGTH + 0.5, 0.06, 0.08), Vector3(0.0, 0.16, -RINK_WIDTH * 0.5 + 0.22), Color(0.95, 0.78, 0.08, 1.0), kick_material)
	_create_flat_line("BottomKickPlate", Vector3(RINK_LENGTH + 0.5, 0.06, 0.08), Vector3(0.0, 0.16, RINK_WIDTH * 0.5 - 0.22), Color(0.95, 0.78, 0.08, 1.0), kick_material)

func _create_glass_posts() -> void:
	var post_material: StandardMaterial3D = _make_material(Color(0.72, 0.86, 1.0, 0.75), 0.0, 0.18)
	var x_min: float = -RINK_LENGTH * 0.5 + 0.8
	var x_max: float = RINK_LENGTH * 0.5 - 0.8
	var side_positions: Array[float] = [-RINK_WIDTH * 0.5 - 0.08, RINK_WIDTH * 0.5 + 0.08]

	for i: int in range(18):
		var x_position: float = lerp(x_min, x_max, float(i) / 17.0)
		for z_position: float in side_positions:
			var post: MeshInstance3D = _create_cylinder("GlassPost", 0.035, 1.7, Vector3(x_position, BOARD_HEIGHT + 0.85, z_position))
			post.material_override = post_material
			world.add_child(post)

func _create_goals() -> void:
	var goal_material: StandardMaterial3D = _make_material(Color(0.85, 0.05, 0.05, 1.0), 0.0, 0.3)
	var net_material: StandardMaterial3D = _make_material(Color(0.86, 0.88, 0.88, 0.65), 0.0, 0.6)
	var goal_positions: Array[float] = [-RINK_LENGTH * 0.5 + 0.55, RINK_LENGTH * 0.5 - 0.55]

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

func _create_spawn_markers() -> void:
	var marker_paths: Array[String] = ["../SpawnPoints/HomeSpawn", "../SpawnPoints/AwaySpawn", "../SpawnPoints/PuckSpawn"]

	for marker_path: String in marker_paths:
		var marker: Node3D = world.get_node_or_null(marker_path) as Node3D
		if marker == null:
			continue
		var marker_visual: MeshInstance3D = _create_cylinder("SpawnMarkerVisual", 0.22, 0.035, marker.global_position)
		marker_visual.material_override = _make_material(Color(1.0, 0.85, 0.2, 1.0), 0.0, 0.35)
		world.add_child(marker_visual)

func _create_flat_line(node_name: String, size: Vector3, position: Vector3, color: Color, material: StandardMaterial3D = null) -> void:
	var line: MeshInstance3D = _create_box(node_name, size, position)
	line.material_override = material if material != null else _make_material(color, 0.0, 0.45)
	world.add_child(line)

func _create_ring(node_name: String, center: Vector3, radius: float, thickness: float, color: Color, segments: int) -> void:
	var material: StandardMaterial3D = _make_material(color, 0.0, 0.45)
	var segment_length: float = TAU * radius / float(segments)

	for index: int in range(segments):
		var angle: float = TAU * float(index) / float(segments)
		var position: Vector3 = Vector3(center.x + cos(angle) * radius, center.y, center.z + sin(angle) * radius)
		var segment: MeshInstance3D = _create_box("%sSegment" % node_name, Vector3(segment_length, 0.025, thickness), position)
		segment.rotation.y = -angle
		segment.material_override = material
		world.add_child(segment)

func _create_box(node_name: String, size: Vector3, position: Vector3) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	return mesh_instance

func _create_cylinder(node_name: String, radius: float, height: float, position: Vector3) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	return mesh_instance

func _make_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
