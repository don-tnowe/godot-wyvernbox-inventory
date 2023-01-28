tool
class_name Inventory
extends Resource

signal item_stack_added(item_stack)
signal item_stack_changed(item_stack, count_delta)
signal item_stack_removed(item_stack)

export var _width := 8 setget _set_width

# The list of items in this inventory.
# Setting and editing may lead to unpredictable behaviour.
var items := []

var _cells := []


func _set_width(v, emit = true):
	if v < 1: v = 1
	_width = v
	_update_size()
	if emit: emit_changed()
	if "restricted_to_types" in self:
		self.restricted_to_types.resize(v)


func _update_size():
	_cells.resize(_width)


# Tries to place [code]stack[/code] into first possible stacks or cells.
# Returns the number of items deposited, which equates to stack's [member ItemStack.count] on success and [code]0[/code] if inventory was full.
# [code]total_deposited[/code] should not be set, as it is used internally.
func try_add_item(stack : ItemStack, total_deposited : int = 0) -> int:
	var item_type = stack.item_type
	var count = stack.count
	var maxcount = get_max_count(item_type)
	while count > maxcount:
		var deposited_overflow = try_add_item(stack.duplicate_with_count(maxcount))
		count -= maxcount
		if deposited_overflow < maxcount:
			return deposited_overflow + total_deposited

	var deposited_through_stacking := _try_stack_item(stack, count)
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

	var rect_pos := get_free_position(stack)
	if rect_pos.x == -1:
		return total_deposited
	
	stack = stack.duplicate_with_count(count)
	stack.position_in_inventory = rect_pos
	_fill_stack_cells(stack)
	_add_to_items_array(stack)
	return count + total_deposited

# Tries to insert items here after a [kbd]Shift+Click[/kbd] on a stack elsewhere.
# Returns the stack that appears where the clicked stack was, which is null on success and the same stack on fail.
func try_quick_transfer(item_stack : ItemStack) -> ItemStack:
	var count_transferred := try_add_item(item_stack)
	item_stack.count -= count_transferred
	if item_stack.count > 0:
		return item_stack

	else: return null

# Returns [code]true[/code] if cell at [code]position[/code] is free.
func can_place_item(item : ItemStack, position : Vector2) -> bool:
	return _cells[position.x + position.y * _width] == null

# Adds [code]delta[/code] or removes [code]-delta[/code] items to [code]item_stack[/code], removing the stack if it becomes empty and emitting [signal item_stack_changed] otherwise.
func add_items_to_stack(item_stack : ItemStack, delta : int = 1):
	item_stack.count += delta
	if item_stack.count > 0:
		emit_signal("item_stack_changed", item_stack, delta)

	else:
		remove_item(item_stack)

# Removes the stack from this inventory, it it was in here.
func remove_item(item_stack : ItemStack):
	items.remove(item_stack.index_in_inventory)
	_clear_stack_cells(item_stack)

	for i in items.size():
		items[i].index_in_inventory = i

	emit_signal("item_stack_removed", item_stack)

# Moves [code]item_stack[/code] to cell [code]pos[/code] in this inventory, removing it from its old inventory if needed.
func move_item_to_pos(item_stack : ItemStack, pos : Vector2):
	if item_stack.count == 0: return

	if item_stack.inventory == self:
		_clear_stack_cells(item_stack)
		remove_item(item_stack)
		item_stack.position_in_inventory = pos
		_add_to_items_array(item_stack)

	else:
		# If from another inv, remove it from there and add to here
		if item_stack.inventory != null:
			item_stack.inventory.remove_item(item_stack)

		item_stack.position_in_inventory = pos
		_add_to_items_array(item_stack)
	
	_fill_stack_cells(item_stack)
	emit_signal("item_stack_changed", item_stack, 0)

# Tries to place [code]item_stack[/code] into a cell with position [code]pos[/code].
# Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]item_stack[/code] if it could not be placed.
func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if !has_cell(pos.x, pos.y): return item_stack

	var found_stack := get_item_at_position(pos.x, pos.y)
	return _place_stackv(item_stack, found_stack, pos)

# Returns the first cell the [code]item_stack[/code] can be placed without stacking.
# Returns [code](-1, -1)[/code] if no empty cells in inventory.
func get_free_position(item_stack : ItemStack) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null:
			return Vector2(i % _width, i / _width)

	return Vector2(-1, -1)

