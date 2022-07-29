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

signal allegiance_changed
signal spawned
signal despawned
signal defeated
signal captured
signal upgraded
signal capture_attempt_failed
signal order_set(order_type,order_target_type,order_target)


const BLANK_ATTACK_TIMING_INFORMATION_DICT = {
	unit_identifier=-1,
	cooldown_s=5.0,
	timeout_s=5.0,
	callback="",
	attack_targeted_position=Vector2.RIGHT,
}


export(int) var order_type : int # UnitManager.OrderTypes
export(int) var order_target_type : int # UnitManager.ObjTargetTypes
export(int) var order_target_identifier : int # for obj targets
export(Vector2) var order_target_point : Vector2
export(Vector2) var position : Vector2
export(Vector2) var velocity : Vector2
export(float) var current_health : float
export(int) var identifier : int
export(int) var species : int
export(int) var faction : int = -1 # governs stats too
export(int) var allegiance : int = -1 setget set_allegiance # usually matches faction, unless captured but not yet purified
export(int) var spawn_status : int = -1
export(int) var upgrade_type = -1
export(int) var upgrade_faction = -1
export(Dictionary) var attack_timing_information := {}
export(bool) var is_able_to_attack : bool = true


var maximum_health : float setget ,get_maximum_health
var _attack_rid : RID


func sync_data_from_manager() -> void:
	# Queries UnitManager singleton for updated position data, if alive.
	pass


func apply_upgrade(type:int) -> void:
	upgrade_type = type
	upgrade_faction = faction
	emit_signal("upgraded")


func set_order(p_order_type:int,p_order_target_type:int,p_order_target) -> void:
	order_type = p_order_type
	order_target_type = p_order_target_type
	if p_order_target is int:
		order_target_identifier = p_order_target
		emit_signal("order_set",order_type,order_target_type,order_target_identifier)
		order_target_point = Vector2()
	elif p_order_target is Vector2:
		order_target_point = p_order_target
		emit_signal("order_set",order_type,order_target_type,order_target_point)
		order_target_identifier = -1


func set_allegiance(to:int) -> void:
	var report_allegiance_changed : bool = true if allegiance != to else false
	allegiance = to
	if report_allegiance_changed:
		emit_signal("allegiance_changed")


func set_spawned() -> void:
	var was_spawned : bool = true if spawn_status != Status.SPAWNED else false
	spawn_status = Status.SPAWNED
	if was_spawned:
		emit_signal("spawned")


func set_queued() -> void:
	var was_despawned : bool = true if spawn_status == Status.SPAWNED else false
	spawn_status = Status.IN_BUILDING_QUEUE
	if was_despawned:
		emit_signal("despawned")


func set_in_limbo() -> void:
	var was_despawned : bool = true if spawn_status == Status.SPAWNED else false
	spawn_status = Status.WAITING_FOR_QUEUE
	if was_despawned:
		emit_signal("despawned")


func save() -> void:
	if attack_timing_information != {}:
		attack_timing_information.cooldown_s = attack_timing_information.timeout_s - GameState.elapsed_time


func on_restore() -> void:
	if attack_timing_information != {}:
		attack_timing_information.timeout_s = attack_timing_information.cooldown_s + GameState.elapsed_time
		GameState.event_heap.push_dict_onto_heap(attack_timing_information)


func start_attack(target_hitbox_position:Vector2) -> bool:
	if not is_able_to_attack:
		return false
	attack_timing_information = BLANK_ATTACK_TIMING_INFORMATION_DICT.duplicate()
	attack_timing_information.cooldown_s = StaticData.get_species(species).attack_delay
	attack_timing_information.attack_targeted_position = target_hitbox_position
	attack_timing_information.unit_identifier = identifier
	attack_timing_information.callback = "_on_attack_delay_timed_out"
	attack_timing_information.timeout_s = GameState.elapsed_time + attack_timing_information.cooldown_s
	GameState.event_heap.push_dict_onto_heap(attack_timing_information)
	is_able_to_attack = false
	return true


func get_maximum_health() -> float:
	return _get_attr_modified_by_upgrade("maximum_health")


func get_melee_resistance() -> float:
	return _get_attr_modified_by_upgrade("melee_damage_to_multiplier")


func get_ranged_resistance() -> float:
	return _get_attr_modified_by_upgrade("ranged_damage_to_multiplier")


