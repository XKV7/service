class_name FakeWall
extends StaticBody2D
## 가짜 벽. 공격을 hits_to_break번 맞으면 부서진다. 한 번 부순 벽은 다시 생기지 않는다.
## 노드 위치가 벽의 왼쪽 위 모서리다.

## 숨겨진 공간 id (세이브용)
@export var secret_id: StringName = &""
@export var size: Vector2 = Vector2(20, 100)
@export var hits_to_break: int = 3
@export var color: Color = Color(0.16, 0.18, 0.32, 1.0)
## 금 간 표시 (아주 살짝 보인다)
@export var crack_color: Color = Color(0.22, 0.24, 0.4, 1.0)
@export var hit_shake: float = 0.15
@export_flags_2d_physics var world_layer: int = 1
@export_flags_2d_physics var hurt_layer: int = 4

var _health: HealthComponent
var _rect: ColorRect
var _crack: ColorRect


func _ready() -> void:
	if GameState.is_secret_open(secret_id):
		queue_free()
		return
	collision_layer = world_layer
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = size * 0.5
	add_child(col)
	_rect = ColorRect.new()
	_rect.size = size
	_rect.color = color
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_crack = ColorRect.new()
	_crack.size = Vector2(2.0, size.y * 0.4)
	_crack.position = Vector2(size.x * 0.5, size.y * 0.3)
	_crack.color = crack_color
	_crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crack)

	_health = HealthComponent.new()
	_health.max_hp = hits_to_break
	add_child(_health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.collision_layer = hurt_layer
	hurtbox.collision_mask = 0
	hurtbox.health = _health
	# 공격 세기와 상관없이 한 번 맞을 때마다 1씩 깎이게 한다.
	hurtbox.damage_taken_mult = 0.0
	var hurt_shape := RectangleShape2D.new()
	hurt_shape.size = size
	var hurt_col := CollisionShape2D.new()
	hurt_col.shape = hurt_shape
	hurt_col.position = size * 0.5
	hurtbox.add_child(hurt_col)
	add_child(hurtbox)
	_health.damaged.connect(_on_damaged)
	_health.died.connect(_on_broken)


func _on_damaged(_amount: int) -> void:
	EventBus.screen_shake_requested.emit(hit_shake)
	_crack.size.x += 2.0
	_crack.color = _crack.color.lightened(0.15)


func _on_broken() -> void:
	GameState.open_secret(secret_id)
	EventBus.toast_requested.emit("숨겨진 공간을 발견했다")
	queue_free()
