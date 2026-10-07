class_name HazardZone
extends Node2D
## 예고 → 판정 → 사라지는 위험 지대. 예고 동안 깜빡이고, 판정 시간 동안 피해를 준다.
## 집게팔, 전류, 스파크, 폭탄, 데이터 장판 등 보스 공격 대부분에 쓴다.

signal activated

@export var warn_flash_period: float = 0.1
@export_flags_2d_physics var hitbox_layer: int = 16
@export_flags_2d_physics var target_mask: int = 2

var _rect: Rect2
var _attack: AttackData
var _warn_time: float = 0.0
var _active_time: float = 0.0
var _warn_color: Color
var _active_color: Color
var _continuous: bool = false
var _time: float = 0.0
var _active: bool = false
var _visual: ColorRect
var _hitbox: HitboxComponent


## rect는 전역 좌표. warn_time이 0이면 바로 판정이 나온다.
static func spawn(parent: Node, rect: Rect2, attack: AttackData, warn_time: float, active_time: float,
		warn_color: Color, active_color: Color, continuous: bool = false) -> HazardZone:
	var zone := HazardZone.new()
	zone._rect = rect
	zone._attack = attack
	zone._warn_time = warn_time
	zone._active_time = active_time
	zone._warn_color = warn_color
	zone._active_color = active_color
	zone._continuous = continuous
	parent.add_child(zone)
	zone.global_position = rect.position
	return zone


func _ready() -> void:
	_visual = ColorRect.new()
	_visual.size = _rect.size
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = hitbox_layer
	_hitbox.collision_mask = target_mask
	_hitbox.continuous = _continuous
	_hitbox.draw_color = Color.TRANSPARENT
	add_child(_hitbox)


func is_warning() -> bool:
	return not _active


func _physics_process(delta: float) -> void:
	_time += delta
	if not _active and _time >= _warn_time:
		_active = true
		_time = 0.0
		_hitbox.activate_rect(_attack, _rect.size * 0.5, _rect.size, Vector2.ZERO)
		activated.emit()
	elif _active and _time >= _active_time:
		queue_free()


func _process(_delta: float) -> void:
	if _active:
		_visual.color = _active_color
	else:
		var on: bool = int(_time / warn_flash_period) % 2 == 0
		_visual.color = _warn_color if on else Color(_warn_color, _warn_color.a * 0.3)
