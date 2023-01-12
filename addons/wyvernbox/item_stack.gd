class_name ItemStack
extends Reference


var name_with_affixes := []
var count := 1
var index_in_inventory := 1
var position_in_inventory := Vector2.ZERO
var inventory : Reference
var item_type : ItemType
var extra_properties : Dictionary


func _init(item, item_count = 1, item_extra_properties = null):
	item_type = item
	count = item_count
	extra_properties = (
		item_extra_properties
		if item_extra_properties != null && item_extra_properties.size() > 0 else
		item.default_properties.duplicate(true)
	)
	name_with_affixes = extra_properties.get("name", [null])

# Creates a copy of the stack with the specified count.
# Useful for splitting a stack into multiple.
func duplicate_with_count(new_count):
	var new_stack = get_script().new(
		item_type, new_count, extra_properties.duplicate(true)
	)
	new_stack.name_with_affixes = name_with_affixes.duplicate()
	return new_stack

# Returns bottom-right corner of the stack's rect in a `GridInventory`.
func get_bottom_right() -> Vector2:
	return Vector2(
		position_in_inventory.x + item_type.in_inventory_width,
		position_in_inventory.y + item_type.in_inventory_height
	)

# Returns how many items would overflow above `max_stack_count`, if `count_delta` was to be added.
# Returns 0 if everything fits.
func get_overflow_if_added(count_delta) -> int:
	return int(max(count + count_delta - item_type.max_stack_count, 0))

# Returns how many items out of `count_delta` would fit into `max_stack_count`.
# Returns the provided `count_delta` if everything fits, 0 if already full.
func get_delta_if_added(count_delta) -> int:
	return int(min(item_type.max_stack_count - count, count_delta))

# Returns `true` if the stacks have the same type, name and extra properties.
# Disable `compare_extras` to ignore extra properties.
func can_stack_with(stack, compare_extras : bool = true) -> bool:
	return (
		item_type == stack.item_type
		&& arrays_equal(name_with_affixes, stack.name_with_affixes)
		&& (!compare_extras || extras_equal(extra_properties, stack.extra_properties))
	)

# Returns `true` if stacks can be stacked together. See `can_stack_with`.
func matches(stack):
	return can_stack_with(stack)

# Returns the name, with all affixes, translated into current locale.
func get_name() -> String:
	var trd := name_with_affixes.duplicate()
	for i in trd.size():
		if trd[i] != null:
			trd[i] = tr(trd[i])

		else:
			trd[i] = tr(item_type.name)
	
	return " ".join(trd)

# Returns how many items would overflow above `maxcount`, if `added` was to be added.
# Static version of `get_overflow_if_added`.
static func get_stack_overflow_if_added(count, added, maxcount) -> int:
	return int(max(count + added - maxcount, 0))

# Returns how many items out of `added` would fit into `maxcount`.
# Static version of `get_delta_if_added`.
static func get_stack_delta_if_added(count, added, maxcount) -> int:
	return int(min(maxcount - count, added))

# Returns `true` if dictionaries are equal.
static func extras_equal(a : Dictionary, b : Dictionary) -> bool:
	if a.size() != b.size(): return false
	for k in a:
		if !b.has(k): return false
		if (
			a[k] != b[k]
			&& (!a[k] is Dictionary || !extras_equal(a[k], b[k]))
			&& (!a[k] is Array || !arrays_equal(a[k], b[k]))
		):
			return false

	return true

# Returns `true` if arrays are equal.
static func arrays_equal(a : Array, b : Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if (
			a[i] != b[i]
			&& (!a[i] is Dictionary || !extras_equal(a[i], b[i]))
			&& (!a[i] is Array || !arrays_equal(a[i], b[i]))
		):
			return false

	return true

# Creates a new `ItemStack` from a dictionary obtained via `to_dict`.
static func new_from_dict(dict):
	var new_item = load("res://addons/wyvernbox/item_stack.gd").new(
		load(dict["type"]),
		dict["count"],
		dict["extra"]
	)
	new_item.name_with_affixes = dict.get("name", [null])
	new_item.position_in_inventory = dict.get("position", Vector2(-1, -1))
	return new_item

# Returns a dictionary representation of this `ItemStack`. Useful for serialization.
func to_dict():
	return {
		"type" : item_type.resource_path,
		"count" : count,
		"extra" : extra_properties,
		"name" : name_with_affixes,
		"position" : position_in_inventory,
	}


func _to_string():
	return (
		get_name()
		+ "\nCount: " + str(count)
		+ ", Data: \n" + str(extra_properties)
		+ "\n"
	)
