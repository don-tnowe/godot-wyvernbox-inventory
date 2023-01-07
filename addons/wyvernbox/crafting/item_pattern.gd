tool
class_name ItemPattern
extends Resource

export var name := "Insert name or full locale string"
export var texture : Texture

export(Array, Resource) var items = [] setget _set_items
export(Array, float) var efficiency = [] setget _set_efficiency


func _set_items(v):
	items = v
	_update_items(v.size())


func _set_efficiency(v):
	efficiency = v
	_update_items(v.size())


func _update_items(new_size):
	efficiency.resize(max(new_size, 1))
	items.resize(max(new_size, 1))


func matches(item_stack : ItemStack) -> bool:
	for x in items:
		if x.matches(item_stack):
			return true

	return false


func get_value(of_stack : ItemStack) -> float:
	var found_at = -1
	for i in items.size():
		if items[i].matches(of_stack):
			found_at = i
			break

	if found_at == -1: return 0.0
	return efficiency[found_at] * of_stack.count
