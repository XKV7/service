class_name BossBrain
extends Node
## 보스 패턴 선택. 체력에 따라 페이즈를 바꾸고, 페이즈의 패턴 목록에서 가중치 랜덤으로 다음 패턴을 고른다.
## 같은 패턴이 연속으로 나오지 않게 한다. (패턴이 하나뿐이면 예외)

signal phase_changed(index: int)

@export var phases: Array[BossPhase] = []
@export var health: HealthComponent

var phase_index: int = 0

var _last_pattern: StringName = &""


func _ready() -> void:
	if health:
		health.health_changed.connect(_on_health_changed)


func get_phase() -> BossPhase:
	return phases[phase_index] if phase_index < phases.size() else null


func get_idle_time() -> float:
	var phase: BossPhase = get_phase()
	return phase.idle_time if phase else 1.0


func next_pattern() -> StringName:
	var phase: BossPhase = get_phase()
	if phase == null or phase.patterns.is_empty():
		return &""
	var candidates: Array[StringName] = []
	var weights: Array[float] = []
	for i: int in phase.patterns.size():
		var pattern: StringName = phase.patterns[i]
		if pattern == _last_pattern and phase.patterns.size() > 1:
			continue
		candidates.append(pattern)
		weights.append(phase.weights[i] if phase.weights.size() == phase.patterns.size() else 1.0)
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll: float = randf() * total
	for i: int in candidates.size():
		roll -= weights[i]
		if roll <= 0.0:
			_last_pattern = candidates[i]
			return _last_pattern
	_last_pattern = candidates.back()
	return _last_pattern


func _on_health_changed(current: int, maximum: int) -> void:
	var ratio: float = float(current) / float(maximum) if maximum > 0 else 0.0
	while phase_index + 1 < phases.size() and ratio <= phases[phase_index + 1].hp_ratio:
		phase_index += 1
		_last_pattern = &""
		phase_changed.emit(phase_index)
