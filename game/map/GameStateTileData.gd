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

extends Resource

class_name MapTileData


# warning-ignore:unused_signal
signal tile_updated(coords,tile_type)


export(Rect2) var extents : Rect2
export(PoolIntArray) var tile_data : PoolIntArray

func apply_to_tilemap(tm:TileMap) -> void:
	var row_size := int(extents.size.x)
	for j in range(int(extents.size.y)):
		for i in range(int(extents.size.x)):
			tm.set_cellv(extents.position+Vector2(i,j),tile_data[j*row_size+i])


func extract_from_tilemap(tm:TileMap) -> void:
	extents = tm.get_used_rect()
	tile_data = PoolIntArray()
	for j in range(int(extents.size.y)):
		for i in range(int(extents.size.x)):
			tile_data.append(tm.get_cellv(extents.position + Vector2(i,j)))




func init_newgame_map_from_mapfile(new_game_map:StartingMapResource) -> RandomNumberGenerator:
	extents = new_game_map.extents
	tile_data.resize(new_game_map.tile_data.size())
	return null
