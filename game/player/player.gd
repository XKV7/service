class_name Player
extends CharacterBody2D
## 플레이어(ROOT의 원격 의체). 이동 로직의 공통 부분과 입력 타이머를 담당한다.
## 상태별 동작은 StateMachine 아래의 PlayerState들이 처리한다.

@export var movement: PlayerMovementData
@export var combat: PlayerCombatData
@export var weapon: WeaponData
@export var railgun: RailgunData
@export var hack: HackData

## 스탯 이름. 부품(StatModifier)은 이 이름으로 수치를 바꾼다.
const STAT_MAX_HP: StringName = &"max_hp"
const STAT_HURT_INVULN: StringName = &"hurt_invuln"
const STAT_DASH_COOLDOWN: StringName = &"dash_cooldown"
const STAT_ATTACK_MULT: StringName = &"attack_mult"
const STAT_DAMAGE_TAKEN_MULT: StringName = &"damage_taken_mult"
const STAT_ENERGY_PER_HIT: StringName = &"energy_per_hit"
const STAT_RAILGUN_CHARGE_TIME: StringName = &"railgun_charge_time"
const STAT_RAILGUN_DAMAGE: StringName = &"railgun_damage"
const STAT_HACK_STUN_DURATION: StringName = &"hack_stun_duration"
const STAT_HACK_REACH: StringName = &"hack_reach"
const STAT_KNOCKBACK_TAKEN_MULT: StringName = &"knockback_taken_mult"
const STAT_HURT_TIME_MULT: StringName = &"hurt_time_mult"
const STAT_DATA_GAIN_MULT: StringName = &"data_gain_mult"
const SKILL_RAILGUN: StringName = &"railgun"
const SKILL_HACK: StringName = &"hack"

## 바라보는 방향. 1.0 = 오른쪽, -1.0 = 왼쪽
var facing: float = 1.0
## 무적 여부 (피격 무적 + 대시 무적)
var is_invulnerable: bool:
	get:
		return health.is_invulnerable()
## 입력 잠금 (컷신 등)
var input_locked: bool = false
## 파괴되었을 때 재접속하는 위치. 레벨(이후 중계기)이 정한다.
var respawn_position: Vector2
## 피격 시 안전 지점으로 되돌려야 하는지 (Hurt 상태가 처리)
var pending_safe_return: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _attack_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _air_dashes_left: int = 0
var _blink_left: float = 0.0
var _safe_sample_timer: float = 0.0
var _safe_history: Array[Vector2] = []

@onready var state_machine: StateMachine = %StateMachine
@onready var visual: Node2D = %Visual
@onready var health: HealthComponent = %Health
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var energy: ResourceGaugeComponent = %Energy
@onready var hitbox: HitboxComponent = %Hitbox
@onready var charge_bar: Node2D = %ChargeBar
@onready var hit_flash: HitFlash = %HitFlash
@onready var stats: StatSheet = %Stats
@onready var knockback: KnockbackComponent = %Knockback
@onready var interact_sensor: Area2D = %InteractSensor


func _ready() -> void:
	assert(movement != null and combat != null and weapon != null, "Player: 데이터가 지정되지 않았다.")
	add_to_group(&"player")
	_init_stats()
	_air_dashes_left = movement.air_dash_count
	respawn_position = global_position
	hitbox.hit_landed.connect(_on_melee_hit_landed)
	hitbox.hit_blocked.connect(_on_melee_blocked)
	hurtbox.hurt.connect(_on_hurt)


func _physics_process(delta: float) -> void:
	# 부모의 _physics_process는 자식(StateMachine)보다 먼저 실행된다.
	# 따라서 여기서 갱신한 타이머를 이번 프레임의 상태가 그대로 사용한다.
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_attack_buffer_timer = maxf(_attack_buffer_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)

	_blink_left = maxf(_blink_left - delta, 0.0)
	if is_on_floor():
		_coyote_timer = movement.coyote_time
		_air_dashes_left = movement.air_dash_count
	_sample_safe_point(delta)

	if input_locked:
		return
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = movement.jump_buffer_time
	if Input.is_action_just_pressed("attack"):
		_attack_buffer_timer = combat.attack_buffer_time
	if Input.is_action_just_pressed("menu") and not is_dead():
		EventBus.body_menu_requested.emit(false)


func _process(_delta: float) -> void:
	visual.scale.x = facing
	if _blink_left > 0.0:
		var on: bool = int(_blink_left / combat.blink_period) % 2 == 0
		visual.modulate.a = 1.0 if on else 0.3
	elif not is_dead():
		visual.modulate.a = 1.0


# --- 입력 ---

func get_input_direction() -> float:
	if input_locked:
		return 0.0
	return Input.get_axis("move_left", "move_right")


func is_down_held() -> bool:
	return not input_locked and Input.is_action_pressed("move_down")


