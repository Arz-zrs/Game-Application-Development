extends Control

signal mini_game_finished(result: int, remaining_time: float, correct_actions: int, errors: int)
signal mini_game_closed

@export var activity_duration: float = 40.0
@export var max_errors: int = 3

@onready var timer_label: Label = %SortingTimerLabel
@onready var progress_label: Label = %SortingProgressLabel
@onready var error_label: Label = %SortingErrorLabel
@onready var items_container: VBoxContainer = %WasteItems
@onready var result_label: Label = %SortingResultLabel

var remaining_time: float
var correct_count: int = 0
var error_count: int = 0
var selected_item: Button = null
var selected_category: int = -1
var item_count: int = 8
var finished: bool = false

func _ready() -> void:
	remaining_time = activity_duration
	_create_items()
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	timer_label.text = "Mini-game time: %02d" % ceili(remaining_time)
	if remaining_time <= 0.0:
		_finish(false)

func _create_items() -> void:
	for index in range(item_count):
		var category: int = index % 4
		var item := Button.new()
		item.text = ["Organic", "Plastic", "Paper", "Hazardous"][category]
		item.custom_minimum_size = Vector2(180, 44)
		item.pressed.connect(_select_item.bind(item, category))
		items_container.add_child(item)

func _select_item(item: Button, category: int) -> void:
	if finished or item.disabled:
		return
	selected_item = item
	selected_category = category
	for child in items_container.get_children():
		child.modulate = Color.WHITE
	item.modulate = Color(1.0, 0.85, 0.35, 1.0)

func _on_bin_pressed(category: int) -> void:
	if finished or selected_item == null:
		return
	if category == selected_category:
		selected_item.disabled = true
		selected_item.hide()
		correct_count += 1
		selected_item = null
		selected_category = -1
		if correct_count >= item_count:
			_finish(true)
	else:
		error_count += 1
		if error_count >= max_errors:
			_finish(false)
	_update_hud()

func _update_hud() -> void:
	progress_label.text = "Sorted: %d / %d" % [correct_count, item_count]
	error_label.text = "Errors: %d / %d" % [error_count, max_errors]

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	var result: int = 0
	if success:
		var resolver: GDScript = load("res://scripts/scoring/score_resolver.gd")
		var activity = _create_activity_config()
		result = resolver.call(
			"get_result",
			activity,
			true,
			remaining_time,
			error_count
		)
	result_label.text = "GREAT" if result == 1 else "AWESOME" if result == 2 else "FAILED"
	mini_game_finished.emit(result, remaining_time, correct_count, error_count)

func _create_activity_config() -> Resource:
	var script: GDScript = load("res://scripts/stage/activity_config.gd")
	var activity = script.new()
	activity.great_points = 100
	activity.awesome_points = 150
	activity.awesome_remaining_time = 10.0
	activity.awesome_max_errors = 1
	return activity

func _on_return_pressed() -> void:
	mini_game_closed.emit()
	queue_free()
