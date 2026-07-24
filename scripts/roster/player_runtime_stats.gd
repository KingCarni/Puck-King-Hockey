class_name PlayerRuntimeStats
extends RefCounted

# Computed stat layer for one skater in one match.
#
#   node baseline (controller export)
#   × definition stat scale
#   + permanent progression / equipment / trait / ability / buff "_add"
#   × (1 + permanent / equipment / trait / ability / buff "_mult")
#   = runtime stat
#
# Controllers call get_scaled()/get_attribute() every frame; results are
# cached and invalidated whenever a modifier layer changes (invalidate()).
# Controllers must never write computed values back onto their exports.

const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")

## Some existing catalog modifiers predate the "<stat>_mult" convention.
const LEGACY_MULT_ALIASES: Dictionary = {
	&"check_knockback_force": [&"check_knockback_mult"],
	&"pickup_radius_scale": [&"pickup_radius_mult"],
}

var definition: Resource = null
var player: Node3D = null
var team_state: RefCounted = null
## Permanent Adventure Mode progression: modifier id → float. Loaded from
## save data in the future (see roster_progression.gd).
var permanent_modifiers: Dictionary = {}
## Equipment bonuses: modifier id → float. Future equipment system hook.
var equipment_modifiers: Dictionary = {}
## Temporary match buffs outside the ability system: modifier id → float.
var buff_modifiers: Dictionary = {}

var _cache: Dictionary = {}

func setup(player_definition: Resource, player_node: Node3D, team_ability_state: RefCounted) -> void:
	definition = player_definition
	player = player_node
	team_state = team_ability_state
	invalidate()

func invalidate() -> void:
	_cache.clear()

## Stat with a node baseline (movement, checking, carry, charge time...).
## `node_base` is the controller's authored export value.
func get_scaled(stat_id: StringName, node_base: float) -> float:
	var cache_key: StringName = stat_id
	if _cache.has(cache_key):
		return float(_cache[cache_key])
	var scale: float = 1.0
	if definition != null and definition is PlayerDefinitionScript:
		scale = definition.get_stat_scale(stat_id)
	var value: float = (node_base * scale + _sum_add(stat_id)) * (1.0 + _sum_mult(stat_id))
	_cache[cache_key] = value
	return value

## Absolute attribute (pass ratings, shot power scale...). No node baseline.
func get_attribute(attribute_id: StringName, default_value: float = 0.5) -> float:
	var cache_key: StringName = StringName("attr/" + String(attribute_id))
	if _cache.has(cache_key):
		return float(_cache[cache_key])
	var base: float = default_value
	if definition != null and definition is PlayerDefinitionScript:
		base = definition.get_attribute(attribute_id, default_value)
	var value: float = (base + _sum_add(attribute_id)) * (1.0 + _sum_mult(attribute_id))
	_cache[cache_key] = value
	return value

func set_permanent_modifiers(modifiers: Dictionary) -> void:
	permanent_modifiers = modifiers.duplicate(true)
	invalidate()

func set_equipment_modifiers(modifiers: Dictionary) -> void:
	equipment_modifiers = modifiers.duplicate(true)
	invalidate()

func add_buff_modifier(modifier_id: StringName, amount: float) -> void:
	buff_modifiers[modifier_id] = float(buff_modifiers.get(modifier_id, 0.0)) + amount
	invalidate()

func clear_buffs() -> void:
	buff_modifiers.clear()
	invalidate()

func _sum_add(stat_id: StringName) -> float:
	return _sum_modifier(StringName(String(stat_id) + "_add"))

func _sum_mult(stat_id: StringName) -> float:
	var total: float = _sum_modifier(StringName(String(stat_id) + "_mult"))
	for alias: StringName in LEGACY_MULT_ALIASES.get(stat_id, []):
		total += _sum_modifier(alias)
	return total

func _sum_modifier(modifier_id: StringName) -> float:
	var total: float = 0.0
	total += float(permanent_modifiers.get(modifier_id, 0.0))
	total += float(equipment_modifiers.get(modifier_id, 0.0))
	total += float(buff_modifiers.get(modifier_id, 0.0))
	if definition != null and definition is PlayerDefinitionScript:
		total += definition.get_trait_modifier(modifier_id)
	if team_state != null and team_state.has_method("get_combined_modifier"):
		total += float(team_state.call("get_combined_modifier", player, modifier_id))
	return total
