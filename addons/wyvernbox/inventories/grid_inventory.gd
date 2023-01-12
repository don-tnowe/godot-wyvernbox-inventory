class_name GridInventory
extends Inventory


func _init(width, height).(width, height):
	_init2(width, height)


func _init2(width, height):
	_width = width
	_height = height
	_cells.resize(width)
	for i in width:
		_cells[i] = []
		_cells[i].resize(height)

# Returns the top-left of the first position the `item_stack` can fit into.
func get_free_position(item_stack : ItemStack) -> Vector2:
	var item_type = item_stack.item_type
	if item_type.in_inventory_height >= item_type.in_inventory_width:
		for j in _height - item_type.in_inventory_height + 1:
			for i in _width - item_type.in_inventory_width + 1:
				if _is_rect_free(i, j, item_type.in_inventory_width, item_type.in_inventory_height):
					return Vector2(i, j)

	else:
		for i in _width - item_type.in_inventory_width + 1:
			for j in _height - item_type.in_inventory_height + 1:
				if _is_rect_free(i, j, item_type.in_inventory_width, item_type.in_inventory_height):
					return Vector2(i, j)

	return Vector2(-1, -1)


func _is_rect_free(x : int, y : int, width : int, height : int) -> bool:
	if !has_cell(x, y) || !has_cell(x + width, y + height): return false

	for i in width:
		for j in height:
			if _cells[x + i][y + j] != null:
				return false

	return true


func _fill_stack_cells(item_stack : ItemStack):
	for i in item_stack.item_type.in_inventory_width:
		for j in item_stack.item_type.in_inventory_height:
			_cells[i + item_stack.position_in_inventory.x][j + item_stack.position_in_inventory.y] = item_stack
			
	item_stack.inventory = self


func _clear_stack_cells(item_stack : ItemStack):
	for i in range(item_stack.position_in_inventory.x, item_stack.get_bottom_right().x):
		for j in range(item_stack.position_in_inventory.y, item_stack.get_bottom_right().y):
			_cells[i][j] = null

	item_stack.inventory = null

# Returns `true` if cells under the `item` are free.
func can_place_item(item : ItemStack, position : Vector2) -> bool:
	return _is_rect_free(
		position.x,
		position.y,
		item.item_type.in_inventory_width,
		item.item_type.in_inventory_height
	)

# Tries to place `item_stack` into a cell with position `pos`.
# Returns the stack that appeared in hand after, which is `null` if rect was empty or the `item_stack` if it could not be placed.
func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if !has_cell(pos.x, pos.y): return item_stack
	if !has_cell(
		pos.x + item_stack.item_type.in_inventory_width,
		pos.y + item_stack.item_type.in_inventory_height
	):
		return item_stack
	
	var found_stack = null
	for i in range(pos.x, pos.x + item_stack.item_type.in_inventory_width):
		for j in range(pos.y, pos.y + item_stack.item_type.in_inventory_height):
			var found_now = get_item_at_position(i, j)
			if found_now == item_stack: continue
			if found_now != found_stack:
				if found_stack == null:
					found_stack = found_now
				
				# Found two or more stacks, but can only grab one! Return the attempted-to-place stack.
				elif found_now != null:
					return item_stack
	
	return _place_stackv(item_stack, found_stack, pos)

# Returns the `ItemStack` in cell `(x, y)`; `null` if cell empty or out of bounds.
func get_item_at_position(x : int, y : int) -> ItemStack:
	if !has_cell(x, y): return null
	return _cells[x][y]
