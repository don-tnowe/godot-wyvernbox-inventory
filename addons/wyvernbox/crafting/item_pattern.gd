tool
class_name ItemPattern, "res://addons/wyvernbox/icons/item_pattern.png"
extends Resource

# Name of the pattern displayed in tooltips. Can be a locale string.
export var name := ""
# The pattern's icon displayed in tooltips.
export var texture : Texture

# The `ItemType`s or `ItemPattern`s this pattern matches.
export(Array, Resource) var items = [] setget _set_items
# How many items in an `ItemConversion` each item or pattern contributes.
# Higher values means you would need less of an item.
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

# Returns `true` if `item_stack` present in `items`.
# Override to define special item patterns that match stacks with specific properties.
func matches(item_stack : ItemStack) -> bool:
	if items.size() == 0: return true
	for x in items:
		if x == null || x.matches(item_stack):
			return true

	return false

# Returns `efficiency` for the stack's type, or first pattern that matches it. Multiplied by stack's count.
# Used to define how many of an item is needed to fulfill an `ItemConversion`'s requirement.
# Override to define special item patterns that define value based on specific properties..
func get_value(of_stack : ItemStack) -> float:
	var found_at = -1
	for i in items.size():
		if items[i].matches(of_stack):
			found_at = i
			break

	if found_at == -1: return 0.0
	return efficiency[found_at] * of_stack.count

# Collects all item types that can ever be matched by this pattern. Used in `Inventory.consume_items`.
# Add a `null` key if this pattern can match ANY item. This, however, can make conversion with this run slower.
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
