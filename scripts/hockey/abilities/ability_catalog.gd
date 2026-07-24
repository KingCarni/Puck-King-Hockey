class_name AbilityCatalog
extends RefCounted

# Builds AbilityDefinition instances from reward ids. References the
# definition script via preload so this never depends on the global class
# cache being warm.

const AbilityDefinitionScript = preload("res://scripts/hockey/abilities/ability_definition.gd")

static func from_reward_id(reward_id: StringName) -> RefCounted:
	match reward_id:
		&"rocket_skates":
			return AbilityDefinitionScript.new(
				&"rocket_skates",
				"Rocket Skates",
				"Team skating speed, boost speed, and acceleration increased.",
				AbilityDefinitionScript.Scope.TEAM,
				AbilityDefinitionScript.Kind.PASSIVE,
				{
					&"acceleration_mult": 0.08,
					&"sprint_acceleration_mult": 0.10,
					&"max_speed_mult": 0.12,
					&"sprint_max_speed_mult": 0.15,
				},
				3
			)
		&"sticky_tape":
			return AbilityDefinitionScript.new(
				&"sticky_tape",
				"Sticky Tape",
				"Team puck control and pickup reach increased.",
				AbilityDefinitionScript.Scope.TEAM,
				AbilityDefinitionScript.Kind.PASSIVE,
				{
					&"puck_carry_distance_add": 0.18,
					&"pickup_radius_mult": 0.25,
					&"carry_lag_speed_mult": 0.18,
				},
				3
			)
		&"titanium_pads":
			return AbilityDefinitionScript.new(
				&"titanium_pads",
				"Titanium Pads",
				"Team checking power, range, and puck pop force increased.",
				AbilityDefinitionScript.Scope.TEAM,
				AbilityDefinitionScript.Kind.PASSIVE,
				{
					&"check_knockback_mult": 0.35,
					&"check_puck_force_mult": 0.25,
					&"check_hit_radius_add": 0.16,
				},
				3
			)
		&"one_timer":
			return AbilityDefinitionScript.new(&"one_timer", "One-Timer", "Improves one-timer release and power.", AbilityDefinitionScript.Scope.PLAYER, AbilityDefinitionScript.Kind.ACTIVE)
		&"sniper":
			return AbilityDefinitionScript.new(&"sniper", "Sniper", "Improves shot accuracy and finishing.", AbilityDefinitionScript.Scope.PLAYER, AbilityDefinitionScript.Kind.ACTIVE)
		&"body_check_plus":
			return AbilityDefinitionScript.new(&"body_check_plus", "Body Check+", "Improves this player's checking impact.", AbilityDefinitionScript.Scope.PLAYER, AbilityDefinitionScript.Kind.ACTIVE)
	return null

static func team_reward_ids() -> Array[StringName]:
	return [&"rocket_skates", &"sticky_tape", &"titanium_pads"]
