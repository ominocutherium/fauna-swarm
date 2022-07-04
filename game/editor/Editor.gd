extends TileMap
# Do not export this (or the tileset it uses) with the game.
# Tile graphics do not matter but the names of tiles in the editor tileset do matter 
# (they have to match the names of functional tiles in the functional tiles spreadsheet).
# Run the scene to save the resource.


export(String,FILE) var save_to : String
export(String) var cosmetic_rng_seed : String


func _ready() -> void:
	save_to_res()


func save_to_res() -> void:
	var save_res := StartingMapResource.new()
	save_res.extents = get_used_rect()
	save_res.tile_data.resize(int(save_res.extents.size.x*save_res.extents.size.y))
	for t in tile_set.get_tiles_ids():
		var tile_id : int = t
		if save_res.tile_type_names_by_id.size() < tile_id + 1:
			save_res.tile_type_names_by_id.resize(tile_id + 1)
		save_res.tile_type_names_by_id[tile_id] = tile_set.tile_get_name(tile_id)
	for tile_v in get_used_cells(): # make sure to actually paint every cell in the rectangle
		save_res.tile_data[int(tile_v.x+tile_v.y*save_res.extents.size.x)] = get_cellv(tile_v)

	if cosmetic_rng_seed == "":
		randomize()
		save_res.cosmetic_randomization_seed = randi()
	else:
		save_res.cosmetic_randomization_seed = hash(cosmetic_rng_seed)
	ResourceSaver.save(save_to,save_res)
