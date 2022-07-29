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

extends MapTileData

class_name BackgroundTileData


const MIN_TIME_TO_INFECT = 30.0
const MIN_TIME_TO_PURIFY = 5.0
const INFECTION_RANGE = 3
const PURIFICATION_RANGE = 8
const TILE_TYPES_DATA_PATH = "res://static_data/tile_types_functional.csv"
const TILE_AUTOTILE_DATA_PATH = "res://static_data/tile_autotile_information.csv"
const AT_TOP_BIT = 0
const AT_RIGHT_BIT = 1
const AT_BOTTOM_BIT = 2
const AT_LEFT_BIT = 3

signal tile_infected(coords,with_biome)
signal tile_purified(coords)
signal entire_map_is_infected

var total_infected_tile_count : int = -1
var total_pure_tile_count : int = -1
var tile_types_by_identifier := {}
var _tile_identifiers_by_tilemap_id := {}
var _autotile_bitmasks_by_tilemap_id := PoolIntArray()
var _lists_of_tile_types_by_biome := {}
var _lists_of_tile_types_by_elevation := {}
var _title_type_lists_by_elevation_then_biome := {}
var rng : RandomNumberGenerator


export(PoolRealArray) var tile_cannot_change_cooldown_started : PoolRealArray
export(int) var cosmetic_randomization_seed : int
export(int) var cosmetic_randomization_state : int
export(Dictionary) var tile_ids_ever_within_purification_range := {}


func _init() -> void:
	_load_tiles_data()


func choose_tiles_to_process(num_tiles:int,current_time:float) -> void:
	for _i in range(num_tiles):
		var chosen_tile : int = GameState.random_number_generator.randi_range(0,tile_data.size()-1)
		_process_tile(chosen_tile,current_time)


func _process_tile(tile_identifier:int, current_time:float) -> void:
	var coords := Vector2(tile_identifier%int(extents.size.x),floor(tile_identifier/extents.size.x))
	if _is_tile_within_purification_range(coords):
		if not coords in tile_ids_ever_within_purification_range:
			tile_ids_ever_within_purification_range[coords] = true
		# purification check
		if current_time - tile_cannot_change_cooldown_started[tile_identifier] > MIN_TIME_TO_PURIFY and _is_tile_infected(tile_identifier):
			# purify tile
			_mutate_tile_to_biome(tile_identifier,StaticData.engine_keys_to_faction_ids.purity)
			total_infected_tile_count -= 1
			total_pure_tile_count += 1
			emit_signal("tile_purified",coords)
			_mark_tiles_within_range_as_under_cooldown(coords,current_time,PURIFICATION_RANGE)
	elif _is_tile_infected(tile_identifier): # being within purification range blocks infection
		# infection check
		var chosen_tile_to_infect : Vector2 = Vector2(
				GameState.random_number_generator.randi_range(int(coords.x)-INFECTION_RANGE,int(coords.x)+INFECTION_RANGE),
				GameState.random_number_generator.randi_range(int(coords.y)-INFECTION_RANGE,int(coords.y)+INFECTION_RANGE))
		var chosen_tile_identifier : int = int(chosen_tile_to_infect.x)+int(chosen_tile_to_infect.y*extents.size.x)
		if _get_discrete_tile_distance(coords,chosen_tile_to_infect) <= INFECTION_RANGE and \
				_is_tile_infectable(chosen_tile_identifier) and current_time - tile_cannot_change_cooldown_started[tile_identifier] > MIN_TIME_TO_INFECT:
			# infect tile
			total_infected_tile_count += 1
			total_pure_tile_count -= 1
			_mutate_tile_to_biome(chosen_tile_identifier,_get_biome_of_tile(tile_data[tile_identifier]))
			emit_signal("tile_infected",chosen_tile_to_infect,_get_biome_of_tile(tile_data[tile_identifier]))
			_mark_tiles_within_range_as_under_cooldown(chosen_tile_to_infect,current_time,INFECTION_RANGE)
			if total_pure_tile_count <= 0:
				emit_signal("entire_map_is_infected")


func init_newgame_map_from_mapfile(new_game_map:StartingMapResource) -> RandomNumberGenerator:
	rng = RandomNumberGenerator.new()
	rng.seed = new_game_map.cosmetic_randomization_seed
	extents = new_game_map.extents
	tile_data.resize(new_game_map.tile_data.size())
	for i in range(new_game_map.tile_data.size()):
		var tile_type_name : String = new_game_map.tile_type_names_by_id[new_game_map.tile_data[i]]
		var tile_type := tile_types_by_identifier[tile_type_name] as TileType
		var tilemap_idx : int = rng.randi_range(0,tile_type.tiles_in_tileset.size()-1)
		tile_data[i] = tile_type.tiles_in_tileset[tilemap_idx]
	Pathfinding.set_map_and_obstacles_structure(new_game_map)
	cosmetic_randomization_seed = new_game_map.cosmetic_randomization_seed
	_create_count_of_inf_pure_tiles_on_init_or_restore()
	return rng # pass the cosmetic rng with its current state for another object to use to randomize background object sprites


