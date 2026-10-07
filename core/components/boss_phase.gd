class_name BossPhase
extends Resource
## 보스 페이즈 하나. 체력 비율이 hp_ratio 이하가 되면 이 페이즈로 넘어간다.

## 이 페이즈가 시작되는 체력 비율 (첫 페이즈는 1.0)
@export_range(0.0, 1.0) var hp_ratio: float = 1.0
## 고를 수 있는 패턴(상태 이름)
@export var patterns: Array[StringName] = []
## 패턴별 가중치. 비어 있거나 개수가 다르면 모두 1로 본다.
@export var weights: Array[float] = []
## 패턴 사이 대기 시간 (초)
@export var idle_time: float = 1.0
