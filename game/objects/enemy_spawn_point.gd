class_name EnemySpawnPoint
extends Marker2D
## 적을 배치하는 지점. 플레이어가 재접속하면(이후 중계기 사용 시에도) 적을 다시 배치한다.

@export var enemy_scene: PackedScene
## 생성한 적에 덮어쓸 속성 (예: {"on_ceiling": true})
@export var properties: Dictionary = {}

var _instance: Node


func _ready() -> void:
	add_to_group(&"enemy_spawn_point")
	EventBus.player_respawned.connect(respawn)
	respawn.call_deferred()


func respawn() -> void:
	if is_instance_valid(_instance):
		_instance.queue_free()
	if enemy_scene == null:
		return
	_instance = enemy_scene.instantiate()
	for key: Variant in properties:
		_instance.set(key, properties[key])
	_instance.position = position
	get_parent().add_child(_instance)
