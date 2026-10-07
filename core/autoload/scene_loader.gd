extends Node
## 씬 전환. 화면을 어둡게 했다가 새 씬을 불러오고 다시 밝힌다.
## transfer에 넣은 데이터는 새 씬이 읽을 수 있다. (예: 플레이어 체력 이어가기)

signal scene_changed(path: String)

@export var fade_time: float = 0.35
@export var fade_color: Color = Color.BLACK

## 이전 씬이 다음 씬에 넘기는 데이터
var transfer: Dictionary = {}

var _rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_rect = ColorRect.new()
	_rect.color = Color(fade_color, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func is_busy() -> bool:
	return _busy


func change_scene(path: String, data: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	transfer = data
	await _fade(1.0)
	HitStop.cancel()
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	scene_changed.emit(path)
	await _fade(0.0)
	_busy = false


## 지금 씬을 처음부터 다시 불러온다. transfer는 비운다.
func reload_scene() -> void:
	var current: Node = get_tree().current_scene
	if current:
		change_scene(current.scene_file_path)


func _fade(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "color:a", alpha, fade_time)
	await tween.finished
