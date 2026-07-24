extends Node3D

# Winger AI 2.0 — "stop chasing the puck, start playing hockey."
#
# Roles per possession state:
#   I have the puck      → attack the net; shoot the far corner when open,
#                          pass back to my center when pressured.
#   My center has it     → support: one-timer spot deep, drift into open ice
#                          otherwise; never stack on the carrier.
#   The enemy has it     → if I'm the closest defender, pressure and poke;
#                          otherwise collapse into the slot and cut the
#                          passing lane. Sprint back on breakaways.
#   Loose puck           → chase only when I'm my team's closest skater,
#                          otherwise take defensive shade.

const SkaterSpriteVisuals: GDScript = preload("res://scripts/hockey/skater_sprite_visuals.gd")

const RINK_HALF_LENGTH: float = 22.0
const RINK_HALF_WIDTH: float = 10.8
const PLAYER_Y: float = 0.72
const PUCK_Y: float = 0.18
# World-space goal mouth (visual rink is scaled 1.14; see test_rink_gameplay_pass.gd).
const GOAL_MOUTH_X: float = 20.75
const GOAL_HALF_WIDTH: float = 1.8

## +1.0 attacks the +X net (home team), -1.0 attacks the -X net (away team).
@export var attack_direction: float = 1.0
@export var puck_path: NodePath = NodePath("../Puck")
@export var ally_center_path: NodePath = NodePath("")
@export var enemy_center_path: NodePath = NodePath("")
@export var enemy_winger_path: NodePath = NodePath("")
@export var enemy_goalie_path: NodePath = NodePath("")

@export var acceleration: float = 14.5
@export var sprint_acceleration: float = 20.0
@export var max_speed: float = 6.4
@export var sprint_max_speed: float = 7.9
@export var friction: float = 4.6
@export var turn_speed: float = 8.0
@export var board_bounce: float = 0.35
@export var puck_carry_distance: float = 1.0
@export var puck_carry_side_offset: float = 0.18
@export var shot_power: float = 0.80
@export var shoot_cooldown_seconds: float = 1.05
@export var pass_power: float = 0.30
@export var pass_cooldown_seconds: float = 1.30
@export var pressure_poke_force: float = 8.5
@export var stun_seconds: float = 0.65
@export var skater_texture_path: String = "res://assets/art/characters/pkh_skater_home_alt.svg"

var _move_velocity: Vector3 = Vector3.ZERO
var _last_facing_direction: Vector3 = Vector3.RIGHT
var _stun_timer: float = 0.0
var _knockdown_timer: float = 0.0
var _shoot_cooldown_timer: float = 0.0
var _pass_cooldown_timer: float = 0.0
var _poke_cooldown_timer: float = 0.0
var _drift_retarget_timer: float = 0.0
var _drift_target: Vector3 = Vector3.ZERO
var hits_delivered: int = 0

var _puck: Node = null
var _ally_center: Node3D = null
var _enemy_center: Node3D = null
var _enemy_winger: Node3D = null
var _enemy_goalie: Node3D = null

# Runtime stat layer (scripts/roster/player_runtime_stats.gd). The exported
# properties above are authored baselines and are never mutated by upgrades;
# when no stats object is attached (legacy scenes) baselines apply unchanged.
var _runtime_stats: RefCounted = null

var _base_material: StandardMaterial3D = null
var _stun_material: StandardMaterial3D = null
var _freeze_material: StandardMaterial3D = null
var _possession_material: StandardMaterial3D = null
var _is_frozen: bool = false

@onready var _visual_root: Node3D = $VisualRoot
@onready var _body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var _direction_marker: MeshInstance3D = get_node_or_null("VisualRoot/DirectionMarker") as MeshInstance3D

func _ready() -> void:
	_build_visuals()
	add_to_group("checkable")
	_puck = get_node_or_null(puck_path)
	_ally_center = get_node_or_null(ally_center_path) as Node3D
	_enemy_center = get_node_or_null(enemy_center_path) as Node3D
	_enemy_winger = get_node_or_null(enemy_winger_path) as Node3D
	_enemy_goalie = get_node_or_null(enemy_goalie_path) as Node3D
	_last_facing_direction = Vector3(attack_direction, 0.0, 0.0)

func set_runtime_stats(stats: RefCounted) -> void:
	_runtime_stats = stats

func get_runtime_stats() -> RefCounted:
	return _runtime_stats

func get_player_definition() -> Resource:
	if _runtime_stats == null:
		return null
	var definition: Variant = _runtime_stats.get("definition")
	return definition if definition is Resource else null

