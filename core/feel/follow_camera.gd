class_name FollowCamera
extends Camera2D
## 대상을 부드럽게 따라가는 카메라. 대상의 진행 방향으로 화면을 조금 앞서 보여준다.
## 대상이 `facing: float` 속성을 가지고 있으면 그 방향으로 미리보기를 준다.

@export var target: Node2D
## 진행 방향으로 앞서 보여줄 거리 (px)
@export var look_ahead_distance: float = 48.0
## 미리보기 오프셋이 목표값에 다가가는 속도 (클수록 빠름)
@export var look_ahead_speed: float = 3.0
## 화면 중심을 대상보다 위로 올리는 거리 (px). 발밑보다 위쪽을 더 보여준다.
@export var vertical_offset: float = -24.0
## 대상 위치를 따라가는 속도 (클수록 빠름)
@export var follow_speed: float = 10.0

var _look_ahead: float = 0.0


func _ready() -> void:
	if target:
		global_position = _desired_position()
	reset_smoothing()


func _process(delta: float) -> void:
	if target == null:
		return
	var facing: float = 0.0
	var facing_value: Variant = target.get("facing")
	if facing_value is float:
		facing = facing_value
	_look_ahead = lerpf(_look_ahead, facing * look_ahead_distance, 1.0 - exp(-look_ahead_speed * delta))
	global_position = global_position.lerp(_desired_position(), 1.0 - exp(-follow_speed * delta))


func _desired_position() -> Vector2:
	return target.global_position + Vector2(_look_ahead, vertical_offset)
