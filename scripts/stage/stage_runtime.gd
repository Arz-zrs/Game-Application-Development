class_name StageRuntime
extends RefCounted

var config: StageConfig
var stage_remaining: float
var activities: Array[ActivityRuntime] = []
var mini_game_points: int = 0
var bonus_points: int = 0
var great_count: int = 0
var awesome_count: int = 0
var failed_count: int = 0

func _init(stage_config: StageConfig) -> void:
	config = stage_config
	stage_remaining = stage_config.stage_duration
	for activity_config in stage_config.activities:
		activities.append(ActivityRuntime.new(activity_config))

func get_available_count() -> int:
	var count: int = 0
	for activity in activities:
		if activity.state == ActivityRuntime.State.AVAILABLE:
			count += 1
	return count

func get_unhandled_count() -> int:
	var count: int = 0
	for activity in activities:
		if not activity.resolved:
			count += 1
	return count

func get_final_score() -> int:
	return mini_game_points + bonus_points

func resolve_activity(activity: ActivityRuntime, result: int) -> int:
	if activity == null or activity.resolved:
		return 0
	var points: int = ScoreResolver.resolve(activity, result)
	if result == ScoreResolver.Result.AWESOME:
		awesome_count += 1
	elif result == ScoreResolver.Result.GREAT:
		great_count += 1
	elif result == ScoreResolver.Result.FAILED:
		failed_count += 1
	mini_game_points += points
	return points

func get_possible_mini_game_points() -> int:
	var possible_points: int = 0
	for activity in activities:
		if activity.config:
			possible_points += activity.config.awesome_points
	return possible_points

func get_star_count() -> int:
	var possible_points: int = get_possible_mini_game_points()
	if possible_points <= 0:
		return 0
	var ratio: float = float(mini_game_points) / float(possible_points)
	if ratio >= config.three_star_percent:
		return 3
	if ratio >= config.two_star_percent:
		return 2
	if ratio >= config.one_star_percent:
		return 1
	return 0
