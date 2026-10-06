extends EnemyState
## 드론 조준 → 사격. 조준선이 대상을 따라가다가 마지막 순간 고정되고 레이저를 쏜다.

const LaserBeamScript: GDScript = preload("res://game/weapons/laser_beam.gd")

@export var attack: AttackData
## 조준선 표시 시간 (초)
@export var aim_time: float = 0.6
## 발사 직전 조준이 고정되는 시간 (초). 이때 피할 수 있다.
@export var lock_time: float = 0.2
@export var beam_length: float = 400.0
@export var beam_width: float = 4.0
@export var beam_color: Color = Color(1.0, 0.25, 0.35, 1.0)
@export var aim_color: Color = Color(1.0, 0.25, 0.35, 0.5)
@export var locked_color: Color = Color(1.0, 0.9, 0.9, 0.9)
## 조준 지점 (대상 발밑 기준, px)
@export var aim_offset: Vector2 = Vector2(0, -22)
@export_flags_2d_physics var target_mask: int = 2
@export_flags_2d_physics var world_mask: int = 1
@export_flags_2d_physics var hitbox_layer: int = 16
@export var next_state: StringName = &"Hover"

var _time: float = 0.0
var _aim_point: Vector2

var drone: Drone:
	get:
		return actor as Drone


func enter() -> void:
	_time = 0.0
	_update_aim()
	drone.aim_line.visible = true


func exit() -> void:
	drone.aim_line.visible = false


func physics_update(delta: float) -> void:
	drone.apply_friction(delta)
	drone.move_and_slide()
	_time += delta
	if _time < aim_time - lock_time:
		_update_aim()
	if _time >= aim_time:
		_fire()
		transitioned.emit(self, next_state)


func update(_delta: float) -> void:
	var from: Vector2 = drone.muzzle.position
	drone.aim_line.points = PackedVector2Array([from, drone.to_local(_aim_point)])
	drone.aim_line.default_color = locked_color if _time >= aim_time - lock_time else aim_color


func _update_aim() -> void:
	var t: Node2D = drone.get_target()
	if t:
		_aim_point = t.global_position + aim_offset
		drone.face_target()


func _fire() -> void:
	var beam: LaserBeam = LaserBeamScript.new() as LaserBeam
	drone.get_parent().add_child(beam)
	var origin: Vector2 = drone.muzzle.global_position
	beam.fire(origin, _aim_point - origin, attack, beam_length, beam_width, target_mask, world_mask, beam_color, hitbox_layer)
