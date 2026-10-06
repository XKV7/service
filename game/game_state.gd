extends Node
## 게임 진행 상태. M3에서는 데이터(재화)만 관리하고, 이후 마일스톤에서 확장한다.

signal data_changed(amount: int)

var data: int = 0


func add_data(amount: int) -> void:
	if amount == 0:
		return
	data = maxi(data + amount, 0)
	data_changed.emit(data)
