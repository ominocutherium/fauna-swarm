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

enum GameMode {SP_PURITY_VS_SINGLE_EVIL,SP_PURITY_VS_TWO_EVILS,MP_EVIL_VS_EVIL}

var units := []
var factions := []
var buildings := []
var background_tiles : BackgroundTileData
var building_tiles : GameStateBuildingData
var elapsed_time : float = 0.0
var event_heap := EventHeap.new()
var random_number_generator := RandomNumberGenerator.new()
var rng_seed : int
var cosmetic_rng : RandomNumberGenerator
var game_mode : int = GameMode.SP_PURITY_VS_SINGLE_EVIL


func _init() -> void:
	event_heap.dict_key_with_compare = "timeout_s"


func _ready() -> void:
	set_process(false)


func _process(delta:float) -> void:
	elapsed_time += delta
	var elapsed_dict := event_heap.compare_top_dict_with_value(elapsed_time)
	if elapsed_dict != {}:
		_process_timed_out_event_dict(elapsed_dict)


func initialize_new_game(mode:int=GameMode.SP_PURITY_VS_SINGLE_EVIL,mapfile:StartingMapResource=null,use_seed:bool=false,used_seed:int=-1) -> void:
	if use_seed:
		random_number_generator.seed = used_seed
	# Static Data needs to be loaded first!
	background_tiles = BackgroundTileData.new()
	building_tiles = GameStateBuildingData.new()
	if mapfile:
		cosmetic_rng = background_tiles.init_newgame_map_from_mapfile(mapfile)
	factions.resize(StaticData.engine_keys_to_faction_ids.size())
	var used_edge_locations := PoolVector2Array()
	if mode in [GameMode.SP_PURITY_VS_SINGLE_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		var pure_faction := _generate_faction(StaticData.engine_keys_to_faction_ids.purity)
		used_edge_locations.append(pure_faction.new_units_spawn_at)
	var first_chosen_evil : int = StaticData.engine_keys_to_faction_ids.specter
	var first_evil_faction := _generate_faction(first_chosen_evil)
	used_edge_locations.append(first_evil_faction.new_units_spawn_at)
	if mode in [GameMode.MP_EVIL_VS_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		var second_chosen_evil : int = -1
		while second_chosen_evil < 0 or second_chosen_evil == first_chosen_evil:
			second_chosen_evil = random_number_generator.randi_range(0,StaticData.engine_keys_to_faction_ids.size())
		var second_evil_faction := _generate_faction(second_chosen_evil)
	if mode != GameMode.MP_EVIL_VS_EVIL:
		_place_unclaimed_forest_hearts(mapfile)


func get_pure_faction() -> Object:
	if factions.size() > 0 and game_mode in [GameMode.SP_PURITY_VS_SINGLE_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		return factions[StaticData.engine_keys_to_faction_ids.purity]
	return null


func get_unit(identifier:int) -> SavedUnit:
	if units.size() <= identifier:
		return null
	return units[identifier]


func restore(save_res:SavedGameState) -> void:
	random_number_generator.seed = save_res.rng_seed
	random_number_generator.state = save_res.rng_state
	units = save_res.units
	for u in units:
		(u as SavedUnit).on_restore()
	factions = save_res.factions
	for f in factions:
		(f as SavedFaction).on_restore()
	background_tiles = save_res.background_tiles
	background_tiles.restore()
	building_tiles = save_res.building_tiles
	buildings = save_res.buildings
	for b in buildings:
		(b as SavedBuilding).on_restore()
	elapsed_time = save_res.elapsed_time
	for u in units:
		var unit := u as SavedUnit
		# TODO: check if spawned, if so call UnitManager.spawn_unit()


func save() -> SavedGameState:
	var save_res := SavedGameState.new()
	background_tiles.on_save()
	save_res.background_tiles = background_tiles
	save_res.building_tiles = building_tiles
	save_res.elapsed_time = elapsed_time
	for b in buildings:
		(b as SavedBuilding).on_save()
	save_res.buildings = buildings
	save_res.units = _serialize_units()
	for f in factions:
		(f as SavedFaction).on_save()
	save_res.factions = factions
	save_res.rng_seed = rng_seed
	save_res.rng_state = random_number_generator.state
	return save_res


func _serialize_units() -> Array: # sets and returns an array of SavedUnits
	_prune_unalive_and_unqueued_units_when_serializing()
	for u in units:
		var unit := u as SavedUnit
		unit.sync_data_from_manager()
		unit.save()
	return units


func _prune_unalive_and_unqueued_units_when_serializing() -> void:
	pass


func _process_timed_out_event_dict(event:Dictionary) -> void:
	pass


func _generate_faction(identifier:int) -> SavedFaction:
	var f := SavedFaction.new()
	f.identifier = identifier
	factions[identifier] = f
	_choose_starting_units_for_faction(f)
	_place_factions_initial_buildings(f)
	return f


func _choose_starting_units_for_faction(_faction:SavedFaction) -> void:
	# also initializes starting location
	pass


func _place_factions_initial_buildings(_faction:SavedFaction) -> void:
	pass


func _place_unclaimed_forest_hearts(_mapfile:StartingMapResource) -> void:
	pass
