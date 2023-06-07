class_name InventoryTooltipProperty
extends RefCounted

## The [InventoryTooltip] this script must display on. Use this property to access Tooltip configuration.
## The class contains many useful methods for generating BBCode.
var tooltip : InventoryTooltip

var _tooltip_last_label : RichTextLabel


## Override to define tooltip content.
## Call [method add_bbcode] and [method add_node] from here. You can acces the tooltip node through the [member tooltip] property.
func _display(item_stack):
	pass

## Appends rich text to the tooltip.
func add_bbcode(text):
	if _tooltip_last_label == null:
		_tooltip_last_label = tooltip.get_node("%Desc").duplicate()
		_tooltip_last_label.text = "[center]"
		tooltip.get_node("Box").add_child(_tooltip_last_label)

	_tooltip_last_label.append_text(text)

## Adds a custom node to the tooltip. Text can still be added after.
func add_node(node):
	tooltip.get_node("Box").add_child(node)
	_tooltip_last_label = null
