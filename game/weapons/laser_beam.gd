class_name LaserBeam
extends Node2D
## 즉시 판정 레이저(레일건, 드론 레이저 등). 지형에 막히는 지점까지 관통 판정을 만들고
## 잠깐 보였다가 사라진다.

signal hit_landed(hurtbox: HurtboxComponent, damage: int, killed: bool)

## 빔이 사라지는 시간 (초)
@export var fade_time: float = 0.2
## 빔 가운데 흰 심지 두께 비율
@export var core_ratio: float = 0.4

var _hitbox: HitboxComponent


## origin에서 direction 방향으로 쏜다. hitbox_layer는 공격 판정이 속할 레이어.
## damage_mult는 공격력 배율 (부품 효과 등)
func fire(origin: Vector2, direction: Vector2, attack: AttackData, max_length: float, width: float,
		target_mask: int, world_mask: int, color: Color, hitbox_layer: int = 0, damage_mult: float = 1.0) -> void:
	var dir: Vector2 = direction.normalized()
	global_position = origin
	rotation = dir.angle()
	var length: float = _measure_length(origin, dir, max_length, world_mask)

	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = hitbox_layer
	_hitbox.collision_mask = target_mask
	_hitbox.draw_color = Color.TRANSPARENT
	_hitbox.damage_mult = damage_mult
	add_child(_hitbox)
	_hitbox.hit_landed.connect(hit_landed.emit)
	# 히트박스는 회전된 이 노드의 자식이므로 로컬 x축이 빔 방향이다.
	_hitbox.activate_rect(attack, Vector2(length * 0.5, 0.0), Vector2(length, width), dir)

	_add_rect(length, width, color)
	_add_rect(length, width * core_ratio, Color.WHITE)

	get_tree().create_timer(attack.active, false, true).timeout.connect(_hitbox.deactivate)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)


func _measure_length(origin: Vector2, dir: Vector2, max_length: float, world_mask: int) -> float:
	var query := PhysicsRayQueryParameters2D.create(origin, origin + dir * max_length, world_mask)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return max_length
	return origin.distance_to(hit["position"])


func _add_rect(length: float, width: float, color: Color) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(length, width)
	rect.position = Vector2(0.0, -width * 0.5)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
