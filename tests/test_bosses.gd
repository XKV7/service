extends Node
## 보스 헤드리스 테스트. 패턴 선택·페이즈 전환·핵심 기믹·처치 보상을 확인한다.
## 실행: godot --headless --path . res://tests/test_bosses.tscn

const TRAIN_ARENA: PackedScene = preload("res://game/bosses/train/train_arena.tscn")
const MISO_ARENA: PackedScene = preload("res://game/bosses/miso/miso_arena.tscn")
const ARK_ARENA: PackedScene = preload("res://game/bosses/ark/ark_arena.tscn")
const PROBE_ATTACK: AttackData = preload("res://data/attacks/blade_1.tres")
## 모든 패턴이 나올 때까지 지켜보는 최대 시간 (게임 시간, 초). 패턴은 가중치 랜덤이다.
const CYCLE_SECONDS: float = 90.0
const WAIT_LIMIT: int = 900

var _failures: int = 0
var _arena: Node
var _seen: Dictionary = {}


func _ready() -> void:
	# 대사 장면은 멈춤 없이 바로 넘긴다.
	Story.auto_skip = true
	_run.call_deferred()


func _run() -> void:
	_test_brain()
	await _test_train_cycle()
	await _test_train_mechanics()
	await _test_miso()
	await _test_ark_cycle()
	await _test_ark_mechanics()
	HitStop.cancel()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- BossBrain ---

func _test_brain() -> void:
	var health := HealthComponent.new()
	health.max_hp = 100
	add_child(health)
	var brain := BossBrain.new()
	brain.health = health
	var p1 := BossPhase.new()
	p1.patterns = [&"A", &"B"]
	var p2 := BossPhase.new()
	p2.hp_ratio = 0.5
	p2.patterns = [&"C"]
	brain.phases = [p1, p2]
	add_child(brain)
	var last: StringName = &""
	var repeated: bool = false
	for i: int in 50:
		var next: StringName = brain.next_pattern()
		repeated = repeated or next == last
		last = next
	_check(not repeated, "BossBrain: 같은 패턴 연속 없음")
	health.take_damage(50)
	_check(brain.phase_index == 1 and brain.next_pattern() == &"C", "BossBrain: 체력 50%에서 2페이즈")
	brain.queue_free()
	health.queue_free()


# --- 전동차 ---

func _test_train_cycle() -> void:
	var train := await _setup(TRAIN_ARENA) as TrainBoss
	_make_invulnerable()
	await _watch_patterns(train, [&"Rush", &"Claw", &"Shock"])
	_check(_seen.has(&"Rush") and _seen.has(&"Claw") and _seen.has(&"Shock"), "전동차 1페이즈 패턴 순환 %s" % [_seen.keys()])
	train.health.take_damage(train.max_hp / 2 + 1)
	_check(train.brain.phase_index == 1, "전동차: 50%에서 2페이즈")
	await _watch_patterns(train, [&"Sparks"])
	_check(_seen.has(&"Sparks"), "전동차 2페이즈 스파크 낙하 %s" % [_seen.keys()])
	await _test_defeat(train, func() -> bool:
		return GameState.has_skill(&"hack") and GameState.has_part(&"compute_amp"), 300, "시스템 정지·연산 증폭기")
	await _cleanup()


func _test_train_mechanics() -> void:
	# 선로 위에 있으면 질주에 맞는다.
	var train := await _setup(TRAIN_ARENA) as TrainBoss
	var p: Player = _arena.player
	train.state_machine.transition_to(&"Rush")
	await _wait_until(func() -> bool: return train.core_open)
	_check(p.health.max_hp - p.health.hp == 40, "전동차 질주: 선로 위면 피해 40 (%d)" % (p.health.max_hp - p.health.hp))
	_check(train.core_open, "전동차: 정차 후 운전석 코어 열림")
	await _cleanup()

	# 승강장 위에 있으면 피할 수 있다.
	train = await _setup(TRAIN_ARENA) as TrainBoss
	p = _arena.player
	p.global_position = Vector2(130, 235)
	await _frames(10)
	train.state_machine.transition_to(&"Rush")
	await _wait_until(func() -> bool: return train.core_open)
	_check(p.health.hp == p.health.max_hp, "전동차 질주: 승강장 위면 안전")
	await _cleanup()

	# 예비동작 중 해킹하면 공격이 취소된다.
	train = await _setup(TRAIN_ARENA) as TrainBoss
	p = _arena.player
	train.state_machine.transition_to(&"Claw")
	await _frames(3)
	train.stun.stun(2.0)
	_check(train.state_machine.get_state_name() == &"Stunned", "해킹: 예비동작 중이면 경직")
	await _wait_until(func() -> bool: return train.state_machine.get_state_name() != &"Stunned")
	await _frames(30)
	_check(p.health.hp == p.health.max_hp, "해킹: 집게팔 공격 취소 (피해 없음)")
	await _cleanup()


