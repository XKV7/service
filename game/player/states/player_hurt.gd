extends PlayerState
## 피격 경직. 넉백으로 밀려나는 동안 조작할 수 없다.

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	player.hitbox.deactivate()


func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.combat.hurt_friction * delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	_time += delta
	if _time < player.combat.hurt_time:
		return
	if player.pending_safe_return:
		player.pending_safe_return = false
		player.return_to_safe_point()
	go_neutral()
