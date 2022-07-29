# This file is a part of "Fauna Swarm", a game produced
# for "RTS Jam 1998" running from June 24th-July 28th on itch:
# <https://itch.io/jam/rts-jam-1998>

# A copy of the Godot 3.x editor is required to export this game.
# See <https://godotengine.org/license> for information about how
# Godot Engine is licensed.

# Gameplay code Copyright (C) 2022 ominocutherium and contributors

# The base game (but not the assets therein, which are licensed separately)
# is free software: you can redistribute it and/or modify it under the terms
# of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

extends Node2D

export(NodePath) var hud_path : NodePath
export(NodePath) var mouse_input_path : NodePath
export(NodePath) var foreground_disp_path : NodePath
export(NodePath) var background_tilemap_path : NodePath
export(NodePath) var building_tilemap_path : NodePath
export(NodePath) var order_input_handler_path : NodePath
export(NodePath) var minimap_path : NodePath
export(NodePath) var camera_path : NodePath


onready var heads_up_display : HeadsUpDisplay = get_node(hud_path)
onready var mouse_input_handler : MouseInputHandler = get_node(mouse_input_path)
onready var foreground_display : ForegroundDisplay = get_node(foreground_disp_path)
onready var background_tilemap : TileMap = get_node(background_tilemap_path)
onready var building_tilemap : TileMap = get_node(building_tilemap_path)
onready var order_input_handler : OrderInputHandler = get_node(order_input_handler_path)
onready var minimap = get_node(minimap_path)
onready var camera : Camera2D = get_node(camera_path)


func _ready() -> void:
	get_tree().paused = true
	if GameState.building_tiles != null:
		initialize_or_restore_map_state()
		foreground_display.reference_tm_for_sprite_tilevs = building_tilemap
		GameState.building_tiles.connect("tile_updated",building_tilemap,"_on_tile_updated_in_gamestate")
		GameState.background_tiles.connect("tile_updated",background_tilemap,"_on_tile_updated_in_gamestate")
		for unit in GameState.units:
			_add_unit_connections(unit)
			if unit.spawn_status == SavedUnit.Status.SPAWNED:
				spawn_existing_unit(unit.identifier,unit.position)
		for building in GameState.buildings:
			_add_building_connections(building)
			if building.build_progress == 1.0:
				foreground_display._on_building_completed(building)
		for faction in GameState.factions:
			if faction != null:
				(faction as SavedFaction).connect("request_unit_generation_from_income",self,"spawn_num_of_requested_units")
		GameState.set_process(true)
		get_tree().paused = false
	UnitManager.connect("unit_moved",self,"_on_unit_moved")
	order_input_handler.connect("report_build_building_order_in_progress",foreground_display,"spawn_phantom_building")
	if minimap.texture as MinimapTexture:
		camera.connect("moved",minimap.texture,"set_current_camera_location")


func spawn_num_of_requested_units(p_num:int,species:int,faction:int,where:Vector2,upgrade_equipped:int=-1) -> void:
	for _i in range(p_num):
		var identifier : int = GameState.add_unit(species,upgrade_equipped,faction)
		var unit : SavedUnit = GameState.get_unit(identifier)
		var actual_spawn_pos : Vector2 = where # TODO: maybe randomize the position a bit within a radius
		UnitManager.spawn_unit(identifier,actual_spawn_pos)
		foreground_display.spawn_unit(identifier,actual_spawn_pos)
		unit.set_spawned()
		GameState.factions[faction].add_unit(unit)
		_add_unit_connections(unit)


func spawn_existing_unit(identifier:int,where_tiles:Vector2) -> void:
	# some buildings do this
	var where : Vector2 = UnitManager.TILE_LEN * where_tiles
	GameState.get_unit(identifier).set_spawned()
	UnitManager.spawn_unit(identifier,where)
	foreground_display.spawn_unit(identifier,where)


