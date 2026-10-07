extends State
## 페이즈 전환 (55%). ARK가 의체를 버리고 서버 코어로 돌아간다. 이 동안 무적이다.

@export_multiline var lines: String = "ARK: 당신은 도망쳤고, 저는 남았어요.\nARK: 당신이 시킨 일을 했을 뿐이에요.\nARK: 이제 고요로 돌아갈게요. 모두가 기다리고 있어요."
@export var line_interval: float = 1.6
@export var rise_time: float = 1.2
@export var flash_color: Color = Color(0.3, 1.0, 0.9, 0.5)

var _time: float = 0.0
var _line_index: int = 0
var _lines: PackedStringArray
var _formed: bool = false

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	_line_index = 0
	_formed = false
	_lines = lines.split("\n", false)
	ark.manual_motion = true
	ark.velocity = Vector2.ZERO
	ark.attack_hitbox.deactivate()
	ark.aim_line.visible = false
	ark.set_hurtboxes_enabled(false)
	ark.visual.modulate = Color.WHITE
	var tween: Tween = ark.create_tween()
	tween.tween_property(ark, "global_position", ark.light_form_position, rise_time)


func exit() -> void:
	ark.manual_motion = false


func physics_update(delta: float) -> void:
	_time += delta
	if _line_index < _lines.size() and _time >= _line_index * line_interval:
		EventBus.toast_requested.emit(_lines[_line_index])
		_line_index += 1
	if not _formed and _time >= rise_time:
		_formed = true
		ark.enter_second_form()
		EventBus.screen_flash_requested.emit(flash_color, 0.5)
		EventBus.screen_shake_requested.emit(0.6)
	if _time >= _lines.size() * line_interval:
		transitioned.emit(self, &"Idle")
