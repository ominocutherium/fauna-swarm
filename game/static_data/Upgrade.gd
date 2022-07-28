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

class_name UpgradeStaticData

const STRING_ATTRIBUTES := [
	"modified_attr_0",
	"modified_attr_1",
	"modified_attr_2",
	"faction",
	"species_name_key",
	"desc_key",
	"faction_name",
]
const VARIANT_ATTRIBUTES := [
	"modified_value_0",
	"modified_value_1",
	"modified_value_2",
]
const INT_ATTRIBUTES := [
	"upgrade_identifier",
]
const REAL_ATTRIBUTES := [
	"cost",
]
const FILTER_ATTRIBUTES := {}

var identifier : int = -1
var modified_attr_0 : String
var modified_attr_1 : String
var modified_attr_2 : String
var modified_value_0
var modified_value_1
var modified_value_2
var cost : float = 100.0
var upgrade_identifier : int
var species_name_key : String
var desc_key : String
var faction_name : String
