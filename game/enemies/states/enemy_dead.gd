extends EnemyState
## 사망. 데이터를 떨어뜨리고 사라진다.

@export var fade_time: float = 0.4

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	enemy.visual_override = true
	if enemy.attack_hitbox:
		enemy.attack_hitbox.deactivate()
	enemy.set_contact_enabled(false)
	enemy.hurtbox.set_deferred(&"monitorable", false)
	DataPickup.spawn_burst(enemy.get_parent(), enemy.global_position + enemy.number_offset * 0.5, enemy.data.data_drop)
	EventBus.enemy_killed.emit(enemy)


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_time += delta
	if _time >= fade_time:
		enemy.queue_free()


func update(_delta: float) -> void:
	enemy.visual.modulate = Color(1.0, 1.0, 1.0, clampf(1.0 - _time / fade_time, 0.0, 1.0))
