extends State
## 보스 처치. 히트스톱과 대사 후 보상을 주고 서서히 사라진다.

@export var fade_time: float = 2.0
## 다 사라진 뒤에도 남길 투명도 (보스 잔해 표현)
@export var final_alpha: float = 0.25

var _time: float = 0.0

var boss: Boss:
	get:
		return actor as Boss


func enter() -> void:
	_time = 0.0
	boss.set_hurtboxes_enabled(false)
	for node: Node in boss.find_children("*", "HitboxComponent", true, false):
		(node as HitboxComponent).deactivate()
	HitStop.trigger(boss.get_tree(), boss.defeat_hitstop)
	EventBus.screen_shake_requested.emit(boss.defeat_shake)
	EventBus.screen_flash_requested.emit(Color(1, 1, 1, 0.6), 0.4)
	boss.grant_rewards()
	# 대사를 먼저 시작해서(게임이 멈춤) 아레나가 대사가 끝난 뒤에 다음으로 넘어가게 한다.
	Story.play(boss.defeat_dialogue)
	EventBus.boss_defeated.emit(boss.boss_id)


func update(delta: float) -> void:
	_time += delta
	var t: float = clampf(_time / fade_time, 0.0, 1.0)
	boss.visual.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, final_alpha, t))
