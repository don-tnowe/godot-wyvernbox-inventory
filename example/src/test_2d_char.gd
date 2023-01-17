extends KinematicBody2D

export var movespeed := 128.0
export var generator : Resource

export var inventory_menu := NodePath()
export var inventory_view := NodePath()
export var inventory_tooltip := NodePath()
export var ground_items := NodePath()

var _mouse_pressed := false


func _physics_process(delta):
	if _mouse_pressed:
		move_and_slide(get_local_mouse_position().normalized() * movespeed)

	else:
		var input_vec = Input.get_vector(
			"ui_left", "ui_right",
			"ui_up", "ui_down"
		) + Input.get_vector(
			"move_left", "move_right",
			"move_up", "move_down"
		)
		move_and_slide(input_vec.limit_length(1.0) * movespeed)


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
			item_manager.add_item(x, global_position)


func _on_ItemPickup_area_entered(area : Area2D):
	if area.is_in_group("ground_item") && !area.filter_hidden:
		# Inventory? Inventory. Don't hard-code paths, kids.
#		area.try_pickup($"../../../Inventory/Inventory/Inventory".inventory)
		area.try_pickup(get_node(inventory_view).inventory)

	if area.is_in_group("touch_loot"):
		var item_init = area.get_node("ItemInit")
		item_init.activate()
		item_init.escape_deletion(area)
		area.queue_free()
