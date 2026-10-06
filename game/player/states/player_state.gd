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


## 공격 입력이 있으면 지상은 Attack, 공중은 AirAttack으로 전환한다.
func try_attack() -> bool:
	if not player.consume_attack():
		return false
	transitioned.emit(self, &"Attack" if player.is_on_floor() else &"AirAttack")
	return true


## 레일건 버튼을 누르면 충전을 시작한다.
func try_fire() -> bool:
	if player.can_fire() and player.is_fire_pressed():
		transitioned.emit(self, &"Charge")
		return true
	return false


## 해킹 버튼을 누르고 연산력이 충분하면 시스템 정지를 시전한다.
func try_hack() -> bool:
	if player.is_hack_pressed() and player.can_hack():
		transitioned.emit(self, &"Hack")
		return true
	return false


## 바닥에서 상호작용 키를 누르면 가장 가까운 대상과 상호작용한다.
func try_interact() -> bool:
	if not player.is_on_floor() or not player.is_interact_pressed():
		return false
	var target: InteractableComponent = player.find_interactable()
	if target == null:
		return false
	target.interact(player)
	return true


## 이동 상태(Idle/Run/Jump/Fall)에서 공통으로 확인하는 행동 입력
func try_actions() -> bool:
	return try_dash() or try_attack() or try_fire() or try_hack() or try_interact()


## 바닥에 있을 때 입력에 따라 Idle 또는 Run으로 전환한다.
func go_grounded() -> void:
	if is_zero_approx(player.get_input_direction()):
		transitioned.emit(self, &"Idle")
	else:
		transitioned.emit(self, &"Run")


## 행동이 끝났을 때 바닥이면 Idle/Run, 공중이면 Fall로 돌아간다.
func go_neutral() -> void:
	if player.is_on_floor():
		go_grounded()
	else:
		transitioned.emit(self, &"Fall")
