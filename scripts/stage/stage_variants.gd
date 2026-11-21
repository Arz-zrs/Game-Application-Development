class_name StageVariants
extends RefCounted

func create_config(stage_number: int) -> Resource:
	var stage_script: GDScript = load("res://scripts/stage/stage_config.gd")
	var activity_script: GDScript = load("res://scripts/stage/activity_config.gd")
	var config = stage_script.new()
	config.stage_title = "Stage %d" % stage_number
	config.stage_duration = 180.0 + (stage_number - 1) * 30.0
	config.bubble_interval_min = 12.0
	config.bubble_interval_max = 18.0
	config.max_active_bubbles = 1 if stage_number == 1 else 2

	var activity_types: Array[int] = []
	match stage_number:
		1:
			config.stage_title = "Stage 1 - Residential Street"
			activity_types = [0, 1, 2]
		2:
			config.stage_title = "Stage 2 - Public Market"
			activity_types = [0, 1, 2, 3]
		3:
			config.stage_title = "Stage 3 - Polluted River"
			activity_types = [0, 1, 2, 3, 4]

	var positions: Array[Vector2] = [
		Vector2(0.20, 0.58),
		Vector2(0.43, 0.38),
		Vector2(0.68, 0.62),
		Vector2(0.82, 0.36),
		Vector2(0.50, 0.72),
	]

	for index in range(activity_types.size()):
		var activity = activity_script.new()
		activity.id = "stage%d_activity%d" % [stage_number, index]
		activity.mini_game_type = activity_types[index]
		activity.title = [
			"Trash Collector",
			"Waste Sorting",
			"Drain Cleaner",
			"River Cleaner",
			"Save the Water",
		][activity_types[index]]
		activity.bubble_duration = 40.0
		activity.mini_game_duration = 35.0 + index * 2.0
		activity.max_errors = 3 if activity_types[index] in [1, 3] else 0
		activity.awesome_max_errors = 1 if activity_types[index] in [1, 3] else 0
		activity.great_points = 100
		activity.awesome_points = 150
		activity.awesome_remaining_time = 10.0
		activity.map_position = positions[index]
		config.activities.append(activity)
	return config
