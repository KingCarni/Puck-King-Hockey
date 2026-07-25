extends Node

# AdventureFlow — the backbone of Adventure Mode. Autoloaded, so run state
# survives scene changes (including playing a real match mid-tournament).
#
# All navigation goes through this manager: screens call goto()/advance()/
# back() and never hardcode scene paths. Adding a screen = add a SCREEN_*
# id, register its scene in SCREEN_SCENES, and route it in advance().
#
# Placeholder systems (quests, rewards, conditions, recruitment) live here
# as small stubs clearly marked for replacement.

const AdventureDataScript = preload("res://scripts/adventure/adventure_data.gd")
const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")

const SCREEN_HUB: StringName = &"hub"
const SCREEN_OVERVIEW: StringName = &"tournament_overview"
const SCREEN_CAPTAIN: StringName = &"captain_select"
const SCREEN_ROSTER: StringName = &"roster"
const SCREEN_QUESTS: StringName = &"quests"
const SCREEN_OPPONENT: StringName = &"opponent_preview"
const SCREEN_RESULTS: StringName = &"results"
const SCREEN_PERK_DRAFT: StringName = &"perk_draft"
const SCREEN_RECRUITMENT: StringName = &"recruitment"
const SCREEN_SHOP: StringName = &"shop"
const SCREEN_FREE_AGENCY: StringName = &"free_agency"
const SCREEN_SETTINGS: StringName = &"settings"

const SCREEN_SCENES: Dictionary = {
	SCREEN_HUB: "res://scenes/adventure/AdventureHub.tscn",
	SCREEN_OVERVIEW: "res://scenes/adventure/TournamentOverview.tscn",
	SCREEN_CAPTAIN: "res://scenes/adventure/CaptainSelect.tscn",
	SCREEN_ROSTER: "res://scenes/adventure/RosterScreen.tscn",
	SCREEN_QUESTS: "res://scenes/adventure/TournamentQuests.tscn",
	SCREEN_OPPONENT: "res://scenes/adventure/OpponentPreview.tscn",
	SCREEN_RESULTS: "res://scenes/adventure/MatchResults.tscn",
	SCREEN_PERK_DRAFT: "res://scenes/adventure/PerkDraft.tscn",
	SCREEN_RECRUITMENT: "res://scenes/adventure/Recruitment.tscn",
	SCREEN_SHOP: "res://scenes/adventure/Shop.tscn",
	SCREEN_FREE_AGENCY: "res://scenes/adventure/FreeAgency.tscn",
	SCREEN_SETTINGS: "res://scenes/adventure/AdventureSettings.tscn",
}

const MAIN_MENU_SCENE: String = "res://scenes/ui/MainMenu.tscn"
const MATCH_SCENE: String = "res://scenes/match/TestRink.tscn"

## One-way gates: back is disabled here so the post-match chain can't be
## walked backwards. Roster in "swap" mode is also gated (see back()).
const GATED_SCREENS: Array[StringName] = [SCREEN_RESULTS, SCREEN_PERK_DRAFT, SCREEN_RECRUITMENT]

# Roster screen behavior: first-time line selection, between-match swap, or
# read-only management from the hub.
const ROSTER_MODE_SELECT: StringName = &"select"
const ROSTER_MODE_SWAP: StringName = &"swap"
const ROSTER_MODE_MANAGE: StringName = &"manage"

# ----------------------------------------------------------- persistent-ish --

var gold: int = 150
var pucks: int = 3
var roster: Array[Resource] = []
var active_ids: Array[StringName] = []
var bench_ids: Array[StringName] = []
var captain_id: StringName = &""
## player id -> condition string. PLACEHOLDER until fatigue system lands.
var conditions: Dictionary = {}

# ------------------------------------------------------------- run state ----

var run_active: bool = false
var match_in_progress: bool = false
var schedule: Array[Dictionary] = []
var current_game: int = 0
var wins: int = 0
var losses: int = 0
var perks: Array[Dictionary] = []
var quests: Array[Dictionary] = []
var last_match: Dictionary = {}
var roster_mode: StringName = ROSTER_MODE_MANAGE

var current_screen: StringName = &""
var _back_stack: Array[StringName] = []

# ------------------------------------------------------------- navigation ---

## Entry point from the title screen.
func open_hub() -> void:
	_ensure_roster()
	_back_stack.clear()
	goto(SCREEN_HUB, false)

