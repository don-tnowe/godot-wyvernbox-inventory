class_name GroundItemManager, "res://addons/wyvernbox/icons/ground_item_manager.png"
extends Node

signal item_clicked(item_node)

# File path to autosave into when the scene changes or game is closed.
# Save can also be triggered manually via `save_state`.
# Only supports "user://" paths.
export var autosave_file_path := ""
# Scene with a `GroundItemStackView2D` or `GroundItemStackView3D` root to instantiate when `add_item` gets called.
export var item_scene : PackedScene = load("res://addons/wyvernbox_prefabs/ground_item_stack_view_2d.tscn")
# Items that don't match these `ItemPattern`s or `ItemType`s will be dimmed out.
export(Array, Resource) var view_filter_patterns setget _set_view_filters


func _set_view_filters(v):
	view_filter_patterns = v
	_apply_view_filters()


func _ready():
	add_to_group("ground_item_manager")
	add_to_group("view_filterable")
	connect("child_entered_tree", self, "_on_child_entered_tree")
	load_state(autosave_file_path)


func _exit_tree():
	save_state(autosave_file_path)

# Creates an in-world representation of stack `stack` at global position `global_pos`.
# If `throw_vector` set, the item will also jump landing at position `global_pos + throw_vector`.
# If `throw_vector` not set, item will land a random short distance nearby.
func add_item(stack : ItemStack, global_pos, throw_vector = null):
	var item_node = item_scene.instance()
	item_node.set_stack(stack)
	add_child(item_node)

	if item_node is Node2D:
		item_node.global_position = global_pos

	else:
		item_node.global_translation = global_pos

	if throw_vector == null:
		throw_vector = item_node.get_random_jump_vector()

	item_node.jump_to_pos(global_pos + throw_vector)

# Loads ground items from `array` created via `to_array`.
func load_from_array(array : Array):
	var new_node : Node
	for x in array:
		new_node = item_scene.instance()
		add_child(new_node)
		new_node.skip_spawn_animation()

		new_node.item_type = load(x["type"])
		new_node.item_count = x["count"]
		new_node.item_extra = x["extra"]
		new_node.item_affixes = x.get("name", [null])
		if new_node is Node2D:
			new_node.global_position = x["position"]

		else:
			new_node.global_translation = x["position"]

# Returns all ground items as an array of dictionaries. Useful for serialization.
func to_array():
	var children = get_children()
	var array = []
	array.resize(children.size())
	for i in array.size():
		array[i] = {
			"type" : children[i].item_type.resource_path,
			"count" : children[i].item_count,
			"extra" : children[i].item_extra,
			"name" : children[i].item_affixes,
			"position" : (children[i].global_position if (children[i] is Node2D) else children[i].global_translation)
		}
	
	return array


func _align_labels():
	var nodes = get_children()
	if !Input.is_action_pressed("inventory_less"):
		for x in nodes:
			x.get_node("Label/Label").hide()

		return

	var rects = []
	var screen_rect = get_viewport().get_visible_rect().grow(200)
	rects.resize(nodes.size())

	for i in nodes.size():
		if nodes[i].filter_hidden: continue
		var cur_label_rect = nodes[i].get_node("Label/Label/Rect")
		cur_label_rect.get_parent().hide()
		
		var rect = Rect2(
			nodes[i].global_position.snapped(Vector2(1, cur_label_rect.rect_size.y)),
			cur_label_rect.rect_size
		)
		rect.size.y -= 1
		rect.position -= cur_label_rect.rect_size * Vector2(0.5, 1.5)
		if screen_rect.intersects(rect):
			rect = _move_to_free_space(rect, rects, cur_label_rect.rect_size.y)

		rects[i] = rect
		cur_label_rect.get_parent().show()
		nodes[i].get_node("Label").global_position = (
			rect.position
			+ rect.size * 0.5
			+ Vector2(0, cur_label_rect.rect_size.y)
		)


func _apply_view_filters(stack_index : int = -1):
	if stack_index == -1:
		for i in get_child_count():
			_apply_view_filters(i)

		return

	var all_match := true
	for x in view_filter_patterns:
		if !x.matches(get_child(stack_index).item_stack):
			all_match = false
			break

	get_child(stack_index).filter_hidden = !all_match

# Writes ground items to file `filename`.
# Only `user://` paths are supported.
func save_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var file = File.new()
	var dir = Directory.new()
	if !dir.dir_exists(filename.get_base_dir()):
		dir.make_dir_recursive(filename.get_base_dir())

	file.open(filename, File.WRITE)
	file.store_var(to_array())

# Loads ground items from file `filename`.
# Only `user://` paths are supported.
func load_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var file = File.new()
	var dir = Directory.new()
	if !file.file_exists(filename):
		return

	file.open(filename, File.READ)
	load_from_array(file.get_var())


func _move_to_free_space(rect : Rect2, label_rects : Array, upwards_step : float) -> Rect2:
	var touches_any = true
	while touches_any:
		touches_any = false
		for x in label_rects:
			if x == null: continue
			if x == rect:
				continue
			
			if x.intersects(rect):
				rect.position.y -= upwards_step
				touches_any = true
				break
	
	return rect


func _unhandled_input(event):
	if event.is_echo(): return
	if event.is_action("inventory_less"):
		_align_labels()
		_align_labels()  # Can't figure why it doesn't work the first time


func _on_child_entered_tree(child):
	child.connect("name_clicked", self, "_on_item_clicked", [child])
	call_deferred("_apply_view_filters", child.get_position_in_parent())


func _on_item_clicked(item):
	emit_signal("item_clicked", item)
