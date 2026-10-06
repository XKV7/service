class_name HitboxComponent
extends Area2D
## 공격 판정. activate()로 켜면 판정 시간 동안 겹친 Hurtbox에 한 번씩 피해를 준다.
## 충돌 모양은 AttackData에 따라 코드에서 만든다.

signal hit_landed(hurtbox: HurtboxComponent, damage: int, killed: bool)
## 방패 등에 막힘
signal hit_blocked(hurtbox: HurtboxComponent)
## 체력이 없는 단단한 대상(함정 등)에 맞음. 아래 찍기 튕김 등에 사용한다.
signal hit_solid(hurtbox: HurtboxComponent)

## 판정이 켜져 있을 때 그리는 색 (플레이스홀더용, 알파 0이면 그리지 않음)
@export var draw_color: Color = Color(0.0, 1.0, 0.9, 0.35)
## 켜져 있는 동안 같은 대상을 계속 때린다. (접촉 피해, 함정) 연타는 대상의 무적 시간이 막는다.
@export var continuous: bool = false

var attack_data: AttackData
## 공격력 배율 (부품 효과 등)
var damage_mult: float = 1.0
## 넉백 방향
var direction: Vector2 = Vector2.RIGHT
var active: bool = false

var _shape: RectangleShape2D
var _already_hit: Array[Area2D] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	_shape = RectangleShape2D.new()
	var collision := CollisionShape2D.new()
	collision.shape = _shape
	add_child(collision)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area: Area2D in get_overlapping_areas():
		if not continuous:
			if area in _already_hit:
				continue
			_already_hit.append(area)
		if area is HurtboxComponent:
			(area as HurtboxComponent).receive_hit(self)


## AttackData의 판정 크기·위치로 켠다. facing은 1 또는 -1.
func activate(data: AttackData, facing: float) -> void:
	var offset := Vector2(data.hitbox_offset.x * facing, data.hitbox_offset.y)
	activate_rect(data, offset, data.hitbox_size, Vector2(facing, 0.0))


## 판정 위치와 크기를 직접 지정해서 켠다. (빔 등)
func activate_rect(data: AttackData, local_center: Vector2, size: Vector2, knockback_dir: Vector2) -> void:
	attack_data = data
	direction = knockback_dir
	position = local_center
	_shape.size = size
	_already_hit.clear()
	active = true
	queue_redraw()


func deactivate() -> void:
	active = false
	queue_redraw()


## Hurtbox가 피해를 적용한 뒤 호출한다.
func notify_hit(hurtbox: HurtboxComponent, damage: int, killed: bool) -> void:
	hit_landed.emit(hurtbox, damage, killed)


func notify_blocked(hurtbox: HurtboxComponent) -> void:
	hit_blocked.emit(hurtbox)


func notify_solid(hurtbox: HurtboxComponent) -> void:
	hit_solid.emit(hurtbox)


func _draw() -> void:
	if active and draw_color.a > 0.0:
		draw_rect(Rect2(-_shape.size * 0.5, _shape.size), draw_color)
