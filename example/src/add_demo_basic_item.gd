extends Button


export(Array, Resource) var possible_items
export var inventory_path := NodePath("../../Inventory")


func _ready():
	randomize()


func get_random_item():
	var new_item = get_random_from_array(possible_items)
	return ItemStack.new(
		new_item,
		randi() % (new_item.max_stack_count / 4 + 1) + 1
	)


func get_random_from_array(arr):
	return arr[randi() % arr.size()]
