extends InventoryTooltipProperty


func _display(item_stack):
	add_bbcode("[color=#%s]" % tooltip.color_neutral.to_html())
	add_bbcode(tr("item_tt_tutorial_filter") % [
		tooltip.get_action_bbcode(tooltip.filter_input)
	])
	if item_stack.extra_properties.has("price"):
		add_bbcode("\n" + tr("item_tt_tutorial_price") % [
			tooltip.get_action_bbcode(tooltip.compare_input),
			tooltip.get_action_bbcode(tooltip.filter_input),
		])
