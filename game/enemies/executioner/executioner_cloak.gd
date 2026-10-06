extends EnemyState
## 한을 처형자 광학 위장. 사라졌다가 1초 뒤 플레이어 뒤에 나타난다.
## 나타나기 직전 일렁임(예비동작)이 보인다.

## 사라지는 시간 (초)
@export var fade_time: float = 0.3
## 완전히 사라져 있는 시간 (초)
@export var hidden_time: float = 0.7
## 나타나기 전 일렁임 시간 (초)
@export var shimmer_time: float = 0.4
@export var shimmer_color: Color = Color(0.7, 0.9, 1.0, 0.5)
@export var shimmer_flash_period: float = 0.06
## 플레이어 뒤 출현 거리 (px)
@export var behind_distance: float = 36.0
@export var next_state: StringName = &"Slash"

enum Phase { FADE, HIDDEN, SHIMMER }

var _phase: Phase = Phase.FADE
var _time: float = 0.0


func enter() -> void:
	_phase = Phase.FADE
	_time = 0.0
	enemy.visual_override = true
	enemy.set_contact_enabled(false)
	enemy.hurtbox.set_deferred(&"monitorable", false)


func exit() -> void:
	enemy.visual_override = false
	enemy.visual.modulate = Color.WHITE
	enemy.set_contact_enabled(true)
	enemy.hurtbox.set_deferred(&"monitorable", true)


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_time += delta
	match _phase:
		Phase.FADE:
			if _time >= fade_time:
				_phase = Phase.HIDDEN
				_time = 0.0
		Phase.HIDDEN:
			if _time >= hidden_time:
				_phase = Phase.SHIMMER
				_time = 0.0
				_reposition_behind()
				enemy.hurtbox.set_deferred(&"monitorable", true)
		Phase.SHIMMER:
			if _time >= shimmer_time:
				transitioned.emit(self, next_state)


func update(_delta: float) -> void:
	match _phase:
		Phase.FADE:
			enemy.visual.modulate = Color(1.0, 1.0, 1.0, clampf(1.0 - _time / fade_time, 0.0, 1.0))
		Phase.HIDDEN:
			enemy.visual.modulate = Color.TRANSPARENT
		Phase.SHIMMER:
			var on: bool = int(_time / shimmer_flash_period) % 2 == 0
			enemy.visual.modulate = shimmer_color if on else Color(1.0, 1.0, 1.0, shimmer_color.a * 0.5)


func _reposition_behind() -> void:
	var t: Node2D = enemy.get_target()
	if t == null:
		return
	var behind: float = -(t as Player).facing if t is Player else -enemy.direction_to_target()
	enemy.global_position = Vector2(t.global_position.x + behind * behind_distance, t.global_position.y)
	enemy.velocity = Vector2.ZERO
	enemy.face_target()
