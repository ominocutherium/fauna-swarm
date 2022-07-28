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

extends TileMap
# Do not export this (or the tileset it uses) with the game.
# Tile graphics do not matter but the names of tiles in the editor tileset do matter 
# (they have to match the names of functional tiles in the functional tiles spreadsheet).
# Run the scene to save the resource.


export(String,FILE) var save_to : String
export(String) var cosmetic_rng_seed : String
export(int) var num_placed_forest_hearts : int

var _found_forest_heart_locs := PoolVector2Array()
var _found_evil_faction_base_locs := PoolVector2Array()
var _found_purity_faction_starting_base_locs := PoolVector2Array()


func _ready() -> void:
	_detect_possible_forest_heart_locs()
	_detect_possible_locations("EvilCommand","_found_evil_faction_base_locs")
	_detect_possible_locations("PurityCommand","_found_purity_faction_starting_base_locs")
	save_to_res()


func save_to_res() -> void:
	var save_res := StartingMapResource.new()
	save_res.extents = get_used_rect()
	var tile_data := PoolIntArray()
	tile_data.resize(int(save_res.extents.size.x*save_res.extents.size.y))
	var t_t_names_by_id := PoolStringArray()
	for t in tile_set.get_tiles_ids():
		var tile_id : int = t
		if t_t_names_by_id.size() < tile_id + 1:
			t_t_names_by_id.resize(tile_id + 1)
		t_t_names_by_id[tile_id] = tile_set.tile_get_name(tile_id)
	save_res.tile_type_names_by_id = t_t_names_by_id
	save_res.number_of_unclaimed_forest_hearts = num_placed_forest_hearts
	save_res.forest_heart_possible_locations = _found_forest_heart_locs
	save_res.purity_spawn_possible_locations = _found_purity_faction_starting_base_locs
	save_res.evil_spawn_possible_locations = _found_evil_faction_base_locs
	for tile_v in get_used_cells(): # make sure to actually paint every cell in the rectangle
		var x_idx : int = int(tile_v.x-save_res.extents.position.x)
		var y_idx : int = int(tile_v.y-save_res.extents.position.y)
		tile_data[int(x_idx+y_idx*save_res.extents.size.x)] = get_cellv(tile_v)
	save_res.tile_data = tile_data

	if cosmetic_rng_seed == "":
		randomize()
		save_res.cosmetic_randomization_seed = randi()
	else:
		save_res.cosmetic_randomization_seed = hash(cosmetic_rng_seed)
	var err := ResourceSaver.save(save_to,save_res)
	if err == OK:
		print("Map successfully saved to {0}".format([save_to]))
	else:
		print("There was an issue saving the resource, error code {0}".format([err]))


func _detect_possible_forest_heart_locs() -> void:
	_detect_possible_locations("ForestHeart","_found_forest_heart_locs")
	if num_placed_forest_hearts > _found_forest_heart_locs.size():
		num_placed_forest_hearts = _found_forest_heart_locs.size()


func _detect_possible_locations(node_name_begins_with:String,property_name:String) -> void:
	var poolv2arr := PoolVector2Array()
	for child in get_children():
		if child is Node2D and child.name.begins_with(node_name_begins_with):
			poolv2arr.append(world_to_map(child.position))
	set(property_name,poolv2arr)
