class_name TrainBoss
extends Boss
## 보스 1. 폭주한 전동차. 선로를 따라 질주하고, 정차하면 운전석 코어가 열린다.
## 코어가 열려 있는 동안 코어는 피해를 2배로 받는다.

@export var track_y: float = 300.0
@export var arena_left: float = 0.0
@export var arena_right: float = 640.0
@export var park_x: float = 320.0
## 화면 밖으로 나갔다고 볼 거리 (px)
@export var offscreen_margin: float = 240.0
## 운전석 코어 위치 (차체 중심 기준, 앞쪽)
@export var core_offset: float = 86.0
@export var core_damage_mult: float = 2.0
@export var core_closed_color: Color = Color(0.3, 0.1, 0.15, 1.0)
@export var core_open_color: Color = Color(1.0, 0.3, 0.5, 1.0)

var core_open: bool = false

@onready var core_hurtbox: HurtboxComponent = %CoreHurtbox
@onready var rush_hitbox: HitboxComponent = %RushHitbox
@onready var core_rect: ColorRect = %CoreRect


func _ready() -> void:
	super._ready()
	core_hurtbox.damage_taken_mult = core_damage_mult
	set_core_open(false)
	brain.phase_changed.connect(func(_i: int) -> void: EventBus.toast_requested.emit("객차가 분리된다!"))


func _process(_delta: float) -> void:
	visual.scale.x = facing
	core_hurtbox.position.x = core_offset * facing


func set_core_open(open: bool) -> void:
	core_open = open
	core_hurtbox.set_deferred(&"monitorable", open)
	core_rect.color = core_open_color if open else core_closed_color


func is_offscreen() -> bool:
	return global_position.x < arena_left - offscreen_margin or global_position.x > arena_right + offscreen_margin


func park() -> void:
	global_position = Vector2(park_x, track_y)
	rush_hitbox.deactivate()
