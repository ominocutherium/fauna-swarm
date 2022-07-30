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

enum OrderTypes {HOLD_POS,MOVE_TO_POS,ATTACK_POS,ATTACK_OBJ,CLAIM_OBJ,BUILD_OBJ,CAPTURE_OBJ,HEAL} # attack position = attack-move. Capture must target a unit, not a position or building.
enum ObjTargetTypes {UNIT,BUILDING}


const TILE_LEN = 64.0
const TILE_LEN_INV = 1.0 / TILE_LEN # to avoid divide operation during runtime
const UNIT_POOL_SIZE_INCREMENT = 30
const DEFAULT_UNIT_RADIUS = 12.0
const ENEMY_DETECTION_RANGE = 400.0
const DEFAULT_OBSTACLE_LEN = TILE_LEN
const NUM_QUADRANTS_X = 25
const NUM_QUADRANTS_Y = 25
const QUANDRANT_LEN = 4 * TILE_LEN
const QUADRANT_LEN_INV = 1.0 / QUANDRANT_LEN # to avoid divide operation during runtime
const FIRST_QUADRANT_START_POS = Vector2(-50,-50)*TILE_LEN


signal unit_moved(identifier,new_position)
signal unit_collided(identifier,coll_information)
signal unit_needs_order_reset(identifier)


var alive_unit_positions := PoolVector2Array()
var alive_unit_velocities := PoolVector2Array()
var alive_unit_distance_moved_since_vel_change_or_coll := PoolRealArray()
var alive_unit_path_ids := PoolIntArray()
var alive_unit_path_point_ids := PoolIntArray()
var alive_unit_identifiers := PoolIntArray()
var alive_unit_identifiers_to_idxs := {}
var alive_unit_body_rids := []
var alive_unit_shape_rids := []
var alive_unit_factions := PoolIntArray()
var units_with_a_target_in_range := {} # hitbox manager should query this every physics frame for units with a cooldown. Keep this clean.

var _unit_pool_size : int = 0
var _unit_pool_unused_idxs := []
var _path_pool_size : int = 0
var _path_pool_unused_idxs := []
var _unit_paths := []
var space_rid : RID
var has_created_space_rid : bool = false
var _obstacle_shape_rids := []
var _obstacle_body_rids := []
var obstacle_idxs_by_coords := {}
var _lists_of_unit_idxs_from_quadrant := {}
var _units_with_temporary_targets := {} # unit_id : id_of_temporary_target (unit identifier : int); -1 means no temp target and follow the path
var _units_with_position_targets := {} # unit_identifier : targeted position (Vector2)
var _units_with_unit_targets := {} # unit_identifier : targeted unit identifier (int)
var _unit_target_ranges := {}
var _unit_groups_needing_paths := []
var _units_needing_orders_resolved := []
var _unit_arr_to_calc_path_for := []
var _units_targeting_unit := {}
var _units_last_direction_moved := {}


class UnitPath:
	extends Reference
	var points := PoolVector2Array() setget set_points
	var distances_between_points := PoolRealArray()
	var units_following_path_precisely := {}

	var _dir_to_next_point : Vector2
	var _last_added_point_idx : int = -1


	func set_unit_following_path(unit_identifier:int) -> void:
		if not units_following_path_precisely.has(unit_identifier):
			units_following_path_precisely[unit_identifier] = false


	func set_unit_following_path_precisely(unit_identifier:int) -> void:
		units_following_path_precisely[unit_identifier] = true


	func is_unit_following_path_precisely(unit_identifier:int) -> bool:
		if not units_following_path_precisely.has(unit_identifier):
			return false
		return units_following_path_precisely[unit_identifier]


	func set_points(p_points:PoolVector2Array) -> void:
		# simplifies the path to only add uniquely needed points (i.e. detect and purge points on existing segments)
		if points.size() != 0:
			return
		for i in range(p_points.size()):
			if i == 0:
				_add_point(p_points[i])
			elif i == 1:
				_dir_to_next_point = (p_points[i] - points[0]).normalized()
				continue
			elif i == p_points.size() - 1:
				if (p_points[i] - p_points[i-1]).normalized().dot(_dir_to_next_point) < 0.99:
					# add both
					for j in range(i-1,i+1):
						_add_point(p_points[j])
				else:
					# add just the last point
					_add_point(p_points[i])
			elif (p_points[i] - points[_last_added_point_idx]).normalized().dot(_dir_to_next_point) < 0.99:
				_add_point(p_points[i-1])


	func _add_point(point_to_add:Vector2) -> void:
		_last_added_point_idx += 1
		points.append(point_to_add)
		if _last_added_point_idx > 0:
			var difference : Vector2 = points[_last_added_point_idx] - points[_last_added_point_idx-1]
			_dir_to_next_point = difference.normalized()
			distances_between_points.append(difference.length())


