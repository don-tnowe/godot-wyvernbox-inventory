@tool
@icon("res://addons/wyvernbox/icons/item_pattern.png")
class_name ItemPattern
extends ItemLike

## Name of the pattern displayed in tooltips. Can be a locale string.
@export var name := ""
## The pattern's icon displayed in tooltips.
@export var texture : Texture2D

## The ItemTypes or ItemPatterns this pattern matches.
@export var items : Array[ItemLike] = []: set = _set_items

## How many items in an ItemConversion each item or pattern contributes.
## Higher values means you would need less of an item.
@export var efficiency : Array[float] = []: set = _set_efficiency


func _set_items(v):
	items = v
	_update_sizes(v.size())


func _set_efficiency(v):
	efficiency = v
	_update_sizes(v.size())


func _update_sizes(new_size):
	efficiency.resize(max(new_size, 1))
	items.resize(max(new_size, 1))


func _init(items_ := [], efficiency_ := []):
	efficiency = []
	for x in efficiency_: efficiency.append(x)
	items = []
	for x in items_: items.append(x)
	if efficiency.size() == 0:
		efficiency.resize(items.size())
		efficiency.fill(1.0)

## Returns [code]true[/code] if [code]item_stack[/code] present in [member items].
## Override to define special item patterns that match stacks with specific properties.
func matches(item_stack : ItemStack) -> bool:
	if items.size() == 0: return true
	for x in items:
		if x == null || x.matches(item_stack):
			return true

	return false

## Returns [member efficiency] for the stack's type, or first pattern that matches it. Multiplied by stack's count.
## Used to define how many of an item is needed to fulfill an [ItemConversion]'s requirement.
## Override to define special item patterns that define value based on specific properties..
func get_value(of_stack : ItemStack) -> float:
	var found_at = -1
	for i in items.size():
		if items[i].matches(of_stack):
			found_at = i
			break

	if found_at == -1: return 0.0
	return efficiency[found_at] * of_stack.count

## Collects all item types that can ever be matched by this pattern. Used in [method Inventory.consume_items].
## Add a [code]null[/code] key if this pattern can match ANY item. This, however, can make conversion with this run slower.
func collect_item_dict(dict : Dictionary = {}) -> Dictionary:
	if items.size() == 0:
		## Tells Inventory that consume_items() must not check the dict this returns: 
		## this pattern can match all items.
		dict[null] = true
		return dict

	for x in items:
		if x is ItemPattern:
			x.collect_item_dict(dict)

		else:
			dict[x] = true

	return dict

## Must return settings for displays of item lists. Override to change behaviour, or add to your own class.
## The returned arrays must contain:
## - Property editor label : String
## - Array properties edited : Array[String] (the resource array must be first; the folowing props skip the resource array)
## - Column labels : Array[String] (each vector array must have two/three)
## - Columns are integer? : bool (each vector array maps to one)
## - Column default values : Variant
## - Allowed resource types : Array[Script or Classname]
func _get_wyvernbox_item_lists() -> Array:
	return [[
		"Matches", ["items", "efficiency"],
		["Efficiency"], [false], [1],
		[ItemType, load("res://addons/wyvernbox/crafting/item_pattern.gd")]
	]]