# --- 미소 ---

func _test_miso() -> void:
	var miso := await _setup(MISO_ARENA) as MisoBoss
	_make_invulnerable()
	_check(not miso.is_vulnerable(), "미소: 평소에는 본체 무적")
	var hp_before: int = miso.health.hp
	_probe_hit(miso.body_hurtbox)
	_check(miso.health.hp == hp_before or not miso.is_vulnerable(), "미소: 투사기 전에는 피해 없음")

	var projector := _arena.get_node(^"ProjectorLeftLow") as MisoProjector
	projector.health.take_damage(projector.max_hp)
	await _frames(2)
	_check(miso.state_machine.get_state_name() == &"Vulnerable" and miso.is_vulnerable(), "미소: 투사기 파괴 → 본체 피해 시간")
	hp_before = miso.health.hp
	_probe_hit(miso.body_hurtbox)
	_check(miso.health.hp < hp_before, "미소: 흔들리는 동안 본체에 피해")
	await _wait_until(func() -> bool: return miso.state_machine.get_state_name() != &"Vulnerable")
	_check(not miso.is_vulnerable(), "미소: 시간이 지나면 다시 무적")

	await _watch_patterns(miso, [&"Beam", &"Popup", &"Bomb"])
	_check(_seen.has(&"Beam") and _seen.has(&"Popup") and _seen.has(&"Bomb"), "미소 1페이즈 패턴 순환 %s" % [_seen.keys()])
	miso.health.take_damage(miso.health.hp - miso.max_hp / 2 + 1)
	_check(miso.brain.phase_index == 1, "미소: 50%에서 2페이즈")
	await _watch_patterns(miso, [&"Summon"])
	_check(_seen.has(&"Summon"), "미소 2페이즈 홀로 망령 소환 %s" % [_seen.keys()])
	_check(get_tree().get_nodes_in_group(&"miso_summon").size() <= 2, "미소: 소환은 동시에 2기까지")
	await _test_defeat(miso, func() -> bool: return GameState.has_part(&"data_intake"), 400, "데이터 흡입기")
	_check(get_tree().get_nodes_in_group(PopupAd.GROUP).is_empty(), "미소 처치: 팝업 광고 정리")
	await _cleanup()


# --- ARK ---

func _test_ark_cycle() -> void:
	var ark := await _setup(ARK_ARENA) as ArkBoss
	_make_invulnerable()
	await _watch_patterns(ark, [&"Blade", &"Dash", &"Snipe", &"ReverseHack"])
	_check(_seen.has(&"Blade") and _seen.has(&"Dash") and _seen.has(&"Snipe") and _seen.has(&"ReverseHack"), "ARK 1페이즈 패턴 순환 %s" % [_seen.keys()])
	ark.health.take_damage(ark.health.hp - int(ark.max_hp * 0.55))
	await _frames(2)
	_check(ark.state_machine.get_state_name() == &"PhaseShift", "ARK: 55%에서 페이즈 전환")
	var hp_before: int = ark.health.hp
	await _frames(5)
	_probe_hit(ark.body_hurtbox)
	_check(ark.health.hp == hp_before, "ARK 페이즈 전환 중 무적")
	await _wait_until(func() -> bool: return ark.state_machine.get_state_name() != &"PhaseShift")
	_check(ark.second_form, "ARK: 서버 코어 형태")
	await _watch_patterns(ark, [&"Expose", &"Projections", &"DataStorm", &"Light"])
	_check(_seen.has(&"Expose") and _seen.has(&"Projections") and _seen.has(&"DataStorm") and _seen.has(&"Light"), "ARK 2페이즈 패턴 순환 %s" % [_seen.keys()])
	await _test_defeat(ark, func() -> bool: return GameState.is_boss_defeated(&"ark"), 0, "처치 기록")
	await _cleanup()


