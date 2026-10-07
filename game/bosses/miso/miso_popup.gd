extends BossPattern
## 팝업 광고. 공중에 광고 창 몇 개가 생겨 투사체를 쏜다. 창은 근접 한 방에 부서진다.

@export var attack: AttackData
@export var count: int = 3
@export var max_alive: int = 4
## 광고 창이 생기는 범위 (전역 좌표)
@export var spawn_area: Rect2 = Rect2(60, 80, 520, 170)

var _time: float = 0.0
var _appear_time: float = 0.0


func enter() -> void:
	_time = 0.0
	telegraphing = true
	var alive: int = boss.get_tree().get_nodes_in_group(PopupAd.GROUP).size()
	for i: int in mini(count, max_alive - alive):
		var ad := PopupAd.new()
		ad.attack = attack
		ad.position = Vector2(randf_range(spawn_area.position.x, spawn_area.end.x), randf_range(spawn_area.position.y, spawn_area.end.y))
		level().add_child(ad)
		track(ad)
		_appear_time = ad.appear_time


func cancel() -> void:
	# 나타나는 중에 해킹당하면 창이 모두 닫힌다.
	for node: Node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	super.cancel()


func physics_update(delta: float) -> void:
	_time += delta
	if _time >= _appear_time:
		_spawned.clear()
		finish()
