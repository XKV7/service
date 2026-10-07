class_name RailSwitch
extends Node2D
## 레일건으로만 맞출 수 있는 스위치. 맞으면 연결된 셔터를 연다.
## hologram 레이어에 있어서 근접 공격은 통과하고 레일건만 닿는다.

@export var shutter: Shutter
@export var size: Vector2 = Vector2(12, 12)
@export var off_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var on_color: Color = Color(0.3, 1.0, 0.5, 1.0)
@export var glow_period: float = 0.8
@export_flags_2d_physics var hurt_layer: int = 256

var _rect: ColorRect
var _on: bool = false
var _time: float = 0.0


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.size = size
	_rect.position = -size * 0.5
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_on = shutter == null or not is_instance_valid(shutter) or GameState.is_secret_open(shutter.secret_id)
	if _on:
		return
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
	health.died.connect(_on_hit)


func is_on() -> bool:
	return _on


func _process(delta: float) -> void:
	_time += delta
	if _on:
		_rect.color = on_color
	else:
		var c := off_color
		c.a = 0.6 + 0.4 * sin(_time * TAU / glow_period)
		_rect.color = c


func _on_hit() -> void:
	_on = true
	EventBus.toast_requested.emit("스위치 작동")
	if is_instance_valid(shutter):
		shutter.open()
