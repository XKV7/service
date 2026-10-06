class_name PartLevel
extends Resource
## 부품 한 레벨의 효과

## 이 레벨의 수정값
@export var modifiers: Array[StatModifier] = []
## 조건부 효과(PartEffect)가 쓰는 수치 (예: 처치 수, 공격력 증가량)
@export var effect_value: float = 0.0
## 보조 수치 (예: 회복량, 지속 시간)
@export var effect_value_2: float = 0.0
## 메뉴에 표시할 설명
@export var description: String = ""
