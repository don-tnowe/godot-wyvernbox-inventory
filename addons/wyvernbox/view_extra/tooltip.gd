@tool
@icon("res://addons/wyvernbox/icons/tooltip.png")
class_name InventoryTooltip
extends Container

## A node collection required to view item information.
##
## Can be expanded to show more information by adding scripts that extend [TooltipProperty]. Check out [code]addons/wyvernbox/extension/[/code] for starters!

## The scale for in-text images drawn by [member get_texture_bbcode].
const TEX_SCALE := 0.5

## Inventory to compare stats to when [member compare_input] is held.
@export var compare_to_inventory : NodePath

## List of [InventoryTooltipProperty] scripts to display items properties in this tooltip.
@export var property_scripts : Array[Script]

@export_group("Input Actions")

## Action for comparing item stats and using quick-transfer (default [kbd]Shift[/kbd]).
@export var compare_input := &"inventory_more"

## Action for attaching a view filter to visible inventories (default [kbd]F[/kbd]).
@export var filter_input := &"inventory_filter"

## Action for the "Clear filter" mod. Hold, then press [member filter_input] to clear all view filters (default [kbd]Alt[/kbd]).
@export var clear_filter_mod_input := &"inventory_less"

@export_group("Visuals")

## Panel to use under the name. If empty, uses the theme's [code]PanelContainer/panel[/code] stylebox.
@export var nameplate_panel : StyleBox:
	set(v):
		nameplate_panel = v
		if get_child_count() == 0: await ready
		if v != null:
			$"%Title/..".add_theme_stylebox_override(&"panel", v)

		else:
			$"%Title/..".remove_theme_stylebox_override(&"panel")

## Panel to use under the description box. If empty, uses the theme's [code]RichTextLabel/normal[/code] stylebox. [br]
@export var desc_panel : StyleBox:
	set(v):
		desc_panel = v
		if get_child_count() == 0: await ready
		if v != null:
			$"%Desc".add_theme_stylebox_override(&"normal", v)
			$"%Desc".add_theme_stylebox_override(&"focus", v)

		else:
			$"%Desc".remove_theme_stylebox_override(&"normal")
			$"%Desc".remove_theme_stylebox_override(&"focus")

## Panel to use under the entire tooltip box. If empty, uses the theme's [code]Panel/panel[/code] stylebox. [br]
## [b]Note: [/b]if using a panel with a border at the top, prefer [member desc_panel] instead.
@export var back_panel : StyleBox:
	set(v):
		back_panel = v
		if get_child_count() == 0: await ready
		if has_node("Panel"):
			# Check for the node first, breaks compatibility in case of reliance on it not existing
			if v != null:
				$"Panel".add_theme_stylebox_override(&"panel", v)

			else:
				$"Panel".remove_theme_stylebox_override(&"panel")

## At [code]1.0[/code], the item's name will fully take the color from the [code]&"back_color"[/code] extra property.
@export var back_color_name_tint := 0.1

## At [code]1.0[/code], the item's name panel will fully take the color from the [code]&"back_color"[/code] extra property.
@export var back_color_nameplate_tint := 0.9

@export_group("Text colors")

## Color for positive/higher stat bonuses.
@export var color_bonus := Color("858ffd")

## Color for negative/lower stat bonuses.
@export var color_malus := Color("ff6060")

## Color for zero/equal stat bonuses.
@export var color_neutral := Color("6a6a6a")

## Color for the item's description.
@export var color_description := Color.WHITE


static var _instance : InventoryTooltip


## Last called display function. Either [method display_item] or [method display_custom].
var last_func : Callable

var _next_filter_to_apply : Array[ItemLike] = []
var _ground_item_state := 0  # 0 for none, 1 for hovering, 2 for released
var _first_displayed := false


## Return a reference to the tooltip node, if present on the scene.
static func get_instance() -> InventoryTooltip:
	return _instance