func get_maximum_range_of_attack() -> float:
	var spec : SpeciesStaticData = StaticData.get_species(species)
	var lesser_hb_radius : float = spec.attack_hb_len_or_radius_0 \
			if (spec.attack_hitbox_shape == SpeciesStaticData.HitboxShape.CIRCLE \
			or spec.attack_hb_len_or_radius_0 < spec.attack_hb_len_or_radius_1) \
			else spec.attack_hb_len_or_radius_1
	return _get_attr_modified_by_upgrade("attack_hb_offset") + lesser_hb_radius


func get_attack_damage_to_buildings() -> float:
	return _get_attr_modified_by_upgrade("attack_damage") * _get_attr_modified_by_upgrade("damage_to_buildings_multiplier")


func get_attack_damage_to_units(is_capture_attack:bool=false) -> float:
	if is_capture_attack and not _get_attr_modified_by_upgrade("true_capture"):
		return StaticData.get_species(species).attack_damage * StaticData.get_species(species).damage_to_units_multiplier
	return _get_attr_modified_by_upgrade("attack_damage") * _get_attr_modified_by_upgrade("damage_to_units_multiplier")


func get_attack_damage_type() -> int:
	return _get_attr_modified_by_upgrade("attack_damage_type")


func get_can_true_capture() -> bool:
	return _get_attr_modified_by_upgrade("true_capture")


func get_move_speed() -> float:
	return _get_attr_modified_by_upgrade("move_speed")


func take_damage(base_amount:float,damage_type:int) -> void:
	current_health -= _get_damage_modified_amount(base_amount,damage_type)
	if current_health <= 0.0:
		emit_signal("defeated")


func take_capture_damage(base_amount:float,damage_type:int,capture_threshold:float,capturing_faction:int,true_capture:bool=false) -> void:
	current_health -= _get_damage_modified_amount(base_amount,damage_type)
	if current_health < 0.0 and not true_capture:
		emit_signal("defeated")
		emit_signal("capture_attempt_failed") # for ui feedback only
	elif current_health < capture_threshold:
		set_in_limbo()
		set_allegiance(capturing_faction)
		emit_signal("captured")


func _get_damage_modified_amount(base_amount:float,damage_type:int) -> float:
	var modified_amount : float = base_amount
	if damage_type == SpeciesStaticData.DamageTypes.MELEE:
		modified_amount = base_amount * get_melee_resistance()
	elif damage_type == SpeciesStaticData.DamageTypes.RANGED:
		modified_amount = base_amount * get_ranged_resistance()
	return modified_amount


func _on_attack_delay_timed_out(dict:Dictionary) -> void:
	attack_timing_information = BLANK_ATTACK_TIMING_INFORMATION_DICT.duplicate()
	attack_timing_information.cooldown_s = StaticData.get_species(species).attack_cooldown - StaticData.get_species(species).attack_delay
	attack_timing_information.timeout_s = GameState.elapsed_time + attack_timing_information.cooldown_s
	attack_timing_information.unit_identifier = identifier
	attack_timing_information.attack_targeted_position = dict.attack_targeted_position
	attack_timing_information.callback = "_on_attack_cooldown_timed_out"
	GameState.event_heap.push_dict_onto_heap(attack_timing_information)
	_attack_rid = HitboxManager.spawn_hitbox(self,dict.attack_targeted_position)


func _on_attack_cooldown_timed_out(_dict:Dictionary) -> void:
	attack_timing_information = {}
	HitboxManager.remove_hitbox(_attack_rid)
	is_able_to_attack = true


func _get_attr_modified_by_upgrade(attr_name:String):
	if upgrade_type < 0:
		return StaticData.get_species(species).get(attr_name)
	var upgrade : UpgradeStaticData = StaticData.get_species(species).upgrade_attributes_by_identifier_then_faction[upgrade_type][upgrade_faction]
	if attr_name in StaticData.get_species(species).ATTRIBUTES_ADD_UPGRADE_TO:
		for i in range(4):
			if attr_name == upgrade.get("modified_attr_"+str(i)):
				return StaticData.get_species(species).get(attr_name) + upgrade.get("modified_value_"+str(i))
	elif attr_name in StaticData.get_species(species).ATTRIBUTES_REPLACE_UPGRADE_WITH:
		for i in range(4):
			if attr_name == upgrade.get("modified_attr_"+str(i)):
				return upgrade.get("modified_value_"+str(i))
	return StaticData.get_species(species).get(attr_name)
