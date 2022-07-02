extends Node

var units := []
var background_tiles : BackgroundTileData
var building_tiles : GameStateBuildingData
var elapsed_time : float = 0.0
var event_heap := EventHeap.new()


func _ready() -> void:
	set_process(false)


func _process(delta:float) -> void:
	elapsed_time += delta
	var elapsed_dict := event_heap.compare_top_dict_with_value(elapsed_time)
	if elapsed_dict != {}:
		_process_timed_out_event_dict(elapsed_dict)


func initialize_new_game() -> void:
	background_tiles = BackgroundTileData.new()
	building_tiles = GameStateBuildingData.new()


func restore(save_res:SavedGameState) -> void:
	units = save_res.units
	background_tiles = save_res.background_tiles
	building_tiles = save_res.building_tiles
	event_heap = save_res.event_heap
	elapsed_time = save_res.elapsed_time
	for u in units:
		var unit := u as SavedUnit
		# TODO: check if spawned, if so call UnitManager.spawn_unit()


func save() -> SavedGameState:
	var save_res := SavedGameState.new()
	save_res.background_tiles = background_tiles
	save_res.building_tiles = building_tiles
	save_res.event_heap = event_heap
	save_res.elapsed_time = elapsed_time
	save_res.units = _serialize_units()
	return save_res


func _serialize_units() -> Array: # sets and returns an array of SavedUnits
	_prune_unalive_and_unqueued_units_when_serializing()
	for u in units:
		var unit := u as SavedUnit
		unit.sync_data_from_manager()
	return units


func _prune_unalive_and_unqueued_units_when_serializing() -> void:
	pass


func _process_timed_out_event_dict(event:Dictionary) -> void:
	pass
