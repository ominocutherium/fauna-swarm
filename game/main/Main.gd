extends Node2D

export(NodePath) var hud_path : NodePath
export(NodePath) var mouse_input_path : NodePath
export(NodePath) var foreground_disp_path : NodePath
export(NodePath) var background_tilemap_path : NodePath
export(NodePath) var building_tilemap_path : NodePath
export(NodePath) var order_input_handler_path : NodePath


onready var heads_up_display : HeadsUpDisplay = get_node(hud_path)
onready var mouse_input_handler : MouseInputHandler = get_node(mouse_input_path)
onready var foreground_display : ForegroundDisplay = get_node(foreground_disp_path)
onready var background_tilemap : TileMap = get_node(background_tilemap_path)
onready var building_tilemap : TileMap = get_node(building_tilemap_path)
onready var order_input_handler : OrderInputHandler = get_node(order_input_handler_path)


func _ready() -> void:
	get_tree().paused = true
	if GameState.building_tiles != null:
		initialize_or_restore_map_state()
	UnitManager.connect("unit_moved",self,"_on_unit_moved")


func _process(delta: float) -> void:
	pass


func initialize_or_restore_map_state() -> void:
	GameState.background_tiles.apply_to_tilemap($"Background Tiles")
	GameState.building_tiles.apply_to_tilemap($"Building Tiles")
	get_tree().paused = false


func _on_unit_moved(identifier:int,to:Vector2) -> void:
	# UnitManager reports locations in physics space, so we need to translate to display space
	var display_space_position : Vector2 = mouse_input_handler.physics_space_to_display_space_transform.xform(to)
	foreground_display.move_unit(identifier,display_space_position)


func _on_MouseInput_location_left_clicked(location : Vector2, selection_radius : float, selection_radius_squared : float) -> void:
	# prioritize finding a building over finding a unit over finding a position
	var building_identifier : int = _get_building_within_display_loc(location)
	if building_identifier != -1:
		pass # TODO: implement
		return
	var xformed_pos : Vector2 = mouse_input_handler.display_space_to_physics_space_transform.xform(location)
	var nearest_unit := UnitManager.get_closest_unit_to_position_within_radius(xformed_pos,selection_radius,selection_radius_squared)
	if nearest_unit != -1:
		heads_up_display.units_selected([nearest_unit])
		order_input_handler.list_of_selected_unit_identifiers = [nearest_unit]
	else:
		order_input_handler.targeted_position = xformed_pos


func _on_MouseInput_location_right_clicked(location : Vector2, selection_radius : float, selection_radius_squared : float) -> void:
	# prioritize finding a building over finding a unit over finding a position
	var building_identifier : int = _get_building_within_display_loc(location)
	if building_identifier != -1:
		pass # TODO: implement
		return
	var nearest_unit : int = -1
	var xformed_pos : Vector2 = mouse_input_handler.display_space_to_physics_space_transform.xform(location)
	nearest_unit = UnitManager.get_closest_unit_to_position_within_radius(xformed_pos,selection_radius,selection_radius_squared)
	# right-click implies a shortcut for immediately ordering something without specifying the order so call special public methods
	if nearest_unit != -1:
		order_input_handler.set_targeted_unit_identifier_and_order_attack(nearest_unit) # TODO: check for held modifiers to modify the order
	else:
		order_input_handler.set_targeted_position_and_move_if_no_other_order(xformed_pos)


func _get_building_within_display_loc(location : Vector2) -> int:
	var cell : Vector2 = building_tilemap.world_to_map(location)
	if building_tilemap.get_cellv(cell) != -1:
		pass # TODO: implement when building data model available
	return -1


func _on_MouseInput_rect_released(selection_rect:Rect2,xformed_rect:Rect2,xformed_midpoints:Array,xformed_normals:Array) -> void:
#	print(("{0} selection finished. Corresponds to rect in physics space of {1} and rect is a diamond in physics space with midpoints {2}").format([
#			selection_rect,xformed_rect,str(xformed_midpoints)]))
	var units_inside := UnitManager.get_units_inside_selection(xformed_rect,xformed_midpoints,xformed_normals)
	# TODO: if no units were selected, try to select a building instead
	var unit_objs := []
	for identifier in units_inside:
		unit_objs.append(GameState.units[identifier])
	heads_up_display.units_selected(unit_objs)
	order_input_handler.list_of_selected_unit_identifiers = units_inside
	# TODO: if nothing was overlapped even after checking for building, tell HUD to deselect everything


func _on_MouseInput_rect_updated(selection_rect:Rect2,xformed_rect:Rect2,xformed_midpoints:Array,xformed_normals:Array) -> void:
	var units_inside := UnitManager.get_units_inside_selection(xformed_rect,xformed_midpoints,xformed_normals)
	var unit_objs := []
	for identifier in units_inside:
		unit_objs.append(GameState.units[identifier])
	heads_up_display.units_selected(unit_objs)
	# if no units were overlapped then do nothing, the selection isn't completed yet