func _ready() -> void:
	space_rid = Physics2DServer.space_create()
	has_created_space_rid = true
	for j in range(NUM_QUADRANTS_Y):
		for i in range(NUM_QUADRANTS_X):
			_lists_of_unit_idxs_from_quadrant[Vector2(i,j)] = []


func _physics_process(delta: float) -> void:
	for i in range(_unit_pool_size):
		if alive_unit_identifiers[i] == -1:
			continue
		if _units_with_temporary_targets.has(i):
			if _units_with_temporary_targets[i] < 0:
				var perceived_enemy : int = _unit_sees_enemy_nearby(i)
				if perceived_enemy >= 0:
					_units_with_temporary_targets[i] = perceived_enemy
				if alive_unit_path_ids[i] == -1:
					alive_unit_velocities[i] = Vector2()
				# TODO: go back to following the path
			if _units_with_temporary_targets[i] >= 0: # almost an else block, except this block should execute if a new temp target was *just* found.
				if units_with_a_target_in_range.has(alive_unit_identifiers[i]):
					alive_unit_velocities[i] = Vector2()
				else:
					var difference : Vector2 = alive_unit_positions[_units_with_temporary_targets[i]] - alive_unit_positions[i]
					if difference.dot(alive_unit_velocities[i]) < 0.99:
						alive_unit_velocities[i] = difference.normalized() * GameState.get_unit(alive_unit_identifiers[i]).get_move_speed()
		var tf := Transform2D()
		tf.origin = alive_unit_positions[i]
		var last_quadrant : Vector2 = _get_quadrant_from_pos(tf.origin)
		var test_movement := Physics2DTestMotionResult.new()
		var collided := Physics2DServer.body_test_motion(alive_unit_body_rids[i],tf,alive_unit_velocities[i]*delta,true,0.08,test_movement)
		if not collided:
			tf.origin += alive_unit_velocities[i] * delta
			alive_unit_distance_moved_since_vel_change_or_coll[i] = alive_unit_distance_moved_since_vel_change_or_coll[i] + (alive_unit_velocities[i] * delta).length()
			_units_last_direction_moved[i] = alive_unit_velocities[i].normalized()
			if alive_unit_path_ids[i] != -1:
				var path : UnitPath = _unit_paths[alive_unit_path_ids[i]]
				if (path.units_following_path_precisely.has(i) and (path.points[alive_unit_path_point_ids[i]]-alive_unit_positions[i]).length_squared() < 2.0) \
						or alive_unit_distance_moved_since_vel_change_or_coll[i] >= path.distances_between_points[alive_unit_path_point_ids[i]]:
					alive_unit_path_point_ids[i] = alive_unit_path_point_ids[i] + 1
					if alive_unit_path_point_ids[i] >= path.points.size():
						alive_unit_path_ids[i] = -1
						alive_unit_velocities[i] = Vector2()
					if i in path.units_following_path_precisely:
						alive_unit_velocities[i] = (path.points[alive_unit_path_point_ids[i]] - alive_unit_positions[i]).normalized() * GameState.get_unit(alive_unit_identifiers[i]).get_move_speed()
					else:
						alive_unit_velocities[i] = (path.points[alive_unit_path_point_ids[i]] - path.points[alive_unit_path_point_ids[i-1]]).normalized() * GameState.get_unit(alive_unit_identifiers[i]).get_move_speed()
		else:
			tf.origin += test_movement.motion
			alive_unit_distance_moved_since_vel_change_or_coll[i] = 0.0
			if alive_unit_path_ids[i] != -1:
				var path : UnitPath = _unit_paths[alive_unit_path_ids[i]]
				path.units_following_path_precisely[i] = true
				alive_unit_velocities[i] = (path.points[alive_unit_path_point_ids[i]] - alive_unit_positions[i]).normalized() * GameState.get_unit(alive_unit_identifiers[i]).get_move_speed()
			if test_movement.motion != Vector2():
				_units_last_direction_moved[i] = test_movement.motion.normalized()
		alive_unit_positions[i] = tf.origin
		var next_quadrant := _get_quadrant_from_pos(tf.origin)
		if last_quadrant != next_quadrant:
			if i in _lists_of_unit_idxs_from_quadrant[last_quadrant]:
				_lists_of_unit_idxs_from_quadrant[last_quadrant].erase(i)
			_lists_of_unit_idxs_from_quadrant[next_quadrant].append(i)
		Physics2DServer.body_set_state(alive_unit_body_rids[i],Physics2DServer.BODY_STATE_TRANSFORM,tf)
		if collided:
			emit_signal("unit_collided",alive_unit_identifiers[i],test_movement)
			if test_movement.motion.length_squared() > 0.0:
				emit_signal("unit_moved",alive_unit_identifiers[i],tf.origin)
		elif alive_unit_velocities[i].length_squared() > 0.0:
			emit_signal("unit_moved",alive_unit_identifiers[i],tf.origin)
	for unit_id in _unit_target_ranges:
		if (not _units_with_position_targets.has(unit_id) and not _units_with_unit_targets.has(unit_id)) or (
				_units_with_temporary_targets.has(unit_id) and _units_with_temporary_targets[unit_id] < 0):
				# only check for a target in range for units attempting to attack something
			if units_with_a_target_in_range.has(unit_id):
				units_with_a_target_in_range.erase(unit_id)
			continue
		var target_in_range : bool = _units_target_in_range(unit_id)
		if target_in_range:
			units_with_a_target_in_range[unit_id] = true
		elif units_with_a_target_in_range.has(unit_id):
			units_with_a_target_in_range.erase(unit_id)


