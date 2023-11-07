@tool
@icon("res://addons/wyvernbox/icons/inventory_view.png")
class_name InventoryView
extends Control

## A view into an [Inventory]. Allows to edit and save the inventory's contents.
##
## This node automatically arranges child nodes according to the inventory's type and settings. For non-grids, changing the type of the created [Container] node
## allows different arrangements of cells. [br]
## This node type emits useful signals that can help with implementing custom inventory logic.[br]

enum InteractionFlags {
	CAN_TAKE = 1 << 0,  ## Player can take items from here.
	VENDOR = 1 << 1,  ## The player can only take items if CAN_TAKE_AUTO inventories contain items from the item's price extra property. When taken, items will be consumed.
	CAN_PLACE = 1 << 2,  ## Player can place items here.
	CAN_TAKE_AUTO = 1 << 3,  ## VENDOR inventories can take from this inventory, and ItemConversion.get_takeable_inventories filters out inventories wihout this flag.
	CAN_QUICK_TRANSFER_HERE = 1 << 4,  ## If CAN_PLACE, can be quick-transferred into via Shift-click.
}

## Emitted when an item stack is added to any slot.
signal item_stack_added(item_stack : ItemStack)
## Emitted when an item changes count. It is recommended to emit manually if a view-affecting [ItemStack.extra_properties] is changed.
signal item_stack_changed(item_stack : ItemStack, count_delta : int)
## Emitted when an item stack is fully removed from a slot.
signal item_stack_removed(item_stack : ItemStack)
## Emitted when a grab is attempted by the user. [code]false[/code] if [member interaction_mode] disallows it completely, or if it states this is a vendor and item price isn't fulfilled.
signal grab_attempted(item_stack : ItemStack, success : bool)

## The [Inventory] this node displays.
@export var inventory : Inventory:
	set = _set_inventory

## The [ItemInstantiator] that populates this inventory when first opened.
@export var contents : ItemInstantiator

## If [code]true[/code], opening the inventory will initialize [member contents] and set this to [code]false[/code].
@export var init_contents := true

## A scene with an [ItemStackView] in root, spawned to display items.
@export var item_scene : PackedScene = load("res://addons/wyvernbox_prefabs/item_stack_view.tscn")

@export_group("IO")

## The [enum InteractionFlags] of this inventory.
@export_flags(
"Can Take",
"Vendor",
"Can Place",
"Can Take Auto",
"Can Quick Transfer Here"
	) var interaction_mode : = 1 | 4 | 16

## For inventories with the [code]InteractionFlags.CAN_TAKE_AUTO[/code] flag. Vendors and conversions consume from higher priorities first.
@export var auto_take_priority := 0

@export_group("Visual")

## A slot's size, in pixels. Affects item icon scale, and for [GridInventory], the grid size.
@export var cell_size := Vector2(14, 14): set = _set_cell_size

## For [GridInventory], the [Control] to be stretched to the view's size.
@export var grid_background : NodePath

## The node to be stretched to the view's [member cell_size]. [br]
## If a [ViewportTexture] is used as a tiled background, this should be the rendered [SubViewport].
@export var grid_resize_cell : NodePath


## Whether to show item's "back_color" extra property as a background behind it.
@export var show_backgrounds := true

## The modulation to apply to items filtered out by [method view_filter_patterns]. [code]Color(1, 1, 1, 1)[/code] to disable.
@export var view_filter_color := Color(0.1, 0.15, 0.3, 0.75)

## Items that don't match these [ItemPattern]s or [ItemType]s will be dimmed out.
@export var view_filter_patterns : Array: set = _set_view_filter

@export_group("Autosave")


## File path to autosave into. [br]
## Only supports "user://" paths.
@export var autosave_file_path := ""

## Defines which events trigger autosave, if [member autosave_file_path] set.
@export_enum(
"LO // Manually through save_state() calls",
"MID // On quit/scene change",
"HI // On open/close",
"Paranoic // On any item added/removed"
	) var autosave_intensity := 2

## Change to save more data when [method save_state] is called. [br]
## Gets changed on autoload, or call to [method load_state].
@export var save_extra_data : Dictionary


