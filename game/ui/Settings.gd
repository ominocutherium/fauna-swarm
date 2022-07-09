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

extends Control

export(NodePath) var audio_tab_button_path : NodePath
export(NodePath) var audio_tab_path : NodePath
export(NodePath) var gameplay_tab_button_path : NodePath
export(NodePath) var gameplay_tab_path : NodePath
export(NodePath) var controls_tab_button_path : NodePath
export(NodePath) var controls_tab_path : NodePath
export(NodePath) var audio_slider_path_main : NodePath
export(NodePath) var audio_slider_path_bgm : NodePath
export(NodePath) var audio_slider_path_sfx : NodePath
export(NodePath) var time_scale_slider_path : NodePath

onready var audio_tab_button : Button = get_node(audio_tab_button_path)
onready var audio_tab_content : Control = get_node(audio_tab_path)
onready var gameplay_tab_button : Button = get_node(gameplay_tab_button_path)
onready var gameplay_tab_content : Control = get_node(gameplay_tab_path)
onready var controls_tab_button : Button = get_node(controls_tab_button_path)
onready var controls_tab_content : Control = get_node(controls_tab_path)
onready var bgm_volume_slider : Range = get_node(audio_slider_path_bgm)
onready var main_volume_slider : Range = get_node(audio_slider_path_main)
onready var sfx_volume_slider : Range = get_node(audio_slider_path_sfx)
onready var time_scale_slider : Range = get_node(time_scale_slider_path)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_gameplay_tab()
# warning-ignore:return_value_discarded
	bgm_volume_slider.connect("value_changed",self,"_volume_updated",["BGM"])
# warning-ignore:return_value_discarded
	main_volume_slider.connect("value_changed",self,"_volume_updated",["Master"])
# warning-ignore:return_value_discarded
	sfx_volume_slider.connect("value_changed",self,"_volume_updated",["SFX"])
# warning-ignore:return_value_discarded
	time_scale_slider.connect("value_changed",self,"_time_scale_updated")


func _hide_all_tabs() -> void:
	audio_tab_content.hide()
	gameplay_tab_content.hide()
	controls_tab_content.hide()


func _show_gameplay_tab() -> void:
	_hide_all_tabs()
	gameplay_tab_content.show()


func _show_audio_tab() -> void:
	_hide_all_tabs()
	audio_tab_content.show()


func _show_controls_tab() -> void:
	_hide_all_tabs()
	controls_tab_content.show()


func _volume_updated(value_exp_input:float,bus_name:String) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name),_get_volume_value_from_exp_input(value_exp_input))


func _get_volume_value_from_exp_input(volume_exp_input:float) -> float:
	return min(0.0,max(-80.0,exp(volume_exp_input)-80.001))


func _time_scale_updated(value_exponent_input:float) -> void:
	var time_scale = pow(1.5,value_exponent_input)
	Engine.time_scale = time_scale
	$Content/Gameplay/V/H/TimeScaleLabel.text = "%.2f x" % time_scale
