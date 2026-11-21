extends Control

signal level_selected

const LEVEL_PATHS: Array[String] = [
	"res://scenes/game/levels/level_1.tscn",
	"res://scenes/game/levels/level_2.tscn",
	"res://scenes/game/levels/level_3.tscn",
]

@onready var tutorial_button: Button = $Map/TutorialButton
@onready var level_buttons: Array[Button] = [
	$Map/Level1Button,
	$Map/Level2Button,
	$Map/Level3Button,
]
@onready var star_groups: Array[Node2D] = [
	$Map/TutorialStars,
	$Map/Level1Stars,
	$Map/Level2Stars,
	$Map/Level3Stars,
]

var level_paths: Array[String] = LEVEL_PATHS

func _ready() -> void:
	_prepare_star_groups()
	_apply_unlocks()
	_apply_stars()

func _prepare_star_groups() -> void:
	for group in star_groups:
		for child in group.get_children():
			if child is Sprite2D:
				child.visible = false

func _apply_unlocks() -> void:
	var game_state := GameState.get_or_create_state()
	for index in range(level_buttons.size()):
		var level_path: String = LEVEL_PATHS[index]
		var level_state: LevelState = game_state.level_states.get(level_path)
		var unlocked: bool = index == 0 or (level_state != null and level_state.unlocked)
		level_buttons[index].disabled = not unlocked
		if level_state == null:
			GameState.get_level_state(level_path)

func _apply_stars() -> void:
	_set_star_group(star_groups[0], 0)
	for index in range(LEVEL_PATHS.size()):
		_set_star_group(star_groups[index + 1], GameState.get_level_stars(LEVEL_PATHS[index]))

func _set_star_group(group: Node2D, star_count: int) -> void:
	var stars: Array[Sprite2D] = []
	for child in group.get_children():
		if child is Sprite2D:
			stars.append(child)
	for index in range(stars.size()):
		stars[index].visible = index < star_count

func _on_tutorial_pressed() -> void:
	var tutorial_scene: PackedScene = load("res://scenes/game/tutorials/tutorial_1.tscn")
	if tutorial_scene:
		var level_state: LevelState = GameState.get_level_state(LEVEL_PATHS[0])
		if level_state:
			level_state.tutorial_read = true
			GlobalState.save()
		add_child(tutorial_scene.instantiate())

func _on_level_pressed(index: int) -> void:
	if index < 0 or index >= LEVEL_PATHS.size():
		return
	if level_buttons[index].disabled:
		return
	GameState.set_checkpoint_level_path(LEVEL_PATHS[index])
	level_paths = [LEVEL_PATHS[index]]
	level_selected.emit()

func _on_back_pressed() -> void:
	hide()
