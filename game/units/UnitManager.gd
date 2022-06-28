extends Node

enum OrderTypes {HOLD_POS,ATTACK_POS,ATTACK_OBJ,CLAIM_OBJ,BUILD_OBJ,CAPTURE_OBJ} # attack position = attack-move. Capture must target a unit, not a position or building.
enum ObjTargetTypes {UNIT,BUILDING}


var alive_unit_positions := PoolVector2Array()
var alive_unit_velocities := PoolVector2Array()
var alive_unit_distance_moved_since_vel_change_or_coll := PoolVector2Array()
var alive_unit_path_ids := PoolIntArray()
var alive_unit_identifiers_to_idxs := {}


func _physics_process(delta: float) -> void:
	pass


func spawn_unit(identifier:int,where:PoolVector2Array) -> void:
	pass


func despawn_unit(identifier:int) -> void:
	pass

