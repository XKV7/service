extends EnemyState
## 추격. 공격 거리에 들어오면 attack_state, 중거리면 alt_attack_state(있으면)로 간다.
## 놓치면 lost_state로 돌아간다.

@export var attack_state: StringName = &"Attack"
@export var lost_state: StringName = &"Patrol"
## 중거리 공격 (비우면 없음)
@export var alt_attack_state: StringName = &""
@export var alt_min_range: float = 80.0
@export var alt_max_range: float = 200.0
## 중거리 공격 재사용 대기 (초)
@export var alt_cooldown: float = 3.0
## 놓쳤다고 판단하는 거리 배율 (감지 거리 기준)
@export var lose_range_mult: float = 1.5
## 공격 재사용 대기 (초). 공격이 끝나고 다시 이 상태로 올 때 적용된다.
@export var attack_cooldown: float = 0.4

var _alt_cooldown_left: float = 0.0
var _attack_cooldown_left: float = 0.0


func enter() -> void:
	_attack_cooldown_left = attack_cooldown


func physics_update(delta: float) -> void:
	_alt_cooldown_left = maxf(_alt_cooldown_left - delta, 0.0)
	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	enemy.face_target()
	var dist: float = enemy.horizontal_distance_to_target()
	var should_stop: bool = dist <= enemy.data.attack_range * 0.8 or (enemy.is_on_floor() and enemy.is_at_edge())
	enemy.accelerate_x(0.0 if should_stop else enemy.facing, enemy.data.chase_speed, delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	if not enemy.can_see_target(lose_range_mult):
		transitioned.emit(self, lost_state)
		return
	if _attack_cooldown_left > 0.0:
		return
	if dist <= enemy.data.attack_range:
		transitioned.emit(self, attack_state)
	elif alt_attack_state != &"" and _alt_cooldown_left <= 0.0 and dist >= alt_min_range and dist <= alt_max_range:
		_alt_cooldown_left = alt_cooldown
		transitioned.emit(self, alt_attack_state)
