extends "res://scenes/game/levels/level.gd"

var stage_runtime
var bubble_spawn_remaining: float = 5.0
var selected_activity
var bubble_buttons: Dictionary = {}

@onready var stage_timer_label: Label = %StageTimerLabel
@onready var stage_score_label: Label = %StageScoreLabel
@onready var star_label: Label = %StarLabel
@onready var bubble_layer: Control = %BubbleLayer
@onready var activity_popup: PanelContainer = %ActivityPopup
@onready var popup_title: Label = %PopupTitle
@onready var popup_objective: Label = %PopupObjective
@onready var popup_bubble_timer: Label = %PopupBubbleTimer
@onready var mini_game_panel: PanelContainer = %MiniGamePanel
@onready var mini_game_title: Label = %MiniGameTitle
@onready var mini_game_objective: Label = %MiniGameObjective
@onready var mini_game_timer_label: Label = %MiniGameTimerLabel
@onready var stage_result: PanelContainer = %StageResult
@onready var result_text: Label = %ResultText

var mini_game_remaining: float = 0.0
var mini_game_active: bool = false
var active_mini_game: Node = null

func _create_stage_config() -> Resource:
	var config_script: GDScript = load("res://scripts/stage/stage_config.gd")
	var config = config_script.new()
	config.stage_title = "Stage 1 - Residential Street"
	config.stage_duration = 180.0
	config.bubble_interval_min = 12.0
	config.bubble_interval_max = 18.0
	config.max_active_bubbles = 2

	var activity_script: GDScript = load("res://scripts/stage/activity_config.gd")
	var trash = activity_script.new()
	trash.id = "stage1_trash"
	trash.title = "Trash Collector"
	trash.mini_game_type = 0
	trash.bubble_duration = 40.0
	trash.mini_game_duration = 35.0
	trash.great_points = 100
	trash.awesome_points = 150
	trash.awesome_remaining_time = 10.0
	trash.map_position = Vector2(0.24, 0.62)

	var sorting = activity_script.new()
	sorting.id = "stage1_sorting"
	sorting.title = "Waste Sorting"
	sorting.mini_game_type = 1
	sorting.bubble_duration = 45.0
	sorting.mini_game_duration = 40.0
	sorting.max_errors = 3
	sorting.awesome_max_errors = 1
	sorting.great_points = 100
	sorting.awesome_points = 150
	sorting.awesome_remaining_time = 10.0
	sorting.map_position = Vector2(0.50, 0.42)

	var drain = activity_script.new()
	drain.id = "stage1_drain"
	drain.title = "Drain Cleaner"
	drain.mini_game_type = 2
	drain.bubble_duration = 40.0
	drain.mini_game_duration = 35.0
	drain.great_points = 100
	drain.awesome_points = 150
	drain.awesome_remaining_time = 10.0
	drain.map_position = Vector2(0.76, 0.68)

	config.activities.append(trash)
	config.activities.append(sorting)
	config.activities.append(drain)
	return config

func _ready() -> void:
	super._ready()
	_build_stage()

func _build_stage() -> void:
	var config = _create_stage_config()
	var runtime_script: GDScript = load("res://scripts/stage/stage_runtime.gd")
	stage_runtime = runtime_script.new(config)
	%StageTitle.text = config.stage_title
	activity_popup.hide()
	mini_game_panel.hide()
	stage_result.hide()
	_update_hud()

func _process(delta: float) -> void:
	if stage_result.visible:
		return
	if stage_runtime.stage_remaining <= 0.0:
		_end_stage()
		return

	stage_runtime.stage_remaining = max(stage_runtime.stage_remaining - delta, 0.0)

	bubble_spawn_remaining -= delta
	if bubble_spawn_remaining <= 0.0:
		_spawn_next_bubble()
		bubble_spawn_remaining = randf_range(
			stage_runtime.config.bubble_interval_min,
			stage_runtime.config.bubble_interval_max
		)

	for activity in stage_runtime.activities:
		if activity.state == 1:
			activity.bubble_remaining = max(activity.bubble_remaining - delta, 0.0)
			if activity.bubble_remaining <= 0.0:
				_resolve_activity(activity, 0)

	if mini_game_active:
		if active_mini_game == null:
			mini_game_remaining = max(mini_game_remaining - delta, 0.0)
			mini_game_timer_label.text = "Mini-game time: %02d" % ceili(mini_game_remaining)
			if mini_game_remaining <= 0.0:
				_finish_placeholder_activity(false)

	if selected_activity and activity_popup.visible:
		popup_bubble_timer.text = "Activity time: %02d" % ceili(selected_activity.bubble_remaining)
	_update_hud()

func _update_hud() -> void:
	stage_timer_label.text = "Stage time: %02d" % ceili(stage_runtime.stage_remaining)
	stage_score_label.text = "Points: %d" % stage_runtime.mini_game_points
	star_label.text = "Stars: %d" % stage_runtime.get_star_count()

func _spawn_next_bubble() -> void:
	if stage_runtime.get_available_count() >= stage_runtime.config.max_active_bubbles:
		return
	for activity in stage_runtime.activities:
		if activity.state == 0:
			activity.make_available()
			_create_bubble(activity)
			return

