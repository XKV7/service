extends PlayerState
## 레일건 발사. 관통 빔을 쏘고 반동으로 뒤로 밀린다.

const LaserBeamScript: GDScript = preload("res://game/weapons/laser_beam.gd")

var _time: float = 0.0


func enter() -> void:
	var data: RailgunData = player.railgun
	player.energy.spend(data.energy_cost)
	_time = 0.0

	var beam: LaserBeam = LaserBeamScript.new() as LaserBeam
	player.get_parent().add_child(beam)
	beam.hit_landed.connect(_on_beam_hit)
	var muzzle := Vector2(data.muzzle_offset.x * player.facing, data.muzzle_offset.y)
	beam.fire(player.global_position + muzzle, Vector2(player.facing, 0.0), data.attack, data.max_length,
			data.beam_width, data.target_mask, data.world_mask, data.beam_color)

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


func _on_beam_hit(hurtbox: HurtboxComponent, damage: int, _killed: bool) -> void:
	HitStop.trigger(get_tree(), player.railgun.attack.hitstop)
	EventBus.hit_landed.emit(hurtbox.owner, damage)
