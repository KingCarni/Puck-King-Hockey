extends RefCounted

# Puck King Arena Specification v1.
#
# This is the single source of truth for gameplay bounds, net geometry,
# markings, reset anchors, camera framing, and the pkh_ice2 presentation.
# Gameplay and visuals must reference this file instead of introducing local
# rink coordinates.

# Playable rounded rink outline.
const HALF_LENGTH: float = 24.4
const HALF_WIDTH: float = 11.8
const LENGTH: float = HALF_LENGTH * 2.0
const WIDTH: float = HALF_WIDTH * 2.0
const CORNER_RADIUS: float = 4.0
const STRAIGHT_HALF_LENGTH: float = HALF_LENGTH - CORNER_RADIUS
const STRAIGHT_HALF_WIDTH: float = HALF_WIDTH - CORNER_RADIUS

# Net and scoring geometry.
const GOAL_LINE_X: float = 20.65
const GOAL_HALF_WIDTH: float = 1.55
const GOAL_WIDTH: float = GOAL_HALF_WIDTH * 2.0
const GOAL_DEPTH: float = 2.25
const BEHIND_NET_DEPTH: float = HALF_LENGTH - GOAL_LINE_X
const POST_RADIUS: float = 0.30
const NET_FRAME_RADIUS: float = 0.28
const PLAYER_NET_CLEARANCE: float = 0.62
const PUCK_NET_CLEARANCE: float = 0.20
const GOALIE_GUARD_X: float = GOAL_LINE_X - 0.75
const GOALIE_CREASE_HALF_WIDTH: float = 2.30

# Rink markings and gameplay anchors.
const BLUE_LINE_X: float = 8.15
const FACEOFF_DOT_X: float = 13.25
const FACEOFF_DOT_Z: float = 5.45
const CENTER_SPAWN: Vector3 = Vector3(0.0, 0.18, 0.0)
const HOME_CENTER_START: Vector3 = Vector3(-8.4, 0.72, -1.9)
const AWAY_CENTER_START: Vector3 = Vector3(8.4, 0.72, 1.9)
const HOME_LEFT_WING_START: Vector3 = Vector3(-8.2, 0.72, -3.7)
const HOME_RIGHT_WING_START: Vector3 = Vector3(-11.0, 0.72, 4.8)
const AWAY_LEFT_WING_START: Vector3 = Vector3(8.2, 0.72, -3.7)
const AWAY_RIGHT_WING_START: Vector3 = Vector3(11.0, 0.72, 4.8)

# pkh_ice2.png presentation. The image contains the full arena, while the
# playable ice occupies a centered subset. These values preserve the source
# image aspect ratio and align its playable interior to LENGTH x WIDTH.
const ART_SOURCE_WIDTH: float = 1792.0
const ART_SOURCE_HEIGHT: float = 1024.0
const ART_PLAYABLE_FRACTION_X: float = 0.89
const ART_PLAYABLE_FRACTION_Z: float = 0.753
const ART_LENGTH: float = LENGTH / ART_PLAYABLE_FRACTION_X
const ART_WIDTH: float = ART_LENGTH * ART_SOURCE_HEIGHT / ART_SOURCE_WIDTH
const ART_Y: float = 0.086
const PRESENTATION_MARGIN: float = 2.35

# Camera values are derived from arena size rather than the retired texture.
const CAMERA_ORTHO_SIZE: float = ART_WIDTH + PRESENTATION_MARGIN * 2.0
const CAMERA_POSITION: Vector3 = Vector3(0.0, 32.5, 29.2)
const CAMERA_LOOK_TARGET: Vector3 = Vector3.ZERO

static func clamp_to_rink(point: Vector3, margin: float = 0.0) -> Vector3:
	var half_length: float = HALF_LENGTH - margin
	var half_width: float = HALF_WIDTH - margin
	var radius: float = maxf(CORNER_RADIUS - margin, 0.25)
	var straight_x: float = half_length - radius
	var straight_z: float = half_width - radius
	point.x = clampf(point.x, -half_length, half_length)
	point.z = clampf(point.z, -half_width, half_width)
	var abs_x: float = absf(point.x)
	var abs_z: float = absf(point.z)
	if abs_x > straight_x and abs_z > straight_z:
		var center: Vector2 = Vector2(signf(point.x) * straight_x, signf(point.z) * straight_z)
		var delta: Vector2 = Vector2(point.x, point.z) - center
		if delta.length() > radius:
			delta = delta.normalized() * radius
			point.x = center.x + delta.x
			point.z = center.y + delta.y
	return point

