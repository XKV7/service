class_name WeaponData
extends Resource
## 근접 무기 정의. 세이브에는 id로 저장한다.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## 콤보 순서대로의 공격. 공중 공격은 첫 번째 공격을 사용한다.
@export var combo: Array[AttackData] = []
## 표시용 사거리 (px)
@export var attack_range: float = 44.0
## 무기 고유 효과 id (예: 마지막 타 끌어당김). 비어 있으면 없음.
@export var special_effect: StringName = &""
