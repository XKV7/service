extends PlayerState
## 낙하 상태. 코요테 타임 안에서는 점프할 수 있다.


func physics_update(delta: float) -> void:
	player.apply_horizontal(delta, player.movement.air_control)
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_dash() or try_jump():
		return
	if player.is_on_floor():
		go_grounded()
