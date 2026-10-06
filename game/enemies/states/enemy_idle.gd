extends EnemyState
## 제자리 대기. 최소 대기 시간이 지나고 플레이어를 발견하면 react_state로 간다.
## idle_time이 지나면 timeout_state로 간다. (비우면 계속 대기)

@export var react_state: StringName = &"Chase"
@export var timeout_state: StringName = &""
## 반응하기 전 최소 대기 시간 (초)
@export var min_wait: float = 0.0
## timeout_state로 넘어가기까지 (초)
@export var idle_time: float = 1.5

var _time: float = 0.0


func enter() -> void:
	_time = 0.0


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	_time += delta
	if _time >= min_wait and enemy.can_see_target():
		transitioned.emit(self, react_state)
	elif timeout_state != &"" and _time >= idle_time:
		transitioned.emit(self, timeout_state)
