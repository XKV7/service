extends BossPattern
## 레일건 저격. 공중으로 뛰어올라 1초 충전하며 조준선을 보여준 뒤 발사한다.

@export var attack: AttackData
@export var jump_velocity: float = -420.0
@export var charge_time: float = 1.0
## 발사 직전 조준이 고정되는 시간 (초)
@export var lock_time: float = 0.25
@export var beam_length: float = 800.0
@export var beam_width: float = 6.0
@export var beam_color: Color = Color(0.3, 1.0, 0.8, 1.0)
@export var aim_color: Color = Color(0.3, 1.0, 0.8, 0.45)
@export var locked_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var aim_offset: Vector2 = Vector2(0, -22)
@export var muzzle_offset: Vector2 = Vector2(0, -28)

enum Phase { RISE, CHARGE, FALL }

var _phase: Phase = Phase.RISE
var _time: float = 0.0
var _aim_point: Vector2

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	ark.manual_motion = true
	ark.velocity = Vector2(0.0, jump_velocity)
	_phase = Phase.RISE
	_time = 0.0


func _cleanup() -> void:
	ark.manual_motion = false
	ark.aim_line.visible = false


func cancel() -> void:
	super.cancel()
	ark.aim_line.visible = false


func physics_update(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.RISE:
			ark.apply_gravity(delta)
			if ark.velocity.y >= 0.0:
				ark.velocity = Vector2.ZERO
				_phase = Phase.CHARGE
				_time = 0.0
				telegraphing = true
				ark.aim_line.visible = true
		Phase.CHARGE:
			ark.velocity = Vector2.ZERO
			if _time < charge_time - lock_time:
				_update_aim()
			if _time >= charge_time:
				telegraphing = false
				ark.aim_line.visible = false
				_fire()
				_phase = Phase.FALL
				_time = 0.0
		Phase.FALL:
			ark.apply_gravity(delta)
			if ark.is_on_floor():
				finish()
	ark.move_and_slide()


func update(_delta: float) -> void:
	if _phase != Phase.CHARGE:
		return
	ark.aim_line.points = PackedVector2Array([muzzle_offset, ark.to_local(_aim_point)])
	ark.aim_line.default_color = locked_color if _time >= charge_time - lock_time else aim_color


func _update_aim() -> void:
	var t: Node2D = ark.get_target()
	if t:
		_aim_point = t.global_position + aim_offset
		ark.face_target()


func _fire() -> void:
	var beam := LaserBeam.new()
	level().add_child(beam)
	var origin: Vector2 = ark.global_position + muzzle_offset
	beam.fire(origin, _aim_point - origin, attack, beam_length, beam_width, 2, 1, beam_color, 16)
	EventBus.screen_shake_requested.emit(attack.shake)
