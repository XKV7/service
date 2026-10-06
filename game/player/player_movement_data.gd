class_name PlayerMovementData
extends Resource
## 플레이어 이동 수치. 기준값은 GDD 6장을 따른다.

@export_group("달리기")
## 최대 이동 속도 (px/s)
@export var move_speed: float = 190.0
## 정지 상태에서 최대 속도까지 걸리는 시간 (초)
@export var accel_time: float = 0.08
## 최대 속도에서 정지까지 걸리는 시간 (초)
@export var decel_time: float = 0.06
## 공중에서의 가속 비율 (1.0 = 지상과 동일)
@export var air_control: float = 0.8

@export_group("점프")
## 점프 시작 속도 (px/s, 위쪽이 음수)
@export var jump_velocity: float = -400.0
## 중력 가속도 (px/s²)
@export var gravity: float = 1000.0
## 낙하 중 중력 배율
@export var fall_gravity_mult: float = 1.6
## 최대 낙하 속도 (px/s)
@export var max_fall_speed: float = 620.0
## 점프 키를 일찍 떼면 상승 속도에 곱하는 값 (가변 점프 높이)
@export var jump_cut_mult: float = 0.45
## 발판에서 떨어진 뒤에도 점프를 허용하는 시간 (초)
@export var coyote_time: float = 0.1
## 착지 전에 누른 점프를 기억하는 시간 (초)
@export var jump_buffer_time: float = 0.1

@export_group("대시")
## 대시 이동 거리 (px)
@export var dash_distance: float = 100.0
## 대시 지속 시간 (초)
@export var dash_duration: float = 0.2
## 대시 무적 시간 (초)
@export var dash_invuln_time: float = 0.16
## 대시 쿨다운 (초)
@export var dash_cooldown: float = 0.5
## 공중에서 쓸 수 있는 대시 횟수 (착지 시 초기화)
@export var air_dash_count: int = 1
## 대시 종료 시 남기는 수평 속도 비율 (move_speed 기준)
@export var dash_exit_speed_mult: float = 1.0
