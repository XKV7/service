class_name PopupAd
extends Node2D
## 팝업 광고 창. 잠시 뒤 플레이어에게 투사체를 쏜다. 근접 한 방에 부서진다. 수명이 지나면 닫힌다.

const GROUP: StringName = &"miso_popup"

@export var attack: AttackData
@export var size: Vector2 = Vector2(40, 28)
@export var appear_time: float = 0.6
@export var fire_interval: float = 1.8
## 쏘기 전 깜빡임 (초)
@export var fire_telegraph: float = 0.45
@export var projectile_speed: float = 150.0
@export var projectile_size: float = 5.0
@export var lifetime: float = 8.0
@export var color: Color = Color(1.0, 0.85, 0.95, 0.9)
@export var bar_color: Color = Color(1.0, 0.3, 0.6, 1.0)
@export var flash_color: Color = Color(1.0, 1.0, 0.4, 1.0)
@export var projectile_color: Color = Color(1.0, 0.4, 0.8, 1.0)
@export var flash_period: float = 0.08
@export_flags_2d_physics var hurt_layer: int = 4
@export_flags_2d_physics var hitbox_layer: int = 16
@export_flags_2d_physics var target_mask: int = 2

var _time: float = 0.0
var _fire_timer: float = 0.0
var _body: ColorRect


func _ready() -> void:
	add_to_group(GROUP)
	_body = ColorRect.new()
	_body.size = size
	_body.position = -size * 0.5
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	var bar := ColorRect.new()
	bar.size = Vector2(size.x, 5)
	bar.position = -size * 0.5
	bar.color = bar_color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(bar)
	bar.position = Vector2.ZERO
	var label := Label.new()
	label.text = "SALE"
	label.add_theme_font_size_override(&"font_size", 12)
	label.add_theme_color_override(&"font_color", bar_color)
	label.position = Vector2(4, 6)
	_body.add_child(label)

	var health := HealthComponent.new()
	health.max_hp = 1
	add_child(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.collision_layer = hurt_layer
	hurtbox.collision_mask = 0
	hurtbox.health = health
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	hurtbox.add_child(col)
	add_child(hurtbox)
	health.died.connect(queue_free)
	_fire_timer = fire_interval


func is_appearing() -> bool:
	return _time < appear_time


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	if is_appearing():
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_fire()


func _process(_delta: float) -> void:
	if is_appearing():
		_body.modulate.a = _time / appear_time
		return
	var warning: bool = _fire_timer <= fire_telegraph and int(_fire_timer / flash_period) % 2 == 0
	_body.color = flash_color if warning else color


func _fire() -> void:
	var target := get_tree().get_first_node_in_group(&"player") as Node2D
	if target == null:
		return
	var aim: Vector2 = (target.global_position + Vector2(0, -22) - global_position).normalized()
	Projectile.spawn(get_parent(), global_position, aim * projectile_speed, attack, projectile_size,
			projectile_color, hitbox_layer, target_mask)
