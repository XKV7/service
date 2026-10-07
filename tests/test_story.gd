extends Node
## 스토리 헤드리스 테스트. 대사 상자, 장면 재생·기록, 기억 조각, 보스 대사, 엔딩 분기를 확인한다.
## 실행: godot --headless --path . res://tests/test_story.tscn

const PROLOGUE: PackedScene = preload("res://game/levels/prologue/prologue.tscn")
const TRAIN_ARENA: PackedScene = preload("res://game/bosses/train/train_arena.tscn")
const ARK_ARENA: PackedScene = preload("res://game/bosses/ark/ark_arena.tscn")
const ENDING: PackedScene = preload("res://game/cutscenes/ending.tscn")
const MEMORY_FRAGMENT_SCRIPT: GDScript = preload("res://game/objects/memory_fragment.gd")
const WAIT_LIMIT: int = 600

var _failures: int = 0
var _started: Array[StringName] = []


func _ready() -> void:
	Story.dialogue_started.connect(func(id: StringName) -> void: _started.append(id))
	_run.call_deferred()


func _run() -> void:
	await _test_dialogue_box()
	await _test_story_pause()
	Story.auto_skip = true
	_test_memory_data()
	await _test_story_trigger_once()
	await _test_memory_fragment()
	await _test_boss_dialogue()
	await _test_endings()
	print("결과: %s (실패 %d)" % ["통과" if _failures == 0 else "실패", _failures])
	get_tree().quit(1 if _failures > 0 else 0)


# --- 대사 상자 ---

func _make_dialogue(id: StringName, texts: Array) -> DialogueData:
	var data := DialogueData.new()
	data.id = id
	for t: String in texts:
		var line := DialogueLine.new()
		line.speaker = "ROOT"
		line.text = t
		data.lines.append(line)
	return data


func _test_dialogue_box() -> void:
	var box := DialogueBox.new()
	add_child(box)
	var done: Array[bool] = [false]
	box.finished.connect(func() -> void: done[0] = true)
	var lines: Array[int] = []
	box.line_started.connect(func(i: int) -> void: lines.append(i))
	box.start(_make_dialogue(&"t1", ["첫 번째 줄입니다", "두 번째"]))
	await _frames(2)
	_check(box.is_active() and lines == [0], "대사 상자: 첫 줄 시작")
	box.advance()
	_check(lines == [0], "대사 상자: 출력 중 누르면 줄만 완성")
	box.advance()
	_check(lines == [0, 1], "대사 상자: 다 나온 뒤 누르면 다음 줄")
	box.advance()
	box.advance()
	_check(done[0] and not box.is_active(), "대사 상자: 마지막 줄 뒤 finished")
	done[0] = false
	box.start(_make_dialogue(&"t2", ["a", "b", "c"]))
	box.skip()
	_check(done[0], "대사 상자: 건너뛰기")
	box.queue_free()
	await _frames(2)


func _test_story_pause() -> void:
	GameState.reset()
	var data := _make_dialogue(&"pause_test", ["멈춰라"])
	var finished: Array[StringName] = []
	var on_finish := func(id: StringName) -> void: finished.append(id)
	Story.dialogue_finished.connect(on_finish)
	Story.play(data)
	_check(get_tree().paused and Story.is_playing(), "Story: 대사 중 게임 멈춤")
	Story._box.skip()
	_check(not get_tree().paused and not Story.is_playing() and finished == [&"pause_test"], "Story: 끝나면 다시 진행")
	_check(GameState.has_seen(&"pause_test") and not Story.play_once(data), "Story: 본 장면은 다시 재생 안 함")
	Story.dialogue_finished.disconnect(on_finish)


# --- 기억 조각 ---

func _test_memory_data() -> void:
	var ids: Array = []
	for i: int in range(1, 9):
		var data := load("res://data/dialogue/memories/mem_%d.tres" % i) as DialogueData
		_check(data != null and data.title != "" and not data.lines.is_empty(), "기억 조각 %d: %s" % [i, data.title if data else "없음"])
		ids.append(data.id)
	_check(ids.size() == 8 and _unique(ids), "기억 조각: id 8개 모두 다름")
	var expected: Dictionary = {
		"res://game/levels/ch1_subway/ch1_subway.tscn": 3,
		"res://game/levels/ch2_market/ch2_market.tscn": 3,
		"res://game/levels/ch3_tower/ch3_tower.tscn": 1,
		"res://game/levels/ch3_tower/ch3_core.tscn": 1,
	}
	for path: String in expected:
		var scene: Node = (load(path) as PackedScene).instantiate()
		var count: int = scene.find_children("*", "MemoryFragment", true, false).size()
		scene.free()
		_check(count == expected[path], "%s 기억 조각 %d개" % [path.get_file(), count])