func infect_tiles(list_of_coords:Array,to_biome:int) -> void:
	# call on NGI when generating evil buildings at start (evil buildings can only be built on corresponding biome)
	for coord in list_of_coords:
		var idx : int = int((coord.y-extents.position.y) * extents.size.x + coord.x - extents.position.x)
		_mutate_tile_to_biome(idx,to_biome)
		total_infected_tile_count += 1
		total_pure_tile_count += 1


func get_tile_type_by_name(tile_identifier:String) -> TileType:
	return tile_types_by_identifier[tile_identifier] as TileType


func get_num_tiles_ever_within_purification_range() -> int:
	return tile_ids_ever_within_purification_range.size()


func on_save() -> void:
	cosmetic_randomization_state = rng.state


func restore() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = cosmetic_randomization_seed
	rng.state = cosmetic_randomization_state
	_create_count_of_inf_pure_tiles_on_init_or_restore()


func _load_tiles_data() -> void:
	# TODO: move this to a new class which is owned by the Static Data singleton for consistent loading of all static data in the same place
	var f := File.new()
	if f.open(TILE_TYPES_DATA_PATH,f.READ) == OK:
		while not f.eof_reached():
			var line := f.get_csv_line()
			_load_tiles_data_process_csv_line(line)
		f.close()
	_finish_cataloguing_tiles()


func _load_autotile_data() -> void:
	var f := File.new()
	if f.open(TILE_AUTOTILE_DATA_PATH,f.READ) == OK:
		while not f.eof_reached():
			var line := f.get_csv_line()
			_load_autotile_data_process_csv_line(line)
		f.close()


func _find_matching_autotile_indices(list_of_indices_to_check : PoolIntArray,must_match_mask:int) -> PoolIntArray:
	# First four bits (little-endian) of the must match mask indicate which directions require a match.
	# The remaining sixteen bits indicate the biomes that must be matched to.
	var matches := PoolIntArray()
	var required_match_mask := 0
	var biome_match_mask := 0
	for bit in [AT_BOTTOM_BIT,AT_LEFT_BIT,AT_RIGHT_BIT,AT_TOP_BIT]:
		if ! must_match_mask&(1<<bit):
			required_match_mask |= 15<<(4*(bit+1))
			biome_match_mask |= must_match_mask&(15<<(4*(bit+1)))
	for idx in list_of_indices_to_check:
		if (_autotile_bitmasks_by_tilemap_id[idx] & required_match_mask) == biome_match_mask:
			matches.append(idx)
	return matches


class TileType:
	extends Reference

	var name : String
	var corner_elevations := [] setget set_corner_elevations
	var corner_elevation_key : int
	var corner_elevations_by_direction := {}
	var biome : int
	var tiles_in_tileset := []
	
	func set_corner_elevations(to:Array) -> void:
		corner_elevations = to
		corner_elevations_by_direction = {
			Vector2(-1,1):corner_elevations[0],
			Vector2(1,1):corner_elevations[1],
			Vector2(1,-1):corner_elevations[2],
			Vector2(-1,-1):corner_elevations[3],
		}
		corner_elevation_key = 0 | int(corner_elevations[0]) | (int(corner_elevations[1])<<4) | (int(corner_elevations[2])<<8) | (int(corner_elevations[3])<<12)


func _load_tiles_data_process_csv_line(line:PoolStringArray) -> void:
	if line.size() < 7 or not line[2].is_valid_float():
		return
	var t_t := TileType.new()
	var id : String = line[0]
	tile_types_by_identifier[id] = t_t
	t_t.name = id
	t_t.biome = StaticData.engine_keys_to_faction_ids[line[1]] if line[1] in StaticData.engine_keys_to_faction_ids else -1
	if not _lists_of_tile_types_by_biome.has(t_t.biome):
		_lists_of_tile_types_by_biome[t_t.biome] = []
	_lists_of_tile_types_by_biome[t_t.biome].append(t_t.name)
	var corner_evs := []
	for i in range(2,2+4):
		if line[i].is_valid_float():
			corner_evs.append(float(line[i]))
	t_t.corner_elevations = corner_evs
	if not _lists_of_tile_types_by_elevation.has(t_t.corner_elevation_key):
		_lists_of_tile_types_by_elevation[t_t.corner_elevation_key] = []
	_lists_of_tile_types_by_elevation[t_t.corner_elevation_key].append(t_t.name)
	for i in range(6,line.size()):
		if line[i].is_valid_integer():
			t_t.tiles_in_tileset.append(int(line[i]))
			_tile_identifiers_by_tilemap_id[int(line[i])] = id


func _finish_cataloguing_tiles() -> void:
	for elevation_key in _lists_of_tile_types_by_elevation:
		_title_type_lists_by_elevation_then_biome[elevation_key] = {}
		for biome in _lists_of_tile_types_by_biome:
			_title_type_lists_by_elevation_then_biome[elevation_key][biome] = []
	for tile_type_name in tile_types_by_identifier:
		var t_t := get_tile_type_by_name(tile_type_name)
		_title_type_lists_by_elevation_then_biome[t_t.corner_elevation_key][t_t.biome].append(tile_type_name)


