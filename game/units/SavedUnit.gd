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
export(int) var spawn_status : int
export(int) var upgrade_type = -1
export(int) var upgrade_faction = -1
export(Dictionary) var attack_timing_information := {}
export(bool) var is_able_to_attack : bool = true


var maximum_health : float setget ,get_maximum_health


func sync_data_from_manager() -> void:
	# Queries UnitManager singleton for updated position data, if alive.
	pass


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
	# TODO: incorporate upgrades into calc
	return StaticData.get_species(species).maximum_health


func get_melee_resistance() -> float:
	# TODO: incorporate upgrades into calc
	return StaticData.get_species(species).melee_damage_to_multiplier


func get_ranged_resistance() -> float:
	# TODO: incorporate upgrades into calc
	return StaticData.get_species(species).ranged_damage_to_multiplier


func take_damage(base_amount:float,damage_type:int) -> void:
	var modified_amount : float = base_amount
	if damage_type == SpeciesStaticData.DamageTypes.MELEE:
		modified_amount = base_amount * get_melee_resistance()
	elif damage_type == SpeciesStaticData.DamageTypes.RANGED:
		modified_amount = base_amount * get_ranged_resistance()
	current_health -= modified_amount
	if current_health <= 0.0:
		emit_signal("defeated")


func _on_attack_delay_timed_out(dict:Dictionary) -> void:
	attack_timing_information = BLANK_ATTACK_TIMING_INFORMATION_DICT.duplicate()
	attack_timing_information.cooldown_s = StaticData.get_species(species).attack_cooldown - StaticData.get_species(species).attack_delay
	attack_timing_information.timeout_s = GameState.elapsed_time + attack_timing_information.cooldown_s
	attack_timing_information.unit_identifier = identifier
	attack_timing_information.attack_targeted_position = dict.attack_targeted_position
	attack_timing_information.callback = "_on_attack_cooldown_timed_out"
	GameState.event_heap.push_dict_onto_heap(attack_timing_information)
	# TODO: When hitbox manager is available, push hitbox information


func _on_attack_cooldown_timed_out(dict:Dictionary) -> void:
	attack_timing_information = {}
	is_able_to_attack = true
