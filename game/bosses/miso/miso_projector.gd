class_name MisoProjector
extends Node2D
## 미소를 비추는 투사기. 부서지면 미소에게 피해가 들어가는 시간이 생기고, 잠시 뒤 다시 만들어진다.

signal destroyed

const GROUP: StringName = &"miso_projector"

@export var max_hp: int = 40
@export var size: Vector2 = Vector2(20, 20)
## 다시 만들어지기까지 (초)
@export var rebuild_time: float = 15.0
@export var color: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var lens_color: Color = Color(1.0, 0.3, 0.8, 1.0)
@export var broken_color: Color = Color(0.3, 0.3, 0.35, 0.6)
## 미소 얼굴 쪽으로 그리는 빛줄기
@export var beam_target: Vector2 = Vector2(320, 120)
@export var beam_color: Color = Color(1.0, 0.3, 0.8, 0.15)
@export_flags_2d_physics var hurt_layer: int = 4

var health: HealthComponent
var _hurtbox: HurtboxComponent
var _box: ColorRect
var _lens: ColorRect
var _beam: Line2D
var _broken_left: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	_beam = Line2D.new()
	_beam.width = 6.0
	_beam.default_color = beam_color
	_beam.points = PackedVector2Array([Vector2.ZERO, beam_target - global_position])
	add_child(_beam)
	_box = ColorRect.new()
	_box.size = size
	_box.position = -size * 0.5
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_lens = ColorRect.new()
	_lens.size = size * 0.4
	_lens.position = -size * 0.2
	_lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lens)

	health = HealthComponent.new()
	health.max_hp = max_hp
	add_child(health)
	_hurtbox = HurtboxComponent.new()
	_hurtbox.collision_layer = hurt_layer
	_hurtbox.collision_mask = 0
	_hurtbox.health = health
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	_hurtbox.add_child(col)
	add_child(_hurtbox)
	_hurtbox.hurt.connect(func(_h: HitboxComponent, d: int) -> void:
		DamageNumber.spawn(get_parent(), global_position + Vector2(0, -size.y), str(d), Color.WHITE))
	health.died.connect(_on_died)
	_set_broken(false)


func is_broken() -> bool:
	return _broken_left > 0.0


func _physics_process(delta: float) -> void:
	if _broken_left <= 0.0:
		return
	_broken_left -= delta
	if _broken_left <= 0.0:
		var boss := get_tree().get_first_node_in_group(&"boss") as Boss
		if boss and boss.is_defeated():
			return
		health.reset()
		_set_broken(false)


func _on_died() -> void:
	_broken_left = rebuild_time
	_set_broken(true)
	EventBus.screen_shake_requested.emit(0.5)
	destroyed.emit()


func _set_broken(broken: bool) -> void:
	_hurtbox.set_deferred(&"monitorable", not broken)
	_box.color = broken_color if broken else color
	_lens.visible = not broken
	_beam.visible = not broken
