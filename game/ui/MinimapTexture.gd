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

extends ImageTexture

class_name MinimapTexture

signal texture_updated


enum TilePaints {PURITY_TILE,EVIL_TILE,OBSTACLE,PURITY_BUILDING,FACTIONLESS_BUILDING,EVIL_BUILDING,PURITY_UNIT,EVIL_UNIT}


export(Color) var purity_units_color := Color.cyan
export(Color) var purity_buildings_color := Color.aquamarine
export(Color) var purity_tile_color := Color.darkgreen
export(Color) var evil_tile_color := Color.darkslateblue
export(Color) var obstacle_color := Color.black
export(Color) var factionless_building_color := Color.gray
export(Color) var evil_building_color := Color.darkmagenta
export(Color) var evil_units_color := Color.magenta
export(Color) var camera_boundary_color := Color.red
export(Vector2) var physics_space_to_display_space_x_basis : Vector2 = Vector2.RIGHT
export(Vector2) var physics_space_to_display_space_y_basis : Vector2 = Vector2.DOWN

var image : Image
var current_camera_location : Vector2 setget set_current_camera_location
var _translated_camera_loc : Vector2
var _row_size : int = -1
var _rect : Rect2

func _init() -> void:
	image = Image.new()
	_rect = Rect2(0,0,400,200)
	image.create(400,200,false,Image.FORMAT_RGB8)
	create_from_image(image)

func paint_layout() -> void:
	image.lock()
	var total_pixels : int = int(GameState.background_tiles.tile_data.size())
	for i in range(total_pixels):
		var color_to_paint : Color = Color.white
		var paint_coords := get_starting_tex_coords_from_tile_idx(i)
		var tile_type_identifier : String = GameState.background_tiles._tile_identifiers_by_tilemap_id[GameState.background_tiles.tile_data[i]]
		if tile_type_identifier.ends_with("obstacle"):
			color_to_paint = obstacle_color
		elif tile_type_identifier.begins_with("purity"):
			color_to_paint = purity_tile_color
		else:
			color_to_paint = evil_tile_color
		image.set_pixelv(paint_coords,color_to_paint)
		image.set_pixelv(paint_coords+Vector2.RIGHT,color_to_paint)
		if i + _row_size < total_pixels and (i+1) % _row_size > 0:
			image.set_pixelv(paint_coords+Vector2.DOWN,color_to_paint)
			image.set_pixelv(paint_coords+Vector2.RIGHT+Vector2.DOWN,color_to_paint)
	_paint_camera_loc()
	image.unlock()
	set_data(image)
	emit_signal("texture_updated")

func get_starting_tex_coords_from_tile_idx(idx:int) -> Vector2:
	if _row_size < 0:
		_row_size = int(GameState.background_tiles.extents.size.x)
	var data_x_coords : int = idx % _row_size
	var data_y_coords : int = idx / _row_size
	return Vector2(198+2*data_x_coords-2*data_y_coords,data_x_coords+data_y_coords)

func set_current_camera_location(to:Vector2) -> void:
	current_camera_location = to
	var translated_loc : Vector2 = Vector2(floor(current_camera_location.x/16.0),floor(current_camera_location.y/16.0)) + Vector2(200,0)
	var changed : bool = true if translated_loc != _translated_camera_loc else false
	_translated_camera_loc = translated_loc
	if changed:
		paint_layout()

func _paint_camera_loc() -> void:
	for i in range(50):
		var pixelv := Vector2(_translated_camera_loc.x-25.0+i,_translated_camera_loc.y-18.0)
		if _rect.has_point(pixelv):
			image.set_pixelv(pixelv,camera_boundary_color)
	for i in range(50):
		var pixelv := Vector2(_translated_camera_loc.x-25.0+i,_translated_camera_loc.y+19.0)
		if _rect.has_point(pixelv):
			image.set_pixelv(pixelv,camera_boundary_color)
	for i in range(37):
		var pixelv := Vector2(_translated_camera_loc.x-25.0,_translated_camera_loc.y-18.0+i)
		if _rect.has_point(pixelv):
			image.set_pixelv(pixelv,camera_boundary_color)
	for i in range(37):
		var pixelv := Vector2(_translated_camera_loc.x+25.0,_translated_camera_loc.y-18.0+i)
		if _rect.has_point(pixelv):
			image.set_pixelv(pixelv,camera_boundary_color)
