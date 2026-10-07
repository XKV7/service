extends Node
## 스테이지 헤드리스 테스트. 씬 연결, 부품 배치, 숨겨진 공간 기믹, 스테이지 함정,
## 그리고 실제 지형에서 어려운 구간(틈·발판)을 입력만으로 건널 수 있는지 확인한다.
## 실행: godot --headless --path . res://tests/test_stages.tscn

const PROLOGUE: String = "res://game/levels/prologue/prologue.tscn"
const CH1: String = "res://game/levels/ch1_subway/ch1_subway.tscn"
const CH2: String = "res://game/levels/ch2_market/ch2_market.tscn"
const CH3: String = "res://game/levels/ch3_tower/ch3_tower.tscn"
const CORE: String = "res://game/levels/ch3_tower/ch3_core.tscn"
const TRAIN_ARENA: String = "res://game/bosses/train/train_arena.tscn"
const MISO_ARENA: String = "res://game/bosses/miso/miso_arena.tscn"
const ARK_ARENA: String = "res://game/bosses/ark/ark_arena.tscn"
const END_SCREEN: String = "res://game/cutscenes/ending.tscn"
const PROBE_ATTACK: AttackData = preload("res://data/attacks/blade_1.tres")
const RAIL_ATTACK: AttackData = preload("res://data/attacks/railgun_beam.tres")
const WAIT_LIMIT: int = 600
## 최대 높이까지 뛰려고 점프를 누르고 있는 시간 (초)
const JUMP_HOLD_TIME: float = 0.4

var _failures: int = 0
var _level: Node


func _ready() -> void:
	# 대사 장면은 멈춤 없이 바로 넘긴다.
	Story.auto_skip = true
	_run.call_deferred()


func _run() -> void:
	_test_flow_links()
	_test_pickup_placement()
	await _test_fake_wall()
	await _test_rail_switch()
	await _test_holo_platform()
	await _test_surveillance_camera()
	await _test_cargo_train()
	await _test_hp_carry()
	await _test_traversal()
	HitStop.cancel()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 연결·배치 ---

func _test_flow_links() -> void:
	var chain: Array = [[PROLOGUE, CH1], [CH1, TRAIN_ARENA], [CH2, MISO_ARENA], [CORE, ARK_ARENA]]
	for link: Array in chain:
		_check(_find_exit_target(link[0]) == link[1], "연결: %s → %s" % [link[0].get_file(), link[1].get_file()])
	var gates: Array = [[TRAIN_ARENA, CH2], [MISO_ARENA, CH3], [CH3, CORE], [ARK_ARENA, END_SCREEN]]
	for link: Array in gates:
		_check(link[1] in _find_gate_targets(link[0]), "연결: %s → %s" % [link[0].get_file(), link[1].get_file()])
	for path: String in [PROLOGUE, CH1, CH2, CH3, CORE]:
		var scene: Node = (load(path) as PackedScene).instantiate()
		var relays: int = scene.find_children("*", "Relay", true, false).size()
		_check(relays >= 2, "%s: 중계기 %d개" % [path.get_file(), relays])
		scene.free()


func _test_pickup_placement() -> void:
	# GDD 10장 지역별 획득 목록
	var expected: Dictionary = {
		PROLOGUE: [&"accel_actuator"],
		CH1: [&"railgun", &"armor_plate", &"absorb_circuit", &"slot_module"],
		CH2: [&"mono_wire", &"overcharge_coil", &"cooling_fin", &"reflex_net"],
		CH3: [&"shock_absorber", &"overclock_chip"],
	}
	for path: String in expected:
		var scene: Node = (load(path) as PackedScene).instantiate()
		var ids: Array = []
		for node: Node in scene.find_children("*", "ItemPickup", true, false):
			ids.append((node as ItemPickup).item_id)
		scene.free()
		var missing: Array = (expected[path] as Array).filter(func(id: StringName) -> bool: return not id in ids)
		_check(missing.is_empty(), "%s 획득물 %s" % [path.get_file(), ids])


# --- 숨겨진 공간 ---

func _test_fake_wall() -> void:
	GameState.reset()
	var wall := FakeWall.new()
	wall.secret_id = &"test_wall"
	add_child(wall)
	await _frames(2)
	var hurtbox := wall.find_children("*", "HurtboxComponent", true, false)[0] as HurtboxComponent
	for i: int in 2:
		_hit(hurtbox, PROBE_ATTACK)
	_check(is_instance_valid(wall) and not wall.is_queued_for_deletion(), "가짜 벽: 2번으로는 안 부서짐")
	_hit(hurtbox, RAIL_ATTACK)
	await _frames(1)
	_check(not is_instance_valid(wall) or wall.is_queued_for_deletion(), "가짜 벽: 3번째에 부서짐 (공격 세기와 무관)")
	_check(GameState.is_secret_open(&"test_wall"), "가짜 벽: 열린 기록")
	var again := FakeWall.new()
	again.secret_id = &"test_wall"
	add_child(again)
	await _frames(1)
	_check(not is_instance_valid(again) or again.is_queued_for_deletion(), "가짜 벽: 한 번 부순 벽은 다시 안 생김")
	await _cleanup()


