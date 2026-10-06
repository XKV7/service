class_name StatSheet
extends Node
## 기본 수치 + 출처별 수정값 목록으로 최종 수치를 계산한다.
## 부품을 장착·해제할 때는 그 출처의 수정값만 추가·제거한다.

signal stats_changed

var _base: Dictionary = {}
## 출처 id -> Array[StatModifier]
var _sources: Dictionary = {}


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	stats_changed.emit()


func get_base(stat: StringName) -> float:
	return _base.get(stat, 0.0)


func get_value(stat: StringName) -> float:
	var add: float = 0.0
	var mult: float = 1.0
	for mods: Array in _sources.values():
		for mod: StatModifier in mods:
			if mod.stat != stat:
				continue
			if mod.op == StatModifier.Op.ADD:
				add += mod.value
			else:
				mult *= mod.value
	return (get_base(stat) + add) * mult


## source의 수정값을 통째로 바꾼다. (같은 출처를 다시 넣으면 덮어쓴다)
func set_source(source: StringName, modifiers: Array) -> void:
	if modifiers.is_empty():
		remove_source(source)
		return
	_sources[source] = modifiers.duplicate()
	stats_changed.emit()


func add_modifier(source: StringName, modifier: StatModifier) -> void:
	if not _sources.has(source):
		_sources[source] = []
	(_sources[source] as Array).append(modifier)
	stats_changed.emit()


func remove_source(source: StringName) -> void:
	if _sources.erase(source):
		stats_changed.emit()


func has_source(source: StringName) -> bool:
	return _sources.has(source)


func get_sources() -> Array:
	return _sources.keys()
