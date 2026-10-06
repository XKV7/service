extends EnemyState
## 크롤러 도약 공격. 웅크렸다가(예비동작) 대상 쪽으로 튀어 오른다. 피해는 접촉 판정이 준다.

@export var telegraph_time: float = 0.3
@export var telegraph_color: Color = Color(1.0, 0.85, 0.2, 1.0)
## 웅크릴 때 세로 크기 배율
@export var crouch_scale: float = 0.6
@export var leap_speed_x: float = 220.0
@export var leap_speed_y: float = -260.0
@export var recovery_time: float = 0.35
## 도약 직후 착지 판정을 무시하는 시간 (초)
@export var takeoff_grace: float = 0.1
@export var next_state: StringName = &"Chase"

enum Phase { CROUCH, LEAP, RECOVERY }

var _phase: Phase = Phase.CROUCH
var _time: float = 0.0


func enter() -> void:
	enemy.face_target()
	_phase = Phase.CROUCH
	_time = 0.0
	enemy.visual_override = true


func exit() -> void:
	enemy.visual.scale.y = 1.0
	enemy.visual_override = false


func physics_update(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.CROUCH:
			enemy.apply_friction(delta)
			if _time >= telegraph_time:
				_phase = Phase.LEAP
				_time = 0.0
				enemy.velocity = Vector2(enemy.facing * leap_speed_x, leap_speed_y)
		Phase.LEAP:
			if _time >= takeoff_grace and enemy.is_on_floor():
				_phase = Phase.RECOVERY
				_time = 0.0
		Phase.RECOVERY:
			enemy.apply_friction(delta)
			if _time >= recovery_time:
				transitioned.emit(self, next_state)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()


func update(_delta: float) -> void:
	var crouching: bool = _phase == Phase.CROUCH
	enemy.visual.scale.y = crouch_scale if crouching else 1.0
	enemy.visual.modulate = telegraph_color if crouching else Color.WHITE
