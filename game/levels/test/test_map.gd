extends LevelBase
## 테스트 맵. 모든 적·함정·부품과 보스 아레나 입구가 있다. 왼쪽 위에 디버그 정보를 띄운다.

@onready var debug_label: Label = %DebugLabel


func _process(_delta: float) -> void:
	debug_label.text = "내구도: %d/%d  연산력: %.0f  데이터: %d\n상태: %s\n속도: (%.0f, %.0f)\n대시 쿨다운: %.2f\n무적: %s" % [
		player.health.hp, player.health.max_hp, player.energy.value, GameState.data,
		player.state_machine.get_state_name(),
		player.velocity.x, player.velocity.y,
		player.get_dash_cooldown_left(),
		"O" if player.is_invulnerable else "-",
	]
