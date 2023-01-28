extends MarginContainer

export var cell_scene : PackedScene
export(Array, Resource) var item_conversions
export var target_inventory := NodePath("")
export var source_inventory := NodePath("")
export var input_from_all_takeable := true
export var just_put_it_into_my_hand := true

onready var recipe_list_node = $"VBoxContainer/ScrollContainer/VBoxContainer"

var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	var _1 = connect("visibility_changed", self, "update_availability")
	var new_btn
	for i in item_conversions.size():
		new_btn = Button.new()
		new_btn.text = item_conversions[i].name
		new_btn.icon = item_conversions[i].output_types[0].texture
		new_btn.expand_icon = true
		new_btn.connect("mouse_entered", self, "_on_button_mouse_entered", [i])
		new_btn.connect("mouse_exited", self, "_on_button_mouse_exited")
		new_btn.connect("pressed", self, "_on_button_pressed", [i])
		recipe_list_node.add_child(new_btn)


func update_availability(_arg0 = null, _arg1 = null, _arg2 = null):
	# Empty args allow signals with parameters to be connected here.
	# I recommend connecting the three "item_stack_*" signals of visible inventories
	if !is_visible_in_tree():
		# If lots of recipes, you wouldn't want to make the CPU busy counting
		# so it instead updates on visibility_changed(), connected in _ready()
		return
	
	var item_counts : Dictionary
	for i in item_conversions.size():
		item_counts = count_all_inventories(item_conversions[i].input_types)
		recipe_list_node.get_child(i).disabled = (
			!item_conversions[i].can_apply_with_items(item_counts)
		)


func _on_button_pressed(index):
	var output_stacks
	if input_from_all_takeable:
		var all_invs = get_tree().get_nodes_in_group("inventory_view")
		var drawable_invs = item_conversions[index].get_takeable_inventories_sorted(all_invs)
		output_stacks = item_conversions[index].apply(
			drawable_invs, rng,
			false
			# true  # If you're feelin' spicy (won't check counts before consuming inputs)
		)

	else:
		output_stacks = item_conversions[index].apply(
			[get_node(source_inventory)], rng, false
		)

	if output_stacks.size() == 0:
		# Crafting failed!
		return

	var inv = get_node(target_inventory).inventory
	var grabbed = get_tree().get_nodes_in_group("grabbed_item")[0]

	if just_put_it_into_my_hand:
		if grabbed.grabbed_stack == null:
			grabbed.grab(output_stacks.pop_front())

		elif grabbed.grabbed_stack.can_stack_with(output_stacks[0]):
			var out_count = output_stacks[0].count
			output_stacks[0].count = grabbed.grabbed_stack.get_overflow_if_added(out_count)
			grabbed.grabbed_stack.count += grabbed.grabbed_stack.get_delta_if_added(out_count)
			if output_stacks[0].count <= 0:
				output_stacks.pop_front()

			grabbed.grab(grabbed.grabbed_stack)

	for x in output_stacks:
		var deposited_count = inv.try_add_item(x)
		if deposited_count < x.count:
			x.count -= deposited_count
			grabbed.drop_on_ground(x)

	update_availability()


func _on_button_mouse_entered(index):
	get_tree().call_group("tooltip", "display_custom",
		recipe_list_node.get_child(index),
		tr(item_conversions[index].name),
		item_conversions[index].get_bbcode(count_all_inventories(item_conversions[index].input_types))
	)


func count_all_inventories(items_patterns) -> Dictionary:
	if !input_from_all_takeable:
		return ItemConversion.count_all_inventories([get_node(source_inventory)], items_patterns)

	var all = get_tree().get_nodes_in_group("inventory_view")
	var drawable = ItemConversion.get_takeable_inventories(all)
	return ItemConversion.count_all_inventories(drawable, items_patterns)


func _on_button_mouse_exited():
	get_tree().call_group("tooltip", "hide")