func _load_autotile_data_process_csv_line(line:PoolStringArray) -> void:
	# Set a mask for the tile from the read data. The mask uses 20 bits (little-endian).
	# The first four bits are not used, though, because they are reserved for information about a tile match.
	# The other sixteen bits record the biomes that this tile display matches.
	if line.size() < 5:
		return
	if not line[0].is_valid_integer():
		return
	var idx : int = int(line[0])
	var mask : int = 0
	for i in range(1,5):
		if not line[i] in StaticData.engine_keys_to_faction_ids:
			return
		mask |= StaticData.engine_keys_to_faction_ids[line[i]]<<(4*i)
	if _autotile_bitmasks_by_tilemap_id.size() < idx + 1:
		_autotile_bitmasks_by_tilemap_id.resize(idx+1)
	_autotile_bitmasks_by_tilemap_id[idx] = mask


func _get_discrete_tile_distance(coords0:Vector2,coords1:Vector2) -> float:
	# function to return a board-game-like distance between tiles in a tilemap with 1.5 as the diagonal value instead of sqrt(2).
	# inaccurate for long distances (but less so than treating diagonals as a distance of 1) but produces values that round well nearby.
	var abs_dist := Vector2(abs(coords0.x-coords1.x),abs(coords0.y-coords1.y))
	var linear_value := abs(abs_dist.x-abs_dist.y)
	var diags := abs_dist.x if abs_dist.x < abs_dist.y else abs_dist.y
	return 1.5 * diags + linear_value


func _get_biome_of_tile(tm_tile_id:int) -> int:
	var current_tile_type : TileType = get_tile_type_by_name(_tile_identifiers_by_tilemap_id[tm_tile_id])
	return current_tile_type.biome


func _is_tile_infectable(index:int,by_other_evil:int=-1) -> bool:
	var biome := _get_biome_of_tile(tile_data[index])
	if biome == StaticData.engine_keys_to_faction_ids.purity:
		return true
	if by_other_evil == -1 or GameState.game_mode != GameState.GameMode.SP_PURITY_VS_TWO_EVILS:
		return false
	if biome == StaticData.engine_keys_to_faction_ids.artifice and by_other_evil == StaticData.engine_keys_to_faction_ids.specter:
		return true
	if biome == StaticData.engine_keys_to_faction_ids.specter and by_other_evil == StaticData.engine_keys_to_faction_ids.sanguine:
		return true
	if biome == StaticData.engine_keys_to_faction_ids.sanguine and by_other_evil == StaticData.engine_keys_to_faction_ids.pestilence:
		return true
	if biome == StaticData.engine_keys_to_faction_ids.pestilence and by_other_evil == StaticData.engine_keys_to_faction_ids.artifice:
		return true
	return false


func _is_tile_infected(index:int) -> bool:
	if _get_biome_of_tile(tile_data[index]) != StaticData.engine_keys_to_faction_ids.purity:
		return true
	return false


func _mutate_tile_to_biome(index:int,to_biome:int) -> void:
	var current_tile_type : TileType = get_tile_type_by_name(_tile_identifiers_by_tilemap_id[tile_data[index]])
	var same_elevation_tile_types : Array = _title_type_lists_by_elevation_then_biome[current_tile_type.corner_elevation_key][to_biome]
	var choices := []
	for t_t in same_elevation_tile_types:
		choices.append_array(tile_types_by_identifier[t_t].tiles_in_tileset)
	var choice_idx : int = rng.randi_range(0,choices.size()-1)
	tile_data[index] = choices[choice_idx]


func _is_tile_within_purification_range(coords:Vector2) -> bool:
	if GameState.building_tiles.get_num_of_purity_buildings() > 0:
		if _get_discrete_tile_distance(coords,GameState.building_tiles.get_coords_of_nearest_purity_building_to(coords)) <= PURIFICATION_RANGE:
			return true
	return false


func _mark_tiles_within_range_as_under_cooldown(from_coords:Vector2,current_time:float,range_of_tiles:int) -> void:
	# every time a tile changes biome, nearby tiles are marked with the cooldown started time
	# so that they cannot change as well until the cooldown is up
	# prevents infection from spreading too quickly and evil factions from building too quickly
	for x in range(from_coords.x - range_of_tiles,from_coords.x+range_of_tiles):
		for y in range(from_coords.y - range_of_tiles,from_coords.y + range_of_tiles):
			if _get_discrete_tile_distance(from_coords,Vector2(x,y)) <= range_of_tiles:
				tile_cannot_change_cooldown_started[x+y*int(extents.size.x)] = current_time


func _create_count_of_inf_pure_tiles_on_init_or_restore() -> void:
	total_infected_tile_count = 0
	total_pure_tile_count = 0
	for i in range(tile_data.size()):
		if _is_tile_infected(i):
			total_infected_tile_count += 1
		else:
			total_pure_tile_count += 1