func _process(_delta: float) -> void:
	if _unit_arr_to_calc_path_for.size() > 0:
		_assign_path_to_targeted_for_group(_unit_arr_to_calc_path_for)
		_unit_arr_to_calc_path_for = []
	elif _unit_groups_needing_paths.size() > 0:
		var prelim_arr : Array = _unit_groups_needing_paths.pop_front()
		var arr_of_arrs := _get_unit_sub_groups_for_pathing_by_proximity(prelim_arr)
		if arr_of_arrs.size() > 0:
			_unit_arr_to_calc_path_for = arr_of_arrs.pop_front()
		if arr_of_arrs.size() > 1:
			arr_of_arrs.append_array(_unit_groups_needing_paths)
			_unit_groups_needing_paths = arr_of_arrs
	elif _units_needing_orders_resolved.size() > 0:
		for id in _units_needing_orders_resolved:
			_resolve_unit_order(id)
		_units_needing_orders_resolved = []


func spawn_unit(identifier:int,where:Vector2) -> void:
	var idx := _get_unused_unit_pool_idx()
	alive_unit_identifiers_to_idxs[identifier] = idx
	alive_unit_identifiers[idx] = identifier
	alive_unit_factions[idx] = GameState.get_unit(identifier).faction # TODO use this to set coll layer and mask
	var body := Physics2DServer.body_create()
	Physics2DServer.body_set_space(body,space_rid)
	Physics2DServer.body_set_mode(body,Physics2DServer.BODY_MODE_KINEMATIC)
	alive_unit_body_rids[idx] = body
	var shape := _get_unit_collshape_from_static_data(identifier)
	alive_unit_shape_rids[idx] = shape
	Physics2DServer.body_add_shape(body,shape,Transform2D())
	var coll_and_mask := _get_coll_layer_and_mask_from_runtime_data(identifier)
	Physics2DServer.body_set_collision_layer(body,coll_and_mask[0])
	Physics2DServer.body_set_collision_mask(body,coll_and_mask[1])
	var tf := Transform2D()
	tf.origin = where
	alive_unit_positions[idx] = where
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_TRANSFORM,tf)
	alive_unit_velocities[idx] = Vector2()
	alive_unit_distance_moved_since_vel_change_or_coll[idx] = 0.0
	var quad := _get_quadrant_from_pos(where)
	_lists_of_unit_idxs_from_quadrant[quad].append(idx)


