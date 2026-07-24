class_name PlayerDefinition
extends Resource

# Identity + tuning data for one named skater.
#
# Definitions carry no match state. Runtime values are computed per match by
# PlayerRuntimeStats (scripts/roster/player_runtime_stats.gd) from these
# layers: definition scales/attributes, permanent Adventure progression,
# equipment, team/player abilities, and temporary match buffs.
#
# Two kinds of tuning data:
#   stat_scales — multipliers applied to the controller node's authored
#     baseline (a winger baseline differs from a center baseline, so
#     characters modulate rather than replace those units). 1.0 = neutral.
#     Keys match controller property names: &"max_speed", &"acceleration",
#     &"sprint_acceleration", &"sprint_max_speed", &"check_knockback_force",
#     &"check_puck_force", &"check_hit_radius", &"puck_carry_distance",
#     &"slap_shot_charge_seconds", ...
#   attributes — absolute ratings/scalars that have no node baseline:
#     &"pass_accuracy", &"pass_assist", &"pass_power", &"pass_lead" (0..1)
#     and &"shot_power_scale" (multiplier, 1.0 = neutral).

@export var id: StringName = &""
@export var display_name: String = ""
@export var nickname: String = ""
@export_enum("FORWARD", "DEFENSE", "GOALIE") var position: String = "FORWARD"
@export var archetype: StringName = &"grinder"
@export_enum("LEFT", "RIGHT") var handedness: String = "LEFT"
@export var portrait_path: String = ""
@export_multiline var bio: String = ""
@export var stat_scales: Dictionary = {}
@export var attributes: Dictionary = {}
## Passive traits: Array of Dictionaries — {id, name, description, modifiers}.
## Trait modifiers use the ability convention: &"<stat>_mult" / &"<stat>_add".
@export var traits: Array[Dictionary] = []
## Ids of active abilities this player starts with (resolved via AbilityCatalog).
@export var active_ability_ids: Array[StringName] = []
## Stable key for future Adventure Mode save data. Defaults to id.
@export var progression_key: StringName = &""

func get_stat_scale(stat_id: StringName) -> float:
	return float(stat_scales.get(stat_id, 1.0))

func get_attribute(attribute_id: StringName, default_value: float = 0.5) -> float:
	return float(attributes.get(attribute_id, default_value))

func get_progression_key() -> StringName:
	return progression_key if progression_key != &"" else id

## Sum of a modifier id across all passive traits (same convention as
## AbilityDefinition modifiers, e.g. &"max_speed_mult").
func get_trait_modifier(modifier_id: StringName) -> float:
	var total: float = 0.0
	for trait_data: Dictionary in traits:
		var modifiers: Dictionary = trait_data.get("modifiers", {})
		total += float(modifiers.get(modifier_id, 0.0))
	return total

func get_portrait_texture() -> Texture2D:
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		return load(portrait_path) as Texture2D
	return null

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"nickname": nickname,
		"position": position,
		"archetype": archetype,
		"handedness": handedness,
		"portrait_path": portrait_path,
		"bio": bio,
		"stat_scales": stat_scales.duplicate(true),
		"attributes": attributes.duplicate(true),
		"traits": traits.duplicate(true),
		"active_ability_ids": active_ability_ids.duplicate(),
	}