func _test_story_trigger_once() -> void:
	GameState.reset()
	_started.clear()
	var level := PROLOGUE.instantiate()
	add_child(level)
	await _frames(10)
	_check(&"prologue_intro" in _started, "스토리 트리거: 프롤로그 시작 대사")
	level.queue_free()
	await _frames(3)
	_started.clear()
	level = PROLOGUE.instantiate()
	add_child(level)
	await _frames(10)
	_check(not &"prologue_intro" in _started, "스토리 트리거: 다시 들어와도 한 번만")
	level.queue_free()
	await _frames(3)


func _test_memory_fragment() -> void:
	GameState.reset()
	_started.clear()
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(0, 320)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2000, 40)
	var col := CollisionShape2D.new()
	col.shape = shape
	floor_body.add_child(col)
	add_child(floor_body)
	var fragment := MEMORY_FRAGMENT_SCRIPT.new() as MemoryFragment
	fragment.dialogue = load("res://data/dialogue/memories/mem_3.tres")
	fragment.position = Vector2(40, 300)
	add_child(fragment)
	var player := (preload("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	player.position = Vector2(0, 299)
	add_child(player)
	await _frames(5)
	Input.action_press(&"move_right")
	await _wait_until(func() -> bool: return GameState.has_memory(&"mem_3"))
	Input.action_release(&"move_right")
	_check(GameState.has_memory(&"mem_3") and &"mem_3" in _started, "기억 조각: 획득하면 회상 장면 재생")
	for n: Node in [floor_body, fragment, player]:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(3)


# --- 보스 대사 ---

func _test_boss_dialogue() -> void:
	GameState.reset()
	_started.clear()
	var arena := TRAIN_ARENA.instantiate()
	add_child(arena)
	var boss := arena.get_node(^"Boss") as Boss
	await _wait_until(func() -> bool: return boss.state_machine.get_state_name() == &"Idle")
	_check(&"train_intro" in _started and boss.state_machine.get_state_name() == &"Idle", "보스: 시작 전 대사 후 전투 시작")
	boss.health.take_damage(boss.health.hp)
	await _frames(3)
	_check(&"train_defeat" in _started, "보스: 처치 후 대사")
	arena.queue_free()
	await _frames(3)

	var ark_arena := ARK_ARENA.instantiate() as BossArena
	_check(ark_arena.after_defeat_scene == "res://game/cutscenes/ending.tscn", "ARK 처치 후 엔딩으로 이동 설정")
	ark_arena.free()


# --- 엔딩 ---

func _test_endings() -> void:
	for case: Array in [[&"destroy", false], [&"control", true]]:
		GameState.reset()
		_started.clear()
		if case[1]:
			for i: int in range(1, 9):
				GameState.collect_memory(StringName("mem_%d" % i))
		var ending := ENDING.instantiate()
		add_child(ending)
		await _frames(2)
		ending.choose(case[0])
		await _wait_until(func() -> bool: return ending.is_showing_credits())
		_check(GameState.ending == case[0] and ending.is_showing_credits(), "엔딩 %s: 선택 → 크레딧" % case[0])
		_check(StringName("ending_%s" % case[0]) in _started, "엔딩 %s: 엔딩 장면 재생" % case[0])
		_check((&"ending_extra" in _started) == case[1], "엔딩 %s: 기억 조각 8개일 때만 추가 장면 (%s)" % [case[0], case[1]])
		ending.queue_free()
		await _frames(3)


# --- 헬퍼 ---

func _unique(values: Array) -> bool:
	var seen: Dictionary = {}
	for v: Variant in values:
		if seen.has(v):
			return false
		seen[v] = true
	return true


func _frames(n: int) -> void:
	for i: int in n:
		await get_tree().process_frame


func _wait_until(condition: Callable) -> void:
	for i: int in WAIT_LIMIT:
		if condition.call():
			return
		await get_tree().physics_frame


func _check(ok: bool, label: String) -> void:
	print(("  [OK] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failures += 1
