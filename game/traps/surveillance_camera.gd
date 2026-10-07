class_name SurveillanceCamera
extends Node2D
## 감시 카메라. 좌우로 시야를 흔들며 살피다가 플레이어를 일정 시간 비추면 보안 드론을 부른다.
## 시스템 정지를 맞으면 잠시 꺼진다.

@export var drone_scene: PackedScene
## 시야 거리 (px)
@export var view_range: float = 220.0
## 시야 반각 (도)
@export var view_half_angle: float = 18.0
## 시야가 흔들리는 범위 (아래 방향 기준 좌우, 도)
@export var sweep_angle: float = 50.0
@export var sweep_period: float = 4.0
## 이 시간 이상 비춰지면 경보 (초)
@export var detect_time: float = 0.4
## 경보 후 다시 경보할 수 있을 때까지 (초)
@export var alarm_cooldown: float = 8.0
@export var drones_per_alarm: int = 2
@export var max_drones: int = 2
## 드론이 나타날 위치 (카메라 기준)
@export var drone_offsets: Array[Vector2] = [Vector2(-60, -30), Vector2(60, -30)]
## 시스템 정지로 꺼지는 시간 (초)
@export var disable_time: float = 3.0
@export var view_color: Color = Color(1.0, 0.95, 0.5, 0.12)
@export var alert_color: Color = Color(1.0, 0.25, 0.3, 0.3)
@export var body_color: Color = Color(0.75, 0.75, 0.8, 1.0)
@export_flags_2d_physics var world_mask: int = 1
@export_flags_2d_physics var hazard_layer: int = 128

var _time: float = 0.0
var _seen_time: float = 0.0
var _cooldown_left: float = 0.0
var _drones: Array[Node] = []
var _cone: Polygon2D
var _stun: StunComponent


func _ready() -> void:
	var body := ColorRect.new()
	body.size = Vector2(14, 10)
	body.position = Vector2(-7, -5)
	body.color = body_color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	_cone = Polygon2D.new()
	add_child(_cone)
	_stun = StunComponent.new()
	_stun.duration_override = disable_time
	add_child(_stun)
	var hack_target := HurtboxComponent.new()
	hack_target.collision_layer = hazard_layer
	hack_target.collision_mask = 0
	hack_target.stun = _stun
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 16)
	var col := CollisionShape2D.new()
	col.shape = shape
	hack_target.add_child(col)
	add_child(hack_target)


func is_disabled() -> bool:
	return _stun.is_stunned()


func get_view_angle() -> float:
	return PI * 0.5 + deg_to_rad(sweep_angle) * sin(_time * TAU / sweep_period)


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if is_disabled():
		_seen_time = 0.0
		return
	_time += delta
	if _can_see_player():
		_seen_time += delta
		if _seen_time >= detect_time and _cooldown_left <= 0.0:
			_alarm()
	else:
		_seen_time = 0.0


func _process(_delta: float) -> void:
	_cone.visible = not is_disabled()
	var angle: float = get_view_angle()
	var half: float = deg_to_rad(view_half_angle)
	_cone.polygon = PackedVector2Array([Vector2.ZERO,
			Vector2.RIGHT.rotated(angle - half) * view_range, Vector2.RIGHT.rotated(angle + half) * view_range])
	_cone.color = alert_color if _seen_time > 0.0 else view_color


func _can_see_player() -> bool:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null or p.is_dead():
		return false
	var target: Vector2 = p.global_position + Vector2(0, -22)
	var to_player: Vector2 = target - global_position
	if to_player.length() > view_range:
		return false
	if absf(angle_difference(get_view_angle(), to_player.angle())) > deg_to_rad(view_half_angle):
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, target, world_mask)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _alarm() -> void:
	_cooldown_left = alarm_cooldown
	EventBus.toast_requested.emit("감시 카메라에 발각! 보안 드론 호출")
	_drones = _drones.filter(func(d: Node) -> bool: return is_instance_valid(d))
	for i: int in mini(drones_per_alarm, max_drones - _drones.size()):
		var drone := drone_scene.instantiate() as Node2D
		drone.position = position + drone_offsets[i % drone_offsets.size()]
		get_parent().add_child(drone)
		_drones.append(drone)
