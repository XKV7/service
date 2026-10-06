class_name HitStop
extends RefCounted
## 타격 순간 Engine.time_scale을 잠깐 낮춰 멈칫하는 느낌을 준다.
## 여러 번 겹치면 가장 늦게 끝나는 것을 따른다.

const NORMAL_SCALE: float = 1.0
const DEFAULT_SLOW_SCALE: float = 0.05
const MSEC_PER_SEC: float = 1000.0

static var _until_msec: int = 0
static var _token: int = 0


static func trigger(tree: SceneTree, duration: float, slow_scale: float = DEFAULT_SLOW_SCALE) -> void:
	if duration <= 0.0 or tree == null:
		return
	var end_msec: int = Time.get_ticks_msec() + int(duration * MSEC_PER_SEC)
	if end_msec <= _until_msec:
		return
	_until_msec = end_msec
	_token += 1
	var my_token: int = _token
	Engine.time_scale = slow_scale
	# 마지막 인자 true: time_scale의 영향을 받지 않는 타이머
	var timer: SceneTreeTimer = tree.create_timer(duration, true, false, true)
	timer.timeout.connect(func() -> void:
		if my_token == _token:
			Engine.time_scale = NORMAL_SCALE
	)


## 진행 중인 히트스톱을 즉시 끝낸다. (씬 전환 등)
static func cancel() -> void:
	_token += 1
	_until_msec = 0
	Engine.time_scale = NORMAL_SCALE
