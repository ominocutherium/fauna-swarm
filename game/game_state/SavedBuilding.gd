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
	"timeout_s":-1.0, # used by EventHeap
	"callback":"",
	"callback_obj":null,
}

signal request_spawn_unit(unit_id,tile_coordinates_v2)
signal destroyed

export(int) var identifer : int
export(int) var faction : int = -1 # -1 is a valid value for factionless buildings, like unclaimed forest hearts
export(bool) var used_special_resource : bool = false
export(int) var building_type : int
export(int) var main_tile_x : int
export(int) var main_tile_y : int
export(int) var current_health : float
export(int) var additional_income_provided : int
export(Array) var queue_items := []

var queue_expiry_event := {} # connects to the heap


func on_restore() -> void:
	push_top_queue_item_event_to_heap()


func on_save() -> void:
	if queue_expiry_event != {}:
		queue_expiry_event.cooldown_s = queue_expiry_event.timeout_s - GameState.elapsed_time


func get_maximum_health() -> float:
	# queries static data based on building type
	return 1.0


func get_maximum_queue_size() -> int:
	var s_d : BuildingStaticData = StaticData.get_building(identifer)
	return s_d.queue_len


func push_top_queue_item_event_to_heap() -> void:
	if queue_items.size() > 0:
		queue_expiry_event = queue_items[0]
		var timeout : float = queue_items[0].cooldown_s + GameState.elapsed_time
		GameState.event_heap.push_dict_onto_heap(queue_expiry_event)
	else:
		queue_expiry_event = {}


func take_damage(amount:float) -> void:
	current_health -= amount
	if current_health < 0:
		emit_signal("destroyed")


func _add_queue_item(item:Dictionary) -> bool:
	if queue_items.size() < StaticData.get_building(identifer).queue_len:
		queue_items.append(item)
		if queue_expiry_event == {}:
			push_top_queue_item_event_to_heap()
		return true
	return false


func _on_purifies_units_queue_item_timed_out(queue_item:Dictionary) -> void:
	# Update faction, heal, and spawn
	if not queue_item.target_identifier is int or queue_item.target_identifier < 0:
		return
	var unit : SavedUnit = GameState.get_unit(queue_item.target_identifier)
	if unit == null:
		return
	unit.faction = StaticData.engine_keys_to_faction_ids.purity
	unit.current_health = unit.get_maximum_health()
	emit_signal("request_spawn_unit",unit.identifier,Vector2(main_tile_x,main_tile_y))
	_on_queue_item_removed(queue_item)


func _unit_spawner_queue_item_timed_out(queue_item:Dictionary) -> void:
	# Heal and spawn
	if not queue_item.target_identifier is int or queue_item.target_identifier < 0:
		return
	var unit : SavedUnit = GameState.get_unit(queue_item.target_identifier)
	if unit == null:
		return
	unit.current_health = unit.get_maximum_health()
	emit_signal("request_spawn_unit",unit.identifier,Vector2(main_tile_x,main_tile_y))
	_on_queue_item_removed(queue_item)


func _on_heals_units_queue_item_removed_from_queue(queue_item:Dictionary):
	# Spawn but do not heal
	if not queue_item.target_identifier is int or queue_item.target_identifier < 0:
		return
	var unit : SavedUnit = GameState.get_unit(queue_item.target_identifier)
	if unit == null:
		return
	emit_signal("request_spawn_unit",unit.identifier,Vector2(main_tile_x,main_tile_y))


func _on_queue_item_removed(queue_item:Dictionary) -> void:
	if queue_item in queue_items:
		queue_items.erase(queue_item)
	if queue_expiry_event != queue_items[0]:
		push_top_queue_item_event_to_heap()