## The latest autosave time, in seconds since startup.
var last_autosave_sec := -1.0

static var _instances : Array[InventoryView] = []:
	set(v): return

var _dragged_node : Control
var _dragged_stack : ItemStack
var _view_nodes := []


func _ready():
	if Engine.is_editor_hint():
		_regenerate_view()
		return

	visibility_changed.connect(_on_visibility_changed)
	await get_tree().process_frame
	load_state()
	add_to_group(&"inventory_view")
	add_to_group(&"view_filterable")
	_on_visibility_changed()


func _enter_tree():
	_instances.push_front(self)


func _exit_tree():
	_instances.erase(self)
	if autosave_intensity >= 1:
		save_state()


func _get_configuration_warnings() -> PackedStringArray:
	if !Engine.is_editor_hint(): return PackedStringArray()
	var arr : Array[String] = []
	if !is_instance_valid(InventoryTooltip.get_instance()):
		arr.append("""To allow viewing of item descriptions and properties, add an InventoryTooltip object.
Search for one in the Scene -> Add Node (Ctrl+A) menu or drag the scene from addons/wyvernbox_prefabs."""
		)

	if !is_instance_valid(GrabbedItemStackView.get_instance()):
		arr.append("""To allow moving items using the mouse cursor, add a GrabbedItemStackView object.
Search for one in the Scene -> Add Node (Ctrl+A) menu or drag the scene from addons/wyvernbox_prefabs."""
		)

	return arr


## Creates a list of all inventory views on the scene. Inventories created last are at the start of the list.
static func get_instances() -> Array[InventoryView]:
	return _instances.duplicate()


func _set_cell_size(v):
	cell_size = v
	if !grid_resize_cell.is_empty():
		get_node(grid_resize_cell).size = v

	_regenerate_view()


func _set_view_filter(v):
	view_filter_patterns = v
	apply_view_filters()


func _set_inventory(v):
	if inventory != null:
		inventory.changed.disconnect(_regenerate_view)
		inventory.item_stack_added.disconnect(_on_item_stack_added)
		inventory.item_stack_changed.disconnect(_on_item_stack_changed)
		inventory.item_stack_removed.disconnect(_on_item_stack_removed)
		inventory.loaded_from_dict.disconnect(_on_loaded_from_dict)

	inventory = v
	if v == null: return
	v.changed.connect(_regenerate_view)
	v.item_stack_added.connect(_on_item_stack_added)
	v.item_stack_changed.connect(_on_item_stack_changed)
	v.item_stack_removed.connect(_on_item_stack_removed)
	v.loaded_from_dict.connect(_on_loaded_from_dict)

	if !is_inside_tree(): await self.ready
	if has_node("Cells"):
		if !v is GridInventory:
			v.width = get_node("Cells").get_child_count()

	if Engine.is_editor_hint(): return

	if has_node("ItemViews"):
		for x in get_node("ItemViews").get_children():
			x.free()

		_view_nodes.clear()
	
	for x in inventory.items:
		_on_item_stack_added(x)

	_regenerate_view()


func _regenerate_view():
	if !is_inside_tree(): await self.ready
	if item_scene == null: return

	if inventory is GridInventory:
		var new_size := cell_size * Vector2(inventory.width, inventory.height)
		if has_node(grid_background):
			get_node(grid_background).show()
			get_node(grid_background).custom_minimum_size = new_size

		custom_minimum_size = new_size
		size = new_size

	else:
		if has_node(grid_background):
			get_node(grid_background).hide()

		var cells = get_node_or_null("Cells")
		if cells == null:
			cells = GridContainer.new()
			cells.columns = 8
			cells.name = "Cells"
			add_child(cells)
			cells.owner = owner if owner != null else self

		if cells.get_child_count() == 0:
			var cell = load("res://addons/wyvernbox_prefabs/inventory_cell.tscn")
			cell = TextureRect.new() if cell == null else cell.instantiate()
			cell.custom_minimum_size = cell_size
			cells.add_child(cell)
			cell.owner = owner if owner != null else self

		var diff := cells.get_child_count() - (inventory.width if inventory != null else 1)
		while diff > 0:
			diff -= 1
			cells.get_child(cells.get_child_count() - 1).free()

		while diff < 0:
			var cell := cells.get_child(0).duplicate()
			diff += 1
			cells.add_child(cell)
			cell.owner = owner if owner != null else self

		if cells is Container:
			# Container items aren't immediately ordered. Wait for the cells to align correctly.
			# NO, awaiting Container.sort_children doesn't work, even if you wait a frame. Why? An enigma.
			await cells.visibility_changed
			await get_tree().process_frame
			for i in _view_nodes.size():
				_redraw_item(_view_nodes[i], inventory.items[i])


