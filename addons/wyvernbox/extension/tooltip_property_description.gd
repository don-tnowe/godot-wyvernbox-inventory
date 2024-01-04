extends InventoryTooltipProperty


func _display(item_stack : ItemStack):
	var desc_tr := tr(item_stack.item_type.description).format(item_stack.extra_properties)
	if desc_tr != item_stack.item_type.description:
		if !is_label_empty(): add_spacing(2.0, false)
		add_bbcode("[color=#%s]" % tooltip.color_description.to_html())
		add_bbcode(desc_tr)