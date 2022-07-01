extends Resource

class_name SavedUnit

enum Status {SPAWNED,IN_BUILDING_QUEUE,WAITING_FOR_QUEUE}

export(int) var order_type : int # UnitManager.OrderTypes
export(int) var order_target_type : int # UnitManager.ObjTargetTypes
export(int) var order_target_identifier : int # for obj targets
export(Vector2) var order_target_point : Vector2
export(Vector2) var position : Vector2
export(Vector2) var velocity : Vector2
export(float) var current_health
export(int) var identifier
export(int) var species
export(int) var faction
export(int) var spawn_status
export(int) var upgrade_type = -1
export(int) var upgrade_faction = -1

var maximum_health : float setget ,get_maximum_health


func sync_data_from_manager() -> void:
	# Queries UnitManager singleton for updated position data, if alive.
	pass


func get_maximum_health() -> float:
	return 1.0
