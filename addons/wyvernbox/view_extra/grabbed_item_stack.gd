@tool
@icon("res://addons/wyvernbox/icons/grabbed_item_stack.png")
class_name GrabbedItemStackView
extends ItemStackView

## A node required for handling any input in [InventoryView]s.

## Emitted before an input happens onto another item in an inventory, only while an item is being held. [br]
## [code]onto_item_view[/code]'s [member ItemStackView.stack] contains the [ItemStack] under the cursor, which in turn contains the inventory. [br]
## Set [member item_input_cancelled] while handling this signal to prevent the action.
signal input_on_inventory(event : InputEvent, grabbed_item : ItemStack, onto_item_view : ItemStackView)
## Emitted before an input happens outside GUI, only while an item is being held. [br]
## Set [member item_input_cancelled] while handling this signal to prevent the action.
signal input_on_empty(event : InputEvent, grabbed_item : ItemStack)

@export_group("Drop On Ground")

## The node whose position [method drop_on_ground] uses for spawning a ground item.
@export var drop_at_node := NodePath("")

## The [GroundItemManager] the [method drop_on_ground] method uses for spawning a ground item.
@export var drop_ground_item_manager := NodePath("")

## The max distance an item dropped by [method drop_on_ground] can fly.
@export var drop_max_distance := 256.0

## The [Camera3D] used for dropping the item into a 3D scene. In 2D, unused.
@export var drop_camera_3d := NodePath("")

## For dropping items in 3D, the physics layers to hit when determining destination position.
@export_flags_3d_physics var drop_ray_mask := 1

@export_group("View and Gestures")

## The size of the item's texture, if its in-inventory size was [code](1, 1)[/code].
@export var unit_size := Vector2(18, 18)

## Hide the mouse cursor while item is grabbed. [br]
## If item texture lags 1 frame behind the user's cursor, set this to [code]false[/code] to reduce the "floaty" feel.
@export var hide_cursor := false

## Maximum time between clicks to register a double-click, a gesture for grabbing all items of one type. Set to 0 to disable.
@export var double_click_time_msec := 200

## The currently grabbed stack - returns [code]null[/code] if none, or if no instances of this class exist.
static var grabbed_stack : ItemStack:
	set(v):
		if !is_instance_valid(_instance): return
		_instance.stack = v
	get:
		if !is_instance_valid(_instance): return null
		return _instance.stack

## The [Control] that will trigger [method drop_on_ground] when clicked. Created automatically.
var drop_surface_node : Control

## [InventoryView] of the item under the cursor.
var selected_item_inventory : InventoryView

## Set to [code]true[/code] after receiving [signal input_on_inventory] or [signal input_on_empty] to prevent an input action on an item.
var item_input_cancelled := false


static var _instance : GrabbedItemStackView
static var _last_click_time_msec := 0
static var _last_click_pos := Vector2()

var _last_input_non_pointer := false


func _enter_tree():
	assert(!is_instance_valid(_instance), "Multiple GrabbedItemStack instances detected in the scene - perhaps you added one to an instantiated scene?. Only one GrabbedItemStack can exist in the game scene.")
	_instance = self


func _exit_tree():
	if _instance == self: _instance = null


static func get_instance() -> GrabbedItemStackView:
	return _instance


static func select_cell(view : InventoryView, cell : Vector2, only_if_grabbed : bool = false):
	if !is_instance_valid(_instance): return
	if only_if_grabbed && _instance.stack == null: return
	_instance.selected_item_inventory = view
	view.selected_cell = cell

	_instance.grab_focus()


static func select_cell_nearest(view : InventoryView):
	if !is_instance_valid(_instance): return
	var former_selected := _instance.selected_item_inventory
	var cell := Vector2(0, 0)
	if is_instance_valid(former_selected):
		# TODO
		# var pos := former_selected.cell_position_to_global(former_selected.selected_cell)
		# cell = view.get_nearest_cell_to_global_position(pos)
		# cell = pos
		pass

	_instance.selected_item_inventory = view
	view.selected_cell = cell
	_instance.grab_focus()


