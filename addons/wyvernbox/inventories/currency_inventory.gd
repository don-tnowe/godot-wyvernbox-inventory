class_name CurrencyInventory
extends Inventory

# Each cell's [ItemType] or [ItemPattern]. Items that don't match won't fit in.
var restricted_to_types := []

# The custom capacity of all stacks in this inventory.
var max_stack := 99999999


func _init(restriction_array, max_stack_count = 99999999).(restriction_array.size(), 1):
	restricted_to_types = restriction_array
	max_stack = max_stack_count

# Returns the configured [member max_stack].
func get_max_count(item_type):
	return max_stack

# Returns the first empty cell position the [code]item_stack[/code] can fit into.
func get_free_position(item_stack : ItemStack) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null && restricted_to_types[i] != null && restricted_to_types[i].matches(item_stack):
			return Vector2(i, 0)

	return Vector2(-1, -1)

# Tries to place [code]item_stack[/code] into cell [code]pos[/code].
# Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]item_stack[/code] if it could not be placed.
func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if restricted_to_types[pos.x] != item_stack.item_type:
		return item_stack

	return .try_place_stackv(item_stack, pos)