func despawn_unit(identifier:int) -> void:
	if not identifier in alive_unit_identifiers_to_idxs:
		return
	var idx : int = alive_unit_identifiers_to_idxs[identifier]
	var quad := _get_quadrant_from_pos(alive_unit_positions[idx])
	if _lists_of_unit_idxs_from_quadrant[quad].has(idx):
		_lists_of_unit_idxs_from_quadrant[quad].erase(idx)
# warning-ignore:return_value_discarded
	alive_unit_identifiers_to_idxs.erase(identifier)
	alive_unit_identifiers[idx] = -1
	_unit_pool_unused_idxs.append(idx)
	Physics2DServer.body_remove_shape(alive_unit_body_rids[idx],0)
	Physics2DServer.free_rid(alive_unit_shape_rids[idx])
	Physics2DServer.free_rid(alive_unit_body_rids[idx])
	alive_unit_body_rids[idx] = null
	alive_unit_shape_rids[idx] = null
	if _units_targeting_unit.has(identifier):
		for id in _units_targeting_unit[identifier]:
			if _units_with_unit_targets.has(id) and _units_with_unit_targets[id] == identifier:
				emit_signal("unit_needs_order_reset",id)
			elif _units_with_temporary_targets.has(id):
				_units_with_temporary_targets[id] = -1
		_units_targeting_unit.erase(identifier)


func spawn_obstacle(where_coords:Vector2) -> void:
	obstacle_idxs_by_coords[where_coords] = _obstacle_body_rids.size()
	var body := Physics2DServer.body_create()
	Physics2DServer.body_set_space(body,space_rid)
	Physics2DServer.body_set_mode(body,Physics2DServer.BODY_MODE_STATIC)
	_obstacle_body_rids.append(body)
	var shape := _get_obstacle_collshape()
	_obstacle_shape_rids.append(shape)
	Physics2DServer.body_add_shape(body,shape)
	var coll_and_mask := _get_coll_layer_and_mask_for_obstacles()
	Physics2DServer.body_set_collision_layer(body,coll_and_mask[0])
	Physics2DServer.body_set_collision_mask(body,coll_and_mask[1])
	var tf := Transform2D()
	tf.origin = (where_coords * Vector2(1,1) + Vector2(0.5,0.5)) * DEFAULT_OBSTACLE_LEN
	Physics2DServer.body_set_state(body,Physics2DServer.BODY_STATE_TRANSFORM,tf)


func despawn_obstacle(where_coords:Vector2) -> void:
	if not obstacle_idxs_by_coords.has(where_coords):
		return
	var idx : int = obstacle_idxs_by_coords[where_coords]
