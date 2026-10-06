class_name HurtboxComponent
extends Area2D
## 피격 판정. Hitbox가 겹치면 피해를 계산해 HealthComponent에 전달하고,
## 공격자 쪽 Hitbox에 hit_landed를 알린다.
## health가 없으면 "단단한 대상"으로 취급해 hit_solid만 알린다. (함정 등)

signal hurt(hitbox: HitboxComponent, damage: int)
signal blocked(hitbox: HitboxComponent)

@export var health: HealthComponent
## 있으면 정지 중 피해 배율을 적용한다.
@export var stun: StunComponent
## 있으면 피격 시 넉백을 적용한다.
@export var knockback: KnockbackComponent

## 막기 판정. (hitbox: HitboxComponent) -> bool. true를 반환하면 피해 없이 막는다.
var block_check: Callable
## 받는 피해 배율 (부품 효과 등)
var damage_taken_mult: float = 1.0


func _ready() -> void:
	monitoring = false
	monitorable = true


## 피해가 들어갔으면 true
func receive_hit(hitbox: HitboxComponent) -> bool:
	if hitbox.attack_data == null:
		return false
	if health == null:
		hitbox.notify_solid(self)
		return false
	if health.is_dead() or health.is_invulnerable():
		return false
	if not hitbox.attack_data.pierces_guard and block_check.is_valid() and block_check.call(hitbox):
		blocked.emit(hitbox)
		hitbox.notify_blocked(self)
		return false
	var mult: float = hitbox.damage_mult * damage_taken_mult
	if stun:
		mult *= stun.get_damage_taken_mult()
	var damage: int = maxi(roundi(hitbox.attack_data.damage * mult), 1)
	var applied: int = health.take_damage(damage)
	if applied <= 0:
		return false
	if knockback:
		knockback.apply(get_knockback_direction(hitbox), hitbox.attack_data.knockback, hitbox.attack_data.knockback_up)
	var killed: bool = health.is_dead()
	hurt.emit(hitbox, applied)
	hitbox.notify_hit(self, applied, killed)
	return true


## 공격 방향이 없으면(접촉 피해 등) 공격자에게서 멀어지는 방향을 쓴다.
func get_knockback_direction(hitbox: HitboxComponent) -> Vector2:
	if hitbox.direction != Vector2.ZERO:
		return hitbox.direction
	var away: float = signf(global_position.x - hitbox.global_position.x)
	return Vector2(away if away != 0.0 else 1.0, 0.0)