func _enter_tree():
	_instance = self
	if Engine.is_editor_hint():
		# If scene root, don't hide. Otherwise, must start hidden
		visible = owner == null


func _exit_tree():
	if _instance == self: _instance = null


func _ready():
	if get_parent() && !(has_node("%Title") && has_node("%Desc")):
		var new_node : Node = load("res://addons/wyvernbox_prefabs/tooltip.tscn").instantiate()
		add_sibling(new_node)
		await get_tree().process_frame
		new_node.owner = owner
		free()
		return

	if Engine.is_editor_hint():
		for x in InventoryView.get_instances():
			x.update_configuration_warnings()

		return


## Empties the display. Called before the tooltip must display something.
func display_empty():
	$"%Title/..".self_modulate = Color.WHITE
	$"%Desc".text = ""
	for x in get_node("Box").get_children():
		if x.get_index() > 1:
			x.free()

	show()

## Displays an item's name and calls all [member property_scripts] display methods.[br]
## [code]mouseover_node[/code] is the [Control] this tooltip must be placed next to.
func display_item(item_stack : ItemStack, mouseover_node : Control, shown_from_inventory : bool = true):
	if shown_from_inventory:
		_ground_item_state = 0
	
	else:
		_ground_item_state = 1

	if mouseover_node == null:
		hide()
		return
	
	display_empty()
	$"%Title".text = item_stack.get_name()
	var item_back_color : Color = item_stack.extra_properties.get("back_color", Color.GRAY)
	$"%Title/..".self_modulate = Color.WHITE.blend(Color(item_back_color, back_color_nameplate_tint))
	$"%Title".self_modulate = Color.WHITE.blend(Color(item_back_color, back_color_name_tint))
	
	var bbcode_label = $"%Desc"
	bbcode_label.text = "[center]"

	var property_instance
	var last_label = bbcode_label
	for x in property_scripts:
		property_instance = x.new()
		property_instance.tooltip = self
		property_instance._tooltip_last_label = last_label
		property_instance._display(item_stack)
		last_label = property_instance._tooltip_last_label

	_update_rect(mouseover_node)
	last_func = display_item.bind(item_stack, mouseover_node, shown_from_inventory)
	_update_rect.call_deferred(mouseover_node)


## Custom display of a title and a rich text description. [br]
## [code]mouseover_node[/code] is the [Control] this tooltip must be placed next to. [br]
## [code]override_filters[/code] is, optionally, an array of [ItemType] and/or [ItemPattern] that defines which items are highlighted when [member filter_input] is next pressed.
func display_custom(mouseover_node : Control, title : String, bbcode_description : String, override_filters : Array[ItemLike] = []):
	display_empty()
	$"%Title".text = title
	$"%Desc".text = bbcode_description

	_update_rect(mouseover_node)
	last_func = display_custom.bind(mouseover_node, title, bbcode_description)
	_next_filter_to_apply = override_filters
	_update_rect.call_deferred(mouseover_node)

## Custom display of any data. [br]
## [code]mouseover_node[/code] is the [Control] this tooltip must be placed next to. [br]
## [code]tooltip_property[/code] is an [InventoryTooltipProperty] that will display the custom data. [br]
## [code]data[/code] will be passed in [code]tooltip_property[/code]'s [method InventoryTooltipProperty._display] method.
func display_custom_data(mouseover_node : Control, title : String, tooltip_property : RefCounted, data = null):
	display_empty()
	$"%Title".text = title
	tooltip_property.tooltip = self
	tooltip_property._tooltip_last_label = $"%Desc"
	tooltip_property._display(data)

	_update_rect(mouseover_node)
	last_func = display_custom_data.bind(mouseover_node, title, tooltip_property, data)
	_update_rect.call_deferred(mouseover_node)


