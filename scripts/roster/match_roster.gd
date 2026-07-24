class_name MatchRoster
extends RefCounted

# Match-scoped registry binding skater nodes to player definitions and their
# computed runtime stats. Identity is keyed by node instance, so switching
# the controlled skater never moves or resets a character's stats.

const PlayerRuntimeStatsScript = preload("res://scripts/roster/player_runtime_stats.gd")
const RosterCatalogScript = preload("res://scripts/roster/roster_catalog.gd")
const RosterProgressionScript = preload("res://scripts/roster/roster_progression.gd")

var ability_state: RefCounted = null

var _entries: Dictionary = {}
var _side_players: Dictionary = {}

func setup(match_ability_state: RefCounted) -> void:
	ability_state = match_ability_state

## Bind a definition to a skater node and hand the node its runtime stats.
func assign(player: Node3D, side: StringName, definition: Resource) -> void:
	if player == null or definition == null:
		return
	var team_state: RefCounted = null
	if ability_state != null and ability_state.has_method("team"):
		team_state = ability_state.call("team", side)
	var stats: RefCounted = PlayerRuntimeStatsScript.new()
	stats.setup(definition, player, team_state)
	stats.set_permanent_modifiers(RosterProgressionScript.load_modifiers(definition.get_progression_key()))
	_entries[player.get_instance_id()] = {
		"player": player,
		"side": side,
		"definition": definition,
		"stats": stats,
	}
	var siblings: Array = _side_players.get(side, [])
	if not siblings.has(player):
		siblings.append(player)
	_side_players[side] = siblings
	if player.has_method("set_runtime_stats"):
		player.call("set_runtime_stats", stats)

## Migration safety net: nodes without a named definition get a neutral
## fallback so unmigrated scenes keep playing exactly as authored.
func ensure_assigned(player: Node3D, side: StringName, position: String = "FORWARD") -> void:
	if player == null or _entries.has(player.get_instance_id()):
		return
	assign(player, side, RosterCatalogScript.fallback_definition(player.name, side, position))

func definition_for(player: Node3D) -> Resource:
	if player == null:
		return null
	return _entries.get(player.get_instance_id(), {}).get("definition")

func stats_for(player: Node3D) -> RefCounted:
	if player == null:
		return null
	return _entries.get(player.get_instance_id(), {}).get("stats")

func display_name_for(player: Node3D) -> String:
	var definition: Resource = definition_for(player)
	if definition != null:
		return String(definition.get("display_name"))
	return ""

## Call when a team gains/loses abilities so cached stats recompute.
func invalidate_side(side: StringName) -> void:
	for player: Node3D in _side_players.get(side, []):
		var stats: RefCounted = stats_for(player)
		if stats != null:
			stats.invalidate()

func invalidate_all() -> void:
	for side: StringName in _side_players.keys():
		invalidate_side(side)
