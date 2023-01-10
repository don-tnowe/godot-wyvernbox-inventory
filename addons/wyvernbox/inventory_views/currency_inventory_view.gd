tool
class_name CurrencyInventoryView, "res://addons/wyvernbox/icons/currency_inventory.png"
extends InventoryView

export(Array, Resource) var restricted_to_types := [] setget _set_restricted_to_types
export var max_stack := 99999999


func _set_restricted_to_types(v):
	restricted_to_types = v
	regenerate_view()


func _ready2():
	_set_inventory(CurrencyInventory.new(restricted_to_types, max_stack))
