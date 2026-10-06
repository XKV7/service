class_name LaserGrid
extends Node2D
## 레이저 보안망. 닿으면 피해를 주고 마지막 안전 지점으로 되돌린다.
## 시스템 정지를 맞으면 일정 시간 꺼진다. 노드 위치가 레이저 위쪽 끝(가운데)이다.

@export var attack: AttackData
## 레이저 길이 (아래로, px)
@export var length: float = 180.0
@export var width: float = 6.0
## 시스템 정지로 꺼지는 시간 (초)
@export var disable_time: float = 3.0
@export var beam_color: Color = Color(1.0, 0.2, 0.35, 0.85)
@export var disabled_color: Color = Color(1.0, 0.2, 0.35, 0.12)
@export var emitter_color: Color = Color(0.85, 0.85, 0.95, 1.0)
@export var emitter_size: Vector2 = Vector2(16, 10)
## 꺼지기 직전 깜빡임 시작 (남은 초)
@export var warn_time: float = 0.6
@export var warn_flash_period: float = 0.08
@export_flags_2d_physics var hazard_layer: int = 128
@export_flags_2d_physics var target_mask: int = 2

var _beam: ColorRect
var _hitbox: HitboxComponent
var _stun: StunComponent


func _ready() -> void:
	_beam = ColorRect.new()
	_beam.size = Vector2(width, length)
	_beam.position = Vector2(-width * 0.5, 0.0)
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_beam)
	for y: float in [-emitter_size.y, length]:
		var emitter := ColorRect.new()
		emitter.size = emitter_size
		emitter.position = Vector2(-emitter_size.x * 0.5, y)
		emitter.color = emitter_color
		emitter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(emitter)

	var center := Vector2(0.0, length * 0.5)
	var size := Vector2(width, length)
	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = hazard_layer
	_hitbox.collision_mask = target_mask
	_hitbox.continuous = true
	_hitbox.draw_color = Color.TRANSPARENT
	add_child(_hitbox)
	_hitbox.activate_rect(attack, center, size, Vector2.ZERO)

	# 시스템 정지를 받는 판정 (체력 없음)
	_stun = StunComponent.new()
	_stun.duration_override = disable_time
	add_child(_stun)
	var hack_target := HurtboxComponent.new()
	hack_target.collision_layer = hazard_layer
	hack_target.collision_mask = 0
	hack_target.stun = _stun
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = center
	hack_target.add_child(col)
	add_child(hack_target)


func is_disabled() -> bool:
	return _stun.is_stunned()


func _physics_process(_delta: float) -> void:
	if is_disabled() and _hitbox.active:
		_hitbox.deactivate()
	elif not is_disabled() and not _hitbox.active:
		_hitbox.activate_rect(attack, _hitbox.position, Vector2(width, length), Vector2.ZERO)
	if _hitbox.active:
		_block_invulnerable_player()


## 무적(피격 직후, 대시) 상태로는 통과할 수 없다. 피해 없이 안전 지점으로 되돌린다.
func _block_invulnerable_player() -> void:
	for area: Area2D in _hitbox.get_overlapping_areas():
		var p := area.owner as Player
		if p and p.is_invulnerable and not p.is_dead() and not p.pending_safe_return:
			p.return_to_safe_point()


func _process(_delta: float) -> void:
	if not is_disabled():
		_beam.color = beam_color
		return
	var left: float = _stun.get_time_left()
	if left <= warn_time and int(left / warn_flash_period) % 2 == 0:
		_beam.color = beam_color
	else:
		_beam.color = disabled_color
