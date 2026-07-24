extends "res://scripts/hockey/test_rink_gameplay_pass.gd"

const TeamPlayManagerScript: GDScript = preload("res://scripts/hockey/team_play_manager.gd")
const AbilityCatalogScript: GDScript = preload("res://scripts/hockey/abilities/ability_catalog.gd")
const MatchAbilityStateScript: GDScript = preload("res://scripts/hockey/abilities/match_ability_state.gd")

const THREE_V_THREE_RINK_SCALE: Vector3 = Vector3.ONE
const THREE_V_THREE_HOME_GOAL_X: float = 22.65
const THREE_V_THREE_AWAY_GOAL_X: float = -22.65
const THREE_V_THREE_GOAL_HALF_WIDTH: float = 1.48
const THREE_V_THREE_MIN_GOAL_SPEED: float = 3.0

var _home_winger2: Node3D = null
var _away_winger2: Node3D = null
var _team_play_manager: Node = null
var _team_indicators: Node = null
var _ability_state: MatchAbilityState = MatchAbilityStateScript.new()
var _pending_reward_team: StringName = &"HOME"
var _base_skater_stats: Dictionary = {}

func _ready() -> void:
	super._ready()
	_home_winger2 = get_node_or_null("HomeTeammate2") as Node3D
	_away_winger2 = get_node_or_null("AwayTeammate2") as Node3D
	world.scale = THREE_V_THREE_RINK_SCALE
	if _collision_manager != null:
		_collision_manager.call("setup", _get_collision_bodies())
	_setup_team_play()
	_setup_match_abilities()
	if _match_clock != null and _match_clock.has_signal("intermission_started"):
		_match_clock.connect("intermission_started", _on_intermission_started)
	_update_upgrade_display()

func _setup_match_abilities() -> void:
	for player: Node3D in _team_players(&"HOME"):
		_ability_state.register_player(&"HOME", player)
		_capture_base_stats(player)
	for player: Node3D in _team_players(&"AWAY"):
		_ability_state.register_player(&"AWAY", player)
		_capture_base_stats(player)

func _setup_team_play() -> void:
	_team_play_manager = Node.new()
	_team_play_manager.name = "TeamPlayManager"
	_team_play_manager.set_script(TeamPlayManagerScript)
	add_child(_team_play_manager)
	var home: Array[Node3D] = _team_players(&"HOME")
	var away: Array[Node3D] = _team_players(&"AWAY")
	_team_play_manager.call("setup", _puck, home, away, _control_side)
	_team_indicators = get_node_or_null("PossessionIndicators")
	if _team_indicators != null:
		_team_play_manager.connect("controlled_player_changed", Callable(_team_indicators, "set_controlled_player"))
		_team_play_manager.connect("pass_target_changed", Callable(_team_indicators, "set_pass_target"))
		_team_play_manager.connect("call_acknowledged", Callable(_team_indicators, "acknowledge_call"))
		var controlled = _team_play_manager.get("controlled_player")
		if controlled is Node3D:
			_team_indicators.call("set_controlled_player", controlled)

func _team_players(side: StringName) -> Array[Node3D]:
	var players: Array[Node3D] = []
	var candidates: Array = [_player, _home_teammate, _home_winger2] if side == &"HOME" else [_away_skater, _away_teammate, _away_winger2]
	for candidate in candidates:
		if candidate is Node3D:
			players.append(candidate)
	return players

func _apply_control_side(side: String, announce: bool) -> void:
	super._apply_control_side(side, announce)
	if _team_play_manager != null:
		_team_play_manager.call("set_control_side", side)
	_update_upgrade_display()

func _configure_camera() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 38.5
	camera.global_position = Vector3(0.0, 33.0, 30.0)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_collision_manager() -> void:
	_collision_manager = Node3D.new()
	_collision_manager.name = "SkaterCollisionManager"
	_collision_manager.set_script(SkaterCollisionManagerScript)
	add_child(_collision_manager)
	_collision_manager.call("setup", _get_collision_bodies())

