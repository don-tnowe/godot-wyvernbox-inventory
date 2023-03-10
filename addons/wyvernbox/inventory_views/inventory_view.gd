tool
class_name InventoryView, "res://addons/wyvernbox/icons/inventory.png"
extends Control

enum InteractionFlags {
	CAN_TAKE = 1 << 0,  # Player can take items from here.
	VENDOR = 1 << 1,  # The player can only take items if CAN_TAKE_AUTO inventories contain items from the item's price extra property. When taken, items will be consumed.
	CAN_PLACE = 1 << 2, # Player can place items here.
	CAN_TAKE_AUTO = 1 << 3, # VENDOR inventories can take from this inventory, and ItemConversion.get_takeable_inventories filters out inventories wihout this flag.
}

signal item_stack_added(item_stack)
signal item_stack_changed(item_stack, count_delta)
signal item_stack_removed(item_stack)
signal grab_attempted(item_stack, success)

# A slot's size, in pixels.
export var cell_size := Vector2(14, 14) setget _set_cell_size

# A scene with an [ItemStackView] in root, spawned to display items.
export var item_scene : PackedScene = load("res://addons/wyvernbox_prefabs/item_stack_view.tscn")

# Whether to show item's "back_color" extra property as a background behind it.
export var show_backgrounds := true

# The [code]InteractionFlags[/code] of this inventory.
export(InteractionFlags, FLAGS) var interaction_mode := 1 | 4 | 8

# For inventories with the [code]InteractionFlags.CAN_TAKE_AUTO[/code] flag. Vendors and conversions consume from higher priorities first.
export var auto_take_priority := 0


# If set, displays this [InventoryView]'s inventory instead of its own.
export var sync_with_inventory := NodePath()

# File path to autosave into.
# Only supports "user://" paths.
export var autosave_file_path := ""

# Defines which events trigger autosave, if [member autosave_file_path] set.
export(int,
	"LO // Manually through save_state() calls",
	"MID // On quit/scene change",
	"HI // On open/close",
	"Paranoic // On any item added/removed"
) var autosave_intensity := 2


# The modulation to apply to items filtered out by [method view_filter_patterns]. [code]Color(1, 1, 1, 1)[/code] to disable.
export var view_filter_color := Color(0.1, 0.15, 0.3, 0.75)

# Items that don't match these [ItemPattern]s or [ItemType]s will be dimmed out.
export(Array, Resource) var view_filter_patterns : Array setget _set_view_filter


# The [Inventory] this node displays.
var inventory : Reference setget _set_inventory

# The latest autosave time, in seconds since startup.
var last_autosave_sec := -1.0


var _dragged_node : Control
var _dragged_stack : ItemStack
var _view_nodes := []


func _ready():
	if Engine.editor_hint:
		_regenerate_view()
		return

	call_deferred("add_to_group", "inventory_view")
	call_deferred("add_to_group", "view_filterable")
	connect("visibility_changed", self, "_on_visibility_changed")
	_ready2()
	yield(get_tree(), "idle_frame")  # Clone source view might not have initialized
	if has_node(sync_with_inventory):
		_set_inventory(get_node(sync_with_inventory).inventory)

	else:
		load_state()


func _ready2():
	_set_inventory(Inventory.new($"Cells".get_child_count(), 1))


func _exit_tree():
	if autosave_intensity >= 1:
		save_state()


func _set_cell_size(v):
	cell_size = v
	_regenerate_view()


func _set_view_filter(v):
	view_filter_patterns = v
	apply_view_filters()


func _set_inventory(v):
	if Engine.editor_hint: return
	if inventory != null:
		inventory.disconnect("item_stack_added", self, "_on_item_stack_added")
		inventory.disconnect("item_stack_changed", self, "_on_item_stack_changed")
		inventory.disconnect("item_stack_removed", self, "_on_item_stack_removed")

	inventory = v
	v.connect("item_stack_added", self, "_on_item_stack_added")
	v.connect("item_stack_changed", self, "_on_item_stack_changed")
	v.connect("item_stack_removed", self, "_on_item_stack_removed")
	if has_node("ItemViews"):
		for x in get_node("ItemViews").get_children():
			x.queue_free()
	
	for x in inventory.items:
		_on_item_stack_added(x)

	_regenerate_view()


