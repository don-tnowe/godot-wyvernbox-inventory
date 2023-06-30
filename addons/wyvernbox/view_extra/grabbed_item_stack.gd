@icon("res://addons/wyvernbox/icons/grabbed_item_stack.png")
class_name GrabbedItemStackView
extends ItemStackView

## The node whose position [method drop_on_ground] uses for spawning a ground item.
@export var drop_at_node := NodePath("")

## The [GroundItemManager] the [method drop_on_ground] method uses for spawning a ground item.
@export var drop_ground_item_manager := NodePath("")

## The max distance an item dropped by [method drop_on_ground] can fly.
@export var drop_max_distance := 256.0

## The [Camera] used for dropping the item into a 3D scene. In 2D, unused.
@export var drop_camera_3d := NodePath("")

## The size of the item's texture, if its in-inventory size was [code](1, 1)[/code].
@export var unit_size := Vector2(18, 18)

## Hide the mouse cursor while item is grabbed.
## If item texture lags 1 frame behind the user's cursor, set this to [code]false[/code] to reduce the "floaty" feel.
@export var hide_cursor := false


## The stack currently grabbed, to be released on click.
var grabbed_stack : ItemStack

## The [Control] that will trigger [method drop_on_ground] when clicked. Created automatically.
var drop_surface_node : Control


func _ready():
	var new_node = Control.new()
	new_node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	new_node.gui_input.connect(_drop_surface_input)
	new_node.name = "DropSurface"
	new_node.hide()
	await get_tree().process_frame
	get_parent().add_child(new_node)
	get_parent().move_child(new_node, 0)

	drop_surface_node = new_node
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))
	_on_visibility_changed()

## Grabs a stack, removing it from its inventory.
func grab(item_stack : ItemStack):
	if item_stack.inventory != null:
		var max_count = item_stack.item_type.max_stack_count
		if item_stack.count > max_count:
			item_stack.inventory.add_items_to_stack(item_stack, -max_count)
			item_stack = item_stack.duplicate_with_count(max_count)
			
		else:
			item_stack.inventory.remove_item(item_stack)

	get_tree().get_nodes_in_group(&"tooltip")[0].hide()
	_set_grabbed_stack(item_stack)
	_move_to_mouse()
	if hide_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

## Adds items to the grabbed stack, updating its visual representation.
func add_items_to_stack(delta : int):
	grabbed_stack.count += delta
	_set_grabbed_stack(grabbed_stack)


func _set_grabbed_stack(item_stack : ItemStack):
	grabbed_stack = item_stack
	set_deferred("visible", item_stack != null)
	if item_stack == null:
		drop_surface_node.hide()
		return

	drop_surface_node.show()
	visible = true
	update_stack(item_stack, unit_size, false)

## Drop the whole stack onto the first inventory under the cursor.
func drop():
	_any_inventory_try_drop_stack(grabbed_stack)
	update_stack(grabbed_stack, unit_size, false)

## Drop one item from the stack onto the first inventory under the cursor.
func drop_one():
	## If you right-click before scene loads, APPARENTLY an error is thrown here.
	if grabbed_stack == null: return
	if grabbed_stack.count == 1:
		_any_inventory_try_drop_stack(grabbed_stack)
		update_stack(grabbed_stack, unit_size, false)
		return
	
	var one = grabbed_stack
	var all_but_one = grabbed_stack.duplicate_with_count(grabbed_stack.count - 1)
	grabbed_stack.count = 1
	## Drop first. This function changes grabbed_stack to whatever's returned.
	_any_inventory_try_drop_stack(grabbed_stack)

	## If nothing was there, drop the 1 and keep holding the rest.
	if grabbed_stack == null:
		_set_grabbed_stack(all_but_one)
	
	## If the dropped 1 was returned (can't place), combine the stacks._add_random_item
	elif grabbed_stack == one:
		one.count += all_but_one.count

	## If there was something in place, just drop all instead of 1.
	else:
		var grabbed = grabbed_stack
		_any_inventory_try_drop_stack(all_but_one)
		_set_grabbed_stack(grabbed)
		
	update_stack(grabbed_stack, unit_size, false)


func _move_to_mouse():
	global_position = get_global_mouse_position() - size * 0.5 * scale


func _any_inventory_try_drop_stack(stack):
	var found_stack : ItemStack
	var invs = get_tree().get_nodes_in_group(&"inventory_view")
	var invs_reversed = []
	# Nodes initialized later are placed above (well, if nothing gets created after the initial scene load)
	# So reversing the array has a higher chance of a correct order
	invs_reversed.resize(invs.size())
	for i in invs.size():
		invs_reversed[i] = invs[invs.size() - 1 - i]

	for x in invs_reversed:
		if !x.is_visible_in_tree():
			continue
		
		found_stack =	x.try_place_stackv(
			stack, x.global_position_to_cell(get_global_mouse_position(), stack)
		)
		if found_stack != stack:
			get_viewport().set_input_as_handled()
			if found_stack == null && hide_cursor:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
			_set_grabbed_stack(found_stack)
			return

## Drop the specified stack on the ground at [member drop_at_node]'s position as child of [member drop_ground_item_manager].
func drop_on_ground(stack, click_pos = null):
	var node = get_node(drop_at_node)
	var spawn_at_pos = node.global_position if node is Node2D else node.global_position
	var throw_vec
	if click_pos == null:
		throw_vec = null

	elif node is Node2D:
		throw_vec = (node.get_viewport().canvas_transform.affine_inverse() * click_pos - spawn_at_pos).limit_length(drop_max_distance)

	else:
		var cam : Camera3D = get_node(drop_camera_3d)
		var origin := cam.project_ray_origin(click_pos)
		var hit = node.get_world_3d().direct_space_state.intersect_ray(origin, origin + cam.project_ray_normal(click_pos) * 9999)
		throw_vec = (hit["position"] - spawn_at_pos).limit_length(drop_max_distance)

	get_node(drop_ground_item_manager).add_item(stack, spawn_at_pos, throw_vec)
	if hide_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event):
	if event is InputEventMouseMotion:
		_move_to_mouse()
		
	if event is InputEventMouseButton:
		if Input.is_action_pressed(&"inventory_more"): return
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			drop()

		if event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			drop_one()


func _drop_surface_input(event):
	if event is InputEventMouseButton && grabbed_stack != null && !event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drop_on_ground(grabbed_stack, event.global_position)
			_set_grabbed_stack(null)
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			drop_on_ground(grabbed_stack.duplicate_with_count(1), event.global_position)
			grabbed_stack.count -= 1
			if grabbed_stack.count == 0:
				_set_grabbed_stack(null)

			else:
				_set_grabbed_stack(grabbed_stack)


func _on_visibility_changed():
	var v = get_parent().is_visible_in_tree()
	set_process_input(v && visible)
	if !v && grabbed_stack != null:
		drop_on_ground(grabbed_stack, get_global_mouse_position())
		_set_grabbed_stack(null)
