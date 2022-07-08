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

class_name SavedBuilding


const QUEUE_ITEM_TYPE = {
	"task_identifier":"",
	"target_identifier":"", # typically a unit identifier
	"cooldown_s":5.0, # only counts down for most recent one
}

export(int) var identifer : int
export(int) var building_type : int
export(int) var main_tile_x : int
export(int) var main_tile_y : int
export(int) var current_health : float
export(Array) var queue_items

var queue_expiry_event # connects to the heap


func get_maximum_health() -> float:
	# queries static data based on building type
	return 1.0

func get_maximum_queue_size() -> int:
	# queries static data based on building type
	return 0

func push_top_queue_item_event_to_heap() -> void:
	if queue_items.size() > 0:
		var timeout : float = queue_items[0].cooldown_s
		# TODO: finish implementing when an event queue, world time, and event type exists