## Returns the in-inventory position of the cell clicked from global [code]pos[/code]. [br]
## Providing an [ItemStack] returns the cell into which the item would be placed. [br]
## Returns [code](-1, -1)[/code] if no cell found.
func global_position_to_cell(pos : Vector2, item : ItemStack = null) -> Vector2:
	var xform := get_global_transform().affine_inverse()
	if inventory is GridInventory:
		if has_node(grid_background):
			xform = get_node(grid_background).get_global_transform().affine_inverse()

		var result_pos := Vector2()
		if item != null:
			result_pos = ((
				(xform * pos) / cell_size
			) - item.item_type.get_size_in_inventory() * 0.5).round()

		else:
			result_pos = (
				(xform * pos) / cell_size
			).floor()

		if !inventory.has_cell(result_pos.x, result_pos.y):
			return Vector2(-1, -1)

		return result_pos

	else:
		var cells := $"Cells".get_children()
		for i in cells.size():
			if cells[i].get_global_rect().has_point(pos):
				return Vector2(i, 0)

		return Vector2(-1, -1)

## Returns the [ItemStackView] in cell [code]x[/code]; returns [code]null[/code] if cell empty or out of bounds. [br]
## Non-vector counterpart of [method get_item_view_at_positionv]. [br]
## [b]Note:[/b] position uses inventory cell coordinates. To get them from a global position, use [method global_position_to_cell].
func get_item_view_at_position(x : int, y : int = 0) -> ItemStackView:
	var found_item := inventory.get_item_at_position(x, y)
	if found_item == null:
		return null

	return _view_nodes[found_item.index_in_inventory]

## Returns the [ItemStackView] in cell [code]pos[/code]; returns [code]null[/code] if cell empty or out of bounds. [br]
## Vector counterpart of [method get_item_view_at_position]. [br]
## [b]Note:[/b] position uses inventory cell coordinates. To get them from a global position, use [method global_position_to_cell].
func get_item_view_at_positionv(pos : Vector2) -> ItemStackView:
	var found_item := inventory.get_item_at_positionv(pos)
	if found_item == null:
		return null

	return _view_nodes[found_item.index_in_inventory]


func _redraw_item(node : Control, item_stack : ItemStack):
	node.update_stack(item_stack, cell_size, show_backgrounds)
	_position_item(node, item_stack)


func _position_item(node : Control, item_stack : ItemStack):
	if inventory is GridInventory:
		node.global_position = get_global_transform() * (cell_size * item_stack.position_in_inventory)
		return

	var cell = $"Cells".get_child(item_stack.position_in_inventory.x)
	node.global_position = cell.global_position
	node.size = cell.size


func _on_item_stack_added(item_stack : ItemStack):
	var new_node := item_scene.instantiate()
	if !has_node("ItemViews"):
		var item_views = Control.new()
		item_views.name = "ItemViews"
		add_child(item_views)
		item_views.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	get_node("ItemViews").add_child(new_node)
	
	_view_nodes.append(new_node)
	_redraw_item(new_node, item_stack)
	new_node.gui_input.connect(_on_item_stack_gui_input.bind(item_stack.index_in_inventory))
	new_node.mouse_entered.connect(_on_item_stack_mouse_entered.bind(item_stack.index_in_inventory))

	apply_view_filters()
	item_stack_added.emit(item_stack)

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
		nodes[node_idx].gui_input.disconnect(_on_item_stack_gui_input)
		nodes[node_idx].mouse_entered.disconnect(_on_item_stack_mouse_entered)
		nodes[node_idx].gui_input.connect(_on_item_stack_gui_input.bind(inv_idx))
		nodes[node_idx].mouse_entered.connect(_on_item_stack_mouse_entered.bind(inv_idx))
		_redraw_item(nodes[node_idx], inventory.items[inv_idx])

	apply_view_filters()
	item_stack_removed.emit(item_stack)

	if autosave_intensity >= 3:
		save_state()


