extends KinematicBody

export var movespeed := 128.0
export var generator : Resource

export var inventory_menu := NodePath()
export var inventory_tooltip := NodePath()
export var ground_items := NodePath()

var _mouse_pressed := false


func _physics_process(_delta):
	var input_vec = Input.get_vector(
		"ui_left", "ui_right",
		"ui_up", "ui_down"
	) + Input.get_vector(
		"move_left", "move_right",
		"move_up", "move_down"
	)
	var horizontal_move = input_vec.limit_length(1.0) * movespeed
	var _new_velocity = move_and_slide(Vector3(horizontal_move.x, 0, horizontal_move.y), Vector3.UP)


func _ready():
	get_node(inventory_menu).hide()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		_mouse_pressed = event.is_pressed()

	if event.is_action("ui_cancel") && event.is_pressed():
		get_node(inventory_menu).hide()

	if event.is_action("menu_inventory") && event.is_pressed():
		get_node(inventory_menu).visible = !get_node(inventory_menu).visible
		get_node(inventory_tooltip).visible = false


func _on_Generator_pressed():
	var item_manager = get_node(ground_items)
	for i in 8:
		for x in generator.get_items():
			item_manager.add_item(x, global_translation + Vector3(0, 0.5, 0))


func _on_ItemPickup_area_entered(area):
	if area.is_in_group("ground_item") && !area.filter_hidden:
		# Inventory? Inventory. Don't hard-code paths, kids.
#		area.try_pickup($"../../../Inventory/Inventory/Inventory".inventory)
		area.try_pickup(get_node(inventory_menu).main_inventory)


func _on_inworld_inv_button_pressed(inventory_view, name):
		get_node(inventory_menu).open_inworld_inventory(inventory_view, name)
