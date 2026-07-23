extends "res://scripts/hockey/test_rink_3v3_pass.gd"

const RinkGeometry = preload("res://scripts/hockey/rink_geometry.gd")

var _last_probe_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	world.scale = Vector3.ONE
	_configure_goalies_from_spec()
	if _puck != null:
		_last_probe_position = _puck.global_position

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = RinkGeometry.CAMERA_ORTHO_SIZE
	camera.global_position = RinkGeometry.CAMERA_POSITION
	camera.look_at(RinkGeometry.CAMERA_LOOK_TARGET, Vector3.UP)

func _configure_goalies_from_spec() -> void:
	_configure_goalie(_home_goalie)
	_configure_goalie(_away_goalie)

func _configure_goalie(goalie: Node3D) -> void:
	if goalie == null:
		return
	goalie.set("guard_distance_from_center", RinkGeometry.GOALIE_GUARD_X)
	goalie.set("crease_half_width", RinkGeometry.GOALIE_CREASE_HALF_WIDTH)
	if goalie.has_method("reset_to_center"):
		goalie.call("reset_to_center")

func _check_goal_state() -> void:
	if _puck == null or _goal_lockout:
		return

	var current: Vector3 = _puck.global_position
	var previous: Vector3 = current
	if _puck.has_method("get_previous_position"):
		previous = _puck.call("get_previous_position") as Vector3

	var velocity: Vector3 = Vector3.ZERO
	if _puck.has_method("get_velocity"):
		velocity = _puck.call("get_velocity") as Vector3

	if _puck.has_method("is_possessed") and bool(_puck.call("is_possessed")):
		_last_probe_position = current
		return

	var scoring_team: String = RinkGeometry.legal_goal_crossing(previous, current, velocity)
	if not scoring_team.is_empty():
		_register_goal(scoring_team)
	_last_probe_position = current

func _reset_faceoff(clear_puck: bool) -> void:
	super._reset_faceoff(clear_puck)
	_reset_arena_actor(_player, RinkGeometry.HOME_CENTER_START, Vector3.RIGHT)
	_reset_arena_actor(_away_skater, RinkGeometry.AWAY_CENTER_START, Vector3.LEFT)
	_reset_arena_actor(_home_teammate, RinkGeometry.HOME_LEFT_WING_START, Vector3.RIGHT)
	_reset_arena_actor(_home_winger2, RinkGeometry.HOME_RIGHT_WING_START, Vector3.RIGHT)
	_reset_arena_actor(_away_teammate, RinkGeometry.AWAY_LEFT_WING_START, Vector3.LEFT)
	_reset_arena_actor(_away_winger2, RinkGeometry.AWAY_RIGHT_WING_START, Vector3.LEFT)
	if clear_puck and _puck != null:
		_puck.global_position = RinkGeometry.CENTER_SPAWN
	_configure_goalies_from_spec()

func _reset_arena_actor(actor: Node3D, spawn_position: Vector3, facing: Vector3) -> void:
	if actor == null:
		return
	actor.global_position = spawn_position
	actor.set("_move_velocity", Vector3.ZERO)
	actor.set("_last_facing_direction", facing)
	actor.set("_stun_timer", 0.0)
	actor.set("_shoot_cooldown_timer", 0.0)
