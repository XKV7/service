class_name AttackData
extends Resource
## 공격 한 번의 수치. 근접 콤보 한 타, 레일건 빔 등 모든 공격에 사용한다.

## 기본 피해량
@export var damage: int = 10
## 입력 후 판정이 나오기까지의 시간 (초)
@export var startup: float = 0.05
## 판정이 유지되는 시간 (초)
@export var active: float = 0.1
## 판정이 끝난 뒤 다음 행동까지의 시간 (초)
@export var recovery: float = 0.15
## 공격 시작 시 앞으로 밀고 나가는 속도 (px/s)
@export var lunge_speed: float = 0.0

@export_group("판정")
## 판정 사각형 크기 (px)
@export var hitbox_size: Vector2 = Vector2(44, 36)
## 판정 중심 위치. x는 바라보는 방향 기준 (px)
@export var hitbox_offset: Vector2 = Vector2(31, -24)

@export_group("피격 반응")
## 맞은 대상을 수평으로 밀어내는 속도 (px/s)
@export var knockback: float = 120.0
## 맞은 대상을 위로 띄우는 속도 (px/s)
@export var knockback_up: float = 0.0
## 히트스톱 시간 (초)
@export var hitstop: float = 0.05
## 화면 흔들림 세기 (0~1)
@export var shake: float = 0.2

@export_group("특수")
## 방패 등 막기 판정을 무시한다. (레일건)
@export var pierces_guard: bool = false
## 맞은 대상을 마지막 안전 지점으로 되돌린다. (레이저 보안망)
@export var sends_to_safe_point: bool = false


func get_total_time() -> float:
	return startup + active + recovery
