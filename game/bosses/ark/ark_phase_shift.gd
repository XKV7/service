extends State
## 페이즈 전환 (55%). ARK가 의체를 버리고 서버 코어로 돌아간다. 이 동안 무적이다.

@export var dialogue: DialogueData
@export var rise_time: float = 1.2
## 형태가 바뀐 뒤 다음 패턴까지 (초)
@export var settle_time: float = 0.8
@export var flash_color: Color = Color(0.3, 1.0, 0.9, 0.5)

var _time: float = 0.0
var _formed: bool = false

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	_formed = false
	ark.manual_motion = true
	ark.velocity = Vector2.ZERO
	ark.attack_hitbox.deactivate()
	ark.aim_line.visible = false
	ark.set_hurtboxes_enabled(false)
	ark.visual.modulate = Color.WHITE
	Story.play(dialogue)
	var tween: Tween = ark.create_tween()
	tween.tween_property(ark, "global_position", ark.light_form_position, rise_time)


func exit() -> void:
	ark.manual_motion = false


func physics_update(delta: float) -> void:
	_time += delta
	if not _formed and _time >= rise_time:
		_formed = true
		ark.enter_second_form()
		EventBus.screen_flash_requested.emit(flash_color, 0.5)
		EventBus.screen_shake_requested.emit(0.6)
	if _time >= rise_time + settle_time:
		transitioned.emit(self, &"Idle")