func is_jump_held() -> bool:
	return not input_locked and Input.is_action_pressed("jump")


func is_dash_pressed() -> bool:
	return not input_locked and Input.is_action_just_pressed("dash")


func is_fire_pressed() -> bool:
	return not input_locked and Input.is_action_just_pressed("fire")


func is_fire_held() -> bool:
	return not input_locked and Input.is_action_pressed("fire")


func is_hack_pressed() -> bool:
	return not input_locked and Input.is_action_just_pressed("hack")


func is_interact_pressed() -> bool:
	return not input_locked and Input.is_action_just_pressed("interact")


## 버퍼에 공격 입력이 있으면 소모하고 true
func consume_attack() -> bool:
	if _attack_buffer_timer > 0.0:
		_attack_buffer_timer = 0.0
		return true
	return false


# --- 이동 공통 ---

## 입력 방향으로 가속/감속한다. speed_scale은 레일건 충전 등 감속에 사용한다.
func apply_horizontal(delta: float, control: float = 1.0, speed_scale: float = 1.0) -> void:
	var dir: float = get_input_direction()
	var target_speed: float = dir * movement.move_speed * speed_scale
	var rate: float
	if is_zero_approx(dir):
		rate = movement.move_speed / movement.decel_time
	else:
		rate = movement.move_speed / movement.accel_time
		facing = signf(dir)
	velocity.x = move_toward(velocity.x, target_speed, rate * control * delta)


## 입력과 상관없이 수평 속도를 줄인다. (공격·시전 중)
func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, combat.attack_friction * delta)


func apply_gravity(delta: float) -> void:
	var mult: float = movement.fall_gravity_mult if velocity.y > 0.0 else 1.0
	velocity.y = minf(velocity.y + movement.gravity * mult * delta, movement.max_fall_speed)


## 입력 방향이 있으면 그쪽을 바라본다. (콤보 사이 방향 전환)
func face_input() -> void:
	var dir: float = get_input_direction()
	if not is_zero_approx(dir):
		facing = signf(dir)


# --- 점프 ---

## 점프 입력이 버퍼에 있고, 바닥이거나 코요테 시간 안이면 true
func can_jump() -> bool:
	return _jump_buffer_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)


func consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


## 아래 찍기 성공 시 튀어 오른다. 공중 대시도 다시 쓸 수 있다.
func pogo_bounce() -> void:
	velocity.y = movement.jump_velocity * combat.pogo_bounce_mult
	_air_dashes_left = movement.air_dash_count


# --- 대시 ---

func can_dash() -> bool:
	if _dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or _air_dashes_left > 0


func consume_dash() -> void:
	_dash_cooldown_timer = stats.get_value(STAT_DASH_COOLDOWN)
	health.add_invulnerability(movement.dash_invuln_time)
	if not is_on_floor():
		_air_dashes_left -= 1


func get_dash_cooldown_left() -> float:
	return _dash_cooldown_timer


# --- 전투 ---

func can_fire() -> bool:
	return railgun != null and GameState.has_skill(SKILL_RAILGUN)


func can_hack() -> bool:
	return hack != null and GameState.has_skill(SKILL_HACK) and energy.can_spend(hack.energy_cost)


## 레일건 피해 배율 (기본 피해 대비 부품 보너스 × 공격력 배율)
func get_railgun_damage_mult() -> float:
	var base: float = float(railgun.attack.damage)
	return stats.get_value(STAT_RAILGUN_DAMAGE) / base * stats.get_value(STAT_ATTACK_MULT)


func heal(amount: int) -> void:
	health.heal(amount)


## 데이터를 얻는다. 부품의 획득 배율이 적용된다.
func collect_data(amount: int) -> void:
	GameState.add_data(roundi(amount * stats.get_value(STAT_DATA_GAIN_MULT)))


## 범위 안의 상호작용 대상 중 가장 가까운 것. 없으면 null
func find_interactable() -> InteractableComponent:
	var best: InteractableComponent = null
	var best_dist: float = INF
	for area: Area2D in interact_sensor.get_overlapping_areas():
		var target := area as InteractableComponent
		if target == null or not target.enabled:
			continue
		var dist: float = global_position.distance_to(target.global_position)
		if dist < best_dist:
			best = target
			best_dist = dist
	return best


func _on_melee_hit_landed(hurtbox_hit: HurtboxComponent, damage: int, killed: bool) -> void:
	var gain: float = stats.get_value(STAT_ENERGY_PER_HIT)
	if killed:
		gain += combat.energy_per_kill
	energy.add(gain)
	var data: AttackData = hitbox.attack_data
	HitStop.trigger(get_tree(), data.hitstop)
	EventBus.screen_shake_requested.emit(data.shake)
	EventBus.hit_landed.emit(hurtbox_hit.owner, damage)