func _get_collision_bodies() -> Array[Node3D]:
	var bodies: Array[Node3D] = []
	var candidates: Array = [_player, _away_skater, _home_teammate, _away_teammate, _home_winger2, _away_winger2, _home_goalie, _away_goalie]
	for body in candidates:
		if body is Node3D:
			bodies.append(body)
	return bodies

func _register_goal(team: String) -> void:
	_pending_reward_team = StringName(team)
	if team != _control_side:
		_award_cpu_team_upgrade(StringName(team))
	super._register_goal(team)

func _award_cpu_team_upgrade(side: StringName) -> void:
	var reward_ids: Array[StringName] = AbilityCatalogScript.team_reward_ids()
	if reward_ids.is_empty():
		return
	var ability: AbilityDefinition = AbilityCatalogScript.from_reward_id(reward_ids[randi() % reward_ids.size()])
	if ability != null and _ability_state.add_ability(side, ability):
		_refresh_team_stats(side)

func _on_reward_selected(index: int, upgrade_id: String) -> void:
	if index < 0 or index >= _reward_options.size():
		return
	var option: Dictionary = _reward_options[index]
	var ability: AbilityDefinition = AbilityCatalogScript.from_reward_id(StringName(upgrade_id))
	if ability == null or not _ability_state.add_ability(_pending_reward_team, ability):
		return
	_selected_upgrades.append(option)
	_refresh_team_stats(_pending_reward_team)
	_update_upgrade_display()
	_reward_visible = false
	_goal_lockout = false
	if _reward_draft != null:
		_reward_draft.hide_draft()
	SfxPlayer.play(SfxPlayer.ID_REWARD_PICK)
	_hud.show_notification("TEAM UPGRADE: %s" % String(option["title"]), Color(1.0, 0.78, 0.10, 1.0), 1.8)
	_set_match_enabled(true)
	_reset_faceoff(true)
	if _match_clock != null:
		_match_clock.resume()

func _capture_base_stats(player: Node3D) -> void:
	if player == null or _base_skater_stats.has(player.get_instance_id()):
		return
	var stats: Dictionary = {}
	for property_name: StringName in [&"acceleration", &"sprint_acceleration", &"max_speed", &"sprint_max_speed", &"puck_carry_distance", &"check_knockback_force", &"check_puck_force", &"check_hit_radius"]:
		var value: Variant = player.get(property_name)
		if value != null:
			stats[property_name] = float(value)
	_base_skater_stats[player.get_instance_id()] = stats

func _refresh_team_stats(side: StringName) -> void:
	var team_state: TeamAbilityState = _ability_state.team(side)
	for player: Node3D in _team_players(side):
		_capture_base_stats(player)
		var base: Dictionary = _base_skater_stats.get(player.get_instance_id(), {})
		_set_scaled_stat(player, base, &"acceleration", 1.0 + team_state.get_combined_modifier(player, &"acceleration_mult"))
		_set_scaled_stat(player, base, &"sprint_acceleration", 1.0 + team_state.get_combined_modifier(player, &"sprint_acceleration_mult"))
		_set_scaled_stat(player, base, &"max_speed", 1.0 + team_state.get_combined_modifier(player, &"max_speed_mult"))
		_set_scaled_stat(player, base, &"sprint_max_speed", 1.0 + team_state.get_combined_modifier(player, &"sprint_max_speed_mult"))
		_set_scaled_stat(player, base, &"check_knockback_force", 1.0 + team_state.get_combined_modifier(player, &"check_knockback_mult"))
		_set_scaled_stat(player, base, &"check_puck_force", 1.0 + team_state.get_combined_modifier(player, &"check_puck_force_mult"))
		_set_added_stat(player, base, &"puck_carry_distance", team_state.get_combined_modifier(player, &"puck_carry_distance_add"))
		_set_added_stat(player, base, &"check_hit_radius", team_state.get_combined_modifier(player, &"check_hit_radius_add"))

func _set_scaled_stat(player: Node3D, base: Dictionary, property_name: StringName, multiplier: float) -> void:
	if base.has(property_name):
		player.set(property_name, float(base[property_name]) * multiplier)