# Returns the [ItemStack] in cell [code](x, y)[/code]; [code]null[/code] if cell empty or out of bounds.
func get_item_at_position(x : int, y : int) -> ItemStack:
	if !has_cell(x, y): return null
	return _cells[y * _width + x]

# Returns the item's max stack count.
# Override to create inventory types with a custom stack limit.
func get_max_count(item_type):
	return item_type.max_stack_count


func _add_to_items_array(item_stack):
	item_stack.inventory = self
	item_stack.index_in_inventory = items.size()
	items.append(item_stack)
	emit_signal("item_stack_added", item_stack)


func _try_stack_item(item_stack : ItemStack, count_delta : int = 1) -> int:
	if count_delta == 0: return 0

	var deposited_count := 0
	for x in items:
		if x.can_stack_with(item_stack):
			deposited_count = ItemStack.get_stack_delta_if_added(x.count, count_delta, get_max_count(item_stack.item_type))
			# If stack full, move on.
			if deposited_count == 0: continue
			x.count += deposited_count
			emit_signal("item_stack_changed", x, deposited_count)
			return deposited_count

	return 0


func _clear_stack_cells(item_stack : ItemStack):
	_cells[item_stack.position_in_inventory.x + item_stack.position_in_inventory.y * _width] = null
	item_stack.inventory = null


func _fill_stack_cells(item_stack : ItemStack):
	_cells[item_stack.position_in_inventory.x + item_stack.position_in_inventory.y * _width] = item_stack
	item_stack.inventory = self


func _place_stackv(top : ItemStack, bottom : ItemStack, pos : Vector2) -> ItemStack:
	# If placing on a cell with item, return that item or stacking remainder
	if bottom != null:
		bottom = _swap_stacks(top, bottom)
	
	# Only move top item to slot if it's not stacking remainder
	if top != bottom:
		move_item_to_pos(top, pos)

	return bottom


func _drop_stack_on_stack(top : ItemStack, bottom : ItemStack) -> int:
	var top_count = top.count
	var bottom_count_delta = ItemStack.get_stack_delta_if_added(bottom.count, top_count, get_max_count(bottom.item_type))
	top.count = ItemStack.get_stack_overflow_if_added(bottom.count, top_count, get_max_count(bottom.item_type))
	bottom.count += bottom_count_delta
	return bottom_count_delta


func _swap_stacks(top : ItemStack, bottom : ItemStack) -> ItemStack:
	if !bottom.can_stack_with(top):
		# If can't be stacked, just swap places.
		remove_item(bottom)
		return bottom
	
	var bottom_count_delta = _drop_stack_on_stack(top, bottom)
	if top.count == 0:
		top = null
	
	emit_signal("item_stack_changed", bottom, bottom_count_delta)
	return top

# Returns [code]false[/code] if cell out of bounds.
func has_cell(x : int, y : int) -> bool:
	if x < 0 || y < 0: return false
	if x > _width: return false
	return true

# Counts all items, incrementing entries in [code]into_dict[/code].
# Note: this modifies the passed dictionary.
func count_all_items(into_dict : Dictionary = {}) -> Dictionary:
	for x in items:
		into_dict[x.item_type] = into_dict.get(x.item_type, 0) + x.count

	return into_dict

# Counts all item types and patterns inside [code]items_patterns[/code], incrementing entries in [code]into_dict[/code].
# If [code]prepacked_reqs[/code] set, checks only items (not patterns!) in the keys. In most cases, it makes the method work faster.
# Note: this method modifies the passed dictionary.
func count_items(items_patterns, into_dict : Dictionary = {}, prepacked_reqs : Dictionary = {}) -> Dictionary:
	var matched_pattern
	var check_reqs = prepacked_reqs.size() > 0 && !prepacked_reqs.has(null)
	for x in items:
		# Dictionary lookup is faster than _get_match(), which has an array search
		# and a call on an array of type-unknown objects
		# This check is not made if ItemPattern.collect_item_dict() added a null
		# => pattern can match any item type, not just those in dict
		if check_reqs && !prepacked_reqs.has(x.item_type):
			continue

		matched_pattern = _get_match(x, items_patterns)
		if matched_pattern == null: continue
		into_dict[matched_pattern] = into_dict.get(matched_pattern, 0) + matched_pattern.get_value(x)

	return into_dict

# Returns [code]true[/code] if the counts of [code]items_patterns[/code] items and patterns are no less that those in [code]item_type_counts[/code].
func has_items(items_patterns, item_type_counts : Dictionary) -> bool:
	var owned_counts := count_items(items_patterns)
	for k in owned_counts:
		if owned_counts[k] < item_type_counts[k]:
			return false
			
	return true

