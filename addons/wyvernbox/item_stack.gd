class_name ItemStack
extends Reference

# Array containing all affixes of this `ItemStack`. Can be locale strings.
# A `null` value will be replaced by the `ItemType's name.
var name_with_affixes := []
# How many item are in this stack. To set, prefer `Inventory.add_items_to_stack`.
var count := 1
# The stack's index in the `Inventory.items` array of its `inventory`. Should not be set externally.
var index_in_inventory := 1
# The item's cell position. To set, prefer `InventoryView.try_place_stackv` or `Inventory.try_place_stackv`.
var position_in_inventory := Vector2.ZERO
# The `Inventory` this stack currently resides in. Should not be set externally.
var inventory : Reference
# The item's `ItemType`.
var item_type : ItemType
# The item's extra property dictionary.
# Can contain various data for display in `InventoryTooltip` via its `InventoryTooltipProperty`, or other, game-specific uses.
# `price` is used for vendor prices, selling and buying.
# `back_color` is used to show a colored background in inventories and a glow on the ground.
var extra_properties : Dictionary

# Creates an `ItemStack` with `item_count` items of type `item_type`.
# If the `item_extra_properties` dictionary is not set, copies `item_type`'s `ItemType.default_properties`.
func _init(item_type, item_count = 1, item_extra_properties = null):
	self.item_type = item_type
	count = item_count
	extra_properties = (
		item_extra_properties
		if item_extra_properties != null && item_extra_properties.size() > 0 else
		item_type.default_properties.duplicate(true)
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
