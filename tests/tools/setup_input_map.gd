extends SceneTree
## Input Map을 project.godot에 기록하는 일회성 도구.
## 실행: godot --headless --path . -s res://tests/tools/setup_input_map.gd

const DEADZONE: float = 0.2
## 모든 입력 장치를 받는다.
const ALL_DEVICES: int = -1


func _init() -> void:
	var actions: Dictionary = {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)],
		"move_up": [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)],
		"move_down": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)],
		"jump": [_key(KEY_SPACE), _button(JOY_BUTTON_A)],
		"attack": [_key(KEY_J), _button(JOY_BUTTON_X)],
		"fire": [_key(KEY_K), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"dash": [_key(KEY_L), _button(JOY_BUTTON_B)],
		"hack": [_key(KEY_I), _button(JOY_BUTTON_Y)],
		"interact": [_key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0)],
		"menu": [_key(KEY_TAB), _button(JOY_BUTTON_BACK)],
		"pause": [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)],
	}
	for action_name: String in actions:
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": DEADZONE,
			"events": actions[action_name],
		})
	var err: Error = ProjectSettings.save()
	print("Input Map 저장 결과: ", error_string(err))
	quit()


func _key(physical: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.device = ALL_DEVICES
	ev.physical_keycode = physical
	return ev


func _button(button: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.device = ALL_DEVICES
	ev.button_index = button
	return ev


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.device = ALL_DEVICES
	ev.axis = axis
	ev.axis_value = value
	return ev
