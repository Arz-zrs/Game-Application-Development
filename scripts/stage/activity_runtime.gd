class_name ActivityRuntime
extends RefCounted

enum State {
	PENDING,
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED,
}

var config: ActivityConfig
var state: State = State.PENDING
var bubble_remaining: float
var resolved: bool = false

func _init(activity_config: ActivityConfig) -> void:
	config = activity_config
	bubble_remaining = activity_config.bubble_duration

func make_available() -> void:
	if state == State.PENDING:
		state = State.AVAILABLE

func open() -> bool:
	if state != State.AVAILABLE:
		return false
	state = State.ACTIVE
	return true

func leave_unfinished() -> bool:
	if state != State.ACTIVE:
		return false
	state = State.AVAILABLE
	return true

func resolve(result: int) -> bool:
	if resolved:
		return false
	resolved = true
	state = State.COMPLETED if result != ScoreResolver.Result.FAILED else State.FAILED
	return true
