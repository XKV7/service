class_name ElectricRail
extends Node2D
## 감전 선로. 닿으면 피해를 주고 튕겨낸다. 노드 위치가 선로 왼쪽 위 모서리다.
## 아래 찍기로 밟으면 튀어 오를 수 있다.

@export var attack: AttackData
@export var size: Vector2 = Vector2(100, 6)
@export var color_on: Color = Color(1.0, 0.95, 0.3, 1.0)
@export var color_off: Color = Color(0.5, 0.45, 0.15, 1.0)
## 전기 깜빡임 주기 (초)
@export var flicker_period: float = 0.07
## 피해 판정 높이 여유 (위로, px)
@export var hit_margin: float = 4.0
@export_flags_2d_physics var hazard_layer: int = 128
@export_flags_2d_physics var target_mask: int = 2

var _rect: ColorRect
var _hitbox: HitboxComponent


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.size = size
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

	var hit_size := Vector2(size.x, size.y + hit_margin)
	var center := Vector2(size.x * 0.5, size.y * 0.5 - hit_margin * 0.5)
	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = hazard_layer
	_hitbox.collision_mask = target_mask
	_hitbox.continuous = true
	_hitbox.draw_color = Color.TRANSPARENT
	add_child(_hitbox)
	_hitbox.activate_rect(attack, center, hit_size, Vector2.ZERO)

	# 아래 찍기용 단단한 판정 (체력 없음)
	var solid := HurtboxComponent.new()
	solid.collision_layer = hazard_layer
	solid.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = hit_size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = center
	solid.add_child(col)
	add_child(solid)


func _process(_delta: float) -> void:
	var on: bool = int(Time.get_ticks_msec() / (flicker_period * 1000.0)) % 3 != 0
	_rect.color = color_on if on else color_off
