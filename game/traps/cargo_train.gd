class_name CargoTrain
extends Node2D
## 무인 화물차. 일정 주기로 경고등이 켜진 뒤 선로 구간을 빠르게 지나간다.
## 선로 위 대피 공간(승강장 발판)으로 피한다. 노드 위치는 선로 구간 왼쪽 끝(선로 높이)이다.

@export var attack: AttackData
## 선로 구간 길이 (px)
@export var track_length: float = 1600.0
@export var speed: float = 600.0
@export var warn_time: float = 1.2
## 지나간 뒤 다음 경고까지 (초)
@export var rest_time: float = 2.5
## 시작 전 대기 (초)
@export var start_delay: float = 1.0
@export var car_size: Vector2 = Vector2(160, 48)
@export var car_color: Color = Color(0.55, 0.45, 0.3, 1.0)
@export var warn_color: Color = Color(1.0, 0.8, 0.2, 0.25)
@export var light_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var flash_period: float = 0.12
## 진행 방향 (1 = 오른쪽)
@export var direction: float = 1.0
@export_flags_2d_physics var hitbox_layer: int = 16
@export_flags_2d_physics var target_mask: int = 2

enum Phase { REST, WARN, PASS }

var _phase: Phase = Phase.REST
var _time: float = 0.0
var _car: Node2D
var _hitbox: HitboxComponent
var _warn_rect: ColorRect


func _ready() -> void:
	_warn_rect = ColorRect.new()
	_warn_rect.size = Vector2(track_length, car_size.y)
	_warn_rect.position = Vector2(0.0, -car_size.y)
	_warn_rect.color = Color.TRANSPARENT
	_warn_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_warn_rect)
	_car = Node2D.new()
	_car.visible = false
	add_child(_car)
	var body := ColorRect.new()
	body.size = car_size
	body.position = Vector2(-car_size.x * 0.5, -car_size.y)
	body.color = car_color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_car.add_child(body)
	var light := ColorRect.new()
	light.size = Vector2(6, 8)
	light.position = Vector2(car_size.x * 0.5 * direction - 3.0, -car_size.y + 6.0)
	light.color = light_color
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_car.add_child(light)
	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = hitbox_layer
	_hitbox.collision_mask = target_mask
	_hitbox.draw_color = Color.TRANSPARENT
	_car.add_child(_hitbox)
	_time = rest_time - start_delay


func is_passing() -> bool:
	return _phase == Phase.PASS


func _physics_process(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.REST:
			if _time >= rest_time:
				_phase = Phase.WARN
				_time = 0.0
		Phase.WARN:
			if _time >= warn_time:
				_phase = Phase.PASS
				_time = 0.0
				_car.visible = true
				_car.position = Vector2(_start_x(), 0.0)
				_hitbox.activate_rect(attack, Vector2(0, -car_size.y * 0.5), car_size, Vector2(direction, 0.0))
		Phase.PASS:
			_car.position.x += direction * speed * delta
			if (_car.position.x - _end_x()) * direction >= 0.0:
				_phase = Phase.REST
				_time = 0.0
				_car.visible = false
				_hitbox.deactivate()


func _process(_delta: float) -> void:
	if _phase == Phase.WARN and int(_time / flash_period) % 2 == 0:
		_warn_rect.color = warn_color
	else:
		_warn_rect.color = Color.TRANSPARENT


func _start_x() -> float:
	return -car_size.x if direction > 0.0 else track_length + car_size.x


func _end_x() -> float:
	return track_length + car_size.x if direction > 0.0 else -car_size.x
