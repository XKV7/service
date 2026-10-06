extends EnemyState
## 피격 경직. 넉백으로 밀려난 뒤 next_state로 돌아간다.

@export var next_state: StringName = &"Chase"

var _time: float = 0.0


func enter() -> void:
	_time = 0.0
	if enemy.attack_hitbox:
		enemy.attack_hitbox.deactivate()


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	_time += delta
	if _time >= enemy.data.hurt_time:
		transitioned.emit(self, next_state)
