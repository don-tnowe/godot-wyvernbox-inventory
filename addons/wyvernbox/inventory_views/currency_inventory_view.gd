tool
extends InventoryView

export(Array, Resource) var restricted_to_types := [] setget _set_restricted_to_types


func _set_restricted_to_types(v):
	restricted_to_types = v
	width = v.size()


func _set_grid_width(v):
	width = restricted_to_types.size()
	regenerate_view()


func _ready2():
	width = restricted_to_types.size()
	_set_inventory(CurrencyInventory.new(restricted_to_types))
