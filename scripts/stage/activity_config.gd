class_name ActivityConfig
extends Resource

enum MiniGameType {
	TRASH_COLLECTOR,
	WASTE_SORTING,
	DRAIN_CLEANER,
	RIVER_CLEANER,
	SAVE_THE_WATER,
}

@export var id: String
@export var title: String
@export var mini_game_type: MiniGameType
@export var bubble_duration: float = 40.0
@export var mini_game_duration: float = 35.0
@export var max_errors: int = 0
@export var great_points: int = 100
@export var awesome_points: int = 150
@export var awesome_remaining_time: float = 10.0
@export var awesome_max_errors: int = 0
@export var map_position: Vector2
