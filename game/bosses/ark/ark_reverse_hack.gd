extends BossPattern
## 역해킹. 몸이 녹색으로 빛난 뒤(예비동작) 주변의 ROOT에게 시스템 정지를 건다.
## 맞으면 잠시 이동 속도가 줄어든다. 대시로 범위 밖으로 빠져나가 피한다.

const DEBUFF_SOURCE: StringName = &"debuff:ark_reverse_hack"

@export var telegraph_time: float = 0.8
@export var radius: float = 130.0
@export var slow_mult: float = 0.5
@export var slow_time: float = 2.0
@export var recovery_time: float = 0.3
@export var glow_color: Color = Color(0.3, 1.0, 0.4, 1.0)
@export var ring_color: Color = Color(0.3, 1.0, 0.4, 0.35)
@export var flash_period: float = 0.08
## 범위 중심 (보스 발밑 기준)
@export var center_offset: Vector2 = Vector2(0, -22)

var _time: float = 0.0
var _released: bool = false
var _ring: Line2D

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	_released = false
	telegraphing = true
	_ring = Line2D.new()
	_ring.width = 2.0
	_ring.default_color = ring_color
	var points := PackedVector2Array()
	var segments: int = 32
	for i: int in segments + 1:
		points.append(Vector2.RIGHT.rotated(TAU * i / segments) * radius)
	_ring.points = points
	_ring.position = center_offset
	ark.add_child(_ring)


func _cleanup() -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()
	ark.visual.modulate = Color.WHITE


func cancel() -> void:
	super.cancel()
	_cleanup()


func physics_update(delta: float) -> void:
	_time += delta
	if not _released and _time >= telegraph_time:
		_released = true
		telegraphing = false
		_release()
	if _time >= telegraph_time + recovery_time:
		finish()


func update(_delta: float) -> void:
	if not _released:
		ark.visual.modulate = glow_color if int(_time / flash_period) % 2 == 0 else Color.WHITE
	else:
		ark.visual.modulate = Color.WHITE


func _release() -> void:
	var p := ark.get_target() as Player
	EventBus.screen_flash_requested.emit(Color(glow_color, 0.2), 0.2)
	if p == null or p.is_dead():
		return
	if p.global_position.distance_to(ark.global_position + center_offset) > radius:
		return
	if p.is_invulnerable and p.state_machine.get_state_name() == &"Dash":
		return
	p.add_timed_modifier(DEBUFF_SOURCE, [StatModifier.create(Player.STAT_MOVE_SPEED_MULT, StatModifier.Op.MULTIPLY, slow_mult)], slow_time)
	EventBus.toast_requested.emit("역해킹: 이동 속도 저하")
