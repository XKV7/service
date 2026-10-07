extends BossPattern
## 홀로 망령 소환 (2페이즈). 동시에 max_alive기까지만 있다.

@export var enemy_scene: PackedScene
@export var max_alive: int = 2
@export var spawn_points: Array[Vector2] = [Vector2(80, 220), Vector2(560, 220)]
@export var telegraph_time: float = 0.6
@export var marker_color: Color = Color(1.0, 0.3, 0.8, 0.4)
@export var marker_size: Vector2 = Vector2(24, 40)

var _time: float = 0.0
var _points: Array[Vector2] = []


func enter() -> void:
	_time = 0.0
	telegraphing = true
	_points.clear()
	var alive: int = boss.get_tree().get_nodes_in_group(&"miso_summon").size()
	for i: int in mini(spawn_points.size(), max_alive - alive):
		_points.append(spawn_points[i])
		track(HazardZone.spawn(level(), Rect2(spawn_points[i] - marker_size * 0.5, marker_size),
				null, telegraph_time, 0.0, marker_color, marker_color))


func physics_update(delta: float) -> void:
	_time += delta
	if _time < telegraph_time:
		return
	for point: Vector2 in _points:
		var enemy := enemy_scene.instantiate() as Node2D
		enemy.position = point
		enemy.add_to_group(&"miso_summon")
		level().add_child(enemy)
	_points.clear()
	finish()
