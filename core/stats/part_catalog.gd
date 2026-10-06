class_name PartCatalog
extends Resource
## 게임에 있는 모든 부품 목록. id로 찾는다.

@export var parts: Array[PartData] = []


func find(id: StringName) -> PartData:
	for part: PartData in parts:
		if part.id == id:
			return part
	return null
