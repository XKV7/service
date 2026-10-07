class_name Boss
extends CharacterBody2D
## 보스 공통 베이스. 패턴은 StateMachine의 BossPattern 상태들이, 패턴 선택은 BossBrain이 맡는다.
## 공통 상태 이름: Dormant(시작 전), Idle(다음 패턴 대기), Stunned(해킹 경직), Defeated(처치)
## 해킹: 예비동작 중이면 그 공격을 취소하고 경직, 공격 중이면 경직 시간 동안 멈춘다.

@export var boss_id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 600
@export_group("보상")
@export var data_reward: int = 0
@export var reward_parts: Array[StringName] = []
@export var reward_skills: Array[StringName] = []
## 처치 연출 대사 (줄바꿈마다 알림 한 개)
@export_multiline var defeat_lines: String = ""
@export_group("연출")
@export var defeat_hitstop: float = 0.3
@export var defeat_shake: float = 0.8
@export var number_offset: Vector2 = Vector2(0, -60)
@export var damage_color: Color = Color.WHITE
@export var stunned_damage_color: Color = Color(0.0, 1.0, 0.9, 1.0)

## 바라보는 방향. 1 = 오른쪽
var facing: float = -1.0

var _hurtboxes: Array[HurtboxComponent] = []
var _frozen: bool = false
var _target: Node2D

@onready var visual: Node2D = %Visual
@onready var health: HealthComponent = %Health
@onready var stun: StunComponent = %Stun
@onready var hit_flash: HitFlash = %HitFlash
@onready var state_machine: StateMachine = %StateMachine
@onready var brain: BossBrain = %Brain


func _ready() -> void:
	add_to_group(&"boss")
	health.max_hp = max_hp
	health.reset()
	for node: Node in find_children("*", "HurtboxComponent", true, false):
		var hurtbox := node as HurtboxComponent
		_hurtboxes.append(hurtbox)
		hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)
	stun.stunned.connect(_on_stunned)
	stun.recovered.connect(_unfreeze)


## 보스전을 시작한다. (아레나가 호출)
func start() -> void:
	if state_machine.get_state_name() != &"Dormant":
		return
	state_machine.transition_to(&"Idle")
	EventBus.boss_started.emit(self)


func is_defeated() -> bool:
	return health.is_dead()


func current_pattern() -> BossPattern:
	return state_machine.current_state as BossPattern


# --- 대상 ---

func get_target() -> Node2D:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(&"player") as Node2D
	return _target


func has_live_target() -> bool:
	var t: Node2D = get_target()
	return t != null and not (t is Player and (t as Player).is_dead())


func direction_to_target() -> float:
	var t: Node2D = get_target()
	if t == null:
		return facing
	var dir: float = signf(t.global_position.x - global_position.x)
	return dir if dir != 0.0 else facing


func face_target() -> void:
	facing = direction_to_target()


func set_hurtboxes_enabled(enabled: bool) -> void:
	for hurtbox: HurtboxComponent in _hurtboxes:
		hurtbox.set_deferred(&"monitorable", enabled)


# --- 피격·해킹·처치 ---

func _on_hurt(_hitbox: HitboxComponent, damage: int) -> void:
	hit_flash.flash()
	var color: Color = stunned_damage_color if stun.is_stunned() else damage_color
	DamageNumber.spawn(get_parent(), global_position + number_offset, str(damage), color)


func _on_stunned(_duration: float) -> void:
	if is_defeated():
		return
	var pattern: BossPattern = current_pattern()
	var state: StringName = state_machine.get_state_name()
	if pattern and pattern.telegraphing:
		pattern.cancel()
		EventBus.toast_requested.emit("공격 취소")
		state_machine.transition_to(&"Stunned")
	elif state == &"Idle":
		state_machine.transition_to(&"Stunned")
	elif pattern:
		# 공격 중에는 경직 시간 동안 멈추기만 한다.
		_frozen = true
		state_machine.process_mode = Node.PROCESS_MODE_DISABLED


func _unfreeze() -> void:
	if _frozen:
		_frozen = false
		state_machine.process_mode = Node.PROCESS_MODE_INHERIT


func _on_died() -> void:
	_unfreeze()
	state_machine.transition_to(&"Defeated")


## 처치 보상을 준다. (Defeated 상태가 호출)
func grant_rewards() -> void:
	GameState.defeat_boss(boss_id)
	for skill: StringName in reward_skills:
		GameState.unlock_skill(skill)
		EventBus.toast_requested.emit("스킬 해금: " + String(ItemPickup.SKILL_NAMES.get(skill, skill)))
	for part: StringName in reward_parts:
		if GameState.acquire_part(part):
			EventBus.toast_requested.emit("부품 획득: " + GameState.get_part(part).display_name)
	DataPickup.spawn_burst(get_parent(), global_position + number_offset * 0.5, data_reward)
