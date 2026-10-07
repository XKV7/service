class_name DebugHud
extends CanvasLayer
## 임시 HUD (M8에서 정식 HUD로 바꾼다). 내구도·연산력·데이터를 보여준다.

@export var font_size: int = 12
@export var text_color: Color = Color.WHITE

var _label: Label
var _player: Player


func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override(&"font_size", font_size)
	_label.add_theme_color_override(&"font_color", text_color)
	add_child(_label)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
		if _player == null:
			return
	_label.text = "내구도 %d/%d  연산력 %.0f  데이터 %d" % [_player.health.hp, _player.health.max_hp, _player.energy.value, GameState.data]
