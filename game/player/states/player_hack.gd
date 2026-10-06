extends PlayerState
## 해킹: 시스템 정지. 시전 시간 뒤 전방 범위의 적을 정지시킨다.

const HackWaveScript: GDScript = preload("res://game/weapons/hack_wave.gd")

var _time: float = 0.0
var _released: bool = false


func enter() -> void:
	player.energy.spend(player.hack.energy_cost)
	_time = 0.0
	_released = false


func physics_update(delta: float) -> void:
	var data: HackData = player.hack
	player.apply_friction(delta)
	player.apply_gravity(delta)
	player.move_and_slide()

	_time += delta
	if not _released and _time >= data.cast_time:
		_released = true
		_release(data)
	if _time >= data.cast_time + data.recovery:
		go_neutral()


func _release(data: HackData) -> void:
	var reach: float = player.stats.get_value(Player.STAT_HACK_REACH)
	var center := player.global_position + Vector2(player.facing * reach * 0.5, data.center_y)
	var size := Vector2(reach, data.height)

	var shape := RectangleShape2D.new()
	shape.size = size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collision_mask = data.target_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query):
		var hurtbox := result.get("collider") as HurtboxComponent
		if hurtbox and hurtbox.stun:
			hurtbox.stun.stun(player.stats.get_value(Player.STAT_HACK_STUN_DURATION))

	var wave: HackWave = HackWaveScript.new() as HackWave
	player.get_parent().add_child(wave)
	wave.play(center, size, player.facing, data.effect_color)
	EventBus.screen_flash_requested.emit(data.flash_color, data.flash_time)
