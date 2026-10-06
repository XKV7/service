extends EnemyState
## 좌우 순찰. 벽이나 낭떠러지를 만나면 돌아선다. 플레이어를 발견하면 추격한다.

@export var chase_state: StringName = &"Chase"


func physics_update(delta: float) -> void:
	if enemy.is_blocked_ahead() or (enemy.is_on_floor() and enemy.is_at_edge()):
		enemy.facing = -enemy.facing
		enemy.velocity.x = 0.0
	enemy.accelerate_x(enemy.facing, enemy.data.move_speed, delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()

	if enemy.can_see_target():
		transitioned.emit(self, chase_state)
