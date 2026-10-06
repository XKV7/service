extends PartEffect
## 반응 신경망: 대시가 끝난 직후 effect_value_2초 동안 공격력 +effect_value

const TEMP_SOURCE: StringName = &"part_temp:reflex_net"

var _time_left: float = 0.0


func _activate() -> void:
	EventBus.player_dashed.connect(_on_dashed)


func _deactivate() -> void:
	if EventBus.player_dashed.is_connected(_on_dashed):
		EventBus.player_dashed.disconnect(_on_dashed)
	if stats:
		stats.remove_source(TEMP_SOURCE)


func _physics_process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		stats.remove_source(TEMP_SOURCE)


func _on_dashed(_direction: float) -> void:
	var data: PartLevel = get_level_data()
	# 대시 시간 + "직후" 시간 동안 유지한다.
	var dash_time: float = (host as Player).movement.dash_duration if host is Player else 0.0
	_time_left = dash_time + data.effect_value_2
	stats.set_source(TEMP_SOURCE, [StatModifier.create(Player.STAT_ATTACK_MULT, StatModifier.Op.ADD, data.effect_value)])
