class_name InventoryTooltip
extends Container

const ITEM_SCALE := 0.5

export var compare_input := "inventory_more"
export var filter_input := "inventory_filter"
export var clear_filter_mod_input := "inventory_less"

export var color_bonus := Color.yellow
export var color_malus := Color.red
export var color_neutral := Color.darkgray
export var compare_to_inventory : NodePath

var last_func : FuncRef
var last_func_args : Array
var ground_item_state := 0  # 0 for none, 1 for hovering, 2 for released


func display_empty():
	$"%Title/..".self_modulate = Color.white
	$"%Desc".bbcode_text = ""
	show()


func display_item(item_stack : ItemStack, mouseover_node : Control, shown_from_inventory : bool = true):
	if shown_from_inventory:
		ground_item_state = 0
	
	else:
		ground_item_state = 1

	if mouseover_node == null:
		hide()
		return
	
	display_empty()
	$"%Title".text = item_stack.get_name()
	$"%Title/..".self_modulate = Color.white.blend(item_stack.extra_properties.get("back_color", Color.gray)) * 2.0
	
	var stats_label = $"%Desc"
	stats_label.bbcode_text = "[center]"
	if item_stack.extra_properties.has("stats"):
		stats_label.append_bbcode("\n")
		_show_equip_stats(item_stack)
	
	if item_stack.extra_properties.has("price"):
		_show_price(item_stack)
		
	# Description and prompts
	stats_label.append_bbcode("\n[color=#ffffff]")
	
	var desc_tr = tr("item_desc_" + item_stack.item_type.name)
	if desc_tr != "item_desc_" + item_stack.item_type.name:
		stats_label.append_bbcode(desc_tr + "\n\n")

	stats_label.append_bbcode(tr("item_tt_tutorial_filter") % ["F"])  # Input hint, replace with relevant InputEvent
	if item_stack.extra_properties.has("price"):
		stats_label.append_bbcode("\n" + tr("item_tt_tutorial_price") % ["Shift", "F"])  # Input hint, replace with relevant InputEvent

	_update_rect(mouseover_node)
	last_func = funcref(self, "display_item")
	last_func_args = [item_stack, mouseover_node, shown_from_inventory]
	call_deferred("_update_rect", mouseover_node)


func display_bonus(node : Control, bonus_res : Resource):
	var desc = tr("item_bonus_desc_" + bonus_res.id)
	if desc == "item_bonus_desc_" + bonus_res.id:
		desc = ""
	
	display_custom(
		node,
		tr("item_bonus_" + bonus_res.id),
		"[center]\n" + desc + "\n\n"
		+ tr("item_tt_tutorial_filter_bonus") % "F" # Input hint, replace with relevant InputEvent
	)

	last_func = funcref(self, "display_bonus")
	last_func_args = [node, bonus_res]
	

func display_custom(mouseover_node : Control, title : String, bbcode_description : String):
	display_empty()
	$"%Title".text = title
	$"%Desc".bbcode_text = bbcode_description

	_update_rect(mouseover_node)
	last_func = funcref(self, "display_custom")
	last_func_args = [mouseover_node, title, bbcode_description]
	call_deferred("_update_rect", mouseover_node)


func display_last():
	if last_func != null:
		last_func.call_funcv(last_func_args)


static func get_texture_bbcode(tex_path, tex_scale = 1.0):
	var loaded = load(tex_path)
	return "[img=%sx%s]%s[/img]" % [
		loaded.get_width() * tex_scale * ITEM_SCALE,
		loaded.get_height() * tex_scale * ITEM_SCALE,
		tex_path,
	]



func _show_price(item_stack):
	var stats_label = $"%Desc"

	var price = item_stack.extra_properties["price"]
	var item_for_sale = item_stack.extra_properties.has("for_sale")

	var hex_malus := color_malus.to_html(false)
	var hex_neutral := color_neutral.to_html(false)
	var owned_item_counts = {}
	if item_for_sale:
		var inventories = get_tree().get_nodes_in_group("inventory_view")
		for x in inventories:
			if (x.interaction_mode & InventoryView.InteractionFlags.CAN_TAKE_AUTO) != 0:
				x.inventory.count_all_items(owned_item_counts)

		if item_stack.extra_properties.has("left_in_stock"):
			stats_label.append_bbcode("\n" + tr("item_tt_left_in_stock") % ("[color=#%s]%s[/color]" % [hex_malus, item_stack.extra_properties["left_in_stock"]]))

	stats_label.append_bbcode("\n" + tr("item_tt_price") + "\n")
	var k_loaded  # Because for easier serialization, items are stored as paths
	for k in price:
		k_loaded = load(k)
		stats_label.append_bbcode(
			"\n[color=#"
			+ k_loaded.default_properties.get("back_color", Color.white).to_html()
			+ "]"
			+ tr("item_name_" + k_loaded.name) + "[/color] x"
			+ str(price[k])
		)
		if item_for_sale:
			stats_label.append_bbcode(" [color=#%s]%s[/color] " % [
				hex_malus if owned_item_counts.get(k_loaded, 0) < price[k] else hex_neutral,
				tr("item_tt_have_items") % owned_item_counts.get(k_loaded, 0)
			])

	stats_label.append_bbcode("\n")


