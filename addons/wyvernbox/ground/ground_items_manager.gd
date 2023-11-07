@icon("res://addons/wyvernbox/icons/ground_item_manager.png")
class_name GroundItemManager
extends Node

## Manages [ItemStack]s on the ground. Use its methods to create and pick up items into your inventory.

signal item_clicked(item_node)

## File path to autosave into when the scene changes or game is closed. [br]
## Save can also be triggered manually via [method save_state]. [br]
## Only supports "user://" paths.
@export var autosave_file_path := ""

## Scene with a [GroundItemStackView2D] or [GroundItemStackView3D] root to instantiate when [method add_item] gets called.
@export var item_scene : PackedScene = load("res://addons/wyvernbox_prefabs/ground_item_stack_view_2d.tscn")

## Items that don't match these ItemPatterns or ItemTypes will be dimmed out.
@export var view_filter_patterns : Array:
	set = _set_view_filters

## Defines min and max distance items jump with unset [code]throw_vector[/code].
@export var spawn_jump_length_range := Vector2(48.0, 96.0)

## Defines upwards velocity for 3D physics items, or arc height for non-physics items. Unused in 2D.
@export var spawn_jump_upwards := 1.0


func _set_view_filters(v):
	view_filter_patterns = v
	_apply_view_filters()


func _ready():
	add_to_group("ground_item_manager")
	add_to_group("view_filterable")
	child_entered_tree.connect(_on_child_entered_tree)
	load_state(autosave_file_path)


func _exit_tree():
	save_state(autosave_file_path)

## Creates an in-world representation of stack [code]stack[/code] at global position [code]global_pos[/code]. [br]
## If [code]throw_vector[/code] set, the item will also jump landing at position [code]global_pos + throw_vector[/code]. [br]
## If [code]throw_vector[/code] not set, item will land a random short distance nearby.
func add_item(stack : ItemStack, global_pos, throw_vector = null):
	var item_node = item_scene.instantiate()
	item_node.item_stack = stack
	add_child(item_node)

	if item_node is Node2D:
		item_node.global_position = global_pos

	else:
		item_node.global_position = global_pos

	if throw_vector == null:
		throw_vector = item_node.get_random_jump_vector(spawn_jump_length_range.x, spawn_jump_length_range.y)

	item_node.jump_to_pos(global_pos + throw_vector, spawn_jump_upwards)

## Loads ground items from [code]array[/code] created via [method to_array].
func load_from_array(array : Array):
	var new_node : Node
	for x in get_children(): x.free()
	for x in array:
		new_node = item_scene.instantiate()
		add_child(new_node)
		new_node.skip_spawn_animation()

		var new_stack := ItemStack.new_from_dict(x)
		new_node.item_stack = new_stack
		new_node.position = x[&"position"]

## Returns all ground items as an array of dictionaries. Useful for serialization.
func to_array():
	var children = get_children()
	var array = []
	array.resize(children.size())
	for i in array.size():
		var cur_stack : ItemStack = children[i].item_stack
		array[i] = {
			&"type" : cur_stack.item_type.resource_path,
			&"count" : cur_stack.count,
			&"extra" : cur_stack.extra_properties,
			&"name" : [cur_stack.name_prefixes, cur_stack.name_override, cur_stack.name_suffixes],
			&"position" : children[i].position,
		}
	
	return array


func _align_labels():
	var nodes = get_children()
	if nodes.size() == 0: return
	if !Input.is_action_pressed(&"inventory_less"):
		for x in nodes:
			x.set_label_visible(false)

		return

	## TODO: 3D needs special care: camera moves all the time so overlap detection must be optimized
	## (also 3D labels look abhorrent, must separate them all on a shared UI layer so they can be moved in screen space)
	if nodes[0] is Node3D:
		for x in nodes: x.set_label_visible(true)
		return

	var rects = []
	var screen_rect = get_viewport().get_visible_rect().grow(200)
	rects.resize(nodes.size())

	for i in nodes.size():
		if nodes[i].filter_hidden: continue
		var cur_label_rect = nodes[i].get_label_rect()
		nodes[i].set_label_visible(false)

		var rect = Rect2(
			nodes[i].global_position.snapped(Vector2(1, cur_label_rect.size.y)),
			cur_label_rect.size
		)
		rect.size.y -= 1
		rect.position -= cur_label_rect.size * Vector2(0.5, 1.5)

		if screen_rect.intersects(rect):
			rect = _move_to_free_space(rect, rects, cur_label_rect.size.y)

		rects[i] = rect
		nodes[i].set_label_visible(true)
		nodes[i].get_node("Label").global_position = (
			rect.position
			+ rect.size * 0.5
			+ Vector2(0, cur_label_rect.size.y)
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

## Writes ground items to file [code]filename[/code]. [br]
## Only [code]user://[/code] paths are supported.
func save_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var filename_dir = filename.get_base_dir()
	if DirAccess.open(filename_dir) == null:
		DirAccess.make_dir_recursive_absolute(filename_dir)

	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_var(to_array())

## Loads ground items from file [code]filename[/code]. [br]
## Only [code]user://[/code] paths are supported.
func load_state(filename):
	if filename == "": return
	filename = "user://" + filename.trim_prefix("user://")

	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		return

	file.open(filename, FileAccess.READ)
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
	if event.is_action(&"inventory_less"):
		_align_labels()
		_align_labels()  ## Can't figure why it doesn't work the first time


func _on_child_entered_tree(child):
	child.clicked.connect(_on_item_clicked.bind(child))
	_apply_view_filters.call_deferred(child.get_index())


func _on_item_clicked(item):
	item_clicked.emit(item)
