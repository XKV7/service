class_name BossArena
extends LevelBase
## 보스 아레나. 잠시 뒤 보스전을 시작하고, 플레이어가 파괴되면 아레나를 처음부터 다시 시작한다.
## 보스를 쓰러뜨리면 출구가 열린다.

@export var boss: Boss
@export var exit_gate: SceneGate
## 보스전 시작까지 (초)
@export var start_delay: float = 1.2


func _ready() -> void:
	super._ready()
	exit_gate.enabled = false
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.player_respawned.connect(_on_player_respawned)
	if GameState.is_boss_defeated(boss.boss_id):
		boss.queue_free()
		exit_gate.enabled = true
		return
	get_tree().create_timer(start_delay, false).timeout.connect(boss.start)


func _on_boss_defeated(_id: StringName) -> void:
	exit_gate.enabled = true


func _on_player_respawned() -> void:
	# 보스전은 처음부터 다시 한다.
	SceneLoader.reload_scene()
