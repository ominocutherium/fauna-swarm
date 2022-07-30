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
var commanders := []
var background_tiles : BackgroundTileData
var building_tiles : GameStateBuildingData
var elapsed_time : float = 0.0
var event_heap := EventHeap.new()
var random_number_generator := RandomNumberGenerator.new()
var rng_seed : int
var cosmetic_rng : RandomNumberGenerator
var game_mode : int = GameMode.SP_PURITY_VS_SINGLE_EVIL
var starting_forest_heart_count : int = 0


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
	_ngi_seed(use_seed,used_seed)
	# Static Data needs to be loaded first!
	background_tiles = BackgroundTileData.new()
	building_tiles = GameStateBuildingData.new()
	if not mapfile:
		return
	cosmetic_rng = background_tiles.init_newgame_map_from_mapfile(mapfile)
	building_tiles.init_newgame_map_from_mapfile(mapfile)
	factions.resize(StaticData.engine_keys_to_faction_ids.size())
	var used_starting_locations := {}
	var first_chosen_evil : int = StaticData.engine_keys_to_faction_ids.specter
	var first_evil_faction := _generate_faction(first_chosen_evil)
	used_starting_locations[_place_factions_initial_buildings(first_evil_faction,mapfile)] = first_evil_faction
	var used_factions := [first_evil_faction]
	if mode in [GameMode.SP_PURITY_VS_SINGLE_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		var pure_faction := _generate_faction(StaticData.engine_keys_to_faction_ids.purity)
		used_factions.append(pure_faction)
		used_starting_locations[_place_factions_initial_buildings(pure_faction,mapfile)] = pure_faction
	var second_evil_faction : SavedFaction
	starting_forest_heart_count = mapfile.number_of_unclaimed_forest_hearts
	if mode in [GameMode.MP_EVIL_VS_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		var second_chosen_evil : int = -1
		while second_chosen_evil < 0 or second_chosen_evil == first_chosen_evil:
			second_chosen_evil = random_number_generator.randi_range(0,StaticData.engine_keys_to_faction_ids.size())
		second_evil_faction = _generate_faction(second_chosen_evil)
		used_factions.append(second_evil_faction)
		used_starting_locations[_place_factions_initial_buildings(second_evil_faction,mapfile,true,used_starting_locations.keys()[0])] = second_evil_faction
	if mode != GameMode.MP_EVIL_VS_EVIL:
		_place_unclaimed_forest_hearts(mapfile)
	_ngi_assign_edges_to_factions(used_starting_locations)
	for faction in used_factions:
		if faction != null:
			faction.on_init()
	_on_init_or_restore()


func get_pure_faction() -> Object:
	if factions.size() > 0 and game_mode in [GameMode.SP_PURITY_VS_SINGLE_EVIL,GameMode.SP_PURITY_VS_TWO_EVILS]:
		return factions[StaticData.engine_keys_to_faction_ids.purity]
	return null


func get_unit(identifier:int) -> SavedUnit:
	if units.size() <= identifier:
		return null
	return units[identifier]


func add_unit(species:int,upgrade_equipped:int,faction:int) -> int:
	var identifier : int = units.size()
	var unit := SavedUnit.new()
	unit.faction = faction
	unit.allegiance = faction
	unit.species = species
	unit.upgrade_faction = faction
	unit.upgrade_type = upgrade_equipped
	units.append(unit)
	_add_unit_connections(identifier,unit)
	return identifier


func create_building(building_type:int,where_coords:Vector2) -> int:
	var building := SavedBuilding.new()
	building.identifier = buildings.size()
	building.building_type = building_type
	building.main_tile_x = where_coords.x
	building.main_tile_y = where_coords.y
	buildings.append(building)
	building_tiles.add_building(building,where_coords)
	return building.identifier


func restore(save_res:SavedGameState) -> void:
	random_number_generator.seed = save_res.rng_seed
	random_number_generator.state = save_res.rng_state
	units = save_res.units
	for u in units:
		var unit := u as SavedUnit
		unit.on_restore()
		_add_unit_connections(unit.identifier,unit)
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
	starting_forest_heart_count = save_res.starting_forest_heart_count
	_on_init_or_restore()


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
	save_res.starting_forest_heart_count = starting_forest_heart_count
	return save_res


func _serialize_units() -> Array: # sets and returns an array of SavedUnits
	_prune_unalive_and_unqueued_units_when_serializing()
	for u in units:
		var unit := u as SavedUnit
		unit.sync_data_from_manager()
		unit.save()
	return units


func _on_init_or_restore() -> void:
	commanders.resize(factions.size())
	for i in range(factions.size()):
		if factions[i] as SavedFaction:
			match StaticData.get_faction(i).faction_type:
				FactionStaticData.FactionTypes.PURE:
					commanders[i] = Commander.new()
				FactionStaticData.FactionTypes.EVIL:
					if game_mode != GameMode.MP_EVIL_VS_EVIL:
						commanders[i] = NPCCommander.new()
					else:
						commanders[i] = Commander.new()
			commanders[i].faction_id = i


func _prune_unalive_and_unqueued_units_when_serializing() -> void:
	pass


func _process_timed_out_event_dict(event:Dictionary) -> void:
	if event.has("callback_obj") and event.callback_obj as Object and event.has("callback") and event.callback_obj.has_method(event.callback):
		event.callback_obj.call_deferred(event.callback,event)


func _generate_faction(identifier:int) -> SavedFaction:
	var f := SavedFaction.new()
	f.identifier = identifier
	factions[identifier] = f
	_choose_starting_units_for_faction(f)
	return f


func _choose_starting_location_for_faction(faction:SavedFaction,mapfile:StartingMapResource,without_used_location:bool=false,used_location:Vector2=Vector2()) -> Vector2:
	var loc_idx : int
	var arr : PoolVector2Array
	match StaticData.get_faction(faction.identifier).faction_type:
		FactionStaticData.FactionTypes.PURE:
			arr = mapfile.purity_spawn_possible_locations
		FactionStaticData.FactionTypes.EVIL:
			arr = mapfile.evil_spawn_possible_locations
	loc_idx = random_number_generator.randi_range(0,arr.size()-1)
	if without_used_location:
		while arr[loc_idx] == used_location:
			loc_idx = random_number_generator.randi_range(0,arr.size()-1)
	return arr[loc_idx]


func _choose_starting_units_for_faction(_faction:SavedFaction) -> void:
	# also initializes starting location
	pass


func _place_factions_initial_buildings(faction:SavedFaction,mapfile:StartingMapResource,without_used_location:bool=false,used_location:Vector2=Vector2()) -> Vector2:
	var building_loc := _choose_starting_location_for_faction(faction,mapfile,without_used_location,used_location)
	var building_type : int
	var faction_type : int = StaticData.get_faction(faction.identifier).faction_type
	match StaticData.get_faction(faction.identifier).faction_type:
		FactionStaticData.FactionTypes.PURE:
			building_type = 0
			# TODO: ideally, some building should be marked in static data as the command center. Hardcoding values because out of time.
		FactionStaticData.FactionTypes.EVIL:
			building_type = 4
	var building_st_data = StaticData.get_building(building_type)
	if faction_type == FactionStaticData.FactionTypes.EVIL:
		for i in range(building_st_data.len_h_tiles*building_st_data.len_v_tiles):
			var coord_to_mutate : Vector2 = building_loc - Vector2(i%building_st_data.len_h_tiles,i/building_st_data.len_h_tiles)
			var tile_to_mutate : int = int((coord_to_mutate.x-background_tiles.extents.position.x) + (coord_to_mutate.y-background_tiles.extents.position.y) * background_tiles.extents.size.x)
			background_tiles._mutate_tile_to_biome(tile_to_mutate,faction.identifier)
	var building := create_building(building_type,building_loc)
	faction.building_identifiers.append(building)
	(buildings[building] as SavedBuilding).build_progress = 1.0
	return building_loc


func _place_unclaimed_forest_hearts(_mapfile:StartingMapResource) -> void:
	var used_locs := {}
	pass


func _on_unit_captured(unit:SavedUnit,faction_captured_by:int) -> void:
	pass


func _add_unit_connections(unit_id:int,unit:SavedUnit) -> void:
	unit.connect("order_set",UnitManager,"_on_unit_order_set",[unit_id])


func _ngi_seed(use_seed:bool,used_seed:int=-1) -> void:
	if use_seed:
		rng_seed = used_seed
	else:
		randomize()
		rng_seed = randi()
	random_number_generator.seed = rng_seed


func _ngi_assign_edges_to_factions(used_starting_locations_to_factions:Dictionary) -> void:
	var center_between_faction_starting_locations : Vector2
	for loc in used_starting_locations_to_factions:
		center_between_faction_starting_locations += loc
	center_between_faction_starting_locations /= used_starting_locations_to_factions.size()
	var faction_dots := {}
	for faction in used_starting_locations_to_factions.values():
		faction_dots[faction.identifier] = {}
	for loc in used_starting_locations_to_factions:
		var faction : SavedFaction = used_starting_locations_to_factions[loc]
		var to_center_norm : Vector2 = (loc - center_between_faction_starting_locations).normalized()
		for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
			faction_dots[faction.identifier][direction] = to_center_norm.dot(direction)
	var directions_to_edges_to_factions_using_them := {}
	for faction_id in faction_dots:
		var highest_dot_product : float = -1.0
		var dir_with_highest_dot := Vector2()
		for dir in faction_dots[faction_id]:
			if faction_dots[faction_id][dir] > highest_dot_product and not dir in directions_to_edges_to_factions_using_them:
				dir_with_highest_dot = dir
				highest_dot_product = faction_dots[faction_id][dir]
		directions_to_edges_to_factions_using_them[dir_with_highest_dot] = factions[faction_id]
	for dir in directions_to_edges_to_factions_using_them:
		(directions_to_edges_to_factions_using_them[dir] as SavedFaction).new_units_spawn_at = 49 * dir * UnitManager.TILE_LEN
