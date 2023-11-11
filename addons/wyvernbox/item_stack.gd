class_name ItemStack
extends RefCounted

## An instance of an [ItemType] with count, name, and extra property overrides.

## Array containing all affixes of this [ItemStack]. Can be locale strings. [br]
## To get the translated, joined name, use [method get_name].
var name_with_affixes:
	set(v):
		assert(false, "ItemStack::name_with_affixes can no longer be set. Use ItemStack::set_name(), ItemStack::name_override, ItemStack::name_prefixes and ItemStack::name_suffixes instead.")
	get:
		return name_prefixes + [name_override if name_override != null else item_type] + name_suffixes

## Item's name override. If empty, uses type's string. Can be locale strings.
var name_override := ""
## Item's prefixes, [method get_name] shows them before the name itself. Can be locale strings.
var name_prefixes : Array = []
## Item's suffixes, [method get_name] shows them after the name itself. Can be locale strings.
var name_suffixes : Array = []

## How many item are in this stack. To set, prefer [Inventory.add_items_to_stack]. [br]
## [b]Warning:[/b] does not update the inventory's view. Call [method emit_changed] after changing this to update.
var count := 1

## The stack's index in the [member Inventory.items] array of its inventory. Should not be set externally.
var index_in_inventory := 1

## The item's cell position. To set, prefer [method InventoryView.try_place_stackv] or [method Inventory.try_place_stackv].
var position_in_inventory := Vector2.ZERO

## The [Inventory] this stack currently resides in. Should not be set externally.
var inventory : Inventory

## The item's [ItemType].
var item_type : ItemType

## The item's extra property dictionary. [br]
## Can contain various data for display in [InventoryTooltip] via its [InventoryTooltipProperty], or other, game-specific uses. [br]
## [code]price[/code] is used for vendor prices, selling and buying. [br]
## [code]back_color[/code] is used to show a colored background in inventories and a glow on the ground. [br]
## For more, edit an [ItemType] with the plugin enabled and search the inspector.
var extra_properties : Dictionary


## Call [code]ItemStack.new(...)[/code] to create an [ItemStack] with [code]item_count[/code] items of type [code]item_type[/code]. [br]
## If the [code]item_extra_properties[/code] dictionary is not set, copies [code]item_type[/code]'s [member ItemType.default_properties].
func _init(item_type : ItemType, item_count : int = 1, item_extra_properties = null):
	self.item_type = item_type
	count = item_count
	extra_properties = (
		item_extra_properties
		if item_extra_properties != null && item_extra_properties.size() > 0 else
		item_type.default_properties.duplicate(true)
	)
	set_name_from_serialized(extra_properties.get(&"name", ""))

## Creates a copy of the stack with the specified count. [br]
## Useful for splitting a stack into multiple.
func duplicate_with_count(new_count : int):
	var new_stack = ItemStack.new(
		item_type, new_count, extra_properties.duplicate(true)
	)
	new_stack.copy_name(self)
	return new_stack

## Returns how many items would overflow above [member max_stack_count], if [code]count_delta[/code] was to be added. [br]
## Returns 0 if everything fits.
func get_overflow_if_added(count_delta : int) -> int:
	return int(max(count + count_delta - item_type.max_stack_count, 0))

## Returns how many items out of [code]count_delta[/code] would fit into [member max_stack_count]. [br]
## Returns the provided [code]count_delta[/code] if everything fits, 0 if already full.
func get_delta_if_added(count_delta : int) -> int:
	return int(min(item_type.max_stack_count - count, count_delta))

## Returns [code]true[/code] if the stacks have the same type, name and extra properties. [br]
## Disable [code]compare_extras[/code] to ignore extra properties.
func can_stack_with(stack : ItemStack, compare_extras : bool = true) -> bool:
	return (
		item_type == stack.item_type
		&& name_prefixes == stack.name_prefixes
		&& name_override == stack.name_override
		&& name_suffixes == stack.name_suffixes
		&& (!compare_extras || extra_properties == stack.extra_properties)
	)

