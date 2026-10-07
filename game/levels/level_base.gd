class_name LevelBase
extends Node2D
## 레벨 공통: 플랫폼 생성, 구덩이 낙하 처리, 의체 잔해 배치, 재접속 지점 초기화.
## 플랫폼은 Rect2 목록으로부터 _ready()에서 만든다.

@export var platforms: Array[Rect2] = []
@export var platform_color: Color = Color(0.16, 0.18, 0.32, 1.0)
@export var platform_edge_color: Color = Color(0.0, 1.0, 0.9, 1.0)
## 플랫폼 윗면 강조선 두께 (px)
@export var edge_thickness: float = 2.0
## 이 높이 아래로 떨어지면 피해를 받고 안전 지점으로 돌아간다 (px)
@export var kill_y: float = 800.0
## 월드 물리 레이어 번호 (Project Settings의 "world")
@export_flags_2d_physics var world_layer: int = 1
## 들어올 때 보여줄 구역 이름 (비우면 안 보여준다)
@export var title: String = ""

@onready var player: Player = %Player


func _ready() -> void:
	player.respawn_position = player.global_position
	for rect: Rect2 in platforms:
		_build_platform(rect)
	GameState.wreck_changed.connect(_sync_wreck)
	_sync_wreck()
	GameState.current_scene = scene_file_path
	_apply_transfer.call_deferred()
	if title != "":
		EventBus.toast_requested.emit(title)


## 이전 구역에서 넘어온 내구도·연산력을 이어받는다. (부품 적용 뒤에 실행)
func _apply_transfer() -> void:
	var data: Dictionary = SceneLoader.transfer
	if data.has("player_hp"):
		player.health.hp = clampi(int(data["player_hp"]), 1, player.health.max_hp)
		player.health.health_changed.emit(player.health.hp, player.health.max_hp)
	if data.has("player_energy"):
		player.energy.set_value(float(data["player_energy"]))
	SceneLoader.transfer = {}


func _physics_process(_delta: float) -> void:
	if player.global_position.y > kill_y and not player.is_dead():
		player.take_environment_damage(player.combat.pit_damage)


func _sync_wreck() -> void:
	BodyWreck.sync(self)


func _build_platform(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = world_layer
	body.collision_mask = 0
	body.position = rect.get_center()

	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	var fill := ColorRect.new()
	fill.color = platform_color
	fill.size = rect.size
	fill.position = -rect.size * 0.5
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(fill)

	var edge := ColorRect.new()
	edge.color = platform_edge_color
	edge.size = Vector2(rect.size.x, edge_thickness)
	edge.position = -rect.size * 0.5
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(edge)

	add_child(body)