# warning-ignore:return_value_discarded
	obstacle_idxs_by_coords.erase(where_coords)
	Physics2DServer.body_remove_shape(_obstacle_body_rids[idx],0)
	Physics2DServer.free_rid(_obstacle_shape_rids[idx])
	Physics2DServer.free_rid(_obstacle_body_rids[idx])
	_obstacle_body_rids[idx] = null
	_obstacle_shape_rids[idx] = null


func get_units_inside_selection(space_to_check:Rect2,selection_diamond_midpoints:Array,selection_diamond_normals:Array) -> Array:
	var first_quadrant := _get_quadrant_from_pos(space_to_check.position)
	var last_quadrant := _get_quadrant_from_pos(space_to_check.end)
	var arr_of_units := [] # identifiers not indices
	for i in range(int(first_quadrant.x),int(last_quadrant.x)):
		for j in range(int(first_quadrant.y),int(last_quadrant.y)):
			for unit_idx in _lists_of_unit_idxs_from_quadrant[Vector2(i,j)]:
				if _position_inside_selection_diamond(alive_unit_positions[unit_idx],selection_diamond_midpoints,selection_diamond_normals):
					arr_of_units.append(alive_unit_identifiers[unit_idx])
	return arr_of_units


func get_closest_unit_to_position_within_radius(position:Vector2,sel_radius:float,_sel_radius_sq:float) -> int:
	var quadrants_to_check := [_get_quadrant_from_pos(position)]
	for offset_by_radius_pos in [
		position + Vector2(1,0)*sel_radius,
		position + Vector2(-1,0)*sel_radius,
		position + Vector2(0,1)*sel_radius,
		position + Vector2(0,-1)*sel_radius,
		position + Vector2(1,1)*sel_radius,
		position + Vector2(-1,-1)*sel_radius,
		position + Vector2(-1,1)*sel_radius,
		position + Vector2(1,-1)*sel_radius,
	]:
		var q := _get_quadrant_from_pos(offset_by_radius_pos)
		if not q in quadrants_to_check:
			quadrants_to_check.append(q)
	var shortest_distance_sq : float = -1.0
	var return_unit_idx : int = -1
	for quadrant in quadrants_to_check:
		if not _lists_of_unit_idxs_from_quadrant.has(quadrant):
			continue
		for unit_idx in _lists_of_unit_idxs_from_quadrant[quadrant]:
			var dist := position.distance_squared_to(alive_unit_positions[unit_idx])
			if shortest_distance_sq < 0.0 or dist < shortest_distance_sq:
				return_unit_idx = unit_idx
	# if no unit is nearby, return -1
	return alive_unit_identifiers[return_unit_idx] if return_unit_idx >= 0 else -1


func mark_unit_as_needing_order_resolution(unit_identifier:int) -> void:
	if not unit_identifier in alive_unit_identifiers:
		return
	_units_needing_orders_resolved.append(unit_identifier)


func mark_units_as_needing_path(arr_of_ids:Array) -> void:
	_unit_groups_needing_paths.append(arr_of_ids)


func _get_unused_unit_pool_idx() -> int:
	if _unit_pool_unused_idxs.size() == 0:
		_increase_unit_pool_size()
	return _unit_pool_unused_idxs.pop_front()


func _increase_unit_pool_size() -> void:
	var starting_idx := _unit_pool_size
	alive_unit_positions.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_velocities.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_distance_moved_since_vel_change_or_coll.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_path_ids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_path_point_ids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_body_rids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_shape_rids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_identifiers.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_factions.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	for i in range(starting_idx,starting_idx+UNIT_POOL_SIZE_INCREMENT):
		alive_unit_identifiers[i] = -1
		alive_unit_path_ids[i] = -1
		_unit_pool_unused_idxs.append(i)
	_unit_pool_size += UNIT_POOL_SIZE_INCREMENT


