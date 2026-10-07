class_name SignText
extends Node2D
## 안내 표지판. 월드에 글자를 띄운다. (튜토리얼, 지역 간판)

@export_multiline var text: String = ""
@export var width: float = 200.0
@export var font_size: int = 12
@export var color: Color = Color(0.0, 1.0, 0.9, 0.85)


func _ready() -> void:
	var label := Label.new()
	label.text = text
	label.size = Vector2(width, 0.0)
	label.position = Vector2(-width * 0.5, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