func _test_ark_mechanics() -> void:
	# 역해킹 범위 안이면 이동 속도 감소
	var ark := await _setup(ARK_ARENA) as ArkBoss
	var p: Player = _arena.player
	p.global_position = ark.global_position + Vector2(-60, -1)
	await _frames(4)
	ark.state_machine.transition_to(&"ReverseHack")
	await _wait_until(func() -> bool: return p.has_timed_modifier(&"debuff:ark_reverse_hack"))
	_check(is_equal_approx(p.stats.get_value(Player.STAT_MOVE_SPEED_MULT), 0.5), "ARK 역해킹: 이동 속도 50%")
	# 다음 패턴으로 역해킹이 또 나오면 감속이 갱신되므로, 회복만 확인하도록 ARK를 멈춘다.
	ark.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	await _wait_seconds(2.2)
	_check(is_equal_approx(p.stats.get_value(Player.STAT_MOVE_SPEED_MULT), 1.0), "ARK 역해킹: 2초 뒤 회복")
	await _cleanup()

	# 고요의 빛: 랙 뒤면 안전, 밖이면 피해 40
	for case: Array in [[120.0, 0, "랙 뒤면 안전"], [250.0, 40, "열린 곳이면 피해 40"]]:
		ark = await _setup(ARK_ARENA) as ArkBoss
		p = _arena.player
		ark.health.take_damage(ark.health.hp - int(ark.max_hp * 0.55))
		await _wait_until(func() -> bool: return ark.second_form and ark.state_machine.get_state_name() == &"Idle")
		p.global_position = Vector2(case[0], 299)
		p.velocity = Vector2.ZERO
		await _frames(4)
		ark.state_machine.transition_to(&"Light")
		await _wait_until(func() -> bool: return ark.state_machine.get_state_name() != &"Light")
		await _frames(10)
		_check(p.health.max_hp - p.health.hp == case[1], "ARK 고요의 빛: %s (피해 %d)" % [case[2], p.health.max_hp - p.health.hp])
		if case[1] == 0:
			ark.state_machine.transition_to(&"Expose")
			await _frames(2)
			_check(ark.is_core_open(), "ARK: 핵심 노드 노출")
			var hp_before: int = ark.health.hp
			_probe_hit(ark.core_hurtbox)
			_check(ark.health.hp < hp_before, "ARK: 노출된 핵심 노드에 피해")
			await _wait_until(func() -> bool: return not ark.is_core_open())
			_check(not ark.is_core_open(), "ARK: 노출 시간이 끝나면 닫힘")
		await _cleanup()


# --- 공통 ---

func _test_defeat(boss: Boss, reward_check: Callable, data_amount: int, label: String) -> void:
	var defeated: Array[bool] = [false]
	EventBus.boss_defeated.connect(func(_id: StringName) -> void: defeated[0] = true, CONNECT_ONE_SHOT)
	var data_before: int = GameState.data
	boss.health.take_damage(boss.health.hp)
	await _frames(2)
	_check(defeated[0] and boss.state_machine.get_state_name() == &"Defeated", "%s 처치" % boss.display_name)
	_check(reward_check.call(), "%s 보상: %s" % [boss.display_name, label])
	if data_amount > 0:
		await _wait_until(func() -> bool: return GameState.data >= data_before + data_amount)
		_check(GameState.data - data_before == data_amount, "%s 보상: 데이터 %d (+%d)" % [boss.display_name, data_amount, GameState.data - data_before])


func _setup(arena_scene: PackedScene) -> Boss:
	HitStop.cancel()
	GameState.reset()
	GameState.unlock_skill(&"railgun")
	_arena = arena_scene.instantiate()
	# 처치 후 엔딩 씬으로 넘어가면 테스트 씬이 바뀌므로 끈다.
	(_arena as BossArena).after_defeat_scene = ""
	add_child(_arena)
	var boss := _arena.get_node(^"Boss") as Boss
	await _wait_until(func() -> bool: return boss.state_machine.get_state_name() == &"Idle")
	return boss


func _make_invulnerable() -> void:
	(_arena.player as Player).health.add_invulnerability(9999.0)


## expected가 모두 나오거나 seconds가 지날 때까지 보스 상태 변화를 기록한다.
func _watch_patterns(boss: Boss, expected: Array[StringName], seconds: float = CYCLE_SECONDS) -> void:
	_seen.clear()
	var on_change := func(_from: StringName, to: StringName) -> void: _seen[to] = true
	boss.state_machine.state_changed.connect(on_change)
	var time: float = 0.0
	while time < seconds and not expected.all(func(e: StringName) -> bool: return _seen.has(e)):
		await get_tree().physics_frame
		time += get_physics_process_delta_time() * Engine.time_scale
	boss.state_machine.state_changed.disconnect(on_change)


func _probe_hit(hurtbox: HurtboxComponent) -> void:
	var probe := HitboxComponent.new()
	add_child(probe)
	probe.global_position = hurtbox.global_position
	probe.attack_data = PROBE_ATTACK
	if hurtbox.monitorable:
		hurtbox.receive_hit(probe)
	probe.queue_free()


func _cleanup() -> void:
	get_tree().paused = false
	if is_instance_valid(_arena):
		_arena.queue_free()
	for child: Node in get_children():
		child.queue_free()
	HitStop.cancel()
	await _frames(3)


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
