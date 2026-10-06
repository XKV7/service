extends Node
## 전투 헤드리스 테스트. 컴포넌트 단위 동작과 플레이어 공격 수치가 GDD 기준과 맞는지 확인한다.
## 실행: godot --headless --path . res://tests/test_combat.tscn

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const SANDBAG_SCENE: PackedScene = preload("res://game/enemies/sandbag/sandbag.tscn")
const FLOOR_Y: float = 300.0
const SETTLE_FRAMES: int = 20
const WAIT_LIMIT: int = 300

var _failures: int = 0
var _floor: StaticBody2D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_components()
	await _test_blade_combo()
	await _test_kill_energy()
	await _test_hologram_ignores_melee()
	await _test_railgun()
	await _test_hack_stun_bonus()
	await _test_pogo()
	await _test_dash_cancel()
	HitStop.cancel()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 컴포넌트 단위 ---

func _test_components() -> void:
	var health := HealthComponent.new()
	health.max_hp = 5
	health.invuln_time = 1.0
	add_child(health)
	_check(health.take_damage(1) == 1 and health.hp == 4, "체력: 피해 적용")
	_check(health.take_damage(1) == 0 and health.hp == 4, "체력: 피격 무적 중 피해 무시")
	health.queue_free()

	var gauge := ResourceGaugeComponent.new()
	gauge.max_value = 100.0
	add_child(gauge)
	gauge.add(130.0)
	_check(is_equal_approx(gauge.value, 100.0), "게이지: 최대치 제한")
	_check(gauge.spend(25.0) and is_equal_approx(gauge.value, 75.0), "게이지: 소모")
	_check(not gauge.spend(80.0) and is_equal_approx(gauge.value, 75.0), "게이지: 부족하면 소모 안 함")
	gauge.queue_free()

	var stun := StunComponent.new()
	add_child(stun)
	stun.stun(2.0)
	_check(is_equal_approx(stun.get_damage_taken_mult(), 1.25), "정지: 받는 피해 +25%")
	stun.max_duration = 0.5
	stun.stun(2.0)
	_check(stun.get_time_left() <= 2.0, "정지: 남은 시간 유지")
	stun.queue_free()


# --- 플레이어 전투 ---

func _test_blade_combo() -> void:
	var setup: Array = await _setup(Vector2(36, FLOOR_Y))
	var p: Player = setup[0]
	var bag: Sandbag = setup[1]
	# 3번 연속 입력 → 10 + 10 + 18
	for i: int in 3:
		await _tap(&"attack")
		await _frames(8)
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	_check(bag.health.hp == bag.health.max_hp - 38, "블레이드 3타 피해 38 (남은 체력 %d)" % bag.health.hp)
	_check(is_equal_approx(p.energy.value, 24.0), "타격당 연산력 +8 ×3 (현재 %.0f)" % p.energy.value)
	_cleanup(setup)


func _test_kill_energy() -> void:
	var setup: Array = await _setup(Vector2(36, FLOOR_Y))
	var p: Player = setup[0]
	var bag: Sandbag = setup[1]
	bag.health.hp = 5
	await _tap(&"attack")
	await _wait_until(func() -> bool: return bag.health.is_dead())
	_check(bag.health.is_dead(), "샌드백 처치")
	_check(is_equal_approx(p.energy.value, 23.0), "처치 시 연산력 +8 +15 (현재 %.0f)" % p.energy.value)
	_cleanup(setup)


func _test_hologram_ignores_melee() -> void:
	var setup: Array = await _setup(Vector2(36, FLOOR_Y), true)
	var p: Player = setup[0]
	var bag: Sandbag = setup[1]
	await _tap(&"attack")
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	_check(bag.health.hp == bag.health.max_hp, "홀로그램은 근접 공격이 통과")
	_cleanup(setup)


