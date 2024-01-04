extends InventoryTooltipProperty

const stock_label := "In Stock: %s"
const price_label := "Price:"
const owned_label := "(have %s)"


func _display(item_stack : ItemStack):
	if item_stack.extra_properties.has(&"price"):
		if !is_label_empty(): add_spacing(2.0, false)
		_show_price(item_stack)


func _show_price(item_stack : ItemStack):
	var price : Dictionary = item_stack.extra_properties[&"price"]
	var item_for_sale := item_stack.extra_properties.has(&"for_sale")

	var hex_malus := tooltip.color_malus.to_html(false)
	var hex_neutral := tooltip.color_neutral.to_html(false)
	var owned_item_counts := {}

	add_bbcode("[color=#fff]")
	if item_for_sale:
		var inventories := InventoryView.get_instances()
		for x in inventories:
			if (x.interaction_mode & InventoryView.InteractionFlags.CAN_TAKE_AUTO) != 0:
				x.inventory.count_all_items(owned_item_counts)

		if item_stack.extra_properties.has(&"left_in_stock"):
			add_bbcode(stock_label % ("[color=#%s]%s[/color]" % [hex_malus, item_stack.extra_properties[&"left_in_stock"]]) + "\n")

	add_bbcode(price_label)
	# For easier serialization, items are stored as paths - load their resources.
	var k_loaded : Resource
	# [InventoryVendor]s can sell stacks. In this case, price might be set for the whole stack, not per item in stack.
	var multiplier := item_stack.count if !item_for_sale else 1
	for k in price:
		k_loaded = load(k) if k is String else k
		add_bbcode(
			"\n[color=#"
			+ k_loaded.default_properties.get(&"back_color", Color.WHITE).to_html()
			+ "]"
			+ tr(k_loaded.name) + "[/color] x"
			+ str(price[k] * multiplier)
		)
		if item_for_sale:
			add_bbcode(" [color=#%s]%s[/color] " % [
				hex_malus if owned_item_counts.get(k_loaded, 0) < price[k] else hex_neutral,
				tr(owned_label) % owned_item_counts.get(k_loaded, 0)
			])
