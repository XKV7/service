class_name ResourceGaugeComponent
extends Node
## 범용 게이지 (연산력, 마나 등). 자연 회복은 하지 않는다.

signal value_changed(current: float, maximum: float)

@export var max_value: float = 100.0
@export var initial_value: float = 0.0

var value: float = 0.0


func _ready() -> void:
	value = clampf(initial_value, 0.0, max_value)


func add(amount: float) -> void:
	set_value(value + amount)


func can_spend(amount: float) -> bool:
	return value >= amount


## 충분하면 소모하고 true, 부족하면 아무것도 하지 않고 false
func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false
	set_value(value - amount)
	return true


func set_value(new_value: float) -> void:
	var clamped: float = clampf(new_value, 0.0, max_value)
	if is_equal_approx(clamped, value):
		return
	value = clamped
	value_changed.emit(value, max_value)


func get_ratio() -> float:
	return value / max_value if max_value > 0.0 else 0.0
