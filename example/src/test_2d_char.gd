extends KinematicBody2D

export var movespeed := 128.0
export var spawn_item : PackedScene
export var generator : Resource

export var inventory_menu := NodePath()
export var inventory_view := NodePath()
export var inventory_tooltip := NodePath()

var _mouse_pressed := false


func _physics_process(delta):
	if _mouse_pressed:
		move_and_slide(get_local_mouse_position().normalized() * movespeed)

	else:
		move_and_slide(Input.get_vector(
			"ui_left", "ui_right",
			"ui_up", "ui_down"
		) * movespeed)


func _ready():
	get_node(inventory_menu).hide()


func _unhandled_input(event):
	if event is InputEventMouseButton:
		_mouse_pressed = event.is_pressed()

	if event.is_action("menu_inventory") && event.is_pressed():
		get_node(inventory_menu).visible = !get_node(inventory_menu).visible
		get_node(inventory_tooltip).visible = false


func _on_Generator_pressed():
	for i in 8:
		var new_node = spawn_item.instance()
		new_node.set_stack(generator.get_item())
		new_node.position = position
		new_node.connect("name_clicked", self, "_on_ItemPickup_area_entered", [new_node])
		$"../Items".add_child(new_node)


func _on_ItemPickup_area_entered(area : Area2D):
	if area.is_in_group("ground_item"):
		# Inventory? Inventory. Don't hard-code paths, kids.
#		area.try_pickup($"../../../Inventory/Inventory/Inventory".inventory)
		area.try_pickup(get_node(inventory_view).inventory)
