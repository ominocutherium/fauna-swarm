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


const BLANK_HITBOX_ACTIVE_DICT = {
	timeout_s=0.0,
	cooldown_s=0.0,
	callback_obj=null,
	callback="_hitbox_expired",
	rid=null,
}


var _space_rid : RID

var _active_hitbox_rids := {}
var _hbs_to_spawn_next_physics_frame := []


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	for unit_identifier in UnitManager.units_with_a_target_in_range:
		# check orders and able to attack status, spawn hitboxes or progress orders if needed
		pass


func _try_to_get_space_rid() -> void:
	if not UnitManager.has_created_space_rid:
		call_deferred("_try_to_get_space_rid")
	else:
		_space_rid = UnitManager.space_rid


func _build_order_should_commence(unit_in_range:int) -> void:
	pass


func spawn_hitbox(attacker:SavedUnit,target_position:Vector2) -> RID:
	var area_rid := Physics2DServer.area_create()
	var hitbox_expiration : Dictionary = BLANK_HITBOX_ACTIVE_DICT.duplicate()
	hitbox_expiration.rid = area_rid
	hitbox_expiration.callback_obj = self
	_active_hitbox_rids[area_rid] = hitbox_expiration
	# TODO: set timeout and cooldown
	GameState.event_heap.push_dict_onto_heap(hitbox_expiration)
	return area_rid


func remove_hitbox(area_rid:RID) -> void:
	Physics2DServer.free_rid(area_rid)
	pass


func _hitbox_collection_callback(attacker:SavedUnit,params) -> void:
	var attacked
	if attacked is SavedUnit:
		# TODO: use params
		attacked.take_damage()
	elif attacked is SavedBuilding:
		# TODO: use params
		attacked.take_damage()


func _hitbox_expired(dict:Dictionary) -> void:
	if dict.has("rid") and dict.rid in _active_hitbox_rids:
		# TODO: despawn
		_active_hitbox_rids.erase(dict.rid)
