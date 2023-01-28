extends Control

export(Array, Texture) var tab_icons

onready var inventory = $"Box/MainInventory".inventory
onready var inworld_inventory_container := $"CenterContainer/TabContainer/Inworld"


var opened_inventory_view : Control


func _ready():
	var tabs = inworld_inventory_container.get_parent()
	tabs.set_tab_hidden(0, true)
	for i in tab_icons.size():
		if tab_icons[i] == null: continue
		tabs.set_tab_icon(i, tab_icons[i])
		tabs.set_tab_title(i, "")


func open_inworld_inventory(inventory_view : InventoryView, name : String):
	if opened_inventory_view != null:
		close_inworld_inventory(opened_inventory_view)

	var tabs = inworld_inventory_container.get_parent()
	tabs.set_tab_hidden(0, false)
	tabs.current_tab = 0

	inworld_inventory_container.get_child(0).inventory = inventory_view.inventory
	inworld_inventory_container.name = name
	opened_inventory_view = inventory_view
	show()


func close_inworld_inventory(inventory_view : InventoryView):
	if opened_inventory_view != inventory_view: return

	var tabs = inworld_inventory_container.get_parent()
	tabs.set_tab_hidden(0, true)
	if tabs.current_tab == 0:
		tabs.current_tab = 1

	# inworld_inventory_container.get_child(0).queue_free()
	opened_inventory_view = null
