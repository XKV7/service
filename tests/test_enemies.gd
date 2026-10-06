extends Node
## 적·함정 헤드리스 테스트. 각 적이 실제로 플레이어를 공격할 수 있는지, 특수 규칙이 동작하는지 확인한다.
## 실행: godot --headless --path . res://tests/test_enemies.tscn

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const GUARD: PackedScene = preload("res://game/enemies/guard/guard.tscn")
const DRONE: PackedScene = preload("res://game/enemies/drone/drone.tscn")
const RIOT: PackedScene = preload("res://game/enemies/riot/riot.tscn")
const CRAWLER: PackedScene = preload("res://game/enemies/crawler/crawler.tscn")
const WRAITH: PackedScene = preload("res://game/enemies/wraith/wraith.tscn")
const EXECUTIONER: PackedScene = preload("res://game/enemies/executioner/executioner.tscn")
const SHOCK: AttackData = preload("res://data/attacks/trap_shock.tres")
const LASER: AttackData = preload("res://data/attacks/trap_laser.tres")
const FLOOR_Y: float = 300.0
const SETTLE_FRAMES: int = 20
## 적 행동을 기다리는 최대 프레임 (약 6초)
const WAIT_LIMIT: int = 360

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_guard_attacks_and_player_hurt()
	await _test_guard_drops_data()
	await _test_riot_shield()
	await _test_drone_shoots()
	await _test_crawler_ceiling_drop()
	await _test_wraith()
	await _test_executioner_appears_behind()
	await _test_electric_rail()
	await _test_laser_grid()
	await _test_crumbling_platform()
	await _test_player_death_and_respawn()
	HitStop.cancel()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 적 ---

func _test_guard_attacks_and_player_hurt() -> void:
	var p: Player = await _setup_player()
	var guard := _spawn(GUARD, Vector2(70, FLOOR_Y)) as Enemy
	var saw_telegraph: bool = false
	for i: int in WAIT_LIMIT:
		await get_tree().physics_frame
		if guard.state_machine.get_state_name() == &"Attack" and p.health.hp == p.health.max_hp:
			saw_telegraph = true
		if p.health.hp < p.health.max_hp:
			break
	_check(saw_telegraph, "경비 의체: 예비동작 후 공격")
	_check(p.health.max_hp - p.health.hp == 20, "경비 의체: 피해 20 (내구도 %d)" % p.health.hp)
	_check(p.state_machine.get_state_name() == &"Hurt", "플레이어 피격 경직")
	_check(p.is_invulnerable, "플레이어 피격 무적")
	await _cleanup()


func _test_guard_drops_data() -> void:
	var p: Player = await _setup_player()
	var guard := _spawn(GUARD, Vector2(36, FLOOR_Y)) as Enemy
	await _frames(2)
	guard.health.hp = 1
	var before: int = GameState.data
	var drop: int = guard.data.data_drop
	await _tap(&"attack")
	await _wait_until(func() -> bool: return GameState.data >= before + drop)
	_check(GameState.data - before == 10, "경비 의체 처치 시 데이터 10 회수 (+%d)" % (GameState.data - before))
	_check(p.energy.value >= 23.0, "처치 연산력")
	await _cleanup()


func _test_riot_shield() -> void:
	var p: Player = await _setup_player()
	var riot := _spawn(RIOT, Vector2(40, FLOOR_Y)) as Enemy
	await _frames(2)
	# 방패 규칙만 확인하도록 AI를 끈다.
	riot.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	riot.facing = -1.0
	await _tap(&"attack")
	await _frames(20)
	_check(riot.health.hp == riot.health.max_hp, "진압 요원: 정면 근접 공격 막음")

	p.energy.set_value(25.0)
	Input.action_press(&"fire")
	await _wait_seconds(p.railgun.charge_time + 0.1)
	Input.action_release(&"fire")
	await _wait_until(func() -> bool: return riot.health.hp < riot.health.max_hp)
	_check(riot.health.max_hp - riot.health.hp == 40, "진압 요원: 레일건은 방패 관통")

	riot.stun.stun(2.0)
	var hp_before: int = riot.health.hp
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	await _tap(&"attack")
	await _wait_until(func() -> bool: return riot.health.hp < hp_before)
	_check(riot.health.hp < hp_before, "진압 요원: 정지 중에는 방패 무력화")
	await _cleanup()


func _test_drone_shoots() -> void:
	var p: Player = await _setup_player()
	_spawn(DRONE, Vector2(120, FLOOR_Y - 90))
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.max_hp - p.health.hp == 10, "보안 드론: 조준 후 레이저 명중, 피해 10")
	await _cleanup()


func _test_crawler_ceiling_drop() -> void:
	var p: Player = await _setup_player()
	var ceiling := _make_body(Rect2(-200, 160, 400, 20))
	var crawler := CRAWLER.instantiate() as Crawler
	crawler.on_ceiling = true
	crawler.position = Vector2(20, 186)
	add_child(crawler)
	await _wait_until(func() -> bool: return not crawler.on_ceiling)
	_check(not crawler.on_ceiling, "선로 크롤러: 천장에서 떨어짐")
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.hp < p.health.max_hp, "선로 크롤러: 접촉·도약 피해")
	ceiling.queue_free()
	await _cleanup()