func _on_item_stack_changed(item_stack : ItemStack, count_delta : int):
	var node = _view_nodes[item_stack.index_in_inventory]
	_redraw_item(node, item_stack)
	item_stack_changed.emit(item_stack, count_delta)

	if autosave_intensity >= 3:
		save_state()


func _grab_stack(stack_index : int):
	var stack = inventory.items[stack_index]
	if interaction_mode & InteractionFlags.CAN_TAKE == 0:
		# If configured as not takeable, emit the fail signal. (can register clicks on items)
		grab_attempted.emit(stack, false)
		return

	# First, handle stacking and swapping
	var grabbed := GrabbedItemStackView.get_instance()
	if !is_instance_valid(grabbed): return

	if grabbed.grabbed_stack != null:
		# With non-placeable invs, stack with the Grabbed stack instead of one in the inv.
		var grabbed_stack = grabbed.grabbed_stack
		if interaction_mode & InteractionFlags.CAN_PLACE == 0:
			if grabbed_stack.can_stack_with(stack):
				var transferred = grabbed_stack.get_delta_if_added(stack.count)
				grabbed.add_items_to_stack(transferred)
				inventory.add_items_to_stack(stack, -transferred)
				grab_attempted.emit(stack, true)

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
				grab_attempted.emit(stack, purchase_successful)
				if purchase_successful:
					inventory.remove_item(stack)
					grabbed.add_items_to_stack(stack.count)

			return

	# If nothing grabbed, just take the item (or not if can't afford)
	else:
		if !_try_buy(stack):
			grab_attempted.emit(stack, false)
			return

		grab_attempted.emit(stack, true)
		if !grabbed.visible:
			grabbed.grab(stack)


func _try_buy(stack : ItemStack):
	if (interaction_mode & InteractionFlags.VENDOR) == 0 || !stack.extra_properties.has(&"price"):
		return true
	
	var price = stack.extra_properties[&"price"].duplicate()
	var counts = {}
	var inventories := InventoryView.get_instances()
	inventories.sort_custom(_compare_inventory_priority)

	var k_loaded
	for k in price.keys():
		# Stored inside items as paths. When deducting, must use objects
		if k is String:
			k_loaded = load(k)
			price[k_loaded] = price[k] * stack.count
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
		if x.interaction_mode & InteractionFlags.CAN_TAKE_AUTO == 0: continue
		x.inventory.consume_items(price, false, items_to_check)

	return true

## Tries to place [code]stack[/code] into a cell with position [code]pos_x, pos_y[/code]. [br]
## Non-vector counterpart of [method try_place_stackv] - for non-grid inventories, only X needs to be set. [br]
## Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]stack[/code] if it could not be placed.
func try_place_stack(stack : ItemStack, pos_x : int, pos_y : int = 0) -> ItemStack:
	return try_place_stackv(stack, Vector2(pos_x, pos_y))

## Tries to place [code]stack[/code] into a cell with position [code]pos[/code]. [br]
## Vector counterpart of [method try_place_stackv]. [br]
## Returns the stack that appeared in hand after, which is [code]null[/code] if slot was empty or the [code]stack[/code] if it could not be placed. [br]
## [b]Note:[/b] to convert from global coords into cell position, use [method global_position_to_cell].
func try_place_stackv(stack : ItemStack, pos : Vector2) -> ItemStack:
	if interaction_mode & InteractionFlags.CAN_PLACE == 0:
		return stack

	if interaction_mode & InteractionFlags.VENDOR != 0 && (
		!stack.extra_properties.has(&"price")
		|| !inventory.can_place_item(stack, pos)
	):
		return stack

	return inventory.try_place_stackv(stack, pos)