func _test_railgun() -> void:
	var setup: Array = await _setup(Vector2(200, FLOOR_Y), true)
	var p: Player = setup[0]
	var bag: Sandbag = setup[1]
	p.energy.set_value(30.0)

	# 짧게 누르면 발사 안 함
	await _tap(&"fire")
	await _frames(10)
	_check(is_equal_approx(p.energy.value, 30.0), "충전 부족 시 발사 안 함")

	Input.action_press(&"fire")
	await _wait_seconds(p.railgun.charge_time + 0.1)
	Input.action_release(&"fire")
	await _wait_until(func() -> bool: return bag.health.hp < bag.health.max_hp)
	_check(bag.health.max_hp - bag.health.hp == 40, "레일건 피해 40, 홀로그램 명중 (남은 체력 %d)" % bag.health.hp)
	_check(is_equal_approx(p.energy.value, 5.0), "레일건 연산력 25 소모 (현재 %.0f)" % p.energy.value)
	_cleanup(setup)


func _test_hack_stun_bonus() -> void:
	var setup: Array = await _setup(Vector2(36, FLOOR_Y))
	var p: Player = setup[0]
	var bag: Sandbag = setup[1]
	p.energy.set_value(50.0)
	await _tap(&"hack")
	await _wait_until(func() -> bool: return bag.stun.is_stunned())
	_check(bag.stun.is_stunned(), "시스템 정지 명중")
	_check(is_zero_approx(p.energy.value), "시스템 정지 연산력 50 소모")
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	await _tap(&"attack")
	await _wait_until(func() -> bool: return bag.health.hp < bag.health.max_hp)
	_check(bag.health.max_hp - bag.health.hp == 13, "정지 중 피해 +25%% (10 → %d)" % (bag.health.max_hp - bag.health.hp))
	_cleanup(setup)


func _test_pogo() -> void:
	_floor = _make_floor()
	var bag: Sandbag = SANDBAG_SCENE.instantiate() as Sandbag
	bag.use_gravity = false
	bag.position = Vector2(0, FLOOR_Y - 10)
	add_child(bag)
	var p: Player = PLAYER_SCENE.instantiate() as Player
	p.position = Vector2(0, FLOOR_Y - 120)
	add_child(p)
	await _frames(4)
	Input.action_press(&"move_down")
	await _tap(&"attack")
	var bounced: bool = false
	for i: int in WAIT_LIMIT:
		await get_tree().physics_frame
		if p.velocity.y < 0.0:
			bounced = true
			break
	Input.action_release(&"move_down")
	_check(bounced, "아래 찍기 명중 시 튀어 오름")
	_check(bag.health.hp < bag.health.max_hp, "아래 찍기 피해")
	_cleanup([p, bag])


func _test_dash_cancel() -> void:
	var setup: Array = await _setup(Vector2(300, FLOOR_Y))
	var p: Player = setup[0]
	await _tap(&"attack")
	await _frames(2)
	_check(p.state_machine.get_state_name() == &"Attack", "공격 중")
	await _tap(&"dash")
	_check(p.state_machine.get_state_name() == &"Dash", "공격을 대시로 캔슬")
	_cleanup(setup)


# --- 헬퍼 ---

## [플레이어, 샌드백]을 반환한다. 플레이어는 원점, 오른쪽을 바라본다.
func _setup(bag_pos: Vector2, hologram: bool = false) -> Array:
	HitStop.cancel()
	_floor = _make_floor()
	var p: Player = PLAYER_SCENE.instantiate() as Player
	p.position = Vector2(0, FLOOR_Y - 1)
	add_child(p)
	var bag: Sandbag = SANDBAG_SCENE.instantiate() as Sandbag
	bag.position = bag_pos + Vector2(0, -1)
	bag.hologram = hologram
	add_child(bag)
	await _frames(SETTLE_FRAMES)
	return [p, bag]


func _make_floor() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = Vector2(0, FLOOR_Y + 20)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _cleanup(nodes: Array = []) -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_down", &"jump", &"dash", &"attack", &"fire", &"hack"]:
		Input.action_release(action)
	for n: Node in nodes:
		n.queue_free()
	# 빔·이펙트처럼 플레이어가 레벨에 남긴 노드도 지운다.
	for child: Node in get_children():
		child.queue_free()
	_floor = null
	HitStop.cancel()
	await _frames(2)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().physics_frame


func _wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, true).timeout


func _wait_until(condition: Callable) -> void:
	for i: int in WAIT_LIMIT:
		if condition.call():
			return
		await get_tree().physics_frame


func _check(ok: bool, label: String) -> void:
	print(("  [OK] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failures += 1
