class_name HurtboxComponent
extends Area2D
## 피격 판정. Hitbox가 겹치면 피해를 계산해 HealthComponent에 전달하고,
## 공격자 쪽 Hitbox에 hit_landed를 알린다.

signal hurt(hitbox: HitboxComponent, damage: int)

@export var health: HealthComponent
## 있으면 정지 중 피해 배율을 적용한다.
@export var stun: StunComponent
## 있으면 피격 시 넉백을 적용한다.
@export var knockback: KnockbackComponent


func _ready() -> void:
	monitoring = false
	monitorable = true


## 피해가 들어갔으면 true
func receive_hit(hitbox: HitboxComponent) -> bool:
	if health == null or hitbox.attack_data == null:
		return false
	if health.is_dead() or health.is_invulnerable():
		return false
	var mult: float = hitbox.damage_mult
	if stun:
		mult *= stun.get_damage_taken_mult()
	var damage: int = maxi(roundi(hitbox.attack_data.damage * mult), 1)
	var applied: int = health.take_damage(damage)
	if applied <= 0:
		return false
	if knockback:
		knockback.apply(hitbox.direction, hitbox.attack_data.knockback, hitbox.attack_data.knockback_up)
	var killed: bool = health.is_dead()
	hurt.emit(hitbox, applied)
	hitbox.notify_hit(self, applied, killed)
	return true
