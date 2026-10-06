class_name KnockbackComponent
extends Node
## 피격 방향으로 몸체를 밀어낸다. 감속은 몸체 쪽 이동 로직이 담당한다.

@export var body: CharacterBody2D
## 넉백 배율 (0이면 넉백 없음)
@export var knockback_mult: float = 1.0


func apply(direction: Vector2, force: float, up_force: float = 0.0) -> void:
	if body == null or knockback_mult <= 0.0:
		return
	if not is_zero_approx(direction.x):
		body.velocity.x = signf(direction.x) * force * knockback_mult
	if up_force > 0.0:
		body.velocity.y = -up_force * knockback_mult