func get_runtime_stat(stat_id: StringName, node_base: float) -> float:
	if _runtime_stats != null and _runtime_stats.has_method("get_scaled"):
		return float(_runtime_stats.call("get_scaled", stat_id, node_base))
	return node_base

func get_runtime_attribute(attribute_id: StringName, default_value: float = 0.5) -> float:
	if _runtime_stats != null and _runtime_stats.has_method("get_attribute"):
		return float(_runtime_stats.call("get_attribute", attribute_id, default_value))
	return default_value

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if _stun_timer <= 0.0:
		_update_ai(delta)
	_update_movement(delta)
	_update_puck_interaction(delta)
	_update_visuals(delta)

func _update_timers(delta: float) -> void:
	_stun_timer = max(_stun_timer - delta, 0.0)
	_knockdown_timer = max(_knockdown_timer - delta, 0.0)
	_shoot_cooldown_timer = max(_shoot_cooldown_timer - delta, 0.0)
	_pass_cooldown_timer = max(_pass_cooldown_timer - delta, 0.0)
	_poke_cooldown_timer = max(_poke_cooldown_timer - delta, 0.0)
	_drift_retarget_timer = max(_drift_retarget_timer - delta, 0.0)
	if _stun_timer <= 0.0:
		_is_frozen = false

# ---------- decision layer ----------

func _update_ai(delta: float) -> void:
	if _puck == null:
		_apply_friction(delta)
		return

	if _possesses(self):
		_attack(delta)
	elif _ally_center != null and _possesses(_ally_center):
		_offense_support(delta)
	elif _enemy_carrier() != null:
		_defend(delta)
	else:
		_loose_puck(delta)

func _attack(delta: float) -> void:
	var net_x: float = attack_direction * GOAL_MOUTH_X
	var to_net: float = absf(net_x - global_position.x)
	var pressured: bool = _nearest_enemy_distance(global_position) < 2.1

	# Pass back to the center when pressured and the center is open.
	if pressured and _pass_cooldown_timer <= 0.0 and _ally_center != null:
		var center_open: bool = _nearest_enemy_distance(_ally_center.global_position) > 2.6
		if center_open and _lane_clear(global_position, _ally_center.global_position, 0.9):
			_pass_to(_ally_center)
			return

	var shot_range: float = 10.5 if not _on_breakaway() else 7.0
	if to_net < shot_range and _shoot_cooldown_timer <= 0.0:
		var aim: Vector3 = _pick_shot_target()
		var aim_direction: Vector3 = (aim - global_position).normalized()
		if _get_facing_direction().dot(aim_direction) > 0.45:
			_puck.call("shoot", aim_direction, _move_velocity, shot_power, get_runtime_attribute(&"shot_power_scale", 1.0))
			_shoot_cooldown_timer = shoot_cooldown_seconds
			return
		# Not lined up yet: curl toward the shooting angle.
		_skate_toward(global_position + aim_direction * 3.0, delta, true)
		return

	# Drive the net, favoring the side away from defenders.
	var drive_z: float = clampf(global_position.z * 0.5, -3.4, 3.4)
	_skate_toward(Vector3(net_x - attack_direction * 1.2, PLAYER_Y, drive_z), delta, _on_breakaway())

func _offense_support(delta: float) -> void:
	var carrier: Node3D = _ally_center
	var net_x: float = attack_direction * GOAL_MOUTH_X
	var carrier_deep: bool = absf(net_x - carrier.global_position.x) < 8.0

	if carrier_deep:
		# One-timer spot: level with the carrier, opposite side, facing the net.
		var side: float = -1.0 if _puck_position().z > 0.0 else 1.0
		var spot: Vector3 = Vector3(carrier.global_position.x + attack_direction * 1.0, PLAYER_Y, side * 3.1)
		_skate_toward(_clamp_to_play_area(spot), delta, false)
		return

	# Otherwise drift into open ice ahead of the play.
	if _drift_retarget_timer <= 0.0 or _drift_target == Vector3.ZERO:
		_drift_target = _find_open_ice(carrier)
		_drift_retarget_timer = 0.9
	_skate_toward(_drift_target, delta, false)

