extends Control

signal mini_game_finished(result: int, remaining_time: float, correct_actions: int, errors: int)
signal mini_game_closed

@export var activity_duration: float = 40.0
@export var target_count: int = 8
@export var max_errors: int = 3

@onready var timer_label: Label = %RiverTimerLabel
@onready var progress_label: Label = %RiverProgressLabel
@onready var error_label: Label = %RiverErrorLabel
@onready var river_layer: Control = %RiverLayer
@onready var collector: Control = %Collector
@onready var result_label: Label = %RiverResultLabel

var remaining_time: float
var caught_count: int = 0
var error_count: int = 0
var spawn_timer: float = 0.0
var finished: bool = false

func _ready() -> void:
	remaining_time = activity_duration
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	timer_label.text = "Mini-game time: %02d" % ceili(remaining_time)

	var movement: float = 0.0
	if Input.is_action_pressed("ui_left"):
		movement -= 1.0
	if Input.is_action_pressed("ui_right"):
		movement += 1.0
	collector.position.x = clamp(
		collector.position.x + movement * 420.0 * delta,
		0.0,
		max(0.0, river_layer.size.x - collector.size.x)
	)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var local_mouse: Vector2 = river_layer.get_local_mouse_position()
		collector.position.x = clamp(
			local_mouse.x - collector.size.x * 0.5,
			0.0,
			max(0.0, river_layer.size.x - collector.size.x)
		)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_waste()
		spawn_timer = 0.65

	_move_waste(delta)
	if remaining_time <= 0.0:
		_finish(false)
	_update_hud()

func _spawn_waste() -> void:
	var waste := ColorRect.new()
	waste.name = "Waste"
	waste.custom_minimum_size = Vector2(28, 28)
	waste.size = Vector2(28, 28)
	waste.position = Vector2(
		randf_range(20.0, max(20.0, river_layer.size.x - 48.0)),
		-40.0
	)
	waste.color = Color(0.65, 0.35, 0.12, 1.0) if randf() < 0.8 else Color.DARK_RED
	waste.set_meta("target", waste.color != Color.DARK_RED)
	river_layer.add_child(waste)

func _move_waste(delta: float) -> void:
	for waste in river_layer.get_children():
		if not waste is ColorRect or waste == collector or waste.name == "RiverWater":
			continue
		waste.position.y += 180.0 * delta
		var waste_rect := Rect2(waste.position, waste.size)
		var collector_rect := Rect2(collector.position, collector.size)
		if waste_rect.intersects(collector_rect):
			var is_target: bool = waste.get_meta("target", true)
			waste.queue_free()
			if is_target:
				caught_count += 1
				if caught_count >= target_count:
					_finish(true)
			else:
				error_count += 1
				if error_count >= max_errors:
					_finish(false)
		elif waste.position.y > river_layer.size.y:
			waste.queue_free()
			error_count += 1
			if error_count >= max_errors:
				_finish(false)

func _update_hud() -> void:
	progress_label.text = "Caught: %d / %d" % [caught_count, target_count]
	error_label.text = "Errors: %d / %d" % [error_count, max_errors]

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	var result: int = 0
	if success:
		var resolver: GDScript = load("res://scripts/scoring/score_resolver.gd")
		var activity = _create_activity_config()
		result = resolver.call("get_result", activity, true, remaining_time, error_count)
	result_label.text = "GREAT" if result == 1 else "AWESOME" if result == 2 else "FAILED"
	mini_game_finished.emit(result, remaining_time, caught_count, error_count)

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
