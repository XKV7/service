extends Node
## 플레이어 이동 헤드리스 테스트. 입력을 흉내 내서 수치가 GDD 기준과 맞는지 확인한다.
## 실행: godot --headless --path . res://tests/test_player_movement.tscn

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const FLOOR_Y: float = 300.0
const SETTLE_FRAMES: int = 30
const TOLERANCE_PX: float = 6.0

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_lands_and_idles()
	await _test_run_speed()
	await _test_jump_height()
	await _test_dash_distance()
	await _test_air_dash_once()
	await _test_coyote_jump()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 테스트 ---

func _test_lands_and_idles() -> void:
	_floor = _make_floor(Rect2(-2000, FLOOR_Y, 4000, 40))
	var p: Player = _spawn(Vector2(0, FLOOR_Y - 40))
	await _frames(SETTLE_FRAMES)
	_check(p.is_on_floor(), "착지")
	_check(p.state_machine.get_state_name() == &"Idle", "착지 후 Idle (현재 %s)" % p.state_machine.get_state_name())
	_cleanup(p)


func _test_run_speed() -> void:
	var p: Player = await _spawn_grounded()
	Input.action_press("move_right")
	await _frames(20)
	_check(is_equal_approx(p.velocity.x, p.movement.move_speed), "최고 속도 %.0f" % p.velocity.x)
	_check(p.state_machine.get_state_name() == &"Run", "Run 상태")
	Input.action_release("move_right")
	await _frames(10)
	_check(is_zero_approx(p.velocity.x), "감속 후 정지")
	_cleanup(p)


func _test_jump_height() -> void:
	var p: Player = await _spawn_grounded()
	var start_y: float = p.global_position.y
	var min_y: float = start_y
	Input.action_press("jump")
	for i: int in 60:
		await get_tree().physics_frame
		min_y = minf(min_y, p.global_position.y)
	Input.action_release("jump")
	var expected: float = p.movement.jump_velocity ** 2 / (2.0 * p.movement.gravity)
	var height: float = start_y - min_y
	_check(absf(height - expected) < TOLERANCE_PX, "최대 점프 높이 %.1f (기대 %.1f)" % [height, expected])
	_cleanup(p)

	# 짧게 누르면 낮게 뛴다.
	p = await _spawn_grounded()
	start_y = p.global_position.y
	min_y = start_y
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	for i: int in 60:
		await get_tree().physics_frame
		min_y = minf(min_y, p.global_position.y)
	_check(start_y - min_y < expected * 0.5, "짧은 점프 높이 %.1f" % (start_y - min_y))
	_cleanup(p)


func _test_dash_distance() -> void:
	var p: Player = await _spawn_grounded()
	var start_x: float = p.global_position.x
	Input.action_press("dash")
	# 대시 상태가 끝나는 순간까지의 이동 거리를 잰다.
	var entered: bool = false
	for i: int in 60:
		await get_tree().physics_frame
		var in_dash: bool = p.state_machine.get_state_name() == &"Dash"
		if in_dash:
			entered = true
		elif entered:
			break
	Input.action_release("dash")
	var dist: float = p.global_position.x - start_x
	_check(absf(dist - p.movement.dash_distance) < TOLERANCE_PX * 2.0, "대시 거리 %.1f" % dist)
	_cleanup(p)


func _test_air_dash_once() -> void:
	# 높은 곳에서 떨어뜨려 쿨다운이 끝날 때까지 공중에 머물게 한다.
	_floor = _make_floor(Rect2(-2000, FLOOR_Y, 4000, 40))
	var p: Player = _spawn(Vector2(0, FLOOR_Y - 600))
	await _frames(2)
	await _tap("dash")
	await _frames(ceili(p.movement.dash_cooldown * Engine.physics_ticks_per_second) + 2)
	_check(not p.is_on_floor(), "아직 공중")
	_check(not p.can_dash(), "공중 대시는 1회만")
	await _frames(90)
	_check(p.is_on_floor() and p.can_dash(), "착지 후 대시 초기화")
	_cleanup(p)


func _test_coyote_jump() -> void:
	# 발판 끝에서 걸어 나간 직후 점프가 되는지 확인한다.
	var ledge: StaticBody2D = _make_floor(Rect2(-200, FLOOR_Y, 220, 40))
	var p: Player = await _spawn_grounded(false)
	Input.action_press("move_right")
	var left_floor: bool = false
	for i: int in 60:
		await get_tree().physics_frame
		if not p.is_on_floor():
			left_floor = true
			break
	Input.action_release("move_right")
	_check(left_floor, "발판에서 떨어짐")
	await _frames(2)
	await _tap("jump")
	_check(p.velocity.y < 0.0, "코요테 점프 (vy %.0f)" % p.velocity.y)
	_cleanup(p)
	ledge.queue_free()


# --- 헬퍼 ---

var _floor: StaticBody2D


func _spawn(pos: Vector2) -> Player:
	var p: Player = PLAYER_SCENE.instantiate() as Player
	p.global_position = pos
	add_child(p)
	return p


func _spawn_grounded(with_floor: bool = true) -> Player:
	if with_floor:
		_floor = _make_floor(Rect2(-2000, FLOOR_Y, 4000, 40))
	var p: Player = _spawn(Vector2(0, FLOOR_Y - 1))
	await _frames(SETTLE_FRAMES)
	return p


func _make_floor(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _cleanup(p: Player) -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump", &"dash"]:
		Input.action_release(action)
	p.queue_free()
	if _floor:
		_floor.queue_free()
		_floor = null


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _check(ok: bool, label: String) -> void:
	print(("  [OK] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failures += 1
