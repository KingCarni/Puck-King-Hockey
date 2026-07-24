extends SceneTree

# Headless validation of the roster/runtime-stat foundation. Run:
#   godot --headless --path . -s res://tests/manual/roster_stat_check.gd
# Prints PASS/FAIL per check and exits non-zero on failure.

const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")
const RosterCatalogScript = preload("res://scripts/roster/roster_catalog.gd")
const PlayerRuntimeStatsScript = preload("res://scripts/roster/player_runtime_stats.gd")
const MatchRosterScript = preload("res://scripts/roster/match_roster.gd")
const MatchAbilityStateScript = preload("res://scripts/hockey/abilities/match_ability_state.gd")
const AbilityCatalogScript = preload("res://scripts/hockey/abilities/ability_catalog.gd")

var _failures: int = 0

func _initialize() -> void:
	var duane_node: Node3D = Node3D.new()
	duane_node.name = "Player"
	root.add_child(duane_node)
	var gronk_node: Node3D = Node3D.new()
	gronk_node.name = "HomeTeammate"
	root.add_child(gronk_node)

	var ability_state: RefCounted = MatchAbilityStateScript.new()
	var roster: RefCounted = MatchRosterScript.new()
	roster.setup(ability_state)
	ability_state.register_player(&"HOME", duane_node)
	ability_state.register_player(&"HOME", gronk_node)
	roster.assign(duane_node, &"HOME", RosterCatalogScript.find(&"duane_clutzky"))
	roster.assign(gronk_node, &"HOME", RosterCatalogScript.find(&"gronk_mckrunk"))
	roster.ensure_assigned(duane_node, &"HOME")

	var duane: RefCounted = roster.stats_for(duane_node)
	var gronk: RefCounted = roster.stats_for(gronk_node)

	_check("named identities resolve",
		roster.display_name_for(duane_node) == "Duane Clutzky"
		and roster.display_name_for(gronk_node) == "Gronk McKrunk")

	_check("ensure_assigned does not overwrite named definition",
		roster.definition_for(duane_node).get("id") == &"duane_clutzky")

	# Different runtime stats from the same node baseline (max_speed 8.2).
	var duane_speed: float = duane.get_scaled(&"max_speed", 8.2)
	var gronk_speed: float = gronk.get_scaled(&"max_speed", 8.2)
	_check("Gronk is slower than Duane (%.2f < %.2f)" % [gronk_speed, duane_speed],
		gronk_speed < duane_speed and is_equal_approx(duane_speed, 8.2))

	_check("Gronk checks harder (scale 1.45)",
		is_equal_approx(gronk.get_scaled(&"check_knockback_force", 14.0), 14.0 * 1.45))

	_check("Gronk winds up slower (charge 0.72 -> %.2f)" % gronk.get_scaled(&"slap_shot_charge_seconds", 0.72),
		gronk.get_scaled(&"slap_shot_charge_seconds", 0.72) > 1.0)

	_check("pass attributes differ (Duane %.2f vs Gronk %.2f accuracy)"
		% [duane.get_attribute(&"pass_accuracy"), gronk.get_attribute(&"pass_accuracy")],
		duane.get_attribute(&"pass_accuracy") > 0.8 and gronk.get_attribute(&"pass_accuracy") < 0.4)

	# Team ability flows through the runtime layer without mutating anything.
	var before: float = duane.get_scaled(&"max_speed", 8.2)
	var rocket: RefCounted = AbilityCatalogScript.from_reward_id(&"rocket_skates")
	ability_state.add_ability(&"HOME", rocket)
	roster.invalidate_side(&"HOME")
	var after: float = duane.get_scaled(&"max_speed", 8.2)
	_check("rocket skates raise runtime speed (%.2f -> %.2f, +12%%)" % [before, after],
		is_equal_approx(after, before * 1.12))
	_check("team ability also reaches Gronk",
		is_equal_approx(gronk.get_scaled(&"max_speed", 8.2), 8.2 * 0.88 * 1.12))

	# Sticky tape pickup reach via the legacy alias.
	var tape: RefCounted = AbilityCatalogScript.from_reward_id(&"sticky_tape")
	ability_state.add_ability(&"HOME", tape)
	roster.invalidate_side(&"HOME")
	_check("sticky tape scales pickup reach (+25%)",
		is_equal_approx(duane.get_scaled(&"pickup_radius_scale", 1.0), 1.25))

	# Temporary buff layer.
	duane.add_buff_modifier(&"max_speed_mult", 0.10)
	_check("temporary buff stacks with team ability",
		is_equal_approx(duane.get_scaled(&"max_speed", 8.2), 8.2 * (1.0 + 0.12 + 0.10)))
	duane.clear_buffs()

	# Permanent progression layer (Adventure hook).
	duane.set_permanent_modifiers({&"pass_accuracy_add": 0.05})
	_check("permanent progression raises pass accuracy",
		duane.get_attribute(&"pass_accuracy") > 0.9)

	if _failures == 0:
		print("roster_stat_check: ALL CHECKS PASSED")
	else:
		print("roster_stat_check: %d CHECK(S) FAILED" % _failures)
	quit(1 if _failures > 0 else 0)

func _check(label: String, condition: bool) -> void:
	if condition:
		print("PASS  %s" % label)
	else:
		_failures += 1
		printerr("FAIL  %s" % label)