func _quick_transfer_anywhere(stack : ItemStack):
	if (interaction_mode & InteractionFlags.CAN_TAKE) == 0 || !_try_buy(stack):
		grab_attempted.emit(stack, false)
		return

	var original_pos = stack.position_in_inventory
	var targets = _get_quick_transfer_targets(stack.extra_properties.has(&"price"))
	if targets.size() == 0: return

	if stack.count > stack.item_type.max_stack_count:
		inventory.add_items_to_stack(stack, -stack.item_type.max_stack_count)
		stack = stack.duplicate_with_count(stack.item_type.max_stack_count)

	else:
		grab_attempted.emit(stack, true)
		inventory.remove_item(stack)

	var returned_stack
	for x in targets:
		returned_stack = x.inventory.try_quick_transfer(stack)
		# No item returned - slot empty.
		if returned_stack == null: break
		# Same stack returned, not all items delivered.
		if returned_stack == stack: continue
		# Returned something different: put it at the transfered item's place.
		if returned_stack != null: break

	if returned_stack != null:
		# Went through all destinations, still item in hand. Place it under cursor first.
		returned_stack = inventory.try_place_stackv(returned_stack, original_pos)
		# No? Just put anywhere, if can...
		if returned_stack != null && inventory.try_add_item(returned_stack) != 0:
			return

		# If can't, just drop it.
		# else:
		# 	var grabbed := GrabbedItemStackView.get_instance()
		# 	if is_instance_valid(grabbed):
		# 		grabbed.drop_on_ground(returned_stack)

		grab_attempted.emit(stack, true)


func _get_quick_transfer_targets(has_price) -> Array:
	var result := []
	for x in InventoryView.get_instances():
		if (
			x == self
			|| !x.is_visible_in_tree()
			|| (x.interaction_mode & InteractionFlags.CAN_PLACE) == 0
			|| (x.interaction_mode & InteractionFlags.CAN_QUICK_TRANSFER_HERE) == 0
			|| (x.interaction_mode & InteractionFlags.VENDOR != 0 && !has_price)  # Stop using merchants as storage!!!
		):
			continue

		result.append(x)

	return result
	

func _on_item_stack_mouse_entered(stack_index : int):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && Input.is_action_pressed(&"inventory_more"):
		if inventory.items.size() > stack_index:
			_quick_transfer_anywhere(inventory.items[stack_index])
			
		force_drag(0, null)


func _on_item_stack_gui_input(event : InputEvent, stack_index : int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if !Input.is_action_pressed(&"inventory_more"):
				_grab_stack(stack_index)

			else:
				_quick_transfer_anywhere(inventory.items[stack_index])
				force_drag(0, null)


func _can_drop_data(position, data):
	return true

## Updates item visibility based on [member view_filter_patterns]. Call manually after editing the pattern array instead of setting.
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

## Calls the [method Inventory.sort] method on the inventory.
func sort_inventory():
	inventory.sort()

## Saves the inventory to disk into the specified file, or the one set in [member autosave_file_path].
func save_state(filepath = ""):
	if Engine.is_editor_hint(): return  # Called in editor by connected signals
	if last_autosave_sec < 0.0: return  # Fixes empty if saving before first load

	var extras = _get_saved_properties()
	if save_extra_data != null:
		extras.merge(save_extra_data, true)

	inventory.save_state(autosave_file_path if filepath == "" else filepath, extras)
	last_autosave_sec = Time.get_ticks_usec() * 0.000001


## Loads the inventory from disk from the specified file, or the one set in [member autosave_file_path].
func load_state(filepath = ""):
	inventory.load_state(autosave_file_path if filepath == "" else filepath)
	last_autosave_sec = Time.get_ticks_usec() * 0.000001


func _get_saved_properties():
	return {
		&"$_init_contents" : init_contents,
	}


func _on_loaded_from_dict(dict : Dictionary):
	init_contents = dict.get("$_init_contents", false)
	# Save the rest into extra data dict.
	save_extra_data = {}
	for k in dict:
		if k != "contents" && !k.begins_with("$_"):
			save_extra_data[k] = dict[k]


func _compare_inventory_priority(a, b):
	return a.auto_take_priority <= b.auto_take_priority


func _on_visibility_changed():
	if is_visible_in_tree() && init_contents && contents != null:
		init_contents = false
		contents.populate_inventory(self)

	if autosave_intensity >= 2:
		save_state()
