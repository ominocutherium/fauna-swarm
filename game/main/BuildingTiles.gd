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

extends TileDisplay


const TILE_BUILDING_BASE : int = 0
const TILE_BUILDING_ADDL : int = 1


signal building_built(identifier,type,cellv)
signal building_removed(identifier)
signal tile_covered_by_building(tilev)
signal tile_uncovered_by_building(tilev)


var boundaries : Rect2
var building_identifiers_by_tilev := {}
var building_base_tile_by_identifier := {}
var lists_of_tilevs_by_building_identifier := {}
var building_types_by_identifier := {}
var _unused_identifiers := []
var _used_identifiers_size : int = 0


func set_map_size(top_left_boundary:Vector2,bottom_right_boundary:Vector2) -> void:
	# Required on map init
	boundaries = Rect2()
	boundaries.position = top_left_boundary
	boundaries.end = bottom_right_boundary


func can_build_building(display_coords:Vector2,building_width:int,building_depth:int) -> bool:
	var base_tile_v := world_to_map(display_coords)
	for i in range(int(base_tile_v.x)-building_width,int(base_tile_v.x)):
		for j in range(int(base_tile_v.y)-building_depth,int(base_tile_v.y)):
			if i < boundaries.position.x or i > boundaries.end.x or j < boundaries.position.y or j > boundaries.end.y:
				return false
			if get_cellv(Vector2(i,j)) != -1:
				return false
	return true


func build_building(display_coords:Vector2,building_type:int,building_width:int,building_depth:int,with_identifier:int=-1) -> void:
	# with_identifier used on gamestate restore. When during active gameplay, always use _get_unused_identifier
	var base_tile_v := world_to_map(display_coords)
	var building_identifier := _get_unused_identifier() if with_identifier == -1 else with_identifier
	var list_of_tilevs := []
	for i in range(int(base_tile_v.x)-building_width,int(base_tile_v.x)):
		for j in range(int(base_tile_v.y)-building_depth,int(base_tile_v.y)):
			var tilev := Vector2(i,j)
			list_of_tilevs.append(tilev)
			if tilev == base_tile_v:
				building_base_tile_by_identifier[building_identifier] = base_tile_v
				set_cellv(base_tile_v,TILE_BUILDING_BASE)
			else:
				set_cellv(tilev,TILE_BUILDING_ADDL)
			emit_signal("tile_covered_by_building",tilev)
			building_identifiers_by_tilev[tilev] = building_identifier
	lists_of_tilevs_by_building_identifier[building_identifier] = list_of_tilevs
	building_types_by_identifier[building_identifier] = building_type
	if building_identifier >= _used_identifiers_size:
		for i in range(_used_identifiers_size,building_identifier): # will stop just before building_identifier
			if not i in building_types_by_identifier:
				_unused_identifiers.append(i)
		_used_identifiers_size = building_identifier + 1
	emit_signal("building_built",building_identifier,building_type,base_tile_v)


func remove_building(identifier:int) -> void:
	if not identifier in building_base_tile_by_identifier:
		return
	var base_tile_v : Vector2 = building_base_tile_by_identifier[identifier]
	for tilev in lists_of_tilevs_by_building_identifier[identifier]:
		set_cellv(tilev,-1)
		if building_identifiers_by_tilev.has(tilev):
			building_identifiers_by_tilev.erase(tilev)
		emit_signal("tile_uncovered_by_building",tilev)
	building_base_tile_by_identifier.erase(identifier)
	lists_of_tilevs_by_building_identifier.erase(identifier)
	building_types_by_identifier.erase(identifier)
	_unused_identifiers.append(identifier)
	emit_signal("building_removed",identifier)


func _get_unused_identifier() -> int:
	if _unused_identifiers.size() > 0:
		return _unused_identifiers.pop_front()
	var id := _used_identifiers_size
	_used_identifiers_size += 1
	return id
