class_name StunComponent
extends Node
## 정지(경직) 상태 관리. 정지 중에는 받는 피해가 늘어난다.

signal stunned(duration: float)
signal recovered

## 정지 중 받는 피해 배율
@export var damage_taken_mult: float = 1.25
## 한 번에 걸리는 최대 정지 시간 (초). 음수면 제한 없음. (보스는 짧게)
@export var max_duration: float = -1.0

var _time_left: float = 0.0


func _physics_process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		recovered.emit()


func stun(duration: float) -> void:
	if max_duration >= 0.0:
		duration = minf(duration, max_duration)
	if duration <= 0.0:
		return
	var was_stunned: bool = is_stunned()
	_time_left = maxf(_time_left, duration)
	if not was_stunned:
		stunned.emit(duration)


func is_stunned() -> bool:
	return _time_left > 0.0


func get_time_left() -> float:
	return _time_left


func get_damage_taken_mult() -> float:
	return damage_taken_mult if is_stunned() else 1.0
