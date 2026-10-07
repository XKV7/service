class_name DialogueData
extends Resource
## 대사 묶음 하나 (한 장면). id로 "이미 본 장면"을 기록한다.

@export var id: StringName = &""
## 회상 장면 등에서 보여줄 제목 (없어도 된다)
@export var title: String = ""
@export var lines: Array[DialogueLine] = []
