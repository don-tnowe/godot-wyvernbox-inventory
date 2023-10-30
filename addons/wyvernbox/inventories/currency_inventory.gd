@tool
@icon("res://addons/wyvernbox/icons/currency_inventory.png")
class_name CurrencyInventory
extends Inventory

## A type of [Inventory] only allowing a specific item in each slot, but providing a higher stack limit.

## Each cell's [ItemType] or [ItemPattern]. Items that don't match won't fit in.
@export var restricted_to_types : Array[ItemLike] = []

## The custom capacity of all stacks in this inventory.
@export var max_stack := 99999999


## Returns the configured [member max_stack].
func get_max_count(item_type):
	return max_stack

## Returns the first empty cell position the [code]item_stack[/code] can fit into.
func get_free_position(item_stack : ItemStack) -> Vector2:
	for i in _cells.size():
		if (
			_cells[i] == null
			&& restricted_to_types[i] != null
			&& restricted_to_types[i].matches(item_stack)
			&& matches_entry_filter(item_stack, Vector2(i, 0))
		):
			return Vector2(i, 0)

	return Vector2(-1, -1)

## Tries to place [code]item_stack[/code] into cell [code]pos[/code]. [br]
## Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]item_stack[/code] if it could not be placed.
func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if restricted_to_types[pos.x] == null || !restricted_to_types[pos.x].matches(item_stack):
		return item_stack

	return super.try_place_stackv(item_stack, pos)
