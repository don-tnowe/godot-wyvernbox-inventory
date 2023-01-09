extends InventoryTooltipProperty


func _display(item_stack):
	add_bbcode("\n[color=#%s]" % tooltip.color_description.to_html())
	var desc_tr = tr(item_stack.item_type.description)
	if desc_tr != item_stack.item_type.description:
		add_bbcode(desc_tr + "\n\n")
