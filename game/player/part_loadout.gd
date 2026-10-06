class_name PartLoadout
extends Node
## GameState의 장착 부품·무기를 플레이어에게 적용한다.
## 부품마다 "part:<id>" 출처로 수정값을 넣고, 조건부 효과는 PartEffect 노드로 붙인다.

const SOURCE_PREFIX: String = "part:"

## 부품 id -> PartEffect
var _effects: Dictionary = {}
## 부품 id -> 적용된 레벨 (효과 노드를 다시 만들지 판단)
var _effect_levels: Dictionary = {}

var player: Player:
	get:
		return owner as Player


func _ready() -> void:
	GameState.loadout_changed.connect(refresh)
	refresh.call_deferred()


func refresh() -> void:
	var stats: StatSheet = player.stats
	var wanted: Dictionary = {}
	for id: StringName in GameState.equipped_parts:
		wanted[id] = GameState.get_part_level(id)

	# 새 수정값을 먼저 넣고 빠진 것을 나중에 지운다. (최대 체력이 잠깐 줄어 체력이 깎이지 않도록)
	for id: StringName in wanted:
		var part: PartData = GameState.get_part(id)
		var level_data: PartLevel = part.get_level(wanted[id])
		stats.set_source(_source_of(id), level_data.modifiers if level_data else [])
	for source: StringName in stats.get_sources():
		var text: String = String(source)
		if text.begins_with(SOURCE_PREFIX) and not wanted.has(StringName(text.trim_prefix(SOURCE_PREFIX))):
			stats.remove_source(source)

	_refresh_effects(wanted)

	var weapon: WeaponData = GameState.get_equipped_weapon()
	if weapon:
		player.weapon = weapon


func _refresh_effects(wanted: Dictionary) -> void:
	for id: StringName in _effects.keys():
		if not wanted.has(id) or _effect_levels[id] != wanted[id]:
			(_effects[id] as Node).queue_free()
			_effects.erase(id)
			_effect_levels.erase(id)
	for id: StringName in wanted:
		var part: PartData = GameState.get_part(id)
		if part.effect_script == null or _effects.has(id):
			continue
		var effect := part.effect_script.new() as PartEffect
		effect.name = String(id)
		effect.setup(part, wanted[id], player, player.stats)
		add_child(effect)
		_effects[id] = effect
		_effect_levels[id] = wanted[id]


func _source_of(id: StringName) -> StringName:
	return StringName(SOURCE_PREFIX + String(id))
