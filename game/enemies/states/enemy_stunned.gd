extends EnemyState
## 시스템 정지. 정지가 풀릴 때까지 아무것도 하지 않는다. 접촉 피해도 없다.

@export var next_state: StringName = &"Chase"


func enter() -> void:
	if enemy.attack_hitbox:
		enemy.attack_hitbox.deactivate()
	enemy.set_contact_enabled(false)


func exit() -> void:
	enemy.set_contact_enabled(true)


func physics_update(delta: float) -> void:
	enemy.apply_friction(delta)
	enemy.apply_gravity(delta)
	enemy.move_and_slide()
	if not enemy.stun.is_stunned():
		transitioned.emit(self, next_state)
