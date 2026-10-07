extends BossPattern
## 고요의 빛. 2초 충전 뒤 화면 전체를 쓰는 빛. 서버 랙 뒤(기둥 반대편)에 숨어야 피할 수 있다.

@export var attack: AttackData
@export var charge_time: float = 2.0
@export var recovery_time: float = 0.5
@export var title: String = "고요의 빛"
@export var title_color: Color = Color(0.6, 1.0, 0.95, 1.0)
@export var dim_color: Color = Color(0.0, 0.05, 0.08, 0.55)
@export var blast_color: Color = Color(0.85, 1.0, 1.0, 0.85)

var _time: float = 0.0
var _fired: bool = false
var _layer: CanvasLayer
var _dim: ColorRect

var ark: ArkBoss:
	get:
		return actor as ArkBoss


func enter() -> void:
	_time = 0.0
	_fired = false
	telegraphing = true
	_layer = CanvasLayer.new()
	_layer.layer = 15
	ark.add_child(_layer)
	_dim = ColorRect.new()
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.color = Color(dim_color, 0.0)
	_layer.add_child(_dim)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override(&"font_size", 24)
	label.add_theme_color_override(&"font_color", title_color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_layer.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label.offset_top = 60.0
	EventBus.toast_requested.emit("서버 랙 뒤로 숨어라!")


func _cleanup() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()


func cancel() -> void:
	super.cancel()
	_cleanup()


func physics_update(delta: float) -> void:
	_time += delta
	if not _fired and _time >= charge_time:
		_fired = true
		telegraphing = false
		_fire()
	if _time >= charge_time + recovery_time:
		finish()


func update(_delta: float) -> void:
	if not _fired:
		_dim.color = Color(dim_color, dim_color.a * clampf(_time / charge_time, 0.0, 1.0))


func _fire() -> void:
	EventBus.screen_flash_requested.emit(blast_color, 0.4)
	EventBus.screen_shake_requested.emit(attack.shake)
	if ark.is_target_covered():
		return
	var width: float = ark.arena_right - ark.arena_left
	HazardZone.spawn(level(), Rect2(ark.arena_left, -200.0, width, ark.floor_y + 200.0), attack, 0.0, 0.1,
			Color.TRANSPARENT, Color(blast_color, 0.3))
