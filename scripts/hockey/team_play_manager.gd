extends Node

signal controlled_player_changed(player: Node3D)
signal pass_target_changed(player: Node3D)
signal call_acknowledged(player: Node3D)

const HumanInputSource: GDScript = preload("res://scripts/hockey/input/human_input_source.gd")
const AiCenterInputSource: GDScript = preload("res://scripts/hockey/input/ai_center_input_source.gd")

@export var switch_cooldown: float = 0.25
@export var call_cooldown: float = 0.65
@export var lane_clearance: float = 0.95

var puck: Node = null
var control_side: String = "HOME"
var home_players: Array[Node3D] = []
var away_players: Array[Node3D] = []
var controlled_player: Node3D = null
var pass_target: Node3D = null
var _switch_timer: float = 0.0
var _call_timer: float = 0.0
var _last_owner: Node3D = null

func setup(puck_node: Node, home: Array[Node3D], away: Array[Node3D], side: String) -> void:
	puck = puck_node
	home_players = home
	away_players = away
	set_control_side(side)

func _process(delta: float) -> void:
	_switch_timer = maxf(_switch_timer - delta, 0.0)
	_call_timer = maxf(_call_timer - delta, 0.0)
	var owner: Node3D = _get_puck_owner()
	if owner != _last_owner:
		_last_owner = owner
		if owner != null and owner in _controlled_team():
			_set_controlled_player(owner)
	if controlled_player == null:
		return
	var prefix: String = "p1" if control_side == "HOME" else "p2"
	if Input.is_action_just_pressed(prefix + "_switch") and _switch_timer <= 0.0:
		switch_to_closest_to_puck()
		_switch_timer = switch_cooldown
	_update_pass_target(prefix)

func set_control_side(side: String) -> void:
	control_side = side
	controlled_player = null
	var team: Array[Node3D] = _controlled_team()
	if not team.is_empty():
		_set_controlled_player(team[0])

