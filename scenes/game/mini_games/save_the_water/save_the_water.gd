extends Control

signal mini_game_finished(result: int, remaining_time: float, correct_actions: int, errors: int)
signal mini_game_closed

@export var activity_duration: float = 45.0
@export var grid_columns: int = 4
@export var grid_rows: int = 4

@onready var timer_label: Label = %PipeTimerLabel
@onready var result_label: Label = %PipeResultLabel
@onready var grid: GridContainer = %PipeGrid

var remaining_time: float
var rotations: int = 0
var finished: bool = false
var pipe_buttons: Array[Button] = []
var solution: Array[int] = []

func _ready() -> void:
	remaining_time = activity_duration
	grid.columns = grid_columns
	_create_grid()

func _process(delta: float) -> void:
	if finished:
		return
	remaining_time = max(remaining_time - delta, 0.0)
	timer_label.text = "Mini-game time: %02d" % ceili(remaining_time)
	if remaining_time <= 0.0:
		_finish(false)

func _create_grid() -> void:
	solution.clear()
	for child in grid.get_children():
		child.queue_free()
	pipe_buttons.clear()

	var straight_indices: Array[int] = [5, 6, 9, 10]
	for index in range(grid_columns * grid_rows):
		var button := Button.new()
		button.custom_minimum_size = Vector2(76, 76)
		var is_straight: bool = index in straight_indices
		var base_rotation: int = 1 if is_straight else randi() % 4
		button.set_meta("rotation", base_rotation)
		button.set_meta("straight", is_straight)
		_update_pipe_text(button)
		button.pressed.connect(_rotate_pipe.bind(button))
		grid.add_child(button)
		pipe_buttons.append(button)
		solution.append(1 if is_straight else base_rotation)

	pipe_buttons[0].disabled = false
	pipe_buttons[pipe_buttons.size() - 1].disabled = false
	_randomize_fixed_solution()

func _randomize_fixed_solution() -> void:
	for index in range(pipe_buttons.size()):
		var button: Button = pipe_buttons[index]
		if index == 0 or index == grid_columns * grid_rows - 1:
			continue
		if bool(button.get_meta("straight")):
			continue
		var random_turn: int = randi() % 4
		button.set_meta("rotation", random_turn)
		_update_pipe_text(button)

func _rotate_pipe(button: Button) -> void:
	if finished:
		return
	if button == pipe_buttons[0] or button == pipe_buttons[pipe_buttons.size() - 1]:
		return
	var rotation: int = int(button.get_meta("rotation"))
	rotation = (rotation + 1) % 4
	button.set_meta("rotation", rotation)
	rotations += 1
	_update_pipe_text(button)
	if _has_source_destination_path():
		_finish(true)

func _update_pipe_text(button: Button) -> void:
	var is_straight: bool = bool(button.get_meta("straight"))
	var rotation: int = int(button.get_meta("rotation"))
	if is_straight:
		button.text = "|" if rotation % 2 == 0 else "-"
	else:
		button.text = ["-", "L", "T", "+"][rotation]

func _has_source_destination_path() -> bool:
	if pipe_buttons.is_empty():
		return false
	var source: int = 0
	var destination: int = pipe_buttons.size() - 1
	var visited: Array[bool] = []
	visited.resize(pipe_buttons.size())
	visited.fill(false)
	var queue: Array[int] = [source]
	visited[source] = true

	while not queue.is_empty():
		var index: int = queue.pop_front()
		if index == destination:
			return true
		for neighbor in _connected_neighbors(index):
			if neighbor >= 0 and neighbor < pipe_buttons.size() and not visited[neighbor]:
				visited[neighbor] = true
				queue.append(neighbor)
	return false

func _connected_neighbors(index: int) -> Array[int]:
	var row: int = index / grid_columns
	var column: int = index % grid_columns
	var neighbors: Array[int] = []
	var button: Button = pipe_buttons[index]
	if index == 0:
		neighbors.append(1)
		neighbors.append(grid_columns)
		return neighbors
	if index == pipe_buttons.size() - 1:
		neighbors.append(index - 1)
		neighbors.append(index - grid_columns)
		return neighbors

	var rotation: int = int(button.get_meta("rotation"))
	var is_straight: bool = bool(button.get_meta("straight"))
	var connections: Array[String] = []
	if is_straight:
		connections = ["L", "R"] if rotation % 2 == 1 else ["U", "D"]
	else:
		match rotation:
			0:
				connections = ["L", "R"]
			1:
				connections = ["L", "D"]
			2:
				connections = ["L", "R", "D", "U"]
			3:
				connections = ["L", "R", "D"]

	for direction in connections:
		match direction:
			"L":
				if column > 0:
					neighbors.append(index - 1)
			"R":
				if column < grid_columns - 1:
					neighbors.append(index + 1)
			"U":
				if row > 0:
					neighbors.append(index - grid_columns)
			"D":
				if row < grid_rows - 1:
					neighbors.append(index + grid_columns)
	return neighbors

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
	mini_game_finished.emit(result, remaining_time, rotations, 0)

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
