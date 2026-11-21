extends Control

signal bonus_finished(total_bonus: int)

@export var bonus_duration: float = 20.0
@export var balloon_points: int = 25

@onready var timer_label: Label = %BonusTimerLabel
@onready var points_label: Label = %BonusPointsLabel
@onready var balloon_layer: Control = %BalloonLayer

var remaining_time: float
var bonus_points: int = 0
var finished: bool = false
var spawn_remaining: float = 0.0

func _ready() -> void:
	remaining_time = bonus_duration
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	spawn_remaining -= delta
	if spawn_remaining <= 0.0:
		_spawn_balloon()
		spawn_remaining = 0.5
	_update_hud()
	if remaining_time <= 0.0:
		_finish()

func _spawn_balloon() -> void:
	if balloon_layer.get_child_count() >= 12:
		return
	var balloon := Button.new()
	balloon.text = "Balloon"
	balloon.custom_minimum_size = Vector2(60, 84)
	balloon.position = Vector2(
		randf_range(24.0, max(24.0, balloon_layer.size.x - 84.0)),
		randf_range(24.0, max(24.0, balloon_layer.size.y - 108.0))
	)
	balloon.pressed.connect(_pop_balloon.bind(balloon))
	balloon_layer.add_child(balloon)

func _pop_balloon(balloon: Button) -> void:
	if finished:
		return
	bonus_points += balloon_points
	balloon.queue_free()
	_update_hud()

func _update_hud() -> void:
	timer_label.text = "Bonus time: %02d" % ceili(remaining_time)
	points_label.text = "Bonus: %d" % bonus_points

func _finish() -> void:
	if finished:
		return
	finished = true
	bonus_finished.emit(bonus_points)
