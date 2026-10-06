class_name HackData
extends Resource
## 해킹: 시스템 정지 수치. 기준값은 GDD 7장을 따른다.

## 소모 연산력
@export var energy_cost: float = 50.0
## 시전 시간 (초). 이 동안 빈틈이 있다.
@export var cast_time: float = 0.3
## 발동 후 다시 움직일 수 있을 때까지 (초)
@export var recovery: float = 0.15
## 전방 범위 (px)
@export var reach: float = 160.0
## 범위 높이 (px)
@export var height: float = 96.0
## 범위 중심 높이 (발밑 기준, px)
@export var center_y: float = -24.0
## 일반 적 정지 시간 (초). 보스는 StunComponent.max_duration으로 제한한다.
@export var stun_duration: float = 2.0
## 정지시킬 수 있는 레이어 (enemy + hologram + hazard)
@export_flags_2d_physics var target_mask: int = 388
@export var effect_color: Color = Color(0.0, 1.0, 0.9, 0.5)
@export var flash_color: Color = Color(0.0, 1.0, 0.9, 0.18)
@export var flash_time: float = 0.2
