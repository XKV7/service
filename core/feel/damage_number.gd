class_name DamageNumber
extends Label
## 떠오르며 사라지는 숫자. spawn()으로 생성한다.

const RISE_DISTANCE: float = 18.0
const LIFETIME: float = 0.6
const HORIZONTAL_JITTER: float = 6.0
const LABEL_WIDTH: float = 40.0


static func spawn(parent: Node, global_pos: Vector2, text_value: String, color: Color) -> DamageNumber:
	var label := DamageNumber.new()
	label.text = text_value
	label.modulate = color
	label.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(LABEL_WIDTH, 0.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.global_position = global_pos + Vector2(-LABEL_WIDTH * 0.5 + randf_range(-HORIZONTAL_JITTER, HORIZONTAL_JITTER), 0.0)
	var tween: Tween = label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - RISE_DISTANCE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, LIFETIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
	return label
