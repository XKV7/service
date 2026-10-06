extends PlayerState
## 레일건 충전. 누르고 있는 동안 충전하고, 떼면 충전 시간과 연산력을 확인해 발사한다.

@export var bar_color_charging: Color = Color(0.6, 0.6, 0.7, 1.0)
@export var bar_color_ready: Color = Color(0.0, 1.0, 0.9, 1.0)
## 충전은 끝났지만 연산력이 모자랄 때
@export var bar_color_no_energy: Color = Color(1.0, 0.25, 0.35, 1.0)

var _time: float = 0.0

@onready var _bar_fill: ColorRect = %ChargeFill
@onready var _bar_back: ColorRect = %ChargeBack


func enter() -> void:
	_time = 0.0
	player.charge_bar.visible = true


func exit() -> void:
	player.charge_bar.visible = false


func physics_update(delta: float) -> void:
	var data: RailgunData = player.railgun
	player.apply_horizontal(delta, 1.0 if player.is_on_floor() else player.movement.air_control, data.move_speed_mult)
	if player.can_jump():
		player.consume_jump()
		player.velocity.y = player.movement.jump_velocity
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_dash():
		return
	_time += delta
	if player.is_fire_held():
		return
	if _time >= _charge_time() and player.energy.can_spend(data.energy_cost):
		transitioned.emit(self, &"Fire")
	else:
		go_neutral()


func update(_delta: float) -> void:
	var data: RailgunData = player.railgun
	var ratio: float = clampf(_time / _charge_time(), 0.0, 1.0)
	_bar_fill.size.x = _bar_back.size.x * ratio
	if ratio < 1.0:
		_bar_fill.color = bar_color_charging
	elif player.energy.can_spend(data.energy_cost):
		_bar_fill.color = bar_color_ready
	else:
		_bar_fill.color = bar_color_no_energy


func _charge_time() -> float:
	return player.stats.get_value(Player.STAT_RAILGUN_CHARGE_TIME)
