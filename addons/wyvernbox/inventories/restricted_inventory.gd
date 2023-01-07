class_name RestrictedInventory
extends Inventory

var allow_rotation := true
var restricted_to_types := []


func _init(restriction_array).(restriction_array.size(), 1):
	restricted_to_types = restriction_array


func _get_free_position(item_stack : ItemStack) -> Vector2:
	var flags = item_stack.item_type.slot_flags
	for i in _cells.size():
		if _cells[i] == null && flags & restricted_to_types[i] != 0:
			return Vector2(i % _width, i / _width)

	return Vector2(-1, -1)


func _shift_contents(to_fit_item : ItemStack) -> ItemStack:
	var returned_item : ItemStack
	var last_viable_position := Vector2(-1, -1)
	for i in range(restricted_to_types.size() - 1, -1, -1):
		if restricted_to_types[i] & to_fit_item.item_type.slot_flags == 0:
			continue
		
		if returned_item == null:
			returned_item = _cells[i]
			remove_stack(returned_item)
			last_viable_position = returned_item.position_in_inventory
			continue
		
		var item_pos = _cells[i].position_in_inventory
		move_stack_to_pos(_cells[i], last_viable_position)
		last_viable_position = item_pos

	move_stack_to_pos(to_fit_item, last_viable_position)
	return returned_item


func _has_fitting_slot(flags : int) -> bool:
	for x in restricted_to_types:
		if x & flags != 0:
			return true

	return false


func try_quick_transfer(item_stack : ItemStack) -> ItemStack:
	var init_count = item_stack.count
	var count_transferred := try_add_item(item_stack)
	item_stack.count -= count_transferred
	if count_transferred < init_count:
		if allow_rotation && _has_fitting_slot(item_stack.item_type.slot_flags):
			return _shift_contents(item_stack)

		return item_stack

	if item_stack.count > 0:
		return item_stack

	else: return null


func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if !has_cell(pos.x, pos.y): return item_stack
	if restricted_to_types[pos.x] & item_stack.item_type.slot_flags == 0:
		return item_stack

	var found_stack := get_stack_at_position(pos.x, pos.y)
	return _place_stackv(item_stack, found_stack, pos)
