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

class_name SpeciesStaticData

extends Resource

enum DamageTypes {MELEE,RANGED}
enum HitboxShape {CAPSULE,CIRCLE,RECTANGLE}

const STRING_ATTRIBUTES := [
	"name_key",
	"desc_short_key",
	"desc_key",
	"attack_name_key",
]
const INT_ATTRIBUTES := [
	"identifier",
	"income_number_of_units_given",
]
const REAL_ATTRIBUTES := [
	"attack_damage",
	"hb_radius",
	"attack_hb_len_or_radius_0",
	"attack_hb_len_or_radius_1",
	"attack_hb_offset",
	"move_speed",
	"maximum_health",
	"melee_damage_to_multiplier",
	"ranged_damage_to_multiplier",
	"attack_cooldown",
	"attack_delay",
	"income_selection_weight",
	"cooldown_before_income",
]
const FILTER_ATTRIBUTES := {
	"attack_damage_type":"ATTACK_DAMAGE_NAMES_TO_TYPES",
	"attack_hitbox_shape":"ATTACK_HITBOX_NAMES_TO_SHAPES",
}
const ATTACK_HITBOX_NAMES_TO_SHAPES := {
	"capsule":HitboxShape.CAPSULE,
	"circle":HitboxShape.CIRCLE,
	"rectangle":HitboxShape.RECTANGLE,
}
const ATTACK_DAMAGE_NAMES_TO_TYPES := {
	"melee":DamageTypes.MELEE,
	"ranged":DamageTypes.RANGED,
}


export(int) var identifier : int
export(String) var name_key : String
export(String) var desc_short_key : String
export(String) var desc_key : String
export(int) var attack_damage_type : int
export(float) var attack_damage : float
export(String) var attack_name_key : String
export(float) var hb_radius : float
export(int) var attack_hitbox_shape : int
export(float) var attack_hb_len_or_radius_0 : float
export(float) var attack_hb_len_or_radius_1 : float
export(float) var attack_hb_offset : float
export(float) var move_speed : float
export(float) var maximum_health : float
export(float) var melee_damage_to_multiplier : float = 1.0
export(float) var ranged_damage_to_multiplier : float = 1.0
export(float) var attack_cooldown : float = 1.0 # game balance parameter
export(float) var attack_delay : float = 0.001 # mainly an animation parameter
export(float) var income_selection_weight : float = 1.0 # i.e. how likely this species will be chosen relative to others for random income step
export(int) var income_number_of_units_given : int = 1 # i.e. how many at a time are given to the player when selected. Light units come in groups greater than 1, heavy units come alone.
export(float) var cooldown_before_income : float = 12.0
export(Dictionary) var upgrade_attributes_by_identifier_then_faction


func get_upgrade_attributes(upgrade_identifier:int,faction:int) -> Dictionary:
	if upgrade_attributes_by_identifier_then_faction.has(upgrade_identifier) and upgrade_attributes_by_identifier_then_faction[upgrade_identifier].has(faction):	
		return upgrade_attributes_by_identifier_then_faction[upgrade_identifier][faction]
	return {}
