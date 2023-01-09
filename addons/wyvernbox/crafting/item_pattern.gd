tool
class_name ItemPattern, "res://addons/wyvernbox/icons/item_pattern.png"
extends Resource

export var name := "Insert name or full locale string"
export var texture : Texture

export(Array, Resource) var items = [] setget _set_items
export(Array, float) var efficiency = [] setget _set_efficiency


func _set_items(v):
	items = v
	_update_sizes(v.size())


func _set_efficiency(v):
	efficiency = v
	_update_sizes(v.size())


func _update_sizes(new_size):
	efficiency.resize(max(new_size, 1))
	items.resize(max(new_size, 1))


func _init(items := [], efficiency := []):
	self.efficiency = efficiency
	self.items = items
	if efficiency.size() == 0:
		efficiency.resize(items.size())
		efficiency.fill(1.0)


func matches(item_stack : ItemStack) -> bool:
	if items.size() == 0: return true
	for x in items:
		if x == null || x.matches(item_stack):
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


func collect_item_dict(dict : Dictionary = {}) -> Dictionary:
	if items.size() == 0:
		# Tells Inventory that consume_items() must not check the dict this returns: 
		# this pattern can match all items.
		dict[null] = true
		return dict

	for x in items:
		if x is get_script():
			x.collect_item_dict(dict)

		else:
			dict[x] = true

	return dict