## Returns [code]true[/code] if stacks can be stacked together. See [method can_stack_with].
func matches(stack : ItemStack):
	return can_stack_with(stack)

## Returns the name, with all affixes, translated into current locale.
func get_name() -> String:
	var trd := []
	var last_prefix := name_prefixes.size() - 1
	for i in last_prefix + 1:
		if name_prefixes[last_prefix - i] == "": continue
		trd.append(tr(name_prefixes[last_prefix - i]))

	trd.append(tr(item_type.name) if name_override == "" else name_override)
	for x in name_suffixes:
		if x == "": continue
		trd.append(tr(x))

	return " ".join(trd)

## Copies name from specified stack, with all affixes.
func copy_name(from : ItemStack):
	name_override = from.name_override
	name_prefixes = from.name_prefixes
	name_suffixes = from.name_suffixes
	emit_changed()

## Sets part of the item's name. Specify [code]affix_pos[/code] to set: prefix (before own name), if positive or suffix (after own name), if negative.
## [b]Warning:[/b] setting at affix [code]0[/code]
func set_name(new_name : String, affix_pos : int = 0):
	if affix_pos == 0:
		name_override = new_name

	elif affix_pos < 0:
		if name_prefixes.size() < -affix_pos:
			name_prefixes.resize(-affix_pos)
			for i in name_prefixes.size():
				if name_prefixes[i] == null: name_prefixes[i] = ""

		name_prefixes[-affix_pos - 1] = new_name

	else:
		if name_suffixes.size() < affix_pos:
			name_suffixes.resize(affix_pos)
			for i in name_suffixes.size():
				if name_suffixes[i] == null: name_suffixes[i] = ""

		name_suffixes[affix_pos - 1] = new_name

	emit_changed()


func set_name_from_serialized(new_name):
	if new_name == null:
		new_name = ""

	if new_name is String || new_name is StringName:
		name_prefixes = []
		name_override = new_name
		name_suffixes = []
		return

	if new_name.size() == 3 && new_name[0] is Array && new_name[2] is Array:
		name_prefixes = new_name[0]
		name_override = new_name[1]
		name_suffixes = new_name[2]

	else:
		var found_at : int = new_name.find(null)
		if found_at == -1:
			name_prefixes = new_name.slice(0, new_name.size() - 1)
			name_override = new_name[-1]
			name_suffixes = []

		else:
			name_prefixes = new_name.slice(0, found_at)
			name_override = ""
			name_suffixes = new_name.slice(found_at + 1)


## Returns bottom-right corner of the stack's rect in a [GridInventory]. [br]
## Equivalent to [method get_rect][code].end[/code].
func get_bottom_right() -> Vector2:
	return Vector2(
		position_in_inventory.x + item_type.in_inventory_width,
		position_in_inventory.y + item_type.in_inventory_height
	)

## Returns the [Rect2] of cells this item stack occupies.
func get_rect() -> Rect2:
	return Rect2(position_in_inventory, item_type.get_size_in_inventory())

## Call after you change an [member extra_properties] that must update the item's in-inventory visuals.
func emit_changed():
	if inventory == null: return
	if count <= 0:
		inventory.item_stack_removed.emit(self)

	else:
		inventory.item_stack_changed.emit(self, 0)

## Returns how many items would overflow above [code]maxcount[/code], if [code]added[/code] was to be added. [br]
## Static version of [code]get_overflow_if_added[/code].
static func get_stack_overflow_if_added(count : int, added : int, maxcount : int) -> int:
	return int(max(count + added - maxcount, 0))

## Returns how many items out of [code]added[/code] would fit into [code]maxcount[/code].
## Static version of [code]get_delta_if_added[/code].
static func get_stack_delta_if_added(count : int, added : int, maxcount : int) -> int:
	return int(min(maxcount - count, added))

