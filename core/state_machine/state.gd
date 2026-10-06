class_name State
extends Node
## 상태머신의 상태 하나. 상속해서 필요한 함수만 재정의한다.
## 다른 상태로 넘어가려면 transitioned.emit(self, "StateName")을 호출한다.

@warning_ignore("unused_signal")
signal transitioned(state: State, new_state_name: StringName)

## 이 상태가 조종하는 대상. StateMachine이 채워 준다.
var actor: Node


func enter() -> void:
	pass


func exit() -> void:
	pass


## 시각 효과용. _process에서 호출된다.
func update(_delta: float) -> void:
	pass


## 물리 로직용. _physics_process에서 호출된다.
func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
