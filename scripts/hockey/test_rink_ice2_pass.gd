extends "res://scripts/hockey/test_rink_3v3_pass.gd"

# Puck King Arena v1 presentation and authoritative match integration.
# This active scene intentionally extends the stable 3v3 layer directly.
# Physical rink and net interaction remain in RinkGeometry plus the net-play
# player, puck, winger, and goalie controller wrappers assigned by TestRink.tscn.

const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")
const ICE2_TEXTURE_PATH: String = "res://assets/art/rink/pkh_ice2.png"

func _ready() -> void:
	super._ready()
	world.scale = Vector3.ONE
	_configure_goalies_from_spec()
	_run_arena_alignment_checks()

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = RinkGeometry.CAMERA_ORTHO_SIZE
	camera.global_position = RinkGeometry.CAMERA_POSITION
	camera.look_at(RinkGeometry.CAMERA_LOOK_TARGET, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null or _goal_lockout:
		return
	if _puck.has_method("is_possessed") and bool(_puck.call("is_possessed")):
		return

	var current: Vector3 = _puck.global_position
	var previous: Vector3 = current
	if _puck.has_method("get_previous_position"):
		previous = _puck.call("get_previous_position")

	var velocity: Vector3 = Vector3.ZERO
	if _puck.has_method("get_velocity"):
		velocity = _puck.call("get_velocity")

	var scoring_team: String = RinkGeometry.legal_goal_crossing(previous, current, velocity)
	if scoring_team != "":
		_register_goal(scoring_team)

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

func _configure_goalies_from_spec() -> void:
	for goalie: Node3D in [_home_goalie, _away_goalie]:
		if goalie == null:
			continue
		goalie.set("guard_distance_from_center", RinkGeometry.GOALIE_GUARD_X)
		goalie.set("crease_half_width", RinkGeometry.GOALIE_CREASE_HALF_WIDTH)
		if goalie.has_method("reset_to_center"):
			goalie.call("reset_to_center")

func _create_floor_backdrop() -> void:
	var floor: MeshInstance3D = _create_box(
		"DarkArenaFloor",
		Vector3(RinkGeometry.ART_LENGTH + 5.0, 0.08, RinkGeometry.ART_WIDTH + 5.0),
		Vector3.ZERO
	)
	floor.position.y = -0.08
	floor.material_override = _make_material(Color(0.025, 0.028, 0.032, 1.0), 0.0, 0.82)
	world.add_child(floor)

func _create_ice_surface() -> void:
	var base_ice: MeshInstance3D = _create_box(
		"ArenaV1IceBase",
		Vector3(RinkGeometry.LENGTH, ICE_THICKNESS, RinkGeometry.WIDTH),
		Vector3.ZERO
	)
	base_ice.material_override = _make_material(Color(0.84, 0.95, 1.0, 1.0), 0.0, 0.22)
	world.add_child(base_ice)

	if not ResourceLoader.exists(ICE2_TEXTURE_PATH):
		push_error("Arena artwork missing: %s" % ICE2_TEXTURE_PATH)
		return
	var texture: Texture2D = load(ICE2_TEXTURE_PATH) as Texture2D
	if texture == null:
		push_error("Arena artwork failed to load: %s" % ICE2_TEXTURE_PATH)
		return

	var arena_quad: MeshInstance3D = MeshInstance3D.new()
	arena_quad.name = "PuckKingArenaV1Artwork"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(RinkGeometry.ART_LENGTH, RinkGeometry.ART_WIDTH)
	arena_quad.mesh = quad
	arena_quad.position = Vector3(0.0, RinkGeometry.ART_Y, 0.0)
	arena_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	arena_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena_quad.material_override = _make_ice_texture_plane_material(texture)
	world.add_child(arena_quad)

# These visuals are baked into pkh_ice2.png.
func _create_ice_surface_details() -> void:
	pass

func _create_zone_tints() -> void:
	pass

func _create_rink_lines() -> void:
	pass

func _create_faceoff_markings() -> void:
	pass

func _create_boards() -> void:
	pass

func _create_glass_posts() -> void:
	pass

func _create_goals() -> void:
	pass

func _has_ice_texture() -> bool:
	return ResourceLoader.exists(ICE2_TEXTURE_PATH)

func _load_ice_texture() -> Texture2D:
	if not ResourceLoader.exists(ICE2_TEXTURE_PATH):
		return null
	return load(ICE2_TEXTURE_PATH) as Texture2D

func _run_arena_alignment_checks() -> void:
	var issues: PackedStringArray = RinkGeometry.validate_spec()
	for issue: String in issues:
		push_warning("Arena Specification v1: %s" % issue)
	if issues.is_empty():
		print("Arena Specification v1 validated: gameplay, artwork, goals, and camera share one definition.")
