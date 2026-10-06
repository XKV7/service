extends EnemyState
## 예비동작 → 공격(1회 또는 연속). 예비동작 동안 몸이 telegraph_color로 깜빡인다.
## 모든 보스·적 공격에는 예비동작이 있어야 한다. (GDD 12장)

@export var attacks: Array[AttackData] = []
## 예비동작 시간 (초)
@export var telegraph_time: float = 0.4
@export var telegraph_color: Color = Color(1.0, 0.85, 0.2, 1.0)
## 예비동작 깜빡임 주기 (초)
@export var telegraph_flash_period: float = 0.1
@export var next_state: StringName = &"Chase"
## 공격 시작 시 대상 쪽으로 돌아본다.
@export var track_target: bool = true

var _index: int = 0
var _time: float = 0.0
var _telegraphing: bool = true
var _hitbox_opened: bool = false


func enter() -> void:
	if track_target:
		enemy.face_target()
	_index = 0
	_time = 0.0
	_telegraphing = telegraph_time > 0.0
	_hitbox_opened = false
	enemy.visual_override = true


func exit() -> void:
	enemy.attack_hitbox.deactivate()
	enemy.visual_override = false


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_time += delta

	if _telegraphing:
		if _time >= telegraph_time:
			_telegraphing = false
			_start_attack(0)
		return

	var data: AttackData = attacks[_index]
	if not _hitbox_opened and _time >= data.startup:
		_hitbox_opened = true
		enemy.attack_hitbox.activate(data, enemy.facing)
	if enemy.attack_hitbox.active and _time >= data.startup + data.active:
		enemy.attack_hitbox.deactivate()
	if _time < data.get_total_time():
		return
	if _index + 1 < attacks.size():
		_start_attack(_index + 1)
	else:
		transitioned.emit(self, next_state)


func update(_delta: float) -> void:
	if _telegraphing:
		var on: bool = int(_time / telegraph_flash_period) % 2 == 0
		enemy.visual.modulate = telegraph_color if on else Color.WHITE
	else:
		enemy.visual.modulate = Color.WHITE


func _start_attack(index: int) -> void:
	_index = index
	_time = 0.0
	_hitbox_opened = false
	enemy.velocity.x = enemy.facing * attacks[index].lunge_speed
