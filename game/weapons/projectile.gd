class_name Projectile
extends Node2D
## 직선으로 날아가는 투사체. 대상에 맞거나 지형에 닿거나 수명이 끝나면 사라진다.

@export var lifetime: float = 4.0
@export_flags_2d_physics var world_mask: int = 1

var _velocity: Vector2
var _hitbox: HitboxComponent
var _time: float = 0.0


static func spawn(parent: Node, origin: Vector2, velocity: Vector2, attack: AttackData, size: float, color: Color,
		hitbox_layer: int, target_mask: int) -> Projectile:
	var p := Projectile.new()
	p._velocity = velocity
	parent.add_child(p)
	p.global_position = origin
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([Vector2(-size, 0), Vector2(0, -size), Vector2(size, 0), Vector2(0, size)])
	p.add_child(visual)
	p._hitbox = HitboxComponent.new()
	p._hitbox.collision_layer = hitbox_layer
	p._hitbox.collision_mask = target_mask
	p._hitbox.draw_color = Color.TRANSPARENT
	p.add_child(p._hitbox)
	p._hitbox.activate_rect(attack, Vector2.ZERO, Vector2(size, size) * 1.5, velocity.normalized())
	p._hitbox.hit_landed.connect(func(_h: HurtboxComponent, _d: int, _k: bool) -> void: p.queue_free())
	return p


func _physics_process(delta: float) -> void:
	_time += delta
	var next: Vector2 = global_position + _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, world_mask)
	if _time >= lifetime or not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
