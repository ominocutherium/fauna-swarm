extends Resource

class_name SavedBuilding


const QUEUE_ITEM_TYPE = {
	"task_identifier":"",
	"target_identifier":"", # typically a unit identifier
	"cooldown_s":5.0, # only counts down for most recent one
}

export(int) var identifer : int
export(int) var building_type : int
export(int) var main_tile_x : int
export(int) var main_tile_y : int
export(int) var current_health : float
export(Array) var queue_items

var queue_expiry_event # connects to the heap


func get_maximum_health() -> float:
	# queries static data based on building type
	return 1.0

func get_maximum_queue_size() -> int:
	# queries static data based on building type
	return 0

func push_top_queue_item_event_to_heap() -> void:
	if queue_items.size() > 0:
		var timeout : float = queue_items[0].cooldown_s
		# TODO: finish implementing when an event queue, world time, and event type exists
