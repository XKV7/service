extends BossPattern
## 광고 빔. 눈에서 나온 레이저가 바닥을 쓸고 지나간다. 시작 지점에 조준 표시가 먼저 보인다.
## 2페이즈에는 양쪽에서 동시에 쓸고 지나간다. 뛰어넘거나 발판 위로 피한다.

@export var attack: AttackData
@export var aim_time: float = 0.8
@export var sweep_time: float = 1.4
@export var beam_width: float = 20.0
@export var beam_height: float = 44.0
## 쓸기 시작·끝 지점 (아레나 양 끝에서 안쪽으로, px)
@export var edge_inset: float = 30.0
@export var eye_offset: Vector2 = Vector2(0, -10)
@export var warn_color: Color = Color(1.0, 0.3, 0.6, 0.35)
@export var beam_color: Color = Color(1.0, 0.3, 0.6, 0.9)
@export var line_color: Color = Color(1.0, 0.5, 0.8, 0.6)

## 쓸기 하나: {"node": Node2D, "hitbox": HitboxComponent, "line": Line2D, "from": float, "to": float}
var _sweeps: Array[Dictionary] = []
var _time: float = 0.0
var _sweeping: bool = false

var miso: MisoBoss:
	get:
		return actor as MisoBoss


func enter() -> void:
	_time = 0.0
	_sweeping = false
	telegraphing = true
	var left: float = miso.arena_left + edge_inset
	var right: float = miso.arena_right - edge_inset
	var dirs: Array[float] = [1.0, -1.0]
	if miso.brain.phase_index < 1:
		dirs = [1.0 if randf() < 0.5 else -1.0]
	for dir: float in dirs:
		var from: float = left if dir > 0.0 else right
		var to: float = right if dir > 0.0 else left
		_sweeps.append(_make_sweep(from, to))
		track(HazardZone.spawn(level(), Rect2(from - beam_width * 0.5, miso.floor_y - beam_height, beam_width, beam_height),
				null, aim_time, 0.0, warn_color, warn_color))


func _cleanup() -> void:
	for sweep: Dictionary in _sweeps:
		if is_instance_valid(sweep["node"]):
			(sweep["node"] as Node).queue_free()
	_sweeps.clear()


func cancel() -> void:
	super.cancel()
	_cleanup()


func physics_update(delta: float) -> void:
	_time += delta
	if not _sweeping:
		if _time >= aim_time:
			_sweeping = true
			telegraphing = false
			_time = 0.0
			for sweep: Dictionary in _sweeps:
				(sweep["node"] as Node2D).visible = true
				var hitbox: HitboxComponent = sweep["hitbox"]
				hitbox.activate_rect(attack, Vector2.ZERO, Vector2(beam_width, beam_height), Vector2.ZERO)
		_update_positions(0.0)
		return
	var t: float = clampf(_time / sweep_time, 0.0, 1.0)
	_update_positions(t)
	if t >= 1.0:
		finish()


func _update_positions(t: float) -> void:
	var eye: Vector2 = miso.global_position + eye_offset
	for sweep: Dictionary in _sweeps:
		var x: float = lerpf(sweep["from"], sweep["to"], t)
		var node: Node2D = sweep["node"]
		node.global_position = Vector2(x, miso.floor_y - beam_height * 0.5)
		(sweep["line"] as Line2D).points = PackedVector2Array([eye - node.global_position, Vector2(0, beam_height * 0.5)])


func _make_sweep(from: float, to: float) -> Dictionary:
	var node := Node2D.new()
	node.visible = false
	level().add_child(node)
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = line_color
	node.add_child(line)
	var rect := ColorRect.new()
	rect.size = Vector2(beam_width, beam_height)
	rect.position = -rect.size * 0.5
	rect.color = beam_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(rect)
	var hitbox := HitboxComponent.new()
	hitbox.collision_layer = 16
	hitbox.collision_mask = 2
	hitbox.draw_color = Color.TRANSPARENT
	node.add_child(hitbox)
	return {"node": node, "hitbox": hitbox, "line": line, "from": from, "to": to}
