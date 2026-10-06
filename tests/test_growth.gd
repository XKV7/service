extends Node
## 성장 시스템 헤드리스 테스트. 스탯 계산, 부품 10종 효과, 슬롯·강화, 무기 교체, 중계기, 의체 잔해를 확인한다.
## 실행: godot --headless --path . res://tests/test_growth.tscn

const PLAYER_SCENE: PackedScene = preload("res://game/player/player.tscn")
const SANDBAG_SCENE: PackedScene = preload("res://game/enemies/sandbag/sandbag.tscn")
const GUARD: PackedScene = preload("res://game/enemies/guard/guard.tscn")
const FLOOR_Y: float = 300.0
const SETTLE_FRAMES: int = 20
const WAIT_LIMIT: int = 360

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_stat_sheet()
	_test_slots_and_upgrade()
	await _test_part_modifiers()
	await _test_absorb_circuit()
	await _test_reflex_net()
	await _test_data_intake()
	await _test_shock_absorber()
	await _test_overclock()
	await _test_weapon_swap()
	await _test_relay()
	await _test_wreck()
	HitStop.cancel()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 스탯·슬롯 ---

func _test_stat_sheet() -> void:
	var sheet := StatSheet.new()
	add_child(sheet)
	sheet.set_base(&"speed", 100.0)
	sheet.set_source(&"a", [StatModifier.create(&"speed", StatModifier.Op.ADD, 20.0)])
	sheet.set_source(&"b", [StatModifier.create(&"speed", StatModifier.Op.MULTIPLY, 0.5)])
	_check(is_equal_approx(sheet.get_value(&"speed"), 60.0), "스탯: (100 + 20) × 0.5 = 60")
	sheet.remove_source(&"b")
	_check(is_equal_approx(sheet.get_value(&"speed"), 120.0), "스탯: 출처 제거")
	sheet.queue_free()


func _test_slots_and_upgrade() -> void:
	GameState.reset()
	for id: StringName in [&"accel_actuator", &"armor_plate", &"compute_amp", &"cooling_fin"]:
		GameState.acquire_part(id)
	_check(GameState.equip_part(&"accel_actuator") and GameState.equip_part(&"armor_plate") and GameState.equip_part(&"compute_amp"), "슬롯 3개 장착")
	_check(not GameState.equip_part(&"cooling_fin"), "슬롯 4번째는 장착 불가")
	GameState.acquire_part(&"slot_module")
	_check(GameState.get_slot_count() == 4 and GameState.equip_part(&"cooling_fin"), "슬롯 확장 모듈로 4개")
	_check(not GameState.equip_part(&"slot_module"), "슬롯 확장 모듈은 장착하는 부품이 아님")

	_check(GameState.get_upgrade_cost(&"accel_actuator") == 200, "강화 비용 Lv2 200")
	_check(not GameState.upgrade_part(&"accel_actuator"), "데이터 부족 시 강화 불가")
	GameState.add_data(700)
	_check(GameState.upgrade_part(&"accel_actuator") and GameState.data == 500, "Lv2 강화 (데이터 -200)")
	_check(GameState.get_upgrade_cost(&"accel_actuator") == 500 and GameState.upgrade_part(&"accel_actuator") and GameState.data == 0, "Lv3 강화 (데이터 -500)")
	_check(GameState.get_upgrade_cost(&"accel_actuator") == -1, "Lv3 이후 강화 없음")


# --- 부품 효과 ---