func _set_added_stat(player: Node3D, base: Dictionary, property_name: StringName, addition: float) -> void:
	if base.has(property_name):
		player.set(property_name, float(base[property_name]) + addition)

func _update_upgrade_display() -> void:
	if _hud == null or _ability_state == null:
		return
	var display_entries: Array[Dictionary] = []
	var side: StringName = StringName(_control_side)
	for raw_entry: Dictionary in _ability_state.team(side).get_team_ability_entries():
		var definition: AbilityDefinition = raw_entry.get("definition") as AbilityDefinition
		if definition == null:
			continue
		var stacks: int = int(raw_entry.get("stacks", 1))
		display_entries.append({
			"id": String(definition.id),
			"title": "%s%s" % [definition.display_name, " x%d" % stacks if stacks > 1 else ""],
			"description": definition.description,
			"glyph": "★",
		})
	while display_entries.size() < 3:
		display_entries.append({"id": "empty", "title": "Empty", "description": "Score a goal to earn a team upgrade.", "glyph": "—"})
	_hud.set_upgrades(display_entries.slice(0, 3))

func _on_intermission_started(_completed_period_index: int, _next_period_index: int) -> void:
	_set_match_enabled(false)
	_goal_lockout = true
	if _hud != null:
		_hud.show_notification("END OF PERIOD", Color(1.0, 0.78, 0.10, 1.0), 2.0)

func _on_clock_period_changed(period_index: int, period_label: String, is_overtime: bool) -> void:
	super._on_clock_period_changed(period_index, period_label, is_overtime)
	if period_index > 0 or is_overtime:
		_goal_lockout = false
		_reset_faceoff(true)
		_set_match_enabled(true)

func _check_goal_state() -> void:
	if _puck == null or _goal_lockout:
		return
	var puck_position: Vector3 = _puck.global_position
	if puck_position.x >= THREE_V_THREE_HOME_GOAL_X:
		if _is_legal_3v3_goal_crossing("HOME"):
			_register_goal("HOME")
		else:
			_reject_3v3_illegal_goal_attempt("HOME")
	elif puck_position.x <= THREE_V_THREE_AWAY_GOAL_X:
		if _is_legal_3v3_goal_crossing("AWAY"):
			_register_goal("AWAY")
		else:
			_reject_3v3_illegal_goal_attempt("AWAY")

func _is_legal_3v3_goal_crossing(team: String) -> bool:
	if _puck == null:
		return false
	if _puck.has_method("is_possessed") and bool(_puck.call("is_possessed")):
		return false
	var puck_position: Vector3 = _puck.global_position
	if absf(puck_position.z) > THREE_V_THREE_GOAL_HALF_WIDTH:
		return false
	var previous_position: Vector3 = puck_position
	if _puck.has_method("get_previous_position"):
		previous_position = _puck.call("get_previous_position")
	var velocity: Vector3 = Vector3.ZERO
	if _puck.has_method("get_velocity"):
		velocity = _puck.call("get_velocity")
	if team == "HOME":
		return previous_position.x < THREE_V_THREE_HOME_GOAL_X and velocity.x >= THREE_V_THREE_MIN_GOAL_SPEED
	return previous_position.x > THREE_V_THREE_AWAY_GOAL_X and velocity.x <= -THREE_V_THREE_MIN_GOAL_SPEED

func _reject_3v3_illegal_goal_attempt(team: String) -> void:
	var clear_direction: Vector3 = Vector3.LEFT if team == "HOME" else Vector3.RIGHT
	var z_push: float = 0.85 if _puck.global_position.z >= 0.0 else -0.85
	if _puck.has_method("poke_free"):
		_puck.call("poke_free", (clear_direction + Vector3(0.0, 0.0, z_push)).normalized(), 13.0)
	_puck.global_position.x = (THREE_V_THREE_HOME_GOAL_X - 0.55) if team == "HOME" else (THREE_V_THREE_AWAY_GOAL_X + 0.55)
	_puck.global_position.y = PUCK_Y

