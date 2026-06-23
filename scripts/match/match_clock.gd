extends Node
class_name MatchClock

# Drives the match clock: periods, intermissions, win conditions.
# Emits signals the HUD and TestRink listen to.

signal time_changed(seconds_left: float, period_index: int, period_label: String)
signal period_changed(period_index: int, period_label: String, is_overtime: bool)
signal match_started(preset: Dictionary)
signal match_ended(winner: String, home_score: int, away_score: int)

const INTERMISSION_TICK: float = 0.0  # No intermission for now — could add later.

var preset: Dictionary = {}
var period_count: int = 3
var period_seconds: float = 90.0
var win_condition: String = "score"
var first_to_goals: int = 0
var mercy_diff: int = 0
var overtime_enabled: bool = false

var period_index: int = 0
var time_left: float = 0.0
var is_running: bool = false
var is_overtime: bool = false
var match_over: bool = false

var _home_score: int = 0
var _away_score: int = 0

func _process(delta: float) -> void:
	if not is_running or match_over:
		return
	if period_seconds <= 0.0 and not is_overtime:
		# Untimed mode (e.g. sudden death without overtime tick).
		return
	time_left = max(time_left - delta, 0.0)
	emit_signal("time_changed", time_left, period_index, _period_label())
	if time_left <= 0.0:
		_on_period_end()

func start_match(match_preset: Dictionary) -> void:
	preset = match_preset.duplicate()
	period_count = int(preset.get("period_count", 3))
	period_seconds = float(preset.get("period_seconds", 90.0))
	win_condition = String(preset.get("win_condition", "score"))
	first_to_goals = int(preset.get("first_to_goals", 0))
	mercy_diff = int(preset.get("mercy_diff", 0))
	overtime_enabled = bool(preset.get("overtime", false))

	period_index = 0
	time_left = period_seconds
	is_running = true
	is_overtime = false
	match_over = false
	_home_score = 0
	_away_score = 0

	emit_signal("match_started", preset)
	emit_signal("period_changed", period_index, _period_label(), false)
	emit_signal("time_changed", time_left, period_index, _period_label())

func stop() -> void:
	is_running = false

func resume() -> void:
	if not match_over:
		is_running = true

func register_goal(team: String) -> bool:
	# Returns true if the match should now end.
	if team == "HOME":
		_home_score += 1
	else:
		_away_score += 1

	if match_over:
		return true

	# First-to-N or sudden-death victory.
	if win_condition == "first_to" or win_condition == "sudden_death":
		if first_to_goals > 0:
			if _home_score >= first_to_goals or _away_score >= first_to_goals:
				_end_match()
				return true

	# Sudden-death overtime: any goal ends it.
	if is_overtime:
		_end_match()
		return true

	# Mercy rule.
	if mercy_diff > 0 and abs(_home_score - _away_score) >= mercy_diff and period_index >= period_count - 1:
		# Only trigger mercy in the final period or later.
		if period_index >= period_count - 1:
			_end_match()
			return true

	return false

func get_home_score() -> int:
	return _home_score

func get_away_score() -> int:
	return _away_score

func get_seconds_left() -> float:
	return time_left

func get_period_label() -> String:
	return _period_label()

func _period_label() -> String:
	if is_overtime:
		return "OVERTIME"
	if period_seconds <= 0.0 and win_condition == "first_to":
		return "FIRST TO %d" % first_to_goals
	return MatchPreset.ordinal_period(period_index)

func _on_period_end() -> void:
	if match_over:
		return

	if period_index + 1 < period_count:
		period_index += 1
		time_left = period_seconds
		is_running = true
		emit_signal("period_changed", period_index, _period_label(), false)
		emit_signal("time_changed", time_left, period_index, _period_label())
		return

	# Final period over.
	if _home_score == _away_score and overtime_enabled and not is_overtime:
		is_overtime = true
		time_left = 999.0  # OT clock counts up visually but ends on next goal.
		is_running = true
		emit_signal("period_changed", period_index, _period_label(), true)
		emit_signal("time_changed", time_left, period_index, _period_label())
		return

	_end_match()

func _end_match() -> void:
	match_over = true
	is_running = false
	var winner: String = "DRAW"
	if _home_score > _away_score:
		winner = "HOME"
	elif _away_score > _home_score:
		winner = "AWAY"
	emit_signal("match_ended", winner, _home_score, _away_score)
