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


class_name UnitDisplay

extends Sprite

var _has_valid_animations : bool = false
var _anim_player : AnimationPlayer


#func _draw() -> void:
#	if not _has_valid_animations:
#		draw_circle(Vector2(0,0),16,Color.yellow)


func initialize_from_unit(unit:SavedUnit) -> void:
	var species_static_data := StaticData.get_species_display(unit.species)
	var idle_start_frame : int = 0
	var moving_start_frame : int = idle_start_frame + species_static_data.num_frames_idle
	var attacking_start_frame : int = moving_start_frame + species_static_data.num_frames_moving
	var total_frames : int = attacking_start_frame + species_static_data.num_frames_attacking
	var tex : Resource
	match unit.faction:
		StaticData.engine_keys_to_faction_ids.purity:
			tex = load(species_static_data.purity_tex_path)
		StaticData.engine_keys_to_faction_ids.specter:
			tex = load(species_static_data.specter_tex_path)
		StaticData.engine_keys_to_faction_ids.sanguine:
			tex = load(species_static_data.sanguine_tex_path)
		StaticData.engine_keys_to_faction_ids.pestilence:
			tex = load(species_static_data.pestilent_tex_path)
		StaticData.engine_keys_to_faction_ids.artifice:
			tex = load(species_static_data.artifice_tex_path)
	if tex:
		texture = tex
		offset = species_static_data.offset
#		var columns : int = int(texture.get_size().x/species_static_data.sprite_size.x)
#		var rows : int = int(texture.get_size().y/species_static_data.sprite_size.y)
#		if columns * rows >= total_frames:
#			_has_valid_animations = true
#			hframes = columns
#			vframes = rows
#			setup_animations(idle_start_frame,moving_start_frame,attacking_start_frame,total_frames,species_static_data.frames_per_second)
#		# TODO: handle upgrade type as well
		region_enabled = true
		var region_rect_name : String = "purity_sprite_rect" if unit.faction == StaticData.engine_keys_to_faction_ids.purity else "specter_sprite_rect"
		region_rect = species_static_data.get(region_rect_name)
		if unit.upgrade_type > -1:
			var format_string : String = "purity_up{0}_sprite_rect" if unit.upgrade_faction == StaticData.engine_keys_to_faction_ids.purity else "specter_up{0}_sprite_rect"
			var upgrade_sprite := Sprite.new()
			upgrade_sprite.texture = texture
			upgrade_sprite.region_rect = species_static_data.get(format_string.format([unit.upgrade_type]))
			upgrade_sprite.region_enabled = true
			add_child(upgrade_sprite)
	
#	if not _has_valid_animations:
#		update()


func start_moving() -> void:
	if not _has_valid_animations:
		return
	_anim_player.play("move")


func start_attacking() -> void:
	if not _has_valid_animations:
		return
	_anim_player.play("attack")


func return_to_idle() -> void:
	if not _has_valid_animations:
		return
	_anim_player.play("idle")


func setup_animations(idle_start:int,moving_start:int,attacking_start:int,total:int,fps:float) -> void:
	_anim_player = AnimationPlayer.new()
	add_child(_anim_player)
	setup_animation("idle",idle_start,moving_start,_anim_player,fps*(moving_start-idle_start))
	setup_animation("move",moving_start,attacking_start,_anim_player,fps*(attacking_start-moving_start))
	setup_animation("attack",attacking_start,total,_anim_player,fps*(total-attacking_start))


func setup_animation(anim_name:String,frame_start:int,frame_end:int,player:AnimationPlayer,fps:float) -> void:
	var animation := Animation.new()
	animation.loop = true
	var seconds_per_frame : float = (1.0/fps)
	animation.length = seconds_per_frame * (frame_end-frame_start)
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track,String(get_path())+":frame")
	animation.value_track_set_update_mode(track,Animation.UPDATE_DISCRETE)
	for frame_number in range(frame_start,frame_end):
		animation.track_insert_key(track,seconds_per_frame*(frame_number-frame_start),frame_number)
	player.add_animation(anim_name,animation)
