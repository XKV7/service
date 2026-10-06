extends PartEffect
## 흡수 회로: 적을 effect_value마리 처치할 때마다 내구도를 effect_value_2만큼 회복한다.

var _kills: int = 0


func _activate() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _deactivate() -> void:
	if EventBus.enemy_killed.is_connected(_on_enemy_killed):
		EventBus.enemy_killed.disconnect(_on_enemy_killed)


func _on_enemy_killed(_enemy: Node) -> void:
	_kills += 1
	var data: PartLevel = get_level_data()
	if _kills < int(data.effect_value):
		return
	_kills = 0
	if host.has_method(&"heal"):
		host.call(&"heal", int(data.effect_value_2))
