class_name InventoryTooltipProperty
extends Reference


var tooltip

var _tooltip_last_label


# Override to define tooltip content.
# Call `add_bbcode()` and `add_node()` from here.
func _display(item_stack):
	pass


func add_bbcode(text):
	if _tooltip_last_label == null:
		_tooltip_last_label = tooltip.get_node("%Desc").duplicate()
		_tooltip_last_label.bbcode_text = "[center]"
		tooltip.get_node("Box").add_child(_tooltip_last_label)

	_tooltip_last_label.append_bbcode(text)


func add_node(node):
	tooltip.get_node("Box").add_child(node)
	_tooltip_last_label = null