func _defend(delta: float) -> void:
	var carrier: Node3D = _enemy_carrier()
	var own_net: Vector3 = Vector3(-attack_direction * GOAL_MOUTH_X, PLAYER_Y, 0.0)

	if _is_breakaway_against_us(carrier):
		# Sprint to the spot between the carrier and our net.
		var intercept: Vector3 = carrier.global_position.lerp(own_net, 0.45)
		_skate_toward(intercept, delta, true)
		_try_poke(carrier)
		return

	if _i_am_closest_defender(carrier):
		_skate_toward(carrier.global_position, delta, true)
		_try_poke(carrier)
		return

	# Collapse toward the slot and cut the lane to the other threat.
	var slot: Vector3 = carrier.global_position.lerp(own_net, 0.55)
	slot.z = clampf(slot.z * 0.5, -3.5, 3.5)
	var other_threat: Node3D = _enemy_winger if carrier != _enemy_winger else _enemy_center
	if other_threat != null:
		var lane_mid: Vector3 = carrier.global_position.lerp(other_threat.global_position, 0.5)
		slot = slot.lerp(lane_mid, 0.30)
	_skate_toward(_clamp_to_play_area(slot), delta, false)

func _loose_puck(delta: float) -> void:
	var puck_position: Vector3 = _puck_position()
	var my_distance: float = _flat_distance(global_position, puck_position)
	var center_distance: float = INF
	if _ally_center != null:
		center_distance = _flat_distance(_ally_center.global_position, puck_position)

	if my_distance <= center_distance:
		var target: Vector3 = puck_position
		# Anti-bunching: shade off the center's chase line.
		if _ally_center != null and _flat_distance(global_position, _ally_center.global_position) < 2.2:
			target.z += 2.4 * signf(global_position.z - _ally_center.global_position.z + 0.01)
		_skate_toward(target, delta, my_distance < 6.0)
		return

	# Center takes it; play the defensive shade between the puck and our net.
	var own_net: Vector3 = Vector3(-attack_direction * GOAL_MOUTH_X, PLAYER_Y, 0.0)
	var shade: Vector3 = puck_position.lerp(own_net, 0.35)
	shade.z = clampf(shade.z, -RINK_HALF_WIDTH + 1.4, RINK_HALF_WIDTH - 1.4)
	_skate_toward(shade, delta, false)

# ---------- awareness helpers ----------

func _pick_shot_target() -> Vector3:
	var net_x: float = attack_direction * GOAL_MOUTH_X
	var corner_z: float = GOAL_HALF_WIDTH - 0.45
	# Shoot the corner away from the goalie.
	if _enemy_goalie != null:
		return Vector3(net_x, PUCK_Y, -signf(_enemy_goalie.global_position.z + 0.001) * corner_z)
	return Vector3(net_x, PUCK_Y, corner_z * (1.0 if randf() > 0.5 else -1.0))

func _on_breakaway() -> bool:
	# No enemy skater between me and the net I'm attacking.
	var net_x: float = attack_direction * GOAL_MOUTH_X
	for enemy: Node3D in _enemies():
		var ahead_of_me: bool = (net_x - enemy.global_position.x) * attack_direction > 0.0 \
			and (enemy.global_position.x - global_position.x) * attack_direction > 0.0
		if ahead_of_me and absf(enemy.global_position.z - global_position.z) < 4.0:
			return false
	return true

func _is_breakaway_against_us(carrier: Node3D) -> bool:
	var own_net_x: float = -attack_direction * GOAL_MOUTH_X
	var carrier_closer: bool = (own_net_x - carrier.global_position.x) * -attack_direction < (own_net_x - global_position.x) * -attack_direction
	if _ally_center != null:
		var center_back: bool = (own_net_x - _ally_center.global_position.x) * -attack_direction < (own_net_x - carrier.global_position.x) * -attack_direction
		if center_back:
			return false
	return carrier_closer

func _i_am_closest_defender(carrier: Node3D) -> bool:
	if _ally_center == null:
		return true
	var mine: float = _flat_distance(global_position, carrier.global_position)
	var centers: float = _flat_distance(_ally_center.global_position, carrier.global_position)
	return mine <= centers

func _find_open_ice(carrier: Node3D) -> Vector3:
	# Sample spots ahead of the carrier; keep the one farthest from defenders
	# without bunching on the carrier.
	var best: Vector3 = global_position
	var best_score: float = -INF
	for i: int in range(6):
		var forward: float = randf_range(2.5, 7.0)
		var lateral: float = randf_range(-6.0, 6.0)
		var candidate: Vector3 = carrier.global_position + Vector3(attack_direction * forward, 0.0, lateral)
		candidate = _clamp_to_play_area(candidate)
		var openness: float = _nearest_enemy_distance(candidate)
		var spacing: float = _flat_distance(candidate, carrier.global_position)
		if spacing < 2.6:
			continue
		var score: float = openness + minf(spacing, 6.0) * 0.35
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _lane_clear(from_position: Vector3, to_position: Vector3, clearance: float) -> bool:
	for enemy: Node3D in _enemies():
		if _point_to_segment_distance(enemy.global_position, from_position, to_position) < clearance:
			return false
	return true

