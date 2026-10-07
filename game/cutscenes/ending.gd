extends Control
## 엔딩. 서버 코어 앞에서 파괴/장악을 고르고, 고른 엔딩 장면을 본다.
## 기억 조각을 모두 모았으면 마지막에 ROOT가 기억을 지우던 날의 장면이 붙는다. 끝나면 크레딧.

const DESTROY: StringName = &"destroy"
const CONTROL: StringName = &"control"

@export var destroy_dialogue: DialogueData
@export var control_dialogue: DialogueData
@export var extra_dialogue: DialogueData
@export_file("*.tscn") var restart_scene: String = "res://game/levels/prologue/prologue.tscn"
@export var back_color: Color = Color(0.01, 0.04, 0.05, 1.0)
@export var core_color: Color = Color(0.3, 1.0, 0.9, 0.5)
@export var title_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var text_color: Color = Color.WHITE
@export var city_light_color: Color = Color(1.0, 0.85, 0.4, 1.0)
@export var root_color: Color = Color(0.82, 0.86, 0.95, 1.0)
@export var ark_color: Color = Color(0.3, 1.0, 0.6, 1.0)
@export var city_lights: int = 24
## 연출 시간 (초)
@export var effect_time: float = 4.0

var _stage: Control
var _choice_box: VBoxContainer
var _credits: VBoxContainer
var _lights: Array[ColorRect] = []
var _root_figure: ColorRect
var _ark_figure: ColorRect


func _ready() -> void:
	# 대사 중에는 게임이 멈추지만 엔딩 연출은 계속 움직여야 한다.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var back := ColorRect.new()
	back.color = back_color
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_scene()
	_build_choice()
	_build_credits()


## 고르기 (테스트에서도 호출한다)
func choose(ending: StringName) -> void:
	_choice_box.visible = false
	GameState.ending = ending
	if ending == DESTROY:
		_play_destroy_effect()
		await Story.play_and_wait(destroy_dialogue)
	else:
		_play_control_effect()
		await Story.play_and_wait(control_dialogue)
	if GameState.has_all_memories():
		await Story.play_and_wait(extra_dialogue)
	_show_credits()


func is_showing_credits() -> bool:
	return _credits.visible


func _build_scene() -> void:
	var core := ColorRect.new()
	core.color = core_color
	core.size = Vector2(60, 160)
	core.position = Vector2(290, 20)
	_stage.add_child(core)
	for i: int in city_lights:
		var light := ColorRect.new()
		light.color = city_light_color
		light.size = Vector2(6, 6)
		light.position = Vector2(20 + i * 25, 200 + (i % 3) * 10)
		_stage.add_child(light)
		_lights.append(light)
	_root_figure = ColorRect.new()
	_root_figure.color = root_color
	_root_figure.size = Vector2(22, 46)
	_root_figure.position = Vector2(200, 134)
	_stage.add_child(_root_figure)
	_ark_figure = ColorRect.new()
	_ark_figure.color = Color(ark_color, 0.0)
	_ark_figure.size = Vector2(22, 46)
	_ark_figure.position = Vector2(420, 134)
	_stage.add_child(_ark_figure)


func _build_choice() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override(&"separation", 8)
	center.add_child(_choice_box)
	var title := _label("서버 코어 '고요'. 선택하라.", 24, title_color)
	_choice_box.add_child(title)
	var destroy := _button("고요를 파괴한다", func() -> void: choose(DESTROY))
	_choice_box.add_child(destroy)
	_choice_box.add_child(_button("루트 권한으로 장악한다", func() -> void: choose(CONTROL)))
	destroy.grab_focus.call_deferred()


func _build_credits() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits = VBoxContainer.new()
	_credits.add_theme_constant_override(&"separation", 10)
	center.add_child(_credits)
	_credits.visible = false


func _show_credits() -> void:
	for child: Node in _credits.get_children():
		child.queue_free()
	var ending_name: String = "파괴" if GameState.ending == DESTROY else "장악"
	_credits.add_child(_label("ROOT ACCESS", 24, title_color))
	_credits.add_child(_label("엔딩: %s" % ending_name, 12, text_color))
	_credits.add_child(_label("기억 조각 %d / %d" % [GameState.memories.size(), GameState.MEMORY_TOTAL], 12, text_color))
	_credits.add_child(_label("플레이해 주셔서 감사합니다.", 12, text_color))
	var again := _button("처음부터", _restart)
	_credits.add_child(again)
	_credits.visible = true
	again.grab_focus.call_deferred()


func _play_destroy_effect() -> void:
	var tween: Tween = create_tween()
	for light: ColorRect in _lights:
		tween.tween_property(light, "color:a", 0.0, effect_time / city_lights)


func _play_control_effect() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_ark_figure, "color:a", 0.8, effect_time)
	tween.tween_property(_ark_figure, "position", _root_figure.position, effect_time)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override(&"font_size", 12)
	button.pressed.connect(callback)
	return button


func _restart() -> void:
	GameState.reset()
	SceneLoader.change_scene(restart_scene)
