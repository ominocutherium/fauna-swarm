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

extends Node

class_name OrderInputHandler


const HANDLERS_BY_EVENT = {
	"order_move":"_handle_order_move",
	"order_hold":"_handle_order_hold",
	"order_capture_attack":"_handle_order_capture",
	"order_attack":"_handle_order_attack",
	"order_claim":"_handle_order_claim",
}

signal report_valid_order_in_progress(order_type)
signal report_no_valid_order_in_progress
signal report_no_more_order_data
signal report_build_building_order_in_progress(building_type)


var player_commander : Commander setget set_player_commander
var list_of_selected_unit_identifiers := [] setget set_list_of_selected_unit_identifiers
var targeted_building_identifier : int = -1 setget set_targeted_building_identifier
var targeted_unit_identifier : int = -1 setget set_targeted_unit_identifier
var targeted_position : Vector2 = Vector2()
var build_order_building_type : int = -1
var order_in_progress : int = -1


func _ready() -> void:
	match GameState.game_mode:
		GameState.GameMode.SP_PURITY_VS_SINGLE_EVIL:
			continue
		GameState.GameMode.SP_PURITY_VS_TWO_EVILS:
			continue
		_:
			self.player_commander = GameState.commanders[StaticData.engine_keys_to_faction_ids.purity]


func _process(delta: float) -> void:
	for action_name in HANDLERS_BY_EVENT:
		if Input.is_action_just_released(action_name):
			call(HANDLERS_BY_EVENT[action_name])


func set_list_of_selected_unit_identifiers(list_of_ids : Array) -> void:
	list_of_selected_unit_identifiers = list_of_ids
	order_in_progress = -1
	emit_signal("report_no_valid_order_in_progress")


func set_targeted_building_identifier(id:int) -> void:
	targeted_building_identifier = id
	if order_in_progress != -1 and list_of_selected_unit_identifiers != []:
		_resolve_order()


func set_build_order_building_to_build(id:int) -> void:
	build_order_building_type = id
	emit_signal("report_build_building_order_in_progress",build_order_building_type)


func set_targeted_unit_identifier(id:int) -> void:
	targeted_unit_identifier = id
	if order_in_progress != -1 and list_of_selected_unit_identifiers != []:
		_resolve_order()


func set_targeted_unit_identifier_and_order_attack(id:int) -> void:
	order_in_progress = UnitManager.OrderTypes.ATTACK_OBJ
	emit_signal("report_valid_order_in_progress",order_in_progress)
	set_targeted_unit_identifier(id)


func set_targeted_position_and_move_if_no_other_order(position:Vector2) -> void:
	if order_in_progress == -1:
		order_in_progress = UnitManager.OrderTypes.MOVE_TO_POS
	emit_signal("report_valid_order_in_progress",order_in_progress)
	set_targeted_position(position)


func set_targeted_position(position:Vector2) -> void:
	# position parameter should be in physics space
	targeted_position = position
	if order_in_progress != -1 and list_of_selected_unit_identifiers != [] and order_in_progress != UnitManager.OrderTypes.CAPTURE_OBJ:
		_resolve_order(true)


func set_player_commander(value:Commander) -> void:
	player_commander = value


func _resolve_order(use_position:bool=false) -> void:
	if order_in_progress == UnitManager.OrderTypes.ATTACK_OBJ and use_position:
		order_in_progress = UnitManager.OrderTypes.ATTACK_POS
	var target_type : int
	var target
	match order_in_progress:
		UnitManager.OrderTypes.HOLD_POS:
			target_type = -1
			target = null
		UnitManager.OrderTypes.ATTACK_OBJ:
			target_type = UnitManager.ObjTargetTypes.UNIT if targeted_unit_identifier != -1 else UnitManager.ObjTargetTypes.BUILDING
			target = targeted_unit_identifier if targeted_unit_identifier != -1 else targeted_building_identifier
			continue
		UnitManager.OrderTypes.MOVE_TO_POS:
			target_type = -1
			target = targeted_position
			continue
		UnitManager.OrderTypes.ATTACK_POS:
			target_type = -1
			target = targeted_position
			continue
		UnitManager.OrderTypes.CLAIM_OBJ:
			target_type = UnitManager.ObjTargetTypes.BUILDING
			target = targeted_building_identifier
			continue
		UnitManager.OrderTypes.BUILD_OBJ:
			if not GameState.building_tiles.is_spot_valid_for_building(StaticData.get_building(build_order_building_type),targeted_position):
				# give some sort of feedback
				return
			target = GameState.create_building(build_order_building_type,targeted_position)
			target_type = UnitManager.ObjTargetTypes.BUILDING
			continue
		UnitManager.OrderTypes.CAPTURE_OBJ:
			target_type = UnitManager.ObjTargetTypes.UNIT
			target = targeted_unit_identifier
			continue
		UnitManager.OrderTypes.HEAL:
			target_type = UnitManager.ObjTargetTypes.BUILDING
			target = targeted_building_identifier
			continue
		_:
			if order_in_progress < UnitManager.OrderTypes.size() and order_in_progress >= 0:
				UnitManager.mark_units_as_needing_path(list_of_selected_unit_identifiers)

	for unit_id in list_of_selected_unit_identifiers:
		var unit : SavedUnit = GameState.get_unit(unit_id)
		unit.set_order(order_in_progress,target_type,target)
		UnitManager.mark_unit_as_needing_order_resolution(unit_id)

	_release_order_data()


func _release_order_data() -> void:
	targeted_building_identifier = -1
	targeted_unit_identifier = -1
	targeted_position = Vector2()
	order_in_progress = -1
	emit_signal("report_no_more_order_data")


func _verify_list_has_at_least_one_player_unit() -> bool:
	return true


func _handle_order_move() -> void:
	print("Move order pressed.")
	if _verify_list_has_at_least_one_player_unit():
		order_in_progress = UnitManager.OrderTypes.MOVE_TO_POS
		emit_signal("report_valid_order_in_progress",order_in_progress)


func _handle_order_hold() -> void:
	print("Hold order pressed.")
	if _verify_list_has_at_least_one_player_unit():
		order_in_progress = UnitManager.OrderTypes.HOLD_POS
		_resolve_order()


func _handle_order_attack() -> void:
	print("Attack order pressed.")
	if _verify_list_has_at_least_one_player_unit():
		order_in_progress = UnitManager.OrderTypes.ATTACK_OBJ
		emit_signal("report_valid_order_in_progress",order_in_progress)


func _handle_order_capture() -> void:
	print("Capture order pressed.")
	if _verify_list_has_at_least_one_player_unit():
		order_in_progress = UnitManager.OrderTypes.CAPTURE_OBJ
		emit_signal("report_valid_order_in_progress",order_in_progress)


func _handle_order_claim() -> void:
	print("Claim order pressed.")
	if _verify_list_has_at_least_one_player_unit():
		order_in_progress = UnitManager.OrderTypes.CLAIM_OBJ
		emit_signal("report_valid_order_in_progress",order_in_progress)
