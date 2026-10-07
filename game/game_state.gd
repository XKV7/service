extends Node
## 게임 진행 상태. 부품·무기·스킬·데이터·중계기·의체 잔해를 관리한다.
## 세이브(M8)는 이 노드의 내용을 id 기준으로 저장한다.

signal data_changed(amount: int)
## 부품 보유·장착·레벨 또는 무기가 바뀜
signal loadout_changed
signal wreck_changed

const PART_CATALOG: PartCatalog = preload("res://data/parts/part_catalog.tres")
const WEAPON_CATALOG: WeaponCatalog = preload("res://data/weapons/weapon_catalog.tres")
const BASE_SLOT_COUNT: int = 3
const SLOT_MODULE_ID: StringName = &"slot_module"
const DEFAULT_WEAPON: StringName = &"blade"
const MEMORY_TOTAL: int = 8

var data: int = 0
## 부품 id -> 레벨
var owned_parts: Dictionary = {}
var equipped_parts: Array[StringName] = []
var owned_weapons: Array[StringName] = [DEFAULT_WEAPON]
var equipped_weapon: StringName = DEFAULT_WEAPON
## 스킬 id -> 해금 여부 (railgun, hack)
var skills: Dictionary = {}
var activated_relays: Array[StringName] = []
var last_relay: StringName = &""
## 의체 잔해 {"position": Vector2, "data": int, "scene": String}. 없으면 비어 있다.
var wreck: Dictionary = {}
var defeated_bosses: Array[StringName] = []
## 열어 둔 숨겨진 공간·가짜 벽·셔터 id
var opened_secrets: Array[StringName] = []
## 지금 있는 레벨 씬 경로 (세이브용)
var current_scene: String = ""
## 모은 기억 조각 id
var memories: Array[StringName] = []
## 본 대사 장면 id
var seen_scenes: Array[StringName] = []
## 고른 엔딩 (destroy / control)
var ending: StringName = &""


## 새 게임 상태로 되돌린다. (테스트, 새 게임)
func reset() -> void:
	data = 0
	owned_parts.clear()
	equipped_parts.clear()
	owned_weapons = [DEFAULT_WEAPON]
	equipped_weapon = DEFAULT_WEAPON
	skills.clear()
	activated_relays.clear()
	last_relay = &""
	wreck.clear()
	defeated_bosses.clear()
	opened_secrets.clear()
	current_scene = ""
	memories.clear()
	seen_scenes.clear()
	ending = &""
	data_changed.emit(data)
	loadout_changed.emit()
	wreck_changed.emit()


# --- 데이터 ---

func add_data(amount: int) -> void:
	if amount == 0:
		return
	data = maxi(data + amount, 0)
	data_changed.emit(data)


func spend_data(amount: int) -> bool:
	if amount < 0 or data < amount:
		return false
	add_data(-amount)
	return true


# --- 부품 ---

func get_part(id: StringName) -> PartData:
	return PART_CATALOG.find(id)


func has_part(id: StringName) -> bool:
	return owned_parts.has(id)


func get_part_level(id: StringName) -> int:
	return owned_parts.get(id, 0)


func get_slot_count() -> int:
	return BASE_SLOT_COUNT + (1 if has_part(SLOT_MODULE_ID) else 0)


func acquire_part(id: StringName) -> bool:
	if has_part(id) or get_part(id) == null:
		return false
	owned_parts[id] = 1
	EventBus.part_acquired.emit(id)
	loadout_changed.emit()
	return true


func is_equipped(id: StringName) -> bool:
	return id in equipped_parts


func can_equip(id: StringName) -> bool:
	var part: PartData = get_part(id)
	return part != null and not part.passive_only and has_part(id) \
			and not is_equipped(id) and equipped_parts.size() < get_slot_count()


func equip_part(id: StringName) -> bool:
	if not can_equip(id):
		return false
	equipped_parts.append(id)
	loadout_changed.emit()
	return true


func unequip_part(id: StringName) -> bool:
	if not is_equipped(id):
		return false
	equipped_parts.erase(id)
	loadout_changed.emit()
	return true


## 다음 레벨 강화 비용. 강화할 수 없으면 -1
func get_upgrade_cost(id: StringName) -> int:
	var part: PartData = get_part(id)
	if part == null or not has_part(id):
		return -1
	return part.get_upgrade_cost(get_part_level(id))


func upgrade_part(id: StringName) -> bool:
	var cost: int = get_upgrade_cost(id)
	if cost < 0 or not spend_data(cost):
		return false
	owned_parts[id] = get_part_level(id) + 1
	loadout_changed.emit()
	return true


# --- 무기 ---

func get_weapon(id: StringName) -> WeaponData:
	return WEAPON_CATALOG.find(id)


func get_equipped_weapon() -> WeaponData:
	return get_weapon(equipped_weapon)


func acquire_weapon(id: StringName) -> bool:
	if id in owned_weapons or get_weapon(id) == null:
		return false
	owned_weapons.append(id)
	loadout_changed.emit()
	return true


func equip_weapon(id: StringName) -> bool:
	if not id in owned_weapons or id == equipped_weapon:
		return false
	equipped_weapon = id
	loadout_changed.emit()
	return true


# --- 스킬 ---

func unlock_skill(id: StringName) -> void:
	skills[id] = true


func has_skill(id: StringName) -> bool:
	return skills.get(id, false)


# --- 중계기 ---

func activate_relay(id: StringName) -> bool:
	last_relay = id
	if id in activated_relays:
		return false
	activated_relays.append(id)
	return true


# --- 의체 잔해 ---

## 파괴된 위치에 잔해를 남기고 들고 있던 데이터를 모두 옮긴다.
## 회수하지 못한 이전 잔해와 데이터는 사라진다. 들고 있던 데이터가 없으면 잔해도 남지 않는다.
func create_wreck(pos: Vector2, scene_path: String = "") -> void:
	if data <= 0:
		wreck.clear()
		wreck_changed.emit()
		return
	wreck = {"position": pos, "data": data, "scene": scene_path}
	data = 0
	data_changed.emit(data)
	wreck_changed.emit()


func has_wreck() -> bool:
	return not wreck.is_empty()


## 잔해의 데이터를 회수한다. 회수한 양을 반환한다.
func recover_wreck() -> int:
	if not has_wreck():
		return 0
	var amount: int = wreck.get("data", 0)
	wreck.clear()
	add_data(amount)
	wreck_changed.emit()
	return amount


# --- 보스 ---

func defeat_boss(id: StringName) -> void:
	if not id in defeated_bosses:
		defeated_bosses.append(id)


func is_boss_defeated(id: StringName) -> bool:
	return id in defeated_bosses


# --- 숨겨진 공간 ---

func open_secret(id: StringName) -> void:
	if id != &"" and not id in opened_secrets:
		opened_secrets.append(id)


func is_secret_open(id: StringName) -> bool:
	return id in opened_secrets


# --- 스토리 ---

func collect_memory(id: StringName) -> bool:
	if id == &"" or id in memories:
		return false
	memories.append(id)
	return true


func has_memory(id: StringName) -> bool:
	return id in memories


func has_all_memories() -> bool:
	return memories.size() >= MEMORY_TOTAL


func mark_seen(id: StringName) -> void:
	if id != &"" and not id in seen_scenes:
		seen_scenes.append(id)


func has_seen(id: StringName) -> bool:
	return id in seen_scenes
