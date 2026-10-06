extends PlayerState
## 상승 상태. 점프 키를 일찍 떼면 상승 속도를 줄여 낮게 뛴다.

var _cut_applied: bool = false


func enter() -> void:
	player.consume_jump()
	player.velocity.y = player.movement.jump_velocity
	_cut_applied = false


func physics_update(delta: float) -> void:
	if not _cut_applied and not player.is_jump_held():
		player.velocity.y *= player.movement.jump_cut_mult
		_cut_applied = true

	player.apply_horizontal(delta, player.movement.air_control)
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_actions():
		return
	if player.is_on_floor():
		go_grounded()
	elif player.velocity.y >= 0.0:
		transitioned.emit(self, &"Fall")
