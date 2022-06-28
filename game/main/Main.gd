extends Node2D


func _ready() -> void:
	get_tree().paused = true
	if GameState.building_tiles != null:
		initialize_or_restore_map_state()


func _process(delta: float) -> void:
	pass


func initialize_or_restore_map_state() -> void:
	GameState.background_tiles.apply_to_tilemap($"Background Tiles")
	GameState.building_tiles.apply_to_tilemap($"Building Tiles")
	get_tree().paused = false


func _on_MouseInput_location_left_clicked(location) -> void:
	print("{0} on map left clicked".format([location]))


func _on_MouseInput_location_right_clicked(location) -> void:
	print("{0} on map right clicked".format([location]))


func _on_MouseInput_rect_released(selection_rect) -> void:
	print("{0} selection finished".format([selection_rect]))


func _on_MouseInput_rect_updated(selection_rect) -> void:
	print("{0} selection in progress".format([selection_rect]))