func _test_part_modifiers() -> void:
	var p: Player = await _setup_player()
	var s: StatSheet = p.stats
	var cases: Array = [
		# [부품, 레벨, 스탯, 기대값]
		[&"accel_actuator", 1, Player.STAT_DASH_COOLDOWN, 0.375],
		[&"accel_actuator", 3, Player.STAT_DASH_COOLDOWN, 0.225],
		[&"armor_plate", 1, Player.STAT_MAX_HP, 120.0],
		[&"armor_plate", 2, Player.STAT_HURT_INVULN, 1.2],
		[&"armor_plate", 3, Player.STAT_MAX_HP, 140.0],
		[&"compute_amp", 1, Player.STAT_ENERGY_PER_HIT, 11.0],
		[&"compute_amp", 3, Player.STAT_ENERGY_PER_HIT, 15.0],
		[&"overcharge_coil", 1, Player.STAT_RAILGUN_CHARGE_TIME, 0.64],
		[&"overcharge_coil", 2, Player.STAT_RAILGUN_DAMAGE, 50.0],
		[&"overcharge_coil", 3, Player.STAT_RAILGUN_CHARGE_TIME, 0.4],
		[&"cooling_fin", 1, Player.STAT_HACK_STUN_DURATION, 2.5],
		[&"cooling_fin", 3, Player.STAT_HACK_REACH, 200.0],
	]
	for c: Array in cases:
		_equip_only(c[0], c[1])
		await _frames(2)
		var value: float = s.get_value(c[2])
		_check(is_equal_approx(value, c[3]), "%s Lv%d: %s = %.3f (기대 %.3f)" % [c[0], c[1], c[2], value, c[3]])

	# 실제 동작까지 확인: 장갑판 Lv1이면 체력 최대치가 120이 된다.
	_equip_only(&"armor_plate", 1)
	await _frames(2)
	_check(p.health.max_hp == 120, "강화 장갑판: 체력 최대치 반영")
	# 연산 증폭기 Lv1: 근접 타격당 11
	_equip_only(&"compute_amp", 1)
	await _frames(2)
	var bag := _spawn(SANDBAG_SCENE, Vector2(36, FLOOR_Y)) as Sandbag
	await _frames(4)
	p.energy.set_value(0.0)
	await _tap(&"attack")
	await _wait_until(func() -> bool: return bag.health.hp < bag.health.max_hp)
	_check(is_equal_approx(p.energy.value, 11.0), "연산 증폭기: 타격당 연산력 11 (현재 %.0f)" % p.energy.value)
	# 과충전 코일 Lv2: 레일건 피해 50
	_equip_only(&"overcharge_coil", 2)
	await _wait_until(func() -> bool: return p.state_machine.get_state_name() == &"Idle")
	var hp_before: int = bag.health.hp
	p.energy.set_value(25.0)
	Input.action_press(&"fire")
	await _wait_seconds(0.8 * 0.65 + 0.1)
	Input.action_release(&"fire")
	await _wait_until(func() -> bool: return bag.health.hp < hp_before)
	_check(hp_before - bag.health.hp == 50, "과충전 코일 Lv2: 충전 0.52초로 발사, 피해 50 (%d)" % (hp_before - bag.health.hp))
	await _cleanup()


func _test_absorb_circuit() -> void:
	var p: Player = await _setup_player()
	_equip_only(&"absorb_circuit", 1)
	await _frames(2)
	p.health.hp = 50
	for i: int in 9:
		EventBus.enemy_killed.emit(null)
	_check(p.health.hp == 50, "흡수 회로: 9마리까지는 회복 없음")
	EventBus.enemy_killed.emit(null)
	_check(p.health.hp == 70, "흡수 회로 Lv1: 10마리째에 20 회복 (%d)" % p.health.hp)
	_equip_only(&"absorb_circuit", 3)
	await _frames(2)
	for i: int in 6:
		EventBus.enemy_killed.emit(null)
	_check(p.health.hp == 90, "흡수 회로 Lv3: 6마리마다 회복 (%d)" % p.health.hp)
	await _cleanup()


func _test_reflex_net() -> void:
	var p: Player = await _setup_player()
	_equip_only(&"reflex_net", 1)
	await _frames(2)
	await _tap(&"dash")
	_check(is_equal_approx(p.hitbox.damage_mult, 1.3), "반응 신경망: 대시 직후 공격력 +30%% (%.2f)" % p.hitbox.damage_mult)
	await _wait_seconds(p.movement.dash_duration + 0.5)
	_check(is_equal_approx(p.hitbox.damage_mult, 1.0), "반응 신경망: 시간이 지나면 원래대로")
	await _cleanup()


func _test_data_intake() -> void:
	var p: Player = await _setup_player()
	_equip_only(&"data_intake", 1)
	await _frames(2)
	p.collect_data(100)
	_check(GameState.data == 120, "데이터 흡입기 Lv1: 획득 +20%% (%d)" % GameState.data)
	await _cleanup()


func _test_shock_absorber() -> void:
	var p: Player = await _setup_player()
	_equip_only(&"shock_absorber", 1)
	await _frames(2)
	_check(is_equal_approx(p.knockback.knockback_mult, 0.5), "충격 흡수기 Lv1: 넉백 -50%")
	_equip_only(&"shock_absorber", 3)
	await _frames(2)
	_spawn(GUARD, Vector2(60, FLOOR_Y))
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	await _frames(1)
	_check(p.health.hp < p.health.max_hp and p.state_machine.get_state_name() != &"Hurt", "충격 흡수기 Lv3: 피격 경직 없음 (%s)" % p.state_machine.get_state_name())
	await _cleanup()


