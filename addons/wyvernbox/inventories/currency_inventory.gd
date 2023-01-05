class_name CurrencyInventory
extends Inventory

var restricted_to_types := []
var max_stack := 99999999


func _init(restriction_array, max_stack_count = 99999999).(restriction_array.size(), 1):
	restricted_to_types = restriction_array
	max_stack = max_stack_count


func _get_free_position(item_type : ItemType) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null && item_type == restricted_to_types[i]:
			return Vector2(i, 0)

	return Vector2(-1, -1)


func _try_stack_item(item_type : ItemType, count_delta : int = 1) -> int:
	if count_delta == 0: return 0

	var deposited_count := 0
	for x in items:
		if x.item_type == item_type:
			deposited_count = ItemStack.get_stack_delta_if_added(x.count, count_delta, max_stack)
			# If stack full, move on.
			if deposited_count == 0: continue
			x.count += deposited_count
			emit_signal("item_stack_changed", x, deposited_count)
			return deposited_count

	return 0


func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if restricted_to_types[pos.x] != item_stack.item_type:
		return item_stack
	
	return .try_place_stackv(item_stack, pos)


func _place_stackv(top : ItemStack, bottom : ItemStack, pos : Vector2) -> ItemStack:
	# If placing on a cell with item, return that item or stacking remainder
	if bottom != null:
		bottom = _swap_stacks(top, bottom)

	else:
		var new_stack = ItemStack.new(top.item_type, 0, top.extra_properties)
		top.count -= _drop_stack_on_stack(top, new_stack)
		move_stack_to_pos(new_stack, pos)
		return top if top.count > 0 else null

	# Only move top item to slot if it's not stacking remainder
	if top != bottom:
		move_stack_to_pos(top, pos)

	return bottom


func _drop_stack_on_stack(top : ItemStack, bottom : ItemStack) -> int:
	var bottom_count_delta = ItemStack.get_stack_delta_if_added(bottom.count, top.count, max_stack)
	top.count = ItemStack.get_stack_overflow_if_added(bottom.count, top.count, max_stack)
	bottom.count += bottom_count_delta
	return bottom_count_delta
