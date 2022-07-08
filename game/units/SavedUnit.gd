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

extends Resource

class_name SavedUnit

enum Status {SPAWNED,IN_BUILDING_QUEUE,WAITING_FOR_QUEUE}

export(int) var order_type : int # UnitManager.OrderTypes
export(int) var order_target_type : int # UnitManager.ObjTargetTypes
export(int) var order_target_identifier : int # for obj targets
export(Vector2) var order_target_point : Vector2
export(Vector2) var position : Vector2
export(Vector2) var velocity : Vector2
export(float) var current_health
export(int) var identifier
export(int) var species
export(int) var faction
export(int) var spawn_status
export(int) var upgrade_type = -1
export(int) var upgrade_faction = -1

var maximum_health : float setget ,get_maximum_health


func sync_data_from_manager() -> void:
	# Queries UnitManager singleton for updated position data, if alive.
	pass


func get_maximum_health() -> float:
	return 1.0
