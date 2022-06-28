extends Control

const SAVE_FILE_PATH = "user://saved_game.tres"


func _ready() -> void:
	pass # Replace with function body.
	if _detect_if_save_file():
		$Buttons/VBoxContainer/Continue.show()
		$Buttons/VBoxContainer/Start.hide()
	else:
		$Buttons/VBoxContainer/Continue.hide()
		$Buttons/VBoxContainer/Start.show()


func _on_Start_pressed() -> void:
	GameState.initialize_new_game()
	get_tree().change_scene("res://main/Main.tscn")


func _on_Continue_pressed() -> void:
	var s := _load_if_save_file()
	if s == null:
		$SaveLoadError.popup()
	else:
		GameState.restore(s)
		get_tree().change_scene("res://main/Main.tscn")


func _on_Settings_pressed() -> void:
	$Settings.popup()


func _on_CreditsLegal_pressed() -> void:
	$Credits.popup()


func _on_Stats_pressed() -> void:
	$Statistics.popup()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _detect_if_save_file() -> bool:
	var f := File.new()
	if f.file_exists(SAVE_FILE_PATH):
		return true
	return false


func _load_if_save_file() -> SavedGameState:
	var res := load(SAVE_FILE_PATH)
	return res as SavedGameState