func _try_poke(carrier: Node3D) -> void:
	if _poke_cooldown_timer > 0.0 or _puck == null:
		return
	if _flat_distance(global_position, carrier.global_position) > 1.9:
		return
	var poke_direction: Vector3 = (carrier.global_position - global_position)
	poke_direction.y = 0.0
	if _puck.has_method("poke_free"):
		_puck.call("poke_free", poke_direction.normalized(), pressure_poke_force)
		_poke_cooldown_timer = 0.8

func _pass_to(target: Node3D) -> void:
	var target_velocity: Vector3 = Vector3.ZERO
	var raw_velocity: Variant = target.get("_move_velocity")
	if raw_velocity is Vector3:
		target_velocity = raw_velocity
	var lead_time: float = lerpf(0.14, 0.42, get_runtime_attribute(&"pass_lead", 0.5))
	var lead: Vector3 = target.global_position + target_velocity * lead_time
	var direction: Vector3 = Vector3(lead.x - global_position.x, 0.0, lead.z - global_position.z)
	if direction.length_squared() <= 0.001:
		return
	var power_scale: float = lerpf(0.8, 1.2, get_runtime_attribute(&"pass_power", 0.5))
	_puck.call("shoot", direction.normalized(), _move_velocity, pass_power * power_scale)
	_pass_cooldown_timer = pass_cooldown_seconds

# ---------- movement + physics ----------

func _skate_toward(target_position: Vector3, delta: float, sprinting: bool) -> void:
	var flat_delta: Vector3 = Vector3(target_position.x - global_position.x, 0.0, target_position.z - global_position.z)
	if flat_delta.length_squared() <= 0.08:
		_apply_friction(delta)
		return
	var desired: Vector3 = flat_delta.normalized()
	var accel: float = get_runtime_stat(&"sprint_acceleration", sprint_acceleration) if sprinting else get_runtime_stat(&"acceleration", acceleration)
	var top: float = get_runtime_stat(&"sprint_max_speed", sprint_max_speed) if sprinting else get_runtime_stat(&"max_speed", max_speed)
	_move_velocity += desired * accel * delta
	_move_velocity = _move_velocity.limit_length(top)
	_last_facing_direction = desired

func _apply_friction(delta: float) -> void:
	_move_velocity = _move_velocity.move_toward(Vector3.ZERO, friction * delta)

func _update_movement(delta: float) -> void:
	global_position += _move_velocity * delta
	global_position.y = PLAYER_Y
	if _stun_timer > 0.0:
		_move_velocity = _move_velocity.move_toward(Vector3.ZERO, friction * 1.4 * delta)
	_apply_rink_bounds()

func _apply_rink_bounds() -> void:
	var clamped_x: float = clamp(global_position.x, -RINK_HALF_LENGTH, RINK_HALF_LENGTH)
	var clamped_z: float = clamp(global_position.z, -RINK_HALF_WIDTH, RINK_HALF_WIDTH)
	if not is_equal_approx(clamped_x, global_position.x):
		global_position.x = clamped_x
		_move_velocity.x = -_move_velocity.x * board_bounce
	if not is_equal_approx(clamped_z, global_position.z):
		global_position.z = clamped_z
		_move_velocity.z = -_move_velocity.z * board_bounce

func _update_puck_interaction(delta: float) -> void:
	if _puck == null:
		return
	if _stun_timer <= 0.0 and _puck.has_method("can_be_picked_up_by") and bool(_puck.call("can_be_picked_up_by", self)):
		_puck.call("take_possession", self)
	if _possesses(self):
		var carry: Vector3 = _get_puck_carry_position()
		_puck.call("update_possession", carry, _move_velocity, delta)

func receive_check(direction: Vector3, force: float, checker_velocity: Vector3, effects: Dictionary = {}) -> void:
	var hit_direction: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if hit_direction.length_squared() <= 0.001:
		hit_direction = Vector3.RIGHT
	_move_velocity = hit_direction.normalized() * force + Vector3(checker_velocity.x, 0.0, checker_velocity.z) * 0.22

	var freeze_seconds: float = float(effects.get("freeze", 0.0))
	if freeze_seconds > 0.0:
		_stun_timer = freeze_seconds
		_is_frozen = true
	else:
		_stun_timer = stun_seconds
		# Huge hits (or hits into the boards) knock the skater down spinning.
		var near_boards: bool = absf(global_position.z) > RINK_HALF_WIDTH - 1.3 or absf(global_position.x) > RINK_HALF_LENGTH - 1.3
		if force > 15.0 or near_boards:
			_stun_timer = 1.0 if force > 15.0 else 0.85
			_start_knockdown_spin()

	if _puck != null and _possesses(self) and _puck.has_method("poke_free"):
		_puck.call("poke_free", hit_direction.normalized(), force * 0.75)

