class_name CountdownTimer
extends RefCounted

signal completed
signal warning

var duration: float
var remaining: float
var warning_at: float
var running: bool = false
var warned: bool = false
var finished: bool = false

func _init(initial_duration: float, warning_seconds: float = 10.0) -> void:
	duration = max(initial_duration, 0.0)
	remaining = duration
	warning_at = warning_seconds

func start() -> void:
	if remaining <= 0.0:
		finished = true
		completed.emit()
		return
	running = true
	finished = false

func pause() -> void:
	running = false

func resume() -> void:
	if remaining > 0.0:
		running = true
		finished = false

func reset(initial_duration: float = -1.0) -> void:
	if initial_duration >= 0.0:
		duration = initial_duration
	remaining = duration
	running = false
	finished = false
	warned = false

func tick(delta: float) -> void:
	if not running or finished:
		return
	remaining = max(remaining - delta, 0.0)
	if remaining <= warning_at and not warned:
		warned = true
		warning.emit()
	if remaining <= 0.0:
		running = false
		finished = true
		completed.emit()
