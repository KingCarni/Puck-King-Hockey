class_name AbilityDefinition
extends RefCounted

# Defines what an ability is. Runtime ownership and stacks live in
# TeamAbilityState rather than on the definition itself.

enum Scope {
	TEAM,
	PLAYER,
}

enum Kind {
	PASSIVE,
	ACTIVE,
}

var id: StringName
var display_name: String
var description: String
var scope: Scope
var kind: Kind
var modifiers: Dictionary
var max_stacks: int

func _init(
	ability_id: StringName,
	ability_name: String,
	ability_description: String,
	ability_scope: Scope,
	ability_kind: Kind,
	ability_modifiers: Dictionary = {},
	ability_max_stacks: int = 1
) -> void:
	id = ability_id
	display_name = ability_name
	description = ability_description
	scope = ability_scope
	kind = ability_kind
	modifiers = ability_modifiers.duplicate(true)
	max_stacks = maxi(ability_max_stacks, 1)

func is_team_ability() -> bool:
	return scope == Scope.TEAM

func is_player_ability() -> bool:
	return scope == Scope.PLAYER

func is_passive() -> bool:
	return kind == Kind.PASSIVE

func is_active() -> bool:
	return kind == Kind.ACTIVE

func get_modifier(modifier_id: StringName, default_value: float = 0.0) -> float:
	return float(modifiers.get(modifier_id, default_value))

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"scope": scope,
		"kind": kind,
		"modifiers": modifiers.duplicate(true),
		"max_stacks": max_stacks,
	}
