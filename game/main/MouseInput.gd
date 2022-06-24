extends Node2D


const MIN_SELECTION_SIZE = 50.0
const MIN_SELECTION_MOUSEDOWN_TIME = 0.1


signal rect_updated(selection_rect)
signal rect_released(selection_rect)
signal request_pan_camera(amount)
signal location_right_clicked(location)
signal location_left_clicked(location)

export(Color) var selection_color : Color
export(float) var selection_line_width : float
export(float) var mouse_edge_camera_pan_speed : float
export(float,0.0,1.0) var edge_margin_h : float
export(float,0.0,1.0) var edge_margin_v : float


var _left_down_for_drag : bool = false
var _left_down_time : float = 0.0
var _middle_down_for_pan : bool = false
var _right_down_for_action : bool = false
var _edge_pan_magnitude_this_frame : Vector2 = Vector2()
var _selection_rect := Rect2()
var _lines := []

onready var margin_h_in_pixels := edge_margin_h * get_tree().root.size.x
onready var margin_v_in_pixels := edge_margin_v * get_tree().root.size.y
onready var right_margin_begin := get_tree().root.size.x - margin_h_in_pixels
onready var bottom_margin_begin := get_tree().root.size.y - margin_v_in_pixels


func _ready() -> void:
	_create_lines()


func _unhandled_input(event: InputEvent) -> void:
	_if_mouse_button_handle_press_release(event)


func _input(event: InputEvent) -> void:
	_if_mouse_motion_handle_check_edge_pan_release(event)


func _process(delta: float) -> void:
	if _left_down_for_drag:
		_left_down_time += delta
	if _edge_pan_magnitude_this_frame != Vector2():
		emit_signal("request_pan_camera",mouse_edge_camera_pan_speed*_edge_pan_magnitude_this_frame*delta)


func _if_mouse_button_handle_press_release(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			BUTTON_LEFT:
				if event.pressed:
					_left_down_for_drag = true
					_left_down_time = 0.0
					_selection_rect.position = make_canvas_position_local(event.position)
					_selection_rect.end = _selection_rect.position
				else:
					_selection_rect.end = make_canvas_position_local(event.position)
					_left_down_for_drag = false
					if _selection_rect.get_area() > MIN_SELECTION_SIZE and _left_down_time > MIN_SELECTION_MOUSEDOWN_TIME:
						emit_signal("rect_released",_selection_rect)
					else:
						emit_signal("location_left_clicked",make_canvas_position_local(event.position))
					_selection_rect = Rect2()
					for line in _lines:
						line.hide()
			BUTTON_MIDDLE:
				if event.pressed:
					_middle_down_for_pan = true
				else:
					_middle_down_for_pan = false
			BUTTON_RIGHT:
				if event.pressed:
					_right_down_for_action = true
				else:
					_right_down_for_action = false
					emit_signal("location_right_clicked",make_canvas_position_local(event.position))


func _if_mouse_motion_handle_check_edge_pan_release(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _middle_down_for_pan:
			emit_signal("request_pan_camera",event.relative)
			return
		if _left_down_for_drag:
			_selection_rect.end = make_canvas_position_local(event.position)
			if _left_down_time > MIN_SELECTION_MOUSEDOWN_TIME and abs(_selection_rect.get_area()) > MIN_SELECTION_SIZE:
				_update_lines_with_rect(_selection_rect)
			emit_signal("rect_updated",_selection_rect)
			return

		if event.position.x < margin_h_in_pixels:
			_edge_pan_magnitude_this_frame.x = (event.position.x-margin_h_in_pixels) / margin_h_in_pixels
		elif event.position.x > right_margin_begin:
			_edge_pan_magnitude_this_frame.x = (event.position.x - right_margin_begin) / margin_h_in_pixels
		else:
			_edge_pan_magnitude_this_frame.x = 0.0

		if event.position.y < margin_v_in_pixels:
			_edge_pan_magnitude_this_frame.y = (event.position.y-margin_v_in_pixels) / margin_v_in_pixels
		elif event.position.y > bottom_margin_begin:
			_edge_pan_magnitude_this_frame.y = (event.position.y - bottom_margin_begin) / margin_v_in_pixels
		else:
			_edge_pan_magnitude_this_frame.y = 0.0


func _create_lines() -> void:
	for i in range(4):
		var line := Line2D.new()
		_lines.append(line)
		line.points = PoolVector2Array([Vector2(),Vector2()])
		line.default_color = selection_color
		line.width = selection_line_width
		add_child(line)


func _get_line(idx:int) -> Line2D:
	return _lines[idx] as Line2D


func _update_lines_with_rect(selection_rect:Rect2) -> void:
	for line in _lines:
		line.show()
	_get_line(0).points[0] = selection_rect.position
	_get_line(1).points[0] = selection_rect.position
	_get_line(0).points[1].y = selection_rect.position.y
	_get_line(0).points[1].x = selection_rect.end.x
	_get_line(1).points[1].x = selection_rect.position.x
	_get_line(1).points[1].y = selection_rect.end.y
	_get_line(2).points[0].y = selection_rect.position.y
	_get_line(2).points[0].x = selection_rect.end.x
	_get_line(2).points[1] = selection_rect.end
	_get_line(3).points[0].x = selection_rect.position.x
	_get_line(3).points[0].y = selection_rect.end.y
	_get_line(3).points[1] = selection_rect.end
