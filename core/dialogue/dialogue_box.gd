class_name DialogueBox
extends CanvasLayer
## 대사 상자. DialogueData를 받아 화자 이름과 대사를 한 글자씩 출력한다.
## advance 입력: 출력 중이면 줄을 바로 완성하고, 다 나왔으면 다음 줄로 넘어간다.
## skip 입력: 남은 대사를 모두 건너뛴다. 끝나면 finished를 보낸다.
## 게임이 멈춘 동안에도 동작한다.

signal line_started(index: int)
signal finished

@export var chars_per_second: float = 40.0
@export var advance_actions: Array[StringName] = [&"ui_accept"]
@export var skip_actions: Array[StringName] = [&"ui_cancel"]
## 화자별 이름 색. 없으면 default_speaker_color
@export var speaker_colors: Dictionary = {}
@export var default_speaker_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var text_color: Color = Color.WHITE
@export var back_color: Color = Color(0.02, 0.02, 0.06, 0.92)
@export var border_color: Color = Color(0.0, 1.0, 0.9, 0.6)
@export var hint_color: Color = Color(0.6, 0.62, 0.7, 1.0)
@export var box_height: float = 92.0
@export var margin: float = 12.0
@export var font_size: int = 12
@export var hint_text: String = "▶"
@export var box_layer: int = 80

var data: DialogueData

var _index: int = -1
var _visible_chars: float = 0.0
var _root: Control
var _speaker: Label
var _text: Label
var _hint: Label


func _ready() -> void:
	layer = box_layer
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func is_active() -> bool:
	return _root.visible


func start(dialogue: DialogueData) -> void:
	data = dialogue
	_index = -1
	_root.visible = true
	_next_line()


func _build() -> void:
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = back_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	_root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = margin
	panel.offset_right = -margin
	panel.offset_bottom = -margin
	panel.offset_top = -margin - box_height
	panel.gui_input.connect(_on_panel_input)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override(&"font_size", font_size)
	box.add_child(_speaker)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override(&"font_size", font_size)
	_text.add_theme_color_override(&"font_color", text_color)
	box.add_child(_text)
	_hint = Label.new()
	_hint.text = hint_text
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override(&"font_size", font_size)
	_hint.add_theme_color_override(&"font_color", hint_color)
	box.add_child(_hint)


func _process(delta: float) -> void:
	if not is_active() or _is_line_complete():
		return
	_visible_chars += chars_per_second * delta
	_text.visible_characters = int(_visible_chars)
	_hint.visible = _is_line_complete()


func _input(event: InputEvent) -> void:
	if not is_active():
		return
	for action: StringName in skip_actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_finish()
			return
	for action: StringName in advance_actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			advance()
			return


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		advance()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		advance()


## 출력 중이면 줄을 완성하고, 다 나왔으면 다음 줄로 넘어간다.
func advance() -> void:
	if not is_active():
		return
	if not _is_line_complete():
		_visible_chars = _text.text.length()
		_text.visible_characters = -1
		_hint.visible = true
		return
	_next_line()


## 남은 대사를 모두 건너뛴다.
func skip() -> void:
	if is_active():
		_finish()


func _is_line_complete() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.text.length()


func _next_line() -> void:
	_index += 1
	if data == null or _index >= data.lines.size():
		_finish()
		return
	var line: DialogueLine = data.lines[_index]
	_speaker.text = line.speaker
	_speaker.visible = line.speaker != ""
	_speaker.add_theme_color_override(&"font_color", speaker_colors.get(line.speaker, default_speaker_color))
	_text.text = line.text
	_visible_chars = 0.0
	_text.visible_characters = 0
	_hint.visible = false
	line_started.emit(_index)


func _finish() -> void:
	_root.visible = false
	finished.emit()
