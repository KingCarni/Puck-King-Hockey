extends "res://scripts/hockey/test_rink_art_pass.gd"

const InputBindings: GDScript = preload("res://scripts/hockey/input/input_bindings.gd")
const HumanInputSource: GDScript = preload("res://scripts/hockey/input/human_input_source.gd")
const AiCenterInputSource: GDScript = preload("res://scripts/hockey/input/ai_center_input_source.gd")
const SkaterCollisionManagerScript: GDScript = preload("res://scripts/hockey/skater_collision_manager.gd")
const GameCameraScript: GDScript = preload("res://scripts/match/game_camera.gd")

const VISUAL_RINK_SCALE: Vector3 = Vector3(1.14, 1.0, 1.14)
const EXPANDED_HOME_GOAL_X: float = 20.75
const EXPANDED_AWAY_GOAL_X: float = -20.75

var _reward_target_player: Node3D = null
var _collision_manager: Node3D = null
var _control_side: String = "HOME"
var _game_camera: Node = null
# Display name -> {"goals": int} — saves/hits are read from the nodes at match end.
var _goal_stats: Dictionary = {}

func _ready() -> void:
	super._ready()
	world.scale = VISUAL_RINK_SCALE
	_reward_target_player = _player
	_build_collision_manager()
	_build_game_camera()
	_connect_goalie_whistles()
	_append_ability_rewards()
	_apply_control_side(_control_side, false)

func _build_game_camera() -> void:
	_game_camera = Node.new()
	_game_camera.name = "GameCamera"
	_game_camera.set_script(GameCameraScript)
	add_child(_game_camera)
	_game_camera.call("setup", camera, _puck)

