extends Control

signal mini_game_finished(result: int, remaining_time: float, correct_actions: int, errors: int)
signal mini_game_closed

@export var activity_duration: float = 35.0
@export var target_count: int = 6

@onready var timer_label: Label = %DrainTimerLabel
@onready var progress_label: Label = %DrainProgressLabel
@onready var items_layer: Control = %DrainItems
@onready var result_label: Label = %DrainResultLabel

var remaining_time: float
var cleared_count: int = 0
var finished: bool = false

func _ready() -> void:
	remaining_time = activity_duration
	_spawn_clogs()
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	timer_label.text = "Mini-game time: %02d" % ceili(remaining_time)
	if remaining_time <= 0.0:
		_finish(false)

func _spawn_clogs() -> void:
	for index in range(target_count):
		var clog := Button.new()
		clog.text = "Clog"
		clog.custom_minimum_size = Vector2(68, 68)
		clog.position = Vector2(
			randf_range(30.0, max(30.0, items_layer.size.x - 98.0)),
			randf_range(50.0, max(50.0, items_layer.size.y - 118.0))
		)
		clog.pressed.connect(_clear_clog.bind(clog))
		items_layer.add_child(clog)

func _clear_clog(clog: Button) -> void:
	if finished:
		return
	cleared_count += 1
	clog.disabled = true
	clog.hide()
	_update_hud()
	if cleared_count >= target_count:
		_finish(true)

func _update_hud() -> void:
	progress_label.text = "Cleared: %d / %d" % [cleared_count, target_count]

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	var result: int = 0
	if success:
		var resolver: GDScript = load("res://scripts/scoring/score_resolver.gd")
		var activity = _create_activity_config()
		result = resolver.call("get_result", activity, true, remaining_time, 0)
	result_label.text = "GREAT" if result == 1 else "AWESOME" if result == 2 else "FAILED"
	mini_game_finished.emit(result, remaining_time, cleared_count, 0)

func _create_activity_config() -> Resource:
	var script: GDScript = load("res://scripts/stage/activity_config.gd")
	var activity = script.new()
	activity.great_points = 100
	activity.awesome_points = 150
	activity.awesome_remaining_time = 10.0
	activity.awesome_max_errors = 0
	return activity

func _on_return_pressed() -> void:
	mini_game_closed.emit()
	queue_free()
