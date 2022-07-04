extends Resource

class_name StartingMapResource

# The map resource created by the editor and loaded by the game itself.

export(PoolStringArray) var tile_type_names_by_id := PoolStringArray()
export(PoolIntArray) var tile_data := PoolIntArray()
export(Rect2) var extents : Rect2
export(int) var cosmetic_randomization_seed : int
