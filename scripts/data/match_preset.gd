extends Resource
class_name MatchPreset

# Static catalog of selectable match presets and a randomizer for adventure mode.

const ID_QUICK_HIT: String = "quick_hit"
const ID_STANDARD: String = "standard"
const ID_MARATHON: String = "marathon"
const ID_SUDDEN_DEATH: String = "sudden_death"
const ID_ADVENTURE: String = "adventure"

# Each preset is a dictionary:
#   id             : String — stable id
#   title          : String — display name (uppercase)
#   blurb          : String — one-line description
#   period_count   : int    — number of periods
#   period_seconds : float  — duration of a single period
#   win_condition  : String — "score" | "first_to" | "sudden_death"
#   first_to_goals : int    — used when win_condition is "first_to" or "sudden_death"
#   mercy_diff     : int    — early end when goal differential >= this (0 = disabled)
#   overtime       : bool   — sudden-death overtime if tied at clock zero
static func catalog() -> Array:
	return [
		{
			"id": ID_QUICK_HIT,
			"title": "QUICK HIT",
			"blurb": "3 periods × 60s. Mercy at +3 goals.",
			"period_count": 3,
			"period_seconds": 60.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 3,
			"overtime": true,
		},
		{
			"id": ID_STANDARD,
			"title": "STANDARD",
			"blurb": "3 periods × 90s. Most goals wins.",
			"period_count": 3,
			"period_seconds": 90.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 0,
			"overtime": true,
		},
		{
			"id": ID_MARATHON,
			"title": "MARATHON",
			"blurb": "3 periods × 3 min. The full brawl.",
			"period_count": 3,
			"period_seconds": 180.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 0,
			"overtime": true,
		},
		{
			"id": ID_SUDDEN_DEATH,
			"title": "SUDDEN DEATH",
			"blurb": "First to 3 goals. No clock.",
			"period_count": 1,
			"period_seconds": 0.0,
			"win_condition": "first_to",
			"first_to_goals": 3,
			"mercy_diff": 0,
			"overtime": false,
		},
		{
			"id": ID_ADVENTURE,
			"title": "ADVENTURE",
			"blurb": "Randomized rules. Equal difficulty.",
			"period_count": 3,
			"period_seconds": 90.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 3,
			"overtime": true,
		},
	]

static func find(preset_id: String) -> Dictionary:
	for preset in catalog():
		if String(preset.get("id", "")) == preset_id:
			return preset
	return catalog()[1]  # default: STANDARD

# Roll an adventure-mode match. Difficulty stays roughly equivalent to STANDARD
# by trading off period count, period length and win conditions.
static func roll_adventure(rng: RandomNumberGenerator = null) -> Dictionary:
	var generator: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		generator.randomize()

	var variants: Array = [
		{
			"title": "ADVENTURE — SPRINT",
			"blurb": "5 short periods. Mercy at +3.",
			"period_count": 5,
			"period_seconds": 45.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 3,
			"overtime": true,
		},
		{
			"title": "ADVENTURE — DUEL",
			"blurb": "First to 4. No clock.",
			"period_count": 1,
			"period_seconds": 0.0,
			"win_condition": "first_to",
			"first_to_goals": 4,
			"mercy_diff": 0,
			"overtime": false,
		},
		{
			"title": "ADVENTURE — DOUBLE OR NOTHING",
			"blurb": "2 long periods. Most goals wins.",
			"period_count": 2,
			"period_seconds": 150.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 0,
			"overtime": true,
		},
		{
			"title": "ADVENTURE — BLITZ",
			"blurb": "3 periods × 60s. Sudden death OT.",
			"period_count": 3,
			"period_seconds": 60.0,
			"win_condition": "score",
			"first_to_goals": 0,
			"mercy_diff": 0,
			"overtime": true,
		},
	]

	var pick: Dictionary = variants[generator.randi_range(0, variants.size() - 1)].duplicate()
	pick["id"] = ID_ADVENTURE
	return pick

static func format_clock(seconds: float) -> String:
	var total: int = int(max(seconds, 0.0))
	var minutes: int = total / 60
	var remaining: int = total % 60
	return "%02d:%02d" % [minutes, remaining]

static func ordinal_period(period_index: int) -> String:
	# period_index is 0-based.
	var n: int = period_index + 1
	var suffix: String = "TH"
	if n == 1:
		suffix = "ST"
	elif n == 2:
		suffix = "ND"
	elif n == 3:
		suffix = "RD"
	return "%d%s PERIOD" % [n, suffix]
