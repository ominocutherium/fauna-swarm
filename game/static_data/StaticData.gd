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


const CSV_INFO_BY_DATA_SHEET := {
	"factions":{path="res://static_data/factions.csv",headers="custom_faction",item_class=FactionStaticData}, # must be first, many things reference it
	"species":{path="res://static_data/species.csv",headers="columns",item_class=SpeciesStaticData}, # must be early, some things reference it
	"species_disp":{path="res://static_data/species_display.csv",headers="columns",item_class=SpeciesDisplayStaticData},
	"buildings":{path="res://static_data/buildings.csv",headers="rows",item_class=BuildingStaticData},
	"faction_color_palettes":{path="res://static_data/faction_color_palettes.csv",headers="custom_colorpalettes",item_class=null},
	"species_upgrades":{path="res://static_data/upgrades.csv",headers="rows",item_class=UpgradeStaticData,}, # must be after species
}


var species := [] setget set_species
var species_disp := []
var buildings := []
var faction_color_palettes : Array setget set_faction_color_palettes
var _faction_color_palettes := FactionColorPalettesStaticData.new()
var factions := [] setget set_factions
var upgrades : Array setget set_upgrades

var _parse_state_property_name := ""
var _parse_state_items_in_creation := []
var _parse_state_row_headings := []
var _parse_state_row_data_types := []
var _species_name_keys_to_ids := {}
var _engine_keys_to_factions := {}
var engine_keys_to_faction_ids := {} # this is now the canonical way to look this up. TODO: Update any class that had this hard-coded.


func _ready() -> void:
	read_from_csv_files()


func get_species(identifier:int) -> SpeciesStaticData:
	if species.size() <= identifier or not species[identifier]:
		return null
	return species[identifier]


func get_species_display(identifier:int) -> SpeciesDisplayStaticData:
	if species_disp.size() <= identifier or not species_disp[identifier]:
		return null
	return species_disp[identifier]


func get_building(identifier:int) -> BuildingStaticData:
	if buildings.size() <= identifier or not buildings[identifier]:
		return null
	return buildings[identifier]


func get_faction(identifier:int) -> FactionStaticData:
	if species.size() <= identifier or not species[identifier]:
		return null
	return species[identifier]


func get_faction_color_palette(faction_id:int) -> Dictionary:
	return {}


func set_faction_color_palettes(arr:Array) -> void:
	_faction_color_palettes = arr[0]


func set_species(to:Array) -> void:
	species = to
	for i in range(species.size()):
		var sp := species[i] as SpeciesStaticData
		_species_name_keys_to_ids[sp.name_key] = i


func set_factions(to:Array) -> void:
	factions = to
	for i in range(factions.size()):
		engine_keys_to_faction_ids[factions[i].engine_key] = i


func read_from_csv_files() -> void:
	for property_name in CSV_INFO_BY_DATA_SHEET:
		_parse_state_property_name = property_name
		read_csv_file(CSV_INFO_BY_DATA_SHEET[property_name].path,CSV_INFO_BY_DATA_SHEET[property_name].headers)
		set(property_name,_parse_state_items_in_creation)
		_parse_state_items_in_creation = []
		_parse_state_row_headings = []


func read_csv_file(filepath:String,format:String) -> void:
	var f := File.new()
	var open_err := f.open(filepath,File.READ)
	if not open_err == OK:
		print("There was an error opening the data file {0}. Error code: {1}".format([filepath,open_err]))
		return
	while not f.eof_reached():
		match format:
			"columns":
				_process_csv_line_columns(f.get_csv_line())
			"rows":
				_process_csv_line_rows(f.get_csv_line())
			"custom_faction":
				_process_csv_line_custom_faction(f.get_csv_line())
			"custom_colorpalettes":
				_process_csv_line_custom_colorpalettes(f.get_csv_line())
			_:
				break
	f.close()


func set_upgrades(to:Array) -> void:
	pass


func _process_csv_line_rows(line:PoolStringArray) -> void:
	# row mode (where property headers are in the first row) are for data sheets with
	# many items but few properties.
	# New items are added row by row.
	if line.size() < 2:
		return
	if _parse_state_row_headings.size() == 0 and CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class is GDScript:
		# First row
		var sample_item = CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class.new()
		_parse_state_row_headings = Array(line)
		for i in range(line.size()):
			var pname : String = line[i]
			_parse_state_row_data_types.append(_get_type_of_property_name_in_item_class(pname,sample_item))
		if not sample_item is Reference:
			sample_item.free()
		return
	if CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class is GDScript:
		var item = CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class.new()
		var last_attr : String
		for i in range(line.size()):
			var cast_data
			var attr : String
			if _parse_state_row_headings[i] == "":
				attr = last_attr
			else:
				attr = _parse_state_row_headings[i]
				last_attr = attr
			if _parse_state_row_data_types[i] is Dictionary and line[i] in _parse_state_row_data_types[i]:
				item.set(attr,_parse_state_row_data_types[i][line[i]])
				continue
			match _parse_state_row_data_types[i]:
				TYPE_STRING:
					cast_data = line[i]
				TYPE_REAL:
					cast_data = 0.0 if not line[i].is_valid_float() else float(line[i])
				TYPE_INT:
					cast_data = -1 if not line[i].is_valid_integer() else int(line[i])
			if item.get(attr) is Array:
				item.get(attr).append(cast_data)
			else:
				item.set(attr,cast_data)
		if item.get("identifier") as int:
			item.identifier = _parse_state_items_in_creation.size()
		_parse_state_items_in_creation.append(item)


