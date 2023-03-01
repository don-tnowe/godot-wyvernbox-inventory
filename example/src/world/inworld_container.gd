extends Node


func _ready():
	assert(has_node("Inventory"), "Inworld Containers require an InventoryView child named Inventory!")

	var _1 = connect("body_entered", self, "_on_body_entered")
	var _2 = connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body):
	if !body.is_in_group("hero"): return
	get_node("Button").show()
	var _3 = get_node("Button").connect("pressed", body, "_on_inworld_inv_button_pressed", [get_node("Inventory"), name])


func _on_body_exited(body):
	if !body.is_in_group("hero"): return
	get_node("Button").hide()
	get_node("Button").disconnect("pressed", body, "_on_inworld_inv_button_pressed")
	body.get_node(body.inventory_menu).close_inworld_inventory(get_node("Inventory"))
