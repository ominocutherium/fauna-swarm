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

class_name SpeciesDisplayStaticData

extends Resource

const STRING_ATTRIBUTES := [
	"purity_tex_path",
	"specter_tex_path",
	"pestilent_tex_path",
	"sanguine_tex_path",
	"artifice_tex_path",
	"upgrade_0_tex_path",
	"upgrade_1_tex_path",
]
const INT_ATTRIBUTES := [
	"num_frames_idle",
	"num_frames_moving",
	"num_frames_attacking",
	"sprite_size_h",
	"sprite_size_v",
	"offset_h",
	"offset_v",
	"purity_pos_x",
	"purity_pos_y",
	"specter_pos_x",
	"specter_pos_y",
	"purity_up_pos_x",
	"purity_up_pos_x",
	"specter_up_pos_x",
	"specter_up_pos_x",
]
const REAL_ATTRIBUTES := [
	"frames_per_second",
]
const FILTER_ATTRIBUTES := {}
const VARIANT_ATTRIBUTES := []

export(int) var num_frames_idle : int
export(int) var num_frames_moving : int
export(int) var num_frames_attacking : int
export(int) var sprite_size_h : int setget set_sprite_size_h
export(int) var sprite_size_v : int setget set_sprite_size_v
export(int) var offset_h : int setget set_offset_h
export(int) var offset_v : int setget set_offset_v
export(float) var frames_per_second : float
export(String) var purity_tex_path : String = ""
export(String) var specter_tex_path : String = ""
export(String) var pestilent_tex_path : String = ""
export(String) var sanguine_tex_path : String = ""
export(String) var artifice_tex_path : String = ""
export(String) var upgrade_0_tex_path : String = ""
export(String) var upgrade_1_tex_path : String = ""

var purity_pos_x : float
var purity_pos_y : float
var specter_pos_x : float
var specter_pos_y : float
var purity_up0_pos_x : float
var purity_up0_pos_y : float
var specter_up0_pos_x : float
var specter_up0_pos_y : float
var purity_up1_pos_x : float
var purity_up1_pos_y : float
var specter_up1_pos_x : float
var specter_up1_pos_y : float
var purity_sprite_rect : Rect2 setget ,get_spr_rect_purity_unit
var specter_sprite_rect : Rect2 setget ,get_spr_rect_specter_unit
var purity_up0_sprite_rect : Rect2 setget ,get_spr_rect_purity_up0
var purity_up1_sprite_rect : Rect2 setget ,get_spr_rect_purity_up1
var specter_up0_sprite_rect : Rect2 setget ,get_spr_rect_specter_up0
var specter_up1_sprite_rect : Rect2 setget ,get_spr_rect_specter_up1


var sprite_size : Vector2
var offset : Vector2

func get_tex_for_faction(faction:int) -> Texture:
	match faction:
		StaticData.engine_keys_to_faction_ids.purity:
			return load(purity_tex_path) as Texture
		StaticData.engine_keys_to_faction_ids.specter:
			return load(specter_tex_path) as Texture
		StaticData.engine_keys_to_faction_ids.sanguine:
			return load(sanguine_tex_path) as Texture
		StaticData.engine_keys_to_faction_ids.artifice:
			return load(artifice_tex_path) as Texture
		StaticData.engine_keys_to_faction_ids.pestilence:
			return load(pestilent_tex_path) as Texture
		_:
			return null


func set_sprite_size_h(to:int) -> void:
	sprite_size_h = to
	sprite_size = Vector2(sprite_size_h,sprite_size_v)


func set_sprite_size_v(to:int) -> void:
	sprite_size_v = to
	sprite_size = Vector2(sprite_size_h,sprite_size_v)


func set_offset_h(to:int) -> void:
	offset_h = to
	offset = Vector2(offset_h,offset_v)


func set_offset_v(to:int) -> void:
	offset_v = to
	offset = Vector2(offset_h,offset_v)


func get_spr_rect_purity_unit() -> Rect2:
	return Rect2(purity_pos_x,purity_pos_y,sprite_size_h,sprite_size_v)


func get_spr_rect_specter_unit() -> Rect2:
	return Rect2(specter_pos_x,specter_pos_y,sprite_size_h,sprite_size_v)


func get_spr_rect_purity_up0() -> Rect2:
	return Rect2(purity_up0_pos_x,purity_up0_pos_y,sprite_size_h,sprite_size_v)


func get_spr_rect_purity_up1() -> Rect2:
	return Rect2(purity_up1_pos_x,purity_up1_pos_y,sprite_size_h,sprite_size_v)


func get_spr_rect_specter_up0() -> Rect2:
	return Rect2(specter_up0_pos_x,specter_up0_pos_y,sprite_size_h,sprite_size_v)


func get_spr_rect_specter_up1() -> Rect2:
	return Rect2(specter_up1_pos_x,specter_up1_pos_y,sprite_size_h,sprite_size_v)
