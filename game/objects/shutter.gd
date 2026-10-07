class_name Shutter
extends StaticBody2D
## 보안 셔터. open()이 불리면 열린다. 한 번 연 셔터는 다시 닫히지 않는다.
## 노드 위치가 셔터의 왼쪽 위 모서리다.

@export var secret_id: StringName = &""
@export var size: Vector2 = Vector2(16, 80)
@export var color: Color = Color(0.7, 0.72, 0.8, 1.0)
@export var stripe_color: Color = Color(0.9, 0.75, 0.3, 1.0)
@export var open_time: float = 0.4
@export_flags_2d_physics var world_layer: int = 1

var _collision: CollisionShape2D
var _visual: Node2D


func _ready() -> void:
	if GameState.is_secret_open(secret_id):
		queue_free()
		return
	collision_layer = world_layer
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	_collision.position = size * 0.5
	add_child(_collision)
	_visual = Node2D.new()
	add_child(_visual)
	var rect := ColorRect.new()
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual.add_child(rect)
	var step: float = 12.0
	var y: float = 4.0
	while y < size.y:
		var stripe := ColorRect.new()
		stripe.size = Vector2(size.x, 2.0)
		stripe.position = Vector2(0.0, y)
		stripe.color = stripe_color
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual.add_child(stripe)
		y += step


func open() -> void:
	if is_queued_for_deletion():
		return
	GameState.open_secret(secret_id)
	_collision.set_deferred(&"disabled", true)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, open_time)
	tween.tween_callback(queue_free)