func _get_unit_collshape_from_static_data(_identifier:int) -> RID:
	var shape := Physics2DServer.circle_shape_create()
	Physics2DServer.shape_set_data(shape,DEFAULT_UNIT_RADIUS)
	return shape


func _get_obstacle_collshape() -> RID:
	var shape := Physics2DServer.rectangle_shape_create()
	Physics2DServer.shape_set_data(shape,Vector2(1,1)*DEFAULT_OBSTACLE_LEN)
	return shape


func _get_coll_layer_and_mask_from_runtime_data(_identifier:int) -> Array:
	# Units exist on the units layer but collide with obstacles (and units of other factions)
	# Pathfinding and cohesive moving is way simpler if units don't collide with units of their own faction,
	# but is probably bad for balance (encourages deathballs and makes chokepoints pointless)
	return [2,1]


func _get_coll_layer_and_mask_for_obstacles() -> Array:
	# Obstacles exist on the obstacles layer but don't collide with anything, including other obstacles
	return [1,0]


func _get_quadrant_from_pos(position:Vector2) -> Vector2:
	var float_quadrant = QUADRANT_LEN_INV * (position - FIRST_QUADRANT_START_POS) # avoiding division for performance
	return Vector2(floor(float_quadrant.x),floor(float_quadrant.y))


func _get_tile_from_pos(position:Vector2) -> Vector2:
	var float_tile = TILE_LEN_INV * position # avoiding division for performance
	# can't use TileMap.world_to_map because TileMap is in a completely different display space
	return Vector2(floor(float_tile.x),floor(float_tile.y))


func _position_inside_selection_diamond(position:Vector2,diamond_midpoints:Array,diamond_normals:Array) -> bool:
	for i in range(4):
		if diamond_normals[i].dot((diamond_midpoints[i] - position).normalized()) <= 0:
			return false
	return true


func _get_unit_path(path_identifier:int) -> UnitPath:
	if path_identifier < _unit_paths.size():
		return _unit_paths[path_identifier]
	return null

const MAX_DIST_PER_PROXIMITY_TIER_FOR_UNITS_TO_BE_GROUPED = 72.0


func _get_unit_sub_groups_for_pathing_by_proximity(list_of_unit_identifiers:Array) -> Array:
	if list_of_unit_identifiers.size() == 0:
		# Exit recursive call
		return []
	var unit_position_sum : Vector2 = alive_unit_positions[list_of_unit_identifiers[0]]
	for i in range(1,list_of_unit_identifiers.size()):
		unit_position_sum += alive_unit_positions[list_of_unit_identifiers[i]]
	var unit_position_average := unit_position_sum / list_of_unit_identifiers.size()
	var max_distance_allowed : float = MAX_DIST_PER_PROXIMITY_TIER_FOR_UNITS_TO_BE_GROUPED * (1+_get_proximity_tier_by_num_of_units(list_of_unit_identifiers.size()))
	var main_group := []
	var other_group := []
	for i in range(list_of_unit_identifiers.size()):
		if (alive_unit_positions[list_of_unit_identifiers[i]] - unit_position_average).length() < max_distance_allowed:
			main_group.append(list_of_unit_identifiers[i])
		else:
			other_group.append(list_of_unit_identifiers[i])
	var return_arr := [main_group]
	return_arr.append_array(_get_unit_sub_groups_for_pathing_by_proximity(other_group))
	return return_arr


static func _get_proximity_tier_by_num_of_units(num_units:int) -> int:
	# inverse of the function d = 1 + 6 * ((n+1)*(n/2)) i.e. 3n^2 + 3n + 1 - d = 0
	# (formula of the radius from center tile for a "ball" in a hex grid with a certain number of tiles)
	# via quadratic function
	return int(ceil(((-3 + sqrt(9 - 4 * 3*(1-num_units)))/6)))


