extends TileMap


func _on_tile_updated_in_gamestate(tile_coords:Vector2,tile_type:int) -> void:
	set_cellv(tile_coords,tile_type)
