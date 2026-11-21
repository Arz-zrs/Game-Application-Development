class_name StageConfig
extends Resource

@export var stage_title: String = "Tidy Trails Stage"
@export var stage_duration: float = 180.0
@export var bubble_interval_min: float = 12.0
@export var bubble_interval_max: float = 18.0
@export var max_active_bubbles: int = 2
@export var bonus_duration: float = 20.0
@export var balloon_points: int = 25
@export var activities: Array[ActivityConfig] = []
@export var one_star_percent: float = 0.25
@export var two_star_percent: float = 0.50
@export var three_star_percent: float = 0.75
