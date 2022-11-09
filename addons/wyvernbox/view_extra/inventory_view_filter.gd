class_name InventoryFilter
extends Resource

export var union = true
export var any_bonus = []
export var any_type = []

var always_show = []


func clear():
	any_bonus = []
	any_type = []
	always_show = []


func is_clear():
	return (
		any_bonus.size() == 0
		&& any_type.size() == 0
		&& always_show.size() == 0
	)


func apply(items):
	var result = []
	result.resize(items.size())
	var all_true = is_clear()
	for i in result.size():
		result[i] = all_true || !union
	
	if all_true: return result
	_apply_any_type(items, result)
	_apply_any_bonus(items, result)
	for x in always_show:
		if items.size() > x.index_in_inventory && items[x.index_in_inventory] == x:
			result[x.index_in_inventory] = true

	return result


func _apply_any_type(items, result):
	if any_type.size() == 0: return
	for i in items.size():
		if union == (items[i].item_type in any_type):
			result[i] = union


func _apply_any_bonus(items, result):
	_apply_any_property_filter(items, result, any_bonus, "stats")


func _apply_any_property_filter(items, result, array, item_key):
	if array.size() == 0: return
	var item_props : Dictionary
	for i in items.size():
		if union == result[i]: continue
		item_props = items[i].extra_properties
		if item_props.has(item_key):
			result[i] = _has_any(item_props[item_key], array)

		elif !union: result[i] = false


func _has_any(dict, from):
	for k in from:
		if dict.has(k): return true

	return false
