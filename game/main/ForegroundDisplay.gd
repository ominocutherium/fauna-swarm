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

extends YSort

class_name ForegroundDisplay

var lists_of_static_sprites_by_tilev := {}
var reference_tm_for_sprite_tilevs : TileMap
var units_by_identifier := {}
var buildings_by_identifier := {}
var phantom_building : Node2D
var position_target : Node2D


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_move_phantom_building_according_to_cursor(event.relative)


func add_static_sprite(tex:Texture,region:Rect2,tex_offset:Vector2,base_location:Vector2) -> void:
	var sprite := _add_sprite(tex,region,tex_offset,base_location)
	if reference_tm_for_sprite_tilevs != null:
		var tilev := reference_tm_for_sprite_tilevs.world_to_map(base_location)
		if not lists_of_static_sprites_by_tilev.has(tilev):
			lists_of_static_sprites_by_tilev[tilev] = []
		lists_of_static_sprites_by_tilev[tilev].append(sprite)


func add_building_sprite(identifier:int,tex:Texture,region:Rect2,tex_offset:Vector2,base_location:Vector2) -> void:
	var building_sprite := _add_sprite(tex,region,tex_offset,base_location)
	if not buildings_by_identifier.has(identifier):
		buildings_by_identifier[identifier] = building_sprite


func spawn_unit(identifier:int,location:Vector2) -> void:
	var unit_sprite := UnitDisplay.new()
	unit_sprite.position = location
	add_child(unit_sprite)
	unit_sprite.initialize_from_unit(GameState.get_unit(identifier))
	unit_sprite.return_to_idle()
	if not units_by_identifier.has(identifier):
		units_by_identifier[identifier] = unit_sprite


func despawn_unit(identifier:int) -> void:
	if units_by_identifier.has(identifier):
		units_by_identifier[identifier].queue_free()
		units_by_identifier.erase(identifier)


func remove_building_sprite(identifier:int) -> void:
	if buildings_by_identifier.has(identifier):
		buildings_by_identifier[identifier].queue_free()
		buildings_by_identifier.erase(identifier)


func spawn_phantom_building(building_type:int) -> void:
	pass


func show_position_target() -> void:
	pass


func hide_position_target() -> void:
	pass


func _move_phantom_building_according_to_cursor(amount:Vector2) -> void:
	if phantom_building:
		phantom_building.position += amount


func _move_position_target_according_to_cursor(amount:Vector2) -> void:
	if position_target:
		position_target.position += amount


func despawn_phantom_building() -> void:
	if phantom_building != null and is_instance_valid(phantom_building):
		phantom_building.queue_free()
		phantom_building = null


func _add_sprite(tex:Texture,region:Rect2,tex_offset:Vector2,base_location:Vector2,sprite_subclass:GDScript=null) -> Sprite:
	var sprite : Sprite
	if sprite_subclass:
		sprite = sprite_subclass.new()
	else:
		sprite = Sprite.new()
	sprite.texture = tex
	sprite.region_rect = region
	sprite.region_enabled = true if region != Rect2() else false
	sprite.offset = tex_offset
	sprite.position = base_location
	add_child(sprite)
	return sprite


func move_unit(identifier:int,to_position:Vector2) -> void:
	# expects position to be in display space.
	if units_by_identifier.has(identifier):
		var old_pos : Vector2 = units_by_identifier[identifier].position
		units_by_identifier[identifier].position = to_position
		if (to_position - old_pos).x > 0 and units_by_identifier[identifier] is Sprite:
			units_by_identifier[identifier].flip_h = true
		else:
			units_by_identifier[identifier].flip_h = false
	# TODO: also set direction


func _on_tile_changed_biome(tilev:Vector2,new_texture:Texture) -> void:
	for s in lists_of_static_sprites_by_tilev[tilev]:
		var spr := s as Sprite
		spr.texture = new_texture


func _on_building_completed(building:SavedBuilding) -> void:
	var building_type = StaticData.get_building(building.building_type)
	var where_coords : Vector2 = Vector2(building.main_tile_x,building.main_tile_y)
	add_building_sprite(
			building.identifier,
			load(building_type.texture_path),
			Rect2(building_type.texture_position,building_type.texture_size),
			building_type.texture_offset,
			reference_tm_for_sprite_tilevs.map_to_world(where_coords)+Vector2(0,16))


func _on_building_removed(building_identifier:int) -> void:
	if buildings_by_identifier.has(building_identifier):
		if buildings_by_identifier[building_identifier] is Node and is_instance_valid(buildings_by_identifier[building_identifier]):
			buildings_by_identifier[building_identifier].queue_free()
		buildings_by_identifier.erase(building_identifier)


func _on_tile_covered_by_building(tilev:Vector2) -> void:
	if not lists_of_static_sprites_by_tilev.has(tilev):
		return
	for s in lists_of_static_sprites_by_tilev[tilev]:
		var spr := s as Sprite
		spr.hide()


func _on_tile_no_longer_covered_by_building(tilev:Vector2) -> void:
	if not lists_of_static_sprites_by_tilev.has(tilev):
		return
	for s in lists_of_static_sprites_by_tilev[tilev]:
		var spr := s as Sprite
		spr.show()
