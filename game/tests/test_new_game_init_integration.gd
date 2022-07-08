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

extends GutTest

var menu_scene : Control
var gameplay_scene : Node2D
var _pre_existing_save_file : SavedGameState # TODO: store real save file here when saving/loading test savedgame in a test

func before_all() -> void:
	GameState.building_tiles = null
	GameState.background_tiles = null

func before_each() -> void:
	menu_scene = partial_double("res://main/MainMenu.tscn").instance()
	menu_scene.gameplay_scene = partial_double("res://main/Main.tscn")
	add_child_autoqfree(menu_scene)

func after_each() -> void:
	GameState.building_tiles = null
	GameState.background_tiles = null

func test_new_game_init_integration() -> void:
	# No changing scenes in a test case, so just call methods that would be called within MainMenu._on_Start_pressed()
	GameState.initialize_new_game()
	assert_not_null(GameState.building_tiles)

	# Now "change the scene"
	# FIXME: partial_double doesn't seem to read exported values in the scene.
	# Need to set the nodes caught in vars with partial doubles as well  (should do anyway to spy on their methods).
	gameplay_scene = partial_double("res://main/Main.tscn").instance()
	add_child_autoqfree(gameplay_scene) # Should invoke _ready()

	assert_called(gameplay_scene,"initialize_or_restore_map_state")
	assert_false(get_tree().paused)
