extends PlayerState
## 의체 파괴. 서서히 사라진 뒤 재접속한다.

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	player.hitbox.deactivate()
	player.pending_safe_return = false
	EventBus.player_died.emit()


func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.combat.hurt_friction * delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	_time += delta
	if _time >= player.combat.death_time:
		player.revive()


func update(_delta: float) -> void:
	player.visual.modulate.a = clampf(1.0 - _time / player.combat.death_time, 0.0, 1.0)