func goto(screen_id: StringName, push_current: bool = true) -> void:
	if not SCREEN_SCENES.has(screen_id):
		push_warning("AdventureFlow: unknown screen '%s'" % screen_id)
		return
	if push_current and current_screen != &"" and current_screen != screen_id:
		_back_stack.append(current_screen)
	current_screen = screen_id
	get_tree().change_scene_to_file(String(SCREEN_SCENES[screen_id]))

## Returns true when back navigation was handled (screens consume the input).
func back() -> bool:
	if current_screen in GATED_SCREENS:
		return false
	if current_screen == SCREEN_ROSTER and roster_mode == ROSTER_MODE_SWAP:
		return false
	if current_screen == SCREEN_HUB:
		exit_to_title()
		return true
	if _back_stack.is_empty():
		goto(SCREEN_HUB, false)
		return true
	goto(_back_stack.pop_back(), false)
	return true

## Canonical forward routing — the tournament loop lives here, not in screens.
func advance(from_screen: StringName) -> void:
	match from_screen:
		SCREEN_OVERVIEW:
			goto(SCREEN_CAPTAIN)
		SCREEN_CAPTAIN:
			roster_mode = ROSTER_MODE_SELECT
			goto(SCREEN_ROSTER)
		SCREEN_ROSTER:
			match roster_mode:
				ROSTER_MODE_SELECT:
					goto(SCREEN_QUESTS)
				ROSTER_MODE_SWAP:
					_back_stack.clear()
					goto(SCREEN_OPPONENT, false)
				_:
					back()
		SCREEN_QUESTS:
			goto(SCREEN_OPPONENT)
		SCREEN_OPPONENT:
			launch_match()
		SCREEN_RESULTS:
			if is_tournament_complete():
				goto(SCREEN_RECRUITMENT, false)
			else:
				goto(SCREEN_PERK_DRAFT, false)
		SCREEN_RECRUITMENT:
			end_run()
			_back_stack.clear()
			goto(SCREEN_HUB, false)
		_:
			back()

## Hub buttons route through here so the hub never knows scene paths.
func hub_select(option: StringName) -> void:
	match option:
		&"tournament":
			start_run()
			goto(SCREEN_OVERVIEW)
		&"shop":
			goto(SCREEN_SHOP)
		&"free_agency":
			goto(SCREEN_FREE_AGENCY)
		&"team":
			roster_mode = ROSTER_MODE_MANAGE
			goto(SCREEN_ROSTER)
		&"settings":
			goto(SCREEN_SETTINGS)

func exit_to_title() -> void:
	current_screen = &""
	_back_stack.clear()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# ------------------------------------------------------------- run control --

func start_run() -> void:
	_ensure_roster()
	run_active = true
	current_game = 0
	wins = 0
	losses = 0
	perks.clear()
	last_match.clear()
	quests = AdventureDataScript.draft_quests(3)
	for id: StringName in _all_ids():
		conditions[id] = "FRESH"
	_build_schedule()

func end_run() -> void:
	run_active = false
	match_in_progress = false
	roster_mode = ROSTER_MODE_MANAGE

func _build_schedule() -> void:
	schedule.clear()
	var pool: Array[Dictionary] = AdventureDataScript.team_pool()
	pool.shuffle()
	for index: int in range(3):
		var entry: Dictionary = pool[index % pool.size()].duplicate(true)
		entry["label"] = "GAME %d / 4" % (index + 1)
		entry["is_boss"] = false
		schedule.append(entry)
	var boss: Dictionary = AdventureDataScript.boss_team()
	boss["label"] = "FINAL — BOSS"
	boss["is_boss"] = true
	schedule.append(boss)

func launch_match() -> void:
	match_in_progress = true
	current_screen = &""
	_back_stack.clear()
	var preset: Dictionary = MatchPreset.find(MatchPreset.ID_QUICK_HIT).duplicate(true)
	preset["title"] = "ADVENTURE — %s" % String(current_opponent().get("label", "MATCH"))
	var session: Node = get_node_or_null("/root/MatchSession")
	if session != null and session.has_method("set_preset"):
		session.call("set_preset", preset)
	get_tree().change_scene_to_file(MATCH_SCENE)

