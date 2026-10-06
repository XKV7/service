class_name StateMachine
extends Node
## 자식 State 노드들을 관리하는 범용 상태머신.
## 상태 이름은 자식 노드 이름을 그대로 사용한다.

signal state_changed(old_state: StringName, new_state: StringName)

@export var initial_state: State
## 상태들이 조종할 대상. 비워두면 씬 루트(owner)를 사용한다.
@export var actor: Node

var current_state: State
var _states: Dictionary = {}


func _ready() -> void:
	if actor == null:
		actor = owner
	for child: Node in get_children():
		if child is State:
			var state := child as State
			state.actor = actor
			state.transitioned.connect(_on_state_transitioned)
			_states[StringName(state.name)] = state
	# 액터의 _ready가 끝난 뒤에 첫 상태에 진입한다.
	_enter_initial_state.call_deferred()


func _enter_initial_state() -> void:
	if initial_state == null:
		push_error("StateMachine '%s': initial_state가 지정되지 않았다." % get_path())
		return
	current_state = initial_state
	current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


## 외부(부모)에서 강제로 상태를 바꿀 때 사용한다. (예: 피격, 사망)
func transition_to(state_name: StringName) -> void:
	var next: State = _states.get(state_name) as State
	if next == null:
		push_error("StateMachine '%s': '%s' 상태가 없다." % [get_path(), state_name])
		return
	var old_name: StringName = StringName(current_state.name) if current_state else &""
	if current_state:
		current_state.exit()
	current_state = next
	current_state.enter()
	state_changed.emit(old_name, state_name)


func get_state_name() -> StringName:
	return StringName(current_state.name) if current_state else &""


func has_state(state_name: StringName) -> bool:
	return _states.has(state_name)


func _on_state_transitioned(state: State, new_state_name: StringName) -> void:
	# 이미 다른 상태로 넘어간 뒤 늦게 도착한 요청은 무시한다.
	if state != current_state:
		return
	transition_to(new_state_name)
