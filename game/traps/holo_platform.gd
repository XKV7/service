class_name HoloPlatform
extends StaticBody2D
## 광고 홀로그램 발판. 일정 주기로 켜지고 꺼진다. 꺼지기 직전에 깜빡인다.
## 노드 위치가 발판의 왼쪽 위 모서리다. 안전 지점으로 기록되지 않는다.

@export var size: Vector2 = Vector2(80, 12)
@export var on_time: float = 2.4
@export var off_time: float = 1.4
## 주기 시작 시점 (초). 발판마다 다르게 주어 번갈아 켜지게 한다.
@export var phase_offset: float = 0.0
## 꺼지기 전 깜빡임 시간 (초)
@export var warn_time: float = 0.5
@export var on_color: Color = Color(1.0, 0.3, 0.8, 0.8)
@export var off_color: Color = Color(1.0, 0.3, 0.8, 0.12)
@export var flash_period: float = 0.08
@export_flags_2d_physics var world_layer: int = 1

var _time: float = 0.0
var _solid: bool = true
var _collision: CollisionShape2D
var _rect: ColorRect


func _ready() -> void:
	add_to_group(&"unsafe_ground")
	collision_layer = world_layer
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	_collision.position = size * 0.5
	add_child(_collision)
	_rect = ColorRect.new()
	_rect.size = size
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_time = phase_offset


func is_solid() -> bool:
	return _solid


func _physics_process(delta: float) -> void:
	_time = fmod(_time + delta, on_time + off_time)
	var solid: bool = _time < on_time
	if solid != _solid:
		_solid = solid
		_collision.set_deferred(&"disabled", not solid)


func _process(_delta: float) -> void:
	if not _solid:
		_rect.color = off_color
	elif _time >= on_time - warn_time and int(_time / flash_period) % 2 == 0:
		_rect.color = off_color
	else:
		_rect.color = on_color
