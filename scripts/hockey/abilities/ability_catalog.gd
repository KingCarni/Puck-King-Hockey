class_name AbilityCatalog
extends RefCounted

const AbilityDefinitionScript: GDScript = preload("res://scripts/hockey/abilities/ability_definition.gd")

static func from_reward_id(reward_id: StringName) -> AbilityDefinition:
	match reward_id:
		&"rocket_skates":
			return AbilityDefinitionScript.new(
				&"rocket_skates",
				"Rocket Skates",
				"Team skating speed, boost speed, and acceleration increased.",
				AbilityDefinition.Scope.TEAM,
				AbilityDefinition.Kind.PASSIVE,
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
				AbilityDefinition.Scope.TEAM,
				AbilityDefinition.Kind.PASSIVE,
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
				AbilityDefinition.Scope.TEAM,
				AbilityDefinition.Kind.PASSIVE,
				{
					&"check_knockback_mult": 0.35,
					&"check_puck_force_mult": 0.25,
					&"check_hit_radius_add": 0.16,
				},
				3
			)
		&"one_timer":
			return AbilityDefinitionScript.new(&"one_timer", "One-Timer", "Improves one-timer release and power.", AbilityDefinition.Scope.PLAYER, AbilityDefinition.Kind.ACTIVE)
		&"sniper":
			return AbilityDefinitionScript.new(&"sniper", "Sniper", "Improves shot accuracy and finishing.", AbilityDefinition.Scope.PLAYER, AbilityDefinition.Kind.ACTIVE)
		&"body_check_plus":
			return AbilityDefinitionScript.new(&"body_check_plus", "Body Check+", "Improves this player's checking impact.", AbilityDefinition.Scope.PLAYER, AbilityDefinition.Kind.ACTIVE)
	return null

static func team_reward_ids() -> Array[StringName]:
	return [&"rocket_skates", &"sticky_tape", &"titanium_pads"]
