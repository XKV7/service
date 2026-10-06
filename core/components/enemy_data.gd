class_name EnemyData
extends Resource
## 적 한 종류의 기본 수치. 기준값은 GDD 11장을 따른다.

@export var id: StringName = &""
@export var display_name: String = ""
@export var max_hp: int = 30
## 기본 공격 피해 (표시용, 실제 피해는 각 AttackData)
@export var damage: int = 1
## 순찰 속도 (px/s)
@export var move_speed: float = 50.0
## 추격 속도 (px/s)
@export var chase_speed: float = 90.0
## 가속 (px/s²)
@export var acceleration: float = 900.0
## 플레이어 감지 거리 (px)
@export var detect_range: float = 180.0
## 감지 높이 차 허용 범위 (px)
@export var detect_height: float = 80.0
## 이 거리 안에 들어오면 공격한다 (px)
@export var attack_range: float = 40.0
## 처치 시 떨어뜨리는 데이터 양
@export var data_drop: int = 10
## 피격 경직 시간 (초)
@export var hurt_time: float = 0.2
