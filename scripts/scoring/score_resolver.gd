class_name ScoreResolver
extends RefCounted

enum Result {
	FAILED,
	GREAT,
	AWESOME,
}

static func get_result(activity: ActivityConfig, objective_reached: bool, remaining_time: float, errors: int) -> int:
	if activity == null:
		return Result.FAILED
	if not objective_reached or remaining_time <= 0.0:
		return Result.FAILED
	var meets_time: bool = remaining_time >= activity.awesome_remaining_time
	var meets_errors: bool = errors <= activity.awesome_max_errors
	if meets_time and meets_errors:
		return Result.AWESOME
	return Result.GREAT

static func get_points(result: int, activity: ActivityConfig) -> int:
	match result:
		Result.AWESOME:
			return activity.awesome_points
		Result.GREAT:
			return activity.great_points
		_:
			return 0

static func resolve(activity_runtime: ActivityRuntime, result: int) -> int:
	if activity_runtime == null or activity_runtime.resolved:
		return 0
	if not activity_runtime.resolve(result):
		return 0
	return get_points(result, activity_runtime.config)

static func get_stars(stage_runtime: StageRuntime) -> int:
	if stage_runtime == null:
		return 0
	return stage_runtime.get_star_count()
