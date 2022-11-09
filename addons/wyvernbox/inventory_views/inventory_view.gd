tool
class_name InventoryView
extends Control

enum InteractionFlags {
	CAN_TAKE = 1 << 0,
	VENDOR = 1 << 1,
	CAN_PLACE = 1 << 2,
	CAN_TAKE_AUTO = 1 << 3,
}

signal item_stack_added(item_stack)
signal item_stack_changed(item_stack, count_delta)
signal item_stack_removed(item_stack)
signal grab_attempted(item_stack, success_state)

export var cell_size := Vector2(14, 14) setget _set_cell_size
export var item_scene : PackedScene = load("res://addons/wyvernbox/view_extra/item_stack_view.tscn")
export var show_backgrounds := true
export var enable_view_filters := true
export(InteractionFlags, FLAGS) var interaction_mode := 1 | 4 | 8
export var width := 12 setget _set_grid_width

var inventory : Reference setget _set_inventory
var _dragged_node : Control
var _dragged_stack : ItemStack
var _view_nodes := []

var view_filter : InventoryFilter


func _ready():
	call_deferred("add_to_group", "inventory_view")
	_ready2()


func _ready2():
	_set_inventory(Inventory.new($"Cells".get_child_count(), 1))


func _set_grid_width(v):
	width = v
	regenerate_view()


func _set_cell_size(v):
	cell_size = v
	regenerate_view()


func _set_inventory(v):
	if inventory != null:
		inventory.disconnect("item_stack_added", self, "_on_item_stack_added")
		inventory.disconnect("item_stack_changed", self, "_on_item_stack_changed")
		inventory.disconnect("item_stack_removed", self, "_on_item_stack_removed")

	inventory = v
	v.connect("item_stack_added", self, "_on_item_stack_added")
	v.connect("item_stack_changed", self, "_on_item_stack_changed")
	v.connect("item_stack_removed", self, "_on_item_stack_removed")
	regenerate_view()


func regenerate_view():
	if !is_inside_tree() || Engine.editor_hint:
		return

	assert(has_node("Cells"), "Inventories require a child node named Cell with Control-type children")


func global_position_to_cell(pos : Vector2, item : ItemStack) -> Vector2:
	var cells = $"Cells".get_children()
	for i in cells.size():
		if cells[i].get_global_rect().has_point(pos):
			return Vector2(i, 0)

	return Vector2(-1, -1)


func _redraw_item(node : Control, item_stack : ItemStack):
	node.update_stack(item_stack, cell_size, show_backgrounds)
	_position_item(node, item_stack)


func _position_item(node : Control, item_stack : ItemStack):
	var cell = $"Cells".get_child(item_stack.position_in_inventory.x + item_stack.position_in_inventory.y * width)
	node.rect_position = cell.rect_position
	node.rect_size = cell.rect_size


func _apply_filter(applied_filter):
	if !enable_view_filters: return
	if applied_filter == null: return
	var vis = applied_filter.apply(inventory.items)
	for i in vis.size():
		_view_nodes[i].modulate = Color.white if vis[i] else Color(0.1, 0.15, 0.3, 0.75)


func _on_item_stack_added(item_stack : ItemStack):
	var new_node := item_scene.instance()
	add_child(new_node)
	
	_view_nodes.append(new_node)
	_redraw_item(new_node, item_stack)
	new_node.connect("gui_input", self, "_on_item_stack_gui_input", [item_stack.index_in_inventory])
	new_node.connect("mouse_entered", self, "_on_item_stack_mouse_entered", [item_stack.index_in_inventory])

	_apply_filter(view_filter)
	emit_signal("item_stack_added", item_stack)


func _on_item_stack_removed(item_stack : ItemStack):
	var nodes = _view_nodes.duplicate()
	_view_nodes.pop_back().queue_free()
	var items = inventory.items
	var node_idx := -1
	for inv_idx in items.size():
		if items[inv_idx] == null: continue

		node_idx += 1
		_view_nodes[node_idx] = nodes[node_idx]
		nodes[node_idx].disconnect("gui_input", self, "_on_item_stack_gui_input")
		nodes[node_idx].disconnect("mouse_entered", self, "_on_item_stack_mouse_entered")
		nodes[node_idx].connect("gui_input", self, "_on_item_stack_gui_input", [inv_idx])
		nodes[node_idx].connect("mouse_entered", self, "_on_item_stack_mouse_entered", [inv_idx])
		_redraw_item(nodes[node_idx], inventory.items[inv_idx])

	_apply_filter(view_filter)
	emit_signal("item_stack_removed", item_stack)


func _on_item_stack_changed(item_stack : ItemStack, count_delta : int):
	var node = _view_nodes[item_stack.index_in_inventory]
	_redraw_item(node, item_stack)
	emit_signal("item_stack_changed", item_stack, count_delta)


