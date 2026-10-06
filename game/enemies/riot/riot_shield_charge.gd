extends EnemyState
## 방패 돌진. 예비동작 뒤 빠르게 돌진하고, 끝나면 한동안 빈틈이 생긴다.

@export var attack: AttackData
@export var telegraph_time: float = 0.6
@export var telegraph_color: Color = Color(1.0, 0.5, 0.2, 1.0)
@export var telegraph_flash_period: float = 0.1
## 돌진 속도 (px/s)
@export var charge_speed: float = 300.0
## 최대 돌진 시간 (초)
@export var charge_time: float = 0.8
## 돌진 후 빈틈 (초)
@export var recovery_time: float = 0.8
@export var next_state: StringName = &"Chase"

enum Phase { TELEGRAPH, CHARGE, RECOVERY }

var _phase: Phase = Phase.TELEGRAPH
var _time: float = 0.0


func enter() -> void:
	enemy.face_target()
	_phase = Phase.TELEGRAPH
	_time = 0.0
	enemy.visual_override = true


func exit() -> void:
	enemy.attack_hitbox.deactivate()
	enemy.visual_override = false


func physics_update(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.TELEGRAPH:
			enemy.apply_friction(delta)
			if _time >= telegraph_time:
				_phase = Phase.CHARGE
				_time = 0.0
				enemy.attack_hitbox.activate(attack, enemy.facing)
		Phase.CHARGE:
			enemy.velocity.x = enemy.facing * charge_speed
			if _time >= charge_time or enemy.is_blocked_ahead() or (enemy.is_on_floor() and enemy.is_at_edge()):
				_phase = Phase.RECOVERY
				_time = 0.0
				enemy.velocity.x = 0.0
				enemy.attack_hitbox.deactivate()
		Phase.RECOVERY:
			enemy.apply_friction(delta)
			if _time >= recovery_time:
				transitioned.emit(self, next_state)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()


func update(_delta: float) -> void:
	if _phase == Phase.TELEGRAPH:
		var on: bool = int(_time / telegraph_flash_period) % 2 == 0
		enemy.visual.modulate = telegraph_color if on else Color.WHITE
	else:
		enemy.visual.modulate = Color.WHITE
