class_name TidyTrailsAudioCues
extends RefCounted

enum Cue {
	UI_SELECT,
	BUBBLE_SPAWN,
	BUBBLE_OPEN,
	ACTIVITY_SUCCESS,
	ACTIVITY_FAILED,
	POINTS,
	STAR,
	BONUS_OPEN,
	BONUS_POP,
	TIMER_WARNING,
	TIMER_END,
}

static func get_bus(cue: Cue) -> String:
	match cue:
		Cue.UI_SELECT:
			return "UI"
		Cue.BUBBLE_SPAWN, Cue.BUBBLE_OPEN, Cue.ACTIVITY_SUCCESS:
			return "SFX"
		Cue.ACTIVITY_FAILED, Cue.POINTS, Cue.STAR, Cue.BONUS_OPEN:
			return "SFX"
		Cue.BONUS_POP, Cue.TIMER_WARNING, Cue.TIMER_END:
			return "SFX"
	return "Master"

static func get_resource_path(cue: Cue) -> String:
	match cue:
		Cue.UI_SELECT:
			return "res://assets/audio/sfx/ui/ui_select.wav"
		Cue.BUBBLE_SPAWN:
			return "res://assets/audio/sfx/gameplay/bubble_spawn.wav"
		Cue.BUBBLE_OPEN:
			return "res://assets/audio/sfx/gameplay/bubble_open.wav"
		Cue.ACTIVITY_SUCCESS:
			return "res://assets/audio/sfx/result/activity_success.wav"
		Cue.ACTIVITY_FAILED:
			return "res://assets/audio/sfx/result/activity_failed.wav"
		Cue.POINTS:
			return "res://assets/audio/sfx/result/points.wav"
		Cue.STAR:
			return "res://assets/audio/sfx/result/star.wav"
		Cue.BONUS_OPEN:
			return "res://assets/audio/sfx/result/bonus_open.wav"
		Cue.BONUS_POP:
			return "res://assets/audio/sfx/gameplay/bonus_pop.wav"
		Cue.TIMER_WARNING:
			return "res://assets/audio/sfx/ui/timer_warning.wav"
		Cue.TIMER_END:
			return "res://assets/audio/sfx/ui/timer_end.wav"
	return ""

static func play(cue: Cue) -> void:
	var path: String = get_resource_path(cue)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = get_bus(cue)
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		main_loop.root.add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
