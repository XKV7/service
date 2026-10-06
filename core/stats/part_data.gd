class_name PartData
extends Resource
## 장착형 부품 정의. 세이브에는 id로 저장한다.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
## 레벨별 효과. 0번이 Lv1
@export var levels: Array[PartLevel] = []
## 다음 레벨로 강화하는 비용. 0번이 Lv1→Lv2
@export var upgrade_costs: Array[int] = []
## 조건부 효과 스크립트 (PartEffect를 상속). 없으면 수정값만 적용한다.
@export var effect_script: Script
## 장착하지 않고 갖고만 있으면 효과가 나는 부품 (예: 슬롯 확장 모듈)
@export var passive_only: bool = false


func get_max_level() -> int:
	return maxi(levels.size(), 1)


func get_level(level: int) -> PartLevel:
	if levels.is_empty():
		return null
	return levels[clampi(level, 1, levels.size()) - 1]


## level에서 다음 레벨로 가는 비용. 최대 레벨이면 -1
func get_upgrade_cost(level: int) -> int:
	if level >= get_max_level() or level - 1 >= upgrade_costs.size():
		return -1
	return upgrade_costs[level - 1]
