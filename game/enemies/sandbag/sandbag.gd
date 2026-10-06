class_name Sandbag
extends CharacterBody2D
## 전투 테스트용 샌드백. 맞으면 번쩍이고 밀려나며 피해 숫자를 띄운다.
## 쓰러지면 잠시 뒤 다시 일어난다. 홀로그램 설정이면 근접 공격이 통과한다.

## 중력 적용 여부 (끄면 공중에 떠 있는 샌드백)
@export var use_gravity: bool = true
## 홀로그램이면 hologram 레이어에만 피격 판정이 있다. (레일건·시스템 정지로만 피해)
@export var hologram: bool = false
@export var gravity: float = 1000.0
@export var max_fall_speed: float = 620.0
## 넉백 후 멈추는 감속 (px/s²)
@export var friction: float = 900.0
## 공중 샌드백이 원래 자리로 돌아가는 속도 (px/s)
@export var return_speed: float = 120.0
## 쓰러진 뒤 다시 일어나기까지 (초)
@export var respawn_time: float = 1.2

@export_group("레이어")
@export_flags_2d_physics var enemy_layer: int = 4
@export_flags_2d_physics var hologram_layer: int = 256

@export_group("색")
@export var body_color: Color = Color(0.85, 0.55, 0.25, 1.0)
@export var hologram_color: Color = Color(1.0, 0.3, 0.8, 0.6)
@export var dead_alpha: float = 0.25
@export var damage_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## 정지 중 피해 숫자 색 (피해 증가 표시)
@export var stunned_damage_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var stun_glitch_color: Color = Color(0.4, 1.0, 1.0, 1.0)
## 정지 중 깜빡임 주기 (초)
@export var stun_flicker_period: float = 0.08
## 피해 숫자가 뜨는 위치 (발밑 기준)
@export var number_offset: Vector2 = Vector2(0, -56)

var _home_position: Vector2
var _respawn_left: float = 0.0

@onready var visual: Node2D = %Visual
@onready var body_rect: ColorRect = %BodyRect
@onready var health: HealthComponent = %Health
@onready var hurtbox: HurtboxComponent = %Hurtbox
@onready var stun: StunComponent = %Stun
@onready var hit_flash: HitFlash = %HitFlash
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	_home_position = global_position
	hurtbox.collision_layer = hologram_layer if hologram else enemy_layer
	body_rect.color = hologram_color if hologram else body_color
	hurtbox.hurt.connect(_on_hurt)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _respawn_left > 0.0:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_respawn()

	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if use_gravity:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	else:
		velocity.y = move_toward(velocity.y, 0.0, friction * delta)
		if is_zero_approx(velocity.x) and is_zero_approx(velocity.y):
			global_position = global_position.move_toward(_home_position, return_speed * delta)
	move_and_slide()


func _process(_delta: float) -> void:
	status_label.text = "%d/%d" % [health.hp, health.max_hp]
	if stun.is_stunned():
		status_label.text += " 정지 %.1f" % stun.get_time_left()
		var flicker_on: bool = int(Time.get_ticks_msec() / (stun_flicker_period * 1000.0)) % 2 == 0
		visual.modulate = stun_glitch_color if flicker_on else Color.WHITE
	elif _respawn_left <= 0.0:
		visual.modulate = Color.WHITE


func _on_hurt(_hitbox: HitboxComponent, damage: int) -> void:
	hit_flash.flash()
	var color: Color = stunned_damage_color if stun.is_stunned() else damage_color
	DamageNumber.spawn(get_parent(), global_position + number_offset, str(damage), color)


func _on_died() -> void:
	EventBus.enemy_killed.emit(self)
	visual.modulate.a = dead_alpha
	_respawn_left = respawn_time


func _respawn() -> void:
	health.reset()
	visual.modulate = Color.WHITE
	if not use_gravity:
		global_position = _home_position