static func double_click_valid() -> bool:
	return (
		_instance != null
		&& Time.get_ticks_msec() <= _last_click_time_msec + _instance.double_click_time_msec
		&& _last_click_pos == _instance.global_position
	)


func _ready():
	if get_parent() && !(has_node("%Texture") && has_node("%Count")):
		var new_node : Node = load("res://addons/wyvernbox_prefabs/grabbed_item_stack_view.tscn").instantiate()
		add_sibling(new_node)
		await get_tree().process_frame
		new_node.owner = owner
		free()
		return

	if Engine.is_editor_hint():
		for x in InventoryView.get_instances():
			x.update_configuration_warnings()

		return

	focus_neighbor_left = "."
	focus_neighbor_right = "."
	focus_neighbor_top = "."
	focus_neighbor_bottom = "."
	focus_previous = "."
	focus_next = "."

	var new_node := Control.new()
	new_node.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	new_node.gui_input.connect(_drop_surface_input)
	new_node.name = "DropSurface"
	new_node.hide()
	await get_tree().process_frame
	get_parent().add_child(new_node)
	get_parent().move_child(new_node, 0)

	drop_surface_node = new_node
	visibility_changed.connect(_on_visibility_changed)
	focus_entered.connect(_on_focus_entered)
	add_to_group(&"grabbed_item")
	hide()
	_on_visibility_changed()

## Sets the displayed stack.
func update_stack(new_stack: ItemStack, unit_size: Vector2 = unit_size, show_background = false):
	super(new_stack, unit_size, false)
	drop_surface_node.visible = visible
	visible = new_stack != null
	if !visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Grabs a stack, removing it from its inventory.
func grab(item_stack : ItemStack):
	if item_stack.inventory != null:
		var max_count := item_stack.item_type.max_stack_count
		if item_stack.count > max_count:
			item_stack.inventory.add_items_to_stack(item_stack, -max_count)
			item_stack = item_stack.duplicate_with_count(max_count)
			
		else:
			item_stack.inventory.remove_item(item_stack)

	var tt := InventoryTooltip.get_instance()
	if is_instance_valid(tt): tt.hide()

	update_stack(item_stack)
	_move_to_mouse()
	if hide_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

## Adds items to the grabbed stack, updating its visual representation.
func add_items_to_stack(delta : int):
	stack.count += delta
	update_stack(stack)

## Drop the whole stack onto the first inventory under the cursor.
func drop():
	if stack == null: return
	_any_inventory_try_drop_stack(stack)
	update_stack(stack, unit_size, false)

## Drop one item from the stack onto the first inventory under the cursor.
func drop_one():
	## If you right-click before scene loads, APPARENTLY an error is thrown here.
	if stack == null: return
	if stack.count == 1:
		_any_inventory_try_drop_stack(stack)
		update_stack(stack, unit_size, false)
		return
	
	var one := stack
	var all_but_one := stack.duplicate_with_count(stack.count - 1)
	stack.count = 1
	## Drop first. This function changes stack to whatever's returned.
	_any_inventory_try_drop_stack(stack)

	## If nothing was there, drop the 1 and keep holding the rest.
	if stack == null:
		stack = all_but_one
	
	## If the dropped 1 was returned (can't place), combine the stacks._add_random_item
	elif stack == one:
		one.count += all_but_one.count

	## If there was something in place, just drop all instead of 1.
	else:
		_any_inventory_try_drop_stack(all_but_one)
		
	update_stack(stack, unit_size, false)

