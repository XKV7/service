extends BossPattern
## 대시 베기. 예비동작 뒤 화면 반대편 끝까지 대시하며 벤다.

@export var attack: AttackData
@export var telegraph_time: float = 0.5
@export var dash_speed: float = 560.0
## 벽에서 이만큼 떨어진 곳에서 멈춘다 (px)
@export var edge_margin: float = 24.0
@export var recovery_time: float = 0.35
@export var telegraph_color: Color = Color(1.0, 0.4, 0.4, 1.0)
@export var flash_period: float = 0.07
@export var ghost_color: Color = Color(0.3, 1.0, 0.8, 0.5)

enum Phase { TELEGRAPH, DASH, RECOVERY }

var _phase: Phase = Phase.TELEGRAPH
var _time: float = 0.0
var _target_x: float = 0.0

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	ark.manual_motion = true
	ark.face_target()
	_phase = Phase.TELEGRAPH
	_time = 0.0
	telegraphing = true
	_target_x = ark.arena_right - edge_margin if ark.facing > 0.0 else ark.arena_left + edge_margin


func _cleanup() -> void:
	ark.manual_motion = false
	ark.attack_hitbox.deactivate()
	ark.visual.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_time += delta
	ark.apply_gravity(delta)
	match _phase:
		Phase.TELEGRAPH:
			ark.velocity.x = 0.0
			if _time >= telegraph_time:
				telegraphing = false
				_phase = Phase.DASH
				_time = 0.0
				ark.attack_hitbox.activate(attack, ark.facing)
		Phase.DASH:
			ark.velocity.x = ark.facing * dash_speed
			if (_target_x - ark.global_position.x) * ark.facing <= 0.0 or ark.is_on_wall():
				ark.velocity.x = 0.0
				ark.attack_hitbox.deactivate()
				_phase = Phase.RECOVERY
				_time = 0.0
		Phase.RECOVERY:
			ark.velocity.x = 0.0
			if _time >= recovery_time:
				finish()
	ark.move_and_slide()


func update(_delta: float) -> void:
	match _phase:
		Phase.TELEGRAPH:
			ark.visual.modulate = telegraph_color if int(_time / flash_period) % 2 == 0 else Color.WHITE
		Phase.DASH:
			ark.visual.modulate = ghost_color
		_:
			ark.visual.modulate = Color.WHITE