func _start_knockdown_spin() -> void:
	_knockdown_timer = 0.8
	if _visual_root == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_visual_root, "rotation:y", _visual_root.rotation.y + TAU * 2.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func is_stunned() -> bool:
	return _stun_timer > 0.0

# ---------- shared helpers ----------

func _possesses(node: Node3D) -> bool:
	return _puck != null and _puck.has_method("is_possessed_by") and bool(_puck.call("is_possessed_by", node))

func _enemy_carrier() -> Node3D:
	for enemy: Node3D in _enemies():
		if _possesses(enemy):
			return enemy
	return null

func _enemies() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if _enemy_center != null:
		result.append(_enemy_center)
	if _enemy_winger != null:
		result.append(_enemy_winger)
	return result

func _nearest_enemy_distance(from_position: Vector3) -> float:
	var nearest: float = INF
	for enemy: Node3D in _enemies():
		nearest = minf(nearest, _flat_distance(from_position, enemy.global_position))
	return nearest

func _puck_position() -> Vector3:
	var puck_node: Node3D = _puck as Node3D
	return puck_node.global_position if puck_node != null else global_position

func _clamp_to_play_area(point: Vector3) -> Vector3:
	point.x = clampf(point.x, -GOAL_MOUTH_X + 0.8, GOAL_MOUTH_X - 0.8)
	point.z = clampf(point.z, -RINK_HALF_WIDTH + 1.3, RINK_HALF_WIDTH - 1.3)
	point.y = PLAYER_Y
	return point

func _get_puck_carry_position() -> Vector3:
	var facing: Vector3 = _get_facing_direction()
	var side: Vector3 = Vector3(facing.z, 0.0, -facing.x).normalized()
	var target: Vector3 = global_position + facing * get_runtime_stat(&"puck_carry_distance", puck_carry_distance) + side * puck_carry_side_offset
	target.y = PUCK_Y
	return target

func _get_facing_direction() -> Vector3:
	var facing: Vector3 = _move_velocity.normalized() if _move_velocity.length_squared() > 0.05 else _last_facing_direction
	if facing.length_squared() <= 0.0:
		return Vector3(attack_direction, 0.0, 0.0)
	return facing.normalized()

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector3(a.x - b.x, 0.0, a.z - b.z).length()

func _point_to_segment_distance(point: Vector3, a: Vector3, b: Vector3) -> float:
	var flat_point: Vector2 = Vector2(point.x, point.z)
	var flat_a: Vector2 = Vector2(a.x, a.z)
	var flat_b: Vector2 = Vector2(b.x, b.z)
	var segment: Vector2 = flat_b - flat_a
	if segment.length_squared() <= 0.0001:
		return flat_point.distance_to(flat_a)
	var t: float = clampf((flat_point - flat_a).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return flat_point.distance_to(flat_a + segment * t)

# ---------- visuals ----------

func _update_visuals(delta: float) -> void:
	if _knockdown_timer <= 0.0:
		var facing: Vector3 = _get_facing_direction()
		var target_yaw: float = atan2(facing.x, facing.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

	if _body_mesh == null:
		return
	if _is_frozen:
		_body_mesh.material_override = _freeze_material
	elif _stun_timer > 0.0:
		_body_mesh.material_override = _stun_material
	elif _possesses(self):
		_body_mesh.material_override = _possession_material
	else:
		_body_mesh.material_override = _base_material

func _build_visuals() -> void:
	var texture: Texture2D = SkaterSpriteVisuals.load_texture(skater_texture_path)
	if texture != null:
		SkaterSpriteVisuals.apply_skater_sprite(_body_mesh, _direction_marker)
		_base_material = SkaterSpriteVisuals.make_sprite_material(texture)
		_stun_material = SkaterSpriteVisuals.make_sprite_material(texture, Color(1.90, 1.55, 0.55, 1.0))
		_freeze_material = SkaterSpriteVisuals.make_sprite_material(texture, Color(0.75, 1.45, 1.90, 1.0))
		_possession_material = SkaterSpriteVisuals.make_sprite_material(texture, Color(1.22, 1.20, 1.14, 1.0))
		_body_mesh.material_override = _base_material
		return

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.85, 0.85, 0.9, 1.0)
	_stun_material = _base_material
	_freeze_material = _base_material
	_possession_material = _base_material
	_body_mesh.material_override = _base_material