func _test_rail_switch() -> void:
	GameState.reset()
	var player := await _spawn_player(Vector2(0, 300))
	var shutter := Shutter.new()
	shutter.secret_id = &"test_shutter"
	shutter.position = Vector2(200, 220)
	add_child(shutter)
	var sw := RailSwitch.new()
	sw.shutter = shutter
	sw.position = Vector2(30, 272)
	add_child(sw)
	await _frames(3)
	# 근접 공격은 hologram 레이어의 스위치에 닿지 않는다.
	await _tap(&"attack")
	await _frames(20)
	_check(not sw.is_on(), "레일건 스위치: 근접 공격으로는 작동 안 함")
	GameState.unlock_skill(&"railgun")
	player.energy.set_value(25.0)
	Input.action_press(&"fire")
	await _wait_seconds(0.9)
	Input.action_release(&"fire")
	await _wait_until(func() -> bool: return sw.is_on())
	_check(sw.is_on() and GameState.is_secret_open(&"test_shutter"), "레일건 스위치: 레일건으로 작동, 셔터 열림")
	await _cleanup()


# --- 스테이지 함정 ---

func _test_holo_platform() -> void:
	var holo := HoloPlatform.new()
	add_child(holo)
	await _frames(2)
	_check(holo.is_solid(), "홀로그램 발판: 처음엔 켜짐")
	await _wait_seconds(holo.on_time + 0.1)
	_check(not holo.is_solid(), "홀로그램 발판: 꺼짐")
	await _wait_seconds(holo.off_time)
	_check(holo.is_solid(), "홀로그램 발판: 다시 켜짐")
	await _cleanup()


func _test_surveillance_camera() -> void:
	GameState.reset()
	var player := await _spawn_player(Vector2(0, 300))
	var cam := SurveillanceCamera.new()
	cam.drone_scene = preload("res://game/enemies/drone/drone.tscn")
	cam.sweep_angle = 0.0
	cam.position = Vector2(0, 150)
	add_child(cam)
	await _wait_until(func() -> bool: return get_tree().get_nodes_in_group(&"enemy").size() > 0)
	_check(get_tree().get_nodes_in_group(&"enemy").size() == 2, "감시 카메라: 발각 시 드론 2기 호출")
	await _cleanup()

	player = await _spawn_player(Vector2(0, 300))
	cam = SurveillanceCamera.new()
	cam.drone_scene = preload("res://game/enemies/drone/drone.tscn")
	cam.sweep_angle = 0.0
	cam.position = Vector2(0, 150)
	add_child(cam)
	await _frames(1)
	cam._stun.stun(1.0)
	await _wait_seconds(cam.detect_time + 0.3)
	_check(get_tree().get_nodes_in_group(&"enemy").is_empty() and cam.is_disabled(), "감시 카메라: 시스템 정지 중에는 꺼짐")
	await _cleanup()


func _test_cargo_train() -> void:
	GameState.reset()
	var player := await _spawn_player(Vector2(300, 300))
	var train := CargoTrain.new()
	train.attack = preload("res://data/attacks/cargo_train.tres")
	train.track_length = 600.0
	train.start_delay = 0.2
	train.position = Vector2(0, 300)
	add_child(train)
	await _wait_until(func() -> bool: return player.health.hp < player.health.max_hp)
	_check(player.health.max_hp - player.health.hp == 40, "화물차: 선로 위면 피해 40")
	await _cleanup()


func _test_hp_carry() -> void:
	GameState.reset()
	SceneLoader.transfer = {"player_hp": 55, "player_energy": 30.0}
	_level = (load(CH1) as PackedScene).instantiate()
	add_child(_level)
	await _frames(5)
	var p: Player = _level.player
	_check(p.health.hp == 55 and is_equal_approx(p.energy.value, 30.0), "구역 이동: 내구도·연산력 이어받기")
	await _cleanup()


# --- 지형 통과 ---

