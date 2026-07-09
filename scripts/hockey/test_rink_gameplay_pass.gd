extends "res://scripts/hockey/test_rink_art_pass.gd"

const InputBindings: GDScript = preload("res://scripts/hockey/input/input_bindings.gd")
const SkaterCollisionManagerScript: GDScript = preload("res://scripts/hockey/skater_collision_manager.gd")

var _reward_target_player: Node3D = null
var _collision_manager: Node3D = null

func _ready() -> void:
	super._ready()
	_reward_target_player = _player
	_build_collision_manager()
	_show_controller_owner_hint()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_set_controller_owner(InputBindings.CONTROLLER_OWNER_P1)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F2:
			_set_controller_owner(InputBindings.CONTROLLER_OWNER_P2)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

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

func _set_controller_owner(owner: String) -> void:
	InputBindings.set_controller_owner(owner)
	if _hud == null:
		return
	var label: String = "P1" if owner == InputBindings.CONTROLLER_OWNER_P1 else "P2"
	_hud.show_notification("CONTROLLER: %s  •  F1=P1  F2=P2" % label, Color(1.0, 0.78, 0.10, 1.0), 2.0)

func _show_controller_owner_hint() -> void:
	if _hud == null:
		return
	var label: String = "P1" if InputBindings.get_controller_owner() == InputBindings.CONTROLLER_OWNER_P1 else "P2"
	_hud.show_notification("CONTROLLER: %s  •  F1=P1  F2=P2" % label, Color(1.0, 0.78, 0.10, 1.0), 2.0)

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

	# In local multiplayer, reward the scorer regardless of side.
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