## Gather all items that would stack with the grabbed item, from a specific inventory, until full.
func gather_same(from_inventory : Inventory):
	if stack == null:
		return

	var left_to_grab := stack.item_type.max_stack_count - stack.count
	if left_to_grab == 0:
		drop()
		return

	for x in from_inventory.items.duplicate():
		if x.can_stack_with(stack):
			var transfered_count := mini(left_to_grab, x.count)
			from_inventory.add_items_to_stack(x, -transfered_count)
			add_items_to_stack(transfered_count)
			left_to_grab -= transfered_count

		if left_to_grab == 0:
			break

	update_stack(stack, unit_size, false)


func _move_to_mouse():
	global_position = get_global_mouse_position() - size * 0.5 * scale


func _any_inventory_try_drop_stack(stack : ItemStack):
	if !is_instance_valid(selected_item_inventory):
		return

	var found_stack = selected_item_inventory.try_place_stackv(stack, selected_item_inventory.selected_cell)
	if found_stack != stack:
		get_viewport().set_input_as_handled()
		if found_stack == null && hide_cursor:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		update_stack(found_stack)
		return

## Drop the specified stack on the ground at [member drop_at_node]'s position as child of [member drop_ground_item_manager].
func drop_on_ground(stack : ItemStack, click_pos = null) -> bool:
	var node := get_node_or_null(drop_at_node)
	if !is_instance_valid(node):
		return false

	var spawn_at_pos = node.global_position
	var throw_vec
	if click_pos == null:
		throw_vec = null

	elif node is Node2D:
		throw_vec = (node.get_canvas_transform().affine_inverse() * (get_canvas_transform() * click_pos) - spawn_at_pos).limit_length(drop_max_distance)

	else:
		var cam : Camera3D = get_node_or_null(drop_camera_3d)
		if is_instance_valid(cam):
			var origin := cam.project_ray_origin(click_pos)
			var ray := PhysicsRayQueryParameters3D.create(origin, origin + cam.project_ray_normal(click_pos) * 9999, drop_ray_mask)
			var hit : Dictionary = node.get_world_3d().direct_space_state.intersect_ray(ray)
			if !hit.is_empty():
				throw_vec = (hit.position - spawn_at_pos).limit_length(drop_max_distance)

	var ground_items := get_node(drop_ground_item_manager)
	assert(is_instance_valid(ground_items), "GrabbedItemStackView can not spawn dropped items without a GroundItemManager! Add one to the scene and check GrabbedItemStackView properties, or connect the input_on_empty(event, item_stack) signal to a script to handle the drop yourself.")

	ground_items.add_item(stack, spawn_at_pos, throw_vec)
	if hide_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	return true


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		# if stack != null && _last_input_non_pointer:
			# Input.warp_mouse(get_viewport_transform().affine_inverse() * get_global_rect().get_center())
			# if !hide_cursor:
			# 	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		_last_input_non_pointer = false

		_move_to_mouse()

	if is_instance_valid(selected_item_inventory):
		item_input_cancelled = false
		input_on_inventory.emit(
			event, stack, selected_item_inventory.get_item_view_at_positionv(selected_item_inventory.selected_cell)
		)
		if item_input_cancelled:
			item_input_cancelled = false
			return

	if event is InputEventMouseButton:
		if Input.is_action_pressed(&"inventory_more"):
			return

		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if double_click_valid() && selected_item_inventory != null:
				gather_same(selected_item_inventory.inventory)

			else:
				drop()

		if event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
			drop_one()

		_last_click_time_msec = Time.get_ticks_msec()
		_last_click_pos = global_position


