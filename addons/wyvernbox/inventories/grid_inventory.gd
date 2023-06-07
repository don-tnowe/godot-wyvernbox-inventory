@tool
@icon("res://addons/wyvernbox/icons/grid_inventory.png")
class_name GridInventory
extends Inventory

## Inventory's vertical cell count.
@export var height := 1:
	set(v):
		if v < 1: v = 1
		height = v
		_update_size()
		emit_changed()


func _update_size():
	_cells.resize(width)
	for i in width:
		_cells[i] = []
		_cells[i].resize(height)

	for x in items:
		_fill_stack_cells(x)

## Returns the top-left of the first position the [code]item_stack[/code] can fit into.
func get_free_position(item_stack : ItemStack) -> Vector2:
	var item_type = item_stack.item_type
	if item_type.in_inventory_height >= item_type.in_inventory_width:
		for j in height - item_type.in_inventory_height + 1:
			for i in width - item_type.in_inventory_width + 1:
				if _is_rect_free(i, j, item_type.in_inventory_width, item_type.in_inventory_height):
					return Vector2(i, j)

	else:
		for i in width - item_type.in_inventory_width + 1:
			for j in height - item_type.in_inventory_height + 1:
				if _is_rect_free(i, j, item_type.in_inventory_width, item_type.in_inventory_height):
					return Vector2(i, j)

	return Vector2(-1, -1)

## Returns [code]false[/code] if cell out of bounds.
func has_cell(x : int, y : int) -> bool:
	return super.has_cell(x, y) && y <= height


func _is_rect_free(x : int, y : int, r_width : int, r_height : int) -> bool:
	if !has_cell(x, y) || !has_cell(x + r_width, y + r_height): return false

	for i in r_width:
		for j in r_height:
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

## Returns [code]true[/code] if cells under the [code]item[/code] are free.
func can_place_item(item : ItemStack, position : Vector2) -> bool:
	return _is_rect_free(
		position.x,
		position.y,
		item.item_type.in_inventory_width,
		item.item_type.in_inventory_height
	)

## Tries to place [code]item_stack[/code] into cell [code]pos[/code].
## Returns the stack that appeared in hand after, which is [code]null[/code] if rect was empty or the [code]item_stack[/code] if it could not be placed.
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
				
				## Found two or more stacks, but can only grab one! Return the attempted-to-place stack.
				elif found_now != null:
					return item_stack
	
	return _place_stackv(item_stack, found_stack, pos)

## Returns the [ItemStack] in cell [code](x, y)[/code]; returns [code]null[/code] if cell empty or out of bounds.
func get_item_at_position(x : int, y : int = 0) -> ItemStack:
	if !has_cell(x, y): return null
	return _cells[x][y]

## Returns position vectors of all free cells in the inventory.
func get_all_free_positions(for_size_x : int = 1, for_size_y : int = 1) -> Array:
	var free_cells := {}
	for i in width - for_size_x + 1:
		for j in height - for_size_y + 1:
			free_cells[Vector2(i, j)] = true

	for i in width:
		for j in height:
			if get_item_at_position(i, j) != null:
				for item_i in for_size_x:
					for item_j in for_size_y:
						free_cells.erase(Vector2(i - item_i, j - item_j))
	
	return free_cells.keys()
