class_name InteractableComponent
extends Area2D
## 상호작용 대상. 플레이어가 범위 안에 들어오면 안내 문구를 보여주고,
## 상호작용하면 interacted 시그널을 보낸다.

signal interacted(actor: Node)

@export var prompt: String = "상호작용"
## 안내 문구 위치
@export var prompt_offset: Vector2 = Vector2(-40, -64)
@export var prompt_width: float = 80.0
## 안내 문구를 띄울 대상 레이어 (플레이어 몸)
@export_flags_2d_physics var actor_mask: int = 2
@export_flags_2d_physics var interactable_layer: int = 32
@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_prompt()

var _label: Label
var _actors_in_range: int = 0


func _ready() -> void:
	collision_layer = interactable_layer
	collision_mask = actor_mask
	monitoring = true
	monitorable = true
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = prompt_offset
	_label.size = Vector2(prompt_width, 0.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	body_entered.connect(func(_b: Node2D) -> void:
		_actors_in_range += 1
		_update_prompt())
	body_exited.connect(func(_b: Node2D) -> void:
		_actors_in_range = maxi(_actors_in_range - 1, 0)
		_update_prompt())
	_update_prompt()


func interact(actor: Node) -> void:
	if enabled:
		interacted.emit(actor)


func set_prompt(text: String) -> void:
	prompt = text
	_update_prompt()


func _update_prompt() -> void:
	if _label == null:
		return
	_label.text = prompt
	_label.visible = enabled and _actors_in_range > 0
