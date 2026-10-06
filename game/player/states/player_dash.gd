extends PlayerState
## 수평 대시. 지속 시간 동안 중력을 무시하고 일정 속도로 이동한다.

## 부동소수점 누적 오차로 한 프레임 더 대시하는 것을 막는 여유값 (초)
const TIME_EPSILON: float = 0.0001

## 잔상 색 (GDD: 청록색)
@export var ghost_color: Color = Color(0.0, 1.0, 0.9, 0.6)
## 잔상 생성 간격 (초)
@export var ghost_interval: float = 0.03
## 잔상이 사라지는 시간 (초)
@export var ghost_fade_time: float = 0.2

var _time_left: float = 0.0
var _direction: float = 1.0
var _ghost_timer: float = 0.0


func enter() -> void:
	# 입력 방향이 있으면 그쪽으로, 없으면 바라보는 방향으로 대시한다.
	var input_dir: float = player.get_input_direction()
	if not is_zero_approx(input_dir):
		player.facing = signf(input_dir)
	_direction = player.facing
	player.consume_dash()
	_time_left = player.movement.dash_duration
	_ghost_timer = 0.0
	EventBus.player_dashed.emit(_direction)


func exit() -> void:
	var exit_speed: float = player.movement.move_speed * player.movement.dash_exit_speed_mult
	player.velocity.x = clampf(player.velocity.x, -exit_speed, exit_speed)


func physics_update(delta: float) -> void:
	var dash_speed: float = player.movement.dash_distance / player.movement.dash_duration
	player.velocity = Vector2(_direction * dash_speed, 0.0)
	player.move_and_slide()

	_time_left -= delta
	if _time_left > TIME_EPSILON:
		return
	if player.is_on_floor():
		if not try_jump():
			go_grounded()
	else:
		if not try_jump():
			transitioned.emit(self, &"Fall")


func update(delta: float) -> void:
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = ghost_interval
		_spawn_ghost()


func _spawn_ghost() -> void:
	var ghost: Node2D = player.visual.duplicate() as Node2D
	ghost.unique_name_in_owner = false
	ghost.modulate = ghost_color
	ghost.global_position = player.visual.global_position
	ghost.scale = player.visual.global_scale
	ghost.z_index = player.z_index - 1
	player.get_parent().add_child(ghost)
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, ghost_fade_time)
	tween.tween_callback(ghost.queue_free)
