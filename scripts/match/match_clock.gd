extends Node
class_name MatchClock

# Drives the match clock: periods, intermissions, win conditions.
# Emits signals the HUD and TestRink listen to.

signal time_changed(seconds_left: float, period_index: int, period_label: String)
signal period_changed(period_index: int, period_label: String, is_overtime: bool)
signal intermission_started(completed_period_index: int, next_period_index: int)
signal match_started(preset: Dictionary)
signal match_ended(winner: String, home_score: int, away_score: int)

const INTERMISSION_SECONDS: float = 2.25

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
var is_intermission: bool = false

var _home_score: int = 0
var _away_score: int = 0

func _process(delta: float) -> void:
	if not is_running or match_over or is_intermission:
		return
	if period_seconds <= 0.0 and not is_overtime:
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
	is_intermission = false
	match_over = false
	_home_score = 0
	_away_score = 0
	emit_signal("match_started", preset)
	emit_signal("period_changed", period_index, _period_label(), false)
	emit_signal("time_changed", time_left, period_index, _period_label())

func stop() -> void:
	is_running = false

func resume() -> void:
	if not match_over and not is_intermission:
		is_running = true

func register_goal(team: String) -> bool:
	if team == "HOME":
		_home_score += 1
	else:
		_away_score += 1
	if match_over:
		return true
	if win_condition == "first_to" or win_condition == "sudden_death":
		if first_to_goals > 0 and (_home_score >= first_to_goals or _away_score >= first_to_goals):
			_end_match()
			return true
	if is_overtime:
		_end_match()
		return true
	if mercy_diff > 0 and abs(_home_score - _away_score) >= mercy_diff and period_index >= period_count - 1:
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
	if match_over or is_intermission:
		return
	is_running = false
	if period_index + 1 < period_count:
		_begin_intermission(period_index + 1, false)
		return
	if _home_score == _away_score and overtime_enabled and not is_overtime:
		_begin_intermission(period_index, true)
		return
	_end_match()

func _begin_intermission(next_period_index: int, next_is_overtime: bool) -> void:
	is_intermission = true
	emit_signal("intermission_started", period_index, next_period_index)
	var timer: SceneTreeTimer = get_tree().create_timer(INTERMISSION_SECONDS)
	timer.timeout.connect(_finish_intermission.bind(next_period_index, next_is_overtime))

func _finish_intermission(next_period_index: int, next_is_overtime: bool) -> void:
	if match_over:
		return
	is_intermission = false
	is_overtime = next_is_overtime
	period_index = next_period_index
	time_left = 999.0 if is_overtime else period_seconds
	is_running = true
	emit_signal("period_changed", period_index, _period_label(), is_overtime)
	emit_signal("time_changed", time_left, period_index, _period_label())

func _end_match() -> void:
	match_over = true
	is_running = false
	is_intermission = false
	var winner: String = "DRAW"
	if _home_score > _away_score:
		winner = "HOME"
	elif _away_score > _home_score:
		winner = "AWAY"
	emit_signal("match_ended", winner, _home_score, _away_score)
