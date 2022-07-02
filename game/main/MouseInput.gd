extends Node2D

class_name MouseInputHandler


const MIN_SELECTION_SIZE = 50.0
const MIN_SELECTION_MOUSEDOWN_TIME = 0.1


signal rect_updated(selection_rect,physics_space_enclosing_rect,physics_space_disp_rect_diamond_midpoints,physics_space_sel_diamond_normals)
signal rect_released(selection_rect,physics_space_enclosing_rect,physics_space_disp_rect_diamond_midpoints,physics_space_sel_diamond_normals)
signal request_pan_camera(amount)
signal location_right_clicked(location,detection_radius,detection_radius_squared)
signal location_left_clicked(location,detection_radius,detection_radius_squared)

export(Color) var selection_color : Color
export(float) var selection_line_width : float
export(float) var mouse_edge_camera_pan_speed : float
export(float,0.0,1.0) var edge_margin_h : float
export(float,0.0,1.0) var edge_margin_v : float
export(Vector2) var physics_space_to_display_space_x_basis : Vector2 = Vector2.RIGHT
export(Vector2) var physics_space_to_display_space_y_basis : Vector2 = Vector2.DOWN
export(float) var selection_rect_grow_amount := 0.0
export(float) var single_click_detection_radius : float = 12.0


var _left_down_for_drag : bool = false
var _left_down_in_minimap_diamond : bool = false
var _left_down_time : float = 0.0
var _middle_down_for_pan : bool = false
var _right_down_for_action : bool = false
var _edge_pan_magnitude_this_frame : Vector2 = Vector2()
var _selection_rect := Rect2()
var _lines := []

onready var selection_radius_squared = single_click_detection_radius * single_click_detection_radius
onready var margin_h_in_pixels := edge_margin_h * get_tree().root.size.x
onready var margin_v_in_pixels := edge_margin_v * get_tree().root.size.y
onready var right_margin_begin := get_tree().root.size.x - margin_h_in_pixels
onready var bottom_margin_begin := get_tree().root.size.y - margin_v_in_pixels
onready var minimap_diamond_midpoints := [
	0.5*(Vector2(600,500)+Vector2(400,400)),
	0.5*(Vector2(400,600)+Vector2(600,500)),
	0.5*(Vector2(400,600)+Vector2(200,500)),
	0.5*(Vector2(400,400)+Vector2(200,500)),
]
onready var minimap_diamond_normals := [
	Vector2(-2,1).normalized(),
	Vector2(-2,-1).normalized(),
	Vector2(2,-1).normalized(),
	Vector2(2,1).normalized(),
]
onready var physics_space_to_display_space_transform : Transform2D = Transform2D(physics_space_to_display_space_x_basis,physics_space_to_display_space_y_basis,Vector2())
onready var display_space_to_physics_space_transform : Transform2D = physics_space_to_display_space_transform.affine_inverse()
onready var selection_diamond_normals_in_physics_space := [
	display_space_to_physics_space_transform.xform(Vector2(-1,0)).normalized(), # top right
	display_space_to_physics_space_transform.xform(Vector2(0,-1)).normalized(), # bottom right
	display_space_to_physics_space_transform.xform(Vector2(1,0)).normalized(), # bottom left
	display_space_to_physics_space_transform.xform(Vector2(0,1)).normalized(), # top left
]

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
					if _position_is_inside_minimap_diamond(event.position):
#						print("Selected inside minimap diamond.")
						_left_down_in_minimap_diamond = true
					else:
						_left_down_in_minimap_diamond = false
					_left_down_time = 0.0
					_selection_rect.position = make_canvas_position_local(event.position)
					_selection_rect.end = _selection_rect.position
				else:
					_selection_rect.end = make_canvas_position_local(event.position)
					_left_down_for_drag = false
					if _selection_rect.get_area() > MIN_SELECTION_SIZE and _left_down_time > MIN_SELECTION_MOUSEDOWN_TIME:
						var grown_rect := _selection_rect.grow(selection_rect_grow_amount)
						emit_signal("rect_released",
								grown_rect,
								_get_physics_space_rect_outside_mouse_diamond(grown_rect),
								_get_physics_space_mouse_diamond_midpoints(grown_rect),
								selection_diamond_normals_in_physics_space)
					else:
						emit_signal("location_left_clicked",make_canvas_position_local(event.position),single_click_detection_radius,selection_radius_squared)
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
					emit_signal("location_right_clicked",make_canvas_position_local(event.position),single_click_detection_radius,selection_radius_squared)


func _if_mouse_motion_handle_check_edge_pan_release(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _middle_down_for_pan:
			emit_signal("request_pan_camera",event.relative)
			return
		if _left_down_for_drag:
			_selection_rect.end = make_canvas_position_local(event.position)
			if _left_down_time > MIN_SELECTION_MOUSEDOWN_TIME and abs(_selection_rect.get_area()) > MIN_SELECTION_SIZE:
				_update_lines_with_rect(_selection_rect)
				var grown_rect := _selection_rect.grow(selection_rect_grow_amount)
				emit_signal("rect_updated",
						grown_rect,
						_get_physics_space_rect_outside_mouse_diamond(grown_rect),
						_get_physics_space_mouse_diamond_midpoints(grown_rect),
						selection_diamond_normals_in_physics_space)
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

func _position_is_inside_minimap_diamond(pos:Vector2) -> bool:
	for i in range(4):
		var compare_vector : Vector2 = (pos-minimap_diamond_midpoints[i]).normalized()
		if minimap_diamond_normals[i].dot(compare_vector) < 0:
#			print("Pos: {0} Midpoint of segment {1}:{2} Compare: {3} Normal: {4}".format([pos,i,minimap_diamond_midpoints[i],compare_vector,minimap_diamond_normals[i]]))
			return false
	return true


func _get_physics_space_rect_outside_mouse_diamond(mouse_rect_display_space:Rect2) -> Rect2:
	var left_midpoint : Vector2 = display_space_to_physics_space_transform.xform(mouse_rect_display_space.position)
	var right_midpoint : Vector2 = display_space_to_physics_space_transform.xform(mouse_rect_display_space.end)
	var top_midpoint : Vector2 = display_space_to_physics_space_transform.xform(
		Vector2(mouse_rect_display_space.end.x,mouse_rect_display_space.position.y)
	)
	var len_x : float = right_midpoint.x - left_midpoint.x
	var len_y : float = (top_midpoint.y - right_midpoint.y) * 2.0
	return Rect2(left_midpoint - Vector2(0,0.5)*len_x,Vector2(len_x,len_y))


func _get_physics_space_mouse_diamond_midpoints(mouse_rect_display_space:Rect2) -> Array:
	var top_right_corner : Vector2 = display_space_to_physics_space_transform.xform(
		Vector2(mouse_rect_display_space.end.x,mouse_rect_display_space.position.y)
	)
	var bottom_right_corner : Vector2 = display_space_to_physics_space_transform.xform(mouse_rect_display_space.end)
	var bottom_left_corner : Vector2 = display_space_to_physics_space_transform.xform(
		Vector2(mouse_rect_display_space.position.x,mouse_rect_display_space.end.y)
	)
	var top_left_corner : Vector2 = display_space_to_physics_space_transform.xform(mouse_rect_display_space.position)
	return [
			0.5*(top_right_corner + bottom_right_corner),
			0.5*(bottom_right_corner + bottom_left_corner),
			0.5*(bottom_left_corner + bottom_right_corner),
			0.5*(bottom_right_corner + top_right_corner),
			]

