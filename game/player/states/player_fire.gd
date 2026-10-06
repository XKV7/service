extends PlayerState
## 레일건 발사. 관통 빔을 쏘고 반동으로 뒤로 밀린다.

const RailgunBeamScript: GDScript = preload("res://game/weapons/railgun_beam.gd")

var _time: float = 0.0


func enter() -> void:
	var data: RailgunData = player.railgun
	player.energy.spend(data.energy_cost)
	_time = 0.0

	var beam: RailgunBeam = RailgunBeamScript.new() as RailgunBeam
	player.get_parent().add_child(beam)
	var muzzle := Vector2(data.muzzle_offset.x * player.facing, data.muzzle_offset.y)
	beam.fire(data, player.global_position + muzzle, player.facing)

	player.velocity.x = -player.facing * data.recoil_speed
	EventBus.screen_flash_requested.emit(data.flash_color, data.flash_time)
	EventBus.screen_shake_requested.emit(data.attack.shake)


func physics_update(delta: float) -> void:
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	_time += delta
	if _time >= player.railgun.fire_recovery:
		go_neutral()
