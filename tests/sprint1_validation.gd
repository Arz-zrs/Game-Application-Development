extends SceneTree


func _init() -> void:
	_run_validation()
	quit()


func _run_validation() -> void:
	_validate_countdown_pause_resume()
	_validate_scoring()
	_validate_duplicate_resolution()
	print("Sprint 1 validation passed")


func _validate_countdown_pause_resume() -> void:
	var countdown_script: GDScript = load("res://scripts/timers/countdown_timer.gd")
	var countdown = countdown_script.new(10.0, 3.0)
	countdown.start()
	countdown.tick(4.0)
	assert(countdown.remaining == 6.0)
	countdown.pause()
	countdown.tick(5.0)
	assert(countdown.remaining == 6.0)
	countdown.resume()
	countdown.tick(6.0)
	assert(countdown.finished)
	assert(countdown.remaining == 0.0)


func _validate_scoring() -> void:
	var activity_script: GDScript = load("res://scripts/stage/activity_config.gd")
	var activity = activity_script.new()
	activity.id = "test"
	activity.great_points = 100
	activity.awesome_points = 150
	activity.awesome_remaining_time = 5.0
	activity.awesome_max_errors = 1

	var resolver_script: GDScript = load("res://scripts/scoring/score_resolver.gd")
	assert(resolver_script.call("get_result", activity, false, 8.0, 0) == 0)
	assert(resolver_script.call("get_result", activity, true, 8.0, 1) == 2)
	assert(resolver_script.call("get_result", activity, true, 4.0, 0) == 1)
	assert(resolver_script.call("get_result", activity, true, 0.0, 0) == 0)


func _validate_duplicate_resolution() -> void:
	var stage_config_script: GDScript = load("res://scripts/stage/stage_config.gd")
	var stage_config = stage_config_script.new()
	stage_config.stage_duration = 180.0
	var activity_script: GDScript = load("res://scripts/stage/activity_config.gd")
	var activity = activity_script.new()
	activity.id = "one"
	activity.great_points = 100
	activity.awesome_points = 150
	stage_config.activities.append(activity)

	var runtime_script: GDScript = load("res://scripts/stage/stage_runtime.gd")
	var runtime = runtime_script.new(stage_config)
	var activity_runtime = runtime.activities[0]

	assert(runtime.resolve_activity(activity_runtime, 2) == 150)
	assert(runtime.resolve_activity(activity_runtime, 2) == 0)
	assert(runtime.mini_game_points == 150)
	assert(runtime.awesome_count == 1)
	assert(runtime.get_star_count() >= 3)
