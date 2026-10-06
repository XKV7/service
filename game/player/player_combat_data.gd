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

@export_group("피격")
## 피격 경직 시간 (초)
@export var hurt_time: float = 0.3
## 피격 중 감속 (px/s²). 작을수록 멀리 밀린다.
@export var hurt_friction: float = 500.0
@export var hurt_hitstop: float = 0.08
@export var hurt_shake: float = 0.45
## 피격 시 화면 가장자리 섬광
@export var hurt_flash_color: Color = Color(1.0, 0.2, 0.35, 0.3)
@export var hurt_flash_time: float = 0.15
## 무적 중 깜빡임 주기 (초)
@export var blink_period: float = 0.08
## 방패에 막혔을 때 뒤로 밀리는 속도 (px/s)
@export var blocked_recoil: float = 160.0
## 구덩이에 떨어졌을 때 피해
@export var pit_damage: int = 20

@export_group("사망")
## 파괴 후 재접속까지 (초)
@export var death_time: float = 1.5

@export_group("안전 지점")
## 안전 지점을 기록하는 간격 (초)
@export var safe_sample_interval: float = 0.1
## 기록해 둘 안전 지점 수. 되돌아갈 때는 가장 오래된 지점을 쓴다.
@export var safe_history_size: int = 5
