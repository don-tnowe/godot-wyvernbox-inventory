extends CharacterBody2D

@export var movespeed := 128.0
@export var generator : Resource

@export var inventory_menu := NodePath()
@export var inventory_tooltip := NodePath()
@export var ground_items := NodePath()

var _mouse_pressed := false


func _physics_process(_delta):
	if _mouse_pressed:
		set_velocity(get_local_mouse_position().normalized() * movespeed)
		move_and_slide()
		var _new_velocity = velocity

	else:
		var input_vec = Input.get_vector(
			&"ui_left", &"ui_right",
			&"ui_up", &"ui_down"
		) + Input.get_vector(
			&"move_left", &"move_right",
			&"move_up", &"move_down"
		)
		set_velocity(input_vec.limit_length(1.0) * movespeed)
		move_and_slide()
		var _new_velocity = velocity


func _unhandled_input(event):
	if event is InputEventMouseButton:
		_mouse_pressed = event.is_pressed()

	if event.is_action(&"ui_cancel") && event.is_pressed():
		get_node(inventory_menu).hide()

	if event.is_action(&"menu_inventory") && event.is_pressed():
		get_node(inventory_menu).visible = !get_node(inventory_menu).visible
		get_node(inventory_tooltip).visible = false


func _on_Generator_pressed():
	var item_manager = get_node(ground_items)
	for i in 8:
		for x in generator.get_items():
			item_manager.add_item(x, global_position)


func _on_ItemPickup_area_entered(area : Area2D):
	if area.is_in_group(&"ground_item") && !area.filter_hidden:
		# Inventory? Inventory. Don't hard-code paths, kids.
#		area.try_pickup($"../../../Inventory/Inventory/Inventory".inventory)
		area.try_pickup(get_node(inventory_menu).main_inventory)


func _on_inworld_inv_button_pressed(inventory_view, inventory_name):
		get_node(inventory_menu).open_inworld_inventory(inventory_view, inventory_name)


func _on_items_item_clicked(item_node : Node):
	_on_ItemPickup_area_entered(item_node)
