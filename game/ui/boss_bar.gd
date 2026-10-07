class_name BossBar
extends CanvasLayer
## 화면 아래 가운데 보스 체력바와 이름. 보스전에서만 보인다.

@export var bar_size: Vector2 = Vector2(360, 6)
@export var bottom_margin: float = 34.0
@export var font_size: int = 12
@export var fill_color: Color = Color(1.0, 0.3, 0.7, 1.0)
@export var back_color: Color = Color(0.1, 0.1, 0.18, 0.9)
@export var name_color: Color = Color.WHITE
@export var hide_delay: float = 2.0

var _box: VBoxContainer
var _name: Label
var _fill: ColorRect
var _boss: Boss


func _ready() -> void:
	layer = 30
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(_box)
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.offset_bottom = -bottom_margin
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.add_theme_font_size_override(&"font_size", font_size)
	_name.add_theme_color_override(&"font_color", name_color)
	_box.add_child(_name)
	var center := CenterContainer.new()
	_box.add_child(center)
	var back := ColorRect.new()
	back.custom_minimum_size = bar_size
	back.color = back_color
	center.add_child(back)
	_fill = ColorRect.new()
	_fill.size = bar_size
	_fill.color = fill_color
	back.add_child(_fill)
	_box.visible = false
	EventBus.boss_started.connect(_on_boss_started)
	EventBus.boss_defeated.connect(_on_boss_defeated)


func _on_boss_started(boss: Node) -> void:
	_boss = boss as Boss
	if _boss == null:
		return
	_name.text = _boss.display_name
	_box.visible = true
	_boss.health.health_changed.connect(_on_health_changed)
	_on_health_changed(_boss.health.hp, _boss.health.max_hp)


func _on_health_changed(current: int, maximum: int) -> void:
	_fill.size.x = bar_size.x * float(current) / float(maximum)


func _on_boss_defeated(_id: StringName) -> void:
	get_tree().create_timer(hide_delay).timeout.connect(func() -> void: _box.visible = false)
