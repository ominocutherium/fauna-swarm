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

extends MapTileData

class_name GameStateBuildingData

var building_ids_by_tile := {}
var _purity_building_count := 0
var _sp_resource_building_count := 0


func get_num_of_purity_buildings() -> int:
	return 0


func get_num_of_buildings_which_use_special_resource() -> int:
	return 0


func get_coords_of_nearest_purity_building_to(coords:Vector2) -> Vector2:
	return Vector2()


func add_building(building:SavedBuilding,where_coords:Vector2) -> void:
	var building_type = StaticData.get_building(building.building_type)
	var starting_x : int = int(where_coords.x-building_type.len_h_tiles-extents.position.x)
	var starting_y : int = int(where_coords.y-building_type.len_v_tiles-extents.position.y)
	var starting_idx : int = starting_x + int(extents.size.x) * starting_y
	for i in range(building_type.len_h_tiles):
		for j in range(building_type.len_v_tiles):
			var idx : int = starting_x + i + (j+starting_y) * int(extents.size.x)
			tile_data[idx] = 0
			building_ids_by_tile[idx] = building.identifier


func remove_building(identifier:int) -> void:
	var building : SavedBuilding = GameState.buildings[identifier]
	var building_type = StaticData.get_building(building.building_type)
	var starting_x : int = building.main_tile_x
	var starting_y : int = building.main_tile_y
	var starting_idx : int = starting_x + int(extents.size.x) * starting_y
	for i in range(building_type.len_h_tiles):
		for j in range(building_type.len_v_tiles):
			var idx : int = starting_x + i + (j+starting_y) * int(extents.size.x)
			tile_data[idx] = -1
			if building_ids_by_tile.has(idx):
				building_ids_by_tile.erase(idx)


func is_spot_valid_for_building(building_type:BuildingStaticData,position:Vector2) -> bool:
	var coords : Vector2 = Vector2(floor(position.x/UnitManager.TILE_LEN),floor(position.y/UnitManager.TILE_LEN))
	if coords.x >= extents.end.x or coords.y >= extents.end.y:
		return false
	var starting_x : int = int(coords.x-building_type.len_h_tiles-extents.position.x)
	var starting_y : int = int(coords.y-building_type.len_v_tiles-extents.position.y)
	if starting_x < 0 or starting_y < 0:
		return false
	var starting_idx : int = starting_x + int(extents.size.x) * starting_y
	for i in range(building_type.len_h_tiles):
		for j in range(building_type.len_v_tiles):
			var idx_to_check : int = starting_x + i + (j+starting_y) * int(extents.size.x)
			if tile_data[idx_to_check] != -1:
				return false
	return true


func get_id_for_building_in_tile(position:Vector2) -> int:
	var coords : Vector2 = Vector2(floor(position.x/UnitManager.TILE_LEN),floor(position.y/UnitManager.TILE_LEN))
	if coords.x >= extents.end.x or coords.y >= extents.end.y:
		return -1
	var x_coord : int = int(coords.x-extents.position.x)
	var y_coord : int = int(coords.y-extents.position.y)
	if x_coord < 0 or y_coord < 0:
		return -1
	var tile_idx : int = x_coord + int(extents.size.x) * y_coord
	if tile_idx in building_ids_by_tile:
		return building_ids_by_tile[tile_idx]
	return -1
