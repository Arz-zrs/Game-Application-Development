extends SceneTree

var failures: int = 0
var captured_result: int = -1
var captured_remaining: float = -1.0
var captured_actions: int = -1
var captured_errors: int = -1
var warning_count: int = 0
var completion_count: int = 0

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	_validate_countdown_signals()
	_validate_scoring_and_stars()
	await _validate_stage_timers()
	await _validate_trash_collector()
	await _validate_waste_sorting()
	await _validate_drain_cleaner()
	await _validate_river_cleaner()
	await _validate_pipe_puzzle()
	await _validate_scene_loads()
	if failures == 0:
		print("Sprint 8 validation passed")
		quit(0)
	else:
		push_error("Sprint 8 validation failed: %d check(s)" % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _capture_mini_game_result(result: int, remaining: float, actions: int, errors: int) -> void:
	captured_result = result
	captured_remaining = remaining
	captured_actions = actions
	captured_errors = errors

func _capture_warning() -> void:
	warning_count += 1

func _capture_completion() -> void:
	completion_count += 1

func _reset_capture() -> void:
	captured_result = -1
	captured_remaining = -1.0
	captured_actions = -1
	captured_errors = -1

func _validate_stage_timers() -> void:
	var stage = await _instantiate_scene("res://scenes/game/levels/level_1.tscn")
	if stage == null:
		return
	stage.bubble_spawn_remaining = 100.0
	var activity = stage.stage_runtime.activities[0]
	activity.make_available()
	activity.bubble_remaining = 20.0
	_check(activity.open(), "Available activity should open.")
	var mock_mini_game := Node.new()
	stage.add_child(mock_mini_game)
	stage.active_mini_game = mock_mini_game
	stage.mini_game_active = true
	var stage_before: float = stage.stage_runtime.stage_remaining
	stage.call("_process", 2.0)
	_check(is_equal_approx(stage.stage_runtime.stage_remaining, stage_before - 2.0), "Stage time should continue during a mini-game.")
	_check(is_equal_approx(activity.bubble_remaining, 20.0), "Active mini-game should pause its bubble timer.")
	mock_mini_game.free()
	stage.active_mini_game = null
	stage.mini_game_active = false
	_check(activity.leave_unfinished(), "Unfinished activity should return to available.")
	stage.call("_process", 1.0)
	_check(is_equal_approx(activity.bubble_remaining, 19.0), "Returning unfinished should resume bubble time from its remainder.")
	await _remove_scene(stage)

	var stage_two = await _instantiate_scene("res://scenes/game/levels/level_2.tscn")
	if stage_two:
		_check(stage_two.stage_runtime.activities.size() == 4, "Stage 2 should configure four activity types.")
		_check(stage_two.stage_runtime.config.stage_duration == 210.0, "Stage 2 should use its configured duration.")
		await _remove_scene(stage_two)

	var stage_three = await _instantiate_scene("res://scenes/game/levels/level_3.tscn")
	if stage_three:
		_check(stage_three.stage_runtime.activities.size() == 5, "Stage 3 should include all five activity types.")
		_check(stage_three.stage_runtime.config.stage_duration == 240.0, "Stage 3 should use its configured duration.")
		await _remove_scene(stage_three)

func _validate_countdown_signals() -> void:
	var timer_script: GDScript = load("res://scripts/timers/countdown_timer.gd")
	var timer = timer_script.new(2.0, 1.0)
	timer.warning.connect(_capture_warning)
	timer.completed.connect(_capture_completion)
	timer.start()
	timer.tick(1.0)
	_check(warning_count == 1, "Countdown warning should emit once at the configured threshold.")
	timer.pause()
	timer.tick(0.5)
	_check(is_equal_approx(timer.remaining, 1.0), "Paused countdown should retain its remaining time.")
	timer.resume()
	timer.tick(1.0)
	timer.tick(1.0)
	_check(completion_count == 1, "Countdown completion should emit exactly once.")
	_check(timer.remaining == 0.0, "Countdown should clamp at zero.")

func _validate_scoring_and_stars() -> void:
	var activity_script: GDScript = load("res://scripts/stage/activity_config.gd")
	var stage_config_script: GDScript = load("res://scripts/stage/stage_config.gd")
	var runtime_script: GDScript = load("res://scripts/stage/stage_runtime.gd")
	var resolver_script: GDScript = load("res://scripts/scoring/score_resolver.gd")
	var stage_config = stage_config_script.new()
	for index in range(4):
		var activity = activity_script.new()
		activity.id = "score_%d" % index
		activity.great_points = 100
		activity.awesome_points = 150
		stage_config.activities.append(activity)
	var runtime = runtime_script.new(stage_config)

	_check(resolver_script.call("get_result", stage_config.activities[0], false, 20.0, 0) == 0, "Unmet objective must fail.")
	_check(resolver_script.call("get_points", 0, stage_config.activities[0]) == 0, "FAILED must award zero points.")
	_check(resolver_script.call("get_points", 1, stage_config.activities[0]) == 100, "GREAT must award configured points.")
	_check(resolver_script.call("get_points", 2, stage_config.activities[0]) == 150, "AWESOME must award configured points.")
	_check(runtime.resolve_activity(runtime.activities[0], 0) == 0, "FAILED must award zero points.")
	_check(runtime.failed_count == 1, "FAILED must be counted once.")
	_check(runtime.resolve_activity(runtime.activities[0], 2) == 0, "A resolved activity must not award points twice.")

	_check(runtime.resolve_activity(runtime.activities[1], 2) == 150, "AWESOME must award configured points.")
	_check(runtime.get_star_count() == 1, "25% score should award one star.")
	_check(runtime.resolve_activity(runtime.activities[2], 2) == 150, "Second AWESOME should award configured points.")
	_check(runtime.get_star_count() == 2, "50% score should award two stars.")
	_check(runtime.resolve_activity(runtime.activities[3], 2) == 150, "Third AWESOME should award configured points.")
	_check(runtime.get_star_count() == 3, "75% score should award three stars.")
	runtime.bonus_points = 50
	_check(runtime.get_final_score() == 500, "Final score should include bonus points.")

func _instantiate_scene(path: String):
	var packed_scene: PackedScene = load(path)
	_check(packed_scene != null, "Could not load scene: %s" % path)
	if packed_scene == null:
		return null
	var instance: Node = packed_scene.instantiate()
	root.add_child(instance)
	await process_frame
	return instance

func _remove_scene(instance: Node) -> void:
	if is_instance_valid(instance):
		instance.queue_free()
		await process_frame

func _validate_trash_collector() -> void:
	_reset_capture()
	var scene = await _instantiate_scene("res://scenes/game/mini_games/trash_collector/trash_collector.tscn")
	if scene == null:
		return
	scene.target_count = 2
	scene.call("_spawn_trash_items")
	var items: Array = scene.get_node("%ItemsLayer").get_children()
	scene.mini_game_finished.connect(_capture_mini_game_result)
	scene.call("_collect_item", items[0])
	scene.call("_collect_item", items[1])
	_check(captured_result == 2, "Collecting all trash quickly should resolve as AWESOME.")
	_check(captured_actions == 2, "Trash Collector should report its collected count.")
	await _remove_scene(scene)

func _validate_waste_sorting() -> void:
	_reset_capture()
	var success_scene = await _instantiate_scene("res://scenes/game/mini_games/waste_sorting/waste_sorting.tscn")
	if success_scene == null:
		return
	success_scene.mini_game_finished.connect(_capture_mini_game_result)
	var items: Array = success_scene.get_node("%WasteItems").get_children()
	for index in range(items.size()):
		success_scene.call("_select_item", items[index], index % 4)
		success_scene.call("_on_bin_pressed", index % 4)
	_check(captured_result == 2, "Sorting every item correctly should resolve as AWESOME.")
	_check(captured_actions == 8, "Waste Sorting should report all correct sorts.")
	await _remove_scene(success_scene)

	_reset_capture()
	var failure_scene = await _instantiate_scene("res://scenes/game/mini_games/waste_sorting/waste_sorting.tscn")
	if failure_scene == null:
		return
	failure_scene.max_errors = 2
	failure_scene.mini_game_finished.connect(_capture_mini_game_result)
	var failure_items: Array = failure_scene.get_node("%WasteItems").get_children()
	failure_scene.call("_select_item", failure_items[0], 0)
	failure_scene.call("_on_bin_pressed", 1)
	failure_scene.call("_on_bin_pressed", 1)
	_check(captured_result == 0, "Waste Sorting should fail at the configured error limit.")
	_check(captured_errors == 2, "Waste Sorting should report the error count.")
	await _remove_scene(failure_scene)

func _validate_drain_cleaner() -> void:
	_reset_capture()
	var scene = await _instantiate_scene("res://scenes/game/mini_games/drain_cleaner/drain_cleaner.tscn")
	if scene == null:
		return
	scene.target_count = 1
	scene.call("_spawn_clogs")
	scene.mini_game_finished.connect(_capture_mini_game_result)
	var clog: Button
	for child in scene.get_node("%DrainItems").get_children():
		if child is Button:
			clog = child
			break
	_check(clog != null, "Drain Cleaner should create at least one selectable clog.")
	if clog == null:
		await _remove_scene(scene)
		return
	scene.call("_clear_clog", clog)
	_check(captured_result == 2, "Clearing all drain clogs quickly should resolve as AWESOME.")
	_check(captured_actions == 1, "Drain Cleaner should report its cleared count.")
	await _remove_scene(scene)

func _validate_river_cleaner() -> void:
	_reset_capture()
	var scene = await _instantiate_scene("res://scenes/game/mini_games/river_cleaner/river_cleaner.tscn")
	if scene == null:
		return
	scene.target_count = 1
	scene.mini_game_finished.connect(_capture_mini_game_result)
	var waste := ColorRect.new()
	waste.name = "Waste"
	waste.size = Vector2(28, 28)
	waste.position = scene.get_node("%Collector").position
	waste.set_meta("target", true)
	scene.get_node("%RiverLayer").add_child(waste)
	scene.call("_move_waste", 0.01)
	_check(captured_result == 2, "Catching the river target should resolve as AWESOME.")
	_check(captured_actions == 1, "River Cleaner should report caught target count.")
	await _remove_scene(scene)

	_reset_capture()
	var error_scene = await _instantiate_scene("res://scenes/game/mini_games/river_cleaner/river_cleaner.tscn")
	if error_scene == null:
		return
	error_scene.max_errors = 1
	error_scene.mini_game_finished.connect(_capture_mini_game_result)
	var decoy := ColorRect.new()
	decoy.name = "Waste"
	decoy.size = Vector2(28, 28)
	decoy.position = error_scene.get_node("%Collector").position
	decoy.set_meta("target", false)
	error_scene.get_node("%RiverLayer").add_child(decoy)
	error_scene.call("_move_waste", 0.01)
	_check(captured_result == 0, "Collecting a river decoy should fail at the configured error limit.")
	_check(captured_errors == 1, "River Cleaner should report decoy errors.")
	await _remove_scene(error_scene)

func _validate_pipe_puzzle() -> void:
	_reset_capture()
	var scene = await _instantiate_scene("res://scenes/game/mini_games/save_the_water/save_the_water.tscn")
	if scene == null:
		return
	scene.mini_game_finished.connect(_capture_mini_game_result)
	_check(not scene.call("_has_source_destination_path"), "Scrambled pipe grid should not start connected.")
	var path_indices: Array[int] = [1, 2, 3, 7, 11]
	for index in path_indices:
		scene.pipe_buttons[index].set_meta("rotation", 0)
	_check(scene.call("_has_source_destination_path"), "Correct pipe orientations should connect source to destination.")
	scene.call("_finish", true)
	_check(captured_result == 2, "Completing the pipe path quickly should resolve as AWESOME.")
	await _remove_scene(scene)

func _validate_scene_loads() -> void:
	var scene_paths: Array[String] = [
		"res://scenes/menus/main_menu/main_menu.tscn",
		"res://scenes/menus/level_select_menu/level_select_menu.tscn",
		"res://scenes/game/levels/level_1.tscn",
		"res://scenes/game/levels/level_2.tscn",
		"res://scenes/game/levels/level_3.tscn",
		"res://scenes/game/mini_games/trash_collector/trash_collector.tscn",
		"res://scenes/game/mini_games/waste_sorting/waste_sorting.tscn",
		"res://scenes/game/mini_games/drain_cleaner/drain_cleaner.tscn",
		"res://scenes/game/mini_games/river_cleaner/river_cleaner.tscn",
		"res://scenes/game/mini_games/save_the_water/save_the_water.tscn",
		"res://scenes/game/stages/stage_bonus.tscn",
	]
	for path in scene_paths:
		var packed_scene: PackedScene = load(path)
		_check(packed_scene != null, "Scene should load: %s" % path)
