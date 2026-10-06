extends PlayerState
## 지상 근접 콤보. 공격 도중 입력하면 다음 타로 이어진다. 대시로 언제든 캔슬할 수 있다.

var _combo_index: int = 0
var _data: AttackData
var _time: float = 0.0
var _queued: bool = false
var _hitbox_opened: bool = false


func enter() -> void:
	_start(0)


func exit() -> void:
	player.hitbox.deactivate()


func physics_update(delta: float) -> void:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_dash():
		return
	if player.consume_attack():
		_queued = true

	_time += delta
	if not _hitbox_opened and _time >= _data.startup:
		_hitbox_opened = true
		player.hitbox.activate(_data, player.facing)
	if player.hitbox.active and _time >= _data.startup + _data.active:
		player.hitbox.deactivate()
	if _time < _data.get_total_time():
		return

	var combo: Array[AttackData] = player.weapon.combo
	if _queued and _combo_index + 1 < combo.size() and player.is_on_floor():
		_start(_combo_index + 1)
	else:
		go_neutral()


func _start(index: int) -> void:
	_combo_index = index
	_data = player.weapon.combo[index]
	_time = 0.0
	_queued = false
	_hitbox_opened = false
	player.face_input()
	player.velocity.x = player.facing * _data.lunge_speed
