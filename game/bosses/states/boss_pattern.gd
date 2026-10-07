class_name BossPattern
extends State
## 보스 공격 패턴 하나. 끝나면 finish()로 Idle에 돌아간다.
## 예비동작 동안 telegraphing을 true로 두면 해킹으로 취소할 수 있다.

## 예비동작 중인지 (해킹하면 이 공격이 취소된다)
var telegraphing: bool = false
## 패턴이 만든 노드 (취소할 때 예고 중인 것을 지운다)
var _spawned: Array[Node] = []

var boss: Boss:
	get:
		return actor as Boss


func exit() -> void:
	telegraphing = false
	_cleanup()


## 해킹으로 취소될 때 호출된다. 하위 클래스가 정리할 것이 있으면 재정의한다.
func cancel() -> void:
	telegraphing = false
	for node: Node in _spawned:
		if is_instance_valid(node) and node is HazardZone and (node as HazardZone).is_warning():
			node.queue_free()
	_spawned.clear()


func finish() -> void:
	telegraphing = false
	transitioned.emit(self, &"Idle")


## 패턴이 끝날 때 정리. 하위 클래스가 재정의한다.
func _cleanup() -> void:
	pass


func track(node: Node) -> Node:
	_spawned.append(node)
	return node


## 보스가 있는 레벨 (위험 지대 등을 붙일 곳)
func level() -> Node:
	return boss.get_parent()
