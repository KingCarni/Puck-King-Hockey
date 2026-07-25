class_name AdventureData
extends RefCounted

# Placeholder data pools for the Adventure Mode shell. Everything here is
# meant to be replaced by real content systems (shop, quests, recruitment,
# opponent design) — screens read these shapes, so later systems only need
# to produce the same dictionaries/definitions.

const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")
const RosterCatalogScript = preload("res://scripts/roster/roster_catalog.gd")

# ------------------------------------------------------------------ roster --

## Starting Adventure squad: the two named characters plus placeholder
## PlayerDefinitions. First three are the opening line, rest ride the bench.
static func starter_roster() -> Array[Resource]:
	var roster: Array[Resource] = []
	roster.append(RosterCatalogScript.duane_clutzky())
	roster.append(RosterCatalogScript.gronk_mckrunk())
	roster.append(_placeholder_player(&"finn_oflash", "Finn O'Flash", "The Blur", "FORWARD", &"speedster",
		{&"max_speed": 1.12, &"sprint_max_speed": 1.10, &"acceleration": 1.14},
		{&"pass_accuracy": 0.55, &"pass_assist": 0.5, &"pass_power": 0.5, &"pass_lead": 0.6, &"shot_power_scale": 0.95}))
	roster.append(_placeholder_player(&"brick_malone", "Brick Malone", "The Foundation", "DEFENSE", &"defensive_defenseman",
		{&"check_knockback_force": 1.2, &"max_speed": 0.95},
		{&"pass_accuracy": 0.45, &"pass_assist": 0.45, &"pass_power": 0.55, &"pass_lead": 0.4, &"shot_power_scale": 1.0}))
	roster.append(_placeholder_player(&"tommy_top_shelf", "Tommy Top Shelf", "Where Mama Hides The Cookies", "FORWARD", &"sniper",
		{&"slap_shot_charge_seconds": 0.9},
		{&"pass_accuracy": 0.6, &"pass_assist": 0.55, &"pass_power": 0.5, &"pass_lead": 0.55, &"shot_power_scale": 1.25}))
	return roster

## Placeholder free agents / recruits shown by Recruitment and Free Agency.
static func recruit_pool() -> Array[Resource]:
	var pool: Array[Resource] = []
	pool.append(_placeholder_player(&"axel_frost", "Axel Frost", "The Iceman", "DEFENSE", &"two_way_forward",
		{}, {&"pass_accuracy": 0.6, &"shot_power_scale": 1.05}))
	pool.append(_placeholder_player(&"rico_rocket", "Rico Rocket", "Launch Pad", "FORWARD", &"power_forward",
		{}, {&"pass_accuracy": 0.5, &"shot_power_scale": 1.15}))
	pool.append(_placeholder_player(&"barry_biscuit", "Barry Biscuit", "Fresh From The Oven", "FORWARD", &"grinder",
		{}, {&"pass_accuracy": 0.5, &"shot_power_scale": 1.0}))
	return pool

static func _placeholder_player(id: StringName, display_name: String, nickname: String, position: String, archetype: StringName, scales: Dictionary, attributes: Dictionary) -> Resource:
	var definition: PlayerDefinitionScript = PlayerDefinitionScript.new()
	definition.id = id
	definition.display_name = display_name
	definition.nickname = nickname
	definition.position = position
	definition.archetype = archetype
	definition.portrait_path = "res://assets/ui/portraits/%s.png" % String(id)
	definition.bio = "Placeholder adventure skater."
	definition.stat_scales = scales
	definition.attributes = attributes
	return definition

# ------------------------------------------------------------- tournaments --

