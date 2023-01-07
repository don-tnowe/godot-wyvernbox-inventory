class_name CurrencyInventory
extends Inventory

var restricted_to_types := []
var max_stack := 99999999


func _init(restriction_array, max_stack_count = 99999999).(restriction_array.size(), 1):
	restricted_to_types = restriction_array
	max_stack = max_stack_count


func get_max_count(item_type):
	return max_stack


func _get_free_position(item_stack : ItemStack) -> Vector2:
	for i in _cells.size():
		if _cells[i] == null && restricted_to_types[i] != null && restricted_to_types[i].matches(item_stack):
			return Vector2(i, 0)

	return Vector2(-1, -1)


func try_place_stackv(item_stack : ItemStack, pos : Vector2) -> ItemStack:
	if restricted_to_types[pos.x] != item_stack.item_type:
		return item_stack
	
	return .try_place_stackv(item_stack, pos)
