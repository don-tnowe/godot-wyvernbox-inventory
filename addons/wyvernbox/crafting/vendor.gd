extends Control

export var vendor_inventory := NodePath("../Inventory")
export var vendor_response := NodePath("Label")
export var sale_inventory := NodePath("../../../../Inventory")
export var remove_price_on_buy := false
export var price_markup := 2.0
export var apply_to_all_stock : Resource
export(Array, Resource) var stock setget _set_stock
export var infinite_stock := true
export(Array, int) var stock_counts setget _set_stock_counts 

var rng = RandomNumberGenerator.new()


func _set_stock(v):
	stock = v
	stock_counts.resize(v.size())


func _set_stock_counts(v):
	stock_counts = v
	stock.resize(v.size())


func _ready():
	rng.randomize()
	if apply_to_all_stock != null:
		var buffer
		for i in stock.size():
			buffer = apply_to_all_stock.duplicate()
			buffer.results[0] = stock[i]
			stock[i] = buffer
		
	refill_stock()
	call_deferred("say", "shopkeeper_hello", Color.green)


func refill_stock():
	var inventory = get_node(vendor_inventory).inventory
	for x in inventory.items:
		inventory.remove(x)

	for i in stock.size():
		var stack = get_stock(i)
		put_up_for_sale(stack, inventory, i)
		inventory.try_add_item(stack)


func get_stock(index):
	if stock[index] is ItemGenerator:
		return stock[index].get_item(rng)
		
	return ItemStack.new(stock[index], 1, stock[index].default_properties.duplicate(true))


func put_up_for_sale(stack, inventory, stash_index):
	stack.extra_properties["seller_stash_index"] = stash_index
	stack.extra_properties["seller"] = true
	apply_price_markup(stack)


func apply_price_markup(stack):
	if !stack.extra_properties.has("price"):
		return
	
	var price_dict = stack.extra_properties["price"]
	stack.extra_properties["real_price"] = price_dict.duplicate()
	for k in price_dict:
		price_dict[k] = int(price_dict[k] * price_markup)


func remove_from_sale(stack):
	var props = stack.extra_properties
	if props.has("price"):
		props["price"] = props.get(
			"real_price", props["price"]
		)
		props.erase("real_price")
	
	props.erase("seller")
	props.erase("seller_stash_index")


func _on_Inventory_grab_attempted(stack, success):
	var inventory = get_node(vendor_inventory).inventory
	if success:
		restock_item(stack, inventory)
		remove_from_sale(stack)
		if remove_price_on_buy:
			stack.extra_properties.erase("price")
		
		say("shopkeeper_purchase", Color.darkturquoise)

	else:
		say("shopkeeper_cant_afford", Color.red)


func restock_item(stack, inventory):
	var stash_idx = stack.extra_properties["seller_stash_index"]
	if stash_idx != -1:
		var restock_item = get_stock(stash_idx)
		restock_item.position_in_inventory = stack.position_in_inventory

		# The item is not yet removed, only attempted to remove.
		# Wait until the restock can be placed 
		yield(get_tree(), "idle_frame")

		if infinite_stock:
			put_up_for_sale(restock_item, inventory, stash_idx)
			inventory.try_place_stackv(restock_item, restock_item.position_in_inventory)
			
		elif stock_counts[stash_idx] > 0:
			stock_counts[stash_idx] -= 1
			put_up_for_sale(restock_item, inventory, stash_idx)
			inventory.try_place_stackv(restock_item, restock_item.position_in_inventory)


func _on_Inventory_item_stack_added(item_stack):
	if item_stack.extra_properties.has("seller"):
		# Those are mine! Why would I give you money for MY items?!?!
		return
	
	say("shopkeeper_sold", Color.green)
	if item_stack.extra_properties.has("price"):
		var inventory = get_node(sale_inventory).inventory
		var reward = item_stack.extra_properties["price"]
		for k in reward:
			inventory.try_add_item(ItemStack.new(load(k), reward[k]))
	
	put_up_for_sale(item_stack, get_node(vendor_inventory).inventory, -1)


func say(text, color = Color(1.0, 0.9, 0.1, 1.0)):
	if !has_node(vendor_response): return
	var resp = get_node(vendor_response)
	resp.text = text
	resp.modulate = color

	var tween = create_tween()
	tween.tween_property(resp, "modulate", Color.white, 1)