# Consumes items matching types and patterns inside [code]item_type_counts[/code].
# Returns all stacks consumed.
# Set [code]check_only[/code] to not actually consume items - this is useful to highlight stacks that would be affected, or show which items are not of sufficient amount.
# Note: this method modifies the [code]item_type_counts[/code] dictionary. The resulting values will match the types/patterns that could not be fully fulfilled.
# If [code]prepacked_reqs[/code] set, checks only items (not patterns!) in the keys. In most cases, it makes the method work faster.
func consume_items(item_type_counts : Dictionary, check_only : bool = false, prepacked_reqs : Dictionary = {}) -> Array:
	var consumed_stacks = []
	# See count_items().
	var check_reqs = prepacked_reqs.size() > 0 && !prepacked_reqs.has(null)
	var matched_pattern
	var stack_value : float
	for x in get_items_ordered():
		if item_type_counts.size() == 0:
			break

		if check_reqs && !prepacked_reqs.has(x.item_type):
			continue

		matched_pattern = _get_match(x, item_type_counts)
		if matched_pattern == null:
			continue

		stack_value = matched_pattern.get_value(x)
		item_type_counts[matched_pattern] -= stack_value
		if item_type_counts[matched_pattern] <= 0:
			var consumed_from_stack = x.count + ceil(item_type_counts[matched_pattern] / (stack_value / x.count))
			consumed_stacks.append(x.duplicate_with_count(consumed_from_stack))
			add_items_to_stack(x, -consumed_from_stack)
			item_type_counts.erase(matched_pattern)

		else:
			if !check_only:
				remove_item(x)

			consumed_stacks.append(x)

	return consumed_stacks

# Returns items ordered by cell position.
func get_items_ordered():
	var arr = items.duplicate()
	arr.sort_custom(self, "_compare_pos_sort")
	return arr

# Returns position vectors of all free cells in the inventory.
func get_all_free_positions(for_size_x : int = 1, for_size_y : int = 1) -> Array:
	var free_cells := []
	var height = self._height if "_height" in self else 1
	for i in _width:
		for j in height:
			if get_item_at_position(i, j) == null:
				free_cells.append(Vector2(i, j))
	
	return free_cells


func _get_match(item : ItemStack, items_patterns) -> Resource:
	if items_patterns.has(item.item_type):
		return item.item_type

	for x in items_patterns:
		if x.matches(item):
			return x

	return null

# Sorts the inventory by item size, then type.
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
		remove_item(x)
	
	var sizes = by_size_type.keys()
	sizes.sort_custom(self, "_compare_size_sort")

	for k in sizes:
		for l in by_size_type[k]:
			for x in by_size_type[k][l]:
				try_add_item(x)


func _compare_size_sort(a : Vector2, b : Vector2):
	return a.x + a.y * 1.01 > b.x + b.y * 1.01


func _compare_pos_sort(a : ItemStack, b : ItemStack):
	return a.position_in_inventory.x + a.position_in_inventory.y * _width < b.position_in_inventory.x + b.position_in_inventory.y * _width

# Loads contents from an array created via [code]to_array[/code].
func load_from_array(array : Array):
	var new_item : ItemStack
	for x in items.duplicate():
		remove_item(x)

	for x in array:
		new_item = ItemStack.new_from_dict(x)
		if new_item.position_in_inventory.x == -1:
			try_add_item(new_item)

		else:
			try_place_stackv(new_item, new_item.position_in_inventory)

# Returns the contents of this inventory as an array of dictionaries. Useful for serialization.
func to_array() -> Array:
	var array = []
	array.resize(items.size())
	for i in array.size():
		array[i] = items[i].to_dict()

	return array

# Writes inventory contents to file [code]filename[/code].
# Only [code]user://[/code] paths are supported.
func save_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var file = File.new()
	var dir = Directory.new()
	if !dir.dir_exists(filename.get_base_dir()):
		dir.make_dir_recursive(filename.get_base_dir())

	file.open(filename, File.WRITE)
	file.store_var(to_array())

# Loads inventory contents from file [code]filename[/code].
# Only [code]user://[/code] paths are supported.
func load_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var file = File.new()
	var dir = Directory.new()
	if !file.file_exists(filename):
		return

	file.open(filename, File.READ)
	load_from_array(file.get_var())
