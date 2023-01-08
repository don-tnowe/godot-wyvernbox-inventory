tool
class_name RestrictedInventoryView, "res://addons/wyvernbox/icons/restricted_inventory.png"
extends InventoryView

export var allow_rotation := true setget _set_allow_rotation
export(Array, ItemType.SlotFlags) var restricted_to_types := [] setget _set_restricted_to_types


func _set_restricted_to_types(v):
	restricted_to_types = v
	width = v.size()


func _set_grid_width(v):
	width = restricted_to_types.size()
	regenerate_view()


func _set_allow_rotation(v):
	allow_rotation = v
	if is_inside_tree():
		inventory.allow_rotation = v


func _ready2():
	width = restricted_to_types.size()
	_set_inventory(RestrictedInventory.new(restricted_to_types))
	inventory.allow_rotation = allow_rotation