func _gui_input(event : InputEvent):
	if event is InputEventMouse:
		_last_input_non_pointer = false

	if !event is InputEventMouse && event.is_pressed():
		_last_input_non_pointer = true
		var input_vec := Vector2(
			event.get_action_strength(&"ui_right") - event.get_action_strength(&"ui_left"),
			event.get_action_strength(&"ui_down") - event.get_action_strength(&"ui_up"),
		)
		if input_vec == Vector2.ZERO:
			return

		var selected_item_position := selected_item_inventory.selected_cell
		var inventory_res := selected_item_inventory.inventory
		var formerly_selected := inventory_res.get_item_at_positionv(selected_item_position)
		var formerly_selected_position := selected_item_position
		if selected_item_inventory.inventory is GridInventory:
			selected_item_position += input_vec
			var newly_selected := inventory_res.get_item_at_positionv(selected_item_position)
			if stack == null:
				while newly_selected == formerly_selected && newly_selected != null:
					selected_item_position += input_vec
					newly_selected = inventory_res.get_item_at_positionv(selected_item_position)

			if !inventory_res.has_cell(selected_item_position.x, selected_item_position.y):
				selected_item_inventory.selection_out_of_bounds.emit(selected_item_position - input_vec, input_vec)

			global_position = selected_item_inventory.cell_position_to_global(selected_item_position) - size
			selected_item_inventory.selected_cell = selected_item_position
			return

		var container := selected_item_inventory.get_node_or_null("Cells")
		var new_focus : Control
		# if is_instance_valid(container):
		# 	new_focus = _item_grab_focus_neighbor(container.get_child(selected_item_position.x), input_vec, true)

		# elif is_instance_valid(formerly_selected):
		# 	new_focus = _item_grab_focus_neighbor(selected_item_inventory._view_nodes[formerly_selected.index_in_inventory], input_vec)

		# else:
		# 	new_focus = _item_grab_focus_neighbor(selected_item_inventory._selection_node, input_vec)

		if !is_instance_valid(new_focus):
			grab_focus()
			selected_item_position = formerly_selected_position
			selected_item_inventory.selected_cell = formerly_selected_position
			selected_item_inventory.selection_out_of_bounds.emit(formerly_selected_position, input_vec)
			global_position = (selected_item_inventory.get_canvas_transform() * selected_item_inventory.get_selected_rect()).get_center()

		elif container == new_focus.get_parent():
			selected_item_inventory.selected_cell = selected_item_position


func _item_grab_focus_neighbor(item : Control, direction : Vector2, items_only : bool = false) -> Control:
	if !has_method(&"find_valid_focus_neighbor"):
		# Check for 4.1, 4.0 compat - [method find_valid_focus_neighbor] wasn't exposed
		return null

	var focus_side := SIDE_LEFT
	if direction.x > 0:
		focus_side = SIDE_RIGHT

	if direction.y > 0:
		focus_side = SIDE_BOTTOM

	if direction.y < 0:
		focus_side = SIDE_TOP

	var found_nb : Control = item.find_valid_focus_neighbor(focus_side)
	if is_instance_valid(found_nb):
		if items_only && !found_nb is ItemStackView:
			return null

		position = found_nb.get_rect().get_center()
		found_nb.grab_focus()
		return found_nb

	return null


func _drop_surface_input(event : InputEvent):
	item_input_cancelled = false
	input_on_empty.emit(event, stack)
	if item_input_cancelled:
		item_input_cancelled = false
		return

	if event is InputEventMouseButton && stack != null && !event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !drop_on_ground(stack, event.position):
				return

			update_stack(null)
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if !drop_on_ground(stack.duplicate_with_count(1), event.position):
				return

			stack.count -= 1
			if stack.count == 0:
				update_stack(null)

			else:
				update_stack(stack)


func _on_visibility_changed():
	var v := false
	var parent := get_parent()
	if parent is CanvasItem:
		v = parent.is_visible_in_tree()

	elif parent is CanvasLayer:
		v = parent.visible

	set_process_input(v && visible)
	if !v && stack != null:
		drop_on_ground(stack, get_global_mouse_position())
		update_stack(null)


func _on_focus_entered():
	# TODO
	# if !selected_item_inventory.inventory.has_cell(selected_item_position.x, selected_item_position.y):
	# 	selected_item_position = Vector2(0, 0)

	pass
