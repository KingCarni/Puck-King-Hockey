extends Node

# Walks the Adventure shell: hub + every hub screen, the pre-tournament
# chain, simulated results for the full schedule (perk drafts + roster
# swaps in between), recruitment, back to hub, then launches one real
# match from Opponent Preview to prove the gameplay handoff.

var _out_dir: String = "user://"
var _flow: Node = null
var _shots: int = 0

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in range(args.size() - 1):
		if args[index] == "--out-dir":
			_out_dir = args[index + 1]
	_flow = get_node_or_null("/root/AdventureFlow")
	if _flow == null:
		printerr("adventure_probe: FAIL — AdventureFlow autoload missing")
		get_tree().quit(1)
		return
	_run()

func _run() -> void:
	await _settle()
	_flow.call("open_hub")
	await _shot("hub")

	for option: Array in [["shop", &"shop"], ["free_agency", &"free_agency"], ["team", &"team"], ["settings", &"settings"]]:
		_flow.call("hub_select", option[1])
		await _shot(String(option[0]))
		_flow.call("back")
		await _settle()

	_flow.call("hub_select", &"tournament")
	await _shot("overview")
	await _advance()  # -> captain select
	await _shot("captain_select")
	await _advance()  # -> roster (select mode)
	var active: Array = _flow.get("active_ids")
	var bench: Array = _flow.get("bench_ids")
	if active.size() >= 3 and bench.size() >= 1:
		_flow.call("swap_players", active[2], bench[0])
	await _shot("roster_select")
	await _advance()  # -> quests
	await _shot("quests")
	await _advance_to_opponent_shot("opponent_game1")

	# Simulated tournament: pretend each match ran, walk the post-match chain.
	var guard: int = 0
	while not bool(_flow.call("is_tournament_complete")) and guard < 8:
		guard += 1
		_flow.set("match_in_progress", true)
		var session: Node = get_node_or_null("/root/MatchSession")
		if session != null:
			session.call("record_result", "HOME" if guard != 2 else "AWAY", 3, 1 if guard != 2 else 4)
		_flow.call("on_match_finished")
		await _shot("results_game%d" % guard)
		await _advance()  # results -> perk draft or recruitment
		if StringName(_flow.get("current_screen")) == &"perk_draft":
			await _shot("perk_draft_game%d" % guard)
			var perks: Array = preload("res://scripts/adventure/adventure_data.gd").draft_perks(1)
			_flow.call("add_perk", perks[0])  # -> roster swap
			await _shot("roster_swap_game%d" % guard)
			await _advance()  # -> opponent preview
			await _settle()

	await _shot("recruitment")
	await _advance()  # -> hub, run ended
	await _shot("hub_after_run")

	var final_screen: StringName = StringName(_flow.get("current_screen"))
	if final_screen != &"hub":
		printerr("adventure_probe: FAIL — expected hub, got %s" % final_screen)
		get_tree().quit(1)
		return

	# Prove the real match handoff: enter a fresh tournament and hit PLAY.
	_flow.call("hub_select", &"tournament")
	await _settle()
	# overview -> captain -> roster -> quests -> opponent -> launch match
	for _i: int in range(5):
		await _advance()
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://scenes/match/TestRink.tscn":
		await _wait_frames(90)
		await _shot("real_match")
		print("adventure_probe: PASS — %d screenshots, real match loaded" % _shots)
		get_tree().quit(0)
	else:
		printerr("adventure_probe: FAIL — match scene did not load (on %s)" % StringName(_flow.get("current_screen")))
		get_tree().quit(1)

func _advance() -> void:
	_flow.call("advance", _flow.get("current_screen"))
	await _settle()

func _advance_to_opponent_shot(shot_name: String) -> void:
	await _advance()
	await _shot(shot_name)

func _settle() -> void:
	await _wait_frames(14)

func _wait_frames(count: int) -> void:
	for _i: int in range(count):
		await get_tree().process_frame

func _shot(shot_name: String) -> void:
	await _settle()
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = _out_dir.path_join("adv_%02d_%s.png" % [_shots, shot_name])
	var error: int = image.save_png(path)
	_shots += 1
	print("adventure_probe: saved %s (error=%d)" % [path, error])
