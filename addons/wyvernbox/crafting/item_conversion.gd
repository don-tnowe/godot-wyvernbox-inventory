tool
class_name ItemConversion
extends Resource

export var name := "Insert name or full locale string"
export(Array, Resource) var input_types setget _set_input_types
export(Array, int) var input_counts setget _set_input_counts
export(Array, Resource) var output_types setget _set_output_types
export(Array, Vector2) var output_ranges setget _set_output_ranges


func _set_input_types(v):
	input_types = v
	input_counts.resize(v.size())


func _set_input_counts(v):
	input_counts = v
	input_types.resize(v.size())


func _set_output_types(v):
	output_types = v
	output_ranges.resize(v.size())


func _set_output_ranges(v):
	output_ranges = v
	output_types.resize(v.size())


func apply(draw_from_inventories : Array, rng : RandomNumberGenerator = null, unsafe : bool = false) -> Array:
	if !unsafe && !can_apply(draw_from_inventories):
		return []

	var consumed_stacks = []
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var items_to_check = get_items_to_check(input_types)
	var left_to_draw = keys_values_to_dict(input_types, input_counts)
	for x in draw_from_inventories:
		if x is InventoryView:
			x = x.inventory

		consumed_stacks.append_array(x.consume_items(left_to_draw, false, items_to_check))

	var results = []
	for i in output_types.size():
		if output_types[i] is ItemType:
			results.append(ItemStack.new(
				output_types[i],
				int(rng.randf_range(output_ranges[i].x, output_ranges[i].y)),
				output_types[i].default_properties.duplicate(true)
			))

		elif output_types[i] is ItemGenerator:
			results.append_array(output_types[i].get_items(rng, consumed_stacks, input_types))

	return results


func can_apply(draw_from_inventories : Array) -> bool:
	return dict_has_enough(
		count_all_inventories(draw_from_inventories, input_types),
		keys_values_to_dict(input_types, input_counts)
	)


func can_apply_with_items(item_counts : Dictionary) -> bool:
	return dict_has_enough(
		item_counts,
		keys_values_to_dict(input_types, input_counts)
	)


func get_inputs_as_dict():
	return keys_values_to_dict(input_types, input_counts)


static func count_all_inventories(inventories : Array, items_patterns) -> Dictionary:
	var have_total = {}
	var items_to_check = get_items_to_check(items_patterns)
	for x in inventories:
		if x is InventoryView:
			x = x.inventory

		x.count_items(items_patterns, have_total, items_to_check)  # Collects counts into have_total

	return have_total
	

static func dict_has_enough(dict : Dictionary, requirements : Dictionary) -> bool:
	for k in requirements:
		if !dict.has(k) || dict[k] < requirements[k]:
			return false

	return true


static func get_drawable_inventories(all_inventory_views : Array) -> Array:
	var result = []
	for x in all_inventory_views:
		if x.interaction_mode & InventoryView.InteractionFlags.CAN_TAKE_AUTO != 0:
			result.append(x)

	return result


static func keys_values_to_dict(keys : Array, values : Array) -> Dictionary:
	var result = {}
	for i in keys.size():
		result[keys[i]] = values[i]

	return result


static func get_items_to_check(items_patterns) -> Dictionary:
	var dict := {}
	for x in items_patterns:
		if x is ItemType:
			dict[x] = true

		else:
			x.collect_item_dict(dict)

	return dict
