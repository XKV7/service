extends PlayerState
## 지상 이동 상태


func physics_update(delta: float) -> void:
	player.apply_horizontal(delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_dash() or try_jump():
		return
	if not player.is_on_floor():
		transitioned.emit(self, &"Fall")
	elif is_zero_approx(player.get_input_direction()):
		transitioned.emit(self, &"Idle")
