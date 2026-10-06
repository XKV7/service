class_name HealthComponent
extends Node
## 체력 관리. 피격 후 무적 시간을 포함한다.

signal damaged(amount: int)
signal healed(amount: int)
signal died
signal health_changed(current: int, maximum: int)

@export var max_hp: int = 100
## 피해를 받은 뒤 무적 시간 (초)
@export var invuln_time: float = 0.0

var hp: int = 0

var _invuln_left: float = 0.0


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	_invuln_left = maxf(_invuln_left - delta, 0.0)


func is_dead() -> bool:
	return hp <= 0


func is_invulnerable() -> bool:
	return _invuln_left > 0.0


## 무적 시간을 최소 seconds만큼 보장한다. (대시 무적 등)
func add_invulnerability(seconds: float) -> void:
	_invuln_left = maxf(_invuln_left, seconds)


## 피해를 적용하고 실제로 들어간 피해량을 반환한다. 무적이거나 죽어 있으면 0.
func take_damage(amount: int) -> int:
	if amount <= 0 or is_dead() or is_invulnerable():
		return 0
	hp = maxi(hp - amount, 0)
	_invuln_left = invuln_time
	damaged.emit(amount)
	health_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()
	return amount


func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	var before: int = hp
	hp = mini(hp + amount, max_hp)
	if hp != before:
		healed.emit(hp - before)
		health_changed.emit(hp, max_hp)


## 최대 체력을 바꾼다. 현재 체력은 새 최대치를 넘지 않게 줄인다.
func set_max_hp(value: int) -> void:
	max_hp = maxi(value, 1)
	hp = mini(hp, max_hp)
	health_changed.emit(hp, max_hp)


## 체력을 최대로 되돌린다. (부활, 중계기)
func reset() -> void:
	hp = max_hp
	_invuln_left = 0.0
	health_changed.emit(hp, max_hp)
