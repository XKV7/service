class_name Riot
extends Enemy
## 진압 요원. 정면 방패로 근접 공격을 막는다. 시스템 정지 중에는 방패를 쓰지 못한다.


func _ready() -> void:
	super._ready()
	hurtbox.block_check = _is_blocked


func _is_blocked(hitbox: HitboxComponent) -> bool:
	return not stun.is_stunned() and not health.is_dead() and _is_from_front(hitbox)


## 방패 정면에서 맞으면 (레일건 관통 포함) 경직하지 않는다.
func should_stagger(hitbox: HitboxComponent) -> bool:
	return super.should_stagger(hitbox) and not _is_from_front(hitbox)


func _is_from_front(hitbox: HitboxComponent) -> bool:
	# 위에서 찍는 공격은 방패로 막지 못한다.
	if is_zero_approx(hitbox.direction.x) and not is_zero_approx(hitbox.direction.y):
		return false
	var attacker: Node2D = hitbox.owner as Node2D if hitbox.owner is Node2D else hitbox
	var side: float = signf(attacker.global_position.x - global_position.x)
	if side == 0.0:
		side = -signf(hitbox.direction.x)
	return side == facing
