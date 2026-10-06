class_name WeaponCatalog
extends Resource
## 게임에 있는 모든 무기 목록. id로 찾는다.

@export var weapons: Array[WeaponData] = []


func find(id: StringName) -> WeaponData:
	for weapon: WeaponData in weapons:
		if weapon.id == id:
			return weapon
	return null
