extends "res://scripts/hockey/test_rink_art_pass.gd"

const InputBindings: GDScript = preload("res://scripts/hockey/input/input_bindings.gd")
const HumanInputSource: GDScript = preload("res://scripts/hockey/input/human_input_source.gd")
const AiCenterInputSource: GDScript = preload("res://scripts/hockey/input/ai_center_input_source.gd")
const SkaterCollisionManagerScript: GDScript = preload("res://scripts/hockey/skater_collision_manager.gd")

var _reward_target_player: Node3D = null
var _collision_manager: Node3D = null
var _control_side: String = "HOME"

func _ready() -> void:
	super._ready()
	_reward_target_player = _player
	_build_collision_manager()
	_apply_control_side(_control_side, false)

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

	var ends_match: bool = false
	if _match_clock != null:
		ends_match = _match_clock.register_goal(team)
		_match_clock.stop()
	_hud.set_score(_match_clock.get_home_score(), _match_clock.get_away_score())
	_hud.celebrate_goal(team)
	SfxPlayer.play(SfxPlayer.ID_GOAL_HORN)
	_goal_lockout = true
	_set_match_enabled(false)
	_reset_faceoff(false)

	if ends_match:
		return

	_schedule_goal_draft(team)

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

func _apply_upgrade(upgrade_id: String) -> void:
	var target: Node3D = _reward_target_player if _reward_target_player != null else _player
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
