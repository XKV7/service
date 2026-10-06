class_name Relay
extends Node2D
## 중계기(체크포인트). 상호작용하면 내구도 회복, 연산력 설정, 재접속 지점 등록, 적 재배치를 하고
## 의체 메뉴(장착·강화·무기 교체)를 연다. 처음 접속할 때는 짧은 해킹 연출이 있다.

@export var relay_id: StringName = &"relay"
## 처음 접속할 때 해킹 시간 (초)
@export var activation_time: float = 0.8
## 접속 시 연산력
@export var rest_energy: float = 50.0
@export var size: Vector2 = Vector2(16, 40)
@export var body_color: Color = Color(0.35, 0.37, 0.45, 1.0)
@export var light_off_color: Color = Color(0.4, 0.15, 0.2, 1.0)
@export var light_on_color: Color = Color(0.0, 1.0, 0.9, 1.0)
## 해킹 중 깜빡임 주기 (초)
@export var hack_flash_period: float = 0.08

var _light: ColorRect
var _interactable: InteractableComponent
var _activating: bool = false
var _activation_left: float = 0.0
var _player: Player


func _ready() -> void:
	var body := ColorRect.new()
	body.size = size
	body.position = Vector2(-size.x * 0.5, -size.y)
	body.color = body_color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_light = ColorRect.new()
	_light.size = Vector2(size.x * 0.5, size.x * 0.5)
	_light.position = Vector2(-size.x * 0.25, -size.y + size.x * 0.25)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_light)

	_interactable = InteractableComponent.new()
	_interactable.prompt = "W 접속"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size.x * 3.0, size.y)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0.0, -size.y * 0.5)
	_interactable.add_child(col)
	add_child(_interactable)
	_interactable.interacted.connect(_on_interacted)


func is_active() -> bool:
	return relay_id in GameState.activated_relays


func _on_interacted(actor: Node) -> void:
	var p := actor as Player
	if p == null or _activating:
		return
	_player = p
	if is_active():
		_rest()
		return
	_activating = true
	_activation_left = activation_time
	p.input_locked = true
	p.velocity.x = 0.0


func _physics_process(delta: float) -> void:
	if not _activating:
		return
	_activation_left -= delta
	if _activation_left <= 0.0:
		_activating = false
		_player.input_locked = false
		_rest()


func _process(_delta: float) -> void:
	if _activating:
		var on: bool = int(_activation_left / hack_flash_period) % 2 == 0
		_light.color = light_on_color if on else light_off_color
	else:
		_light.color = light_on_color if is_active() else light_off_color


func _rest() -> void:
	var first: bool = GameState.activate_relay(relay_id)
	_player.health.reset()
	_player.energy.set_value(rest_energy)
	_player.respawn_position = global_position
	EventBus.relay_activated.emit(relay_id)
	EventBus.toast_requested.emit("중계기 해킹 완료" if first else "중계기 접속")
	EventBus.body_menu_requested.emit(true)