func _test_traversal() -> void:
	# [레벨, 시작 위치, 동작 목록, 성공 조건 설명, 성공 조건]
	# 동작: ["hold", 액션] / ["release", 액션] / ["jump_at_x", x] / ["dash_after", 초] / ["wait", 초] / ["tap", 액션]
	# 작은 발판은 방향키를 계속 누르면 지나치므로 잠깐만 누른다.
	var right_jump: Array = [["hold", &"move_right"], ["tap", &"jump"], ["wait", 0.35], ["release", &"move_right"], ["wait", 0.7]]
	var left_jump: Array = [["hold", &"move_left"], ["tap", &"jump"], ["wait", 0.35], ["release", &"move_left"], ["wait", 0.7]]
	var on_floor_at := func(min_x: float, max_x: float, y: float) -> Callable:
		# 몸 절반(9px)이 걸쳐 있어도 서 있는 것으로 본다.
		return func(p: Player) -> bool:
			return p.is_on_floor() and absf(p.global_position.y - y) <= 1.5 and p.global_position.x >= min_x - 9.0 and p.global_position.x <= max_x + 9.0
	var cases: Array = [
		[PROLOGUE, Vector2(380, 299), [["hold", &"move_right"], ["jump_at_x", 405.0], ["wait", 0.8], ["release", &"move_right"]],
			"프롤로그 블록 넘기", func(p: Player) -> bool: return p.global_position.x > 480.0 and p.is_on_floor()],
		[PROLOGUE, Vector2(700, 299), [["hold", &"move_right"], ["jump_at_x", 750.0], ["wait", 1.0], ["release", &"move_right"]],
			"프롤로그 첫 틈 (100px)", func(p: Player) -> bool: return p.global_position.x > 860.0 and p.is_on_floor()],
		[PROLOGUE, Vector2(1100, 299), [["hold", &"move_right"], ["jump_at_x", 1190.0], ["dash_after", 0.25], ["wait", 1.0], ["release", &"move_right"]],
			"프롤로그 대시 틈 (200px)", func(p: Player) -> bool: return p.global_position.x > 1400.0 and p.is_on_floor()],
		[CH1, Vector2(1640, 299), [["hold", &"move_right"], ["jump_at_x", 1690.0], ["wait", 1.0], ["release", &"move_right"]],
			"1장 틈 (120px)", func(p: Player) -> bool: return p.global_position.x > 1820.0 and p.is_on_floor()],
		[CH1, Vector2(1920, 299), [["hold", &"move_right"], ["jump_at_x", 1990.0], ["dash_after", 0.25], ["wait", 1.0], ["release", &"move_right"]],
			"1장 대시 틈 (200px)", func(p: Player) -> bool: return p.global_position.x > 2200.0 and p.is_on_floor()],
		[CH1, Vector2(2700, 299), [["hold", &"move_right"], ["jump_at_x", 2760.0], ["wait", 0.5], ["release", &"move_right"], ["wait", 0.3],
			["hold", &"move_right"], ["wait", 0.2], ["release", &"move_right"], ["wait", 0.3]],
			"1장 강화 장갑판 발판", func(p: Player) -> bool: return GameState.has_part(&"armor_plate")],
		[CH1, Vector2(620, 299), [["hold", &"move_right"], ["jump_at_x", 680.0], ["wait", 0.5], ["release", &"move_right"], ["wait", 0.3]],
			"1장 감전 선로 위 발판에 오르기", on_floor_at.call(730.0, 870.0, 244.0)],
		[CH1, Vector2(840, 243), [["hold", &"move_right"], ["tap", &"jump"], ["wait", 1.0], ["release", &"move_right"]],
			"1장 발판에서 선로 건너편으로", func(p: Player) -> bool: return p.global_position.x > 900.0 and p.is_on_floor() and p.health.hp == p.health.max_hp],
		[CH2, Vector2(3530, 359), [["open", &"ch2_reflex_shutter"], ["tap", &"jump"], ["wait", 0.3], ["hold", &"move_right"], ["wait", 0.6], ["release", &"move_right"]],
			"2장 지하 비밀 방에서 나오기", func(p: Player) -> bool: return p.global_position.y <= 301.0 and p.is_on_floor()],
		[CH2, Vector2(1300, 299), right_jump, "2장 간판 1단 (바닥 → 252)", on_floor_at.call(1330.0, 1390.0, 252.0)],
		[CH2, Vector2(1385, 251), right_jump, "2장 간판 2단 (252 → 204)", on_floor_at.call(1430.0, 1490.0, 204.0)],
		[CH2, Vector2(1435, 203), left_jump, "2장 간판 3단 (204 → 156)", on_floor_at.call(1330.0, 1390.0, 156.0)],
		[CH2, Vector2(1385, 155), right_jump, "2장 간판 4단 (156 → 108)", on_floor_at.call(1430.0, 1490.0, 108.0)],
		[CH2, Vector2(1485, 107), [["hold", &"move_right"], ["tap", &"jump"], ["wait", 1.0], ["release", &"move_right"]], "2장 옥상 (108 → 60)", on_floor_at.call(1500.0, 1920.0, 60.0)],
		[CH3, Vector2(1425, 299), [["hold", &"move_right"], ["tap", &"jump"], ["wait", 0.3], ["release", &"move_right"], ["wait", 0.7]],
			"3장 수직 통로 1단", on_floor_at.call(1450.0, 1530.0, 240.0)],
		[CH3, Vector2(1510, 239), [["hold", &"move_right"], ["tap", &"jump"], ["wait", 0.45], ["release", &"move_right"], ["wait", 0.6]],
			"3장 수직 통로 2단", on_floor_at.call(1590.0, 1660.0, 180.0)],
		[CH3, Vector2(1600, 179), [["hold", &"move_left"], ["tap", &"jump"], ["wait", 0.45], ["release", &"move_left"], ["wait", 0.6]],
			"3장 수직 통로 3단", on_floor_at.call(1450.0, 1520.0, 120.0)],
		[CH3, Vector2(1650, -61), [["hold", &"move_right"], ["tap", &"jump"], ["wait", 0.6], ["release", &"move_right"]],
			"3장 수직 통로 꼭대기 → 위층", on_floor_at.call(1700.0, 3600.0, -120.0)],
	]
	for c: Array in cases:
		await _run_case(c[0], c[1], c[2], c[3], c[4])


