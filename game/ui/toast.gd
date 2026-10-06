class_name Toast
extends CanvasLayer
## 화면 위쪽 알림 문구. EventBus.toast_requested를 구독한다. 여러 개면 차례로 보여준다.

@export var show_time: float = 1.6
## 대기 중인 알림이 이만큼 이상이면 빨리 넘긴다.
@export var rush_queue_size: int = 2
@export var rush_show_time: float = 0.5
@export var fade_time: float = 0.3
@export var top_margin: float = 28.0
@export var text_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var back_color: Color = Color(0.03, 0.03, 0.08, 0.8)
@export var font_size: int = 12

var _queue: Array[String] = []
var _panel: PanelContainer
var _label: Label
var _busy: bool = false


func _ready() -> void:
	# 의체 메뉴(50)보다 아래에 그려서 메뉴를 가리지 않는다.
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = back_color
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	_panel.add_theme_stylebox_override(&"panel", style)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_color_override(&"font_color", text_color)
	_label.add_theme_font_size_override(&"font_size", font_size)
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	EventBus.toast_requested.connect(show_text)


func show_text(text: String) -> void:
	_queue.append(text)
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		_panel.visible = false
		return
	_busy = true
	_label.text = _queue.pop_front()
	_panel.visible = true
	_panel.modulate.a = 1.0
	_panel.reset_size()
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	_panel.position = Vector2((viewport_width - _panel.size.x) * 0.5, top_margin)
	var tween: Tween = create_tween()
	tween.tween_interval(rush_show_time if _queue.size() >= rush_queue_size else show_time)
	tween.tween_property(_panel, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_next)
