class_name BodyWreck
extends Node2D
## 의체 잔해. 파괴된 위치에 남고, 상호작용하면 들고 있던 데이터를 회수한다.
## 레벨은 GameState.wreck_changed 때 sync()를 호출해 잔해를 맞춘다.

const GROUP: StringName = &"body_wreck"

@export var body_color: Color = Color(0.45, 0.47, 0.55, 1.0)
@export var glow_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var glow_period: float = 0.6

var _glow: ColorRect
var _time: float = 0.0


## GameState의 잔해 정보에 맞춰 parent 아래 잔해를 다시 만든다.
static func sync(parent: Node) -> void:
	for node: Node in parent.get_tree().get_nodes_in_group(GROUP):
		node.queue_free()
	if not GameState.has_wreck():
		return
	var wreck := BodyWreck.new()
	parent.add_child(wreck)
	wreck.global_position = GameState.wreck["position"]


func _ready() -> void:
	add_to_group(GROUP)
	var body := ColorRect.new()
	body.size = Vector2(30, 10)
	body.position = Vector2(-15, -10)
	body.color = body_color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_glow = ColorRect.new()
	_glow.size = Vector2(6, 6)
	_glow.position = Vector2(-3, -16)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	var interactable := InteractableComponent.new()
	interactable.prompt = "W 회수 (%d)" % int(GameState.wreck.get("data", 0))
	interactable.prompt_offset = Vector2(-40, -40)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 30)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -12)
	interactable.add_child(col)
	add_child(interactable)
	interactable.interacted.connect(_on_interacted)


func _process(delta: float) -> void:
	_time += delta
	var c := glow_color
	c.a = 0.5 + 0.5 * sin(_time * TAU / glow_period)
	_glow.color = c


func _on_interacted(_actor: Node) -> void:
	var amount: int = GameState.recover_wreck()
	EventBus.toast_requested.emit("데이터 %d 회수" % amount)
