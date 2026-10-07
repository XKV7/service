class_name StoryTrigger
extends Area2D
## 플레이어가 지나가면 한 번 재생되는 대사 장면. 노드 위치가 영역 아래 가운데다.

@export var dialogue: DialogueData
@export var size: Vector2 = Vector2(80, 120)
@export_flags_2d_physics var player_mask: int = 2


func _ready() -> void:
	if dialogue == null or Story.has_seen(dialogue):
		queue_free()
		return
	collision_layer = 0
	collision_mask = player_mask
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -size.y * 0.5)
	add_child(col)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	Story.play_once(dialogue)
	queue_free()
