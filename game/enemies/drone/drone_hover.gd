extends EnemyState
## 드론 이동. 플레이어 옆 위쪽의 일정 거리에 머무르다가 재사용 대기가 끝나면 조준한다.

@export var aim_state: StringName = &"Aim"
## 플레이어와 유지할 수평 거리 (px)
@export var preferred_distance: float = 130.0
## 플레이어보다 떠 있을 높이 (px)
@export var hover_height: float = 90.0
## 사격 재사용 대기 (초)
@export var shoot_cooldown: float = 1.6
## 위아래로 흔들리는 폭 (px)과 주기 (초)
@export var bob_amplitude: float = 4.0
@export var bob_period: float = 1.2

var _cooldown_left: float = 0.0
var _time: float = 0.0

var drone: Drone:
	get:
		return actor as Drone


func enter() -> void:
	_cooldown_left = shoot_cooldown


func physics_update(delta: float) -> void:
	_time += delta
	var goal: Vector2 = drone.home_position
	var sees: bool = drone.can_see_target()
	if sees:
		drone.face_target()
		var t: Node2D = drone.get_target()
		goal = t.global_position + Vector2(-drone.facing * preferred_distance, -hover_height)
	goal.y += sin(_time * TAU / bob_period) * bob_amplitude
	var desired: Vector2 = (goal - drone.global_position).limit_length(drone.data.move_speed)
	drone.velocity = drone.velocity.move_toward(desired, drone.data.acceleration * delta)
	drone.move_and_slide()

	_cooldown_left -= delta
	if sees and _cooldown_left <= 0.0:
		transitioned.emit(self, aim_state)
