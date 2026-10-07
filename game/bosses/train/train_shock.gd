extends BossPattern
## 전류 방출. 선로 전체가 깜빡인 뒤 전기가 흐른다. 승강장으로 올라가거나 뛰어서 피한다.

@export var attack: AttackData
@export var warn_time: float = 0.8
@export var active_time: float = 0.6
## 감전 판정 높이 (선로 위, px)
@export var height: float = 14.0
@export var warn_color: Color = Color(1.0, 0.95, 0.3, 0.35)
@export var active_color: Color = Color(1.0, 0.95, 0.3, 0.85)

var _time: float = 0.0

var train: TrainBoss:
	get:
		return actor as TrainBoss


func enter() -> void:
	_time = 0.0
	telegraphing = true
	var width: float = train.arena_right - train.arena_left
	track(HazardZone.spawn(level(), Rect2(train.arena_left, train.track_y - height + 2.0, width, height),
			attack, warn_time, active_time, warn_color, active_color, true))


func physics_update(delta: float) -> void:
	_time += delta
	telegraphing = _time < warn_time
	if _time >= warn_time + active_time:
		finish()
