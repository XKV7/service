extends BossPattern
## 질주 돌파. 터널로 빠졌다가 헤드라이트 경고 뒤 선로를 가로질러 질주한다.
## 1페이즈는 한 번, 2페이즈는 양쪽에서 번갈아 질주한다. 마지막 질주는 정차하고 코어를 연다.

@export var attack: AttackData
@export var depart_speed: float = 320.0
@export var rush_speed: float = 720.0
## 정차 감속 (px/s²)
@export var brake_decel: float = 1600.0
@export var warn_time: float = 1.0
## 페이즈별 질주 횟수
@export var passes_per_phase: Array[int] = [1, 2]
## 페이즈별 코어 열림 시간 (초)
@export var core_open_times: Array[float] = [2.5, 1.5]
@export var warn_color: Color = Color(1.0, 0.95, 0.6, 0.35)
## 경고 표시 높이 (선로 위, px)
@export var warn_height: float = 56.0

enum Phase { DEPART, WARN, RUSH, CORE }

var _phase: Phase = Phase.DEPART
var _passes_left: int = 0
var _dir: float = 1.0
var _time: float = 0.0
var _speed: float = 0.0

var train: TrainBoss:
	get:
		return actor as TrainBoss


func enter() -> void:
	var phase: int = mini(train.brain.phase_index, passes_per_phase.size() - 1)
	_passes_left = passes_per_phase[phase]
	_phase = Phase.DEPART
	_dir = 1.0
	train.facing = 1.0
	train.rush_hitbox.activate(attack, train.facing)


func _cleanup() -> void:
	train.rush_hitbox.deactivate()
	train.set_core_open(false)


func cancel() -> void:
	super.cancel()
	# 예고 중에 해킹당하면 선로에 천천히 들어와 멈춘 것으로 처리한다.
	train.facing = -1.0
	train.park()


func physics_update(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.DEPART:
			train.global_position.x += _dir * depart_speed * delta
			if train.is_offscreen():
				_start_warning(-1.0 if _dir > 0.0 else 1.0)
		Phase.WARN:
			if _time >= warn_time:
				telegraphing = false
				_phase = Phase.RUSH
				_time = 0.0
				_speed = rush_speed
				train.rush_hitbox.activate(attack, train.facing)
		Phase.RUSH:
			_move_rush(delta)
		Phase.CORE:
			var phase: int = mini(train.brain.phase_index, core_open_times.size() - 1)
			if _time >= core_open_times[phase]:
				finish()


## entry_side: -1이면 왼쪽 터널에서 들어온다.
func _start_warning(entry_side: float) -> void:
	_phase = Phase.WARN
	_time = 0.0
	telegraphing = true
	train.rush_hitbox.deactivate()
	_dir = -entry_side
	train.facing = _dir
	var entry_x: float = train.arena_left - train.offscreen_margin if entry_side < 0.0 else train.arena_right + train.offscreen_margin
	train.global_position = Vector2(entry_x, train.track_y)
	var width: float = train.arena_right - train.arena_left
	track(HazardZone.spawn(level(), Rect2(train.arena_left, train.track_y - warn_height, width, warn_height),
			null, warn_time, 0.0, warn_color, warn_color))


func _move_rush(delta: float) -> void:
	var last: bool = _passes_left <= 1
	if last:
		var dist: float = (train.park_x - train.global_position.x) * _dir
		var brake_speed: float = sqrt(maxf(2.0 * brake_decel * dist, 0.0))
		_speed = minf(rush_speed, brake_speed)
		if dist <= 1.0:
			train.park()
			train.set_core_open(true)
			EventBus.toast_requested.emit("운전석 코어가 열렸다!")
			_phase = Phase.CORE
			_time = 0.0
			return
	train.global_position.x += _dir * _speed * delta
	if not last and train.is_offscreen():
		_passes_left -= 1
		_start_warning(-1.0 if _dir > 0.0 else 1.0)
