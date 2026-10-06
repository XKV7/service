class_name Drone
extends Enemy
## 보안 드론. 공중에서 거리를 유지하다가 조준선을 보여준 뒤 레이저를 쏜다.

@onready var aim_line: Line2D = %AimLine
@onready var muzzle: Marker2D = %Muzzle

var home_position: Vector2


func _ready() -> void:
	super._ready()
	home_position = global_position
	aim_line.visible = false