func _test_wraith() -> void:
	var p: Player = await _setup_player()
	var wraith := _spawn(WRAITH, Vector2(150, FLOOR_Y - 30)) as Enemy
	await _wait_until(func() -> bool: return wraith.state_machine.get_state_name() == &"Attack")
	_check(absf(wraith.global_position.x - p.global_position.x) < 80.0, "홀로 망령: 플레이어 옆으로 순간이동")
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.max_hp - p.health.hp == 20, "홀로 망령: 공격 명중, 피해 20")
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	p.facing = signf(wraith.global_position.x - p.global_position.x)
	var hp_before: int = wraith.health.hp
	await _tap(&"attack")
	await _frames(20)
	_check(wraith.health.hp == hp_before, "홀로 망령: 근접 공격 통과")
	await _cleanup()


func _test_executioner_appears_behind() -> void:
	var p: Player = await _setup_player()
	var ex := _spawn(EXECUTIONER, Vector2(150, FLOOR_Y)) as Enemy
	await _wait_until(func() -> bool: return ex.state_machine.get_state_name() == &"Cloak")
	_check(ex.state_machine.get_state_name() == &"Cloak", "처형자: 광학 위장")
	var facing_at_cloak: float = p.facing
	await _wait_until(func() -> bool: return ex.state_machine.get_state_name() == &"Slash")
	var side: float = signf(ex.global_position.x - p.global_position.x)
	_check(side == -facing_at_cloak, "처형자: 플레이어 뒤에서 출현")
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.max_hp - p.health.hp == 40, "처형자: 피해 40")
	await _cleanup()


# --- 함정 ---

func _test_electric_rail() -> void:
	var p: Player = await _setup_player()
	var rail := ElectricRail.new()
	rail.attack = SHOCK
	rail.position = Vector2(-50, FLOOR_Y - 6)
	add_child(rail)
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.max_hp - p.health.hp == 10, "감전 선로: 피해 10")
	_check(p.velocity.y < 0.0 or p.global_position.y < FLOOR_Y - 2.0, "감전 선로: 튕겨 오름")
	await _cleanup()


func _test_laser_grid() -> void:
	var p: Player = await _setup_player()
	var grid := LaserGrid.new()
	grid.attack = LASER
	grid.position = Vector2(80, FLOOR_Y - 180)
	add_child(grid)
	await _frames(30)
	var start_x: float = p.global_position.x
	Input.action_press(&"move_right")
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	Input.action_release(&"move_right")
	_check(p.health.max_hp - p.health.hp == 20, "레이저 보안망: 피해 20")
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() != &"Hurt")
	_check(p.global_position.x < 80.0 - 20.0 and absf(p.global_position.x - start_x) < 60.0, "레이저 보안망: 안전 지점으로 복귀 (x=%.0f)" % p.global_position.x)

	p.energy.set_value(50.0)
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	p.facing = 1.0
	await _tap(&"hack")
	await _wait_until(func() -> bool: return grid.is_disabled())
	_check(grid.is_disabled(), "레이저 보안망: 시스템 정지로 해제")
	await _cleanup()


func _test_crumbling_platform() -> void:
	HitStop.cancel()
	var plat := CrumblingPlatform.new()
	plat.position = Vector2(-32, FLOOR_Y)
	add_child(plat)
	var p := PLAYER_SCENE.instantiate() as Player
	p.position = Vector2(0, FLOOR_Y - 20)
	add_child(p)
	await _wait_until(func() -> bool: return p.is_on_floor())
	_check(p.is_on_floor(), "무너지는 발판: 올라섬")
	await _wait_seconds(plat.crumble_delay + 0.2)
	_check(not p.is_on_floor(), "무너지는 발판: 붕괴 후 낙하")
	await _cleanup()


func _test_player_death_and_respawn() -> void:
	var p: Player = await _setup_player()
	p.respawn_position = Vector2(-100, FLOOR_Y - 1)
	var respawned: Array[bool] = [false]
	EventBus.player_respawned.connect(func() -> void: respawned[0] = true, CONNECT_ONE_SHOT)
	p.health.hp = 10
	_spawn(GUARD, Vector2(60, FLOOR_Y))
	await _wait_until(func() -> bool: return p.is_dead())
	_check(p.state_machine.get_state_name() == &"Dead", "의체 파괴")
	await _wait_until(func() -> bool: return respawned[0])
	_check(respawned[0] and p.health.hp == p.health.max_hp, "재접속: 체력 회복")
	_check(absf(p.global_position.x - p.respawn_position.x) < 4.0, "재접속: 재접속 지점으로 이동")
	await _cleanup()


# --- 헬퍼 ---

func _setup_player() -> Player:
	HitStop.cancel()
	_make_body(Rect2(-2000, FLOOR_Y, 4000, 40))
	var p := PLAYER_SCENE.instantiate() as Player
	p.position = Vector2(0, FLOOR_Y - 1)
	add_child(p)
	await _frames(SETTLE_FRAMES)
	return p


func _spawn(scene: PackedScene, pos: Vector2) -> Node2D:
	var n := scene.instantiate() as Node2D
	n.position = pos
	add_child(n)
	return n


func _make_body(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body


func _cleanup() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_down", &"jump", &"dash", &"attack", &"fire", &"hack"]:
		Input.action_release(action)
	for child: Node in get_children():
		child.queue_free()
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
