extends GutTest

var menu_scene : Control
var gameplay_scene : Node2D
var _pre_existing_save_file : SavedGameState # TODO: store real save file here when saving/loading test savedgame in a test

func before_all() -> void:
	GameState.building_tiles = null
	GameState.background_tiles = null

func before_each() -> void:
	menu_scene = partial_double("res://main/MainMenu.tscn").instance()
	menu_scene.gameplay_scene = partial_double("res://main/Main.tscn")
	add_child_autoqfree(menu_scene)

func after_each() -> void:
	GameState.building_tiles = null
	GameState.background_tiles = null

func test_new_game_init_integration() -> void:
	# No changing scenes in a test case, so just call methods that would be called within MainMenu._on_Start_pressed()
	GameState.initialize_new_game()
	assert_not_null(GameState.building_tiles)

	# Now "change the scene"
	gameplay_scene = partial_double("res://main/Main.tscn").instance()
	add_child_autoqfree(gameplay_scene) # Should invoke _ready()

	assert_called(gameplay_scene,"initialize_or_restore_map_state")
	assert_false(get_tree().paused)