func _assign_path_to_targeted_for_group(arr_of_unit_identifiers:Array) -> void:
	var position_sum := Vector2()
	var group_size : int = arr_of_unit_identifiers.size()
	var idxs_to_assign_to_path := []
	var end_pos_assigned : bool = false
	var end_pos : Vector2  # TODO: assign. Does not work yet.
	for identifier in arr_of_unit_identifiers:
		if not identifier in alive_unit_identifiers_to_idxs:
			# Did the unit get defeated while it was in a group waiting for a path?
			group_size -= 1
			if group_size == 0:
				return
			continue
		var idx : int = alive_unit_identifiers_to_idxs[identifier]
		position_sum += alive_unit_positions[idx]
		idxs_to_assign_to_path.append(idx)
		if not end_pos_assigned:
			if identifier in _units_with_position_targets:
				end_pos = _units_with_position_targets[identifier]
				end_pos_assigned = true
			elif identifier in _units_with_unit_targets:
				var targeted_unit_idx : int = alive_unit_identifiers_to_idxs[_units_with_unit_targets[identifier]]
				end_pos = alive_unit_positions[targeted_unit_idx]
				end_pos_assigned = true
	if not end_pos_assigned:
		return
	var average_position : Vector2 = position_sum / float(group_size)
	var path := UnitPath.new()
	path.points = Pathfinding.get_path_with_current_params(average_position,end_pos,-1,false) # FIXME: Will work once end pos is correct (and makes all units with each other regardless of faction) but please rewrite
	if path.points.size() == 0:
		return
	var path_idx : int = _path_pool_unused_idxs.pop_front() if _path_pool_unused_idxs.size() > 0 else _path_pool_size
	if path_idx == _path_pool_size:
		_path_pool_size += 1
		_unit_paths.resize(_path_pool_size)
	_unit_paths[path_idx] = path
	for unit_idx in idxs_to_assign_to_path:
		alive_unit_path_ids[unit_idx] = path_idx
		alive_unit_path_point_ids[unit_idx] = 0


func _resolve_unit_order(unit_identifier:int) -> void:
	var unit : SavedUnit = GameState.get_unit(unit_identifier)
	var idx : int = alive_unit_identifiers_to_idxs[unit_identifier]
	alive_unit_velocities[idx] = Vector2()
	if unit.order_type in [OrderTypes.ATTACK_OBJ,OrderTypes.CAPTURE_OBJ]:
		_set_units_unit_target(unit_identifier,unit.order_target_identifier)
	elif unit.order_type in [OrderTypes.ATTACK_POS,OrderTypes.BUILD_OBJ,OrderTypes.MOVE_TO_POS,OrderTypes.CLAIM_OBJ,OrderTypes.HEAL]:
		_units_with_position_targets[unit_identifier] = unit.order_target_point
	if unit.order_type in [OrderTypes.HOLD_POS,OrderTypes.ATTACK_POS]:
		_units_with_temporary_targets[idx] = -1
	else:
		if _units_with_temporary_targets.has(idx):
# warning-ignore:return_value_discarded
			_units_with_temporary_targets.erase(idx)
	if unit.order_type in [OrderTypes.ATTACK_OBJ,OrderTypes.CAPTURE_OBJ,OrderTypes.HOLD_POS,OrderTypes.ATTACK_POS] and not _unit_target_ranges.has(unit_identifier):
		_unit_target_ranges[unit_identifier] = GameState.get_unit(unit_identifier).get_maximum_range_of_attack()
#		units_with_a_target_in_range[unit_identifier] = false


func _units_target_in_range(id:int) -> bool:
	var idx : int = alive_unit_identifiers_to_idxs[id]
	if id in _units_with_temporary_targets and _units_with_temporary_targets[id] >= 0:
		var target_id : int = _units_with_temporary_targets[id]
		return (alive_unit_positions[alive_unit_identifiers_to_idxs[target_id]] - alive_unit_positions[idx]).length() < _unit_target_ranges[id]
	if id in _units_with_unit_targets:
		var target_id : int = _units_with_unit_targets[id]
		if target_id < 0:
			return false
		else:
			return (alive_unit_positions[alive_unit_identifiers_to_idxs[target_id]] - alive_unit_positions[idx]).length() < _unit_target_ranges[id]
	elif id in _units_with_position_targets:
		return (alive_unit_positions[idx] - _units_with_position_targets[id]).length() < _unit_target_ranges[id]
	return false


