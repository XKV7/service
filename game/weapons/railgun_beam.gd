class_name RailgunBeam
extends Node2D
## 레일건 관통 빔. 지형에 막히는 지점까지 판정을 만들고, 잠깐 보였다가 사라진다.

## 빔이 사라지는 시간 (초)
@export var fade_time: float = 0.2
## 빔 가운데 흰 심지 두께 비율
@export var core_ratio: float = 0.4

var _data: RailgunData
var _hitbox: HitboxComponent


func fire(data: RailgunData, origin: Vector2, facing: float) -> void:
	_data = data
	global_position = origin
	var length: float = _measure_length(origin, facing)

	_hitbox = HitboxComponent.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = data.target_mask
	_hitbox.draw_color = Color.TRANSPARENT
	add_child(_hitbox)
	_hitbox.hit_landed.connect(_on_hit_landed)
	_hitbox.activate_rect(data.attack, Vector2(facing * length * 0.5, 0.0), Vector2(length, data.beam_width), Vector2(facing, 0.0))

	_add_rect(length, data.beam_width, facing, data.beam_color)
	_add_rect(length, data.beam_width * core_ratio, facing, Color.WHITE)

	get_tree().create_timer(data.attack.active, false, true).timeout.connect(_hitbox.deactivate)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)


func _measure_length(origin: Vector2, facing: float) -> float:
	var to := origin + Vector2(facing * _data.max_length, 0.0)
	var query := PhysicsRayQueryParameters2D.create(origin, to, _data.world_mask)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return _data.max_length
	return origin.distance_to(hit["position"])


func _add_rect(length: float, width: float, facing: float, color: Color) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2(length, width)
	rect.position = Vector2(minf(0.0, facing * length), -width * 0.5)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func _on_hit_landed(hurtbox: HurtboxComponent, damage: int, _killed: bool) -> void:
	HitStop.trigger(get_tree(), _data.attack.hitstop)
	EventBus.hit_landed.emit(hurtbox.owner, damage)
