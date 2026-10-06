class_name BodyMenu
extends CanvasLayer
## 의체 메뉴. 부품 장착·해제·강화와 근접 무기 교체를 한다.
## 중계기에서 열면 바꿀 수 있고, Tab으로 열면 보기만 할 수 있다. 열려 있는 동안 게임이 멈춘다.
## 방향키 + Enter(또는 터치)로 조작하고, Tab/Esc로 닫는다.

@export var panel_size: Vector2 = Vector2(600, 320)
@export var font_size: int = 12
@export var title_color: Color = Color(0.0, 1.0, 0.9, 1.0)
@export var equipped_color: Color = Color(1.0, 0.3, 0.7, 1.0)
@export var muted_color: Color = Color(0.6, 0.62, 0.7, 1.0)
@export var back_color: Color = Color(0.03, 0.03, 0.08, 0.97)
@export var dim_color: Color = Color(0.0, 0.0, 0.0, 0.5)
@export var border_color: Color = Color(0.0, 1.0, 0.9, 0.6)
@export var detail_width: float = 280.0

var editable: bool = false

var _selected: StringName = &""
var _selected_is_weapon: bool = false
var _closed_frame: int = -100

var _root: Control
var _slots_label: Label
var _part_list: VBoxContainer
var _weapon_list: VBoxContainer
var _detail_name: Label
var _detail_level: Label
var _detail_text: Label
var _action_button: Button
var _upgrade_button: Button
var _footer: Label


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false
	EventBus.body_menu_requested.connect(open)
	GameState.loadout_changed.connect(_on_loadout_changed)
	GameState.data_changed.connect(func(_d: int) -> void: _on_loadout_changed())


func is_open() -> bool:
	return _root.visible


func open(can_edit: bool) -> void:
	# 닫은 직후 같은 키 입력으로 다시 열리는 것을 막는다.
	if is_open() or Engine.get_physics_frames() - _closed_frame <= 2:
		return
	editable = can_edit
	_root.visible = true
	get_tree().paused = true
	_refresh()
	_focus_selected()


func close() -> void:
	_root.visible = false
	get_tree().paused = false
	_closed_frame = Engine.get_physics_frames()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"menu") or event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


# --- 화면 구성 ---

func _build() -> void:
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = dim_color
	_root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = back_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override(&"panel", style)
	panel.custom_minimum_size = panel_size
	center.add_child(panel)

	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override(&"separation", 16)
	outer.add_child(columns)

	# 왼쪽: 슬롯, 부품, 무기
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	_slots_label = _make_label(title_color)
	left.add_child(_slots_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var lists := VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lists)
	_part_list = VBoxContainer.new()
	lists.add_child(_part_list)
	var weapon_title := _make_label(title_color)
	weapon_title.text = "근접 무기"
	lists.add_child(weapon_title)
	_weapon_list = VBoxContainer.new()
	lists.add_child(_weapon_list)

	# 오른쪽: 선택한 항목 설명
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(detail_width, 0)
	columns.add_child(right)
	_detail_name = _make_label(title_color)
	right.add_child(_detail_name)
	_detail_level = _make_label(equipped_color)
	right.add_child(_detail_level)
	_detail_text = _make_label(Color.WHITE)
	_detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_text.custom_minimum_size = Vector2(detail_width, 0)
	_detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_detail_text)
	_action_button = _make_button()
	_action_button.pressed.connect(_on_action_pressed)
	right.add_child(_action_button)
	_upgrade_button = _make_button()
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	right.add_child(_upgrade_button)

	_footer = _make_label(muted_color)
	outer.add_child(_footer)


func _make_label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _make_button() -> Button:
	var button := Button.new()
	button.add_theme_font_size_override(&"font_size", font_size)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	return button


# --- 내용 갱신 ---

func _on_loadout_changed() -> void:
	if is_open():
		_refresh()
		_focus_selected()


