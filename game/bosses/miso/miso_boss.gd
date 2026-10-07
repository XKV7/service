class_name MisoBoss
extends Boss
## 보스 2. 광고 AI '미소'. 본체는 홀로그램이라 평소에는 피해가 들어가지 않는다.
## 광장의 투사기를 하나 부술 때마다 크게 흔들리며 잠깐 본체에 피해가 들어간다.
## 2페이즈에는 화면 일부가 글리치로 가려진다. (조작 방해는 없다)

@export var floor_y: float = 320.0
@export var arena_left: float = 0.0
@export var arena_right: float = 640.0
## 투사기 파괴 후 본체에 피해가 들어가는 시간 (초)
@export var window_time: float = 6.0
@export var glitch_interval: float = 4.0
@export var glitch_rects: int = 3
@export var glitch_time: float = 0.5
@export var glitch_color: Color = Color(1.0, 0.3, 0.8, 0.55)
@export var glitch_max_size: Vector2 = Vector2(220, 90)
@export var crack_color: Color = Color(0.1, 0.05, 0.1, 1.0)

var _glitch_timer: float = 0.0
var _glitch_layer: CanvasLayer

@onready var body_hurtbox: HurtboxComponent = %BodyHurtbox
@onready var crack: ColorRect = %Crack


func _ready() -> void:
	super._ready()
	set_vulnerable(false)
	crack.visible = false
	_glitch_layer = CanvasLayer.new()
	_glitch_layer.layer = 20
	add_child(_glitch_layer)
	brain.phase_changed.connect(_on_phase_changed)
	_connect_projectors.call_deferred()


func _connect_projectors() -> void:
	for node: Node in get_tree().get_nodes_in_group(MisoProjector.GROUP):
		(node as MisoProjector).destroyed.connect(open_window)


func is_vulnerable() -> bool:
	return body_hurtbox.monitorable


func set_vulnerable(enabled: bool) -> void:
	body_hurtbox.set_deferred(&"monitorable", enabled)
	# set_deferred 전에도 바로 읽을 수 있게 즉시 반영한다.
	body_hurtbox.monitorable = enabled


## 투사기가 부서지면 본체가 흔들리며 피해를 받는다.
func open_window() -> void:
	if is_defeated() or state_machine.get_state_name() == &"Dormant":
		return
	state_machine.transition_to(&"Vulnerable")


func _on_phase_changed(_index: int) -> void:
	crack.visible = true
	EventBus.toast_requested.emit("「지금… 바로… 우리를… 사세요…」")


func _process(delta: float) -> void:
	if brain.phase_index < 1 or is_defeated() or state_machine.get_state_name() == &"Dormant":
		return
	_glitch_timer -= delta
	if _glitch_timer <= 0.0:
		_glitch_timer = glitch_interval
		_spawn_glitch()


func _spawn_glitch() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	for i: int in glitch_rects:
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size = Vector2(randf_range(40.0, glitch_max_size.x), randf_range(10.0, glitch_max_size.y))
		rect.position = Vector2(randf_range(0.0, view.x - rect.size.x), randf_range(0.0, view.y - rect.size.y))
		rect.color = glitch_color
		_glitch_layer.add_child(rect)
		get_tree().create_timer(glitch_time).timeout.connect(rect.queue_free)


func _on_died() -> void:
	super._on_died()
	for group: StringName in [PopupAd.GROUP, &"miso_summon"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			node.queue_free()