static func resolve_net_body(point: Vector3, previous: Vector3, clearance: float) -> Dictionary:
	var result: Dictionary = {"position": point, "normal": Vector3.ZERO, "hit": false}
	for side: float in [-1.0, 1.0]:
		var mouth_x: float = side * GOAL_LINE_X
		var back_x: float = side * (GOAL_LINE_X + GOAL_DEPTH)
		var outward: float = side

		# Back frame blocks entry from behind and rebounds toward open ice.
		if absf(point.z) <= GOAL_HALF_WIDTH + clearance and _crossed_plane(previous.x, point.x, back_x):
			point.x = back_x + outward * clearance
			return {"position": point, "normal": Vector3(outward, 0.0, 0.0), "hit": true}

		# Side frames run from the mouth to the back of the net.
		var min_x: float = minf(mouth_x, back_x) - clearance
		var max_x: float = maxf(mouth_x, back_x) + clearance
		if point.x >= min_x and point.x <= max_x:
			for rail_z: float in [-GOAL_HALF_WIDTH, GOAL_HALF_WIDTH]:
				var dz: float = point.z - rail_z
				if absf(dz) < clearance + NET_FRAME_RADIUS:
					var fallback: float = previous.z - rail_z
					var push_sign: float = signf(dz if absf(dz) > 0.001 else fallback)
					if is_zero_approx(push_sign):
						push_sign = 1.0
					point.z = rail_z + push_sign * (clearance + NET_FRAME_RADIUS)
					return {"position": point, "normal": Vector3(0.0, 0.0, push_sign), "hit": true}

		# Circular posts leave the front mouth open between them.
		for post_z: float in [-GOAL_HALF_WIDTH, GOAL_HALF_WIDTH]:
			var post: Vector2 = Vector2(mouth_x, post_z)
			var delta: Vector2 = Vector2(point.x, point.z) - post
			var radius: float = POST_RADIUS + clearance
			if delta.length() < radius:
				var normal2: Vector2 = delta.normalized() if delta.length_squared() > 0.0001 else Vector2(-outward, 0.0)
				point.x = post.x + normal2.x * radius
				point.z = post.y + normal2.y * radius
				return {"position": point, "normal": Vector3(normal2.x, 0.0, normal2.y), "hit": true}
	return result

static func legal_goal_crossing(previous: Vector3, current: Vector3, velocity: Vector3) -> String:
	if absf(current.z) > GOAL_HALF_WIDTH - POST_RADIUS:
		return ""
	if previous.x < GOAL_LINE_X and current.x >= GOAL_LINE_X and velocity.x > 0.25:
		return "HOME"
	if previous.x > -GOAL_LINE_X and current.x <= -GOAL_LINE_X and velocity.x < -0.25:
		return "AWAY"
	return ""

static func is_behind_net(point: Vector3) -> bool:
	return absf(point.x) > GOAL_LINE_X + 0.25

static func wrap_target(attack_direction: float, current_z: float) -> Vector3:
	var side_z: float = -signf(current_z) * (GOAL_HALF_WIDTH + 0.85)
	if absf(current_z) < 0.2:
		side_z = GOAL_HALF_WIDTH + 0.85
	return Vector3(attack_direction * (GOAL_LINE_X - 0.85), 0.72, side_z)

static func faceoff_spot(home_side: bool, upper: bool) -> Vector3:
	var x_sign: float = -1.0 if home_side else 1.0
	var z_sign: float = -1.0 if upper else 1.0
	return Vector3(x_sign * FACEOFF_DOT_X, 0.18, z_sign * FACEOFF_DOT_Z)

static func validate_spec() -> PackedStringArray:
	var issues: PackedStringArray = []
	if CORNER_RADIUS <= 0.0 or CORNER_RADIUS >= minf(HALF_LENGTH, HALF_WIDTH):
		issues.append("Corner radius is outside the legal rink range.")
	if GOAL_LINE_X + GOAL_DEPTH >= HALF_LENGTH:
		issues.append("Net back frame reaches or crosses the end boards.")
	if BEHIND_NET_DEPTH <= GOAL_DEPTH:
		issues.append("Behind-net lane is too shallow for the configured net depth.")
	if not is_equal_approx(ART_LENGTH * ART_PLAYABLE_FRACTION_X, LENGTH):
		issues.append("Arena artwork length no longer maps to playable length.")
	if absf(ART_WIDTH * ART_PLAYABLE_FRACTION_Z - WIDTH) > 0.05:
		issues.append("Arena artwork width no longer maps to playable width.")
	return issues

static func _crossed_plane(previous_value: float, current_value: float, plane: float) -> bool:
	return (previous_value - plane) * (current_value - plane) <= 0.0
