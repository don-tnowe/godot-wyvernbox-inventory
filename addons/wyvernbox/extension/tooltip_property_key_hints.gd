extends InventoryTooltipProperty

const filter_label := "%s to highlight same items."
const price_label := "%s+%s to highlight all requirements."


func _display(item_stack):
	add_bbcode("[color=#%s]" % tooltip.color_neutral.to_html())
	add_bbcode(filter_label % [
		tooltip.get_action_bbcode(tooltip.filter_input)
	])
	if item_stack.extra_properties.has(&"price"):
		add_bbcode("\n" + price_label % [
			tooltip.get_action_bbcode(tooltip.compare_input),
			tooltip.get_action_bbcode(tooltip.filter_input),
		])