## Display texture on `node`, or its siblings if item has multiple layers. Nodes are created if needed. [br]
## Texture is shown based on [member item_type], but before that, [member extra_properties] is checked. [br]
## If [code]"custom_texture"[/code] is a [String] or [Texture], loads it. [br]
## If [code]"custom_texture"[/code] is a [Dictionary], tries to load it as an image. See [member Image.data]. [br]
## If [code]"custom_texture"[/code] is an [Array], loads each item in a separate node. Nodes are created as needed. [br]
## [code]"custom_colors"[/code] is an array defining color of each layer.
func display_texture(node : Node):
	for x in node.get_parent().get_children():
		x.texture = null
		x.modulate = Color.WHITE

	node.texture = item_type.texture
	_display_texture_internal(
		node,
		extra_properties.get(&"custom_texture", null),
		extra_properties.get(&"texture_colors", []),
		(Vector3.ONE if node is Node3D else Vector2.ONE) * item_type.texture_scale
	)


func _display_texture_internal(node : Node, data_or_paths, colors : Array = [], scale = Vector2.ONE, index : int = 0):
	if colors.size() > index:
		node.self_modulate = colors[index]

	if node is Control: node.scale = scale
	else: node.scale = scale

	if data_or_paths is Array:
		var count = data_or_paths.size() if data_or_paths is Array else 1
		var icon_parent = node.get_parent()
		var original = node
		for i in data_or_paths.size():
			if icon_parent.get_child_count() > i:
				node = original.duplicate()
				icon_parent.add_child(node)

			else:
				node = icon_parent.get_child(i)

			_display_texture_internal(node, data_or_paths[i], colors, scale, i)

		return

	if data_or_paths is Dictionary:
		var img = Image.new()
		img.data = data_or_paths
		var tex = ImageTexture.create_from_image(img)
		node.texture = tex
		return

	if data_or_paths is String:
		node.texture = load(data_or_paths)
		return

	if data_or_paths is Texture2D:
		node.texture = data_or_paths
		return

## [b]Deprecated.[/b] Returns [code]true[/code] if dictionaries are equal. [br]
## [b]Note:[/b] since Godot 4, the comparison [code]==[/code] operator compares both Arrays and Dictionaries by value. 
static func extras_equal(a : Dictionary, b : Dictionary) -> bool:
	if a.size() != b.size(): return false
	for k in a:
		if !b.has(k): return false
		if (
			a[k] != b[k]
			&& (!a[k] is Dictionary || !extras_equal(a[k], b[k]))
			&& (!a[k] is Array || !arrays_equal(a[k], b[k]))
		):
			return false

	return true

## [b]Deprecated.[/b] Returns [code]true[/code] if arrays are equal. [br]
## [b]Note:[/b] since Godot 4, the comparison [code]==[/code] operator compares both Arrays and Dictionaries by value. 
static func arrays_equal(a : Array, b : Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if (
			a[i] != b[i]
			&& (!a[i] is Dictionary || !extras_equal(a[i], b[i]))
			&& (!a[i] is Array || !arrays_equal(a[i], b[i]))
		):
			return false

	return true

# Creates a new [ItemStack] from a dictionary obtained via [method to_dict].
static func new_from_dict(dict : Dictionary) -> ItemStack:
	var new_item = ItemStack.new(
		load(dict[&"type"]),
		dict[&"count"],
		dict[&"extra"],
	)
	new_item.set_name_from_serialized(dict.get(&"name", ""))
	new_item.position_in_inventory = dict.get(&"position", Vector2(-1, -1))
	return new_item

# Returns a dictionary representation of this [ItemStack]. Useful for serialization.
func to_dict():
	return {
		&"type" : item_type.resource_path,
		&"count" : count,
		&"extra" : extra_properties,
		&"name" : [name_prefixes, name_override, name_suffixes],
		&"position" : position_in_inventory,
	}


func _to_string():
	return (
		get_name()
		+ "\nCount: " + str(count)
		+ ", Data: \n" + str(extra_properties)
		+ "\n"
	)
