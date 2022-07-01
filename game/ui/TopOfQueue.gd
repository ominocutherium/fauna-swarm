extends Control

signal request_top_queue_cancel

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and !event.pressed:
		emit_signal("request_top_queue_cancel")
