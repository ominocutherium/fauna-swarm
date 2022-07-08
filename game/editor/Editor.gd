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


func _ready() -> void:
	save_to_res()


func save_to_res() -> void:
	var save_res := StartingMapResource.new()
	save_res.extents = get_used_rect()
	save_res.tile_data.resize(int(save_res.extents.size.x*save_res.extents.size.y))
	for t in tile_set.get_tiles_ids():
		var tile_id : int = t
		if save_res.tile_type_names_by_id.size() < tile_id + 1:
			save_res.tile_type_names_by_id.resize(tile_id + 1)
		save_res.tile_type_names_by_id[tile_id] = tile_set.tile_get_name(tile_id)
	for tile_v in get_used_cells(): # make sure to actually paint every cell in the rectangle
		save_res.tile_data[int(tile_v.x+tile_v.y*save_res.extents.size.x)] = get_cellv(tile_v)

	if cosmetic_rng_seed == "":
		randomize()
		save_res.cosmetic_randomization_seed = randi()
	else:
		save_res.cosmetic_randomization_seed = hash(cosmetic_rng_seed)
	ResourceSaver.save(save_to,save_res)