func _run_case(level_path: String, start: Vector2, actions: Array, label: String, success: Callable) -> void:
	GameState.reset()
	_level = (load(level_path) as PackedScene).instantiate()
	add_child(_level)
	await _frames(2)
	# 적은 치우고 지형만 본다.
	for spawn: Node in _level.find_children("*", "EnemySpawnPoint", true, false):
		spawn.queue_free()
	for enemy: Node in get_tree().get_nodes_in_group(&"enemy"):
		enemy.queue_free()
	var p: Player = _level.player
	p.global_position = start
	p.velocity = Vector2.ZERO
	await _frames(10)
	for action: Array in actions:
		match action[0]:
			"hold":
				Input.action_press(action[1])
			"release":
				Input.action_release(action[1])
			"tap":
				if action[1] == &"jump":
					_hold_jump()
					await get_tree().physics_frame
				else:
					await _tap(action[1])
			"wait":
				await _wait_seconds(action[1])
			"open":
				# 숨겨진 공간이 열린 상태를 가정한다.
				GameState.open_secret(action[1])
				for node: Node in _level.find_children("*", "Shutter", true, false):
					node.queue_free()
				await get_tree().physics_frame
			"jump_at_x":
				await _wait_until(func() -> bool: return p.global_position.x >= action[1])
				_hold_jump()
				await get_tree().physics_frame
			"dash_after":
				await _wait_seconds(action[1])
				await _tap(&"dash")
	await _frames(10)
	_check(success.call(p), "지형: %s (위치 %.0f, %.0f)" % [label, p.global_position.x, p.global_position.y])
	await _cleanup()


# --- 헬퍼 ---

func _find_exit_target(path: String) -> String:
	var scene: Node = (load(path) as PackedScene).instantiate()
	var target: String = ""
	for node: Node in scene.find_children("*", "StageExit", true, false):
		target = (node as StageExit).target_scene
	scene.free()
	return target


func _find_gate_targets(path: String) -> Array:
	var scene: Node = (load(path) as PackedScene).instantiate()
	var targets: Array = []
	for node: Node in scene.find_children("*", "SceneGate", true, false):
		targets.append((node as SceneGate).target_scene)
	scene.free()
	return targets


func _spawn_player(pos: Vector2) -> Player:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 320)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4000, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	floor_body.add_child(col)
	add_child(floor_body)
	var p := (preload("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	p.position = pos + Vector2(0, -1)
	add_child(p)
	await _frames(10)
	return p


func _hit(hurtbox: HurtboxComponent, attack: AttackData) -> void:
	var probe := HitboxComponent.new()
	add_child(probe)
	probe.attack_data = attack
	hurtbox.receive_hit(probe)
	probe.queue_free()


func _cleanup() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump", &"dash", &"attack", &"fire", &"hack", &"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	for child: Node in get_children():
		child.queue_free()
	_level = null
	HitStop.cancel()
	await _frames(3)


## 점프를 끝까지 누르고 있다가 뗀다 (짧게 누르면 낮게 뛰므로). 기다리지 않고 바로 돌아온다.
func _hold_jump() -> void:
	Input.action_press(&"jump")
	get_tree().create_timer(JUMP_HOLD_TIME, true, true).timeout.connect(Input.action_release.bind(&"jump"))


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
