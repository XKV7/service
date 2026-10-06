class_name Crawler
extends Enemy
## 선로 크롤러. 바닥이나 천장을 기어 다닌다. 천장에 있으면 아래를 지나가는 플레이어 위로 떨어진다.

## 이 수평 거리 안으로 플레이어가 아래를 지나가면 떨어진다 (px)
@export var drop_range: float = 40.0
@export var drop_state: StringName = &"Chase"


func _physics_process(_delta: float) -> void:
	if not on_ceiling or health.is_dead() or stun.is_stunned():
		return
	var t: Node2D = get_target()
	if t and has_live_target() and t.global_position.y > global_position.y and horizontal_distance_to_target() <= drop_range:
		drop_from_ceiling()


func drop_from_ceiling() -> void:
	on_ceiling = false
	up_direction = Vector2.UP
	visual.scale.y = 1.0
	velocity = Vector2.ZERO
	state_machine.transition_to(drop_state)
