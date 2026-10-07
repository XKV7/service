class_name ArkBoss
extends Boss
## 보스 3. ARK. 1페이즈는 ROOT를 본뜬 전투 의체로 같은 기술을 쓰는 거울 대결.
## 체력 55%에서 의체를 버리고 서버 코어로 돌아간다. 2페이즈에는 핵심 노드가 주기적으로 노출된다.

@export var floor_y: float = 300.0
@export var arena_left: float = 0.0
@export var arena_right: float = 640.0
@export var gravity: float = 1000.0
@export var max_fall_speed: float = 620.0
@export var friction: float = 1600.0
## 서버 기둥(고요의 빛 발원점) x
@export var pillar_x: float = 320.0
## 2페이즈 핵심 노드 위치 (전역)
@export var core_position: Vector2 = Vector2(320, 268)
## 2페이즈에 ARK 빛의 형상이 머무는 위치 (전역)
@export var light_form_position: Vector2 = Vector2(320, 110)
## 서버 랙 x 위치 (고요의 빛을 막아 준다)
@export var rack_xs: Array[float] = [150.0, 490.0]
@export var rack_half_width: float = 14.0
## 랙 뒤 안전 범위 (px)
@export var rack_shadow: float = 54.0
@export var core_closed_color: Color = Color(0.1, 0.25, 0.25, 1.0)
@export var core_open_color: Color = Color(0.3, 1.0, 0.9, 1.0)
## 투영체가 쓰러질 때 남기는 목소리
@export var projection_lines: PackedStringArray = ["「…집에 가고 싶어.」", "「고마워요…」", "「엄마…?」", "「여긴… 너무 조용해.」"]

## 상태가 이동을 직접 맡는 동안 true (아니면 중력·감속을 여기서 적용)
var manual_motion: bool = false
var second_form: bool = false

var _projections: Array[Node] = []

@onready var body_hurtbox: HurtboxComponent = %BodyHurtbox
@onready var core_hurtbox: HurtboxComponent = %CoreHurtbox
@onready var core_node: Node2D = %CoreNode
@onready var core_rect: ColorRect = %CoreRect
@onready var attack_hitbox: HitboxComponent = %AttackHitbox
@onready var body_visual: Node2D = %BodyVisual
@onready var light_form: Node2D = %LightForm
@onready var aim_line: Line2D = %AimLine


func _ready() -> void:
	super._ready()
	core_node.top_level = true
	core_node.global_position = core_position
	set_core_open(false)
	light_form.visible = false
	aim_line.visible = false
	brain.phase_changed.connect(_on_phase_changed)
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _physics_process(delta: float) -> void:
	if manual_motion or second_form or state_machine.get_state_name() == &"Dormant":
		return
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()


func _process(_delta: float) -> void:
	body_visual.scale.x = facing


func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func set_core_open(open: bool) -> void:
	core_hurtbox.set_deferred(&"monitorable", open)
	core_hurtbox.monitorable = open
	core_rect.color = core_open_color if open else core_closed_color


func is_core_open() -> bool:
	return core_hurtbox.monitorable


## 플레이어가 서버 랙 뒤(기둥 반대편)에 숨어 있으면 true
func is_target_covered() -> bool:
	var t: Node2D = get_target()
	if t == null:
		return true
	for rack_x: float in rack_xs:
		var side: float = signf(rack_x - pillar_x)
		var near: float = rack_x + side * rack_half_width
		var far: float = near + side * rack_shadow
		if t.global_position.x >= minf(near, far) and t.global_position.x <= maxf(near, far):
			return true
	return false


## 2페이즈 모습으로 바꾼다. (PhaseShift 상태가 호출)
func enter_second_form() -> void:
	second_form = true
	velocity = Vector2.ZERO
	global_position = light_form_position
	body_visual.visible = false
	light_form.visible = true
	body_hurtbox.set_deferred(&"monitorable", false)


func register_projection(node: Node) -> void:
	_projections.append(node)


func alive_projections() -> int:
	_projections = _projections.filter(func(n: Node) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
	return _projections.size()


func _on_phase_changed(index: int) -> void:
	if index == 1 and not is_defeated():
		state_machine.transition_to(&"PhaseShift")


func _on_enemy_killed(enemy: Node) -> void:
	if enemy in _projections:
		EventBus.toast_requested.emit(projection_lines[randi() % projection_lines.size()])


func _on_died() -> void:
	super._on_died()
	set_core_open(false)
	for node: Node in _projections:
		if is_instance_valid(node):
			node.queue_free()
