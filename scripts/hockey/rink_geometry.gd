extends RefCounted

# Single source of truth for the expanded arcade rink and net geometry.
const HALF_LENGTH: float = 24.4
const HALF_WIDTH: float = 11.8
const CORNER_RADIUS: float = 4.0
const STRAIGHT_HALF_LENGTH: float = HALF_LENGTH - CORNER_RADIUS
const STRAIGHT_HALF_WIDTH: float = HALF_WIDTH - CORNER_RADIUS

const GOAL_LINE_X: float = 20.65
const GOAL_HALF_WIDTH: float = 1.55
const GOAL_DEPTH: float = 2.25
const POST_RADIUS: float = 0.30
const NET_FRAME_RADIUS: float = 0.28
const PLAYER_NET_CLEARANCE: float = 0.62
const PUCK_NET_CLEARANCE: float = 0.20

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

		# Back frame: blocks entry from behind and rebounds toward open ice.
		if absf(point.z) <= GOAL_HALF_WIDTH + clearance and _crossed_plane(previous.x, point.x, back_x):
			point.x = back_x + outward * clearance
			result = {"position": point, "normal": Vector3(outward, 0.0, 0.0), "hit": true}
			return result

		# Side frames run from the mouth to the back of the net.
		var min_x: float = minf(mouth_x, back_x) - clearance
		var max_x: float = maxf(mouth_x, back_x) + clearance
		if point.x >= min_x and point.x <= max_x:
			for rail_z: float in [-GOAL_HALF_WIDTH, GOAL_HALF_WIDTH]:
				var dz: float = point.z - rail_z
				if absf(dz) < clearance + NET_FRAME_RADIUS:
					point.z = rail_z + signf(dz if absf(dz) > 0.001 else previous.z - rail_z) * (clearance + NET_FRAME_RADIUS)
					result = {"position": point, "normal": Vector3(0.0, 0.0, signf(point.z - rail_z)), "hit": true}
					return result

		# Posts are circular and leave the front mouth open between them.
		for post_z: float in [-GOAL_HALF_WIDTH, GOAL_HALF_WIDTH]:
			var post: Vector2 = Vector2(mouth_x, post_z)
			var delta: Vector2 = Vector2(point.x, point.z) - post
			var radius: float = POST_RADIUS + clearance
			if delta.length() < radius:
				var normal2: Vector2 = delta.normalized() if delta.length_squared() > 0.0001 else Vector2(-outward, 0.0)
				point.x = post.x + normal2.x * radius
				point.z = post.y + normal2.y * radius
				result = {"position": point, "normal": Vector3(normal2.x, 0.0, normal2.y), "hit": true}
				return result
	result["position"] = point
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

static func _crossed_plane(previous_value: float, current_value: float, plane: float) -> bool:
	return (previous_value - plane) * (current_value - plane) <= 0.0
