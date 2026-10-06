class_name DataCache
extends Node2D
## 데이터 캐시. 공격 한 번에 부서지며 데이터가 쏟아진다.

@export var data_amount: int = 50
@export var size: Vector2 = Vector2(16, 14)
@export var color: Color = Color(0.2, 0.3, 0.55, 1.0)
@export var stripe_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export_flags_2d_physics var hurt_layer: int = 4

var _health: HealthComponent


func _ready() -> void:
	var box := ColorRect.new()
	box.size = size
	box.position = Vector2(-size.x * 0.5, -size.y)
	box.color = color
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var stripe := ColorRect.new()
	stripe.size = Vector2(size.x, 2)
	stripe.position = Vector2(-size.x * 0.5, -size.y * 0.5)
	stripe.color = stripe_color
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stripe)

	_health = HealthComponent.new()
	_health.max_hp = 1
	add_child(_health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.collision_layer = hurt_layer
	hurtbox.collision_mask = 0
	hurtbox.health = _health
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -size.y * 0.5)
	hurtbox.add_child(col)
	add_child(hurtbox)
	_health.died.connect(_on_broken)


func _on_broken() -> void:
	DataPickup.spawn_burst(get_parent(), global_position + Vector2(0, -size.y), data_amount)
	queue_free()