func _test_overclock() -> void:
	var p: Player = await _setup_player()
	_equip_only(&"overclock_chip", 1)
	await _frames(2)
	_check(is_equal_approx(p.hitbox.damage_mult, 1.4), "오버클럭 칩: 공격력 +40%")
	_spawn(GUARD, Vector2(60, FLOOR_Y))
	await _wait_until(func() -> bool: return p.health.hp < p.health.max_hp)
	_check(p.health.max_hp - p.health.hp == 40, "오버클럭 칩: 받는 피해 2배 (20 → %d)" % (p.health.max_hp - p.health.hp))
	await _cleanup()


func _test_weapon_swap() -> void:
	var p: Player = await _setup_player()
	GameState.acquire_weapon(&"mono_wire")
	GameState.equip_weapon(&"mono_wire")
	await _frames(2)
	_check(p.weapon.id == &"mono_wire" and p.weapon.combo.size() == 2, "무기 교체: 단분자 와이어 2연격")
	var bag := _spawn(SANDBAG_SCENE, Vector2(90, FLOOR_Y)) as Sandbag
	await _frames(4)
	await _tap(&"attack")
	await _wait_until(func() -> bool: return bag.health.hp < bag.health.max_hp)
	_check(bag.health.max_hp - bag.health.hp == 14, "단분자 와이어: 사거리 96, 1타 피해 14")
	var x_before: float = bag.global_position.x
	await _tap(&"attack")
	await _wait_until(func() -> bool: return bag.health.hp <= bag.health.max_hp - 36)
	await _frames(20)
	_check(bag.global_position.x < x_before - 4.0, "단분자 와이어: 2타째 끌어당김 (%.0f → %.0f)" % [x_before, bag.global_position.x])
	await _cleanup()


# --- 중계기·잔해 ---

func _test_relay() -> void:
	var p: Player = await _setup_player()
	var relay := Relay.new()
	relay.relay_id = &"test_relay"
	relay.position = Vector2(20, FLOOR_Y)
	add_child(relay)
	p.health.hp = 30
	p.energy.set_value(0.0)
	var respawned: Array[bool] = [false]
	EventBus.relay_activated.connect(func(_id: StringName) -> void: respawned[0] = true, CONNECT_ONE_SHOT)
	await _frames(4)
	await _tap(&"interact")
	await _wait_until(func() -> bool: return respawned[0])
	_check(p.health.hp == p.health.max_hp, "중계기: 내구도 전부 회복")
	_check(is_equal_approx(p.energy.value, 50.0), "중계기: 연산력 50")
	_check(p.respawn_position == relay.global_position, "중계기: 재접속 지점 등록")
	_check(&"test_relay" in GameState.activated_relays, "중계기: 활성화 기록")
	get_tree().paused = false
	await _cleanup()


func _test_wreck() -> void:
	var p: Player = await _setup_player()
	GameState.add_data(120)
	p.health.hp = 10
	var guard := _spawn(GUARD, Vector2(60, FLOOR_Y)) as Enemy
	await _wait_until(func() -> bool: return p.is_dead())
	_check(GameState.has_wreck() and GameState.wreck["data"] == 120 and GameState.data == 0, "의체 잔해: 데이터 전부 잔해에 남음")
	guard.queue_free()
	await _wait_until(func() -> bool: return not p.is_dead())
	GameState.add_data(30)
	_check(GameState.recover_wreck() == 120 and GameState.data == 150, "의체 잔해: 회수")

	GameState.create_wreck(Vector2.ZERO)
	GameState.add_data(10)
	GameState.create_wreck(Vector2.ONE)
	_check(GameState.wreck["data"] == 10, "의체 잔해: 회수 전 다시 파괴되면 이전 데이터 소실")
	await _cleanup()


# --- 헬퍼 ---

func _equip_only(id: StringName, level: int) -> void:
	for equipped: StringName in GameState.equipped_parts.duplicate():
		GameState.unequip_part(equipped)
	if not GameState.has_part(id):
		GameState.acquire_part(id)
	GameState.owned_parts[id] = level
	GameState.equip_part(id)


func _setup_player() -> Player:
	HitStop.cancel()
	GameState.reset()
	GameState.unlock_skill(&"railgun")
	GameState.unlock_skill(&"hack")
	var body := StaticBody2D.new()
	body.position = Vector2(0, FLOOR_Y + 20)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)
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


func _cleanup() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump", &"dash", &"attack", &"fire", &"hack", &"interact"]:
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
