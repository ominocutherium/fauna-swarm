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

class_name SavedFaction

extends Resource


const CHECK_FOR_SPOT_IN_QUEUE_TIMEOUT = 4.0/13.0
const BUILDING_CAP_FOR_INCOME_MILESTONE = 31.0
const BLANK_UNIT_INCOME_DICT = {
	"cooldown_s":5.0,
	"timeout_s":0.0,
	"unit_type":-1,
	"unit_qty":-1,
	callback_obj=null,
	callback="_on_unit_income_timeout_dict_expired",
}
const BLANK_CURRENCY_INCOME_DICT = {
	"cooldown_s":5.0,
	"timeout_s":0.0,
	"amount":-1,
	callback_obj=null,
	callback="_on_currency_income_timeout_dict_expired",
}
const BLANK_CHECK_FOR_SPOT_DICT = {
	cooldown_s=5.0,
	timeout_s=0.0,
	callback_obj=null,
	callback="_check_for_spot_in_queue_elapsed",
}
const UNIT_SIGNAL_CALLBACK_PAIRS = [
		["allegiance_changed","_on_unit_allegiance_changed"],
		["spawned","_on_unit_spawned"],
		["despawned","_on_unit_despawned"],
]

signal request_unit_generation_from_income(unit_types,unit_qty)
signal request_unit_spawn(unit_identifier)


export(int) var identifier : int
export(int) var current_currency : int = 0 # gold or leaves
export(int) var current_special_resource : int = 1 # forest hearts for pure faction; evil factions currently don't use this. Does not go down, current display subtracts number of buildings using it
export(int) var max_num_buildings_built_at_once : int = 0 # typically only used for evil factions' build milestones
export(Array) var spawned_unit_identifiers := []
export(Array) var queued_unit_identifiers := []
export(Array) var unit_identifiers_in_limbo := []
export(Array) var building_identifiers := []
export(Dictionary) var currency_income_cooldown := {}
export(Dictionary) var unit_income_cooldown := {}
export(Dictionary) var place_limbo_unit_in_queue_cooldown := {}
export(Vector2) var new_units_spawn_at : Vector2 # set this in new game init


func add_unit(unit:SavedUnit) -> void:
	_add_unit_with_unknown_status(unit)
	for signal_callback_pair in UNIT_SIGNAL_CALLBACK_PAIRS:
		if not unit.is_connected(signal_callback_pair[0],self,signal_callback_pair[1]):
# warning-ignore:return_value_discarded
			unit.connect(signal_callback_pair[0],self,signal_callback_pair[1])


func remove_unit(unit:SavedUnit) -> void:
	# only call for evil factions; it shouldn't be possible for the pure faction to truly lose units
	for signal_callback_pair in UNIT_SIGNAL_CALLBACK_PAIRS:
		if unit.is_connected(signal_callback_pair[0],self,signal_callback_pair[1]):
			unit.disconnect(signal_callback_pair[0],self,signal_callback_pair[1])
	if spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.erase(unit.identifier)
	elif queued_unit_identifiers.has(unit.identifier):
		queued_unit_identifiers.erase(unit.identifier)
	elif unit_identifiers_in_limbo.has(unit.identifier):
		unit_identifiers_in_limbo.erase(unit.identifier)


func on_save() -> void:
	if unit_income_cooldown != {}:
		unit_income_cooldown.cooldown_s = GameState.elapsed_time - unit_income_cooldown.timeout_s
		unit_income_cooldown.erase("callback_obj")
	if currency_income_cooldown != {}:
		currency_income_cooldown.cooldown_s = GameState.elapsed_time - currency_income_cooldown.timeout_s
		currency_income_cooldown.erase("callback_obj")
	if place_limbo_unit_in_queue_cooldown != {}:
		place_limbo_unit_in_queue_cooldown.cooldown_s = GameState.elapsed_time - currency_income_cooldown.timeout_s
		place_limbo_unit_in_queue_cooldown.erase("callback_obj")


func on_restore() -> void:
	if unit_income_cooldown != {}:
		unit_income_cooldown.timeout_s = GameState.elapsed_time + unit_income_cooldown.cooldown_s
		unit_income_cooldown.callback_obj = self
		GameState.event_heap.push_dict_onto_heap(unit_income_cooldown)
	if currency_income_cooldown != {}:
		currency_income_cooldown.timeout_s = GameState.elapsed_time + currency_income_cooldown.cooldown_s
		currency_income_cooldown.callback_obj = self
		GameState.event_heap.push_dict_onto_heap(currency_income_cooldown)
	if place_limbo_unit_in_queue_cooldown != {}:
		place_limbo_unit_in_queue_cooldown.timeout_s = GameState.elapsed_time + place_limbo_unit_in_queue_cooldown.cooldown_s
		currency_income_cooldown.callback_obj = self
		GameState.event_heap.push_dict_onto_heap(place_limbo_unit_in_queue_cooldown)


func on_init() -> void:
	_push_new_currency_income_timeout_dict()
	_push_new_unit_income_timeout_dict()


func _on_unit_allegiance_changed(unit:SavedUnit) -> void:
	remove_unit(unit)
	GameState.get_faction(unit.allegiance).add_unit(unit)


func _on_unit_spawned(unit:SavedUnit) -> void:
	if queued_unit_identifiers.has(unit.identifier):
		queued_unit_identifiers.erase(unit.identifier)
	elif unit_identifiers_in_limbo.has(unit.identifier):
		unit_identifiers_in_limbo.erase(unit.identifier)
	if not spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.append(unit.identifier)


