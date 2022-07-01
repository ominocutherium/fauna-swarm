class_name EventHeap
# a heap data type which does bookkeep of dictionaries in an array. Intended to be included
# via composition in a class which knows what to do with the popped dicts.

# Included keys must have a bool associated with the key "is_in_heap" and an
# int associated with the key "heap_idx". Also, there must be a float associated
# with the key named in "dict_key_with_compare". The heap otherwise makes no further
# assumptions about the data in the dictionary.


extends Resource


export(String) var dict_key_with_compare
export(Array) var dicts_in_heap


func push_dict_onto_heap(dict:Dictionary) -> void:
	_insert_dict_onto_heap(dict)


func compare_top_dict_with_value(compare_value:float) -> Dictionary:
	if dicts_in_heap.size() < 1:
		return {}
	var dict = dicts_in_heap[0]
	if dict.get(dict_key_with_compare) < compare_value:
		_remove_dict_from_heap(0)
		return dict
	return {}


func reorganize_heap_starting_on_dict(dict) -> void:
	_rebalance_heap_from_top(dict.heap_idx)


func remove_dict_from_heap(dict) -> void:
	if !dict.is_in_heap:
		return
	_remove_dict_from_heap(dict.heap_idx)


func _rebalance_heap_from_top(idx:int) -> void:
	if _get_idx_of_first_child(idx) >= dicts_in_heap.size():
		# no first child
		return
	elif _get_idx_of_first_child(idx) + 1 == dicts_in_heap.size():
		# special case where first child is last item
		var dict = dicts_in_heap[idx]
		var child_dict = dicts_in_heap[_get_idx_of_first_child(idx)]
		if child_dict.get(dict_key_with_compare) < dict.get(dict_key_with_compare):
					_swap_dicts_in_heap(idx,_get_idx_of_first_child(idx))
	else:
		var dict = dicts_in_heap[idx]
		var child_dict_0 = dicts_in_heap[_get_idx_of_first_child(idx)]
		var child_dict_1 = dicts_in_heap[_get_idx_of_first_child(idx)+1]
		if child_dict_0.get(dict_key_with_compare) < dict.get(dict_key_with_compare) or \
				child_dict_1.get(dict_key_with_compare) < dict.get(dict_key_with_compare) :
					if child_dict_0.get(dict_key_with_compare) < child_dict_1.get(dict_key_with_compare):
						_swap_dicts_in_heap(idx,_get_idx_of_first_child(idx))
						_rebalance_heap_from_top(_get_idx_of_first_child(idx))
					else:
						_swap_dicts_in_heap(idx,_get_idx_of_first_child(idx)+1)
						_rebalance_heap_from_top(_get_idx_of_first_child(idx)+1)


func _rebalance_heap_from_bottom(idx:int) -> void:
	if idx == 0:
		return
	var dict = dicts_in_heap[idx]
	var parent_dict = dicts_in_heap[_get_idx_of_parent_in_heap(idx)]
	if dict.get(dict_key_with_compare) < parent_dict.get(dict_key_with_compare):
		_swap_dicts_in_heap(idx,_get_idx_of_parent_in_heap(idx))
		_rebalance_heap_from_bottom(_get_idx_of_parent_in_heap(idx))


func _swap_dicts_in_heap(idx:int,swap_idx:int) -> void:
	var dict = dicts_in_heap[idx]
	var swap_dict = dicts_in_heap[swap_idx]
	_set_dict_pos_in_heap(dict,swap_idx)
	_set_dict_pos_in_heap(swap_dict,idx)


func _get_idx_of_first_child(idx:int) -> int:
	return (idx<<1)+1


func _get_idx_of_parent_in_heap(idx:int) -> int:
	if idx == 0:
		return -1 # undefined
	return (idx-1)>>1


func _set_dict_pos_in_heap(dict,idx:int) -> void:
	dicts_in_heap[idx] = dict
	dict.heap_idx = idx


func _insert_dict_onto_heap(dict:Dictionary) -> void:
	var heap_id : int = dicts_in_heap.size()
	dicts_in_heap.append(dict)
	dict.is_in_heap = true
	dict.heap_idx = heap_id
	if heap_id > 0:
		_rebalance_heap_from_bottom(heap_id)


func _move_last_to_popped_place(popped_idx:int) -> void:
	var last_idx : int = dicts_in_heap.size() -1
	var dict = dicts_in_heap[last_idx]
	dict.heap_idx = popped_idx
	dicts_in_heap[popped_idx] = dict
	dicts_in_heap.resize(last_idx)
	_rebalance_heap_from_top(popped_idx)


func _remove_dict_from_heap(idx:int) -> void:
	var dict = dicts_in_heap[idx]
	dict.is_in_heap = false
	dict.heap_idx = -1
	_move_last_to_popped_place(idx)
	