func _unit_sees_enemy_nearby(idx:int) -> int:
	var dir : Vector2 = _units_last_direction_moved[idx] if alive_unit_velocities[idx] == Vector2() else alive_unit_velocities[idx].normalized()
	var quads_to_scan := get_quadrants_in_units_enemy_detection_range(idx,dir)
	for quad in quads_to_scan:
		for other_unit_idx in _lists_of_unit_idxs_from_quadrant[quad]:
			if alive_unit_factions[idx] != alive_unit_factions[other_unit_idx] and dir.dot((alive_unit_positions[other_unit_idx]-alive_unit_positions[idx]).normalized()) > 0.0:
				# TODO: add a ray cast check here to make sure unit does not get stuck on an obstacle.
				return alive_unit_identifiers[other_unit_idx]
	return -1


func _on_unit_order_set(_a,_b,_c,unit_identifier:int) -> void:
	_units_needing_orders_resolved.append(unit_identifier)


func _set_units_unit_target(targeting_unit_id:int,targeted_unit_id:int,temporary:bool=false) -> void:
	# remove bookkeeping for old target
	var old_target_id : int = -1
	if _units_with_unit_targets.has(targeting_unit_id):
		old_target_id = _units_with_unit_targets[targeting_unit_id]
	elif _units_with_temporary_targets.has(targeting_unit_id):
		old_target_id = _units_with_temporary_targets[targeting_unit_id]
	if old_target_id >= 0:
		if _units_targeting_unit.has(old_target_id) and _units_targeting_unit[old_target_id] as Array and _units_targeting_unit[old_target_id].has(targeting_unit_id):
			_units_targeting_unit[old_target_id].erase(targeting_unit_id)

	# add new target and add bookkeeping for new target
	if temporary:
		_units_with_temporary_targets[targeting_unit_id] = targeted_unit_id
	else:
		_units_with_unit_targets[targeting_unit_id] = targeted_unit_id
	if not _units_targeting_unit.has(targeted_unit_id):
		_units_targeting_unit[targeted_unit_id] = []
	_units_targeting_unit[targeted_unit_id].append(targeting_unit_id)


func get_quadrants_in_units_enemy_detection_range(unit_idx:int,dir:Vector2) -> Array:
	var end_of_range : Vector2 = alive_unit_positions[unit_idx] + dir * ENEMY_DETECTION_RANGE
	var quads := []
	var top_left := Vector2()
	var bottom_right := Vector2()
	top_left.x = alive_unit_positions[unit_idx].x if alive_unit_positions[unit_idx].x < end_of_range.x else end_of_range.x
	top_left.y = alive_unit_positions[unit_idx].y if alive_unit_positions[unit_idx].y < end_of_range.y else end_of_range.y
	bottom_right.x = alive_unit_positions[unit_idx].x if alive_unit_positions[unit_idx].x > end_of_range.x else end_of_range.x
	bottom_right.y = alive_unit_positions[unit_idx].y if alive_unit_positions[unit_idx].y > end_of_range.y else end_of_range.y
	var top_left_quad := _get_quadrant_from_pos(top_left)
	var bottom_right_quad := _get_quadrant_from_pos(bottom_right)
	for i in range(int(top_left_quad.x),int(bottom_right_quad.x)+1):
		for j in range(int(top_left_quad.y),int(bottom_right_quad.y)+1):
			if not Vector2(i,j) in quads:
				quads.append(Vector2(i,j))
	return quads
