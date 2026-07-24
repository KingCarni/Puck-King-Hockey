class_name MatchAbilityState
extends RefCounted

# Owns the two team ability containers for a single match.
#
# Cross-script references use preloads instead of global class names so this
# layer never depends on Godot's global class cache being warm (which broke
# with "Could not find type ... in the current scope" on fresh imports).

const TeamAbilityStateScript = preload("res://scripts/hockey/abilities/team_ability_state.gd")

var home: RefCounted
var away: RefCounted

func _init() -> void:
	home = TeamAbilityStateScript.new(&"HOME")
	away = TeamAbilityStateScript.new(&"AWAY")

func team(side: StringName) -> RefCounted:
	return home if side == &"HOME" else away

func opponent(side: StringName) -> RefCounted:
	return away if side == &"HOME" else home

func register_player(side: StringName, player: Node3D) -> void:
	team(side).register_player(player)

func add_ability(side: StringName, ability: RefCounted, player: Node3D = null) -> bool:
	return team(side).add_ability(ability, player)

func reset() -> void:
	home.reset()
	away.reset()

func to_dictionary() -> Dictionary:
	return {
		"home": home.to_dictionary(),
		"away": away.to_dictionary(),
	}