func _refresh() -> void:
	_slots_label.text = "장착 부품 %d / %d" % [GameState.equipped_parts.size(), GameState.get_slot_count()]
	for child: Node in _part_list.get_children():
		child.queue_free()
	for child: Node in _weapon_list.get_children():
		child.queue_free()

	var part_ids: Array = GameState.owned_parts.keys()
	if part_ids.is_empty():
		var empty := _make_label(muted_color)
		empty.text = "보유한 부품이 없다"
		_part_list.add_child(empty)
	for id: StringName in part_ids:
		var part: PartData = GameState.get_part(id)
		var button := _make_button()
		var mark: String = "■ " if GameState.is_equipped(id) else "□ "
		if part.passive_only:
			mark = "◆ "
		button.text = "%s%s  Lv%d" % [mark, part.display_name, GameState.get_part_level(id)]
		if GameState.is_equipped(id):
			button.add_theme_color_override(&"font_color", equipped_color)
		button.set_meta(&"id", id)
		button.focus_entered.connect(_select.bind(id, false))
		button.pressed.connect(_on_item_pressed.bind(id, false))
		_part_list.add_child(button)

	for id: StringName in GameState.owned_weapons:
		var weapon: WeaponData = GameState.get_weapon(id)
		var button := _make_button()
		var equipped: bool = id == GameState.equipped_weapon
		button.text = ("■ " if equipped else "□ ") + weapon.display_name
		if equipped:
			button.add_theme_color_override(&"font_color", equipped_color)
		button.set_meta(&"id", id)
		button.focus_entered.connect(_select.bind(id, true))
		button.pressed.connect(_on_item_pressed.bind(id, true))
		_weapon_list.add_child(button)

	_footer.text = "데이터 %d    %s    Tab/Esc 닫기" % [
		GameState.data, "Enter: 장착/해제" if editable else "중계기에서만 바꿀 수 있다"]
	if _selected == &"":
		if not part_ids.is_empty():
			_selected = part_ids[0]
			_selected_is_weapon = false
		else:
			_selected = GameState.equipped_weapon
			_selected_is_weapon = true
	_update_detail()


func _select(id: StringName, is_weapon: bool) -> void:
	_selected = id
	_selected_is_weapon = is_weapon
	_update_detail()


func _update_detail() -> void:
	_action_button.visible = editable
	_upgrade_button.visible = false
	if _selected_is_weapon:
		var weapon: WeaponData = GameState.get_weapon(_selected)
		if weapon == null:
			return
		_detail_name.text = weapon.display_name
		_detail_level.text = "%d연격 · 사거리 %dpx" % [weapon.combo.size(), int(weapon.attack_range)]
		_detail_text.text = weapon.description
		var equipped: bool = _selected == GameState.equipped_weapon
		_action_button.text = "장착 중" if equipped else "장착"
		_action_button.disabled = equipped
		return

	var part: PartData = GameState.get_part(_selected)
	if part == null:
		_detail_name.text = ""
		_detail_level.text = ""
		_detail_text.text = ""
		_action_button.visible = false
		return
	var level: int = GameState.get_part_level(_selected)
	_detail_name.text = part.display_name
	_detail_level.text = "Lv%d / %d" % [level, part.get_max_level()]
	var lines: PackedStringArray = [part.description, "", "현재: " + part.get_level(level).description]
	if level < part.get_max_level():
		lines.append("다음: " + part.get_level(level + 1).description)
	_detail_text.text = "\n".join(lines)

	if part.passive_only:
		_action_button.visible = false
	elif GameState.is_equipped(_selected):
		_action_button.text = "해제"
		_action_button.disabled = false
	else:
		var full: bool = GameState.equipped_parts.size() >= GameState.get_slot_count()
		_action_button.text = "슬롯이 가득 찼다" if full else "장착"
		_action_button.disabled = full

	var cost: int = GameState.get_upgrade_cost(_selected)
	_upgrade_button.visible = editable and cost >= 0
	if cost >= 0:
		_upgrade_button.text = "강화 (데이터 %d)" % cost
		_upgrade_button.disabled = GameState.data < cost


func _focus_selected() -> void:
	for list: VBoxContainer in [_part_list, _weapon_list]:
		for child: Node in list.get_children():
			if child is Button and child.get_meta(&"id", &"") == _selected and not child.is_queued_for_deletion():
				(child as Button).grab_focus.call_deferred()
				return
	for child: Node in _part_list.get_children():
		if child is Button and not child.is_queued_for_deletion():
			(child as Button).grab_focus.call_deferred()
			return


# --- 조작 ---

func _on_item_pressed(id: StringName, is_weapon: bool) -> void:
	_select(id, is_weapon)
	_on_action_pressed()


func _on_action_pressed() -> void:
	if not editable:
		return
	if _selected_is_weapon:
		GameState.equip_weapon(_selected)
	elif GameState.is_equipped(_selected):
		GameState.unequip_part(_selected)
	else:
		GameState.equip_part(_selected)


func _on_upgrade_pressed() -> void:
	if editable and GameState.upgrade_part(_selected):
		EventBus.toast_requested.emit("%s Lv%d" % [GameState.get_part(_selected).display_name, GameState.get_part_level(_selected)])
