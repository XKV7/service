extends State
## 다음 패턴까지 대기. 대기 시간은 BossBrain의 현재 페이즈가 정한다.

## 대기 중 대상 쪽을 바라볼지
@export var face_target: bool = true

var _time: float = 0.0

var boss: Boss:
	get:
		return actor as Boss


func enter() -> void:
	_time = 0.0


func physics_update(delta: float) -> void:
	if face_target:
		boss.face_target()
	_time += delta
	if _time < boss.brain.get_idle_time() or not boss.has_live_target():
		return
	var next: StringName = boss.brain.next_pattern()
	if next != &"":
		transitioned.emit(self, next)
