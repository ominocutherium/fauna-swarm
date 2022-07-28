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

extends Commander

class_name NPCCommander

enum Priorities {EXPAND_BUILDINGS,MORE_UNITS,UPGRADE_UNITS}

var _costs_of_buildings := {}
var current_priority : int

# Holds "bot" logic for NPC commanders.

func update(_delta:float) -> void:
	# call in GameState._process()
	# TODO: maybe change this to update based on callbacks from EventHeap instead
	match current_priority:
		Priorities.EXPAND_BUILDINGS:
			if not _has_space_to_build():
				if _has_units_available_for_an_order() and _has_units_in_range_of_creep_blocking_building():
					_attack_nearest_non_allied_building()
			elif _has_enough_currency_to_build() and _has_units_available_for_an_order():
				_choose_and_build_building()
		Priorities.MORE_UNITS:
			if _has_currency_and_space_in_queue_for_units():
				_buy_unit_from_building()
		Priorities.UPGRADE_UNITS:
			if _has_units_that_can_be_upgraded_with_currency():
				_choose_and_upgrade_unit()


func _re_evaluate_priority() -> void:
	current_priority = GameState.random_number_generator.randi_range(0,Priorities.size()-1)


func _has_units_in_range_of_creep_blocking_building() -> bool:
	return false


func _has_units_available_for_an_order() -> bool:
	return false


func _has_enough_currency_to_build() -> bool:
	return false


func _has_space_to_build() -> bool:
	return false


func _has_units_that_can_be_upgraded_with_currency() -> bool:
	return false


func _has_currency_and_space_in_queue_for_units() -> bool:
	return false


func _choose_and_build_building() -> void:
	pass


func _choose_and_upgrade_unit() -> void:
	pass


func _buy_unit_from_building() -> void:
	pass


func _attack_nearest_non_allied_building() -> void:
	pass
