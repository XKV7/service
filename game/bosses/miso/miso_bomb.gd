extends BossPattern
## 할인 폭격. "지금 바로!" 문구 뒤 가격표 모양 폭탄이 떨어진다. 떨어질 위치가 먼저 깜빡인다.

@export var attack: AttackData
@export var shout_time: float = 0.6
@export var count: int = 5
@export var interval: float = 0.2
@export var warn_time: float = 0.9
@export var active_time: float = 0.15
@export var size: float = 36.0
@export var shout_text: String = "지금 바로!"
@export var shout_color: Color = Color(1.0, 0.9, 0.2, 1.0)
@export var warn_color: Color = Color(1.0, 0.9, 0.2, 0.3)
@export var active_color: Color = Color(1.0, 0.5, 0.2, 0.9)
@export var bomb_color: Color = Color(1.0, 0.85, 0.3, 1.0)

var _time: float = 0.0
var _dropped: int = 0
var _label: Label

var miso: MisoBoss:
	get:
		return actor as MisoBoss


func enter() -> void:
	_time = 0.0
	_dropped = 0
	telegraphing = true
	_label = Label.new()
	_label.text = shout_text
	_label.add_theme_font_size_override(&"font_size", 24)
	_label.add_theme_color_override(&"font_color", shout_color)
	_label.position = miso.global_position + Vector2(-48, 60)
	level().add_child(_label)


func _cleanup() -> void:
	if is_instance_valid(_label):
		_label.queue_free()


func cancel() -> void:
	super.cancel()
	_cleanup()


func physics_update(delta: float) -> void:
	_time += delta
	if _time < shout_time:
		return
	var t: float = _time - shout_time
	if _dropped < count and t >= _dropped * interval:
		_drop(_dropped == 0)
		_dropped += 1
	telegraphing = t < warn_time
	if t >= (count - 1) * interval + warn_time + active_time:
		finish()


func _drop(at_player: bool) -> void:
	var x: float = randf_range(miso.arena_left + size, miso.arena_right - size)
	var target: Node2D = miso.get_target()
	if at_player and target:
		x = target.global_position.x
	var rect := Rect2(x - size * 0.5, miso.floor_y - size, size, size)
	track(HazardZone.spawn(level(), rect, attack, warn_time, active_time, warn_color, active_color))
	# 떨어지는 폭탄 모양
	var bomb := ColorRect.new()
	bomb.size = Vector2(size * 0.5, size * 0.35)
	bomb.color = bomb_color
	bomb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level().add_child(bomb)
	bomb.global_position = Vector2(x - bomb.size.x * 0.5, 0.0)
	var tween: Tween = bomb.create_tween()
	tween.tween_property(bomb, "global_position:y", miso.floor_y - bomb.size.y, warn_time).set_ease(Tween.EASE_IN)
	tween.tween_callback(bomb.queue_free)
