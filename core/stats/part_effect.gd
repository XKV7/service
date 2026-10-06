class_name PartEffect
extends Node
## 부품의 조건부 효과 베이스. 장착하면 대상 아래에 노드로 붙고, 해제하면 사라진다.
## 하위 클래스는 _activate()에서 EventBus 시그널 등을 구독한다.

var part: PartData
var level: int = 1
## 효과를 받는 대상 (예: 플레이어)
var host: Node
var stats: StatSheet


func setup(part_data: PartData, part_level: int, target: Node, sheet: StatSheet) -> void:
	part = part_data
	level = part_level
	host = target
	stats = sheet


func _ready() -> void:
	_activate()


func _exit_tree() -> void:
	_deactivate()


func get_level_data() -> PartLevel:
	return part.get_level(level)


## 하위 클래스가 재정의한다.
func _activate() -> void:
	pass


## 하위 클래스가 재정의한다. 임시 수정값 등을 정리한다.
func _deactivate() -> void:
	pass