func _create_bubble(activity) -> void:
	var button := Button.new()
	button.text = "!"
	button.tooltip_text = activity.config.title
	button.custom_minimum_size = Vector2(52, 52)
	button.position = activity.config.map_position * bubble_layer.size - button.custom_minimum_size * 0.5
	button.pressed.connect(_open_activity_popup.bind(activity))
	bubble_layer.add_child(button)
	bubble_buttons[activity.config.id] = button

func _open_activity_popup(activity) -> void:
	if mini_game_active or activity.resolved:
		return
	selected_activity = activity
	popup_title.text = activity.config.title
	popup_objective.text = _get_objective(activity.config)
	popup_bubble_timer.text = "Activity time: %02d" % ceili(activity.bubble_remaining)
	activity_popup.show()

func _get_objective(config) -> String:
	match config.mini_game_type:
		0:
			return "Collect every trash item before time expires."
		1:
			return "Sort every waste item into the correct bin."
		2:
			return "Clear every clogged drain item."
		_:
			return "Complete the environmental cleaning activity."

func _on_popup_close_pressed() -> void:
	activity_popup.hide()

func _on_popup_start_pressed() -> void:
	if selected_activity == null:
		return
	if not selected_activity.open():
		return
	activity_popup.hide()
	if selected_activity.config.mini_game_type == 0:
		_start_trash_collector()
		return
	if selected_activity.config.mini_game_type == 1:
		_start_waste_sorting()
		return
	mini_game_title.text = selected_activity.config.title
	mini_game_objective.text = _get_objective(selected_activity.config)
	mini_game_remaining = selected_activity.config.mini_game_duration
	mini_game_timer_label.text = "Mini-game time: %02d" % ceili(mini_game_remaining)
	mini_game_active = true
	mini_game_panel.show()

func _start_trash_collector() -> void:
	var scene: PackedScene = load("res://scenes/game/mini_games/trash_collector/trash_collector.tscn")
	active_mini_game = scene.instantiate()
	active_mini_game.activity_duration = selected_activity.config.mini_game_duration
	active_mini_game.target_count = 8
	active_mini_game.mini_game_finished.connect(_on_real_mini_game_finished)
	active_mini_game.mini_game_closed.connect(_on_real_mini_game_closed)
	add_child(active_mini_game)
	mini_game_active = true

func _start_waste_sorting() -> void:
	var scene: PackedScene = load("res://scenes/game/mini_games/waste_sorting/waste_sorting.tscn")
	active_mini_game = scene.instantiate()
	active_mini_game.activity_duration = selected_activity.config.mini_game_duration
	active_mini_game.max_errors = selected_activity.config.max_errors
	active_mini_game.mini_game_finished.connect(_on_real_mini_game_finished)
	active_mini_game.mini_game_closed.connect(_on_real_mini_game_closed)
	add_child(active_mini_game)
	mini_game_active = true

func _on_real_mini_game_finished(result: int, _remaining_time: float, _correct_actions: int, _errors: int) -> void:
	if selected_activity and not selected_activity.resolved:
		_resolve_activity(selected_activity, result)

func _on_real_mini_game_closed() -> void:
	if selected_activity:
		if not selected_activity.resolved:
			selected_activity.leave_unfinished()
	selected_activity = null
	active_mini_game = null
	mini_game_active = false

func _on_return_placeholder_pressed() -> void:
	if selected_activity:
		selected_activity.leave_unfinished()
	mini_game_active = false
	mini_game_panel.hide()
	selected_activity = null

func _on_finish_placeholder_pressed() -> void:
	_finish_placeholder_activity(true)

func _finish_placeholder_activity(_success: bool) -> void:
	if selected_activity == null:
		return
	if not selected_activity.resolved:
		var result: int
		if _success:
			var resolver: GDScript = load("res://scripts/scoring/score_resolver.gd")
			result = resolver.call("get_result", selected_activity.config, true, mini_game_remaining, 0)
		else:
			result = 0
		_resolve_activity(selected_activity, result)
	mini_game_active = false
	mini_game_panel.hide()
	selected_activity = null

func _resolve_activity(activity, result: int) -> void:
	var button: Button = bubble_buttons.get(activity.config.id)
	if is_instance_valid(button):
		button.queue_free()
	bubble_buttons.erase(activity.config.id)
	stage_runtime.resolve_activity(activity, result)
	_update_hud()
	if activity.state == 1:
		activity.state = 4 if result == 0 else 3
	if stage_runtime.get_unhandled_count() == 0:
		_end_stage()

func _end_stage() -> void:
	if stage_result.visible:
		return
	stage_runtime.stage_remaining = max(stage_runtime.stage_remaining, 0.0)
	for activity in stage_runtime.activities:
		if not activity.resolved:
			stage_runtime.resolve_activity(activity, 0)
	_update_hud()
	var stars: int = stage_runtime.get_star_count()
	result_text.text = (
		"Mini-game points: %d\n"
		+ "Bonus points: %d\n"
		+ "Final score: %d\n"
		+ "Stars: %d"
	) % [
		stage_runtime.mini_game_points,
		stage_runtime.bonus_points,
		stage_runtime.get_final_score(),
		stars
	]
	stage_result.show()
	activity_popup.hide()
	mini_game_panel.hide()

func _on_continue_pressed() -> void:
	level_won.emit(next_level_path)
