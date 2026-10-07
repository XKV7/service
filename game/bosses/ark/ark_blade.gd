extends BossPattern
## 블레이드 3연타. 다가와서 예비동작 뒤 3번 벤다. 마지막 타가 크다.

@export var attacks: Array[AttackData] = []
@export var approach_speed: float = 170.0
## 이 거리까지 다가간다 (px)
@export var approach_range: float = 40.0
@export var approach_max_time: float = 1.2
@export var telegraph_time: float = 0.35
@export var telegraph_color: Color = Color(0.5, 1.0, 0.8, 1.0)
@export var flash_period: float = 0.07

enum Phase { APPROACH, TELEGRAPH, ATTACK }

var _phase: Phase = Phase.APPROACH
var _time: float = 0.0
var _index: int = 0
var _opened: bool = false

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	ark.manual_motion = true
	_phase = Phase.APPROACH
	_time = 0.0


func _cleanup() -> void:
	ark.manual_motion = false
	ark.attack_hitbox.deactivate()
	ark.visual.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_time += delta
	ark.apply_gravity(delta)
	match _phase:
		Phase.APPROACH:
			ark.face_target()
			var t: Node2D = ark.get_target()
			var dist: float = absf(t.global_position.x - ark.global_position.x) if t else 0.0
			ark.velocity.x = ark.facing * approach_speed
			if dist <= approach_range or _time >= approach_max_time:
				ark.velocity.x = 0.0
				_phase = Phase.TELEGRAPH
				_time = 0.0
				telegraphing = true
		Phase.TELEGRAPH:
			ark.velocity.x = move_toward(ark.velocity.x, 0.0, ark.friction * delta)
			if _time >= telegraph_time:
				telegraphing = false
				_start_attack(0)
		Phase.ATTACK:
			ark.velocity.x = move_toward(ark.velocity.x, 0.0, ark.friction * delta)
			var data: AttackData = attacks[_index]
			if not _opened and _time >= data.startup:
				_opened = true
				ark.attack_hitbox.activate(data, ark.facing)
			if ark.attack_hitbox.active and _time >= data.startup + data.active:
				ark.attack_hitbox.deactivate()
			if _time >= data.get_total_time():
				if _index + 1 < attacks.size():
					_start_attack(_index + 1)
				else:
					finish()
	ark.move_and_slide()


func update(_delta: float) -> void:
	if _phase == Phase.TELEGRAPH:
		ark.visual.modulate = telegraph_color if int(_time / flash_period) % 2 == 0 else Color.WHITE
	else:
		ark.visual.modulate = Color.WHITE


func _start_attack(index: int) -> void:
	_phase = Phase.ATTACK
	_index = index
	_time = 0.0
	_opened = false
	ark.velocity.x = ark.facing * attacks[index].lunge_speed
