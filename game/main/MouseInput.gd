extends Node2D


const EDGE_MARGIN_H = 0.15
const EDGE_MARGIN_V = 0.1


signal rect_updated(selection_rect)
signal rect_released(selection_rect)


var _left_down_for_drag : bool = false
var _middle_down_for_pan : bool = false
var _right_down_for_action : bool = false
var _selection_rect : Rect2


func _unhandled_input(event: InputEvent) -> void:
	_if_mouse_button_handle_press_release(event)
	_if_mouse_motion_handle_check_edge_pan_release(event)


func _if_mouse_button_handle_press_release(event:InputEvent) -> void:
	pass


func _if_mouse_motion_handle_check_edge_pan_release(event:InputEvent) -> void:
	pass
