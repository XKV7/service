extends State
## 투사기가 부서져 미소가 크게 흔들리는 동안. 본체에 피해가 들어가고 공격하지 않는다.

@export var shake_amount: float = 4.0
@export var tint: Color = Color(1.0, 0.7, 0.8, 1.0)

var _time: float = 0.0
var _origin: Vector2

var miso: MisoBoss:
	get:
		return actor as MisoBoss


func enter() -> void:
	_time = 0.0
	_origin = miso.visual.position
	miso.set_vulnerable(true)
	EventBus.toast_requested.emit("미소가 흔들린다! 지금이다!")


func exit() -> void:
	miso.set_vulnerable(false)
	miso.visual.position = _origin
	miso.visual.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_time += delta
	if _time >= miso.window_time:
		transitioned.emit(self, &"Idle")


func update(_delta: float) -> void:
	miso.visual.position = _origin + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
	miso.visual.modulate = tint
