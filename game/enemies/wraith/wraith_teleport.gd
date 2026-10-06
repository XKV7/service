extends EnemyState
## 홀로 망령 순간이동. 사라졌다가 플레이어 옆에 나타난다. 사라진 동안에는 맞지 않는다.

## 사라지는 시간 (초)
@export var fade_out_time: float = 0.35
## 나타나는 시간 (초)
@export var fade_in_time: float = 0.25
## 플레이어 옆 출현 거리 (px)
@export var side_offset: float = 52.0
## 출현 높이 (플레이어 발밑 기준, px)
@export var appear_height: float = -24.0
@export var next_state: StringName = &"Attack"

var _time: float = 0.0
var _moved: bool = false


func enter() -> void:
	_time = 0.0
	_moved = false
	enemy.visual_override = true
	enemy.velocity = Vector2.ZERO
	enemy.hurtbox.set_deferred(&"monitorable", false)


func exit() -> void:
	enemy.visual_override = false
	enemy.visual.modulate.a = 1.0
	enemy.hurtbox.set_deferred(&"monitorable", true)


func physics_update(_delta: float) -> void:
	_time = _time + _delta
	if not _moved and _time >= fade_out_time:
		_moved = true
		_reposition()
	if _time >= fade_out_time + fade_in_time:
		transitioned.emit(self, next_state)


func update(_delta: float) -> void:
	var alpha: float
	if _time < fade_out_time:
		alpha = 1.0 - _time / fade_out_time
	else:
		alpha = (_time - fade_out_time) / fade_in_time
	enemy.visual.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))


func _reposition() -> void:
	var t: Node2D = enemy.get_target()
	if t == null:
		return
	# 원래 있던 쪽의 반대편이 아니라, 망령이 있던 쪽에서 다가온다.
	var side: float = signf(enemy.global_position.x - t.global_position.x)
	if side == 0.0:
		side = 1.0
	enemy.global_position = t.global_position + Vector2(side * side_offset, appear_height)
	enemy.face_target()
