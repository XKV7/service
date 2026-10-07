extends BossPattern
## 의식 투영체 소환. 갇힌 사람들의 형상이 나타난다. 처치하면 짧게 목소리를 남긴다.

@export var enemy_scene: PackedScene
@export var count: int = 3
@export var max_alive: int = 3
@export var telegraph_time: float = 0.6
@export var spawn_inset: float = 60.0
@export var marker_size: Vector2 = Vector2(22, 44)
@export var marker_color: Color = Color(0.6, 0.95, 1.0, 0.4)
@export var projection_tint: Color = Color(0.6, 0.95, 1.0, 0.75)

var _time: float = 0.0
var _points: Array[Vector2] = []

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	telegraphing = true
	_points.clear()
	for i: int in mini(count, max_alive - ark.alive_projections()):
		var x: float = randf_range(ark.arena_left + spawn_inset, ark.arena_right - spawn_inset)
		var point := Vector2(x, ark.floor_y)
		_points.append(point)
		track(HazardZone.spawn(level(), Rect2(point - Vector2(marker_size.x * 0.5, marker_size.y), marker_size),
				null, telegraph_time, 0.0, marker_color, marker_color))


func physics_update(delta: float) -> void:
	_time += delta
	if _time < telegraph_time:
		return
	for point: Vector2 in _points:
		var enemy := enemy_scene.instantiate() as Node2D
		enemy.position = point
		enemy.modulate = projection_tint
		level().add_child(enemy)
		ark.register_projection(enemy)
	_points.clear()
	finish()
