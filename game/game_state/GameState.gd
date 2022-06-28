extends Node

var units := []
var background_tiles : BackgroundTileData
var building_tiles : GameStateBuildingData


func restore(save_res:SavedGameState) -> void:
	units = save_res.units
	background_tiles = save_res.background_tiles
	building_tiles = save_res.building_tiles
	for u in units:
		var unit := u as SavedUnit
		# TODO: check if spawned, if so call UnitManager.spawn_unit()


func save() -> SavedGameState:
	var save_res := SavedGameState.new()
	save_res.background_tiles = background_tiles
	save_res.building_tiles = building_tiles
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
