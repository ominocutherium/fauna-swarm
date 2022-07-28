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

extends Reference

class_name Commander

# the object that actually issues orders for the faction to the rest of the game state.
# a "commander" is decoupled from faction so that it is possible for there to be two commanders in one faction
# (i.e. for a future co-op mode)
# It's also cleaner to separate this code from Faction so that it can be inherited by a class
# which holds all of the NPC faction AI logic.

var faction_id : int = -1 setget set_faction_id
var faction : SavedFaction setget ,get_faction


func set_building_order(building_to_build:int,units_to_build_it:Array,where_coords:Vector2) -> void:
	var building_type = StaticData.get_building(building_to_build)
	var building = GameState.create_building(building_to_build,where_coords)
	self.faction.current_currency -= building_type.cost_to_build

	for unit_id in units_to_build_it:
		var unit : SavedUnit = GameState.get_unit(unit_id)
		unit.set_order(UnitManager.OrderTypes.BUILD_OBJ,UnitManager.ObjTargetTypes.BUILDING,building)
		UnitManager.mark_unit_as_needing_order_resolution(unit_id)


func get_faction() -> SavedFaction:
	return GameState.factions[faction_id]


func set_faction_id(value:int) -> void:
	faction_id = value
	# virutual function


func upgrade_unit(unit_identifier:int,upgrade_to_apply:int) -> void:
	var unit := GameState.get_unit(unit_identifier)
	var upgrade : UpgradeStaticData = StaticData.get_species(unit.species).upgrade_attributes_by_identifier_then_faction[upgrade_to_apply][faction_id]
	if not faction.current_currency >= upgrade.cost:
		return
	faction.current_currency -= upgrade.cost
	unit.apply_upgrade(upgrade_to_apply)
