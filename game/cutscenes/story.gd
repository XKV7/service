extends Node
## 스토리 진행. 대사 장면을 재생하는 동안 게임을 멈추고, 본 장면을 기록한다.
## 기억 조각은 회상 화면(정지 화면 + 제목) 위에 대사를 띄운다.

signal dialogue_started(id: StringName)
signal dialogue_finished(id: StringName)

## 테스트용: 대사를 띄우지 않고 바로 끝낸다.
var auto_skip: bool = false

const SPEAKER_COLORS: Dictionary = {
	"ROOT": Color(0.85, 0.9, 1.0),
	"ROOT (과거)": Color(0.7, 0.75, 0.85),
	"ARK": Color(0.3, 1.0, 0.6),
	"구조 신호": Color(0.6, 0.9, 1.0),
	"시스템": Color(0.9, 0.78, 0.4),
	"시스템 로그": Color(0.9, 0.78, 0.4),
	"스피커": Color(1.0, 0.85, 0.3),
	"광고": Color(1.0, 0.4, 0.8),
	"미소": Color(1.0, 0.4, 0.8),
	"한을 임원": Color(0.95, 0.95, 0.95),
	"목소리들": Color(0.6, 0.9, 1.0),
}
const MEMORY_TINT: Color = Color(0.75, 0.95, 1.0, 0.85)
const MEMORY_TITLE_COLOR: Color = Color(0.05, 0.1, 0.15, 1.0)
const MEMORY_LAYER: int = 70

var _box: DialogueBox
var _queue: Array[DialogueData] = []
var _current: DialogueData
var _memory_layer: CanvasLayer
var _memory_title: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = DialogueBox.new()
	_box.advance_actions = [&"interact", &"attack", &"jump", &"ui_accept"]
	_box.skip_actions = [&"menu", &"pause"]
	_box.speaker_colors = SPEAKER_COLORS
	_box.hint_text = "▶  (Tab: 건너뛰기)"
	add_child(_box)
	_box.finished.connect(_on_box_finished)
	_build_memory_layer()


func is_playing() -> bool:
	return _current != null


func has_seen(data: DialogueData) -> bool:
	return data != null and GameState.has_seen(data.id)


## 장면을 재생한다. 이미 재생 중이면 끝난 뒤에 이어서 재생한다.
func play(data: DialogueData) -> void:
	if data == null:
		return
	GameState.mark_seen(data.id)
	_queue.append(data)
	if _current == null:
		_start_next()


## 아직 본 적 없는 장면이면 재생하고 true
func play_once(data: DialogueData) -> bool:
	if data == null or has_seen(data):
		return false
	play(data)
	return true


## 재생하고 그 장면이 끝날 때까지 기다린다.
func play_and_wait(data: DialogueData) -> void:
	if data == null:
		return
	play(data)
	while true:
		var finished_id: StringName = await dialogue_finished
		if finished_id == data.id:
			return


## 기억 조각 회상 장면
func play_memory(data: DialogueData, number: int, total: int) -> void:
	_memory_title.text = "기억 조각 %d / %d\n%s" % [number, total, data.title]
	_memory_layer.visible = not auto_skip
	play(data)


func _start_next() -> void:
	_current = _queue.pop_front()
	dialogue_started.emit(_current.id)
	if auto_skip:
		_on_box_finished.call_deferred()
		return
	HitStop.cancel()
	get_tree().paused = true
	_box.start(_current)


func _on_box_finished() -> void:
	var finished_id: StringName = _current.id if _current else &""
	_current = null
	_memory_layer.visible = false
	if _queue.is_empty():
		if not auto_skip:
			get_tree().paused = false
		dialogue_finished.emit(finished_id)
		return
	dialogue_finished.emit(finished_id)
	_start_next()


func _build_memory_layer() -> void:
	_memory_layer = CanvasLayer.new()
	_memory_layer.layer = MEMORY_LAYER
	add_child(_memory_layer)
	var tint := ColorRect.new()
	tint.color = MEMORY_TINT
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_memory_layer.add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_memory_title = Label.new()
	_memory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_memory_title.add_theme_font_size_override(&"font_size", 24)
	_memory_title.add_theme_color_override(&"font_color", MEMORY_TITLE_COLOR)
	_memory_layer.add_child(_memory_title)
	_memory_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_memory_title.offset_top = 70.0
	_memory_layer.visible = false
