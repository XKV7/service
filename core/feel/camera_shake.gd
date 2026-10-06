class_name CameraShake
extends Node
## Camera2D 흔들림. trauma(0~1) 방식으로, 세기의 제곱만큼 흔든다.
## EventBus.screen_shake_requested를 구독한다.

@export var camera: Camera2D
## trauma가 1일 때 최대 흔들림 (px)
@export var max_offset: float = 8.0
## 초당 trauma 감소량
@export var decay: float = 2.5

var _trauma: float = 0.0


func _ready() -> void:
	EventBus.screen_shake_requested.connect(add_trauma)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if camera == null:
		return
	if _trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - decay * delta, 0.0)
	var strength: float = _trauma * _trauma * max_offset
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
