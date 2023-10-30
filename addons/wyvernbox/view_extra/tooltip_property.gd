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

## Appends rich text to the tooltip.
func add_bbcode(text : String):
	if _tooltip_last_label == null:
		_tooltip_last_label = tooltip.get_node("%Desc").duplicate()
		_tooltip_last_label.text = "[center]"
		tooltip.get_node("Box").add_child(_tooltip_last_label)

	_tooltip_last_label.append_text(text)

## Adds a custom node to the tooltip. Text can still be added after.
func add_node(node : Node):
	tooltip.get_node("Box").add_child(node)
	_tooltip_last_label = null
