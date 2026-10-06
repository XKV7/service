class_name HackWave
extends Node2D
## 시스템 정지 범위 표시. 시전자 쪽에서 앞으로 퍼지며 사라진다.

@export var spread_time: float = 0.18
@export var fade_time: float = 0.25
@export var outline_width: float = 2.0
## 채움 투명도 (테두리 대비)
@export var fill_alpha_mult: float = 0.3

var _size: Vector2
var _facing: float = 1.0
var _color: Color
var _progress: float = 0.0


func play(center: Vector2, size: Vector2, facing: float, color: Color) -> void:
	global_position = center
	_size = size
	_facing = facing
	_color = color
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, spread_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _draw() -> void:
	var width: float = _size.x * _progress
	# 시전자 쪽 끝에서 앞으로 자란다.
	var start_x: float = -_size.x * 0.5 if _facing > 0.0 else _size.x * 0.5 - width
	var rect := Rect2(Vector2(start_x, -_size.y * 0.5), Vector2(width, _size.y))
	var fill := _color
	fill.a *= fill_alpha_mult
	draw_rect(rect, fill)
	draw_rect(rect, _color, false, outline_width)
