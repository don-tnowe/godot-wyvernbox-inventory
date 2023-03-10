tool
class_name RestrictedInventoryView, "res://addons/wyvernbox/icons/restricted_inventory.png"
extends InventoryView

# If set and inventory full, quick-transferring into here will shift all items by one cell.
export var allow_rotation := true setget _set_allow_rotation

# Each cell's [member ItemType.slot_flags]. Items that don't match won't fit in.
export(Array, ItemType.SlotFlags) var restricted_to_types := [] setget _set_restricted_to_types


func _set_restricted_to_types(v):
	restricted_to_types = v
	_regenerate_view()


func _set_allow_rotation(v):
	allow_rotation = v
	if is_inside_tree():
		inventory.allow_rotation = v


func _ready2():
	_set_inventory(RestrictedInventory.new(restricted_to_types))
	inventory.allow_rotation = allow_rotation