func _on_melee_blocked(_hurtbox: HurtboxComponent) -> void:
	velocity.x = -facing * combat.blocked_recoil
	HitStop.trigger(get_tree(), hitbox.attack_data.hitstop)


# --- 피격·사망 ---

func is_dead() -> bool:
	return health.is_dead()


func _on_hurt(hit_by: HitboxComponent, _damage: int) -> void:
	hit_flash.flash()
	HitStop.trigger(get_tree(), combat.hurt_hitstop)
	EventBus.screen_shake_requested.emit(combat.hurt_shake)
	EventBus.screen_flash_requested.emit(combat.hurt_flash_color, combat.hurt_flash_time)
	if is_dead():
		state_machine.transition_to(&"Dead")
		return
	_blink_left = health.invuln_time
	pending_safe_return = hit_by.attack_data.sends_to_safe_point
	if get_hurt_time() > 0.0:
		state_machine.transition_to(&"Hurt")
	elif pending_safe_return:
		pending_safe_return = false
		return_to_safe_point()


## 피격 경직 시간 (부품으로 0이 될 수 있다)
func get_hurt_time() -> float:
	return combat.hurt_time * stats.get_value(STAT_HURT_TIME_MULT)


## 의체 잔해가 남을 위치. 공중(구덩이 등)에서 파괴되면 마지막 안전 지점에 남는다.
func get_wreck_position() -> Vector2:
	if is_on_floor() or _safe_history.is_empty():
		return global_position
	return _safe_history.back()


## 환경 피해 (구덩이 낙하 등). 히트박스 없이 피해를 주고 안전 지점으로 되돌린다.
func take_environment_damage(amount: int) -> void:
	var applied: int = health.take_damage(amount)
	if applied > 0 and is_dead():
		hit_flash.flash()
		state_machine.transition_to(&"Dead")
		return
	if applied > 0:
		_blink_left = health.invuln_time
		hit_flash.flash()
		EventBus.screen_flash_requested.emit(combat.hurt_flash_color, combat.hurt_flash_time)
	return_to_safe_point()


func return_to_safe_point() -> void:
	if not _safe_history.is_empty():
		global_position = _safe_history[0]
	velocity = Vector2.ZERO


## 재접속: 예비 의체로 다시 시작한다.
func revive() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	health.reset()
	_safe_history.clear()
	_blink_left = 0.0
	visual.modulate = Color.WHITE
	state_machine.transition_to(&"Idle")
	EventBus.player_respawned.emit()


# --- 스탯 ---

func _init_stats() -> void:
	stats.set_base(STAT_MAX_HP, health.max_hp)
	stats.set_base(STAT_HURT_INVULN, health.invuln_time)
	stats.set_base(STAT_DASH_COOLDOWN, movement.dash_cooldown)
	stats.set_base(STAT_ATTACK_MULT, 1.0)
	stats.set_base(STAT_DAMAGE_TAKEN_MULT, 1.0)
	stats.set_base(STAT_ENERGY_PER_HIT, combat.energy_per_hit)
	stats.set_base(STAT_RAILGUN_CHARGE_TIME, railgun.charge_time)
	stats.set_base(STAT_RAILGUN_DAMAGE, railgun.attack.damage)
	stats.set_base(STAT_HACK_STUN_DURATION, hack.stun_duration)
	stats.set_base(STAT_HACK_REACH, hack.reach)
	stats.set_base(STAT_KNOCKBACK_TAKEN_MULT, 1.0)
	stats.set_base(STAT_HURT_TIME_MULT, 1.0)
	stats.set_base(STAT_DATA_GAIN_MULT, 1.0)
	stats.stats_changed.connect(_apply_stats)
	_apply_stats()


## 스탯을 각 컴포넌트에 반영한다.
func _apply_stats() -> void:
	health.set_max_hp(roundi(stats.get_value(STAT_MAX_HP)))
	health.invuln_time = stats.get_value(STAT_HURT_INVULN)
	hitbox.damage_mult = stats.get_value(STAT_ATTACK_MULT)
	hurtbox.damage_taken_mult = stats.get_value(STAT_DAMAGE_TAKEN_MULT)
	knockback.knockback_mult = stats.get_value(STAT_KNOCKBACK_TAKEN_MULT)


func _sample_safe_point(delta: float) -> void:
	_safe_sample_timer -= delta
	if _safe_sample_timer > 0.0:
		return
	_safe_sample_timer = combat.safe_sample_interval
	if not is_on_floor() or not _is_on_safe_ground():
		return
	_safe_history.append(global_position)
	if _safe_history.size() > combat.safe_history_size:
		_safe_history.pop_front()


## 무너지는 발판처럼 "unsafe_ground" 그룹 위에 서 있으면 false
func _is_on_safe_ground() -> bool:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is Node and (collider as Node).is_in_group(&"unsafe_ground"):
			return false
	return true
