class_name BossArena
extends LevelBase
## 보스 아레나. 잠시 뒤 보스전을 시작하고, 플레이어가 파괴되면 아레나를 처음부터 다시 시작한다.
## 보스를 쓰러뜨리면 출구가 열린다.

@export var boss: Boss
@export var exit_gate: SceneGate
## 보스전 시작까지 (초)
@export var start_delay: float = 1.2
## 보스전 시작 전 대사 (한 번만)
@export var intro_dialogue: DialogueData
## 비워 두지 않으면 처치 대사가 끝난 뒤 이 씬으로 바로 넘어간다. (최종 보스 → 엔딩)
@export_file("*.tscn") var after_defeat_scene: String = ""


func _ready() -> void:
	super._ready()
	exit_gate.enabled = false
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_respawned.connect(_on_player_respawned)
	if GameState.is_boss_defeated(boss.boss_id):
		boss.queue_free()
		exit_gate.enabled = true
		return
	get_tree().create_timer(start_delay, false).timeout.connect(_begin)


func _begin() -> void:
	if not Story.has_seen(intro_dialogue):
		await Story.play_and_wait(intro_dialogue)
	if is_instance_valid(boss):
		boss.start()


func _on_boss_defeated(_id: StringName) -> void:
	exit_gate.enabled = true
	if after_defeat_scene == "":
		return
	while Story.is_playing():
		await Story.dialogue_finished
	SceneGate.travel(get_tree(), after_defeat_scene)


func _on_player_respawned() -> void:
	# 보스전은 처음부터 다시 한다.
	SceneLoader.reload_scene()
