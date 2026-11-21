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
var bonus_session: Node = null
var stage_ending_started: bool = false

func _create_stage_config() -> Resource:
	var stage_number: int = 1
	if scene_file_path.ends_with("level_2.tscn"):
		stage_number = 2
	elif scene_file_path.ends_with("level_3.tscn"):
		stage_number = 3
	var variant_script: GDScript = load("res://scripts/stage/stage_variants.gd")
	var variants = variant_script.new()
	return variants.create_config(stage_number)

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
		3:
			return "Catch the flowing waste while avoiding pollution."
		4:
			return "Rotate pipe segments to connect source and destination."
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
	if selected_activity.config.mini_game_type == 2:
		_start_drain_cleaner()
		return
	if selected_activity.config.mini_game_type == 3:
		_start_river_cleaner()
		return
	if selected_activity.config.mini_game_type == 4:
		_start_save_the_water()
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

func _start_drain_cleaner() -> void:
	var scene: PackedScene = load("res://scenes/game/mini_games/drain_cleaner/drain_cleaner.tscn")
	active_mini_game = scene.instantiate()
	active_mini_game.activity_duration = selected_activity.config.mini_game_duration
	active_mini_game.target_count = 6
	active_mini_game.mini_game_finished.connect(_on_real_mini_game_finished)
	active_mini_game.mini_game_closed.connect(_on_real_mini_game_closed)
	add_child(active_mini_game)
	mini_game_active = true

func _start_river_cleaner() -> void:
	var scene: PackedScene = load("res://scenes/game/mini_games/river_cleaner/river_cleaner.tscn")
	active_mini_game = scene.instantiate()
	active_mini_game.activity_duration = selected_activity.config.mini_game_duration
	active_mini_game.max_errors = selected_activity.config.max_errors
	active_mini_game.target_count = 8
	active_mini_game.mini_game_finished.connect(_on_real_mini_game_finished)
	active_mini_game.mini_game_closed.connect(_on_real_mini_game_closed)
	add_child(active_mini_game)
	mini_game_active = true

func _start_save_the_water() -> void:
	var scene: PackedScene = load("res://scenes/game/mini_games/save_the_water/save_the_water.tscn")
	active_mini_game = scene.instantiate()
	active_mini_game.activity_duration = selected_activity.config.mini_game_duration
	active_mini_game.mini_game_finished.connect(_on_real_mini_game_finished)
	active_mini_game.mini_game_closed.connect(_on_real_mini_game_closed)
	add_child(active_mini_game)
	mini_game_active = true

func _on_real_mini_game_finished(result: int, _remaining_time: float, _correct_actions: int, _errors: int) -> void:
	var completed_activity = selected_activity
	mini_game_active = false
	if is_instance_valid(active_mini_game):
		active_mini_game.queue_free()
	active_mini_game = null
	selected_activity = null
	if completed_activity and not completed_activity.resolved:
		_resolve_activity(completed_activity, result)

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
	if selected_activity == activity:
		selected_activity = null
		activity_popup.hide()
	_update_hud()
	if stage_runtime.get_unhandled_count() == 0:
		_end_stage()

func _end_stage() -> void:
	if stage_ending_started:
		return
	stage_ending_started = true
	stage_runtime.stage_remaining = max(stage_runtime.stage_remaining, 0.0)
	mini_game_active = false
	selected_activity = null
	activity_popup.hide()
	mini_game_panel.hide()
	if is_instance_valid(active_mini_game):
		active_mini_game.queue_free()
	active_mini_game = null
	for activity in stage_runtime.activities:
		if not activity.resolved:
			stage_runtime.resolve_activity(activity, 0)
	_update_hud()
	var stars: int = stage_runtime.get_star_count()
	if stars == 3:
		_start_bonus_session()
		return
	_show_final_result(stars)

func _start_bonus_session() -> void:
	var scene: PackedScene = load("res://scenes/game/stages/stage_bonus.tscn")
	bonus_session = scene.instantiate()
	bonus_session.bonus_duration = stage_runtime.config.bonus_duration
	bonus_session.balloon_points = stage_runtime.config.balloon_points
	bonus_session.bonus_finished.connect(_on_bonus_finished)
	add_child(bonus_session)
	activity_popup.hide()
	mini_game_panel.hide()

func _on_bonus_finished(total_bonus: int) -> void:
	stage_runtime.bonus_points = total_bonus
	if is_instance_valid(bonus_session):
		bonus_session.queue_free()
	bonus_session = null
	_show_final_result(stage_runtime.get_star_count())

func _show_final_result(stars: int) -> void:
	_save_stage_result(stars)
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

func _save_stage_result(stars: int) -> void:
	var level_path: String = ResourceUID.ensure_path(scene_file_path)
	var previous_stars: int = GameState.get_level_stars(level_path)
	if stars > previous_stars:
		GameState.set_level_stars(level_path, stars)
	GameState.set_level_unlocked(level_path, true)
	if level_path.ends_with("level_1.tscn"):
		GameState.set_level_unlocked("res://scenes/game/levels/level_2.tscn", true)
	elif level_path.ends_with("level_2.tscn"):
		GameState.set_level_unlocked("res://scenes/game/levels/level_3.tscn", true)

func _on_continue_pressed() -> void:
	level_won.emit(next_level_path)