func _reset_faceoff(clear_puck: bool) -> void:
	super._reset_faceoff(clear_puck)
	_reset_extra_winger(_home_winger2, Vector3(-11.0, PLAYER_Y, -4.8), Vector3.RIGHT)
	_reset_extra_winger(_away_winger2, Vector3(11.0, PLAYER_Y, 4.8), Vector3.LEFT)

func _reset_extra_winger(winger: Node3D, position: Vector3, facing: Vector3) -> void:
	if winger == null:
		return
	winger.global_position = position
	winger.global_position.y = PLAYER_Y
	winger.set("_move_velocity", Vector3.ZERO)
	winger.set("_last_facing_direction", facing)
	winger.set("_stun_timer", 0.0)
	winger.set("_shoot_cooldown_timer", 0.0)

func _set_match_enabled(is_enabled: bool) -> void:
	super._set_match_enabled(is_enabled)
	var mode: int = Node.PROCESS_MODE_INHERIT if is_enabled else Node.PROCESS_MODE_DISABLED
	if _home_winger2 != null:
		_home_winger2.process_mode = mode
	if _away_winger2 != null:
		_away_winger2.process_mode = mode
	if _team_play_manager != null:
		_team_play_manager.process_mode = mode

func _compute_three_stars() -> Array:
	var candidates: Array = []
	var skaters: Array = [_player, _away_skater, _home_teammate, _away_teammate, _home_winger2, _away_winger2]
	for skater in skaters:
		if not (skater is Node3D):
			continue
		var display: String = _display_name(skater)
		var goals: int = int(_goal_stats.get(display, {}).get("goals", 0))
		var hits_value = skater.get("hits_delivered")
		var hits: int = int(hits_value) if hits_value != null else 0
		var score: float = goals * 3.0 + hits * 0.75
		candidates.append({"name": display, "score": score, "line": "%d G · %d HIT" % [goals, hits]})
	var goalies: Array = [_home_goalie, _away_goalie]
	for goalie in goalies:
		if not (goalie is Node3D):
			continue
		var saves_value = goalie.get("saves_made")
		var saves: int = int(saves_value) if saves_value != null else 0
		candidates.append({"name": _display_name(goalie), "score": saves * 0.85, "line": "%d SAVES" % saves})
	candidates.sort_custom(_sort_star_candidates)
	var stars: Array = []
	var glyphs: Array = ["★", "★★", "★★★"]
	for index in range(mini(3, candidates.size())):
		var entry: Dictionary = candidates[index]
		stars.append("%s  %s — %s" % [glyphs[index], String(entry["name"]), String(entry["line"])])
	if not stars.is_empty():
		stars[0] = "MVP " + String(stars[0])
	return stars

func _sort_star_candidates(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("score", 0.0)) > float(b.get("score", 0.0))

func _display_name(node: Node3D) -> String:
	match node.name:
		&"HomeTeammate2": return "HOME RIGHT WING"
		&"AwayTeammate2": return "AWAY RIGHT WING"
		&"HomeTeammate": return "HOME LEFT WING"
		&"AwayTeammate": return "AWAY LEFT WING"
	return super._display_name(node)

func _credit_goal_scorer(team: String) -> void:
	if _puck == null or not _puck.has_method("get_last_toucher"):
		return
	var scorer = _puck.call("get_last_toucher")
	if not (scorer is Node3D):
		return
	var home_scorers: Array = [&"Player", &"HomeTeammate", &"HomeTeammate2"]
	var away_scorers: Array = [&"Player2", &"AwayTeammate", &"AwayTeammate2"]
	var valid: bool = (team == "HOME" and scorer.name in home_scorers) or (team == "AWAY" and scorer.name in away_scorers)
	if not valid:
		return
	var display: String = _display_name(scorer)
	var entry: Dictionary = _goal_stats.get(display, {"goals": 0})
	entry["goals"] = int(entry["goals"]) + 1
	_goal_stats[display] = entry
