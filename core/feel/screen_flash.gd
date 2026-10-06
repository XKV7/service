class_name ScreenFlash
extends CanvasLayer
## 화면 전체 섬광. EventBus.screen_flash_requested를 구독한다.

@export var flash_layer: int = 100

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = flash_layer
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color.TRANSPARENT
	add_child(_rect)
	EventBus.screen_flash_requested.connect(flash)


func flash(color: Color, duration: float) -> void:
	if _tween:
		_tween.kill()
	_rect.color = color
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", 0.0, duration)
