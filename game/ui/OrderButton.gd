extends TextureButton

class_name OrderInputButton


export(String) var action_emulated setget set_action_emulated

var _hotkey_value : int = -1
var _hotkey_disp : String = ""

func _ready() -> void:
	connect("button_down",self,"_on_button_down")
	connect("button_up",self,"_on_button_up")
	connect("mouse_exited",self,"_on_mouse_exited")
	if action_emulated != "":
		_on_action_assigned()


func set_action_emulated(value:String) -> void:
	action_emulated = value
	_on_action_assigned()


func _on_action_assigned() -> void:
	if InputMap.has_action(action_emulated):
		var action_list := InputMap.get_action_list(action_emulated)
		for ev in action_list:
			if ev is InputEventKey:
				_hotkey_value = ev.physical_scancode
				_hotkey_disp = OS.get_scancode_string(_hotkey_value)
				break
	else:
		_hotkey_value = -1
		_hotkey_disp = ""
	if _hotkey_disp != "":
		hint_tooltip = tr("ORDER_BUTTON_TOOLTIP").format([action_emulated,_hotkey_disp])
	else:
		hint_tooltip = ""


func _on_button_down() -> void:
	if InputMap.has_action(action_emulated):
		Input.action_press(action_emulated)


func _on_button_up() -> void:
	if InputMap.has_action(action_emulated):
		Input.action_release(action_emulated)


func _on_mouse_exited() -> void:
	if InputMap.has_action(action_emulated) and Input.is_action_pressed(action_emulated):
		Input.action_release(action_emulated)
