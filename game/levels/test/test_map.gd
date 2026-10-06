extends Node2D
## M1 이동 테스트 맵. 플랫폼은 Rect2 목록으로부터 _ready()에서 생성한다.

@export var platforms: Array[Rect2] = []
@export var platform_color: Color = Color(0.16, 0.18, 0.32, 1.0)
@export var platform_edge_color: Color = Color(0.0, 1.0, 0.9, 1.0)
## 플랫폼 윗면 강조선 두께 (px)
@export var edge_thickness: float = 2.0
## 이 높이 아래로 떨어지면 피해를 받고 안전 지점으로 돌아간다 (px)
@export var kill_y: float = 800.0
## 월드 물리 레이어 번호 (Project Settings의 "world")
@export_flags_2d_physics var world_layer: int = 1

@onready var player: Player = %Player
@onready var debug_label: Label = %DebugLabel

func _ready() -> void:
	player.respawn_position = player.global_position
	for rect: Rect2 in platforms:
		_build_platform(rect)
	GameState.wreck_changed.connect(func() -> void: BodyWreck.sync(self))
	BodyWreck.sync(self)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > kill_y and not player.is_dead():
		player.take_environment_damage(player.combat.pit_damage)


func _process(_delta: float) -> void:
	debug_label.text = "내구도: %d/%d  연산력: %.0f  데이터: %d\n상태: %s\n속도: (%.0f, %.0f)\n대시 쿨다운: %.2f\n무적: %s" % [
		player.health.hp, player.health.max_hp, player.energy.value, GameState.data,
		player.state_machine.get_state_name(),
		player.velocity.x, player.velocity.y,
		player.get_dash_cooldown_left(),
		"O" if player.is_invulnerable else "-",
	]


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
	body.add_child(fill)

	var edge := ColorRect.new()
	edge.color = platform_edge_color
	edge.size = Vector2(rect.size.x, edge_thickness)
	edge.position = -rect.size * 0.5
	body.add_child(edge)

	add_child(body)