## Placeholder opponent teams. `monogram` stands in for a logo until art
## lands; `color` drives the placeholder badge and accents.
static func team_pool() -> Array[Dictionary]:
	return [
		{
			"id": &"ice_vipers", "name": "ICE VIPERS", "monogram": "IV",
			"color": Color(0.10, 0.75, 0.65),
			"modifier": "SLICK ICE — everyone skates 10% faster.",
			"roster": ["Sly Fangston", "Venom Volkov", "Coily Jones"],
		},
		{
			"id": &"rust_town_wreckers", "name": "RUST TOWN WRECKERS", "monogram": "RW",
			"color": Color(0.85, 0.45, 0.10),
			"modifier": "DEMOLITION DERBY — checks hit 25% harder.",
			"roster": ["Sledge Hammerson", "Rivet Rosie", "Crash Kowalski"],
		},
		{
			"id": &"polar_reapers", "name": "POLAR REAPERS", "monogram": "PR",
			"color": Color(0.55, 0.80, 1.0),
			"modifier": "FROZEN PUCK — the puck glides further.",
			"roster": ["Frostbite Phil", "Aurora Axelsen", "Chill Whitmore"],
		},
		{
			"id": &"gold_tooth_gators", "name": "GOLD TOOTH GATORS", "monogram": "GG",
			"color": Color(0.75, 0.65, 0.10),
			"modifier": "HIGH STAKES — double gold, tired legs.",
			"roster": ["Snappy Goldman", "Bayou Bev", "Chomp Charlie"],
		},
	]

static func boss_team() -> Dictionary:
	return {
		"id": &"crown_breakers", "name": "KING KARNAGE & THE CROWN BREAKERS", "monogram": "KK",
		"color": Color(0.80, 0.08, 0.10),
		"modifier": "ROYAL RUMBLE — no whistles, constant pressure.",
		"boss_rule": "THE KING'S DECREE — King Karnage's goals count double.",
		"roster": ["King Karnage", "Duke Damage", "Baron Von Bruise"],
	}

# ------------------------------------------------------------------- perks --

static func perk_pool() -> Array[Dictionary]:
	return [
		{"id": &"rocket_fuel", "title": "ROCKET FUEL", "description": "Team skating +8% for this tournament."},
		{"id": &"fresh_tape", "title": "FRESH TAPE", "description": "Pass accuracy +10% for this tournament."},
		{"id": &"iron_pads", "title": "IRON PADS", "description": "Checks hit 15% harder for this tournament."},
		{"id": &"lucky_horseshoe", "title": "LUCKY HORSESHOE", "description": "+25% gold from the next two matches."},
		{"id": &"energy_bar", "title": "ENERGY BAR", "description": "One tired skater starts the next match FRESH."},
		{"id": &"crowd_favorite", "title": "CROWD FAVORITE", "description": "Home crowd boost: +5% everything, final period."},
	]

## Placeholder draft: pick `count` distinct perks.
static func draft_perks(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = perk_pool()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

# ------------------------------------------------------------------ quests --

static func quest_pool() -> Array[Dictionary]:
	return [
		{"id": &"goal_rush", "title": "GOAL RUSH", "description": "Score 6 goals this tournament.", "goal": 6},
		{"id": &"bone_rattler", "title": "BONE RATTLER", "description": "Land 10 body checks.", "goal": 10},
		{"id": &"tape_to_tape", "title": "TAPE TO TAPE", "description": "Complete 12 passes.", "goal": 12},
		{"id": &"shutout_king", "title": "SHUTOUT KING", "description": "Win a match without conceding.", "goal": 1},
		{"id": &"comeback_kid", "title": "COMEBACK KID", "description": "Win after trailing.", "goal": 1},
	]

static func draft_quests(count: int = 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = quest_pool()
	pool.shuffle()
	var quests: Array[Dictionary] = []
	for quest: Dictionary in pool.slice(0, mini(count, pool.size())):
		var entry: Dictionary = quest.duplicate(true)
		entry["progress"] = 0
		quests.append(entry)
	return quests

# --------------------------------------------------------------- shop (WIP) --

static func shop_stock() -> Array[Dictionary]:
	return [
		{"title": "CARBON STICK", "price": 220, "description": "Shot power +5%. (Equipment system coming soon.)"},
		{"title": "WAXED LACES", "price": 140, "description": "Acceleration +4%. (Equipment system coming soon.)"},
		{"title": "LUCKY MOUTHGUARD", "price": 90, "description": "??? (Item system coming soon.)"},
		{"title": "MYSTERY CRATE", "price": 300, "description": "Contains one random item. (Coming soon.)"},
	]
