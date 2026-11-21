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

const EMPTY: int = 0
const UP: int = 1
const RIGHT: int = 2
const DOWN: int = 4
const LEFT: int = 8

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
	grid_columns = max(grid_columns, 2)
	grid_rows = max(grid_rows, 2)
	grid.columns = grid_columns
	for child in grid.get_children():
		child.queue_free()
	pipe_buttons.clear()

	var path_masks: Dictionary = {0: RIGHT}
	for column in range(1, grid_columns - 1):
		path_masks[column] = LEFT | RIGHT
	path_masks[grid_columns - 1] = LEFT | DOWN
	for row in range(1, grid_rows - 1):
		path_masks[row * grid_columns + grid_columns - 1] = UP | DOWN
	path_masks[grid_rows * grid_columns - 1] = UP | RIGHT
	for index in range(grid_columns * grid_rows):
		var button := Button.new()
		button.custom_minimum_size = Vector2(76, 76)
		var base_mask: int = int(path_masks.get(index, EMPTY))
		var initial_rotation: int = 0
		if index != 0 and index != grid_columns * grid_rows - 1 and base_mask != EMPTY:
			initial_rotation = randi_range(0, 3)
			if _rotate_mask(base_mask, initial_rotation) == base_mask:
				initial_rotation = (initial_rotation + 1) % 4
		button.set_meta("base_mask", base_mask)
		button.set_meta("rotation", initial_rotation)
		_update_pipe_text(button)
		button.pressed.connect(_rotate_pipe.bind(button))
		grid.add_child(button)
		pipe_buttons.append(button)

	pipe_buttons[0].disabled = false
	pipe_buttons[pipe_buttons.size() - 1].disabled = false

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
	var base_mask: int = int(button.get_meta("base_mask"))
	var rotation: int = int(button.get_meta("rotation"))
	var mask: int = _rotate_mask(base_mask, rotation)
	var index: int = pipe_buttons.find(button)
	if index == 0:
		button.text = "Source >"
	elif index == pipe_buttons.size() - 1:
		button.text = "Dest ^ >"
	elif mask == (UP | DOWN):
		button.text = "|"
	elif mask == (LEFT | RIGHT):
		button.text = "-"
	elif mask == (UP | RIGHT):
		button.text = "UR"
	elif mask == (RIGHT | DOWN):
		button.text = "RD"
	elif mask == (DOWN | LEFT):
		button.text = "DL"
	elif mask == (LEFT | UP):
		button.text = "LU"
	elif mask == (UP | RIGHT | DOWN):
		button.text = "URD"
	elif mask == (UP | RIGHT | LEFT):
		button.text = "URL"
	elif mask == (RIGHT | DOWN | LEFT):
		button.text = "RDL"
	elif mask == (UP | DOWN | LEFT):
		button.text = "UDL"
	elif mask == (UP | RIGHT | DOWN | LEFT):
		button.text = "+"
	else:
		button.text = ""

func _rotate_mask(mask: int, turns: int) -> int:
	var rotated: int = mask
	for _turn in range(turns % 4):
		var next_mask: int = EMPTY
		if rotated & UP:
			next_mask |= RIGHT
		if rotated & RIGHT:
			next_mask |= DOWN
		if rotated & DOWN:
			next_mask |= LEFT
		if rotated & LEFT:
			next_mask |= UP
		rotated = next_mask
	return rotated

func _get_mask(index: int) -> int:
	var button: Button = pipe_buttons[index]
	return _rotate_mask(int(button.get_meta("base_mask")), int(button.get_meta("rotation")))

func _has_source_destination_path() -> bool:
	if pipe_buttons.is_empty():
		return false
	var source: int = 0
	var destination: int = pipe_buttons.size() - 1
	if _get_mask(source) & RIGHT == 0 or _get_mask(destination) & UP == 0:
		return false
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
				if _pipes_connect(index, neighbor):
					visited[neighbor] = true
					queue.append(neighbor)
	return false

func _connected_neighbors(index: int) -> Array[int]:
	var row: int = index / grid_columns
	var column: int = index % grid_columns
	var neighbors: Array[int] = []
	if index == 0:
		if grid_columns > 1:
			neighbors.append(1)
		return neighbors
	if index == pipe_buttons.size() - 1:
		if grid_columns > 1:
			neighbors.append(index - 1)
		return neighbors
	if column > 0:
		neighbors.append(index - 1)
	if column < grid_columns - 1:
		neighbors.append(index + 1)
	if row > 0:
		neighbors.append(index - grid_columns)
	if row < grid_rows - 1:
		neighbors.append(index + grid_columns)
	return neighbors

func _pipes_connect(index: int, neighbor: int) -> bool:
	var row: int = index / grid_columns
	var column: int = index % grid_columns
	var neighbor_row: int = neighbor / grid_columns
	var neighbor_column: int = neighbor % grid_columns
	var outgoing: int
	var incoming: int
	if neighbor_column > column:
		outgoing = RIGHT
		incoming = LEFT
	elif neighbor_column < column:
		outgoing = LEFT
		incoming = RIGHT
	elif neighbor_row > row:
		outgoing = DOWN
		incoming = UP
	else:
		outgoing = UP
		incoming = DOWN
	return (_get_mask(index) & outgoing) != 0 and (_get_mask(neighbor) & incoming) != 0

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
