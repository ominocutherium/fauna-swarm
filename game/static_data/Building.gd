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

class_name BuildingStaticData

extends Resource

const STRING_ATTRIBUTES := [
	"name_key",
	"texture_path",
	"effects",
]
const INT_ATTRIBUTES := [
	"len_h_tiles",
	"len_v_tiles",
	"queue_len",
]
const REAL_ATTRIBUTES := [
	"texture_pos_x",
	"texture_pos_y",
	"texture_offs_x",
	"texture_offs_y",
	"texture_size_x",
	"texture_size_y",
	"build_progress_per_s",
]
const FILTER_ATTRIBUTES := {
	"faction":"ids_of_factions",
}
const VARIANT_ATTRIBUTES := []


export(int) var identifier : int
export(String) var name_key : String
export(int) var len_h_tiles : int
export(int) var len_v_tiles : int
export(int) var faction : int
export(int) var queue_len : int
export(float) var maximum_health : float
export(float) var build_progress_per_s : float
export(int) var cost_to_build : int
export(String) var texture_path : String
export(Vector2) var texture_position : Vector2
export(Vector2) var texture_offset : Vector2
export(Vector2) var texture_size : Vector2
export(Array) var effects : Array

var texture_pos_x : float setget set_tex_pos_x
var texture_pos_y : float setget set_tex_pos_y
var texture_size_x : float setget set_tex_size_x
var texture_size_y : float setget set_tex_size_y
var texture_offs_x : float setget set_tex_offs_x
var texture_offs_y : float setget set_tex_offs_y
var ids_of_factions : Dictionary setget ,get_ids_of_factions

func get_ids_of_factions() -> Dictionary:
	# custom modification to the generated dictionary from static data
	# honestly, the default behavior is to not set the building's faction if the value isn't found in the dictionary,
	# but this makes it clear exactly what is intended (and at least one building type is intended to be factionless)
	var copy_dict : Dictionary = StaticData.engine_keys_to_faction_ids.duplicate()
	copy_dict["factionless"] = -1
	return copy_dict


func set_tex_pos_x(value:float) -> void:
	texture_pos_x = value
	texture_position = Vector2(texture_pos_x,texture_pos_y)


func set_tex_pos_y(value:float) -> void:
	texture_pos_y = value
	texture_position = Vector2(texture_pos_x,texture_pos_y)


func set_tex_size_x(value:float) -> void:
	texture_size_x = value
	texture_size = Vector2(texture_size_x,texture_size_y)


func set_tex_size_y(value:float) -> void:
	texture_size_y = value
	texture_size = Vector2(texture_size_x,texture_size_y)


func set_tex_offs_x(value:float) -> void:
	texture_offs_x = value
	texture_offset = Vector2(texture_offs_x,texture_offs_y)


func set_tex_offs_y(value:float) -> void:
	texture_offs_y = value
	texture_offset = Vector2(texture_offs_x,texture_offs_y)
