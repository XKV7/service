class_name StageExit
extends Area2D
## 구역 출구. 플레이어가 닿으면 다음 씬으로 넘어간다.

@export_file("*.tscn") var target_scene: String = ""
@export var size: Vector2 = Vector2(24, 120)
@export var color: Color = Color(0.0, 1.0, 0.9, 0.15)
@export_flags_2d_physics var player_mask: int = 2

var _used: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = player_mask
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -size.y * 0.5)
	add_child(col)
	var rect := ColorRect.new()
	rect.size = size
	rect.position = Vector2(-size.x * 0.5, -size.y)
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body is Player or (body as Player).is_dead():
		return
	_used = true
	SceneGate.travel(get_tree(), target_scene)
