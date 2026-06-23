extends Node

# Carries match settings across scene boundaries.
# Set by MainMenu when the player picks a preset, read by TestRink on _ready.

var current_preset: Dictionary = {}
var last_result: Dictionary = {}

func _ready() -> void:
	current_preset = MatchPreset.find(MatchPreset.ID_STANDARD)

func set_preset(preset: Dictionary) -> void:
	current_preset = preset.duplicate()

func get_preset() -> Dictionary:
	if current_preset.is_empty():
		return MatchPreset.find(MatchPreset.ID_STANDARD)
	return current_preset

func record_result(winner: String, home_score: int, away_score: int) -> void:
	last_result = {
		"winner": winner,
		"home": home_score,
		"away": away_score,
		"preset_title": String(current_preset.get("title", "MATCH")),
	}

func get_last_result() -> Dictionary:
	return last_result
