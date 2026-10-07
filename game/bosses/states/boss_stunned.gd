extends State
## 해킹 경직. 정지가 풀리면 Idle로 돌아간다.

@export var stun_color: Color = Color(0.4, 1.0, 1.0, 1.0)

var boss: Boss:
	get:
		return actor as Boss


func exit() -> void:
	boss.visual.modulate = Color.WHITE


func physics_update(_delta: float) -> void:
	if not boss.stun.is_stunned():
		transitioned.emit(self, &"Idle")


func update(_delta: float) -> void:
	boss.visual.modulate = stun_color
