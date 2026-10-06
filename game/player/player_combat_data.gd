class_name PlayerCombatData
extends Resource
## 플레이어 전투 공통 수치. 기준값은 GDD 6~7장을 따른다.

@export_group("연산력")
## 근접 공격이 맞을 때마다 얻는 연산력
@export var energy_per_hit: float = 8.0
## 근접 공격으로 적을 처치하면 추가로 얻는 연산력
@export var energy_per_kill: float = 15.0

@export_group("근접")
## 공격 입력을 기억하는 시간 (초). 콤보 이어가기에 사용한다.
@export var attack_buffer_time: float = 0.2
## 지상 공격 중 감속 (px/s²)
@export var attack_friction: float = 1800.0
## 아래 찍기
@export var down_attack: AttackData
## 아래 찍기가 맞았을 때 튀어 오르는 속도 = 점프 속도 × 이 값
@export var pogo_bounce_mult: float = 0.85
