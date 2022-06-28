extends Node

enum OrderTypes {HOLD_POS,ATTACK_POS,ATTACK_OBJ,CLAIM_OBJ,BUILD_OBJ,CAPTURE_OBJ} # attack position = attack-move. Capture must target a unit, not a position or building.
enum ObjTargetTypes {UNIT,BUILDING}


const UNIT_POOL_SIZE_INCREMENT = 30
const DEFAULT_UNIT_RADIUS = 12.0
const DEFAULT_OBSTACLE_LEN = 64.0


signal unit_moved(identifier,new_position)
signal unit_collided(identifier,coll_information)


var alive_unit_positions := PoolVector2Array()
var alive_unit_velocities := PoolVector2Array()
var alive_unit_distance_moved_since_vel_change_or_coll := PoolRealArray()
var alive_unit_path_ids := PoolIntArray()
var alive_unit_identifiers_to_idxs := {}
var alive_unit_body_rids := []
var alive_unit_shape_rids := []

var _unit_pool_size : int = 0
var _unit_pool_unused_idxs := []
var _alive_unit_identifiers := PoolIntArray()
var _space_rid : RID
var _obstacle_shape_rids := []
var _obstacle_body_rids := []
var obstacle_idxs_by_coords := {}

func _ready() -> void:
	_space_rid = Physics2DServer.space_create()


func _physics_process(delta: float) -> void:
	for i in range(_unit_pool_size):
		if _alive_unit_identifiers[i] == -1:
			continue
		var tf := Transform2D()
		tf.origin = alive_unit_positions[i]
		var test_movement := Physics2DTestMotionResult.new()
		var collided := Physics2DServer.body_test_motion(alive_unit_body_rids[i],tf,alive_unit_velocities[i]*delta,true,0.08,test_movement)
		if not collided:
			tf.origin += alive_unit_velocities[i] * delta
			alive_unit_distance_moved_since_vel_change_or_coll[i] = alive_unit_distance_moved_since_vel_change_or_coll[i] + (alive_unit_velocities[i] * delta).length()
			# TODO: check if done following current point of path, and change velocity if so
		else:
			tf.origin += test_movement.motion
			alive_unit_distance_moved_since_vel_change_or_coll[i] = 0.0
		alive_unit_positions[i] = tf.origin
		Physics2DServer.body_set_state(alive_unit_body_rids[i],Physics2DServer.BODY_STATE_TRANSFORM,tf)
		if collided:
			emit_signal("unit_collided",_alive_unit_identifiers[i],test_movement)
			if test_movement.motion.length_squared() > 0.0:
				emit_signal("unit_moved",_alive_unit_identifiers[i],tf.origin)
		elif alive_unit_velocities[i].length_squared() > 0.0:
			emit_signal("unit_moved",_alive_unit_identifiers[i],tf.origin)


func spawn_unit(identifier:int,where:Vector2) -> void:
	var idx := _get_unused_unit_pool_idx()
	alive_unit_identifiers_to_idxs[identifier] = idx
	_alive_unit_identifiers[idx] = identifier
	var body := Physics2DServer.body_create()
	Physics2DServer.body_set_space(body,_space_rid)
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
	alive_unit_velocities[idx] = Vector2(0,-20)
	alive_unit_distance_moved_since_vel_change_or_coll[idx] = 0.0


func despawn_unit(identifier:int) -> void:
	var idx : int = alive_unit_identifiers_to_idxs[identifier]
	alive_unit_identifiers_to_idxs.erase(identifier)
	_alive_unit_identifiers[idx] = -1
	_unit_pool_unused_idxs.append(idx)
	Physics2DServer.body_remove_shape(alive_unit_body_rids[idx],0)
	Physics2DServer.free_rid(alive_unit_shape_rids[idx])
	Physics2DServer.free_rid(alive_unit_body_rids[idx])
	alive_unit_body_rids[idx] = null
	alive_unit_shape_rids[idx] = null


func spawn_obstacle(where_coords:Vector2) -> void:
	obstacle_idxs_by_coords[where_coords] = _obstacle_body_rids.size()
	var body := Physics2DServer.body_create()
	Physics2DServer.body_set_space(body,_space_rid)
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
	obstacle_idxs_by_coords.erase(where_coords)
	Physics2DServer.body_remove_shape(_obstacle_body_rids[idx],0)
	Physics2DServer.free_rid(_obstacle_shape_rids[idx])
	Physics2DServer.free_rid(_obstacle_body_rids[idx])
	_obstacle_body_rids[idx] = null
	_obstacle_shape_rids[idx] = null


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
	alive_unit_body_rids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	alive_unit_shape_rids.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	_alive_unit_identifiers.resize(UNIT_POOL_SIZE_INCREMENT+starting_idx)
	for i in range(starting_idx,starting_idx+UNIT_POOL_SIZE_INCREMENT):
		_alive_unit_identifiers[i] = -1
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
