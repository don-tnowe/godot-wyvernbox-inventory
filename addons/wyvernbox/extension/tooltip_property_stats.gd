extends InventoryTooltipProperty



func _display(item_stack):
	if item_stack.extra_properties.has(&"stats"):
		add_bbcode("\n")
		_show_equip_stats(item_stack)


func _show_equip_stats(item_stack : ItemStack):
	var stats = item_stack.extra_properties[&"stats"]
	var hex_bonus = tooltip.color_bonus.to_html(false)
	var hex_malus = tooltip.color_malus.to_html(false)
	var hex_neutral = tooltip.color_neutral.to_html(false)

	var displayed_stats := {}
	for k in stats:
		displayed_stats[k] = stats[k]
	
	if !Input.is_action_pressed(tooltip.compare_input):
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		add_bbcode(tooltip.get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))
		return

	var compared := _get_compared_item_stats(item_stack)
	if compared.size() == 0:
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		add_bbcode(tooltip.get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))
		return
		
	for k in displayed_stats:
		var arr := []
		arr.resize(compared.size())
		arr.fill(displayed_stats[k])
		displayed_stats[k] = arr

	for i in compared.size():
		for k in compared[i]:
			if !displayed_stats.has(k):
				var arr := []
				arr.resize(compared.size())
				arr.fill(0.0)
				displayed_stats[k] = arr

			displayed_stats[k][i] -= compared[i].get(k, 0.0)

	add_bbcode(tooltip.get_stats_bbcode(displayed_stats, hex_bonus, hex_neutral, hex_malus))


func _get_compared_item_stats(to_item : ItemStack) -> Array:
	var inv = tooltip.get_node(tooltip.compare_to_inventory).inventory._cells
	var result := []
	var to_flags := to_item.item_type.slot_flags
	for x in inv:
		if x == null: continue
		if x.item_type.slot_flags & to_flags & ItemType.EQUIPMENT_FLAGS != 0:
			result.append(x.extra_properties["stats"])

	return result
