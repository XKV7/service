class_name Enemy
extends CharacterBody2D
## 적 공통 베이스. 이동 보조 함수와 피격·정지·사망 처리를 담당한다.
## 행동은 StateMachine 아래 상태들이 정한다. 상태 이름 규칙:
## Hurt(피격 경직), Stunned(시스템 정지), Dead(사망)는 모든 적이 가진다.

@export var data: EnemyData
## 공중 유닛이면 중력을 받지 않는다.
@export var flying: bool = false
## 천장에 붙어 있으면 중력이 위로 향한다. (선로 크롤러)
@export var on_ceiling: bool = false
@export var gravity: float = 1000.0
@export var max_fall_speed: float = 620.0
## 감속 (px/s²)
@export var friction: float = 1200.0
## 접촉 피해. 비우면 접촉 피해 없음.
@export var contact_attack: AttackData
## 낭떠러지 확인 거리 (몸 앞쪽, px)
@export var edge_check_ahead: float = 14.0
## 낭떠러지 확인 깊이 (px)
@export var edge_check_depth: float = 20.0
@export_flags_2d_physics var world_mask: int = 1

@export_group("표시")
@export var damage_color: Color = Color.WHITE
@export var stunned_damage_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var stun_glitch_color: Color = Color(0.4, 1.0, 1.0, 1.0)
@export var stun_flicker_period: float = 0.08
## 피해 숫자가 뜨는 위치 (몸 중심 기준)
@export var number_offset: Vector2 = Vector2(0, -40)

## 바라보는 방향. 1 = 오른쪽
var facing: float = -1.0
## true인 동안 피격 경직에 빠지지 않는다.
var super_armor: bool = false
## true면 시각 효과(정지 깜빡임 등)를 상태가 직접 제어한다.
var visual_override: bool = false

var _target: Node2D

@onready var visual: Node2D = %Visual
@onready var health: HealthComponent = %Health
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var stun: StunComponent = %Stun
@onready var hit_flash: HitFlash = %HitFlash
@onready var state_machine: StateMachine = %StateMachine
@onready var attack_hitbox: HitboxComponent = get_node_or_null(^"%AttackHitbox") as HitboxComponent
@onready var contact_hitbox: HitboxComponent = get_node_or_null(^"%ContactHitbox") as HitboxComponent


func _ready() -> void:
	assert(data != null, "%s: EnemyData가 지정되지 않았다." % name)
	add_to_group(&"enemy")
	health.max_hp = data.max_hp
	health.reset()
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	stun.stunned.connect(_on_stunned)
	if on_ceiling:
		up_direction = Vector2.DOWN
		visual.scale.y = -1.0
	set_contact_enabled(true)


func _process(_delta: float) -> void:
	visual.scale.x = facing
	if visual_override:
		return
	if stun.is_stunned():
		var flicker_on: bool = int(Time.get_ticks_msec() / (stun_flicker_period * 1000.0)) % 2 == 0
		visual.modulate = stun_glitch_color if flicker_on else Color.WHITE
	else:
		visual.modulate = Color.WHITE


# --- 대상 ---

func get_target() -> Node2D:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player") as Node2D
	return _target


func has_live_target() -> bool:
	var t: Node2D = get_target()
	return t != null and not (t is Player and (t as Player).is_dead())


func distance_to_target() -> float:
	var t: Node2D = get_target()
	return INF if t == null else global_position.distance_to(t.global_position)


func horizontal_distance_to_target() -> float:
	var t: Node2D = get_target()
	return INF if t == null else absf(t.global_position.x - global_position.x)


func direction_to_target() -> float:
	var t: Node2D = get_target()
	if t == null:
		return facing
	var dir: float = signf(t.global_position.x - global_position.x)
	return dir if dir != 0.0 else facing


func can_see_target(range_mult: float = 1.0) -> bool:
	if not has_live_target():
		return false
	var t: Node2D = get_target()
	return horizontal_distance_to_target() <= data.detect_range * range_mult \
			and absf(t.global_position.y - global_position.y) <= data.detect_height


func face_target() -> void:
	facing = direction_to_target()


# --- 이동 ---

func apply_gravity(delta: float) -> void:
	if flying:
		return
	var dir: float = -1.0 if on_ceiling else 1.0
	velocity.y = clampf(velocity.y + gravity * dir * delta, -max_fall_speed, max_fall_speed)


func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if flying:
		velocity.y = move_toward(velocity.y, 0.0, friction * delta)


## 수평으로 speed까지 가속한다. dir은 -1/0/1
func accelerate_x(dir: float, speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, dir * speed, data.acceleration * delta)


## 앞이 낭떠러지면 true (공중 유닛은 항상 false)
func is_at_edge() -> bool:
	if flying:
		return false
	var down: float = -1.0 if on_ceiling else 1.0
	var from := global_position + Vector2(facing * edge_check_ahead, -down * 4.0)
	var to := from + Vector2(0.0, down * edge_check_depth)
	var query := PhysicsRayQueryParameters2D.create(from, to, world_mask)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func is_blocked_ahead() -> bool:
	return is_on_wall() and signf(get_wall_normal().x) == -facing


# --- 피격 ---

func set_contact_enabled(enabled: bool) -> void:
	if contact_hitbox == null or contact_attack == null:
		return
	if enabled:
		contact_hitbox.activate_rect(contact_attack, contact_hitbox.position, contact_attack.hitbox_size, Vector2.ZERO)
	else:
		contact_hitbox.deactivate()


## 피격 경직에 빠질지. 하위 클래스가 재정의한다. (방패 정면 등)
func should_stagger(_hitbox: HitboxComponent) -> bool:
	return not super_armor and data.hurt_time > 0.0


func _on_hurt(hitbox: HitboxComponent, damage: int) -> void:
	hit_flash.flash()
	var color: Color = stunned_damage_color if stun.is_stunned() else damage_color
	DamageNumber.spawn(get_parent(), global_position + number_offset, str(damage), color)
	if health.is_dead() or stun.is_stunned():
		return
	if should_stagger(hitbox) and state_machine.has_state(&"Hurt"):
		state_machine.transition_to(&"Hurt")


func _on_died() -> void:
	state_machine.transition_to(&"Dead")


func _on_stunned(_duration: float) -> void:
	if not health.is_dead():
		state_machine.transition_to(&"Stunned")
