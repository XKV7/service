class_name SceneGate
extends Node2D
## 다른 씬으로 넘어가는 입구. 상호작용하면 target_scene으로 이동한다.

@export_file("*.tscn") var target_scene: String = ""
@export var prompt: String = "W 이동"
@export var size: Vector2 = Vector2(24, 44)
@export var color: Color = Color(0.5, 0.2, 0.8, 0.8)
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready():
			_apply_enabled()

var _visual: ColorRect
var _interactable: InteractableComponent


func _ready() -> void:
	_visual = ColorRect.new()
	_visual.size = size
	_visual.position = Vector2(-size.x * 0.5, -size.y)
	_visual.color = color
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)
	_interactable = InteractableComponent.new()
	_interactable.prompt = prompt
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -size.y * 0.5)
	_interactable.add_child(col)
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)
	_apply_enabled()


func _apply_enabled() -> void:
	_visual.visible = enabled
	_interactable.enabled = enabled


func _on_interacted(_actor: Node) -> void:
	if target_scene == "":
		return
	HitStop.cancel()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(target_scene)
