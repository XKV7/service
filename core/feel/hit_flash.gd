class_name HitFlash
extends Node
## 대상 CanvasItem(과 그 자식들)을 잠깐 흰색으로 번쩍이게 한다.

const FLASH_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")

@export var target: CanvasItem
@export var flash_color: Color = Color.WHITE
## 번쩍임이 사라지는 시간 (초)
@export var duration: float = 0.12

var _material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	if target == null:
		return
	_material = ShaderMaterial.new()
	_material.shader = FLASH_SHADER
	_material.set_shader_parameter("flash_color", flash_color)
	target.material = _material
	_share_material(target)


func flash() -> void:
	if _material == null:
		return
	if _tween:
		_tween.kill()
	_material.set_shader_parameter("flash_amount", 1.0)
	_tween = create_tween()
	_tween.tween_method(_set_amount, 1.0, 0.0, duration)


func _set_amount(amount: float) -> void:
	_material.set_shader_parameter("flash_amount", amount)


func _share_material(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = true
			_share_material(child)
