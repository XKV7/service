extends Control
## 임시 엔딩 화면 (M7에서 엔딩 선택으로 바꾼다).

@export_file("*.tscn") var restart_scene: String = "res://game/levels/prologue/prologue.tscn"
@export var title_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var back_color: Color = Color(0.02, 0.02, 0.05, 1.0)


func _ready() -> void:
	var back := ColorRect.new()
	back.color = back_color
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.text = "ROOT ACCESS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 24)
	title.add_theme_color_override(&"font_color", title_color)
	box.add_child(title)
	var body := Label.new()
	body.text = "ARK가 멈췄다. 서버 코어 앞에서 선택이 기다리고 있다.\n(엔딩 선택은 다음 업데이트에서)\n\n처치한 보스 %d / 3   열어 본 숨겨진 공간 %d" % [GameState.defeated_bosses.size(), GameState.opened_secrets.size()]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override(&"font_size", 12)
	box.add_child(body)
	var button := Button.new()
	button.text = "처음부터"
	button.add_theme_font_size_override(&"font_size", 12)
	button.pressed.connect(_restart)
	box.add_child(button)
	button.grab_focus.call_deferred()


func _restart() -> void:
	GameState.reset()
	SceneLoader.change_scene(restart_scene)
