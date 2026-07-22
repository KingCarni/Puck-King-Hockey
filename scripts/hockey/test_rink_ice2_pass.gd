extends "res://scripts/hockey/test_rink_net_play_pass.gd"

# Puck King Arena v1 presentation.
# pkh_ice2.png contains the complete visible arena. Gameplay bounds, scoring,
# net collision, reset anchors, and camera values come from RinkGeometry.

const ICE2_TEXTURE_PATH: String = "res://assets/art/rink/pkh_ice2.png"

func _ready() -> void:
	super._ready()
	_hide_debug_geometry()
	_run_arena_alignment_checks()

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = RinkGeometry.CAMERA_ORTHO_SIZE
	camera.global_position = RinkGeometry.CAMERA_POSITION
	camera.look_at(RinkGeometry.CAMERA_LOOK_TARGET, Vector3.UP)

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
	# Keep a physical-looking ice slab directly under the playable area so any
	# transparent pixels around the arena artwork never expose the dark floor.
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

# The following presentation is baked into pkh_ice2.png. The authoritative
# physical boards and nets remain in RinkGeometry and the net-play wrappers.
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

func _hide_debug_geometry() -> void:
	var overlay: Node3D = get_node_or_null("NetPlayGeometry") as Node3D
	if overlay != null:
		overlay.visible = false

func _run_arena_alignment_checks() -> void:
	var issues: PackedStringArray = RinkGeometry.validate_spec()
	for issue: String in issues:
		push_warning("Arena Specification v1: %s" % issue)
	if issues.is_empty():
		print("Arena Specification v1 validated: gameplay, artwork, goals, and camera share one definition.")
