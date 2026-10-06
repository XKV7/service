class_name Player
extends CharacterBody2D
## 플레이어(ROOT의 원격 의체). 이동 로직의 공통 부분과 입력 타이머를 담당한다.
## 상태별 동작은 StateMachine 아래의 PlayerState들이 처리한다.

@export var movement: PlayerMovementData

## 바라보는 방향. 1.0 = 오른쪽, -1.0 = 왼쪽
var facing: float = 1.0
## 무적 여부. M2에서 HealthComponent가 참조한다.
var is_invulnerable: bool:
	get:
		return _invuln_timer > 0.0
## 입력 잠금 (컷신 등)
var input_locked: bool = false

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _invuln_timer: float = 0.0
var _air_dashes_left: int = 0

@onready var state_machine: StateMachine = %StateMachine
@onready var visual: Node2D = %Visual


func _ready() -> void:
	assert(movement != null, "Player: movement 데이터가 지정되지 않았다.")
	_air_dashes_left = movement.air_dash_count


func _physics_process(delta: float) -> void:
	# 부모의 _physics_process는 자식(StateMachine)보다 먼저 실행된다.
	# 따라서 여기서 갱신한 타이머를 이번 프레임의 상태가 그대로 사용한다.
	_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)

	if is_on_floor():
		_coyote_timer = movement.coyote_time
		_air_dashes_left = movement.air_dash_count

	if not input_locked and Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = movement.jump_buffer_time


func _process(_delta: float) -> void:
	visual.scale.x = facing


# --- 입력 ---

func get_input_direction() -> float:
	if input_locked:
		return 0.0
	return Input.get_axis("move_left", "move_right")


func is_jump_held() -> bool:
	return not input_locked and Input.is_action_pressed("jump")


func is_dash_pressed() -> bool:
	return not input_locked and Input.is_action_just_pressed("dash")


# --- 이동 공통 ---

## 입력 방향으로 가속/감속한다. speed_scale은 레일건 충전 등 감속에 사용한다.
func apply_horizontal(delta: float, control: float = 1.0, speed_scale: float = 1.0) -> void:
	var dir: float = get_input_direction()
	var target_speed: float = dir * movement.move_speed * speed_scale
	var rate: float
	if is_zero_approx(dir):
		rate = movement.move_speed / movement.decel_time
	else:
		rate = movement.move_speed / movement.accel_time
		facing = signf(dir)
	velocity.x = move_toward(velocity.x, target_speed, rate * control * delta)


func apply_gravity(delta: float) -> void:
	var mult: float = movement.fall_gravity_mult if velocity.y > 0.0 else 1.0
	velocity.y = minf(velocity.y + movement.gravity * mult * delta, movement.max_fall_speed)


# --- 점프 ---

## 점프 입력이 버퍼에 있고, 바닥이거나 코요테 시간 안이면 true
func can_jump() -> bool:
	return _jump_buffer_timer > 0.0 and (is_on_floor() or _coyote_timer > 0.0)


func consume_jump() -> void:
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0


# --- 대시 ---

func can_dash() -> bool:
	if _dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or _air_dashes_left > 0


func consume_dash() -> void:
	_dash_cooldown_timer = movement.dash_cooldown
	_invuln_timer = maxf(_invuln_timer, movement.dash_invuln_time)
	if not is_on_floor():
		_air_dashes_left -= 1


func get_dash_cooldown_left() -> float:
	return _dash_cooldown_timer
