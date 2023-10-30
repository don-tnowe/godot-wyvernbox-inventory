@tool
@icon("res://addons/wyvernbox/icons/item_conversion.png")
class_name ItemConversion
extends Resource

## Describes a list of inputs and a list of outputs. Can draw items from an array of inventories to apply the conversion.
##
## You can utilize [ItemPattern]s to allow several input item types or match for specific rules, and [ItemGenerator]s to randomize the output or process the input.

## Name of the conversion displayed in tooltips. Can be a locale string.
@export var name := "Insert name or full locale string"
## Tags, for any purpose.
@export var tags : Array[StringName]
## The input [ItemType]s or [ItemPattern]s.
@export var input_types : Array[Resource]:
	set = _set_input_types
## The required count of input [ItemType]s or [ItemPattern]s.
@export var input_counts : Array[int]:
	set = _set_input_counts
## The output [ItemType]s or [ItemGenerator]s.
@export var output_types : Array[Resource]:
	set = _set_output_types
## The minimum and maximum counts of output [ItemType]s or [ItemGenerator]s.
@export var output_ranges : Array[Vector2]:
	set = _set_output_ranges


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

## Applies conversion, consuming items from [code]draw_from_inventories[/code]. [br]
## Set [code]rng[/code] to define a generator to determine [ItemGenerator] outcomes; if not set, uses global RNG. [br]
## Set [code]unsafe[/code] to avoid checking if all required items are present.
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

## Returns [code]true[/code] if all requirements are contained inside [code]draw_from_inventories[/code].
func can_apply(draw_from_inventories : Array) -> bool:
	return dict_has_enough(
		count_all_inventories(draw_from_inventories, input_types),
		keys_values_to_dict(input_types, input_counts)
	)

## Returns [code]true[/code] if all item counts inside [code]item_counts[/code] are sufficient.
func can_apply_with_items(item_counts : Dictionary) -> bool:
	return dict_has_enough(
		item_counts,
		keys_values_to_dict(input_types, input_counts)
	)

## Sorts [code]all_inventory_views[/code] by their [member InventoryView.auto_take_priority].
func get_takeable_inventories_sorted(all_inventory_views : Array) -> Array:
	all_inventory_views = get_takeable_inventories(all_inventory_views)
	all_inventory_views.sort_custom(_compare_priorities)
	return all_inventory_views

## Returns the Rich Text representation of this conversion's inputs and outputs. [br]
## [code]owned_item_counts[/code], optional, is a dictionary of [ItemType] to [int], shown next to requirement counts. [br]
## [code]*_label[/code] parameters are the labels for input items, output items, the "or" connector if several inputs are possible, and the label for the amount of an item already owned, in that order.
func get_bbcode(
  owned_item_counts := {},
  inputs_label := "[b]Requires:[/b]",
  outputs_label := "[b]Gives:[/b]",
  input_or_label := " or ",
  owned_label := "(have %s)",
) -> String:
	var result = "\n[center]" + inputs_label
	var x
	var item_text
	for i in input_types.size():
		x = input_types[i]
		## 4[icon] Red Potion
		item_text = ""
		if x is ItemPattern && x.name == "":
			## 4[icon] Red Potion OR 4[blue potion] OR 4[purple potion] (have 2)
			for pattern_i in x.items.size():
				if item_text != "": item_text += input_or_label
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

		## 4[icon] Red Potion (have 2)
		result += "\n%s [color=#%s]%s[/color]" % [
			item_text,
			("ff7f7f" if owned_item_counts.get(x, 0) < input_counts[i] else "ffffff"),
			owned_label % str(owned_item_counts.get(x, 0)),
		]
		
	result += "\n\n" + outputs_label
	for i in output_types.size():
		x = output_types[i]
		var out_range = output_ranges[i]
		## 4-6[icon] Red Potion
		result += "\n%s%s%s %s" % [
			out_range.x,
			"-" + str(out_range.y) if out_range.x != out_range.y else "",
			InventoryTooltip.get_texture_bbcode(x.texture.resource_path),
			tr(x.name),
		]
	
	return result

## Must return settings for displays of item lists. Override to change behaviour, or add to your own class. [br]
## The returned arrays must contain: [br]
## - Property editor label : String [br]
## - Array properties edited : Array[String] (the resource array must be first; the folowing props skip the resource array) [br]
## - Column labels : Array[String] (each vector array must have two/three) [br]
## - Columns are integer? : bool (each vector array maps to one) [br]
## - Column default values : Variant [br]
## - Allowed resource types : Array[Script or Classname] [br]
func _get_wyvernbox_item_lists() -> Array:
	return [
		[
			"Inputs", ["input_types", "input_counts"],
			["Count"], [true], [1],
			[ItemType, ItemPattern], ["ItemType", "ItemPattern"],
		],
		[
			"Outputs", ["output_types", "output_ranges"],
			["Min", "Max"], [true], [Vector2(1, 1)],
			[ItemType, ItemGenerator], ["ItemType", "ItemGenerator"],
		],
	]

## Counts types and patterns from [code]items_patterns[/code] inside [code]inventories[/code].
static func count_all_inventories(inventories : Array, items_patterns) -> Dictionary:
	var have_total = {}
	var items_to_check = get_items_to_check(items_patterns)
	for x in inventories:
		if x is InventoryView:
			x = x.inventory

		x.count_items(items_patterns, have_total, items_to_check)  # Collects counts into have_total

	return have_total

## Returns [code]true[/code] if values inside [code]dict[/code] are no less than values with matching keys in [code]requirements[/code].
static func dict_has_enough(dict : Dictionary, requirements : Dictionary) -> bool:
	for k in requirements:
		if !dict.has(k) || dict[k] < requirements[k]:
			return false

	return true

## Returns a copy of [code]all_inventory_views[/code] without inventories where [code]InventoryView.InteractionFlags.CAN_TAKE_AUTO[/code] is not set.
static func get_takeable_inventories(all_inventory_views : Array) -> Array:
	var result = []
	for x in all_inventory_views:
		if x.interaction_mode & InventoryView.InteractionFlags.CAN_TAKE_AUTO != 0:
			result.append(x)

	return result

## Constructs a dictionary where keys match [code]keys[/code] and values match corresponding elements of [code]values[/code].
static func keys_values_to_dict(keys : Array, values : Array) -> Dictionary:
	var result = {}
	for i in keys.size():
		result[keys[i]] = values[i]

	return result

## Collects all required items for [method Inventory.consume_items].
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