## Shows the tooltip again after hidden, with the same contents.
func display_last():
	if last_func != null && last_func.is_valid():
		# Breaks if a parameter is null.
    # last_func.call()

		# Breaks because tries to convert Object to Object (???)
    # callv(last_func.get_method, last_func.get_bound_arguments())

    # I couldn't reproduce it in a new project, so I can't report it and this has to stay.
		Callable(self, last_func.get_method()).callv(last_func.get_bound_arguments())

## Returns the visual representation of an [InputEvent] of the specified [code]action[/code].
func get_action_bbcode(action : String) -> String:
	## TODO: detect when there is a joystick input and show that
	for x in InputMap.action_get_events(action):
		if x is InputEventKey:
			return "[color=#aaa]%s[/color]" % x.as_text()

	return "[color=#aaa]%s[/color]" % action.capitalize()

## Turns a [Texture] into rich text. [br]
## Allows to specify scale. For a fixed height, see [method get_fixheight_texture_bbcode].
static func get_texture_bbcode(tex_path : String, tex_scale : float = 1.0) -> String:
	var loaded = load(tex_path)
	if loaded == null: return ""
	return "[img=%sx%s]%s[/img]" % [
		loaded.get_width() * tex_scale * TEX_SCALE,
		loaded.get_height() * tex_scale * TEX_SCALE,
		tex_path,
	]

## Turns a [Texture] into rich text. [br]
## Allows to specify a fixed height, in pixels. For a fixed pixel size, see [method get_texture_bbcode].
static func get_fixheight_texture_bbcode(tex_path : String, tex_height : float) -> String:
	var loaded = load(tex_path)
	if loaded == null: return ""
	var tex_scale = loaded.get_height() / tex_height
	return "[img=%sx%s]%s[/img]" % [
		loaded.get_width() * tex_scale,
		loaded.get_height() * tex_scale,
		tex_path,
	]


func _update_rect(mouseover_node : Control):
	size.y = 0
	if !_first_displayed:
		# I don't know why it starts being stretched to the entire screen height, but I need this workaround.
		_first_displayed = true
		await get_tree().process_frame

	var left := mouseover_node.global_position.x + mouseover_node.size.x * 0.5 < get_viewport_rect().size.x * 0.5
	var minsize := get_combined_minimum_size()
	position = mouseover_node.global_position + Vector2(
		(mouseover_node.size.x if left else -minsize.x),
		(mouseover_node.size.y - minsize.y) * 0.5
	)
	position.y = clamp(position.y, 0,  get_viewport_rect().size.y - minsize.y)
	size.y = 0


func _input(event : InputEvent):
	if event.is_action(filter_input) && event.is_pressed():
		if Input.is_action_pressed(clear_filter_mod_input):
			for x in get_tree().get_nodes_in_group(&"view_filterable"):
				x.view_filter_patterns = []

			return

		_apply_filter_to_inventories()

	if event.is_action(compare_input):
		if _ground_item_state == 1:
			if !event.is_pressed(): hide()
			else: display_last()

		elif _ground_item_state == 2:
			_ground_item_state = 0
			hide()

		elif visible:
			display_last()


func _apply_filter_to_inventories():
	var patterns := _get_filter_to_apply()
	for x in get_tree().get_nodes_in_group(&"view_filterable"):
		x.view_filter_patterns = patterns


func _get_filter_to_apply() -> Array[ItemLike]:
	if last_func == null: return []

	if last_func.get_method() == &"display_custom":
		return _next_filter_to_apply

	if last_func.get_method() != &"display_item":
		return []

	var item_stack = last_func.get_bound_arguments()[0]

	if Input.is_action_pressed(compare_input) && item_stack.extra_properties.has(&"price"):
		var price_items = item_stack.extra_properties[&"price"].keys()
		for i in price_items.size():
			if price_items[i] is String:
				price_items[i] = load(price_items[i])

		return [ItemPatternHighlightStack.new(price_items, [], item_stack)]

	else:
		return [ItemPattern.new([item_stack.item_type])]


func _on_ground_item_released():
	_ground_item_state = 2
