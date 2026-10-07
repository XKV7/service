extends BossPattern
## 스파크 낙하 (2페이즈). 천장 전선을 끊어 스파크를 떨어뜨린다. 떨어질 위치에 그림자가 먼저 보인다.

@export var attack: AttackData
@export var count: int = 4
@export var interval: float = 0.25
@export var warn_time: float = 0.8
@export var active_time: float = 0.2
@export var width: float = 20.0
@export var warn_color: Color = Color(0.3, 0.9, 1.0, 0.35)
@export var active_color: Color = Color(0.7, 1.0, 1.0, 0.9)

var _spawned_count: int = 0
var _time: float = 0.0

var train: TrainBoss:
	get:
		return actor as TrainBoss


func enter() -> void:
	_spawned_count = 0
	_time = 0.0
	telegraphing = true


func physics_update(delta: float) -> void:
	_time += delta
	if _spawned_count < count and _time >= _spawned_count * interval:
		_drop(_spawned_count == 0)
		_spawned_count += 1
	telegraphing = _time < warn_time
	if _time >= (count - 1) * interval + warn_time + active_time:
		finish()


func _drop(at_player: bool) -> void:
	var x: float = randf_range(train.arena_left + width, train.arena_right - width)
	var t: Node2D = train.get_target()
	if at_player and t:
		x = t.global_position.x
	track(HazardZone.spawn(level(), Rect2(x - width * 0.5, 0.0, width, train.track_y),
			attack, warn_time, active_time, warn_color, active_color))
