tool
class_name ItemConversion, "res://addons/wyvernbox/icons/item_conversion.png"
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

# Applies conversion, consuming items from `draw_from_inventories`.
# Set `rng` to define a generator to determine `ItemGenerator` outcomes; if not set, uses global RNG.
# Set `unsafe` to avoid checking if all required items are present.
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

# Returns `true` if all requirements are contained inside `draw_from_inventories`.
func can_apply(draw_from_inventories : Array) -> bool:
	return dict_has_enough(
		count_all_inventories(draw_from_inventories, input_types),
		keys_values_to_dict(input_types, input_counts)
	)

# Returns `true` if all item counts inside `item_counts` are sufficient.
func can_apply_with_items(item_counts : Dictionary) -> bool:
	return dict_has_enough(
		item_counts,
		keys_values_to_dict(input_types, input_counts)
	)

# Sorts `all_inventory_views` by their `auto_take_priority`.
func get_takeable_inventories_sorted(all_inventory_views : Array) -> Array:
	all_inventory_views = get_takeable_inventories(all_inventory_views)
	all_inventory_views.sort_custom(self, "_compare_priorities")
	return all_inventory_views

# Returns the Rich Text representation of this conversion's inputs and outputs.
func get_bbcode(owned_item_counts = {}) -> String:
	var result = "\n[center]" + tr("item_tt_crafting_in")
	var x
	var item_text
	for i in input_types.size():
		x = input_types[i]
		# 4[icon] Red Potion
		item_text = ""
		if x is ItemPattern && x.name == "":
			# 4[icon] Red Potion OR 4[blue potion] OR 4[purple potion] (have 2)
			for pattern_i in x.items.size():
				if item_text != "": item_text += tr("item_tt_items_or")
				item_text += "%s%s %s" % [
					1 / (x.efficiency[pattern_i] * input_counts[i]),
					InventoryTooltip.get_texture_bbcode(x.items[pattern_i].texture.resource_path),
					tr(x.items[pattern_i].name),
				]
		
		else:
			item_text = "%s%s %s" % [
				input_counts[i],
				InventoryTooltip.get_texture_bbcode(x.texture.resource_path),
				tr(x.name),
			]

		# 4[icon] Red Potion (have 2)
		result += "\n%s [color=#%s]%s[/color]" % [
			item_text,
			("ff7f7f" if owned_item_counts.get(x, 0) < input_counts[i] else "ffffff"),
			tr("item_tt_have_items") % str(owned_item_counts.get(x, 0)),
		]
		
	result += "\n\n" + tr("item_tt_crafting_out")
	for i in output_types.size():
		x = output_types[i]
		var out_range = output_ranges[i]
		# 4-6[icon] Red Potion
		result += "\n%s%s%s %s" % [
			out_range.x,
			"-" + str(out_range.y) if out_range.x != out_range.y else "",
			InventoryTooltip.get_texture_bbcode(x.texture.resource_path),
			tr(x.name),
		]
	
	return result

# Counts types and patterns from `items_patterns` inside `inventories`.
static func count_all_inventories(inventories : Array, items_patterns) -> Dictionary:
	var have_total = {}
	var items_to_check = get_items_to_check(items_patterns)
	for x in inventories:
		if x is InventoryView:
			x = x.inventory

		x.count_items(items_patterns, have_total, items_to_check)  # Collects counts into have_total

	return have_total

# Returns `true` if values inside `dict` are no less than values with matching keys in `requirements`.
static func dict_has_enough(dict : Dictionary, requirements : Dictionary) -> bool:
	for k in requirements:
		if !dict.has(k) || dict[k] < requirements[k]:
			return false

	return true

# Returns a copy of `all_inventory_views` without inventories where `InventoryView.InteractionFlags.CAN_TAKE_AUTO` is not set.
static func get_takeable_inventories(all_inventory_views : Array) -> Array:
	var result = []
	for x in all_inventory_views:
		if x.interaction_mode & InventoryView.InteractionFlags.CAN_TAKE_AUTO != 0:
			result.append(x)

	return result

# Constructs a dictionary where keys match `keys` and values match corresponding elements of `values`.
static func keys_values_to_dict(keys : Array, values : Array) -> Dictionary:
	var result = {}
	for i in keys.size():
		result[keys[i]] = values[i]

	return result

# Collects all required items for `Inventory.consume_items`.
static func get_items_to_check(items_patterns) -> Dictionary:
	var dict := {}
	for x in items_patterns:
		if x is ItemType:
			dict[x] = true

		else:
			x.collect_item_dict(dict)

	return dict


static func _compare_priorities(inv_a, inv_b):
	return inv_a.auto_take_priority > inv_b.auto_take_priority