func _regenerate_view():
	if !is_inside_tree() || Engine.editor_hint:
		return

	assert(has_node("Cells"), "Inventories require a child node named Cell with Control-type children")

# Returns the position of the cell clicked from [code]pos[/code]. Vector's [code]x[/code] equals to cell index, while [code]y[/code] is always 0.
# Returns [code](-1, -1)[/code] if no cell found.
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
	var cell = $"Cells".get_child(item_stack.position_in_inventory.x)
	node.rect_position = cell.rect_position
	node.rect_size = cell.rect_size


func _on_item_stack_added(item_stack : ItemStack):
	var new_node := item_scene.instance()
	if !has_node("ItemViews"):
		var item_views = Control.new()
		item_views.name = "ItemViews"
		add_child(item_views)
		item_views.set_anchors_and_margins_preset(PRESET_WIDE)

	get_node("ItemViews").add_child(new_node)
	
	_view_nodes.append(new_node)
	_redraw_item(new_node, item_stack)
	new_node.connect("gui_input", self, "_on_item_stack_gui_input", [item_stack.index_in_inventory])
	new_node.connect("mouse_entered", self, "_on_item_stack_mouse_entered", [item_stack.index_in_inventory])

	apply_view_filters()
	emit_signal("item_stack_added", item_stack)

	if autosave_intensity >= 3:
		save_state()


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

	apply_view_filters()
	emit_signal("item_stack_removed", item_stack)

	if autosave_intensity >= 3:
		save_state()


func _on_item_stack_changed(item_stack : ItemStack, count_delta : int):
	var node = _view_nodes[item_stack.index_in_inventory]
	_redraw_item(node, item_stack)
	emit_signal("item_stack_changed", item_stack, count_delta)

	if autosave_intensity >= 3:
		save_state()


func _grab_stack(stack_index : int):
	var stack = inventory.items[stack_index]
	if interaction_mode & InteractionFlags.CAN_TAKE == 0:
		# If configured as not takeable, emit the fail signal. (can register clicks on items)
		emit_signal("grab_attempted", stack, false)
		return

	# First, handle stacking and swapping
	var grabbed = get_tree().get_nodes_in_group("grabbed_item")[0]
	if grabbed.grabbed_stack != null:
		# With non-placeable invs, stack with the Grabbed stack instead of one in the inv.
		var grabbed_stack = grabbed.grabbed_stack
		if interaction_mode & InteractionFlags.CAN_PLACE == 0:
			if grabbed_stack.can_stack_with(stack):
				var transferred = grabbed_stack.get_delta_if_added(stack.count)
				grabbed.add_items_to_stack(transferred)
				inventory.add_items_to_stack(stack, -transferred)
				emit_signal("grab_attempted", stack, true)

			return

		# With vendors though, only stack if can fit ALL items.
		# Also, never swap items (if can't stack).
		if interaction_mode & InteractionFlags.VENDOR != 0:
			# Don't compare extras: price may be different,
			# and vendor-specific properties may not be there
			if (
				grabbed_stack.can_stack_with(stack, false)
				&& grabbed_stack.get_overflow_if_added(stack.count) <= 0
			):
				var purchase_successful = _try_buy(stack)
				emit_signal("grab_attempted", stack, purchase_successful)
				if purchase_successful:
					inventory.remove_item(stack)
					grabbed.add_items_to_stack(stack.count)

			return

	# If nothing grabbed, just take the item (or not if can't afford)
	else:
		if !_try_buy(stack):
			emit_signal("grab_attempted", stack, false)
			return

		emit_signal("grab_attempted", stack, true)
		if !grabbed.visible:
			grabbed.grab(stack)


