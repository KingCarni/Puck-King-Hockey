extends "res://scripts/hockey/test_rink_art_pass.gd"

# Puck King Arena v1 visual pass.
#
# pkh_ice2.png contains the complete arena presentation (ice, markings,
# boards, glass, benches, and visible goals), so this layer replaces the old
# procedural visual rink while leaving gameplay collision and scoring in the
# shared geometry scripts.

const ICE2_TEXTURE_PATH: String = "res://assets/art/rink/pkh_ice2.png"
const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")

# The source image is 1792x1024 (1.75:1). Keep its aspect ratio so the artwork
# is never stretched, while sizing its playable interior around the current
# 48.8 x 23.6 arena specification. These values can be tuned from screenshots
# without touching gameplay physics.
const ICE2_ART_LENGTH: float = 55.0
const ICE2_ART_WIDTH: float = ICE2_ART_LENGTH * 1024.0 / 1792.0
const ICE2_Y: float = 0.086

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 36.5
	camera.global_position = Vector3(0.0, 31.5, 28.5)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _create_floor_backdrop() -> void:
	var floor: MeshInstance3D = _create_box(
		"DarkArenaFloor",
		Vector3(ICE2_ART_LENGTH + 5.0, 0.08, ICE2_ART_WIDTH + 5.0),
		Vector3.ZERO
	)
	floor.position.y = -0.08
	floor.material_override = _make_material(Color(0.025, 0.028, 0.032, 1.0), 0.0, 0.82)
	world.add_child(floor)

func _create_ice_surface() -> void:
	# A subtle physical ice slab underneath the complete arena image prevents
	# transparent edge pixels from exposing the dark floor.
	var base_ice: MeshInstance3D = _create_box(
		"Ice2SurfaceBase",
		Vector3(RinkGeometry.HALF_LENGTH * 2.0, ICE_THICKNESS, RinkGeometry.HALF_WIDTH * 2.0),
		Vector3.ZERO
	)
	base_ice.material_override = _make_material(Color(0.84, 0.95, 1.0, 1.0), 0.0, 0.22)
	world.add_child(base_ice)

	if not ResourceLoader.exists(ICE2_TEXTURE_PATH):
		push_warning("Arena artwork missing: %s" % ICE2_TEXTURE_PATH)
		return

	var texture: Texture2D = load(ICE2_TEXTURE_PATH) as Texture2D
	if texture == null:
		push_warning("Arena artwork failed to load: %s" % ICE2_TEXTURE_PATH)
		return

	var arena_quad: MeshInstance3D = MeshInstance3D.new()
	arena_quad.name = "PuckKingArenaV1Artwork"
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(ICE2_ART_LENGTH, ICE2_ART_WIDTH)
	arena_quad.mesh = quad
	arena_quad.position = Vector3(0.0, ICE2_Y, 0.0)
	arena_quad.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	arena_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena_quad.material_override = _make_ice_texture_plane_material(texture)
	world.add_child(arena_quad)

func _create_ice_surface_details() -> void:
	# All markings, ice scratches, branding, benches, and perimeter presentation
	# are already baked into pkh_ice2.png.
	pass

func _create_zone_tints() -> void:
	pass

func _create_rink_lines() -> void:
	pass

func _create_faceoff_markings() -> void:
	pass

func _create_boards() -> void:
	# Visual boards are baked into the arena asset. Gameplay bounds are handled
	# by RinkGeometry and the player/puck wrappers.
	pass

func _create_glass_posts() -> void:
	pass

func _create_goals() -> void:
	# The visible goals are baked into the new artwork. Physical net interaction
	# remains authoritative in RinkGeometry.resolve_net_body().
	pass

func _has_ice_texture() -> bool:
	return ResourceLoader.exists(ICE2_TEXTURE_PATH)

func _load_ice_texture() -> Texture2D:
	if not ResourceLoader.exists(ICE2_TEXTURE_PATH):
		return null
	return load(ICE2_TEXTURE_PATH) as Texture2D
