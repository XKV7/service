class_name CrumblingPlatform
extends StaticBody2D
## 무너지는 발판. 밟으면 흔들리다가 무너지고, 잠시 뒤 복구된다.
## 노드 위치가 발판 왼쪽 위 모서리다. 안전 지점으로 기록되지 않는다.

@export var size: Vector2 = Vector2(64, 12)
## 밟고 나서 무너지기까지 (초)
@export var crumble_delay: float = 0.6
## 무너진 뒤 복구까지 (초)
@export var restore_time: float = 3.0
@export var color: Color = Color(0.55, 0.5, 0.45, 1.0)
@export var warn_color: Color = Color(0.9, 0.6, 0.3, 1.0)
## 흔들림 폭 (px)
@export var shake_amount: float = 1.5
@export_flags_2d_physics var world_layer: int = 1
@export_flags_2d_physics var player_mask: int = 2

enum Phase { IDLE, SHAKING, GONE }

var _phase: Phase = Phase.IDLE
var _time: float = 0.0
var _rect: ColorRect
var _collision: CollisionShape2D


func _ready() -> void:
	add_to_group(&"unsafe_ground")
	collision_layer = world_layer
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	_collision.position = size * 0.5
	add_child(_collision)

	_rect = ColorRect.new()
	_rect.size = size
	_rect.color = color
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

	# 위에 올라섰는지 감지하는 얇은 판정
	var detector := Area2D.new()
	detector.collision_layer = 0
	detector.collision_mask = player_mask
	var detect_shape := RectangleShape2D.new()
	detect_shape.size = Vector2(size.x, 4.0)
	var detect_col := CollisionShape2D.new()
	detect_col.shape = detect_shape
	detect_col.position = Vector2(size.x * 0.5, -2.0)
	detector.add_child(detect_col)
	add_child(detector)
	detector.body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node2D) -> void:
	if _phase == Phase.IDLE:
		_phase = Phase.SHAKING
		_time = 0.0


func _physics_process(delta: float) -> void:
	if _phase == Phase.IDLE:
		return
	_time += delta
	if _phase == Phase.SHAKING and _time >= crumble_delay:
		_phase = Phase.GONE
		_time = 0.0
		_collision.set_deferred(&"disabled", true)
		_rect.visible = false
	elif _phase == Phase.GONE and _time >= restore_time:
		_phase = Phase.IDLE
		_collision.set_deferred(&"disabled", false)
		_rect.visible = true
		_rect.position = Vector2.ZERO
		_rect.color = color


func _process(_delta: float) -> void:
	if _phase == Phase.SHAKING:
		_rect.color = warn_color
		_rect.position = Vector2(randf_range(-shake_amount, shake_amount), 0.0)
