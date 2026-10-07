extends BossPattern
## 집게팔. 객차 문에서 집게팔이 나와 플레이어 위치를 3번 연속 내려찍는다.

@export var attack: AttackData
@export var slams: int = 3
@export var warn_time: float = 0.6
@export var active_time: float = 0.2
@export var gap: float = 0.35
@export var width: float = 40.0
@export var top_y: float = 120.0
@export var warn_color: Color = Color(1.0, 0.5, 0.2, 0.35)
@export var active_color: Color = Color(0.85, 0.85, 0.95, 0.9)

var _count: int = 0
var _time: float = 0.0

var train: TrainBoss:
	get:
		return actor as TrainBoss


func enter() -> void:
	_count = 0
	_time = 0.0
	_slam()


func physics_update(delta: float) -> void:
	_time += delta
	telegraphing = _time < warn_time
	if _time < warn_time + active_time + gap:
		return
	if _count >= slams:
		finish()
	else:
		_slam()


func _slam() -> void:
	_count += 1
	_time = 0.0
	telegraphing = true
	var t: Node2D = train.get_target()
	var x: float = t.global_position.x if t else train.park_x
	track(HazardZone.spawn(level(), Rect2(x - width * 0.5, top_y, width, train.track_y - top_y),
			attack, warn_time, active_time, warn_color, active_color))
