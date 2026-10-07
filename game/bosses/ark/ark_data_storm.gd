extends BossPattern
## 데이터 폭풍. 바닥 일부가 데이터 장판으로 변한다. 플레이어가 있는 구역은 항상 포함된다.

@export var attack: AttackData
@export var segments: int = 6
@export var active_segments: int = 3
@export var warn_time: float = 1.0
@export var active_time: float = 3.0
@export var height: float = 14.0
@export var warn_color: Color = Color(0.3, 1.0, 0.9, 0.3)
@export var active_color: Color = Color(0.3, 1.0, 0.9, 0.75)

var _time: float = 0.0

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	telegraphing = true
	var width: float = (ark.arena_right - ark.arena_left) / segments
	var chosen: Array[int] = []
	var t: Node2D = ark.get_target()
	if t:
		chosen.append(clampi(int((t.global_position.x - ark.arena_left) / width), 0, segments - 1))
	var pool: Array = range(segments)
	pool.shuffle()
	for i: int in pool:
		if chosen.size() >= active_segments:
			break
		if not i in chosen:
			chosen.append(i)
	for i: int in chosen:
		var rect := Rect2(ark.arena_left + i * width, ark.floor_y - height + 2.0, width, height)
		track(HazardZone.spawn(level(), rect, attack, warn_time, active_time, warn_color, active_color, true))


func physics_update(delta: float) -> void:
	_time += delta
	telegraphing = _time < warn_time
	if _time >= warn_time + active_time:
		finish()
