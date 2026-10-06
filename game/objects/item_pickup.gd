class_name ItemPickup
extends Area2D
## 부품·무기·스킬 획득물. 플레이어가 닿으면 얻는다. 이미 가진 것이면 나타나지 않는다.

enum Kind { PART, WEAPON, SKILL }

## 스킬 표시 이름
const SKILL_NAMES: Dictionary = {&"railgun": "차지 레일건", &"hack": "해킹: 시스템 정지"}

@export var kind: Kind = Kind.PART
@export var item_id: StringName = &""
@export var size: float = 6.0
@export var part_color: Color = Color(1.0, 0.3, 0.7, 1.0)
@export var weapon_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var skill_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var bob_height: float = 3.0
@export var bob_period: float = 1.4
## 떠 있는 높이 (발밑 기준, px)
@export var hover_height: float = 14.0
@export_flags_2d_physics var pickup_layer: int = 64
@export_flags_2d_physics var player_mask: int = 2

var _visual: Polygon2D
var _time: float = 0.0


func _ready() -> void:
	if _is_owned():
		queue_free()
		return
	collision_layer = pickup_layer
	collision_mask = player_mask
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = size * 2.0
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -hover_height)
	add_child(col)
	_visual = Polygon2D.new()
	_visual.color = [part_color, weapon_color, skill_color][kind]
	_visual.polygon = PackedVector2Array([Vector2(0, -size), Vector2(size, 0), Vector2(0, size), Vector2(-size, 0)])
	add_child(_visual)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.position = Vector2(0, -hover_height + sin(_time * TAU / bob_period) * bob_height)


func _is_owned() -> bool:
	match kind:
		Kind.PART:
			return GameState.has_part(item_id)
		Kind.WEAPON:
			return item_id in GameState.owned_weapons
		_:
			return GameState.has_skill(item_id)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var label: String
	match kind:
		Kind.PART:
			GameState.acquire_part(item_id)
			label = "부품 획득: " + GameState.get_part(item_id).display_name
		Kind.WEAPON:
			GameState.acquire_weapon(item_id)
			label = "무기 획득: " + GameState.get_weapon(item_id).display_name
		Kind.SKILL:
			GameState.unlock_skill(item_id)
			label = "스킬 해금: " + String(SKILL_NAMES.get(item_id, item_id))
	EventBus.toast_requested.emit(label)
	queue_free()