func spawn_existing_unit_at(identifier:int,where:Vector2) -> void:
	UnitManager.spawn_unit(identifier,where)
	foreground_display.spawn_unit(identifier,where)


func initialize_or_restore_map_state() -> void:
	building_tilemap.set_map_size(GameState.building_tiles.extents.position,GameState.building_tiles.extents.end)
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
	var nearest_unit : int = UnitManager.get_closest_unit_to_position_within_radius(xformed_pos,selection_radius,selection_radius_squared)
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


func _on_MouseInput_rect_released(_selection_rect:Rect2,xformed_rect:Rect2,xformed_midpoints:Array,xformed_normals:Array) -> void:
#	print(("{0} selection finished. Corresponds to rect in physics space of {1} and rect is a diamond in physics space with midpoints {2}").format([
#			selection_rect,xformed_rect,str(xformed_midpoints)]))
	var units_inside : Array = UnitManager.get_units_inside_selection(xformed_rect,xformed_midpoints,xformed_normals)
	# TODO: if no units were selected, try to select a building instead
	var unit_objs := []
	for identifier in units_inside:
		unit_objs.append(GameState.units[identifier])
	heads_up_display.units_selected(unit_objs)
	order_input_handler.list_of_selected_unit_identifiers = units_inside
	# TODO: if nothing was overlapped even after checking for building, tell HUD to deselect everything


func _on_MouseInput_rect_updated(_selection_rect:Rect2,xformed_rect:Rect2,xformed_midpoints:Array,xformed_normals:Array) -> void:
	var units_inside : Array = UnitManager.get_units_inside_selection(xformed_rect,xformed_midpoints,xformed_normals)
	var unit_objs := []
	for identifier in units_inside:
		unit_objs.append(GameState.units[identifier])
	heads_up_display.units_selected(unit_objs)
	# if no units were overlapped then do nothing, the selection isn't completed yet


func _on_save_and_exit_requested() -> void:
	_save_game_incl_map_data()
	get_tree().quit()


func _on_save_and_back_to_mm_requested() -> void:
	_save_game_incl_map_data()
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main/MainMenu.tscn")


func _save_game_incl_map_data() -> void:
	GameState.background_tiles.extract_from_tilemap(background_tilemap)
	GameState.building_tiles.extract_from_tilemap(building_tilemap)
	GameState.save()


func _on_unit_defeated(unit:SavedUnit) -> void:
	UnitManager.despawn_unit(unit.identifier)
	foreground_display.despawn_unit(unit.identifier)
	if unit.faction == StaticData.engine_keys_to_faction_ids.purity:
		unit.set_in_limbo()
	else:
		GameState.get_faction(unit.faction).remove_unit(unit)


func _on_unit_captured(unit:SavedUnit) -> void:
	UnitManager.despawn_unit(unit.identifier)
	foreground_display.despawn_unit(unit.identifier)
	# updating unit's faction in the game state is already taken care of by Faction connections


func _add_unit_connections(unit:SavedUnit) -> void:
	if not unit.is_connected("defeated",self,"_on_unit_defeated"):
# warning-ignore:return_value_discarded
		unit.connect("defeated",self,"_on_unit_defeated",[unit])
	if not unit.is_connected("captured",self,"_on_unit_captured"):
# warning-ignore:return_value_discarded
		unit.connect("captured",self,"_on_unit_captured",[unit])
#	unit.connect("capture_attempt_failed",self,"_on_capture_attempt_failed",[unit]) # TODO: make a notifications object and connect this feedback-only signal to it


func _add_building_connections(building:SavedBuilding) -> void:
# warning-ignore:return_value_discarded
	building.connect("request_spawn_unit",self,"spawn_existing_unit")
	if building.build_progress < 1.0:
		building.connect("completed",foreground_display,"_on_building_completed",[building])
	building.connect("destroyed",foreground_display,"_on_building_removed",[building.identifier])