func _connect_goalie_whistles() -> void:
	for goalie: Node3D in [_home_goalie, _away_goalie]:
		if goalie != null and goalie.has_signal("puck_frozen"):
			goalie.puck_frozen.connect(_on_goalie_froze_puck)

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 34.0
	camera.global_position = Vector3(0.0, 30.0, 27.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null:
		return
	if _goal_lockout:
		return

	var puck_position: Vector3 = _puck.global_position
	var is_inside_goal_width: bool = abs(puck_position.z) <= GOAL_WIDTH * 0.5 + 0.35
	if not is_inside_goal_width:
		return

	if puck_position.x >= EXPANDED_HOME_GOAL_X:
		_register_goal("HOME")
	elif puck_position.x <= EXPANDED_AWAY_GOAL_X:
		_register_goal("AWAY")

func _build_ui() -> void:
	super._build_ui()
	if _pause_menu != null:
		if _pause_menu.has_signal("control_home_requested"):
			_pause_menu.control_home_requested.connect(_on_control_home_requested)
		if _pause_menu.has_signal("control_away_requested"):
			_pause_menu.control_away_requested.connect(_on_control_away_requested)
		if _pause_menu.has_method("set_control_side"):
			_pause_menu.call("set_control_side", _control_side)

func _build_collision_manager() -> void:
	_collision_manager = Node3D.new()
	_collision_manager.name = "SkaterCollisionManager"
	_collision_manager.set_script(SkaterCollisionManagerScript)
	add_child(_collision_manager)

	var bodies: Array[Node3D] = []
	_add_collision_body(bodies, _player)
	_add_collision_body(bodies, _away_skater)
	_add_collision_body(bodies, _home_teammate)
	_add_collision_body(bodies, _away_teammate)
	_add_collision_body(bodies, _home_goalie)
	_add_collision_body(bodies, _away_goalie)
	_collision_manager.call("setup", bodies)

func _add_collision_body(bodies: Array[Node3D], body: Node3D) -> void:
	if body != null:
		bodies.append(body)

func _on_control_home_requested() -> void:
	_apply_control_side("HOME", true)

func _on_control_away_requested() -> void:
	_apply_control_side("AWAY", true)

func _apply_control_side(side: String, announce: bool) -> void:
	_control_side = side
	if _pause_menu != null and _pause_menu.has_method("set_control_side"):
		_pause_menu.call("set_control_side", _control_side)

	if _control_side == "HOME":
		InputBindings.set_controller_owner(InputBindings.CONTROLLER_OWNER_P1)
		_set_human_control(_player, "p1")
		_set_cpu_control(_away_skater, -1.0)
	else:
		InputBindings.set_controller_owner(InputBindings.CONTROLLER_OWNER_P2)
		_set_cpu_control(_player, 1.0)
		_set_human_control(_away_skater, "p2")

	if announce and _hud != null:
		_hud.show_notification("YOU CONTROL: %s" % _control_side, Color(1.0, 0.78, 0.10, 1.0), 1.8)

func _set_human_control(skater: Node3D, prefix: String) -> void:
	if skater == null or not skater.has_method("set_input_source"):
		return
	skater.call("set_input_source", HumanInputSource.new(prefix))

func _set_cpu_control(skater: Node3D, attack_direction: float) -> void:
	if skater == null or not skater.has_method("set_input_source"):
		return
	var ai_source: RefCounted = AiCenterInputSource.new()
	ai_source.call("setup", skater, _puck, attack_direction)
	skater.call("set_input_source", ai_source)

func _register_goal(team: String) -> void:
	_reward_target_player = _player if team == "HOME" else _away_skater
	_credit_goal_scorer(team)

	var ends_match: bool = false
	if _match_clock != null:
		ends_match = _match_clock.register_goal(team)
		_match_clock.stop()
	_hud.set_score(_match_clock.get_home_score(), _match_clock.get_away_score())
	_hud.celebrate_goal(team)
	SfxPlayer.play(SfxPlayer.ID_GOAL_HORN)
	SfxPlayer.play(SfxPlayer.ID_CROWD_CHEER, randf_range(0.92, 1.05), 1.5)
	_flash_goal_light(team)
	if _game_camera != null:
		_game_camera.call("goal_punch")
	_goal_lockout = true
	_set_match_enabled(false)
	_reset_faceoff(false)

	if ends_match:
		return

	_schedule_goal_draft(team)

func _credit_goal_scorer(team: String) -> void:
	if _puck == null or not _puck.has_method("get_last_toucher"):
		return
	var scorer: Node3D = _puck.call("get_last_toucher") as Node3D
	if scorer == null:
		return
	# Only credit shooters on the scoring team (no own-goal glory).
	var home_scorers: Array[StringName] = [&"Player", &"HomeTeammate"]
	var away_scorers: Array[StringName] = [&"Player2", &"AwayTeammate"]
	var valid: bool = (team == "HOME" and scorer.name in home_scorers) or (team == "AWAY" and scorer.name in away_scorers)
	if not valid:
		return
	var display: String = _display_name(scorer)
	var entry: Dictionary = _goal_stats.get(display, {"goals": 0})
	entry["goals"] = int(entry["goals"]) + 1
	_goal_stats[display] = entry

# Red goal-light strobe behind the scored-on net.
func _flash_goal_light(team: String) -> void:
	var net_x: float = EXPANDED_HOME_GOAL_X if team == "HOME" else EXPANDED_AWAY_GOAL_X
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "GoalLight"
	light.light_color = Color(1.0, 0.09, 0.06)
	light.omni_range = 10.0
	light.light_energy = 0.0
	light.position = Vector3(net_x, 2.3, 0.0)
	add_child(light)

	var tween: Tween = create_tween()
	for i: int in range(5):
		tween.tween_property(light, "light_energy", 7.5, 0.11)
		tween.tween_property(light, "light_energy", 0.5, 0.15)
	tween.tween_callback(light.queue_free)

func _on_goalie_froze_puck() -> void:
	if _goal_lockout:
		return
	if _match_clock != null and _match_clock.match_over:
		return
	SfxPlayer.play(SfxPlayer.ID_WHISTLE)
	if _hud != null:
		_hud.show_notification("WHISTLE — GOALIE FREEZES IT", Color(0.55, 0.90, 1.0, 1.0), 1.4)
	_goal_lockout = true
	_set_match_enabled(false)
	var timer: SceneTreeTimer = get_tree().create_timer(1.4)
	timer.timeout.connect(_on_freeze_faceoff_timeout)

func _on_freeze_faceoff_timeout() -> void:
	if _match_clock != null and _match_clock.match_over:
		return
	if _reward_visible:
		return
	_goal_lockout = false
	_set_match_enabled(true)
	_reset_faceoff(true)

func _on_clock_period_changed(period_index: int, period_label: String, is_overtime: bool) -> void:
	super._on_clock_period_changed(period_index, period_label, is_overtime)
	if _game_camera != null:
		_game_camera.call("set_overtime", is_overtime)

func _on_match_ended(winner: String, home_score: int, away_score: int) -> void:
	if _game_over != null and _game_over.has_method("set_three_stars"):
		_game_over.call("set_three_stars", _compute_three_stars())
	super._on_match_ended(winner, home_score, away_score)

func _compute_three_stars() -> Array:
	var candidates: Array = []
	for skater: Node3D in [_player, _away_skater, _home_teammate, _away_teammate]:
		if skater == null:
			continue
		var display: String = _display_name(skater)
		var goals: int = int(_goal_stats.get(display, {}).get("goals", 0))
		var hits: int = int(skater.get("hits_delivered")) if skater.get("hits_delivered") != null else 0
		var score: float = goals * 3.0 + hits * 0.75
		candidates.append({"name": display, "score": score, "line": "%d G · %d HIT" % [goals, hits]})
	for goalie: Node3D in [_home_goalie, _away_goalie]:
		if goalie == null:
			continue
		var saves: int = int(goalie.get("saves_made")) if goalie.get("saves_made") != null else 0
		candidates.append({"name": _display_name(goalie), "score": saves * 0.85, "line": "%d SAVES" % saves})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))
	var stars: Array = []
	var glyphs: Array[String] = ["★", "★★", "★★★"]
	for index: int in range(mini(3, candidates.size())):
		var entry: Dictionary = candidates[index]
		stars.append("%s  %s — %s" % [glyphs[index] if index < glyphs.size() else "★", String(entry["name"]), String(entry["line"])])
	if not stars.is_empty():
		stars[0] = "MVP " + String(stars[0])
	return stars

