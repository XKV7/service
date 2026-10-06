class_name StatModifier
extends Resource
## 스탯 하나를 바꾸는 수정값. 최종 수치 = (기본값 + 덧셈 합) × 곱셈 값들의 곱

enum Op { ADD, MULTIPLY }

@export var stat: StringName = &""
@export var op: Op = Op.ADD
@export var value: float = 0.0


static func create(stat_name: StringName, operation: Op, amount: float) -> StatModifier:
	var mod := StatModifier.new()
	mod.stat = stat_name
	mod.op = operation
	mod.value = amount
	return mod
