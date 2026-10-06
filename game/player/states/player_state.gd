class_name PlayerState
extends State
## 플레이어 상태 공통 베이스. 여러 상태가 공유하는 전환 조건을 모아둔다.

var player: Player:
	get:
		return actor as Player


## 점프 가능하면 Jump로 전환하고 true를 반환한다.
func try_jump() -> bool:
	if player.can_jump():
		transitioned.emit(self, &"Jump")
		return true
	return false


## 대시 가능하면 Dash로 전환하고 true를 반환한다.
func try_dash() -> bool:
	if player.is_dash_pressed() and player.can_dash():
		transitioned.emit(self, &"Dash")
		return true
	return false


## 바닥에 있을 때 입력에 따라 Idle 또는 Run으로 전환한다.
func go_grounded() -> void:
	if is_zero_approx(player.get_input_direction()):
		transitioned.emit(self, &"Idle")
	else:
		transitioned.emit(self, &"Run")
