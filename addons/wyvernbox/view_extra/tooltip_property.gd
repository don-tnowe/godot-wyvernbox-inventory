class_name InventoryTooltipProperty
extends RefCounted

## Extend this class to create a script that lets [InventoryTooltip] show more.

## The [InventoryTooltip] this script must display on. Use this property to access Tooltip configuration. [br]
## The class contains many useful methods for generating BBCode.
var tooltip : InventoryTooltip

var _tooltip_last_label : RichTextLabel


## Override to define tooltip content. [br]
## Call [method add_bbcode] and [method add_node] from here. You can acces the tooltip node through the [member tooltip] property.
func _display(item_stack : ItemStack):
	pass

## Returns [code]true[/code] if the last label in the tooltip is empty. [br]
## Before adding any text to the label, built-in properties use: [br]
## [code]if !is_label_empty(): add_spacing(2.0, false)[/code]
func is_label_empty():
	return _tooltip_last_label == null || _tooltip_last_label.text.length() == 0

## Appends rich text to the tooltip.
func add_bbcode(text : String):
	if _tooltip_last_label == null:
		_tooltip_last_label = tooltip.get_node("%Desc").duplicate()
		_tooltip_last_label.text = "[center]"
		tooltip.get_node("Box").add_child(_tooltip_last_label)

	_tooltip_last_label.append_text(text)

## Adds an empty [Control] of the specified height.
func add_spacing(amount : float, include_boxcontainer_spacing : bool = true):
	var node := Control.new()
	if include_boxcontainer_spacing:
		node.custom_minimum_size.y = amount - tooltip.get_node("Box").get_theme_constant(&"separation")

	else:
		node.custom_minimum_size.y = amount

	add_node(node)

## Adds a custom control node to the tooltip. Text can still be added after. [br]
## [b]Warning:[/b] for nodes with children, make sure childrens' [member Control.mouse_filter] is [code]MOUSE_FILTER_IGNORE[/code].
func add_node(node : Control):
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.get_node("Box").add_child(node)
	_tooltip_last_label = null
