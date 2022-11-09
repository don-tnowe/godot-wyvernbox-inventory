class_name CurrencyInventory
extends Inventory

var restricted_to_types := []


func _init(restriction_array).(restriction_array.size(), 1):
	restricted_to_types = restriction_array


func _get_free_position(item_type : ItemType) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null && item_type == restricted_to_types[i]:
			return Vector2(i, 0)

	return Vector2(-1, -1)	


func _try_stack_item(item_type : ItemType, count_delta : int = 1) -> int:
	if count_delta == 0: return 0

	for i in restricted_to_types.size():
		if restricted_to_types[i] == item_type:
			# If stack full, move on.
			if get_stack_at_position(i, 0) == null:
				return 0
			
			_cells[i].count += count_delta
			emit_signal("item_stack_changed", _cells[i], count_delta)
			return count_delta

	return 0


func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if restricted_to_types[pos.x] != item_stack.item_type:
		return item_stack
	
	return .try_place_stackv(item_stack, pos)


func _drop_stack_on_stack(top : ItemStack, bottom : ItemStack) -> int:
	# ALWAYS transfer all units to the bottom - currency here is infinitely stackable.
	var top_count = top.count
	top.count = 0
	bottom.count += top_count
	return top_count