## Called by the GameOver screen when an adventure match ends.
func on_match_finished() -> void:
	match_in_progress = false
	var result: Dictionary = {}
	var session: Node = get_node_or_null("/root/MatchSession")
	if session != null and session.has_method("get_last_result"):
		result = session.call("get_last_result")
	var home_score: int = int(result.get("home", 0))
	var away_score: int = int(result.get("away", 0))
	var won: bool = String(result.get("winner", "HOME")) == "HOME"
	# PLACEHOLDER rewards until the economy system lands.
	var gold_earned: int = 120 if won else 40
	var pucks_earned: int = 3 if won else 1
	gold += gold_earned
	pucks += pucks_earned
	if won:
		wins += 1
	else:
		losses += 1
	last_match = {
		"opponent": current_opponent(),
		"home": home_score,
		"away": away_score,
		"won": won,
		"gold_earned": gold_earned,
		"pucks_earned": pucks_earned,
	}
	_bump_quest_progress()
	_refresh_conditions()
	current_game += 1
	_back_stack.clear()
	goto(SCREEN_RESULTS, false)

func add_perk(perk: Dictionary) -> void:
	perks.append(perk.duplicate(true))
	roster_mode = ROSTER_MODE_SWAP
	goto(SCREEN_ROSTER, false)

# PLACEHOLDER: real quest tracking will hook match events.
func _bump_quest_progress() -> void:
	for quest: Dictionary in quests:
		var goal: int = int(quest.get("goal", 1))
		quest["progress"] = mini(int(quest.get("progress", 0)) + randi_range(1, 3), goal)

# PLACEHOLDER: real fatigue will come from minutes played / hits taken.
func _refresh_conditions() -> void:
	for id: StringName in _all_ids():
		conditions[id] = "TIRED" if randf() < 0.3 else "FRESH"

# ---------------------------------------------------------------- queries ---

func is_run_active() -> bool:
	return run_active

func is_adventure_match() -> bool:
	return match_in_progress

func is_tournament_complete() -> bool:
	return current_game >= schedule.size()

func current_opponent() -> Dictionary:
	if schedule.is_empty():
		return {}
	return schedule[mini(current_game, schedule.size() - 1)]

func tournament_label() -> String:
	if not run_active or schedule.is_empty():
		return ""
	if is_tournament_complete():
		return "TOURNAMENT COMPLETE — %dW %dL" % [wins, losses]
	return "%s — %dW %dL" % [String(current_opponent().get("label", "")), wins, losses]

func currencies_label() -> String:
	return "GOLD %d   ·   PUCKS %d" % [gold, pucks]

# ----------------------------------------------------------------- roster ---

func _ensure_roster() -> void:
	if not roster.is_empty():
		return
	roster = AdventureDataScript.starter_roster()
	active_ids.clear()
	bench_ids.clear()
	for index: int in range(roster.size()):
		var id: StringName = _id_of(roster[index])
		if index < 3:
			active_ids.append(id)
		else:
			bench_ids.append(id)
		conditions[id] = "FRESH"
	if not active_ids.is_empty():
		captain_id = active_ids[0]

func player_by_id(id: StringName) -> Resource:
	for definition: Resource in roster:
		if _id_of(definition) == id:
			return definition
	return null

func active_players() -> Array[Resource]:
	return _players_for(active_ids)

func bench_players() -> Array[Resource]:
	return _players_for(bench_ids)

func set_captain(id: StringName) -> void:
	if player_by_id(id) != null:
		captain_id = id

func condition_of(id: StringName) -> String:
	return String(conditions.get(id, "FRESH"))

## Swap two roster slots by player id. Same-list swaps exchange order;
## cross-list swaps exchange active/bench membership.
func swap_players(id_a: StringName, id_b: StringName) -> void:
	if id_a == id_b:
		return
	var slot_a: Dictionary = _find_slot(id_a)
	var slot_b: Dictionary = _find_slot(id_b)
	if slot_a.is_empty() or slot_b.is_empty():
		return
	var list_a: Array[StringName] = active_ids if slot_a["list"] == &"active" else bench_ids
	var list_b: Array[StringName] = active_ids if slot_b["list"] == &"active" else bench_ids
	list_a[slot_a["index"]] = id_b
	list_b[slot_b["index"]] = id_a

func _find_slot(id: StringName) -> Dictionary:
	var index: int = active_ids.find(id)
	if index >= 0:
		return {"list": &"active", "index": index}
	index = bench_ids.find(id)
	if index >= 0:
		return {"list": &"bench", "index": index}
	return {}

func _players_for(ids: Array[StringName]) -> Array[Resource]:
	var players: Array[Resource] = []
	for id: StringName in ids:
		var definition: Resource = player_by_id(id)
		if definition != null:
			players.append(definition)
	return players

func _all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append_array(active_ids)
	ids.append_array(bench_ids)
	return ids

func _id_of(definition: Resource) -> StringName:
	return StringName(definition.get("id")) if definition != null else &""
