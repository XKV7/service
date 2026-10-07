class_name MemoryFragment
extends Area2D
## 기억 조각. 닿으면 ROOT의 지워진 기억 하나가 회상 장면으로 재생된다.

@export var dialogue: DialogueData
@export var size: float = 7.0
@export var color: Color = Color(0.85, 1.0, 1.0, 1.0)
@export var glow_color: Color = Color(0.3, 1.0, 0.9, 0.35)
@export var bob_height: float = 3.0
@export var bob_period: float = 1.6
@export var hover_height: float = 18.0
@export_flags_2d_physics var pickup_layer: int = 64
@export_flags_2d_physics var player_mask: int = 2

var _visual: Node2D
var _time: float = 0.0


func _ready() -> void:
	if dialogue == null or GameState.has_memory(dialogue.id):
		queue_free()
		return
	collision_layer = pickup_layer
	collision_mask = player_mask
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = size * 2.0
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -hover_height)
	add_child(col)
	_visual = Node2D.new()
	add_child(_visual)
	var glow := Polygon2D.new()
	glow.color = glow_color
	glow.polygon = _diamond(size * 2.0)
	_visual.add_child(glow)
	var core := Polygon2D.new()
	core.color = color
	core.polygon = _diamond(size)
	_visual.add_child(core)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.position = Vector2(0, -hover_height + sin(_time * TAU / bob_period) * bob_height)
	_visual.rotation = sin(_time * TAU / (bob_period * 2.0)) * 0.3


func _diamond(r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -r * 1.4), Vector2(r, 0), Vector2(0, r * 1.4), Vector2(-r, 0)])


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	GameState.collect_memory(dialogue.id)
	EventBus.memory_acquired.emit(dialogue.id)
	Story.play_memory(dialogue, GameState.memories.size(), GameState.MEMORY_TOTAL)
	queue_free()