func _get_type_of_property_name_in_item_class(pname:String,item:Object):
	# Reading constant arrays/dictionaries on static data objects to know how to interpret cells from the csv for that object
	# Probably should break this method up to report more meaningful errors than null return if a const arr/dict is missing
	# or if the property name was not found within it
	if item.get("FILTER_ATTRIBUTES") as Dictionary and item.FILTER_ATTRIBUTES.has(pname):
		return item.get(item.FILTER_ATTRIBUTES[pname])
	for type_list_pair in [
			["STRING_ATTRIBUTES",TYPE_STRING],
			["INT_ATTRIBUTES",TYPE_INT],
			["REAL_ATTRIBUTES",TYPE_REAL],
			]:
		if item.get(type_list_pair[0]) as Array and pname in item.get(type_list_pair[0]):
			return type_list_pair[1]
	return null


func _process_csv_line_columns(line:PoolStringArray) -> void:
	# column mode (where property headers are in the first column and each respective column
	# is an item) are for data sheets with more properties than items within.
	# Items are initialized from the first row and properties are read to all of the items
	# row-by-row.
	if line.size() < 2:
		return
	if _parse_state_items_in_creation.size() == 0:
		for i in range(1,line.size()):
			if CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class is GDScript:
				_parse_state_items_in_creation.append(CSV_INFO_BY_DATA_SHEET[_parse_state_property_name].item_class.new())
		if get(_parse_state_property_name) as Array:
			set(_parse_state_property_name,_parse_state_items_in_creation)
	var pname : String = line[0]
	var sample_item : Object = _parse_state_items_in_creation[0]
	var handler = _get_type_of_property_name_in_item_class(pname,sample_item)
	for i in range(line.size()-1):
		var item : Object = _parse_state_items_in_creation[i]
		var cell : String = line[i+1]
		if handler is Dictionary:
			if cell in handler:
				item.set(pname,handler[cell])
			continue
		match handler:
			TYPE_STRING:
				item.set(pname,cell)
			TYPE_REAL:
				var cast_data : float = 0.0 if not cell.is_valid_float() else float(cell)
				item.set(pname,cast_data)
			TYPE_INT:
				var cast_data : int = -1 if not cell.is_valid_integer() else int(cell)
				item.set(pname,cast_data)


func _process_csv_line_custom_faction(line:PoolStringArray) -> void:
	if line.size() < 2:
		return
	var pfaction := FactionStaticData.new()
	if _get_type_of_property_name_in_item_class(line[0],pfaction) != null:
		_process_csv_line_columns(line)
	if line[0].begins_with("Unit Bonuses"):
		for f in _parse_state_items_in_creation:
			var faction := f as FactionStaticData
			_engine_keys_to_factions[faction.engine_key] = faction
		return
	var unit_bonus_dict := {}
	if _species_name_keys_to_ids.has(line[1]):
		unit_bonus_dict.species = _species_name_keys_to_ids[line[1]]
	unit_bonus_dict.property = line[2]
	if unit_bonus_dict.property in SpeciesStaticData.STRING_ATTRIBUTES:
		unit_bonus_dict.value = line[3]
	elif unit_bonus_dict.property in SpeciesStaticData.REAL_ATTRIBUTES and line[3].is_valid_float():
		unit_bonus_dict.value = line[3].to_float()
	elif unit_bonus_dict.property in SpeciesStaticData.INT_ATTRIBUTES and line[3].is_valid_integer():
		unit_bonus_dict.value = line[3].to_int()
	if _engine_keys_to_factions.has(line[0]):
		var f := _engine_keys_to_factions[line[0]] as FactionStaticData
		f.unit_bonuses.append(unit_bonus_dict)


func _process_csv_line_custom_colorpalettes(line:PoolStringArray) -> void:
	if line.size() < 2 or line[0].begins_with("faction"):
		return
	if not line[1].is_valid_float():
		return
	if not line[2].is_valid_hex_number() and not line[2].substr(1).is_valid_hex_number():
		return
	if not line[0] in _engine_keys_to_factions:
		return
	if _parse_state_items_in_creation.size() == 0:
		_parse_state_items_in_creation.append(FactionColorPalettesStaticData.new())
	var f := _parse_state_items_in_creation[0] as FactionColorPalettesStaticData
	if not f.palettes_by_faction_name.has(line[0]):
		f.palettes_by_faction_name[line[0]] = {}
	f.palettes_by_faction_name[line[0]][line[1].to_float()] = Color(line[2])


func _assign_upgrades_arr_to_species_files(arr:Array) -> void:
	pass
