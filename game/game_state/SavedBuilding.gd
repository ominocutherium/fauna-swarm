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
const EMPTY_BUILD_COMPLETION_EVENT_HEAP_DICT = {
	"cooldown_s":5.0, # only counts down for most recent one
	"timeout_s":-1.0, # used by EventHeap
	"callback":"_on_build_progress_dict_completed",
	"callback_obj":null,
}

signal request_spawn_unit(unit_id,tile_coordinates_v2)
signal destroyed
signal completed

export(int) var identifer : int
export(int) var faction : int = -1 # -1 is a valid value for factionless buildings, like unclaimed forest hearts
export(bool) var used_special_resource : bool = false
export(int) var building_type : int
export(int) var main_tile_x : int
export(int) var main_tile_y : int
export(int) var current_health : float
export(int) var additional_income_provided : int
export(float) var build_progress : float = 0.0 setget set_build_progress # TODO: ensure NGI-placed buildings start completed
export(Array) var queue_items := []

var queue_expiry_event := {} # connects to the heap
var build_completion_event := {}


func on_restore() -> void:
	if build_completion_event != {} and build_progress < 1.0:
		_push_build_progress_dict_to_heap()
	push_top_queue_item_event_to_heap()


func on_save() -> void:
	if queue_expiry_event != {}:
		queue_expiry_event.cooldown_s = queue_expiry_event.timeout_s - GameState.elapsed_time
		queue_expiry_event.callback_obj = null
	if build_completion_event != {}:
		build_completion_event.callback_obj = null
		var progress_made : float = (build_completion_event.cooldown_s - build_completion_event.timeout_s + GameState.elapsed_time) * StaticData.get_building(building_type).build_progress_per_s
		self.build_progress += progress_made
		build_completion_event.cooldown_s = build_completion_event.timeout_s - GameState.elapsed_time


func get_maximum_health() -> float:
	# queries static data based on building type
	return 1.0


func get_maximum_queue_size() -> int:
	var s_d : BuildingStaticData = StaticData.get_building(identifer)
	return s_d.queue_len


func push_top_queue_item_event_to_heap() -> void:
	if queue_items.size() > 0:
		queue_expiry_event = queue_items[0]
		var timeout : float = queue_expiry_event.cooldown_s + GameState.elapsed_time
		queue_expiry_event.callback_obj = self
		queue_expiry_event.timeout_s = timeout
		GameState.event_heap.push_dict_onto_heap(queue_expiry_event)
	else:
		queue_expiry_event = {}


func add_queue_item(task_identifier:String,target) -> bool:
	match task_identifier:
		"heal_units_in_queue":
			if typeof(target) == TYPE_INT:
				var item : Dictionary = QUEUE_ITEM_TYPE.duplicate()
				item.target_identifier = target
				item.task_identifier = task_identifier
				item.callback = "_unit_spawner_queue_item_timed_out"
				item.callback_obj = self
				return _add_queue_item(item)
		"purify_units_in_queue":
			if typeof(target) == TYPE_INT:
				var item : Dictionary = QUEUE_ITEM_TYPE.duplicate()
				item.target_identifier = target
				item.task_identifier = task_identifier
				item.callback = "_on_purifies_units_queue_item_timed_out"
				item.callback_obj = self
				return _add_queue_item(item)
		"generate_units":
			var unit_generated : SavedUnit = GameState.get_unit(GameState.add_unit(0,-1,faction)) # TODO: don't make the unit yet, other obj will do so via signal
			unit_generated.set_queued()
			GameState.get_faction(faction).add_unit(unit_generated)
			var item : Dictionary = QUEUE_ITEM_TYPE.duplicate()
			item.target_identifier = unit_generated
			item.task_identifier = task_identifier
			item.callback = "_unit_spawner_queue_item_timed_out"
			item.callback_obj = self
			return _add_queue_item(item)
	return false


func remove_queue_item(index:int) -> void:
	if index < queue_items.size():
		_on_queue_item_removed(queue_items[index])


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
	# Spawn but do not heal (only for pure faction) or remove (evil faction)
	if not queue_item.target_identifier is int or queue_item.target_identifier < 0:
		return
	var unit : SavedUnit = GameState.get_unit(queue_item.target_identifier)
	if unit == null:
		return
	if faction != StaticData.engine_keys_to_faction_ids.purity:
		GameState.get_faction(faction).remove_unit(queue_item.target_identifier)
		return
	if queue_expiry_event == queue_item:
		# apply partial progress of heal
		unit.current_health = lerp(unit.current_health,unit.get_maximum_health(),1.0-(queue_expiry_event.timeout_s-GameState.time_elapsed)/QUEUE_ITEM_TYPE.cooldown_s)
	emit_signal("request_spawn_unit",unit.identifier,Vector2(main_tile_x,main_tile_y))


func _on_build_progress_dict_completed(dict:Dictionary) -> void:
	self.build_progress = 1.0
	build_completion_event = {}


func _push_build_progress_dict_to_heap() -> void:
	var dict := EMPTY_BUILD_COMPLETION_EVENT_HEAP_DICT.duplicate()
	dict.cooldown_s = (1.0-build_progress) / StaticData.get_building(building_type).build_progress_per_s
	if dict.cooldown_s == 0.0:
		return
	dict.timeout_s = GameState.elapsed_time + dict.cooldown_s
	dict.callback_obj = self
	GameState.event_heap.push_dict_onto_heap(dict)


func _on_queue_item_removed(queue_item:Dictionary) -> void:
	if queue_item in queue_items:
		queue_items.erase(queue_item)
		if queue_item.task_identifier in ["heal_units_in_queue","generate_units"]:
			_on_heals_units_queue_item_removed_from_queue(queue_item)
	if queue_expiry_event != queue_items[0]:
		push_top_queue_item_event_to_heap()


func set_build_progress(value:float) -> void:
	var old_progress := build_progress
	build_progress = max(0.0,min(1.0,value))
	if build_progress == 1.0 and old_progress < build_progress:
		emit_signal("completed")