func _on_unit_despawned(unit:SavedUnit) -> void:
	_add_unit_with_unknown_status(unit)
	if spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.erase(unit.identifier)


func _on_unit_income_timeout_dict_expired(dict:Dictionary) -> void:
	var with_upgrade : int = -1
	if dict.has("with_upgrade"):
		with_upgrade = dict.with_upgrade
	emit_signal("request_unit_generation_from_income",dict.unit_qty,dict.unit_type,identifier,new_units_spawn_at,with_upgrade)


func _push_new_unit_income_timeout_dict() -> void:
	unit_income_cooldown = BLANK_UNIT_INCOME_DICT.duplicate()
	var species_selection = StaticData.choose_species_to_give_as_income()
	unit_income_cooldown.unit_type = species_selection.identifier
	unit_income_cooldown.unit_qty = species_selection.income_number_of_units_given
	unit_income_cooldown.cooldown_s = species_selection.cooldown_before_income
	unit_income_cooldown.callback_obj = self
	unit_income_cooldown.timeout_s = GameState.elapsed_time + unit_income_cooldown.cooldown_s
	GameState.event_heap.push_dict_onto_heap(unit_income_cooldown)


func _on_currency_income_timeout_dict_expired(dict:Dictionary) -> void:
	current_currency += dict.amount
	_push_new_currency_income_timeout_dict()


func _push_new_currency_income_timeout_dict() -> void:
	currency_income_cooldown = BLANK_CURRENCY_INCOME_DICT.duplicate()
	currency_income_cooldown.callback_obj = self
	currency_income_cooldown.cooldown_s = StaticData.get_faction(identifier).income_cooldown
	var milestone_multiplier : float = 1.0
	match StaticData.get_faction(identifier).faction_type:
		FactionStaticData.FactionTypes.PURE:
			milestone_multiplier = lerp(1.0,StaticData.get_faction(identifier).income_amount_maximum_multiplier,
					0.5 * float(GameState.background_tiles.tile_ids_ever_within_purification_range.size()) / (
					GameState.background_tiles.extents.size.x * GameState.background_tiles.extents.size.y) +
					0.5 * min(1.0,float(current_special_resource/max(1.0,GameState.starting_forest_heart_count))))
		FactionStaticData.FactionTypes.EVIL:
			milestone_multiplier = lerp(1.0,StaticData.get_faction(identifier).income_amount_maximum_multiplier,
					min(1.0,max_num_buildings_built_at_once/BUILDING_CAP_FOR_INCOME_MILESTONE))
	currency_income_cooldown.amount = int(floor(StaticData.get_faction(identifier).income_amount*milestone_multiplier))
	currency_income_cooldown.timeout_s = GameState.elapsed_time + currency_income_cooldown.cooldown_s
	GameState.event_heap.push_dict_onto_heap(currency_income_cooldown)


func _add_unit_with_unknown_status(unit:SavedUnit) -> void:
	match unit.spawn_status:
		SavedUnit.Status.SPAWNED:
			# New Game Init or unit income generated this unit
			spawned_unit_identifiers.append(unit.identifier)
		SavedUnit.Status.IN_BUILDING_QUEUE:
			# A building generated this unit
			queued_unit_identifiers.append(unit.identifier)
		SavedUnit.Status.WAITING_FOR_QUEUE:
			# This unit was captured from another faction, it is currently "defeated" at negative health
			continue
		_:
			unit_identifiers_in_limbo.append(unit.identifier)
			if unit_identifiers_in_limbo.size() > 0 and place_limbo_unit_in_queue_cooldown == {}:
				_push_check_for_spot_in_queue()


func _check_for_spot_in_queue_elapsed(_dict:Dictionary) -> void:
	place_limbo_unit_in_queue_cooldown = {}
	_check_for_spot_in_queue_for_unit_in_limbo()


func _push_check_for_spot_in_queue() -> void:
	place_limbo_unit_in_queue_cooldown = BLANK_CHECK_FOR_SPOT_DICT.duplicate()
	place_limbo_unit_in_queue_cooldown.callback_obj = self
	place_limbo_unit_in_queue_cooldown.timeout_s = place_limbo_unit_in_queue_cooldown.cooldown_s + GameState.elapsed_time
	GameState.event_heap.push_dict_onto_heap(place_limbo_unit_in_queue_cooldown)


func _check_for_spot_in_queue_for_unit_in_limbo() -> void:
	var success : bool = false
	var required_ability : String
	var unit_identifier : int = unit_identifiers_in_limbo.pop_front()
	if GameState.get_unit(unit_identifier).faction != identifier:
		required_ability = "purify_units_in_queue"
	else:
		required_ability = "heal_units_in_queue"
	if required_ability == "heal_units_in_queue" and GameState.get_unit(unit_identifier).current_health == GameState.get_unit(unit_identifier).get_maximum_health():
		# no need to find a place to heal a unit already at full health
		emit_signal("request_unit_spawn",unit_identifier)
		success = true
	else:
		for building_id in building_identifiers:
			var building = GameState.get_building(building_id) # duck typing to avoid cyclic reference
			var building_data : BuildingStaticData = StaticData.get_building(building.building_type)
			if required_ability in building_data.effects and building.queue_items.size() < building_data.queue_len:
				success = building.add_queue_item(required_ability,unit_identifier)
	if not success:
		unit_identifiers_in_limbo.push_front(unit_identifier)
	if unit_identifiers_in_limbo.size() > 0:
		_push_check_for_spot_in_queue()