func _try_buy(stack : ItemStack):
	if (interaction_mode & InteractionFlags.VENDOR) == 0 || !stack.extra_properties.has("price"):
		return true
	
	var price = stack.extra_properties["price"].duplicate()
	var counts = {}
	var inventories = get_tree().get_nodes_in_group("inventory_view")
	inventories.sort_custom(self, "_sort_inventories_priority")

	var k_loaded
	for k in price.keys():
		# Stored inside items as paths. When deducting, must use objects
		k_loaded = load(k)
		price[k_loaded] = price[k]
		price.erase(k)

	for x in inventories:
		if (x.interaction_mode & InteractionFlags.CAN_TAKE_AUTO) != 0:
			x.inventory.count_items(price, counts)

	var items_to_check = {}
	for k in price:
		if !counts.has(k) || counts[k] < price[k]:
			return false

		if k is ItemPattern:
			k.collect_item_dict(items_to_check)

		else:
			items_to_check[k] = true

	for x in inventories:
		if price.size() == 0: break
		x.inventory.consume_items(price, false, items_to_check)

	return true

# Tries to place [code]stack[/code] into a cell with position [code]pos[/code].
# Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]stack[/code] if it could not be placed.
# Note: to convert from global coords into cell position, use [method global_position_to_cell].
func try_place_stackv(stack : ItemStack, pos : Vector2) -> ItemStack:
	if interaction_mode & InteractionFlags.CAN_PLACE == 0:
		return stack

	if interaction_mode & InteractionFlags.VENDOR != 0 && (
		!stack.extra_properties.has("price")
		|| !inventory.can_place_item(stack, pos)
	):
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
		inventory.remove_item(stack)

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
			|| !x.is_visible_in_tree()
			|| (x.interaction_mode & InteractionFlags.CAN_PLACE == 0)
			|| (x.interaction_mode & InteractionFlags.VENDOR != 0 && !stack.extra_properties.has("price"))  # Stop using merchants as storage!!!
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
			
		force_drag(0, null)


func _on_item_stack_gui_input(event : InputEvent, stack_index : int):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if !Input.is_action_pressed("inventory_more"):
				_grab_stack(stack_index)

			else:
				_quick_transfer_anywhere(inventory.items[stack_index])
				force_drag(0, null)


func can_drop_data(position, data):
	return true

# Updates item visibility based on [member view_filter_patterns].
func apply_view_filters(stack_index : int = -1):
	if stack_index == -1:
		if view_filter_color == Color(1, 1, 1, 1):
			for i in _view_nodes.size():
				_view_nodes[i].modulate = Color(1, 1, 1, 1)

		for i in _view_nodes.size():
			apply_view_filters(i)

		return

	var all_match := true
	for x in view_filter_patterns:
		if !x.matches(inventory.items[stack_index]):
			all_match = false
			break

	_view_nodes[stack_index].modulate = Color(1, 1, 1, 1) if all_match else view_filter_color

# Calls the [method Inventory.sort] method on the inventory.
func sort_inventory():
	inventory.sort()

# Saves the inventory to disk into the specified file, or the one set in [member autosave_file_path].
func save_state(filepath = ""):
	if Engine.editor_hint: return  # Called in editor by connected signals
	if last_autosave_sec < 0.0: return  # Fixes empty if saving before first load

	last_autosave_sec = Time.get_ticks_usec() * 0.000001
	inventory.save_state(autosave_file_path if filepath == "" else filepath)

# Loads the inventory from disk from the specified file, or the one set in [member autosave_file_path].
func load_state(filepath = ""):
	last_autosave_sec = Time.get_ticks_usec() * 0.000001
	inventory.load_state(autosave_file_path if filepath == "" else filepath)


func _compare_inventory_priority(a, b):
	return a.auto_take_priority <= b.auto_take_priority


func _on_visibility_changed():
	if autosave_intensity >= 2:
		save_state()
