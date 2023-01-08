tool
class_name InventoryVendor, "res://addons/wyvernbox/icons/vendor.png"
extends Control

signal item_received(item_stack)
signal item_given(item_stack)
signal item_cant_afford(item_stack)

export var vendor_inventory := NodePath()
export var sell_reward_into_inventory := NodePath()
export var price_markup := 2.0
export var apply_to_all_stock : Resource
export(Array, Resource) var stock setget _set_stock
export(Array, int) var stock_counts setget _set_stock_counts
export(Array, int) var stock_restocks setget _set_stock_restocks

export var infinite_restocks := true
export var remove_price_on_buy := false
export var clear_sold_items_when_hidden := true
export var free_buyback := true

var rng = RandomNumberGenerator.new()


func _set_stock(v):
	stock = v
	_resize_arrays(v.size())


func _set_stock_counts(v):
	stock_counts = v
	_resize_arrays(v.size())


func _set_stock_restocks(v):
	stock_restocks = v
	_resize_arrays(v.size())


func _resize_arrays(size):
	stock_restocks.resize(size)
	stock_counts.resize(size)
	stock.resize(size)


func _ready():
	if Engine.editor_hint: return

	rng.randomize()
	refill_stock()
	connect("visibility_changed", self, "_on_visibility_changed")


func refill_stock():
	var inventory = get_node(vendor_inventory).inventory
	for x in inventory.items:
		inventory.remove(x)

	for i in stock.size():
		var stack = get_stock(i)
		put_up_for_sale(stack, inventory, i)
		inventory.try_add_item(stack)


func get_stock(index : int):
	var stack
	if stock[index] is ItemGenerator:
		stack = stock[index].get_items(rng)[0]
		stack.count *= stock_counts[index]

	else:
		stack = ItemStack.new(stock[index], stock_counts[index], stock[index].default_properties.duplicate(true))

	if apply_to_all_stock != null:
		return apply_to_all_stock.get_items(rng, [stack], [stack.item_type])[0]

	return stack


func put_up_for_sale(stack : ItemStack, inventory : Inventory, stash_index : int):
	stack.extra_properties["seller_stash_index"] = stash_index
	stack.extra_properties["for_sale"] = true
	if stash_index != -1 || !free_buyback:
		apply_price_markup(stack)

	if stash_index != -1 && !infinite_restocks && stock_restocks[stash_index] > 0:
		stack.extra_properties["left_in_stock"] = stock_restocks[stash_index]


func apply_price_markup(stack : ItemStack):
	if !stack.extra_properties.has("price"):
		return
	
	var price_dict = stack.extra_properties["price"]
	stack.extra_properties["real_price"] = price_dict.duplicate()
	for k in price_dict:
		price_dict[k] = int(price_dict[k] * price_markup)


func remove_from_sale(stack : ItemStack):
	var props = stack.extra_properties
	if props.has("price"):
		props["price"] = props.get(
			"real_price", props["price"]
		)
		props.erase("real_price")
	
	props.erase("for_sale")
	props.erase("seller_stash_index")
	props.erase("left_in_stock")


func _on_Inventory_grab_attempted(item_stack : ItemStack, success : bool):
	var inventory = get_node(vendor_inventory).inventory
	if success:
		restock_item(item_stack, inventory)
		remove_from_sale(item_stack)
		if remove_price_on_buy:
			item_stack.extra_properties.erase("price")
		
		emit_signal("item_given", item_stack)

	else:
		emit_signal("item_cant_afford", item_stack)


func restock_item(item_stack : ItemStack, inventory : Inventory):
	var stash_idx = item_stack.extra_properties["seller_stash_index"]
	if stash_idx == -1:
		return

	var left_in_stock = item_stack.extra_properties.get("left_in_stock", -1)
	var restock_item = get_stock(stash_idx)
	var restock_pos = item_stack.position_in_inventory

	# The item is not yet removed, only attempted to remove.
	# Wait until the restock can be placed 
	yield(get_tree(), "idle_frame")

	if !inventory.can_place_item(restock_item, restock_pos):
		restock_pos = inventory.get_free_position(restock_item)

	if infinite_restocks:
		put_up_for_sale(restock_item, inventory, stash_idx)
		inventory.try_place_stackv(restock_item, restock_pos)

	elif left_in_stock > 1:
		put_up_for_sale(restock_item, inventory, stash_idx)
		restock_item.extra_properties["left_in_stock"] = left_in_stock - 1
		inventory.try_place_stackv(restock_item, restock_pos)


func clear_sold_items():
	var inventory = get_node(vendor_inventory).inventory
	for x in inventory.items.duplicate():
		if x.extra_properties["seller_stash_index"] == -1:
			inventory.remove_item(x)


func _on_Inventory_item_stack_added(item_stack : ItemStack):
	if item_stack.extra_properties.has("for_sale"):
		# Those are mine! Why would I give you money for MY items?!?!
		return
	
	emit_signal("item_received", item_stack)
	if item_stack.extra_properties.has("price") && has_node(sell_reward_into_inventory):
		var inventory = get_node(sell_reward_into_inventory).inventory
		var reward = item_stack.extra_properties["price"]
		for k in reward:
			inventory.try_add_item(ItemStack.new(load(k), reward[k]))
	
	put_up_for_sale(item_stack, get_node(vendor_inventory).inventory, -1)


func _on_visibility_changed():
	if !is_visible_in_tree():
		if clear_sold_items_when_hidden:
			clear_sold_items()
