extends PlayerState
## 공중 공격. 아래를 누른 채 공격하면 아래 찍기가 되고, 맞으면 튀어 오른다.

var _data: AttackData
var _time: float = 0.0
var _hitbox_opened: bool = false
var _is_down: bool = false


func enter() -> void:
	_is_down = player.is_down_held()
	_data = player.combat.down_attack if _is_down else player.weapon.combo[0]
	_time = 0.0
	_hitbox_opened = false
	player.hitbox.hit_landed.connect(_on_hit_landed)


func exit() -> void:
	player.hitbox.deactivate()
	player.hitbox.hit_landed.disconnect(_on_hit_landed)


func physics_update(delta: float) -> void:
	player.apply_horizontal(delta, player.movement.air_control)
	player.apply_gravity(delta)
	player.move_and_slide()

	if try_dash():
		return
	if player.is_on_floor():
		go_grounded()
		return

	_time += delta
	if not _hitbox_opened and _time >= _data.startup:
		_hitbox_opened = true
		var dir: Vector2 = Vector2.DOWN if _is_down else Vector2(player.facing, 0.0)
		player.hitbox.activate_rect(_data, _get_offset(), _data.hitbox_size, dir)
	if player.hitbox.active and _time >= _data.startup + _data.active:
		player.hitbox.deactivate()
	if _time >= _data.get_total_time():
		transitioned.emit(self, &"Fall")


func _get_offset() -> Vector2:
	if _is_down:
		return _data.hitbox_offset
	return Vector2(_data.hitbox_offset.x * player.facing, _data.hitbox_offset.y)


func _on_hit_landed(_hurtbox: HurtboxComponent, _damage: int, _killed: bool) -> void:
	if not _is_down:
		return
	player.pogo_bounce()
	transitioned.emit(self, &"Fall")
