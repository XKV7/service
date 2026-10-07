extends BossPattern
## 핵심 노드 노출. 서버 기둥의 핵심 노드가 열려 피해를 받는다.

@export var expose_time: float = 4.0

var _time: float = 0.0

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	ark.set_core_open(true)
	EventBus.toast_requested.emit("핵심 노드 노출!")


func _cleanup() -> void:
	ark.set_core_open(false)


func physics_update(delta: float) -> void:
	_time += delta
	if _time >= expose_time:
		finish()
