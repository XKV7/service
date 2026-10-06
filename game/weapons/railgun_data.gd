class_name RailgunData
extends Resource
## 차지 레일건 수치. 기준값은 GDD 7장을 따른다.

@export var attack: AttackData
## 발사에 필요한 최소 충전 시간 (초)
@export var charge_time: float = 0.8
## 발사 시 소모하는 연산력
@export var energy_cost: float = 25.0
## 충전 중 이동 속도 배율
@export var move_speed_mult: float = 0.4
## 빔 최대 길이 (px). 지형에 막히면 그 앞까지만 나간다.
@export var max_length: float = 480.0
## 빔 두께 (px)
@export var beam_width: float = 8.0
## 발사 반동 속도 (px/s)
@export var recoil_speed: float = 160.0
## 발사 후 다시 움직일 수 있을 때까지 (초)
@export var fire_recovery: float = 0.2
## 발사 위치 (바라보는 방향 기준, px)
@export var muzzle_offset: Vector2 = Vector2(12, -28)
## 빔이 맞출 수 있는 레이어 (enemy + hologram)
@export_flags_2d_physics var target_mask: int = 260
## 빔을 막는 지형 레이어
@export_flags_2d_physics var world_mask: int = 1
@export var beam_color: Color = Color(0.0, 1.0, 0.9, 1.0)
## 발사 순간 화면 섬광
@export var flash_color: Color = Color(0.7, 1.0, 1.0, 0.35)
@export var flash_time: float = 0.12
