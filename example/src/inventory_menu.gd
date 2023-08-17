extends Control

@export var tab_icons : Array[Texture2D]

@onready var main_inventory = $"Box/MainInventory".inventory
@onready var ui_inventory := $"CenterContainer/TabContainer/Inworld"
@onready var tabs = ui_inventory.get_parent()


var opened_container


func _ready():
	tabs.set_tab_hidden(0, true)
	tabs.current_tab = 1
	for i in tab_icons.size():
		if tab_icons[i] == null: continue
		tabs.set_tab_icon(i, tab_icons[i])
		tabs.set_tab_title(i, "")


func open_inworld_inventory(inventory_view : InventoryView, inventory_name : String):
	if opened_container != null:
		close_inworld_inventory(opened_container)

	tabs.set_tab_hidden(0, false)
	tabs.current_tab = 0

	var copied_inventory = inventory_view.duplicate()
	ui_inventory.add_child(copied_inventory)
	copied_inventory.name = "Inventory"
	copied_inventory.show()

	ui_inventory.name = inventory_name
	opened_container = inventory_view
	show()


func close_inworld_inventory(inventory_view : InventoryView):
	if opened_container != inventory_view: return

	inventory_view.save_state()
	tabs.set_tab_hidden(0, true)
	if tabs.current_tab == 0:
		tabs.current_tab = 1

	if ui_inventory.has_node("Inventory"):
		ui_inventory.get_node("Inventory").free()

	opened_container = null
