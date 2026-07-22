extends "res://scripts/hockey/test_rink_ice2_pass.gd"

const InputBindings: GDScript = preload("res://scripts/hockey/input/input_bindings.gd")
const HumanInputSource: GDScript = preload("res://scripts/hockey/input/human_input_source.gd")
const AiCenterInputSource: GDScript = preload("res://scripts/hockey/input/ai_center_input_source.gd")
const SkaterCollisionManagerScript: GDScript = preload("res://scripts/hockey/skater_collision_manager.gd")
const GameCameraScript: GDScript = preload("res://scripts/match/game_camera.gd")

# Arena v1 artwork is authored at final world size; do not scale its visual root.
const VISUAL_RINK_SCALE: Vector3 = Vector3.ONE
const EXPANDED_HOME_GOAL_X: float = 20.75
const EXPANDED_AWAY_GOAL_X: float = -20.75
const LEGAL_GOAL_HALF_WIDTH: float = 1.48
const MIN_GOAL_ENTRY_SPEED: float = 3.0

var _reward_target_player: Node3D = null
var _collision_manager: Node3D = null
var _control_side: String = "HOME"
var _game_camera: Node = null
var _goal_stats: Dictionary = {}
var _current_reward_options: Array[Dictionary] = []

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
	camera.size = 36.5
	camera.global_position = Vector3(0.0, 31.5, 28.5)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _check_goal_state() -> void:
	if _puck == null or _goal_lockout:
		return

	var puck_position: Vector3 = _puck.global_position
	if puck_position.x >= EXPANDED_HOME_GOAL_X:
		if _is_legal_goal_crossing("HOME"):
			_register_goal("HOME")
		else:
			_reject_illegal_goal_attempt("HOME")
	elif puck_position.x <= EXPANDED_AWAY_GOAL_X:
		if _is_legal_goal_crossing("AWAY"):
			_register_goal("AWAY")
		else:
			_reject_illegal_goal_attempt("AWAY")

func _is_legal_goal_crossing(team: String) -> bool:
	if _puck == null:
		return false
	if _puck.has_method("is_possessed") and bool(_puck.call("is_possessed")):
		return false

	var puck_position: Vector3 = _puck.global_position
	if absf(puck_position.z) > LEGAL_GOAL_HALF_WIDTH:
		return false

	var previous_position: Vector3 = puck_position
	if _puck.has_method("get_previous_position"):
		previous_position = _puck.call("get_previous_position")
	var velocity: Vector3 = Vector3.ZERO
	if _puck.has_method("get_velocity"):
		velocity = _puck.call("get_velocity")

	if team == "HOME":
		return previous_position.x < EXPANDED_HOME_GOAL_X and velocity.x >= MIN_GOAL_ENTRY_SPEED
	return previous_position.x > EXPANDED_AWAY_GOAL_X and velocity.x <= -MIN_GOAL_ENTRY_SPEED

func _reject_illegal_goal_attempt(team: String) -> void:
	var clear_direction: Vector3 = Vector3.LEFT if team == "HOME" else Vector3.RIGHT
	var z_push: float = 0.70 if _puck.global_position.z >= 0.0 else -0.70
	if _puck.has_method("poke_free"):
		_puck.call("poke_free", (clear_direction + Vector3(0.0, 0.0, z_push)).normalized(), 12.0)
	_puck.global_position.x = (EXPANDED_HOME_GOAL_X - 0.45) if team == "HOME" else (EXPANDED_AWAY_GOAL_X + 0.45)
	_puck.global_position.y = PUCK_Y

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

	if _is_user_controlled_team(team):
		_schedule_goal_draft(team)
	else:
		_schedule_post_goal_reset()

func _is_user_controlled_team(team: String) -> bool:
	return team == _control_side

func _credit_goal_scorer(team: String) -> void:
	if _puck == null or not _puck.has_method("get_last_toucher"):
		return
	var scorer: Node3D = _puck.call("get_last_toucher") as Node3D
	if scorer == null:
		return
	var home_scorers: Array[StringName] = [&"Player", &"HomeTeammate"]
	var away_scorers: Array[StringName] = [&"Player2", &"AwayTeammate"]
	var valid: bool = (team == "HOME" and scorer.name in home_scorers) or (team == "AWAY" and scorer.name in away_scorers)
	if not valid:
		return
	var display: String = _display_name(scorer)
	var entry: Dictionary = _goal_stats.get(display, {"goals": 0})
	entry["goals"] = int(entry["goals"]) + 1
	_goal_stats[display] = entry

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
		&"Player": return "HOME CAPTAIN"
		&"Player2": return "AWAY CAPTAIN"
		&"HomeTeammate": return "HOME WINGER"
		&"AwayTeammate": return "AWAY WINGER"
		&"HomeGoalie": return "HOME GOALIE"
		&"AwayGoalie": return "AWAY GOALIE"
	return String(node.name).to_upper()

func _append_ability_rewards() -> void:
	# Ability cards are appended once to the reward pool.
	var extras: Array[Dictionary] = [
		{"name": "ROCKET SHOT", "description": "+35% shot power", "stat": "shot_power", "amount": 0.35},
		{"name": "ICE FREEZE", "description": "Checks freeze enemies", "stat": "ice_freeze", "amount": 1.0},
	]
	for reward: Dictionary in extras:
		if not _reward_exists(String(reward["name"])):
			REWARDS.append(reward)

func _reward_exists(reward_name: String) -> bool:
	for reward: Dictionary in REWARDS:
		if String(reward.get("name", "")) == reward_name:
			return true
	return false

func _show_reward_draft(team: String = _control_side) -> void:
	_current_reward_options.clear()
	var shuffled: Array = REWARDS.duplicate()
	shuffled.shuffle()
	for index: int in range(mini(3, shuffled.size())):
		_current_reward_options.append(shuffled[index])
	if _reward_draft != null:
		_reward_draft.show_draft(_current_reward_options, team)
	_reward_visible = true

func _on_reward_selected(index: int) -> void:
	if index < 0 or index >= _current_reward_options.size():
		return
	var reward: Dictionary = _current_reward_options[index]
	_apply_reward_to_target(reward)
	_reward_visible = false
	_schedule_post_goal_reset()

func _apply_reward_to_target(reward: Dictionary) -> void:
	if _reward_target_player == null:
		return
	var stat: String = String(reward.get("stat", ""))
	var amount: float = float(reward.get("amount", 0.0))
	match stat:
		"speed":
			_reward_target_player.set("max_speed", float(_reward_target_player.get("max_speed")) + amount)
		"acceleration":
			_reward_target_player.set("acceleration", float(_reward_target_player.get("acceleration")) + amount)
		"shot_power":
			_reward_target_player.set("shot_power", float(_reward_target_player.get("shot_power")) + amount)
		"check_power":
			_reward_target_player.set("check_power", float(_reward_target_player.get("check_power")) + amount)
		"ice_freeze":
			_reward_target_player.set("ice_freeze_enabled", true)
	if _hud != null:
		_hud.show_notification("%s: %s" % [_display_name(_reward_target_player), String(reward.get("name", "UPGRADE"))], Color(1.0, 0.78, 0.10, 1.0), 2.0)
