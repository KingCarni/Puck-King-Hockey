class_name TeamAbilityState
extends RefCounted

# Match-scoped ability ownership for one team.
# Team abilities apply to every skater on the team. Player abilities are stored
# against a stable player key so changing the controlled skater does not move or
# remove that player's abilities.
#
# Ability arguments are AbilityDefinition instances, referenced via preload so
# resolution never depends on the global class cache.

const AbilityDefinitionScript = preload("res://scripts/hockey/abilities/ability_definition.gd")

var team_id: StringName
var team_abilities: Dictionary = {}
var player_abilities: Dictionary = {}
var registered_players: Dictionary = {}

func _init(id: StringName = &"") -> void:
	team_id = id

func register_player(player: Node3D) -> void:
	if player == null:
		return
	var player_key: StringName = _player_key(player)
	registered_players[player_key] = player
	if not player_abilities.has(player_key):
		player_abilities[player_key] = {}

func unregister_player(player: Node3D) -> void:
	if player == null:
		return
	registered_players.erase(_player_key(player))

func add_ability(ability: RefCounted, player: Node3D = null) -> bool:
	if ability == null:
		return false
	if ability.is_team_ability():
		return _add_stack(team_abilities, ability)
	if player == null:
		return false
	register_player(player)
	var player_key: StringName = _player_key(player)
	var abilities: Dictionary = player_abilities[player_key]
	var added: bool = _add_stack(abilities, ability)
	player_abilities[player_key] = abilities
	return added

func get_team_stack(ability_id: StringName) -> int:
	return int(team_abilities.get(ability_id, {}).get("stacks", 0))

func get_player_stack(player: Node3D, ability_id: StringName) -> int:
	if player == null:
		return 0
	var abilities: Dictionary = player_abilities.get(_player_key(player), {})
	return int(abilities.get(ability_id, {}).get("stacks", 0))

func has_team_ability(ability_id: StringName) -> bool:
	return get_team_stack(ability_id) > 0

func has_player_ability(player: Node3D, ability_id: StringName) -> bool:
	return get_player_stack(player, ability_id) > 0

func get_team_modifier(modifier_id: StringName) -> float:
	return _sum_modifier(team_abilities, modifier_id)

func get_player_modifier(player: Node3D, modifier_id: StringName) -> float:
	if player == null:
		return 0.0
	var abilities: Dictionary = player_abilities.get(_player_key(player), {})
	return _sum_modifier(abilities, modifier_id)

func get_combined_modifier(player: Node3D, modifier_id: StringName) -> float:
	return get_team_modifier(modifier_id) + get_player_modifier(player, modifier_id)

func get_team_ability_entries() -> Array[Dictionary]:
	return _entries_from_store(team_abilities)

func get_player_ability_entries(player: Node3D) -> Array[Dictionary]:
	if player == null:
		return []
	var abilities: Dictionary = player_abilities.get(_player_key(player), {})
	return _entries_from_store(abilities)

func reset() -> void:
	team_abilities.clear()
	player_abilities.clear()
	for player_key: Variant in registered_players.keys():
		player_abilities[player_key] = {}

func to_dictionary() -> Dictionary:
	var players_snapshot: Dictionary = {}
	for player_key: Variant in player_abilities.keys():
		players_snapshot[player_key] = _copy_store(player_abilities[player_key])
	return {
		"team_id": team_id,
		"team_abilities": _copy_store(team_abilities),
		"player_abilities": players_snapshot,
	}

func _add_stack(store: Dictionary, ability: RefCounted) -> bool:
	var entry: Dictionary = store.get(ability.id, {
		"definition": ability,
		"stacks": 0,
	})
	var current_stacks: int = int(entry.get("stacks", 0))
	if current_stacks >= ability.max_stacks:
		# A reward draft must always be resolvable. Treat selecting an already
		# capped ability as a consumed/no-op reward instead of trapping the match
		# behind a draft that can no longer apply any offered option.
		return true
	entry["definition"] = ability
	entry["stacks"] = current_stacks + 1
	store[ability.id] = entry
	return true

func _sum_modifier(store: Dictionary, modifier_id: StringName) -> float:
	var total: float = 0.0
	for raw_entry: Variant in store.values():
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = raw_entry
		var ability: Variant = entry.get("definition")
		if not (ability is AbilityDefinitionScript):
			continue
		var stacks: int = int(entry.get("stacks", 0))
		total += float(ability.get_modifier(modifier_id)) * float(stacks)
	return total

func _entries_from_store(store: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for raw_entry: Variant in store.values():
		if raw_entry is Dictionary:
			entries.append((raw_entry as Dictionary).duplicate(true))
	return entries

func _copy_store(store: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for ability_id: Variant in store.keys():
		var raw_entry: Variant = store[ability_id]
		if raw_entry is Dictionary:
			var entry: Dictionary = raw_entry
			var ability: Variant = entry.get("definition")
			var has_definition: bool = ability is AbilityDefinitionScript
			result[ability_id] = {
				"definition": ability.to_dictionary() if has_definition else {},
				"stacks": int(entry.get("stacks", 0)),
			}
	return result

func _player_key(player: Node3D) -> StringName:
	return StringName(player.name)