func _grab_stack(stack_index : int):
	var stack = inventory.items[stack_index]
	if (interaction_mode & InteractionFlags.CAN_TAKE) == 0 || !_try_buy(stack):
		emit_signal("grab_attempted", stack, false)
		return

	emit_signal("grab_attempted", stack, true)
	var grabbed = get_tree().get_nodes_in_group("grabbed_item")[0]
	if !grabbed.visible:
		grabbed.grab(stack)


func _try_buy(stack : ItemStack):
	if (interaction_mode & InteractionFlags.VENDOR) == 0 || !stack.extra_properties.has("price"):
		return true
	
	var price = stack.extra_properties["price"]
	var counts = {}
	var inventories = get_tree().get_nodes_in_group("inventory_view")
	for x in inventories:
		if (x.interaction_mode & InteractionFlags.CAN_TAKE_AUTO) != 0:
			x.inventory.count_items(counts)
	
	for k in price:
		if counts.get(load(k), 0) < price[k]:
			return false
	
	for x in inventories:
		if price.size() == 0: break
		price = x.inventory.consume_items(price)
	
	stack.extra_properties.erase("price")
	return true


func try_place_stackv(stack : ItemStack, pos : Vector2):
	if interaction_mode & InteractionFlags.CAN_PLACE == 0:
		return stack

	return inventory.try_place_stackv(stack, pos)


func _quick_transfer_anywhere(stack : ItemStack, skip_inventories : int = 0):
	if (interaction_mode & InteractionFlags.CAN_TAKE) == 0 || !_try_buy(stack):
		emit_signal("grab_attempted", stack, false)
		return

	var original_pos = stack.position_in_inventory
	var target = _find_quick_transfer_target(stack, skip_inventories)
	if target == null: return
	
	if stack.count > stack.item_type.max_stack_count:
		inventory.add_items_to_stack(stack, -stack.item_type.max_stack_count)
		stack = stack.duplicate_with_count(stack.item_type.max_stack_count)
	
	else:
		emit_signal("grab_attempted", stack, true)
		inventory.remove_stack(stack)
	
	var grabbed_stack = target.inventory.try_quick_transfer(stack)
	if grabbed_stack == null:
		# No item returned - slot empty.
		return
		
	if inventory.can_place_item(grabbed_stack, original_pos):
		# If the item was returned, seek another place.
		if grabbed_stack == stack:
			# DON'T FORGET: item was removed, so put it back. (remember the "work" in "workaround")
			inventory.try_place_stackv(stack, original_pos)
			_quick_transfer_anywhere(stack, skip_inventories + 1)
			return
		
		# If a different item returned, replace original.
		inventory.try_place_stackv(grabbed_stack, original_pos)

	else:
		# Just put anywhere, if can...
		if inventory.try_add_item(grabbed_stack) != 0:
			return
		# If can't, put it back!
		if inventory.try_add_item(grabbed_stack) != 0:
			return
		# If can't put back, just drop it.
		get_tree().call_group("grabbed_item", "drop_on_ground", grabbed_stack)


func _find_quick_transfer_target(stack, skip_inventories_left) -> InventoryView:
	for x in get_tree().get_nodes_in_group("inventory_view"):
		if (
			x == self
			|| (x.interaction_mode & InteractionFlags.CAN_PLACE == 0)
			|| !x.is_visible_in_tree()
		):
			continue
			
		if skip_inventories_left > 0:
			skip_inventories_left -= 1
			continue
		
		return x

	return null
	

func _on_item_stack_mouse_entered(stack_index : int):
	if Input.is_mouse_button_pressed(BUTTON_LEFT) && Input.is_action_pressed("inventory_more"):
		if inventory.items.size() > stack_index:
			_quick_transfer_anywhere(inventory.items[stack_index])
			
		var new_event = InputEventMouseButton.new()
		new_event.pressed = false
		new_event.button_index = BUTTON_LEFT
		get_tree().input_event(new_event)


func _on_item_stack_gui_input(event : InputEvent, stack_index : int):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if !Input.is_action_pressed("inventory_more"):
				_grab_stack(stack_index)

			else:
				var new_event = InputEventMouseButton.new()
				new_event.pressed = false
				new_event.button_index = BUTTON_LEFT
				_quick_transfer_anywhere(inventory.items[stack_index])
				get_tree().input_event(new_event)


func set_filter(key, value):
	if view_filter == null: view_filter = InventoryFilter.new()
	view_filter.set(key, value)
	_apply_filter(view_filter)


func clear_filters():
	if view_filter == null: return
	view_filter.clear()
	_apply_filter(view_filter)


func sort_inventory():
	inventory.sort()
