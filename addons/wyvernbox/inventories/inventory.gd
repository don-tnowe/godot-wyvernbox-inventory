class_name Inventory
extends Reference

signal item_stack_added(item_stack)
signal item_stack_changed(item_stack, count_delta)
signal item_stack_removed(item_stack)

var _width := 8
var _height := 1

var items := []
var _cells := []
var _counts := {}


func _init(width, height):
	_init2(width, height)


func _init2(width, height):
	_width = width
	_height = height
	_cells.resize(width * height)


func get_width() -> int:
	return _width


func get_height() -> int:
	return _height


func try_add_item(stack : ItemStack, total_deposited : int = 0) -> int:
	var item_type = stack.item_type
	var count = stack.count
	var deposited_through_stacking := _try_stack_item(item_type, count)
	if deposited_through_stacking > 0:
		# If all items deposited, return.
		if count - deposited_through_stacking <= 0:
			return total_deposited + deposited_through_stacking

		# If a stack got filled,
		# create another stack from the items that did not fit.
		total_deposited += deposited_through_stacking
		return try_add_item(
			stack.duplicate_with_count(count - deposited_through_stacking),
			total_deposited
		)

	var rect_pos := _get_free_position(item_type)
	if rect_pos.x == -1:
		return total_deposited
	
	stack = stack.duplicate_with_count(count)
	stack.position_in_inventory = rect_pos
	_fill_stack_cells(stack)
	_add_to_items_array(stack)
	return count + total_deposited


func try_quick_transfer(item_stack : ItemStack) -> ItemStack:
	var count_transferred := try_add_item(item_stack)
	item_stack.count -= count_transferred
	if item_stack.count > 0:
		return item_stack
		
	else: return null


func can_place_item(item : ItemStack, position : Vector2) -> bool:
	return _cells[position.x + position.y * _width] == null


func _add_to_items_array(item_stack):
	item_stack.inventory = self
	item_stack.index_in_inventory = items.size()
	items.append(item_stack)
	emit_signal("item_stack_added", item_stack)


func _get_free_position(item_type : ItemType) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null:
			return Vector2(i % _width, i / _width)

	return Vector2(-1, -1)


func _try_stack_item(item_type : ItemType, count_delta : int = 1) -> int:
	if count_delta == 0: return 0

	var deposited_count := 0
	for x in items:
		if x.item_type == item_type:
			deposited_count = x.get_delta_if_added(count_delta)
			# If stack full, move on.
			if deposited_count == 0: continue
			x.count += deposited_count
			emit_signal("item_stack_changed", x, deposited_count)
			return deposited_count

	return 0


func add_items_to_stack(item_stack : ItemStack, delta : int = 1):
	item_stack.count += delta
	if item_stack.count > 1:
		emit_signal("item_stack_changed", item_stack, delta)

	else:
		remove_stack(item_stack)


func remove_stack(stack : ItemStack):
	items.remove(stack.index_in_inventory)
	_clear_stack_cells(stack)

	for i in items.size():
		items[i].index_in_inventory = i

	emit_signal("item_stack_removed", stack)


func move_stack_to_pos(item_stack : ItemStack, pos : Vector2):
	if item_stack.count == 0: return

	if item_stack.inventory == self:
		_clear_stack_cells(item_stack)
		remove_stack(item_stack)
		item_stack.position_in_inventory = pos
		_add_to_items_array(item_stack)

	else:
		# If from another inv, remove it from there and add to here
		if item_stack.inventory != null:
			item_stack.inventory.remove_stack(item_stack)

		item_stack.position_in_inventory = pos
		_add_to_items_array(item_stack)
	
	_fill_stack_cells(item_stack)
	emit_signal("item_stack_changed", item_stack, 0)


func _clear_stack_cells(item_stack : ItemStack):
	_cells[item_stack.position_in_inventory.x + item_stack.position_in_inventory.y * _width] = null
	item_stack.inventory = null


func _fill_stack_cells(item_stack : ItemStack):
	_cells[item_stack.position_in_inventory.x + item_stack.position_in_inventory.y * _width] = item_stack
	item_stack.inventory = self


func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if !has_cell(pos.x, pos.y): return item_stack

	var found_stack := get_stack_at_position(pos.x, pos.y)
	return _place_stackv(item_stack, found_stack, pos)


func _place_stackv(top : ItemStack, bottom : ItemStack, pos : Vector2) -> ItemStack:
	# If placing on a cell with item, return that item or stacking remainder
	if bottom != null:
		bottom = _swap_stacks(top, bottom)
	
	# Only move top item to slot if it's not stacking remainder
	if top != bottom:
		move_stack_to_pos(top, pos)

	return bottom


func _drop_stack_on_stack(top : ItemStack, bottom : ItemStack) -> int:
	var top_count = top.count
	var bottom_count_delta = bottom.get_delta_if_added(top_count)
	top.count = bottom.get_overflow_if_added(top_count)
	bottom.count += bottom_count_delta
	return bottom_count_delta


func _swap_stacks(top : ItemStack, bottom : ItemStack) -> ItemStack:
	if !bottom.can_stack_with(top):
		# If can't be stacked, just swap places.
		remove_stack(bottom)
		return bottom
	
	var bottom_count_delta = _drop_stack_on_stack(top, bottom)
	if top.count == 0:
		top = null
	
	emit_signal("item_stack_changed", bottom, bottom_count_delta)
	return top


func get_stack_at_position(x : int, y : int) -> ItemStack:
	if !has_cell(x, y): return null
	return _cells[y * _width + x]


func has_cell(x : int, y : int) -> bool:
	if x < 0 || y < 0: return false
	if x > _width || y > _height: return false
	return true


func count_items(into_dict : Dictionary = {}) -> Dictionary:
	for x in items:
		into_dict[x.item_type] = into_dict.get(x.item_type, 0) + x.count

	return into_dict


func has_items(item_type_counts : Dictionary) -> bool:
	var owned_counts := count_items()
	for k in owned_counts:
		if owned_counts[k] < item_type_counts[k]:
			return false
			
	return true


func consume_items(item_type_counts : Dictionary, check_only : bool = false) -> Dictionary:
	var result_stacks = []
	for x in items:
		if !item_type_counts.has(x.item_type) || item_type_counts[x.item_type] <= 0:
			continue
		
		item_type_counts[x.item_type] -= x.count
		if item_type_counts[x.item_type] < 0:
			var deduced_count = x.count + item_type_counts[x.item_type]
			result_stacks.append(x.duplicate_with_count(deduced_count))
			add_items_to_stack(x, -deduced_count)
			item_type_counts.erase(x.item_type)
			continue

		if !check_only:
			remove_stack(x)
			result_stacks.append(x)

	return result_stacks


func sort():
	var by_size_type = {}
	var cur_size : Vector2
	for x in items.duplicate():
		cur_size = x.item_type.get_size_in_inventory()
		if !by_size_type.has(cur_size):
			by_size_type[cur_size] = {}

		if !by_size_type[cur_size].has(x.item_type):
			by_size_type[cur_size][x.item_type] = []

		by_size_type[cur_size][x.item_type].append(x)
		remove_stack(x)
	
	var sizes = by_size_type.keys()
	sizes.sort_custom(self, "compare_size_sort")

	for k in sizes:
		for l in by_size_type[k]:
			for x in by_size_type[k][l]:
				try_add_item(x)


func compare_size_sort(a, b):
	return a.x + a.y * 1.01 > b.x + b.y * 1.01
