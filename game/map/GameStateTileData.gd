extends Resource

class_name MapTileData


signal tile_updated(coords,tile_type)


export(Rect2) var extents : Rect2
export(PoolIntArray) var tile_data : PoolIntArray

func apply_to_tilemap(tm:TileMap) -> void:
	var row_size := int(extents.size.x)
	for j in range(int(extents.position.y),int(extents.end.y)):
		for i in range(int(extents.position.x),int(extents.end.x)):
			tm.set_cellv(Vector2(i,j),tile_data[j*row_size+i])


func extract_from_tilemap(tm:TileMap) -> void:
	extents = tm.get_used_rect()
	tile_data = PoolIntArray()
	for j in range(int(extents.position.y),int(extents.end.y)):
		for i in range(int(extents.position.x),int(extents.end.x)):
			tile_data.append(tm.get_cell(i,j))
