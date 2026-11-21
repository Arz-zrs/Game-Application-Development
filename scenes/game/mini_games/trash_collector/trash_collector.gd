extends Control

signal mini_game_finished(result: int, remaining_time: float, correct_actions: int, errors: int)
signal mini_game_closed

@export var activity_duration: float = 35.0
@export var target_count: int = 8

@onready var timer_label: Label = %TimerLabel
@onready var progress_label: Label = %ProgressLabel
@onready var items_layer: Control = %ItemsLayer
@onready var result_label: Label = %ResultLabel

var remaining_time: float
var collected_count: int = 0
var finished: bool = false

func _ready() -> void:
	remaining_time = activity_duration
	collected_count = 0
	result_label.text = ""
	_spawn_trash_items()
	_update_progress()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	timer_label.text = "Mini-game time: %02d" % ceili(remaining_time)
	if remaining_time <= 0.0:
		_finish(false)

func _spawn_trash_items() -> void:
	for child in items_layer.get_children():
		child.queue_free()
	for index in range(target_count):
		var item := Button.new()
		item.text = "Trash"
		item.custom_minimum_size = Vector2(74, 74)
		item.position = Vector2(
			randf_range(50.0, max(50.0, items_layer.size.x - 124.0)),
			randf_range(70.0, max(70.0, items_layer.size.y - 124.0))
		)
		item.pressed.connect(_collect_item.bind(item))
		items_layer.add_child(item)

func _collect_item(item: Button) -> void:
	if finished:
		return
	collected_count += 1
	item.disabled = true
	item.hide()
	_update_progress()
	if collected_count >= target_count:
		_finish(true)

func _update_progress() -> void:
	progress_label.text = "Collected: %d / %d" % [collected_count, target_count]

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	var result: int = 0
	if success:
		var resolver: GDScript = load("res://scripts/scoring/score_resolver.gd")
		result = resolver.call(
			"get_result",
			_create_activity_config(),
			true,
			remaining_time,
			0
		)
	result_label.text = "GREAT" if result == 1 else "AWESOME" if result == 2 else "FAILED"
	mini_game_finished.emit(result, remaining_time, collected_count, 0)

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
