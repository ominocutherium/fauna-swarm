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

extends Button

class_name OrderInputButton


export(String) var action_emulated setget set_action_emulated

var _hotkey_value : int = -1
var _hotkey_disp : String = ""

func _ready() -> void:
	connect("button_down",self,"_on_button_down")
	connect("button_up",self,"_on_button_up")
	connect("mouse_exited",self,"_on_mouse_exited")
	if action_emulated != "":
		_on_action_assigned()


func set_action_emulated(value:String) -> void:
	action_emulated = value
	_on_action_assigned()


func _on_action_assigned() -> void:
	if InputMap.has_action(action_emulated):
		var action_list := InputMap.get_action_list(action_emulated)
		for ev in action_list:
			if ev is InputEventKey:
				_hotkey_value = ev.physical_scancode
				_hotkey_disp = OS.get_scancode_string(_hotkey_value)
				break
	else:
		_hotkey_value = -1
		_hotkey_disp = ""
	if _hotkey_disp != "":
		hint_tooltip = tr("ORDER_BUTTON_TOOLTIP").format([action_emulated,_hotkey_disp])
	else:
		hint_tooltip = ""


func _on_button_down() -> void:
	if InputMap.has_action(action_emulated):
		Input.action_press(action_emulated)


func _on_button_up() -> void:
	if InputMap.has_action(action_emulated) and Input.is_action_pressed(action_emulated):
		Input.action_release(action_emulated)


func _on_mouse_exited() -> void:
	if InputMap.has_action(action_emulated) and Input.is_action_pressed(action_emulated):
		Input.action_release(action_emulated)
