extends Node2D


func _ready() -> void:
	get_tree().paused = true


func _process(delta: float) -> void:
	pass


func set_map_data(map_data_variant) -> void:
	# Implement during Step 8 on roadmap
	pass


func initialize_or_restore_map_state(map_state_variant) -> void:
	# Implement during Step 3 on roadmap
	pass
	get_tree().paused = false


func _on_MouseInput_location_left_clicked(location) -> void:
	print("{0} on map left clicked".format([location]))


func _on_MouseInput_location_right_clicked(location) -> void:
	print("{0} on map right clicked".format([location]))


func _on_MouseInput_rect_released(selection_rect) -> void:
	print("{0} selection finished".format([selection_rect]))


func _on_MouseInput_rect_updated(selection_rect) -> void:
	print("{0} selection in progress".format([selection_rect]))

