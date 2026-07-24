class_name MatchAbilityState
extends RefCounted

# Owns the two team ability containers for a single match.

var home: TeamAbilityState
var away: TeamAbilityState

func _init() -> void:
	home = TeamAbilityState.new(&"HOME")
	away = TeamAbilityState.new(&"AWAY")

func team(side: StringName) -> TeamAbilityState:
	return home if side == &"HOME" else away

func opponent(side: StringName) -> TeamAbilityState:
	return away if side == &"HOME" else home

func register_player(side: StringName, player: Node3D) -> void:
	team(side).register_player(player)

func add_ability(
	side: StringName,
	ability: AbilityDefinition,
	player: Node3D = null
) -> bool:
	return team(side).add_ability(ability, player)

func reset() -> void:
	home.reset()
	away.reset()

func to_dictionary() -> Dictionary:
	return {
		"home": home.to_dictionary(),
		"away": away.to_dictionary(),
	}
