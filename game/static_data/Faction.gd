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

class_name FactionStaticData

extends Resource

enum FactionTypes {PURE,EVIL}

const STRING_ATTRIBUTES := [
	"name_key",
	"engine_key",
]
const INT_ATTRIBUTES := [
	"income_amount",
	"income_amount_maximum_multiplier",
]
const REAL_ATTRIBUTES := [
	"income_cooldown",
]
const FILTER_ATTRIBUTES := {
	"faction_type":"FACTION_TYPES_TO_ENUM",
}
const FACTION_TYPES_TO_ENUM := {
	"pure":FactionTypes.PURE,
	"evil":FactionTypes.EVIL
}


const FACTION_IDS_BY_NAME = {
	"purity" : 1,
	"specter" : 2,
	"sanguine" : 3,
	"artifice" : 4,
	"pestilence" : 5,
}

export(int) var identifier : int
export(FactionTypes) var faction_type : int
export(String) var name_key : String
export(String) var engine_key : String
export(Array) var unit_bonuses : Array = []
export(float) var income_cooldown : float = 20.0
export(int) var income_amount : int = 15
export(float) var income_amount_maximum_multiplier : float = 5.0

var bonuses_by_species := {}


func get_bonuses_by_species(species:int) -> Array:
	return []


func _index_bonuses_by_species() -> void:
	pass
