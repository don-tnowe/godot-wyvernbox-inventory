@tool
@icon("res://addons/wyvernbox/icons/restricted_inventory.png")
class_name RestrictedInventory
extends Inventory

## A type of [Inventory] only allowing a specific [member ItemType.slot_flags] flag in each slot. Intended primarily for character equipment
##
## This inventory can allow [kbd]Shift+Click[/kbd] quick-transfers even if no items can fit, cycling through possible slots to place.

## If set and inventory full, quick-transferring into here will shift all items by one cell. [br]
## [b]Warning:[/b] might ignore [member entry_filter].
@export var allow_rotation := true

## Each cell's [member ItemType.slot_flags]. Items that don't match won't fit in.
@export var restricted_to_types : Array[ItemType.SlotFlags] = []:
	set(v):
		restricted_to_types = v
		v.resize(width)


## Returns the first cell the [code]item_stack[/code] can be placed without stacking.
## Returns [code](-1, -1)[/code] if no empty cells in inventory, or the item type doesn't fit due to flags.
func get_free_position(item_stack : ItemStack) -> Vector2:
	var flags = item_stack.item_type.slot_flags
	for i in _cells.size():
		if _cells[i] == null && flags & restricted_to_types[i] != 0 && matches_entry_filter(item_stack):
			return Vector2(i, 0)

	return Vector2(-1, -1)


func _shift_contents(to_fit_item : ItemStack) -> ItemStack:
	var returned_item : ItemStack
	var last_viable_position := Vector2(-1, -1)
	for i in range(restricted_to_types.size() - 1, -1, -1):
		if restricted_to_types[i] & to_fit_item.item_type.slot_flags == 0:
			continue
		
		if returned_item == null:
			returned_item = _cells[i]
			remove_item(returned_item)
			last_viable_position = returned_item.position_in_inventory
			continue
		
		var item_pos = _cells[i].position_in_inventory
		move_item_to_pos(_cells[i], last_viable_position)
		last_viable_position = item_pos

	move_item_to_pos(to_fit_item, last_viable_position)
	return returned_item


func _has_fitting_slot(flags : int) -> bool:
	for x in restricted_to_types:
		if x & flags != 0:
			return true

	return false

## Tries to insert items here after a [kbd]Shift+Click[/code] on a stack elsewhere.
## If [member allow_rotation] is set, this will shift the items by 1 cell if the inventory is full.
## Returns the stack that appears where the clicked stack was, which is [code]null[/code] on success and the same stack on fail.
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

## Tries to place [code]item_stack[/code] into a cell with position [code]pos[/code].
## Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]item_stack[/code] if it could not be placed.
func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if !has_cell(pos.x, pos.y): return item_stack
	if restricted_to_types[pos.x] & item_stack.item_type.slot_flags == 0:
		return item_stack

	var found_stack := get_item_at_position(pos.x, pos.y)
	return _place_stackv(item_stack, found_stack, pos)