func switch_to_closest_to_puck() -> void:
	var team: Array[Node3D] = _controlled_team()
	if team.is_empty() or puck == null:
		return
	var puck_node: Node3D = puck as Node3D
	var best: Node3D = team[0]
	var best_distance: float = INF
	for player: Node3D in team:
		if player == null:
			continue
		var distance: float = player.global_position.distance_squared_to(puck_node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = player
	_set_controlled_player(best)

func request_pass(requester: Node3D) -> bool:
	if _call_timer > 0.0 or puck == null:
		return false
	var owner: Node3D = _get_puck_owner()
	if owner == null or owner == requester or not owner in _controlled_team():
		return false
	if not _lane_clear(owner.global_position, requester.global_position):
		return false
	var velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = requester.get("_move_velocity")
	if raw_velocity is Vector3:
		velocity = raw_velocity
	# The current carrier makes the pass, so their attributes shape it.
	var lead_time: float = lerpf(0.16, 0.46, _attribute_of(owner, &"pass_lead", 0.5))
	var lead: Vector3 = requester.global_position + velocity * lead_time
	var direction: Vector3 = lead - owner.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return false
	var pass_speed: float = 0.38 * lerpf(0.82, 1.22, _attribute_of(owner, &"pass_power", 0.5))
	puck.call("shoot", direction.normalized(), Vector3.ZERO, pass_speed)
	if puck.has_method("set_receiver_priority"):
		puck.call("set_receiver_priority", requester, owner, lerpf(0.25, 0.60, _attribute_of(owner, &"pass_assist", 0.5)))
	_call_timer = call_cooldown
	emit_signal("call_acknowledged", owner)
	return true

# Passing is assisted, scaled by the passer's attributes:
#   pass_assist   — how reliably a receiver is acquired off-axis from raw aim
#   pass_accuracy — how strongly the pass direction corrects onto the receiver
#   pass_lead     — how well the pass leads a moving receiver
#   pass_power    — pass speed
# A low-passing skater mostly shoots where they aim; a playmaker finds tape.
func choose_pass_target(from_player: Node3D, aim: Vector3) -> Node3D:
	var candidates: Array[Node3D] = _controlled_team()
	var best: Node3D = null
	var best_score: float = -INF
	var facing: Vector3 = aim.normalized() if aim.length_squared() > 0.01 else Vector3.RIGHT
	var assist: float = _attribute_of(from_player, &"pass_assist", 0.5)
	# Low assist demands aiming nearly at the receiver; high assist widens the
	# acquisition cone. Raw aim always matters — the cone never goes behind.
	var minimum_dot: float = lerpf(0.55, 0.05, clampf(assist, 0.0, 1.0))
	for candidate: Node3D in candidates:
		if candidate == null or candidate == from_player:
			continue
		var delta: Vector3 = candidate.global_position - from_player.global_position
		delta.y = 0.0
		if delta.length_squared() < 0.01:
			continue
		var aim_dot: float = facing.dot(delta.normalized())
		if aim_dot < minimum_dot:
			continue
		var score: float = aim_dot * lerpf(1.8, 3.4, assist) - delta.length() * lerpf(0.055, 0.020, assist)
		if _lane_clear(from_player.global_position, candidate.global_position):
			score += lerpf(0.0, 0.9, assist)
		if score > best_score:
			best_score = score
			best = candidate
	return best

func execute_pass(from_player: Node3D, aim: Vector3, charge: float) -> bool:
	if puck == null or not bool(puck.call("is_possessed_by", from_player)):
		return false
	var clamped_charge: float = clampf(charge, 0.0, 1.0)
	var raw_aim: Vector3 = Vector3(aim.x, 0.0, aim.z)
	raw_aim = raw_aim.normalized() if raw_aim.length_squared() > 0.001 else Vector3.RIGHT
	var power_attribute: float = _attribute_of(from_player, &"pass_power", 0.5)
	var pass_speed: float = lerpf(0.22, 0.58, clamped_charge) * lerpf(0.82, 1.22, power_attribute)
	var target: Node3D = choose_pass_target(from_player, aim)
	if target == null:
		# No receiver in the cone: the pass follows the raw aim ("hope pass").
		puck.call("shoot", raw_aim, Vector3.ZERO, pass_speed * 0.9)
		return true
	var lead_attribute: float = _attribute_of(from_player, &"pass_lead", 0.5)
	var target_velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = target.get("_move_velocity")
	if raw_velocity is Vector3:
		target_velocity = raw_velocity
	var lead_time: float = lerpf(0.08, 0.50, lead_attribute) * lerpf(0.65, 1.0, clamped_charge)
	var lead: Vector3 = target.global_position + target_velocity * lead_time
	var to_receiver: Vector3 = lead - from_player.global_position
	to_receiver.y = 0.0
	if to_receiver.length_squared() < 0.001:
		return false
	to_receiver = to_receiver.normalized()
	# Blend raw stick aim toward the receiver: accuracy decides how much the
	# pass corrects onto the tape versus following the player's input.
	var accuracy: float = _attribute_of(from_player, &"pass_accuracy", 0.5)
	var correction: float = lerpf(0.35, 0.95, accuracy)
	var direction: Vector3 = raw_aim.lerp(to_receiver, correction)
	if direction.length_squared() < 0.001:
		direction = to_receiver
	puck.call("shoot", direction.normalized(), Vector3.ZERO, pass_speed)
	if puck.has_method("set_receiver_priority"):
		var assist: float = _attribute_of(from_player, &"pass_assist", 0.5)
		puck.call("set_receiver_priority", target, from_player, lerpf(0.25, 0.60, assist))
	return true

func _set_controlled_player(player: Node3D) -> void:
	if player == null or player == controlled_player:
		return
	var prefix: String = "p1" if control_side == "HOME" else "p2"
	for teammate: Node3D in _controlled_team():
		if teammate == null:
			continue
		if teammate == player:
			if teammate.has_method("set_human_control"):
				teammate.call("set_human_control", HumanInputSource.new(prefix), self)
			elif teammate.has_method("set_input_source"):
				teammate.call("set_input_source", HumanInputSource.new(prefix))
		else:
			if teammate.has_method("set_ai_control"):
				teammate.call("set_ai_control")
			elif teammate.has_method("set_input_source"):
				var ai: RefCounted = AiCenterInputSource.new()
				var direction: float = 1.0 if control_side == "HOME" else -1.0
				ai.call("setup", teammate, puck, direction)
				teammate.call("set_input_source", ai)
	controlled_player = player
	emit_signal("controlled_player_changed", controlled_player)

func _update_pass_target(prefix: String) -> void:
	var new_target: Node3D = null
	if Input.is_action_pressed(prefix + "_pass") and controlled_player != null:
		var raw_facing: Variant = controlled_player.get("_last_facing_direction")
		var facing: Vector3 = raw_facing if raw_facing is Vector3 else Vector3.RIGHT
		new_target = choose_pass_target(controlled_player, facing)
	if new_target != pass_target:
		pass_target = new_target
		emit_signal("pass_target_changed", pass_target)

func _get_puck_owner() -> Node3D:
	if puck == null:
		return null
	var possessed: Variant = puck.get("_is_possessed")
	if not (possessed is bool) or not bool(possessed):
		return null
	var owner: Variant = puck.get("_owner")
	return owner as Node3D if owner is Node3D else null

## Reads a runtime attribute off a skater (roster stat layer), falling back
## to the league-average default for unmigrated controllers.
func _attribute_of(player: Node3D, attribute_id: StringName, default_value: float) -> float:
	if player != null and player.has_method("get_runtime_attribute"):
		return float(player.call("get_runtime_attribute", attribute_id, default_value))
	return default_value

func _controlled_team() -> Array[Node3D]:
	if control_side == "HOME":
		return home_players
	return away_players

func _opponents() -> Array[Node3D]:
	if control_side == "HOME":
		return away_players
	return home_players

func _lane_clear(from_position: Vector3, to_position: Vector3) -> bool:
	for opponent: Node3D in _opponents():
		if opponent == null:
			continue
		if _point_to_segment_distance(opponent.global_position, from_position, to_position) < lane_clearance:
			return false
	return true

func _point_to_segment_distance(point: Vector3, a: Vector3, b: Vector3) -> float:
	var p: Vector2 = Vector2(point.x, point.z)
	var av: Vector2 = Vector2(a.x, a.z)
	var bv: Vector2 = Vector2(b.x, b.z)
	var segment: Vector2 = bv - av
	if segment.length_squared() <= 0.0001:
		return p.distance_to(av)
	var t: float = clampf((p - av).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return p.distance_to(av + segment * t)
