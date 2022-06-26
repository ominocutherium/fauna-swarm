extends Control


func _ready() -> void:
	pass # Replace with function body.


func _on_Start_pressed() -> void:
	get_tree().change_scene("res://main/Main.tscn")


func _on_Continue_pressed() -> void:
	get_tree().change_scene("res://main/Main.tscn")


func _on_Settings_pressed() -> void:
	$Settings.popup()


func _on_CreditsLegal_pressed() -> void:
	$Credits.popup()


func _on_Stats_pressed() -> void:
	$Statistics.popup()


func _on_Quit_pressed() -> void:
	get_tree().quit()