func _display_name(node: Node3D) -> String:
	match node.name:
		&"Player": return "P1 CAPTAIN"
		&"Player2": return "P2 CAPTAIN"
		&"HomeTeammate": return "HOME WINGER"
		&"AwayTeammate": return "AWAY WINGER"
		&"HomeGoalie": return "HOME GOALIE"
		&"AwayGoalie": return "AWAY GOALIE"
	return String(node.name).to_upper()

func _schedule_goal_draft(team: String) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(REWARD_DRAFT_DELAY)
	timer.timeout.connect(func() -> void:
		_on_goal_draft_timeout(team)
	)

func _on_goal_draft_timeout(team: String) -> void:
	if _match_clock != null and _match_clock.match_over:
		return
	var label: String = "HOME" if team == "HOME" else "AWAY"
	if _hud != null:
		_hud.show_notification("%s DRAFT PICK" % label, Color(1.0, 0.78, 0.10, 1.0), 1.0)
	_show_reward_draft()

# Active abilities join the stat upgrades in the reward pool; each draft
# offers a random three so runs diverge.
func _append_ability_rewards() -> void:
	_reward_options.append_array([
		{
			"id": "rocket_shot",
			"title": "Rocket Shot",
			"description": "Shots fly 30% faster and burn red hot.",
			"glyph": "⚑",
			"icon": "res://assets/art/powerups/powerup_rocket_shot.svg"
		},
		{
			"id": "magnet_puck",
			"title": "Magnet Puck",
			"description": "Loose pucks curve toward your stick.",
			"glyph": "⚛",
			"icon": "res://assets/art/powerups/powerup_magnet_puck.svg"
		},
		{
			"id": "freeze_blast",
			"title": "Freeze Blast",
			"description": "Your body checks freeze victims solid.",
			"glyph": "❄",
			"icon": "res://assets/art/powerups/powerup_freeze_opponent.svg"
		}
	])

func _show_reward_draft() -> void:
	if _reward_draft != null:
		_reward_draft.set_options(_pick_reward_options())
	super._show_reward_draft()

func _pick_reward_options() -> Array:
	var pool: Array = _reward_options.duplicate()
	pool.shuffle()
	return pool.slice(0, 3)

func _apply_upgrade(upgrade_id: String) -> void:
	var target: Node3D = _reward_target_player if _reward_target_player != null else _player
	match upgrade_id:
		"rocket_shot":
			_apply_float_multiplier(target, "shot_speed_scale", 1.30)
			return
		"magnet_puck":
			_puck.set("magnet_target", target)
			_puck.set("magnet_radius", float(_puck.get("magnet_radius")) + 0.5)
			return
		"freeze_blast":
			_apply_float_add(target, "check_freeze_seconds", 1.1)
			return
	match upgrade_id:
		"rocket_skates":
			_apply_float_multiplier(target, "acceleration", 1.08)
			_apply_float_multiplier(target, "sprint_acceleration", 1.10)
			_apply_float_multiplier(target, "max_speed", 1.12)
			_apply_float_multiplier(target, "sprint_max_speed", 1.15)
		"sticky_tape":
			_apply_float_add(target, "puck_carry_distance", 0.18)
			_puck.set("pickup_radius", float(_puck.get("pickup_radius")) * 1.25)
			_puck.set("carry_lag_speed", float(_puck.get("carry_lag_speed")) * 1.18)
		"titanium_pads":
			_apply_float_multiplier(target, "check_knockback_force", 1.35)
			_apply_float_multiplier(target, "check_puck_force", 1.25)
			_apply_float_add(target, "check_hit_radius", 0.16)
		_:
			return

func _apply_float_multiplier(target: Node3D, property_name: String, multiplier: float) -> void:
	if target == null:
		return
	var current: Variant = target.get(property_name)
	if current == null:
		return
	target.set(property_name, float(current) * multiplier)

func _apply_float_add(target: Node3D, property_name: String, amount: float) -> void:
	if target == null:
		return
	var current: Variant = target.get(property_name)
	if current == null:
		return
	target.set(property_name, float(current) + amount)
