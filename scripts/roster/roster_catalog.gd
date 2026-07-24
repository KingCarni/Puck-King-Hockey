class_name RosterCatalog
extends RefCounted

# Static catalog of named player definitions plus archetype fallbacks.
# Definitions are built in code for now; migrating them to .tres resources
# later only requires saving these as PlayerDefinition resources.

const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")

const PORTRAIT_DIR: String = "res://assets/ui/portraits"

static func all_named_ids() -> Array[StringName]:
	return [&"duane_clutzky", &"gronk_mckrunk"]

static func find(player_id: StringName) -> Resource:
	match player_id:
		&"duane_clutzky":
			return duane_clutzky()
		&"gronk_mckrunk":
			return gronk_mckrunk()
	return null

static func duane_clutzky() -> Resource:
	var definition: PlayerDefinitionScript = PlayerDefinitionScript.new()
	definition.id = &"duane_clutzky"
	definition.display_name = "Duane Clutzky"
	definition.nickname = "The Tape Wizard"
	definition.position = "FORWARD"
	definition.archetype = &"playmaker"
	definition.handedness = "LEFT"
	definition.portrait_path = PORTRAIT_DIR + "/duane_clutzky.png"
	definition.bio = "Creative tape wizard. Sees passing lanes nobody else does and hits them without looking."
	definition.stat_scales = {
		# Average skater, slightly quicker shot release.
		&"slap_shot_charge_seconds": 0.92,
	}
	definition.attributes = {
		&"pass_accuracy": 0.88,
		&"pass_assist": 0.90,
		&"pass_power": 0.80,
		&"pass_lead": 0.85,
		&"shot_power_scale": 1.10,
	}
	definition.traits = [
		{
			"id": &"tape_wizard",
			"name": "Tape Wizard",
			"description": "Passes stick to the tape: receivers keep more momentum.",
			"modifiers": {},
		},
	]
	definition.active_ability_ids = [&"one_timer"]
	return definition

static func gronk_mckrunk() -> Resource:
	var definition: PlayerDefinitionScript = PlayerDefinitionScript.new()
	definition.id = &"gronk_mckrunk"
	definition.display_name = "Gronk McKrunk"
	definition.nickname = "The Wrecking Wall"
	definition.position = "DEFENSE"
	definition.archetype = &"enforcer"
	definition.handedness = "RIGHT"
	definition.portrait_path = PORTRAIT_DIR + "/gronk_mckrunk.png"
	definition.bio = "Intimidating heavy hitter. His slapshot dents glass; his hits rearrange rosters."
	definition.stat_scales = {
		# Lower agility, elite checking, huge but slow slapshot.
		&"acceleration": 0.82,
		&"sprint_acceleration": 0.80,
		&"max_speed": 0.88,
		&"sprint_max_speed": 0.87,
		&"check_knockback_force": 1.45,
		&"check_puck_force": 1.30,
		&"check_hit_radius": 1.15,
		&"slap_shot_charge_seconds": 1.50,
	}
	definition.attributes = {
		&"pass_accuracy": 0.30,
		&"pass_assist": 0.30,
		&"pass_power": 0.55,
		&"pass_lead": 0.30,
		&"shot_power_scale": 1.35,
	}
	definition.traits = [
		{
			"id": &"heavy_wind_up",
			"name": "Heavy Wind-Up",
			"description": "Slower to charge, devastating on release.",
			"modifiers": {},
		},
		{
			"id": &"iron_wall",
			"name": "Iron Wall",
			"description": "Checks carry extra weight.",
			"modifiers": {},
		},
	]
	definition.active_ability_ids = [&"body_check_plus"]
	return definition

## Neutral fallback so unnamed scene nodes keep playing exactly as authored.
## stat_scales stay empty (×1.0) and attributes sit at the league average.
static func fallback_definition(node_name: StringName, side: StringName, position: String = "FORWARD") -> Resource:
	var definition: PlayerDefinitionScript = PlayerDefinitionScript.new()
	definition.id = StringName("fallback_" + String(side).to_lower() + "_" + String(node_name).to_snake_case())
	definition.display_name = _fallback_display_name(node_name, side)
	definition.nickname = ""
	definition.position = position
	definition.archetype = &"grinder"
	definition.bio = "Unsigned league skater."
	definition.attributes = {
		&"pass_accuracy": 0.5,
		&"pass_assist": 0.5,
		&"pass_power": 0.5,
		&"pass_lead": 0.5,
		&"shot_power_scale": 1.0,
	}
	return definition

static func _fallback_display_name(node_name: StringName, side: StringName) -> String:
	match node_name:
		&"Player": return "Duane Clutzky"
		&"Player2": return "Brick Malone"
		&"HomeTeammate": return "Gronk McKrunk"
		&"AwayTeammate": return "Axel Frost"
		&"HomeTeammate2": return "Finn O'Flash"
		&"AwayTeammate2": return "Tommy Top Shelf"
	return "Rico Rocket" if side == &"HOME" else "Barry Biscuit"