func _update_rect(mouseover_node):
	var left = mouseover_node.rect_global_position.x + mouseover_node.rect_size.x * 0.5 < get_viewport_rect().size.x * 0.5
	rect_size = Vector2.ZERO
	rect_position = mouseover_node.rect_global_position + Vector2(
		(mouseover_node.rect_size.x if left else -rect_size.x),
		(mouseover_node.rect_size.y - rect_size.y) * 0.5
	)
	rect_position.y = clamp(rect_position.y, 0,  get_viewport_rect().size.y - rect_size.y)


func _get_compared_item_stats(to_item : ItemStack) -> Array:
	var inv = get_node(compare_to_inventory).inventory._cells
	var result := []
	var to_flags := to_item.item_type.slot_flags
	for x in inv:
		if x == null: continue
		if x.item_type.slot_flags & to_flags & ItemType.EQUIPMENT_FLAGS != 0:
			result.append(x.extra_properties["stats"])

	return result


func _show_equip_stats(item_stack : ItemStack):
	var stats = item_stack.extra_properties["stats"]
	var hex_bonus := color_bonus.to_html(false)
	var hex_malus := color_malus.to_html(false)
	var hex_neutral := color_neutral.to_html(false)

	var displayed_stats := {}
	for k in stats:
		displayed_stats[k] = stats[k]
	
	if !Input.is_action_pressed(compare_input):
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		_append_bbcode_stats(displayed_stats, hex_bonus, hex_neutral, hex_malus)
		return

	var compared := _get_compared_item_stats(item_stack)
	if compared.size() == 0:
		for k in displayed_stats:
			displayed_stats[k] = [displayed_stats[k]]

		_append_bbcode_stats(displayed_stats, hex_bonus, hex_neutral, hex_malus)
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

	_append_bbcode_stats(displayed_stats, hex_bonus, hex_neutral, hex_malus)


func _append_bbcode_stats(displayed_stats, hex_bonus, hex_neutral, hex_malus):
	var first := true
	var value := 0.0
	var text := ""
	for k in displayed_stats:
		first = true
		for i in displayed_stats[k].size():
			value = displayed_stats[k][i]
			text += ("%s[color=#%s]%s%s" % [
				("" if first else "/"),
				(hex_bonus if value > 0.0 else (hex_neutral if value == -0.0 else hex_malus)),
				("+" if value >= 0.0 else ""),
				value
			])
			first = false
		
		text += (
			" "
			+ tr("item_bonus_" + k)
			+ "[/color]\n"
		)

	$"%Desc".append_bbcode(text)


func _input(event):
	if event.is_action(filter_input) && event.is_pressed():
		if Input.is_action_pressed(clear_filter_mod_input):
			for x in get_tree().get_nodes_in_group("inventory_view"):
				x.clear_filters()

			return
		
		if last_func == null: return
		if last_func.function == "display_bonus":
			for x in get_tree().get_nodes_in_group("inventory_view"):
				x.set_filter("any_bonus", [last_func_args[1].id])

		if last_func.function != "display_item": return
		var item_stack = last_func_args[0]

		if Input.is_action_pressed(compare_input) && item_stack.extra_properties.has("price"):
			var price = item_stack.extra_properties["price"].keys()
			for i in price.size():
				price[i] = load(price[i])

			for x in get_tree().get_nodes_in_group("inventory_view"):
				x.set_filter("any_type", price)
				x.set_filter("always_show", [item_stack])

		else:
			for x in get_tree().get_nodes_in_group("inventory_view"):
				x.set_filter("any_type", [item_stack.item_type])

	if event.is_action(compare_input):
		if ground_item_state == 1:
			if !event.is_pressed(): hide()
			else: display_last()

		elif ground_item_state == 2:
			ground_item_state = 0
			hide()

		elif visible:
			display_last()


func ground_item_released():
	ground_item_state = 2
