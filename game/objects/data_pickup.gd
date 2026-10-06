class_name DataPickup
extends Area2D
## 적이 떨어뜨리는 데이터 조각. 튀어나왔다가 잠시 뒤 플레이어에게 빨려 들어간다.

## 조각 하나가 담는 최대 데이터 양
const MAX_VALUE_PER_SHARD: int = 5
## 한 번에 만드는 최대 조각 수
const MAX_SHARDS: int = 8

@export var value: int = 5
## 튀어나오는 속도 (px/s)
@export var pop_speed: float = 140.0
## 튀어나온 뒤 감속 (px/s²)
@export var drag: float = 400.0
## 빨려 들어가기 시작하기까지 (초)
@export var home_delay: float = 0.35
## 빨려 들어가는 가속 (px/s²)
@export var home_accel: float = 1600.0
## 이 거리 안에 들어오면 획득 (px)
@export var collect_distance: float = 12.0
@export var color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var size: float = 5.0
@export_flags_2d_physics var pickup_layer: int = 64

var _velocity: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _target: Node2D


## amount를 여러 조각으로 나눠 position 주변에 뿌린다.
static func spawn_burst(parent: Node, pos: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	var shards: int = clampi(ceili(float(amount) / MAX_VALUE_PER_SHARD), 1, MAX_SHARDS)
	var base: int = amount / shards
	var remainder: int = amount % shards
	for i: int in shards:
		var pickup := DataPickup.new()
		pickup.value = base + (1 if i < remainder else 0)
		parent.add_child(pickup)
		pickup.global_position = pos
		pickup.launch(Vector2.UP.rotated(randf_range(-PI * 0.4, PI * 0.4)))


func _ready() -> void:
	collision_layer = pickup_layer
	collision_mask = 0
	monitoring = false
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
	add_child(visual)


func launch(direction: Vector2) -> void:
	_velocity = direction * pop_speed


func _physics_process(delta: float) -> void:
	_time += delta
	if _time < home_delay:
		_velocity = _velocity.move_toward(Vector2.ZERO, drag * delta)
	else:
		if _target == null:
			_target = get_tree().get_first_node_in_group(&"player") as Node2D
		if _target:
			var center: Vector2 = _target.global_position + Vector2.UP * size * 4.0
			var to_target: Vector2 = center - global_position
			if to_target.length() <= collect_distance:
				_collect()
				return
			_velocity += to_target.normalized() * home_accel * delta
			# 목표를 지나치지 않도록 방향을 맞춘다.
			_velocity = to_target.normalized() * _velocity.length()
	global_position += _velocity * delta


func _collect() -> void:
	GameState.add_data(value)
	queue_free()
