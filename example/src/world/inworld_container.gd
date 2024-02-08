extends Node

@export var stored_gui : NodePath = "Inventory"

func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)


func _on_body_entered(body):
	if !body.is_in_group("hero"): return
	get_node("Button").show()
	var _3 = get_node("Button").connect("pressed", body._on_inworld_inv_button_pressed.bind(get_node(stored_gui), name))


func _on_body_exited(body):
	if !body.is_in_group("hero"): return
	get_node("Button").hide()
	get_node("Button").disconnect("pressed", body._on_inworld_inv_button_pressed)
	body.get_node(body.inventory_menu).close_inworld_inventory(get_node(stored_gui))
