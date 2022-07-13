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

const BLANK_UNIT_INCOME_DICT = {
	"cooldown_s":5.0,
	"timeout_s":0.0,
	"unit_type":-1,
	"unit_qty":-1,
}
const BLANK_CURRENCY_INCOME_DICT = {
	"cooldown_s":5.0,
	"timeout_s":0.0,
	"amount":-1,
}

signal request_unit_generation_from_income(unit_types,unit_qty)


export(int) var identifier : int
export(int) var current_currency : int = 0 # gold or leaves
export(int) var current_special_resource : int = 0 # forest hearts for pure faction; evil factions currently don't use this
export(Array) var spawned_unit_identifiers := []
export(Array) var queued_unit_identifiers := []
export(Array) var building_identifiers := []
export(Dictionary) var currency_income_cooldown := {}
export(Dictionary) var unit_income_cooldown := {}
export(Vector2) var new_units_spawn_at : Vector2 # set this in new game init



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func add_unit(unit:SavedUnit) -> void:
	queued_unit_identifiers.append(unit.identifier)
	unit.connect("allegiance_changed",self,"_on_unit_allegiance_changed",[unit])
	unit.connect("spawned",self,"_on_unit_spawned",[unit])
	unit.connect("despawned",self,"_on_unit_despawned",[unit])


func remove_unit(unit:SavedUnit) -> void:
	# only call for evil factions; it shouldn't be possible for the pure faction to truly lose units
	if spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.erase(unit.identifier)
	elif queued_unit_identifiers.has(unit.identifier):
		queued_unit_identifiers.erase(unit.identifier)


func on_save() -> void:
	if unit_income_cooldown != {}:
		unit_income_cooldown.cooldown_s = GameState.elapsed_time - unit_income_cooldown.timeout_s
	if currency_income_cooldown != {}:
		currency_income_cooldown.cooldown_s = GameState.elapsed_time - currency_income_cooldown.timeout_s


func on_restore() -> void:
	if unit_income_cooldown != {}:
		unit_income_cooldown.timeout_s = GameState.elapsed_time + unit_income_cooldown.cooldown_s
		GameState.event_heap.push_dict_onto_heap(unit_income_cooldown)
	if currency_income_cooldown != {}:
		currency_income_cooldown.timeout_s = GameState.elapsed_time + currency_income_cooldown.cooldown_s
		GameState.event_heap.push_dict_onto_heap(currency_income_cooldown)


func _on_unit_allegiance_changed(unit:SavedUnit) -> void:
	remove_unit(unit)
	GameState.get_faction(unit.allegiance).add_unit(unit)


func _on_unit_spawned(unit:SavedUnit) -> void:
	if queued_unit_identifiers.has(unit.identifier):
		queued_unit_identifiers.erase(unit.identifier)
	if not spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.append(unit.identifier)


func _on_unit_despawned(unit:SavedUnit) -> void:
	if not queued_unit_identifiers.has(unit.identifier):
		queued_unit_identifiers.append(unit.identifier)
	if spawned_unit_identifiers.has(unit.identifier):
		spawned_unit_identifiers.erase(unit.identifier)


func _on_unit_income_timeout_dict_expired(dict:Dictionary) -> void:
	emit_signal("request_unit_generation_from_income",dict.unit_type,dict.unit_qty)


func _push_new_unit_income_timeout_dict() -> void:
	unit_income_cooldown = BLANK_UNIT_INCOME_DICT.duplicate()
	# TODO: randomly generate the units from static data
	GameState.event_heap.push_dict_onto_heap(unit_income_cooldown)


func _on_currency_income_timeout_dict_expired(dict:Dictionary) -> void:
	current_currency += dict.amount
	_push_new_currency_income_timeout_dict()


func _push_new_currency_income_timeout_dict() -> void:
	currency_income_cooldown = BLANK_CURRENCY_INCOME_DICT.duplicate()
	currency_income_cooldown.timeout_s = GameState.elapsed_time + currency_income_cooldown.cooldown_s
	# TODO: calculate amount from static data and milestones
	GameState.event_heap.push_dict_onto_heap(currency_income_cooldown)
