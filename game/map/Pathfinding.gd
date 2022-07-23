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

extends Node


var pathfinding_for_normal_units : AStar2D
var pathfinding_for_flying_units : AStar2D


func set_map_and_obstacles_structure(game_map:StartingMapResource) -> void:
	# initializes the AStar objects.
	var num_tiles : int = int(game_map.extents.size.x*game_map.extents.size.y)
	pathfinding_for_normal_units = AStar2D.new()
	pathfinding_for_flying_units = AStar2D.new()
	pathfinding_for_flying_units.reserve_space(num_tiles)
	pathfinding_for_normal_units.reserve_space(num_tiles)
	for i in range(int(game_map.extents.position.x),int(game_map.extents.position.x+game_map.extents.size.x)):
		for j in range(int(game_map.extents.position.y),int(game_map.extents.position.y+game_map.extents.size.y)):
			var node_coords : Vector2 = (Vector2(i,j) + Vector2(0.5,0.5)) * UnitManager.TILE_LEN
			var pt_index : int = j*int(game_map.extents.size.x)+i
			pathfinding_for_flying_units.add_point(pt_index,node_coords)
			pathfinding_for_normal_units.add_point(pt_index,node_coords)
			if i > int(game_map.extents.position.x):
				var compare_pt : int = pt_index - 1
				pathfinding_for_flying_units.connect_points(pt_index,compare_pt)
				if _compare_points_should_be_connected(game_map,Vector2(i,j),Vector2(i-1,j)):
					pathfinding_for_normal_units.connect_points(pt_index,compare_pt)
			if j > int(game_map.extents.position.y):
				var compare_pt : int = pt_index - int(game_map.extents.position.x)
				pathfinding_for_flying_units.connect_points(pt_index,compare_pt)
				if _compare_points_should_be_connected(game_map,Vector2(i,j),Vector2(i,j-1)):
					pathfinding_for_normal_units.connect_points(pt_index,compare_pt)
			if i > int(game_map.extents.position.x) and j > int(game_map.extents.position.y):
				var compare_pt : int = pt_index - int(game_map.extents.position.x) - 1
				pathfinding_for_flying_units.connect_points(pt_index,compare_pt)
				if _compare_points_should_be_connected(game_map,Vector2(i,j),Vector2(i-1,j-1)):
					pathfinding_for_normal_units.connect_points(pt_index,compare_pt,sqrt(2.0))
			var functional_tilename_pt : String = game_map.tile_type_names_by_id[game_map.tile_data[pt_index]]
			var tiletype := GameState.background_tiles.get_tile_type_by_name(functional_tilename_pt)
			if 5.0 in tiletype.corner_elevations:
				UnitManager.spawn_obstacle(Vector2(i,j))
	var grown_map_for_obstacles : Rect2 = game_map.extents.grow(1.0)
	for i in range(int(grown_map_for_obstacles.position.x),int(grown_map_for_obstacles.position.x+grown_map_for_obstacles.size.x)):
		for j in range(int(grown_map_for_obstacles.position.y),int(grown_map_for_obstacles.position.y+grown_map_for_obstacles.size.y)):
			if i < game_map.extents.position.x or j < game_map.extents.position.y or \
					i >= game_map.extents.size.x+game_map.extents.position.x or \
					j >= game_map.extents.size.y+game_map.extents.position.y:
				UnitManager.spawn_obstacle(Vector2(i,j))


func _compare_points_should_be_connected(game_map : StartingMapResource,point_coords:Vector2,compare_coords : Vector2) -> bool:
	# Look at elevations
	var dist := point_coords - compare_coords
# warning-ignore:narrowing_conversion
	var point_idx_0 : int = point_coords.x + point_coords.y*game_map.extents.size.x
# warning-ignore:narrowing_conversion
	var point_idx_1 : int = compare_coords.x + compare_coords.y*game_map.extents.size.x
	var functional_tilename_pt : String = game_map.tile_type_names_by_id[game_map.tile_data[point_idx_0]]
	var functional_tilename_compare_pt : String = game_map.tile_type_names_by_id[game_map.tile_data[point_idx_1]]
	var tiletype_origin := GameState.background_tiles.get_tile_type_by_name(functional_tilename_pt)
	var tiletype_compare := GameState.background_tiles.get_tile_type_by_name(functional_tilename_compare_pt)
	match dist:
		Vector2.RIGHT:
			if tiletype_origin.corner_elevations_by_direction[Vector2(1,-1)] == tiletype_compare.corner_elevations_by_direction[Vector2(-1,-1)] \
				and tiletype_origin.corner_elevations_by_direction[Vector2(1,1)] == tiletype_compare.corner_elevations_by_direction[Vector2(-1,1)]:
					# top right of origin matches top left of compare
					# and bottom right of origin matches bottom left of compare
					return true
		Vector2.UP:
			if tiletype_origin.corner_elevations_by_direction[Vector2(-1,1)] == tiletype_compare.corner_elevations_by_direction[Vector2(-1,-1)] \
				and tiletype_origin.corner_elevations_by_direction[Vector2(1,1)] == tiletype_compare.corner_elevations_by_direction[Vector2(1,-1)]:
					# bottom left of origin matches top left of compare
					# and bottom right of origin matches top right of compare
					return true
		Vector2(1,1):
			if tiletype_origin.corner_elevations_by_direction[Vector2(1,1)] == tiletype_compare.corner_elevations_by_direction[Vector2(-1,-1)]:
				# bottom right of origin must match top left of compare but we're not done yet
				# must check two more tiles with the compare location to see if we can go "through" this diagonal
				if _compare_points_should_be_connected(game_map,compare_coords+Vector2(1,0),compare_coords) \
					and _compare_points_should_be_connected(game_map,compare_coords+Vector2(0,1),compare_coords):
						return true
	return false


func get_path_with_current_params(start_pos:Vector2,end_pos:Vector2,faction:int,unit_can_fly:bool=false) -> PoolVector2Array:
	var astar_to_use : AStar2D = pathfinding_for_flying_units if unit_can_fly else pathfinding_for_normal_units
	var nearest_starting_point : int = astar_to_use.get_closest_point(start_pos)
	var nearest_ending_point : int = astar_to_use.get_closest_point(end_pos)
	# setup obstacles
	var points_disabled := {}
	if not unit_can_fly:
		for coords in UnitManager.obstacle_idxs_by_coords:
			var node_coords : Vector2 = (coords + Vector2(0.5,0.5)) * UnitManager.TILE_LEN
			var point_idx : int = astar_to_use.get_closest_point(node_coords)
			if not point_idx in points_disabled:
				points_disabled[point_idx] = true
				astar_to_use.set_point_disabled(point_idx,true)
	for i in range(UnitManager.alive_unit_identifiers.size()):
		var identifier : int = UnitManager.alive_unit_identifiers[i]
		if identifier == -1:
			continue
		if UnitManager.alive_unit_factions[i] != faction:
			var nearest_point : int = astar_to_use.get_closest_point(UnitManager.alive_unit_positions[i])
			if not nearest_point in points_disabled:
				points_disabled[nearest_point] = true
				astar_to_use.set_point_disabled(nearest_point,true)
	var point_path : PoolVector2Array = astar_to_use.get_point_path(nearest_starting_point,nearest_ending_point)
	# cleanup
	for idx in points_disabled:
		astar_to_use.set_point_disabled(idx,false)
	return point_path
