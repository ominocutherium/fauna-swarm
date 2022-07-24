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

const SAVE_FILE_PATH = "user://saved_game.tres"

onready var gameplay_scene : PackedScene = preload("res://main/Main.tscn")


func _ready() -> void:
	pass # Replace with function body.
	if _detect_if_save_file():
		$Buttons/VBoxContainer/Continue.show()
		$Buttons/VBoxContainer/Start.hide()
	else:
		$Buttons/VBoxContainer/Continue.hide()
		$Buttons/VBoxContainer/Start.show()


func _on_Start_pressed() -> void:
	GameState.initialize_new_game(GameState.GameMode.SP_PURITY_VS_SINGLE_EVIL,load("res://map/game_map_0.tres"))
	get_tree().change_scene_to(gameplay_scene)


func _on_Continue_pressed() -> void:
	var s := _load_if_save_file()
	if s == null:
		$SaveLoadError.popup()
	else:
		GameState.restore(s)
		get_tree().change_scene_to(gameplay_scene)


func _on_Settings_pressed() -> void:
	$Settings.popup()


func _on_CreditsLegal_pressed() -> void:
	$Credits.popup()


func _on_Stats_pressed() -> void:
	$Statistics.popup()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _detect_if_save_file() -> bool:
	var f := File.new()
	if f.file_exists(SAVE_FILE_PATH):
		return true
	return false


func _load_if_save_file() -> SavedGameState:
	var res := load(SAVE_FILE_PATH)
	return res as SavedGameState
